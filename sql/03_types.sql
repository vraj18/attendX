-- =============================================================
-- Student Attendance & Registration System
-- File: 03_types.sql
-- Collection / Object types for PL/SQL
-- =============================================================

-- Drop existing types if re-running
BEGIN
  EXECUTE IMMEDIATE 'DROP TYPE T_COURSE_INSTANCE_TABLE FORCE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TYPE T_COURSE_INSTANCE_ROW FORCE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- -------------------------------------------------------
-- Row type: holds a single course instance result
-- -------------------------------------------------------
CREATE OR REPLACE TYPE T_COURSE_INSTANCE_ROW AS OBJECT (
    InstanceID      NUMBER(10),
    CourseID        NUMBER(10),
    CourseCode      VARCHAR2(20),
    CourseName      VARCHAR2(200),
    CourseLevel     VARCHAR2(10),
    Credits         NUMBER(2),
    SessionID       NUMBER(10),
    SessionName     VARCHAR2(100),
    SectionID       NUMBER(10),
    SectionName     VARCHAR2(10),
    FacultyName     VARCHAR2(150),
    Room            VARCHAR2(50),
    Slot1           VARCHAR2(50),
    Slot2           VARCHAR2(50),
    RegStatus       VARCHAR2(15)
);
/

-- -------------------------------------------------------
-- Table type: collection of T_COURSE_INSTANCE_ROW
-- -------------------------------------------------------
CREATE OR REPLACE TYPE T_COURSE_INSTANCE_TABLE AS TABLE OF T_COURSE_INSTANCE_ROW;
/

PROMPT Types created successfully.
