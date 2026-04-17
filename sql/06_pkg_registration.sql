-- =============================================================
-- Student Attendance & Registration System
-- File: 06_pkg_registration.sql
-- Package: PKG_REGISTRATION
--   - SP_REGISTER_STUDENT   : validates & registers a student
--   - SP_DROP_STUDENT       : drops a student from a section
--   - SP_ADMIT_STUDENT      : admits a new student
--   - FN_VALIDATE_REGISTRATION : validation helper (private)
-- =============================================================

-- ====== PACKAGE SPECIFICATION ==============================
CREATE OR REPLACE PACKAGE PKG_REGISTRATION AS

    -- Register student in a section
    PROCEDURE SP_REGISTER_STUDENT (
        p_StudentID   IN  NUMBER,
        p_SectionID   IN  NUMBER,
        p_PerformedBy IN  VARCHAR2,
        p_RegID       OUT NUMBER,
        p_Message     OUT VARCHAR2
    );

    -- Drop student from a specific section
    PROCEDURE SP_DROP_FROM_SECTION (
        p_StudentID   IN  NUMBER,
        p_SectionID   IN  NUMBER,
        p_Reason      IN  VARCHAR2,
        p_PerformedBy IN  VARCHAR2,
        p_Message     OUT VARCHAR2
    );

    -- Admit a brand-new student into the system
    PROCEDURE SP_ADMIT_STUDENT (
        p_Name        IN  VARCHAR2,
        p_Email       IN  VARCHAR2,
        p_Phone       IN  VARCHAR2,
        p_DOB         IN  DATE,
        p_Branch      IN  VARCHAR2,
        p_BatchYear   IN  NUMBER,
        p_CurrentYear IN  NUMBER,
        p_ProgramLevel IN  VARCHAR2,
        p_PerformedBy IN  VARCHAR2,
        p_StudentID   OUT NUMBER,
        p_RollNumber  OUT VARCHAR2,
        p_Message     OUT VARCHAR2
    );

    -- Drop a student entirely from the institution
    PROCEDURE SP_DROP_STUDENT (
        p_StudentID   IN  NUMBER,
        p_Reason      IN  VARCHAR2,
        p_PerformedBy IN  VARCHAR2,
        p_Message     OUT VARCHAR2
    );

END PKG_REGISTRATION;
/


