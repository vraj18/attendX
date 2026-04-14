-- =============================================================
-- Student Attendance & Registration System
-- File: 07_pkg_attendance.sql
-- Package: PKG_ATTENDANCE
--   - SP_MARK_ATTENDANCE  : mark one student's attendance
--   - SP_BULK_MARK        : mark attendance for all students
--                           in a section for a date+slot
--   - FN_GET_PERCENTAGE   : returns attendance % for a student
--                           in a section
-- =============================================================

-- ====== PACKAGE SPECIFICATION ==============================
CREATE OR REPLACE PACKAGE PKG_ATTENDANCE AS

    -- Mark attendance for one student
    PROCEDURE SP_MARK_ATTENDANCE (
        p_StudentID     IN  NUMBER,
        p_SectionID     IN  NUMBER,
        p_Date          IN  DATE,
        p_Slot          IN  NUMBER,
        p_Status        IN  VARCHAR2,   -- 'Present','Absent','Late'
        p_MarkedBy      IN  NUMBER,     -- FacultyID
        p_Message       OUT VARCHAR2
    );

    -- Bulk mark attendance for all students in a section
    PROCEDURE SP_BULK_MARK (
        p_SectionID     IN  NUMBER,
        p_Date          IN  DATE,
        p_Slot          IN  NUMBER,
        p_DefaultStatus IN  VARCHAR2 DEFAULT 'Absent',
        p_MarkedBy      IN  NUMBER,
        p_Message       OUT VARCHAR2
    );

    -- Get attendance percentage
    FUNCTION FN_GET_PERCENTAGE (
        p_StudentID IN NUMBER,
        p_SectionID IN NUMBER
    ) RETURN NUMBER;

END PKG_ATTENDANCE;
/


-- ====== PACKAGE BODY =======================================
CREATE OR REPLACE PACKAGE BODY PKG_ATTENDANCE AS

    -- --------------------------------------------------------
    -- PRIVATE: Verify student is registered and active in section
    -- --------------------------------------------------------
    FUNCTION IS_VALID_REGISTRATION (
        p_StudentID IN NUMBER,
        p_SectionID IN NUMBER
    ) RETURN BOOLEAN AS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM   STUDENT_REGISTRATIONS
        WHERE  StudentID = p_StudentID
          AND  SectionID = p_SectionID
          AND  RegStatus = 'Registered';
        RETURN v_count > 0;
    END;


    -- --------------------------------------------------------
    -- PUBLIC: Mark attendance for one student
    -- --------------------------------------------------------
    PROCEDURE SP_MARK_ATTENDANCE (
        p_StudentID     IN  NUMBER,
        p_SectionID     IN  NUMBER,
        p_Date          IN  DATE,
        p_Slot          IN  NUMBER,
        p_Status        IN  VARCHAR2,
        p_MarkedBy      IN  NUMBER,
        p_Message       OUT VARCHAR2
    ) AS
        v_att_id NUMBER;
    BEGIN
        -- Validate registration
        IF NOT IS_VALID_REGISTRATION(p_StudentID, p_SectionID) THEN
            p_Message := 'ERROR: Student ' || p_StudentID ||
                         ' is not actively registered in section ' || p_SectionID;
            RETURN;
        END IF;

        -- Validate slot
        IF p_Slot NOT IN (1, 2) THEN
            p_Message := 'ERROR: SlotNumber must be 1 or 2.';
            RETURN;
        END IF;

        -- Validate status
        IF p_Status NOT IN ('Present', 'Absent', 'Late') THEN
            p_Message := 'ERROR: Status must be Present, Absent, or Late.';
            RETURN;
        END IF;

        -- Upsert attendance (MERGE)
        MERGE INTO ATTENDANCE a
        USING (SELECT p_StudentID AS sid,
                      p_SectionID AS secid,
                      TRUNC(p_Date) AS adate,
                      p_Slot AS slot
               FROM DUAL) src
        ON (a.StudentID = src.sid
            AND a.SectionID = src.secid
            AND TRUNC(a.AttendanceDate) = src.adate
            AND a.SlotNumber = src.slot)
        WHEN MATCHED THEN
            UPDATE SET AttStatus  = p_Status,
                       MarkedBy   = p_MarkedBy,
                       MarkedAt   = SYSTIMESTAMP
        WHEN NOT MATCHED THEN
            INSERT (AttendanceID, StudentID, SectionID,
                    AttendanceDate, SlotNumber, AttStatus,
                    MarkedBy, MarkedAt)
            VALUES (SEQ_ATTENDANCE.NEXTVAL, p_StudentID, p_SectionID,
                    TRUNC(p_Date), p_Slot, p_Status,
                    p_MarkedBy, SYSTIMESTAMP);

        COMMIT;
        p_Message := 'SUCCESS: Attendance marked as ' || p_Status ||
                     ' for StudentID=' || p_StudentID;

    EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        p_Message := 'EXCEPTION: ' || SQLERRM;
    END SP_MARK_ATTENDANCE;


    -- --------------------------------------------------------
    -- PUBLIC: Bulk-mark attendance for all registered students
    --         in a section (default to Absent, then faculty
    --         can update individual records to Present/Late)
    -- --------------------------------------------------------
    PROCEDURE SP_BULK_MARK (
        p_SectionID     IN  NUMBER,
        p_Date          IN  DATE,
        p_Slot          IN  NUMBER,
        p_DefaultStatus IN  VARCHAR2 DEFAULT 'Absent',
        p_MarkedBy      IN  NUMBER,
        p_Message       OUT VARCHAR2
    ) AS
        v_count  NUMBER := 0;
        v_msg    VARCHAR2(200);
    BEGIN
        FOR rec IN (
            SELECT StudentID FROM STUDENT_REGISTRATIONS
            WHERE  SectionID = p_SectionID
              AND  RegStatus  = 'Registered'
        ) LOOP
            SP_MARK_ATTENDANCE(
                rec.StudentID, p_SectionID,
                p_Date, p_Slot, p_DefaultStatus,
                p_MarkedBy, v_msg
            );
            v_count := v_count + 1;
        END LOOP;

        COMMIT;
        p_Message := 'SUCCESS: Bulk attendance initialized for ' || v_count ||
                     ' students in SectionID=' || p_SectionID;

    EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        p_Message := 'EXCEPTION: ' || SQLERRM;
    END SP_BULK_MARK;


    -- --------------------------------------------------------
    -- PUBLIC: Calculate attendance % for student in a section
    -- --------------------------------------------------------
    FUNCTION FN_GET_PERCENTAGE (
        p_StudentID IN NUMBER,
        p_SectionID IN NUMBER
    ) RETURN NUMBER AS
        v_total   NUMBER;
        v_present NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO   v_total
        FROM   ATTENDANCE
        WHERE  StudentID  = p_StudentID
          AND  SectionID  = p_SectionID;

        IF v_total = 0 THEN
            RETURN 0;
        END IF;

        SELECT COUNT(*)
        INTO   v_present
        FROM   ATTENDANCE
        WHERE  StudentID  = p_StudentID
          AND  SectionID  = p_SectionID
          AND  AttStatus IN ('Present', 'Late');

        RETURN ROUND((v_present / v_total) * 100, 2);
    END FN_GET_PERCENTAGE;

END PKG_ATTENDANCE;
/

PROMPT PKG_ATTENDANCE created successfully.
