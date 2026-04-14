# Student Attendance & Registration System
**Oracle SQL 21c + PL/SQL + Node.js + Vanilla JS**

---

## 📁 Project Structure

```
dbms/
├── sql/
│   ├── 01_schema.sql           ← Tables + Constraints + Storage Clauses
│   ├── 02_sequences.sql        ← Auto-increment sequences
│   ├── 03_types.sql            ← T_COURSE_INSTANCE_TABLE (collection type)
│   ├── 04_triggers.sql         ← TRG_COURSE_LEVEL_UPDATE, TRG_STUDENT_ADMISSION_STATUS
│   ├── 05_functions.sql        ← FN_GET_COURSE_INSTANCES (pipelined table function)
│   ├── 06_pkg_registration.sql ← PKG_REGISTRATION package
│   ├── 07_pkg_attendance.sql   ← PKG_ATTENDANCE package
│   └── 08_sample_data.sql      ← Seed data (8 students, 8 courses, 10 sections…)
├── backend/
│   ├── server.js               ← Express app entry
│   ├── db.js                   ← Oracle connection pool (oracledb)
│   └── routes/
│       ├── students.js
│       ├── registration.js
│       └── attendance.js
└── frontend/
    ├── index.html              ← Dashboard
    ├── registration.html       ← Register / Admit / Drop
    ├── attendance.html         ← Mark Attendance
    ├── profile.html            ← Student Profile
    ├── report.html             ← Attendance Report
    ├── css/style.css
    └── js/app.js
```

---

## 🚀 Setup Instructions

### Step 1 — Run SQL Scripts in Oracle SQL*Plus / SQL Developer

Run the files **in order**:

```sql
@sql/01_schema.sql
@sql/02_sequences.sql
@sql/03_types.sql
@sql/04_triggers.sql
@sql/05_functions.sql
@sql/06_pkg_registration.sql
@sql/07_pkg_attendance.sql
@sql/08_sample_data.sql
```

### Step 2 — Configure Oracle Credentials

Edit `backend/db.js`:
```js
const DB_CONFIG = {
  user:          'system',       // your Oracle user
  password:      'oracle',       // your Oracle password
  connectString: 'localhost/XE', // your Oracle SID
};
```

### Step 3 — Start Backend

```bash
cd backend
npm install     # already done
npm start       # or: npm run dev
```

Server runs at: **http://localhost:3000**

### Step 4 — Open Frontend

Open `frontend/index.html` directly in a browser OR access via:
**http://localhost:3000**

---

## 📌 Key Business Rules Implemented

| Rule | Implementation |
|------|---------------|
| Course level auto-update before session | `TRG_COURSE_LEVEL_UPDATE` → fires on `Sessions.IsActive = 'Y'` |
| Student drop updates table | `TRG_STUDENT_ADMISSION_STATUS` → fires on `ADMISSION_DROP_LOG` INSERT |
| FN returning multiple course instances | `FN_GET_COURSE_INSTANCES(studentId, sessionId)` → returns `T_COURSE_INSTANCE_TABLE` |
| Registration validation | `PKG_REGISTRATION.FN_VALIDATE_REGISTRATION` (private function, 7 checks) |
| Attendance stored via package | `PKG_ATTENDANCE.SP_MARK_ATTENDANCE` + `SP_BULK_MARK` |

---

## 🗄️ Data Estimation (1 Session)

| Table | Rows | Rationale |
|-------|------|-----------|
| STUDENTS | ~2,000 | College enrollment |
| COURSES | ~80 | Offered per session |
| SESSIONS | ~2 | Odd + Even semester |
| COURSE_INSTANCES | ~80 | 1 per course/session |
| SECTIONS | ~200 | 2–3 per instance |
| FACULTY | ~150 | Teaching staff |
| BATCHES | ~50 | Year × Branch |
| STUDENT_REGISTRATIONS | ~10,000 | ~5 courses/student |
| ATTENDANCE | ~150,000 | 10k regs × 15 days × 1-2 slots |
| ADMISSION_DROP_LOG | ~200 | ~10% students with changes |

---

## 🎨 UI Features

- **Dark glassmorphism** design with purple/blue gradient
- **5 pages**: Dashboard, Registration, Attendance, Profile, Report
- Animated stat counters, progress bars, filterable tables
- Per-student P/A/L attendance toggles with bulk save
- Student profile with course-wise attendance % and risk status
- Toast notifications for all API responses
