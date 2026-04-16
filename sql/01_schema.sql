-- =============================================================
-- Student Attendance & Registration System
-- File: 01_schema.sql
-- Oracle SQL 21c
-- =============================================================

-- Drop tables in reverse dependency order (if re-running)
BEGIN
  FOR t IN (
    SELECT table_name FROM user_tables
    WHERE table_name IN (
      'ADMISSION_DROP_LOG','ATTENDANCE','STUDENT_REGISTRATIONS',
      'BATCHES','SECTIONS','COURSE_INSTANCES','FACULTY',
      'STUDENTS','COURSES','SESSIONS','ADMINS'
    )
  ) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
  END LOOP;
END;
/

-- =============================================================
-- 1. SESSIONS
-- =============================================================
CREATE TABLE SESSIONS (
    SessionID       NUMBER(10)      CONSTRAINT PK_SESSIONS PRIMARY KEY,
    SessionName     VARCHAR2(100)   NOT NULL,
    AcademicYear    VARCHAR2(9)     NOT NULL,       -- e.g. 2024-2025
    StartDate       DATE            NOT NULL,
    EndDate         DATE            NOT NULL,
    IsActive        CHAR(1)         DEFAULT 'Y'
        CONSTRAINT CHK_SESSION_ACTIVE CHECK (IsActive IN ('Y','N')),
    CONSTRAINT CHK_SESSION_DATES CHECK (EndDate > StartDate)
)
STORAGE (INITIAL 64K NEXT 64K);


-- =============================================================
-- 2. FACULTY
-- =============================================================
CREATE TABLE FACULTY (
    FacultyID       NUMBER(10)      CONSTRAINT PK_FACULTY PRIMARY KEY,
    Name            VARCHAR2(150)   NOT NULL,
    Email           VARCHAR2(200)   NOT NULL
        CONSTRAINT UQ_FACULTY_EMAIL UNIQUE,
    Phone           VARCHAR2(15),
    Department      VARCHAR2(100)   NOT NULL,
    Designation     VARCHAR2(100)   DEFAULT 'Assistant Professor'
        CONSTRAINT CHK_FACULTY_DESIG CHECK (Designation IN (
            'Professor','Associate Professor','Assistant Professor','Lecturer'
        )),
    Password        VARCHAR2(100)   DEFAULT 'pass123'
)
STORAGE (INITIAL 64K NEXT 64K);

-- =============================================================
-- 2b. ADMINS
-- =============================================================
CREATE TABLE ADMINS (
    Name            VARCHAR2(150)   NOT NULL,
    Email           VARCHAR2(200)   NOT NULL
        CONSTRAINT UQ_ADMINS_EMAIL UNIQUE,
    Password        VARCHAR2(100)   DEFAULT 'pass123'
)
STORAGE (INITIAL 64K NEXT 64K);


-- =============================================================
-- 3. COURSES
-- =============================================================
CREATE TABLE COURSES (
    CourseID        NUMBER(10)      CONSTRAINT PK_COURSES PRIMARY KEY,
    CourseCode      VARCHAR2(20)    NOT NULL
        CONSTRAINT UQ_COURSE_CODE UNIQUE,
    CourseName      VARCHAR2(200)   NOT NULL,
    Credits         NUMBER(2)       NOT NULL
        CONSTRAINT CHK_CREDITS CHECK (Credits BETWEEN 1 AND 6),
    Department      VARCHAR2(100)   NOT NULL,
    CourseLevel     VARCHAR2(10)    NOT NULL
        CONSTRAINT CHK_COURSE_LEVEL CHECK (CourseLevel IN ('UG','PG','BOTH')),
    SemesterType    VARCHAR2(6)     DEFAULT 'Both'
        CONSTRAINT CHK_COURSE_SEM_TYPE CHECK (SemesterType IN ('Odd','Even','Both')),
    CourseCategory  VARCHAR2(5)     NOT NULL
        CONSTRAINT CHK_COURSE_CAT CHECK (CourseCategory IN ('DC','DE','OC','HM')),
    RecommendedYear NUMBER(1)       NOT NULL
        CONSTRAINT CHK_COURSE_YEAR CHECK (RecommendedYear BETWEEN 1 AND 4)
)
STORAGE (INITIAL 64K NEXT 64K);


