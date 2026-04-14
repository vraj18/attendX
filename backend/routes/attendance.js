// =============================================================
// routes/attendance.js
// POST /api/attendance/mark        — mark one student
// POST /api/attendance/bulk        — bulk init section attendance
// GET  /api/attendance/section/:id — attendance for a section
// GET  /api/attendance/student/:id — student's full attendance
// GET  /api/attendance/report/:id  — attendance % per student in section
// =============================================================
const express  = require('express');
const oracledb = require('oracledb');
const db       = require('../db');
const router   = express.Router();

// POST /api/attendance/mark
router.post('/mark', async (req, res) => {
  const { studentId, sectionId, date, slot, status, markedBy } = req.body;
  try {
    const result = await db.execute(
      `BEGIN
         PKG_ATTENDANCE.SP_MARK_ATTENDANCE(
           :sid, :secid, TO_DATE(:dt,'YYYY-MM-DD'), :slot, :status, :by, :msg
         );
       END;`,
      {
        sid: studentId, secid: sectionId, dt: date,
        slot, status, by: markedBy,
        msg: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 500 }
      }
    );
    const msg = result.outBinds.msg;
    res.json({ success: msg.startsWith('SUCCESS'), message: msg });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/attendance/bulk
router.post('/bulk', async (req, res) => {
  const { sectionId, date, slot, defaultStatus, markedBy } = req.body;
  try {
    const result = await db.execute(
      `BEGIN
         PKG_ATTENDANCE.SP_BULK_MARK(:secid, TO_DATE(:dt,'YYYY-MM-DD'), :slot, :defstatus, :by, :msg);
       END;`,
      {
        secid: sectionId, dt: date, slot,
        defstatus: defaultStatus || 'Absent', by: markedBy,
        msg: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 500 }
      }
    );
    const msg = result.outBinds.msg;
    res.json({ success: msg.startsWith('SUCCESS'), message: msg });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/attendance/section/:id?date=YYYY-MM-DD&slot=1
router.get('/section/:id', async (req, res) => {
  const { date, slot } = req.query;
  try {
    let sql = `
      SELECT a.AttendanceID, a.StudentID, st.Name AS StudentName,
             a.AttendanceDate, a.SlotNumber, a.AttStatus,
             a.MarkedAt, f.Name AS MarkedByName
      FROM ATTENDANCE a
      JOIN STUDENTS st  ON a.StudentID  = st.StudentID
      LEFT JOIN FACULTY f ON a.MarkedBy = f.FacultyID
      WHERE a.SectionID = :secid`;
    const binds = { secid: req.params.id };

    if (date) { sql += ` AND TRUNC(a.AttendanceDate) = TO_DATE(:dt,'YYYY-MM-DD')`; binds.dt = date; }
    if (slot) { sql += ` AND a.SlotNumber = :slot`; binds.slot = slot; }
    sql += ` ORDER BY a.AttendanceDate, st.Name`;

    const result = await db.execute(sql, binds);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/attendance/student/:id
router.get('/student/:id', async (req, res) => {
  try {
    const result = await db.execute(
      `SELECT a.AttendanceDate, a.SlotNumber, a.AttStatus,
              c.CourseCode, c.CourseName, sec.SectionName, s.SessionName
       FROM ATTENDANCE a
       JOIN SECTIONS sec        ON a.SectionID   = sec.SectionID
       JOIN COURSE_INSTANCES ci ON sec.InstanceID = ci.InstanceID
       JOIN COURSES c           ON ci.CourseID    = c.CourseID
       JOIN SESSIONS s          ON ci.SessionID   = s.SessionID
       WHERE a.StudentID = :id
       ORDER BY a.AttendanceDate DESC, a.SlotNumber`,
      [req.params.id]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/attendance/report/:sectionId — per-student summary
router.get('/report/:sectionId', async (req, res) => {
  try {
    const result = await db.execute(
      `SELECT st.StudentID, st.Name AS StudentName,
              COUNT(a.AttendanceID)                                        AS Total,
              SUM(CASE WHEN a.AttStatus IN ('Present','Late') THEN 1 ELSE 0 END) AS Present,
              ROUND(SUM(CASE WHEN a.AttStatus IN ('Present','Late') THEN 1 ELSE 0 END)
                    * 100.0 / NULLIF(COUNT(a.AttendanceID),0), 2)         AS Percentage
       FROM STUDENT_REGISTRATIONS sr
       JOIN STUDENTS st  ON sr.StudentID  = st.StudentID
       LEFT JOIN ATTENDANCE a  ON a.StudentID = sr.StudentID
                              AND a.SectionID = sr.SectionID
       WHERE sr.SectionID = :secid
         AND sr.RegStatus = 'Registered'
       GROUP BY st.StudentID, st.Name
       ORDER BY st.Name`,
      [req.params.sectionId]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/attendance/dashboard/stats?role=student&id=100
router.get('/dashboard/stats', async (req, res) => {
  const { role, id } = req.query;
  try {
    if (role === 'student' && id) {
      const activeCourses = await db.execute(
        `SELECT COUNT(*) AS CNT FROM STUDENT_REGISTRATIONS WHERE StudentID = :id AND RegStatus = 'Registered'`,
        [id]
      );
      const pendingRegs = await db.execute(
        `SELECT COUNT(*) AS CNT FROM STUDENT_REGISTRATIONS WHERE StudentID = :id AND RegStatus = 'Pending'`,
        [id]
      );
      const attStats = await db.execute(
        `SELECT COUNT(*) AS Total, 
                SUM(CASE WHEN AttStatus IN ('Present','Late') THEN 1 ELSE 0 END) AS Present
         FROM ATTENDANCE WHERE StudentID = :id`,
        [id]
      );
      
      const total = attStats.rows[0].TOTAL || 0;
      const present = attStats.rows[0].PRESENT || 0;
      const percent = total > 0 ? Math.round((present / total) * 100) : 0;

      res.json({
        success: true,
        data: {
          activeCourses: activeCourses.rows[0].CNT,
          attendancePercent: percent,
          totalSessions: total,
          pendingRegs: pendingRegs.rows[0].CNT
        }
      });
    } else if (role === 'admin' && id) {
      const studentsUnderMe = await db.execute(
        `SELECT COUNT(DISTINCT StudentID) AS CNT 
         FROM STUDENT_REGISTRATIONS sr
         JOIN SECTIONS s ON sr.SectionID = s.SectionID
         WHERE s.FacultyID = :id AND sr.RegStatus = 'Registered'`,
        [id]
      );
      const mySections = await db.execute(
        `SELECT COUNT(*) AS CNT FROM SECTIONS WHERE FacultyID = :id`,
        [id]
      );
      const todayAtt = await db.execute(
        `SELECT COUNT(*) AS CNT 
         FROM ATTENDANCE a
         JOIN SECTIONS s ON a.SectionID = s.SectionID
         WHERE s.FacultyID = :id AND TRUNC(a.MarkedAt) = TRUNC(SYSDATE)`,
        [id]
      );
      const pendingApprovals = await db.execute(
        `SELECT COUNT(*) AS CNT 
         FROM STUDENT_REGISTRATIONS sr
         JOIN SECTIONS s ON sr.SectionID = s.SectionID
         WHERE s.FacultyID = :id AND sr.RegStatus = 'Pending'`,
        [id]
      );

      res.json({
        success: true,
        data: {
          studentsUnderMe: studentsUnderMe.rows[0].CNT,
          mySections: mySections.rows[0].CNT,
          todayAttendance: todayAtt.rows[0].CNT,
          pendingApprovals: pendingApprovals.rows[0].CNT
        }
      });
    } else {
      // Default Global Stats
      const students = await db.execute(`SELECT COUNT(*) AS CNT FROM STUDENTS WHERE Status='Active'`);
      const sessions = await db.execute(`SELECT COUNT(*) AS CNT FROM SESSIONS WHERE IsActive='Y'`);
      const regs     = await db.execute(`SELECT COUNT(*) AS CNT FROM STUDENT_REGISTRATIONS WHERE RegStatus='Registered'`);
      const att      = await db.execute(`SELECT COUNT(*) AS CNT FROM ATTENDANCE WHERE TRUNC(MarkedAt)=TRUNC(SYSDATE)`);
      res.json({
        success: true,
        data: {
          activeStudents:    students.rows[0].CNT,
          activeSessions:    sessions.rows[0].CNT,
          totalRegistrations: regs.rows[0].CNT,
          todayAttendance:   att.rows[0].CNT
        }
      });
    }
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