-- ====== PACKAGE BODY =======================================
CREATE OR REPLACE PACKAGE BODY PKG_REGISTRATION AS

    -- --------------------------------------------------------
    -- PRIVATE: Validate registration eligibility
    -- Returns: 'OK' or error message string
    -- --------------------------------------------------------
    FUNCTION FN_VALIDATE_REGISTRATION (
        p_StudentID IN NUMBER,
        p_SectionID IN NUMBER
    ) RETURN VARCHAR2
    AS
        v_student_status   STUDENTS.Status%TYPE;
        v_student_level    STUDENTS.ProgramLevel%TYPE;
        v_course_level     COURSES.CourseLevel%TYPE;
        v_course_parity    COURSES.SemesterType%TYPE;
        v_course_cat       COURSES.CourseCategory%TYPE;
        v_course_year      COURSES.RecommendedYear%TYPE;
        v_course_branch    COURSES.Department%TYPE;
        v_student_branch   STUDENTS.Branch%TYPE;
        v_student_year     STUDENTS.CurrentYear%TYPE;
        v_session_active   SESSIONS.IsActive%TYPE;
        v_session_parity   VARCHAR2(50);
        v_course_id        COURSE_INSTANCES.CourseID%TYPE;
        v_section_max      SECTIONS.MaxStudents%TYPE;
        v_enrolled_count   NUMBER;
        v_dup_count        NUMBER;
        v_dup_instance     NUMBER;
        v_passed_count     NUMBER;
        v_backlog_count    NUMBER;
        v_instance_id      COURSE_INSTANCES.InstanceID%TYPE;
    BEGIN
        -- 1. Student must exist and be Active
        BEGIN
            SELECT Status, ProgramLevel, Branch, CurrentYear
            INTO   v_student_status, v_student_level, v_student_branch, v_student_year
            FROM   STUDENTS
            WHERE  StudentID = p_StudentID;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            RETURN 'ERROR: Student ID ' || p_StudentID || ' not found.';
        END;

        IF v_student_status != 'Active' THEN
            RETURN 'ERROR: Student is not active (Status=' || v_student_status || ').';
        END IF;

        -- 2. Get section → instance → course → session
        BEGIN
            SELECT ci.InstanceID, ci.CourseID, c.CourseLevel, c.SemesterType, 
                   c.CourseCategory, c.RecommendedYear, c.Department,
                   s.IsActive, s.SessionName,
                   sec.MaxStudents
            INTO   v_instance_id, v_course_id, v_course_level, v_course_parity,
                   v_course_cat, v_course_year, v_course_branch,
                   v_session_active, v_session_parity,
                   v_section_max
            FROM   SECTIONS           sec
            JOIN   COURSE_INSTANCES   ci  ON sec.InstanceID = ci.InstanceID
            JOIN   COURSES            c   ON ci.CourseID    = c.CourseID
            JOIN   SESSIONS           s   ON ci.SessionID   = s.SessionID
            WHERE  sec.SectionID = p_SectionID;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            RETURN 'ERROR: Section ID ' || p_SectionID || ' not found.';
        END;

        v_session_parity := CASE
            WHEN INSTR(UPPER(v_session_parity), 'ODD') > 0 THEN 'Odd'
            WHEN INSTR(UPPER(v_session_parity), 'EVEN') > 0 THEN 'Even'
            ELSE 'Both'
        END;

        IF v_course_parity != 'Both' AND v_session_parity != v_course_parity THEN
            RETURN 'ERROR: Course is offered only in ' || v_course_parity || ' semesters.';
        END IF;

        -- 2b. Branch Matching for DC/DE
        IF v_course_cat IN ('DC','DE') AND v_course_branch != v_student_branch THEN
            RETURN 'ERROR: This course is restricted to ' || v_course_branch || ' students.';
        END IF;

        -- 2c. Year Level Restriction
        IF v_course_year > v_student_year THEN
            RETURN 'ERROR: Senior year courses (' || v_course_year || ') are not available for you.';
        END IF;

        SELECT COUNT(*) INTO v_passed_count
        FROM   STUDENT_REGISTRATIONS sr
        JOIN   SECTIONS          sec ON sr.SectionID = sec.SectionID
        JOIN   COURSE_INSTANCES ci  ON sec.InstanceID = ci.InstanceID
        WHERE  sr.StudentID = p_StudentID
          AND  ci.CourseID   = v_course_id
          AND  sr.RegStatus != 'Dropped'
          AND  sr.Grade IN ('AA','AB','BB','BC','CC','CD','DD');

        IF v_passed_count > 0 THEN
            RETURN 'ERROR: Student has already passed this course and cannot register again.';
        END IF;

        SELECT COUNT(*) INTO v_backlog_count
        FROM   STUDENT_REGISTRATIONS sr
        JOIN   SECTIONS          sec ON sr.SectionID = sec.SectionID
        JOIN   COURSE_INSTANCES ci  ON sec.InstanceID = ci.InstanceID
        WHERE  sr.StudentID = p_StudentID
          AND  ci.CourseID   = v_course_id
          AND  sr.RegStatus != 'Dropped'
          AND  sr.Grade IN ('W','FF','LL');

        IF v_backlog_count > 0 AND v_course_parity != 'Both' AND v_session_parity != v_course_parity THEN
            RETURN 'ERROR: Backlog retake for this course is allowed only in ' || v_course_parity || ' semesters.';
        END IF;

        -- 3. Session must be active
        IF v_session_active != 'Y' THEN
            RETURN 'ERROR: Session is not currently active.';
        END IF;

        -- 4. Student level must match course level
        IF v_course_level != 'BOTH' AND v_course_level != v_student_level THEN
            RETURN 'ERROR: Student level (' || v_student_level ||
                   ') does not match course level (' || v_course_level || ').';
        END IF;

        -- 5. Section must not be full
        SELECT COUNT(*) INTO v_enrolled_count
        FROM   STUDENT_REGISTRATIONS
        WHERE  SectionID = p_SectionID
          AND  RegStatus = 'Registered';

        IF v_enrolled_count >= v_section_max THEN
            RETURN 'ERROR: Section is full (' || v_enrolled_count ||
                   '/' || v_section_max || ').';
        END IF;

        -- 6. No duplicate registration in this section
        SELECT COUNT(*) INTO v_dup_count
        FROM   STUDENT_REGISTRATIONS
        WHERE  StudentID = p_StudentID
          AND  SectionID = p_SectionID
          AND  RegStatus != 'Dropped';

        IF v_dup_count > 0 THEN
            RETURN 'ERROR: Student already registered in this section.';
        END IF;

        -- 7. Student must not be in another section of the SAME instance
        SELECT COUNT(*) INTO v_dup_instance
        FROM   STUDENT_REGISTRATIONS sr
        JOIN   SECTIONS sec ON sr.SectionID = sec.SectionID
        WHERE  sr.StudentID  = p_StudentID
          AND  sec.InstanceID = v_instance_id
          AND  sr.RegStatus  != 'Dropped';

        IF v_dup_instance > 0 THEN
            RETURN 'ERROR: Student is already registered in another section of this course.';
        END IF;

        RETURN 'OK';
    END FN_VALIDATE_REGISTRATION;


    -- --------------------------------------------------------
    -- PUBLIC: Register student in a section
    -- --------------------------------------------------------
    PROCEDURE SP_REGISTER_STUDENT (
    p_StudentID   IN  NUMBER,
    p_SectionID   IN  NUMBER,
    p_PerformedBy IN  VARCHAR2,
    p_RegID       OUT NUMBER,
    p_Message     OUT VARCHAR2
) AS
    v_validation   VARCHAR2(500);
    v_reg_id       NUMBER;
    v_existing_id  NUMBER;
    v_existing_status VARCHAR2(20);
    v_init_status  VARCHAR2(15) := 'Pending';
