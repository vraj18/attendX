// =============================================================
// routes/courses.js
// GET  /api/courses               — list course catalog
// GET  /api/courses/faculty       — list faculty for course assignment
// GET  /api/courses/:id           — course details
// POST /api/courses               — add new course + default section
// PUT  /api/courses/:id           — update course metadata / section assignment
// DELETE /api/courses/:id        — remove a course if no registrations exist
// =============================================================
const express = require('express');
const oracledb = require('oracledb');
const db = require('../db');
const router = express.Router();

function requireAdmin(req, res) {
  const role = req.body.role || req.query.role;
  if (role !== 'admin') {
    return res.status(403).json({ success: false, message: 'Admin role required' });
  }
  return null;
}

async function lookupFacultyIdByName(name) {
  if (!name || !name.toString().trim()) return null;
  const normalized = name.toString().trim().toUpperCase();
  const result = await db.execute(
    `SELECT FacultyID FROM FACULTY WHERE UPPER(Name) = :facultyName OR UPPER(Name) LIKE :facultyLikeName FETCH FIRST 1 ROWS ONLY`,
    { facultyName: normalized, facultyLikeName: `%${normalized}%` }
  );
  return result.rows.length ? result.rows[0].FACULTYID : null;
}

// GET /api/courses
router.get('/', async (req, res) => {
  try {
    const result = await db.execute(
      `SELECT c.CourseID, c.CourseCode, c.CourseName, c.Credits,
              c.Department, c.CourseLevel, c.SemesterType,
              c.CourseCategory, c.RecommendedYear,
              MIN(s.SessionName) AS SessionName,
              MIN(f.Name) AS FacultyName,
              MIN(sec.SectionID) AS SectionID
       FROM COURSES c
       LEFT JOIN COURSE_INSTANCES ci ON ci.CourseID = c.CourseID
       LEFT JOIN SECTIONS sec ON sec.InstanceID = ci.InstanceID
       LEFT JOIN FACULTY f ON sec.FacultyID = f.FacultyID
       LEFT JOIN SESSIONS s ON ci.SessionID = s.SessionID
       GROUP BY c.CourseID, c.CourseCode, c.CourseName, c.Credits,
                c.Department, c.CourseLevel, c.SemesterType,
                c.CourseCategory, c.RecommendedYear
       ORDER BY c.Department, c.RecommendedYear, c.CourseCode`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/courses/faculty
router.get('/faculty', async (req, res) => {
  try {
    const result = await db.execute(
      `SELECT FacultyID, Name, Department, Designation
       FROM FACULTY
       ORDER BY Name`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/courses/:id
router.get('/:id', async (req, res) => {
  try {
    const result = await db.execute(
      `SELECT c.CourseID, c.CourseCode, c.CourseName, c.Credits,
              c.Department, c.CourseLevel, c.SemesterType,
              c.CourseCategory, c.RecommendedYear,
              ci.InstanceID, ci.SessionID,
              sec.SectionID, sec.SectionName, sec.Room, sec.Slot1, sec.Slot2, sec.MaxStudents,
              sec.FacultyID, f.Name AS FacultyName
       FROM COURSES c
       LEFT JOIN COURSE_INSTANCES ci ON ci.CourseID = c.CourseID
       LEFT JOIN SECTIONS sec ON sec.InstanceID = ci.InstanceID
       LEFT JOIN FACULTY f ON sec.FacultyID = f.FacultyID
       WHERE c.CourseID = :id
       FETCH FIRST 1 ROWS ONLY`,
      { id: Number(req.params.id) }
    );
    if (!result.rows.length) {
      return res.status(404).json({ success: false, message: 'Course not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/courses
router.post('/', async (req, res) => {
  const adminCheck = requireAdmin(req, res);
  if (adminCheck) return;

  const {
    courseCode, courseName, credits, department,
    courseLevel, semesterType, courseCategory, recommendedYear,
    sessionId, facultyId, facultyName, sectionName, room, slot1, slot2, maxStudents
  } = req.body;

  const code = (courseCode || '').trim().toUpperCase();
  const name = (courseName || '').trim();
  const level = (courseLevel || 'UG').trim().toUpperCase();
  const semester = (semesterType || 'Both').trim();
  const category = (courseCategory || '').trim().toUpperCase();
  const dept = (department || '').trim().toUpperCase();
  const year = Number(recommendedYear);
  const creditsNum = Number(credits || 4);
  const sessId = Number(sessionId);
  const section = (sectionName || 'A').trim().toUpperCase();
  const maxCap = Number(maxStudents || 60);
  const professor = (facultyName || '').trim();
  const facId = Number(facultyId || 0);

  if (!code || !name || !dept || !category || !year || !sessId || (!professor && !facId)) {
    return res.status(400).json({ success: false, message: 'Missing required course details' });
  }

  try {
    const courseIdRes = await db.execute(`SELECT SEQ_COURSES.NEXTVAL AS NEXTID FROM DUAL`);
    const courseId = courseIdRes.rows[0].NEXTID;

    await db.execute(
      `INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
       VALUES (:id, :code, :courseName, :credits, :dept, :courseLevel, :semesterType, :courseCategory, :recommendedYear)`,
      {
        id: courseId,
        code,
        courseName: name,
        credits: creditsNum,
        dept,
        courseLevel: level,
        semesterType: semester,
        courseCategory: category,
        recommendedYear: year
      },
      { autoCommit: false }
    );

    const instanceRes = await db.execute(`SELECT SEQ_COURSE_INSTANCES.NEXTVAL AS NEXTID FROM DUAL`);
    const instanceId = instanceRes.rows[0].NEXTID;
    await db.execute(
      `INSERT INTO COURSE_INSTANCES (InstanceID, CourseID, SessionID, MaxCapacity)
       VALUES (:id, :courseId, :sessionId, :maxCap)`,
      { id: instanceId, courseId, sessionId: sessId, maxCap },
      { autoCommit: false }
    );

    const resolvedFacultyId = facId || await lookupFacultyIdByName(professor);
    if (!resolvedFacultyId) {
      return res.status(400).json({ success: false, message: 'Professor not found. Enter a valid faculty name or ID.' });
    }

    const sectionRes = await db.execute(`SELECT SEQ_SECTIONS.NEXTVAL AS NEXTID FROM DUAL`);
    const secId = sectionRes.rows[0].NEXTID;
    await db.execute(
      `INSERT INTO SECTIONS (SectionID, InstanceID, SectionName, FacultyID, Room, Slot1, Slot2, MaxStudents)
       VALUES (:id, :instanceId, :section, :facultyId, :room, :slot1, :slot2, :maxCap)`,
      { id: secId, instanceId: instanceId, section, facultyId: resolvedFacultyId, room: room || null, slot1: slot1 || null, slot2: slot2 || null, maxCap },
      { autoCommit: true }
    );

    res.json({ success: true, message: 'Course created successfully', courseId, sectionId: secId });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT /api/courses/:id
router.put('/:id', async (req, res) => {
  const adminCheck = requireAdmin(req, res);
  if (adminCheck) return;

  const {
    courseCode, courseName, credits, department,
    courseLevel, semesterType, courseCategory, recommendedYear,
    sectionId, facultyId, facultyName, room, slot1, slot2, maxStudents
  } = req.body;

  const courseId = Number(req.params.id);
  if (!courseId) {
    return res.status(400).json({ success: false, message: 'Invalid Course ID' });
  }

  try {
    await db.execute(
      `UPDATE COURSES SET CourseCode = :code, CourseName = :courseName, Credits = :credits,
                          Department = :dept, CourseLevel = :courseLevel,
                          SemesterType = :semesterType, CourseCategory = :courseCategory,
                          RecommendedYear = :recommendedYear
       WHERE CourseID = :courseId`,
      {
        code: (courseCode || '').trim().toUpperCase(),
        courseName: (courseName || '').trim(),
        credits: Number(credits || 4),
        dept: (department || '').trim().toUpperCase(),
        courseLevel: (courseLevel || 'UG').trim().toUpperCase(),
        semesterType: (semesterType || 'Both').trim(),
        courseCategory: (courseCategory || '').trim().toUpperCase(),
        recommendedYear: Number(recommendedYear || 1),
        courseId
      },
      { autoCommit: false }
    );

    if (sectionId) {
      const professor = (facultyName || '').trim();
      const facIdFromName = Number(facultyId) || 0;
      const resolvedFacultyId = facIdFromName || await lookupFacultyIdByName(professor);
      if (!resolvedFacultyId) {
        return res.status(400).json({ success: false, message: 'Professor not found. Enter a valid faculty name or ID.' });
      }
      await db.execute(
        `UPDATE SECTIONS SET FacultyID = :facultyId, Room = :room, Slot1 = :slot1, Slot2 = :slot2, MaxStudents = :maxStudents
         WHERE SectionID = :sectionId`,
        {
          facultyId: resolvedFacultyId,
          room: room || null,
          slot1: slot1 || null,
          slot2: slot2 || null,
          maxStudents: Number(maxStudents || 60),
          sectionId: Number(sectionId)
        },
        { autoCommit: true }
      );
    } else {
      await db.execute('COMMIT', [], { autoCommit: false });
      await db.execute('COMMIT', [], { autoCommit: true });
    }

    res.json({ success: true, message: 'Course updated successfully' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE /api/courses/:id
router.delete('/:id', async (req, res) => {
  const adminCheck = requireAdmin(req, res);
  if (adminCheck) return;

  const courseId = Number(req.params.id);
  if (!courseId) {
    return res.status(400).json({ success: false, message: 'Invalid Course ID' });
  }

  try {
    const regCheck = await db.execute(
      `SELECT COUNT(*) AS CNT
       FROM STUDENT_REGISTRATIONS sr
       JOIN SECTIONS sec ON sr.SectionID = sec.SectionID
       JOIN COURSE_INSTANCES ci ON sec.InstanceID = ci.InstanceID
       WHERE ci.CourseID = :courseId`,
      { courseId }
    );
    if (regCheck.rows[0].CNT > 0) {
      return res.status(400).json({ success: false, message: 'Cannot delete course with existing student registrations' });
    }

    await db.execute(
      `DELETE FROM SECTIONS
       WHERE InstanceID IN (SELECT InstanceID FROM COURSE_INSTANCES WHERE CourseID = :courseId)`,
      { courseId },
      { autoCommit: false }
    );
    await db.execute(
      `DELETE FROM COURSE_INSTANCES WHERE CourseID = :courseId`,
      { courseId },
      { autoCommit: false }
    );
    await db.execute(
      `DELETE FROM COURSES WHERE CourseID = :courseId`,
      { courseId },
      { autoCommit: true }
    );

    res.json({ success: true, message: 'Course removed successfully' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