-- =============================================================
-- 4. STUDENTS
-- =============================================================
CREATE TABLE STUDENTS (
    StudentID       NUMBER(10)      CONSTRAINT PK_STUDENTS PRIMARY KEY,
    RollNumber      VARCHAR2(20)    NOT NULL CONSTRAINT UQ_STUDENT_ROLL UNIQUE,
    Password        VARCHAR2(100)   DEFAULT 'pass123',
    Name            VARCHAR2(150)   NOT NULL,
    Email           VARCHAR2(200)   NOT NULL
        CONSTRAINT UQ_STUDENT_EMAIL UNIQUE,
    Phone           VARCHAR2(15),
    DOB             DATE            NOT NULL,
    Branch          VARCHAR2(10)    NOT NULL
        CONSTRAINT CHK_STUDENT_BRANCH CHECK (Branch IN ('CSE','ECE','EEE','MEC')),
    BatchYear       NUMBER(4)       NOT NULL,
    CurrentYear     NUMBER(1)       NOT NULL
        CONSTRAINT CHK_STUDENT_YEAR CHECK (CurrentYear BETWEEN 1 AND 4),
    ProgramLevel    VARCHAR2(10)    DEFAULT 'UG' NOT NULL
        CONSTRAINT CHK_STUDENT_LEVEL CHECK (ProgramLevel IN ('UG','PG')),
    AdmissionDate   DATE            DEFAULT SYSDATE NOT NULL,
    Status          VARCHAR2(10)    DEFAULT 'Active'
        CONSTRAINT CHK_STUDENT_STATUS CHECK (Status IN ('Active','Dropped','Graduated'))
)
STORAGE (INITIAL 64K NEXT 64K);


-- =============================================================
-- 5. COURSE_INSTANCES
-- (One Course × One Session = one Course Instance)
-- =============================================================
CREATE TABLE COURSE_INSTANCES (
    InstanceID      NUMBER(10)      CONSTRAINT PK_COURSE_INSTANCES PRIMARY KEY,
    CourseID        NUMBER(10)      NOT NULL
        CONSTRAINT FK_CI_COURSE REFERENCES COURSES(CourseID),
    SessionID       NUMBER(10)      NOT NULL
        CONSTRAINT FK_CI_SESSION REFERENCES SESSIONS(SessionID),
    MaxCapacity     NUMBER(5)       DEFAULT 120
        CONSTRAINT CHK_CI_CAPACITY CHECK (MaxCapacity > 0),
    CONSTRAINT UQ_CI_COURSE_SESSION UNIQUE (CourseID, SessionID)
)
STORAGE (INITIAL 64K NEXT 64K);


-- =============================================================
-- 6. SECTIONS
-- (One Course Instance → multiple sections; each section
--  has exactly 1 Faculty Coordinator; max 2 daily time slots)
-- =============================================================
CREATE TABLE SECTIONS (
    SectionID       NUMBER(10)      CONSTRAINT PK_SECTIONS PRIMARY KEY,
    InstanceID      NUMBER(10)      NOT NULL
        CONSTRAINT FK_SEC_INSTANCE REFERENCES COURSE_INSTANCES(InstanceID),
    SectionName     VARCHAR2(10)    NOT NULL,           -- e.g. A, B, C
    FacultyID       NUMBER(10)      NOT NULL
        CONSTRAINT FK_SEC_FACULTY REFERENCES FACULTY(FacultyID),
    Room            VARCHAR2(50),
    Slot1           VARCHAR2(50),                       -- e.g. 09:00-10:30
    Slot2           VARCHAR2(50),                       -- optional 2nd slot same day
    EnrolledCount   NUMBER(4)       DEFAULT 0,
    MaxStudents     NUMBER(4)       DEFAULT 60
        CONSTRAINT CHK_SEC_MAXSTUDENTS CHECK (MaxStudents > 0),
    CONSTRAINT UQ_SECTION_NAME UNIQUE (InstanceID, SectionName)
)
STORAGE (INITIAL 64K NEXT 64K);