BEGIN
    -- 1. Check if record already exists
    BEGIN
        -- SELECT RegistrationID, RegStatus
        -- INTO   v_existing_id, v_existing_status
        -- FROM   STUDENT_REGISTRATIONS
        -- WHERE  StudentID = p_StudentID
        --   AND  SectionID = p_SectionID;
        SELECT RegistrationID, RegStatus
        INTO   v_existing_id, v_existing_status
        FROM (
            SELECT RegistrationID, RegStatus
            FROM STUDENT_REGISTRATIONS
            WHERE StudentID = p_StudentID
            AND SectionID = p_SectionID
            ORDER BY RegistrationDate DESC
        )
        WHERE ROWNUM = 1;

        -- Record exists
        IF v_existing_status = 'Dropped' THEN

            -- ✅ VALIDATE AGAIN
            v_validation := FN_VALIDATE_REGISTRATION(p_StudentID, p_SectionID);

            IF v_validation != 'OK' THEN
                p_RegID   := -1;
                p_Message := v_validation;
                RETURN;
            END IF;
            -- 🔥 RE-REGISTER (UPDATE instead of INSERT)

            UPDATE STUDENT_REGISTRATIONS
            SET RegStatus = v_init_status,
                RegistrationDate = SYSDATE
            WHERE RegistrationID = v_existing_id;

            COMMIT;
            p_RegID   := v_existing_id;
            p_Message := 'SUCCESS: Student re-registered.';
            RETURN;

        ELSE
            -- Already active/pending
            p_RegID   := -1;
            p_Message := 'ERROR: Student already registered in this section.';
            RETURN;
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL; -- No existing record → proceed normally
    END;

    -- 2. Run validation ONLY for fresh insert
    v_validation := FN_VALIDATE_REGISTRATION(p_StudentID, p_SectionID);

    IF v_validation != 'OK' THEN
        p_RegID   := -1;
        p_Message := v_validation;
        RETURN;
    END IF;

    -- 3. Fresh INSERT
    v_reg_id := SEQ_REGISTRATIONS.NEXTVAL;

    INSERT INTO STUDENT_REGISTRATIONS (
        RegistrationID, StudentID, SectionID, RegistrationDate, RegStatus
    ) VALUES (
        v_reg_id, p_StudentID, p_SectionID, SYSDATE, v_init_status
    );

    COMMIT;
    p_RegID   := v_reg_id;
    p_Message := 'SUCCESS: Student registered. RegistrationID=' || v_reg_id;

EXCEPTION WHEN OTHERS THEN
    ROLLBACK;
    p_RegID   := -1;
    p_Message := 'EXCEPTION: ' || SQLERRM;
