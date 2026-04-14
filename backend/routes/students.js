// =============================================================
// routes/students.js
// GET  /api/students            — list all students
// GET  /api/students/:id        — get one student
// GET  /api/students/:id/courses/:sessionId — course instances
// POST /api/students/admit      — admit new student
// POST /api/students/drop       — drop student from institution
// =============================================================
const express = require('express');
const oracledb = require('oracledb');
const db = require('../db');
const router = express.Router();

// GET /api/students
router.get('/', async (req, res) => {
  try {
    const result = await db.execute(
      `SELECT StudentID, Name, Email, Phone, ProgramLevel,
              Department, AdmissionDate, Status
       FROM STUDENTS
       ORDER BY Name`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/students/:id
router.get('/:id', async (req, res) => {
  try {
    const result = await db.execute(
      `SELECT * FROM STUDENTS WHERE StudentID = :id`,
      [req.params.id]
    );
    if (!result.rows.length)
      return res.status(404).json({ success: false, message: 'Student not found' });
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/students/:id/courses/:sessionId — calls pipelined function
router.get('/:id/courses/:sessionId', async (req, res) => {
  try {
    const result = await db.execute(
      `SELECT * FROM TABLE(FN_GET_COURSE_INSTANCES(:sid, :sess))`,
      { sid: req.params.id, sess: req.params.sessionId }
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/students/admit
router.post('/admit', async (req, res) => {
  const { name, email, phone, dob, level, department, performedBy } = req.body;
  try {
    const result = await db.execute(
      `BEGIN
         PKG_REGISTRATION.SP_ADMIT_STUDENT(
           :name, :email, :phone, TO_DATE(:dob,'YYYY-MM-DD'),
           :level, :dept, :by, :sid, :msg
         );
       END;`,
      {
        name, email, phone, dob, level, dept: department, by: performedBy || 'webui',
        sid: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
        msg: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 500 }
      }
    );
    const msg = result.outBinds.msg;
    const sid = result.outBinds.sid;
    const ok  = msg.startsWith('SUCCESS');
    res.status(ok ? 200 : 400).json({ success: ok, message: msg, studentId: sid });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/students/drop
router.post('/drop', async (req, res) => {
  const { studentId, reason, performedBy } = req.body;
  try {
    const result = await db.execute(
      `BEGIN PKG_REGISTRATION.SP_DROP_STUDENT(:sid, :reason, :by, :msg); END;`,
      {
        sid: studentId, reason, by: performedBy || 'webui',
        msg: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 500 }
      }
    );
    const msg = result.outBinds.msg;
    res.json({ success: msg.startsWith('SUCCESS'), message: msg });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/students/sessions — list all sessions
router.get('/meta/sessions', async (req, res) => {
  try {
    const result = await db.execute(
      `SELECT SessionID, SessionName, AcademicYear, StartDate, EndDate, IsActive
       FROM SESSIONS ORDER BY StartDate DESC`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
