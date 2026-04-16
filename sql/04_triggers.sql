-- =============================================================
-- Student Attendance & Registration System
-- File: 04_triggers.sql
-- Triggers:
--   1. TRG_COURSE_LEVEL_UPDATE  — auto-updates student course level
--      BEFORE a session becomes active
--   2. TRG_STUDENT_ADMISSION_STATUS — syncs Students.Status
--      when an Admission_Drop_Log row is inserted
-- =============================================================

-- -------------------------------------------------------
-- Trigger 1: Update student ProgramLevel BEFORE session activates
-- Business Rule: Before the start of a session, the course
-- level for students should be automatically updated.
-- Logic: When a SESSION row IsActive is set to 'Y', we
-- upgrade PG students (2+ years after admission) to reflect
-- correct program level so they can register for PG courses.
-- -------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_COURSE_LEVEL_UPDATE
BEFORE UPDATE OF IsActive ON SESSIONS
FOR EACH ROW
WHEN (NEW.IsActive = 'Y' AND OLD.IsActive = 'N')
BEGIN
    -- Update students who have been admitted >= 3 years
    -- to PG status (if currently UG and eligible)
    UPDATE STUDENTS
    SET ProgramLevel = 'PG'
    WHERE ProgramLevel = 'UG'
      AND Status       = 'Active'
      AND MONTHS_BETWEEN(:NEW.StartDate, AdmissionDate) >= 36;

    -- Log to server output for debugging
    DBMS_OUTPUT.PUT_LINE(
        'TRG_COURSE_LEVEL_UPDATE fired for Session: ' || :NEW.SessionName ||
        ' | Students updated to PG: ' || SQL%ROWCOUNT
    );
END;
/


-- -------------------------------------------------------
-- Trigger 2: Sync STUDENTS.Status when ADMISSION_DROP_LOG
--            gets a new row (AFTER INSERT)
-- Business Rule: Student table is updated based on
--                admission and drop information.
-- -------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_STUDENT_ADMISSION_STATUS
AFTER INSERT ON ADMISSION_DROP_LOG
FOR EACH ROW
BEGIN
    IF :NEW.Action = 'Dropped' THEN
        UPDATE STUDENTS
        SET    Status = 'Dropped'
        WHERE  StudentID = :NEW.StudentID;

        -- Also drop all pending registrations
        UPDATE STUDENT_REGISTRATIONS
        SET    RegStatus = 'Dropped'
        WHERE  StudentID  = :NEW.StudentID
          AND  RegStatus IN ('Registered', 'Waitlisted');

    ELSIF :NEW.Action = 'Admitted' THEN
        UPDATE STUDENTS
        SET    Status       = 'Active',
               AdmissionDate = :NEW.ActionDate
        WHERE  StudentID = :NEW.StudentID;
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        'TRG_STUDENT_ADMISSION_STATUS: StudentID=' || :NEW.StudentID ||
        ' Action=' || :NEW.Action
    );
END;
/


-- -------------------------------------------------------
-- Trigger 3: Maintain SECTIONS.EnrolledCount
-- Business Rule: Automatically sync the count when 
--                registrations are added, dropped or 
--                approved.
-- -------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_UPDATE_SECTION_ENROLLMENT
AFTER INSERT OR UPDATE OR DELETE ON STUDENT_REGISTRATIONS
FOR EACH ROW
BEGIN
    -- Handle Deletion or Status Change away from 'Registered'
    IF DELETING OR (UPDATING AND :OLD.RegStatus = 'Registered' AND :NEW.RegStatus != 'Registered') THEN
        UPDATE SECTIONS 
        SET    EnrolledCount = EnrolledCount - 1
        WHERE  SectionID = :OLD.SectionID;
    END IF;

    -- Handle Insertion or Status Change to 'Registered'
    IF INSERTING THEN
        IF :NEW.RegStatus = 'Registered' THEN
            UPDATE SECTIONS 
            SET    EnrolledCount = EnrolledCount + 1
            WHERE  SectionID = :NEW.SectionID;
        END IF;
    ELSIF UPDATING THEN
        IF :OLD.RegStatus != 'Registered' AND :NEW.RegStatus = 'Registered' THEN
            UPDATE SECTIONS 
            SET    EnrolledCount = EnrolledCount + 1
            WHERE  SectionID = :NEW.SectionID;
        END IF;
    END IF;
END;
/

PROMPT Triggers created successfully.
