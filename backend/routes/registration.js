// =============================================================
// routes/registration.js
// GET  /api/registration/sections          — all sections w/ details
// GET  /api/registration/sections/:id      — one section
// POST /api/registration/register          — register student
// POST /api/registration/drop-section      — drop from section
// GET  /api/registration/student/:id       — all regs for a student
// =============================================================
const express  = require('express');
const oracledb = require('oracledb');
const db       = require('../db');
const router   = express.Router();

// GET /api/registration/sections
router.get('/sections', async (req, res) => {
  try {
    const result = await db.execute(
      `SELECT sec.SectionID, sec.SectionName, sec.Room,
              sec.Slot1, sec.Slot2, sec.MaxStudents,
              ci.InstanceID,
              c.CourseCode, c.CourseName, c.CourseLevel, c.Credits,
              s.SessionID, s.SessionName,
              f.Name AS FacultyName,
              (SELECT COUNT(*) FROM STUDENT_REGISTRATIONS sr
               WHERE sr.SectionID = sec.SectionID
               AND sr.RegStatus = 'Registered') AS EnrolledCount
       FROM SECTIONS sec
       JOIN COURSE_INSTANCES ci ON sec.InstanceID = ci.InstanceID
       JOIN COURSES c           ON ci.CourseID    = c.CourseID
       JOIN SESSIONS s          ON ci.SessionID   = s.SessionID
       JOIN FACULTY f           ON sec.FacultyID  = f.FacultyID
       ORDER BY c.CourseName, sec.SectionName`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/registration/sections/:id
router.get('/sections/:id', async (req, res) => {
  try {
    const result = await db.execute(
      `SELECT sr.RegistrationID, sr.StudentID, st.Name AS StudentName,
              st.ProgramLevel, st.Email, sr.RegistrationDate, sr.RegStatus
       FROM STUDENT_REGISTRATIONS sr
       JOIN STUDENTS st ON sr.StudentID = st.StudentID
       WHERE sr.SectionID = :id
       ORDER BY st.Name`,
      [req.params.id]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/registration/register
router.post('/register', async (req, res) => {
  const { studentId, sectionId, performedBy } = req.body;
  try {
    const result = await db.execute(
      `BEGIN PKG_REGISTRATION.SP_REGISTER_STUDENT(:sid, :secid, :by, :rid, :msg); END;`,
      {
        sid: studentId, secid: sectionId, by: performedBy || 'webui',
        rid: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
        msg: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 500 }
      }
    );
    const msg = result.outBinds.msg;
    const rid = result.outBinds.rid;
    const ok  = msg.startsWith('SUCCESS');
    res.status(ok ? 200 : 400).json({ success: ok, message: msg, registrationId: rid });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/registration/drop-section
router.post('/drop-section', async (req, res) => {
  const { studentId, sectionId, reason, performedBy } = req.body;
  try {
    const result = await db.execute(
      `BEGIN PKG_REGISTRATION.SP_DROP_FROM_SECTION(:sid, :secid, :reason, :by, :msg); END;`,
      {
        sid: studentId, secid: sectionId, reason, by: performedBy || 'webui',
        msg: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 500 }
      }
    );
    const msg = result.outBinds.msg;
    res.json({ success: msg.startsWith('SUCCESS'), message: msg });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/registration/student/:id
router.get('/student/:id', async (req, res) => {
  try {
    const result = await db.execute(
      `SELECT sr.RegistrationID, sr.RegStatus, sr.RegistrationDate,
              sec.SectionID, sec.SectionName, sec.Room, sec.Slot1, sec.Slot2,
              c.CourseCode, c.CourseName, c.Credits, c.CourseLevel,
              s.SessionName, f.Name AS FacultyName,
              PKG_ATTENDANCE.FN_GET_PERCENTAGE(sr.StudentID, sec.SectionID) AS AttendancePct
       FROM STUDENT_REGISTRATIONS sr
       JOIN SECTIONS           sec ON sr.SectionID   = sec.SectionID
       JOIN COURSE_INSTANCES   ci  ON sec.InstanceID = ci.InstanceID
       JOIN COURSES            c   ON ci.CourseID    = c.CourseID
       JOIN SESSIONS           s   ON ci.SessionID   = s.SessionID
       JOIN FACULTY            f   ON sec.FacultyID  = f.FacultyID
       WHERE sr.StudentID = :id
       ORDER BY s.StartDate DESC, c.CourseName`,
      [req.params.id]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/registration/pending
router.get('/pending', async (req, res) => {
  try {
    const result = await db.execute(
      `SELECT sr.RegistrationID, sr.StudentID, st.Name AS StudentName,
              sr.RegistrationDate, sr.RegStatus,
              sec.SectionID, sec.SectionName, 
              c.CourseCode, c.CourseName,
              f.Name AS FacultyName
       FROM STUDENT_REGISTRATIONS sr
       JOIN STUDENTS st         ON sr.StudentID = st.StudentID
       JOIN SECTIONS sec        ON sr.SectionID = sec.SectionID
       JOIN COURSE_INSTANCES ci ON sec.InstanceID = ci.InstanceID
       JOIN COURSES c           ON ci.CourseID = c.CourseID
       JOIN FACULTY f           ON sec.FacultyID = f.FacultyID
       WHERE sr.RegStatus = 'Pending'
       ORDER BY sr.RegistrationDate ASC`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/registration/approve
router.post('/approve', async (req, res) => {
  const { registrationId, status } = req.body;
  
  if (!['Registered', 'Rejected'].includes(status)) {
    return res.status(400).json({ success: false, message: 'Invalid status' });
  }

  try {
    const result = await db.execute(
      `UPDATE STUDENT_REGISTRATIONS 
       SET RegStatus = :status 
       WHERE RegistrationID = :regId AND RegStatus = 'Pending'`,
      { status: status, regId: registrationId },
      { autoCommit: true }
    );
    
    if (result.rowsAffected > 0) {
      res.json({ success: true, message: `Registration ${status} successfully` });
    } else {
      res.status(404).json({ success: false, message: 'Pending registration not found' });
    }
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/registration/my-sections/:facultyId
router.get('/my-sections/:facultyId', async (req, res) => {
  try {
    const result = await db.execute(
      `SELECT sec.SectionID, sec.SectionName, c.CourseCode, c.CourseName,
              s.SessionName, sec.EnrolledCount, sec.MaxStudents
       FROM SECTIONS sec
       JOIN COURSE_INSTANCES ci ON sec.InstanceID = ci.InstanceID
       JOIN COURSES c           ON ci.CourseID    = c.CourseID
       JOIN SESSIONS s          ON ci.SessionID   = s.SessionID
       WHERE sec.FacultyID = :fid
       ORDER BY s.StartDate DESC, c.CourseCode`,
      { fid: req.params.facultyId }
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/registration/my-courses/:studentId
router.get('/my-courses/:studentId', async (req, res) => {
  try {
    const result = await db.execute(
      `SELECT sr.RegistrationID, sr.RegStatus, sec.SectionName,
              c.CourseCode, c.CourseName, f.Name AS FacultyName,
              s.SessionName
       FROM STUDENT_REGISTRATIONS sr
       JOIN SECTIONS sec        ON sr.SectionID = sec.SectionID
       JOIN COURSE_INSTANCES ci ON sec.InstanceID = ci.InstanceID
       JOIN COURSES c           ON ci.CourseID    = c.CourseID
       JOIN SESSIONS s          ON ci.SessionID   = s.SessionID
       JOIN FACULTY f           ON sec.FacultyID  = f.FacultyID
       WHERE sr.StudentID = :sid
       ORDER BY s.StartDate DESC, c.CourseCode`,
      { sid: req.params.studentId }
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