-- =============================================================
-- 7. BATCHES
-- (One Course → multiple batches; each batch has a coordinator)
-- =============================================================
CREATE TABLE BATCHES (
    BatchID         NUMBER(10)      CONSTRAINT PK_BATCHES PRIMARY KEY,
    BatchName       VARCHAR2(100)   NOT NULL,
    CourseID        NUMBER(10)      NOT NULL
        CONSTRAINT FK_BATCH_COURSE REFERENCES COURSES(CourseID),
    SessionID       NUMBER(10)      NOT NULL
        CONSTRAINT FK_BATCH_SESSION REFERENCES SESSIONS(SessionID),
    CoordinatorID   NUMBER(10)      NOT NULL
        CONSTRAINT FK_BATCH_COORD REFERENCES FACULTY(FacultyID)
)
STORAGE (INITIAL 64K NEXT 64K);


-- =============================================================
-- 8. STUDENT_REGISTRATIONS
-- (Attendance is a relationship between Student ↔ Section)
-- =============================================================
CREATE TABLE STUDENT_REGISTRATIONS (
    RegistrationID  NUMBER(10)      CONSTRAINT PK_REGISTRATIONS PRIMARY KEY,
    StudentID       NUMBER(10)      NOT NULL
        CONSTRAINT FK_REG_STUDENT REFERENCES STUDENTS(StudentID),
    SectionID       NUMBER(10)      NOT NULL
        CONSTRAINT FK_REG_SECTION REFERENCES SECTIONS(SectionID),
    RegistrationDate DATE           DEFAULT SYSDATE NOT NULL,
    RegStatus       VARCHAR2(15)    DEFAULT 'Pending'
        CONSTRAINT CHK_REG_STATUS CHECK (RegStatus IN ('Pending','Registered','Dropped','Waitlisted','Rejected')),
    Grade           VARCHAR2(3)     NULL
        CONSTRAINT CHK_REG_GRADE CHECK (Grade IN ('AA','AB','BB','BC','CC','CD','DD','W','FF','LL') OR Grade IS NULL),
    CONSTRAINT UQ_STUDENT_SECTION UNIQUE (StudentID, SectionID)
)
STORAGE (INITIAL 64K NEXT 64K);


-- =============================================================
-- 9. ATTENDANCE
-- (Student ↔ Section relationship; up to 2 slots per day)
-- =============================================================
CREATE TABLE ATTENDANCE (
    AttendanceID    NUMBER(10)      CONSTRAINT PK_ATTENDANCE PRIMARY KEY,
    StudentID       NUMBER(10)      NOT NULL
        CONSTRAINT FK_ATT_STUDENT REFERENCES STUDENTS(StudentID),
    SectionID       NUMBER(10)      NOT NULL
        CONSTRAINT FK_ATT_SECTION REFERENCES SECTIONS(SectionID),
    AttendanceDate  DATE            NOT NULL,
    SlotNumber      NUMBER(1)       NOT NULL
        CONSTRAINT CHK_ATT_SLOT CHECK (SlotNumber IN (1,2)),
    AttStatus       VARCHAR2(10)    DEFAULT 'Absent'
        CONSTRAINT CHK_ATT_STATUS CHECK (AttStatus IN ('Present','Absent','Late')),
    MarkedBy        NUMBER(10)
        CONSTRAINT FK_ATT_FACULTY REFERENCES FACULTY(FacultyID),
    MarkedAt        TIMESTAMP       DEFAULT SYSTIMESTAMP,
    CONSTRAINT UQ_ATTENDANCE UNIQUE (StudentID, SectionID, AttendanceDate, SlotNumber)
)
STORAGE (INITIAL 64K NEXT 64K);


-- =============================================================
-- 10. ADMISSION_DROP_LOG
-- (Audit log for student admission / drop events)
-- =============================================================
CREATE TABLE ADMISSION_DROP_LOG (
    LogID           NUMBER(10)      CONSTRAINT PK_LOG PRIMARY KEY,
    StudentID       NUMBER(10)      NOT NULL
        CONSTRAINT FK_LOG_STUDENT REFERENCES STUDENTS(StudentID),
    Action          VARCHAR2(10)    NOT NULL
        CONSTRAINT CHK_LOG_ACTION CHECK (Action IN ('Admitted','Dropped')),
    ActionDate      DATE            DEFAULT SYSDATE NOT NULL,
    Reason          VARCHAR2(500),
    PerformedBy     VARCHAR2(100)
)
STORAGE (INITIAL 64K NEXT 64K);

COMMIT;

PROMPT Schema created successfully.
