const express = require('express');
const db = require('../db');
const router = express.Router();

// POST /api/auth/login
router.post('/login', async (req, res) => {
  const { userId, role } = req.body;
  try {
    if (role === 'student') {
      const result = await db.execute(
        `SELECT StudentID as Id, Name, Email FROM STUDENTS WHERE StudentID = :id`,
        [parseInt(userId)]
      );
      if (result.rows.length > 0) {
        res.json({ success: true, user: { ...result.rows[0], Role: 'student' } });
      } else {
        res.status(401).json({ success: false, message: 'Student ID not found' });
      }
    } else if (role === 'admin') {
      const result = await db.execute(
        `SELECT FacultyID as Id, Name, Email, Designation FROM FACULTY WHERE FacultyID = :id`,
        [parseInt(userId)]
      );
      if (result.rows.length > 0) {
        res.json({ success: true, user: { ...result.rows[0], Role: 'admin' } });
      } else {
        res.status(401).json({ success: false, message: 'Faculty Admin ID not found' });
      }
    } else {
      res.status(400).json({ success: false, message: 'Invalid role specified' });
    }
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