END SP_REGISTER_STUDENT;


    -- --------------------------------------------------------
    -- PUBLIC: Drop student from a specific section
    -- --------------------------------------------------------
    PROCEDURE SP_DROP_FROM_SECTION (
        p_StudentID   IN  NUMBER,
        p_SectionID   IN  NUMBER,
        p_Reason      IN  VARCHAR2,
        p_PerformedBy IN  VARCHAR2,
        p_Message     OUT VARCHAR2
    ) AS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM   STUDENT_REGISTRATIONS
        WHERE  StudentID  = p_StudentID
          AND  SectionID  = p_SectionID
          AND  RegStatus != 'Dropped';

        IF v_count = 0 THEN
            p_Message := 'ERROR: No active registration found for StudentID='
                         || p_StudentID || ' in SectionID=' || p_SectionID;
            RETURN;
        END IF;

        -- UPDATE STUDENT_REGISTRATIONS
        -- SET    RegStatus = 'Dropped'
        -- WHERE  StudentID = p_StudentID
        --   AND  SectionID = p_SectionID;
        UPDATE STUDENT_REGISTRATIONS
        SET RegStatus = 'Dropped'
        WHERE StudentID = p_StudentID
        AND SectionID = p_SectionID
        AND RegStatus IN ('Registered', 'Pending');

        COMMIT;
        p_Message := 'SUCCESS: Student dropped from section.';

    EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        p_Message := 'EXCEPTION: ' || SQLERRM;
    END SP_DROP_FROM_SECTION;


    -- --------------------------------------------------------
    -- PUBLIC: Admit a new student (inserts into STUDENTS +
    --         logs to ADMISSION_DROP_LOG)
    -- --------------------------------------------------------
    PROCEDURE SP_ADMIT_STUDENT (
        p_Name        IN  VARCHAR2,
        p_Email       IN  VARCHAR2,
        p_Phone       IN  VARCHAR2,
        p_DOB         IN  DATE,
        p_Branch      IN  VARCHAR2,
        p_BatchYear   IN  NUMBER,
        p_CurrentYear IN  NUMBER,
        p_ProgramLevel IN  VARCHAR2,
        p_PerformedBy IN  VARCHAR2,
        p_StudentID   OUT NUMBER,
        p_RollNumber  OUT VARCHAR2,
        p_Message     OUT VARCHAR2
    ) AS
        v_sid    NUMBER;
        v_dup    NUMBER;
        v_roll   VARCHAR2(20);
    BEGIN
        -- Generate Roll Number: bt + batch_year_suffix + branch + next_id
        -- e.g. bt23cse101
        SELECT SEQ_STUDENTS.NEXTVAL INTO v_sid FROM DUAL;
        v_roll := 'bt' || SUBSTR(TO_CHAR(p_BatchYear), 3, 2) || LOWER(p_Branch) || TO_CHAR(v_sid);

        -- Check duplicate email
        SELECT COUNT(*) INTO v_dup FROM STUDENTS WHERE Email = p_Email;
        IF v_dup > 0 THEN
            p_StudentID := -1;
            p_Message   := 'ERROR: Email already exists.';
            RETURN;
        END IF;

        INSERT INTO STUDENTS (
            StudentID, RollNumber, Name, Email, Phone, DOB,
            Branch, BatchYear, CurrentYear, ProgramLevel, AdmissionDate, Status
        ) VALUES (
            v_sid, v_roll, p_Name, p_Email, p_Phone, p_DOB,
            p_Branch, p_BatchYear, p_CurrentYear, p_ProgramLevel, SYSDATE, 'Active'
        );

        -- Trigger TRG_STUDENT_ADMISSION_STATUS will fire on this insert:
        INSERT INTO ADMISSION_DROP_LOG (
            LogID, StudentID, Action, ActionDate, Reason, PerformedBy
        ) VALUES (
            SEQ_ADM_DROP_LOG.NEXTVAL, v_sid, 'Admitted', SYSDATE,
            'New admission', p_PerformedBy
        );

        COMMIT;
        p_StudentID  := v_sid;
        p_RollNumber := v_roll;
        p_Message    := 'SUCCESS: Student admitted. RollNumber=' || v_roll;

    EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        p_StudentID := -1;
        p_Message   := 'EXCEPTION: ' || SQLERRM;
    END SP_ADMIT_STUDENT;


    -- --------------------------------------------------------
    -- PUBLIC: Drop student entirely from the institution
    -- --------------------------------------------------------
    PROCEDURE SP_DROP_STUDENT (
        p_StudentID   IN  NUMBER,
        p_Reason      IN  VARCHAR2,
        p_PerformedBy IN  VARCHAR2,
        p_Message     OUT VARCHAR2
    ) AS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM STUDENTS WHERE StudentID = p_StudentID;
        IF v_count = 0 THEN
            p_Message := 'ERROR: Student not found.';
            RETURN;
        END IF;

        -- Insert log → trigger fires → updates STUDENTS.Status + registrations
        INSERT INTO ADMISSION_DROP_LOG (
            LogID, StudentID, Action, ActionDate, Reason, PerformedBy
        ) VALUES (
            SEQ_ADM_DROP_LOG.NEXTVAL, p_StudentID, 'Dropped',
            SYSDATE, p_Reason, p_PerformedBy
        );

        COMMIT;
        p_Message := 'SUCCESS: Student dropped from institution. Trigger updated status.';

    EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        p_Message := 'EXCEPTION: ' || SQLERRM;
    END SP_DROP_STUDENT;

END PKG_REGISTRATION;
/

PROMPT PKG_REGISTRATION created successfully.
