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
      `SELECT StudentID, RollNumber, Name, Email, Phone,
              Branch AS Department, BatchYear, CurrentYear, AdmissionDate, Status, ProgramLevel
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
      `SELECT StudentID, RollNumber, Name, Email, Phone, 
              Branch AS Department, BatchYear, CurrentYear, 
              AdmissionDate, Status, ProgramLevel
       FROM STUDENTS 
       WHERE RollNumber = :id OR CAST(StudentID AS VARCHAR2(20)) = :id`,
      { id: req.params.id }
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
    const { name, email, phone, dob, programLevel, department, performedBy } = req.body;
    try {
      // Use native Date object for better type safety with Oracle
      const dobDate = dob ? new Date(dob) : null;
      
      const result = await db.execute(
        `BEGIN
           PKG_REGISTRATION.SP_ADMIT_STUDENT(
             p_Name         => :name,
             p_Email        => :email,
             p_Phone        => :phone,
             p_DOB          => :dobDate,
             p_Branch       => :branch,
             p_BatchYear    => :batch,
             p_CurrentYear  => :curYear,
             p_ProgramLevel => :progLevel,
             p_PerformedBy  => :by,
             p_StudentID    => :sid,
             p_RollNumber   => :roll,
             p_Message      => :msg
           );
         END;`,
        {
          name, email, phone, dobDate,
          branch: req.body.branch, 
          batch: Number(req.body.batchYear), 
          curYear: Number(req.body.currentYear),
          progLevel: programLevel || 'UG',
          by: performedBy || 'webui',
          sid: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
          roll: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 50 },
          msg: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 500 }
        }
      );
    const msg = result.outBinds.msg;
    const sid = result.outBinds.sid;
    const roll = result.outBinds.roll;
    const ok  = msg.startsWith('SUCCESS') || !msg.includes('ERROR');
    res.status(ok ? 200 : 400).json({ success: ok, message: msg, studentId: sid, rollNumber: roll });
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
