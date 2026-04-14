// =============================================================
// server.js — Express Application Entry Point
// =============================================================
const express = require('express');
const cors    = require('cors');
const path    = require('path');
const db      = require('./db');

const studentsRouter     = require('./routes/students');
const registrationRouter = require('./routes/registration');
const attendanceRouter   = require('./routes/attendance');
const authRouter         = require('./routes/auth');

const app  = express();
const PORT = process.env.PORT || 3000;

// ── Middleware ─────────────────────────────────────────────
app.use(cors());
app.use(express.json());

// Serve frontend static files
app.use(express.static(path.join(__dirname, '..', 'frontend')));

// ── API Routes ─────────────────────────────────────────────
app.use('/api/students',     studentsRouter);
app.use('/api/registration', registrationRouter);
app.use('/api/attendance',   attendanceRouter);
app.use('/api/auth',         authRouter);

// Health check
app.get('/api/health', (req, res) => res.json({ status: 'ok', timestamp: new Date() }));

// ── Global error handler ───────────────────────────────────
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ success: false, message: err.message });
});

// ── Start ──────────────────────────────────────────────────
(async () => {
  try {
    await db.init();
    app.listen(PORT, () => {
      console.log(`🚀  Server running at http://localhost:${PORT}`);
    });
  } catch (err) {
    console.error('Failed to start server:', err);
    process.exit(1);
  }
})();
