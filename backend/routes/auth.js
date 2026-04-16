const express = require('express');
const db = require('../db');
const router = express.Router();

// POST /api/auth/login
router.post('/login', async (req, res) => {
  const { userId, role } = req.body;
  try {
    if (role === 'student') {
      const result = await db.execute(
        `SELECT StudentID as Id, Name, Email, RollNumber, Branch, CurrentYear 
         FROM STUDENTS WHERE RollNumber = :id AND Password = :pass`,
        [userId, req.body.password]
      );
      if (result.rows.length > 0) {
        res.json({ success: true, user: { ...result.rows[0], Role: 'student' } });
      } else {
        res.status(401).json({ success: false, message: 'Invalid Roll Number or Password' });
      }
    } else if (role === 'faculty') {
      const result = await db.execute(
        `SELECT FacultyID as Id, Name, Email, Designation FROM FACULTY 
         WHERE FacultyID = :id AND Password = :pass`,
        [parseInt(userId), req.body.password]
      );
      if (result.rows.length > 0) {
        res.json({ success: true, user: { ...result.rows[0], Role: 'faculty' } });
      } else {
        res.status(401).json({ success: false, message: 'Invalid Faculty ID or Password' });
      }
    } else if (role === 'admin') {
      const result = await db.execute(
        `SELECT Name, Email FROM ADMINS 
         WHERE Email = :id AND Password = :pass`,
        [userId, req.body.password]
      );
      if (result.rows.length > 0) {
        // Admin ID is effectively their email for simple identification
        res.json({ success: true, user: { ...result.rows[0], Id: result.rows[0].EMAIL, Role: 'admin' } });
      } else {
        res.status(401).json({ success: false, message: 'Invalid Admin Credentials' });
      }
    } else {
      res.status(400).json({ success: false, message: 'Invalid role specified' });
    }
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
