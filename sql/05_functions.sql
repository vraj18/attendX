-- =============================================================
-- Student Attendance & Registration System
-- File: 05_functions.sql
-- Function: FN_GET_COURSE_INSTANCES
--   Input : p_StudentID  NUMBER, p_SessionID NUMBER
--   Return: T_COURSE_INSTANCE_TABLE  (collection / table type)
-- Business Rule: Returns all course instances (with section
--   details) that a student is registered in for a given
--   session.
-- =============================================================

CREATE OR REPLACE FUNCTION FN_GET_COURSE_INSTANCES (
    p_StudentID  IN NUMBER,
    p_SessionID  IN NUMBER
)
RETURN T_COURSE_INSTANCE_TABLE
PIPELINED                       -- pipeline rows for efficiency
AS
    -- Cursor: join all relevant tables
    CURSOR c_instances IS
        SELECT
            ci.InstanceID,
            c.CourseID,
            c.CourseCode,
            c.CourseName,
            c.CourseLevel,
            c.Credits,
            s.SessionID,
            s.SessionName,
            sec.SectionID,
            sec.SectionName,
            f.Name        AS FacultyName,
            sec.Room,
            sec.Slot1,
            sec.Slot2,
            sr.RegStatus
        FROM
            STUDENT_REGISTRATIONS  sr
            JOIN SECTIONS          sec ON sr.SectionID   = sec.SectionID
            JOIN COURSE_INSTANCES  ci  ON sec.InstanceID = ci.InstanceID
            JOIN COURSES           c   ON ci.CourseID    = c.CourseID
            JOIN SESSIONS          s   ON ci.SessionID   = s.SessionID
            JOIN FACULTY           f   ON sec.FacultyID  = f.FacultyID
        WHERE
            sr.StudentID  = p_StudentID
            AND ci.SessionID  = p_SessionID
            AND sr.RegStatus != 'Dropped'     -- exclude dropped courses
        ORDER BY c.CourseName;

    v_row  T_COURSE_INSTANCE_ROW;
BEGIN
    -- Validate student exists
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM STUDENTS WHERE StudentID = p_StudentID;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Student ID ' || p_StudentID || ' not found.');
        END IF;
    END;

    -- Validate session exists
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM SESSIONS WHERE SessionID = p_SessionID;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Session ID ' || p_SessionID || ' not found.');
        END IF;
    END;

    -- Stream results
    FOR rec IN c_instances LOOP
        v_row := T_COURSE_INSTANCE_ROW(
            rec.InstanceID,
            rec.CourseID,
            rec.CourseCode,
            rec.CourseName,
            rec.CourseLevel,
            rec.Credits,
            rec.SessionID,
            rec.SessionName,
            rec.SectionID,
            rec.SectionName,
            rec.FacultyName,
            rec.Room,
            rec.Slot1,
            rec.Slot2,
            rec.RegStatus
        );
        PIPE ROW(v_row);
    END LOOP;

    RETURN;
END FN_GET_COURSE_INSTANCES;
/

-- Usage example:
-- SELECT * FROM TABLE(FN_GET_COURSE_INSTANCES(1001, 1));

PROMPT Function FN_GET_COURSE_INSTANCES created successfully.
