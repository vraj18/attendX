-- File: 08_sample_data.sql  (OVERHAULED — 100 Students + Registration)
-- =============================================================

-- Clean slate for re-runs
DELETE FROM ATTENDANCE;
DELETE FROM ADMISSION_DROP_LOG;
DELETE FROM STUDENT_REGISTRATIONS;
DELETE FROM BATCHES;
DELETE FROM SECTIONS;
DELETE FROM COURSE_INSTANCES;
DELETE FROM STUDENTS;
DELETE FROM COURSES;
DELETE FROM FACULTY;
DELETE FROM ADMINS;
DELETE FROM SESSIONS;
COMMIT;

-- ── SESSIONS ──────────────────────────────────────────────
INSERT INTO SESSIONS (SessionID, SessionName, AcademicYear, StartDate, EndDate, IsActive)
VALUES (1, 'Odd Semester 2024-25', '2024-2025', DATE '2024-07-15', DATE '2024-11-30', 'N');
INSERT INTO SESSIONS (SessionID, SessionName, AcademicYear, StartDate, EndDate, IsActive)
VALUES (2, 'Even Semester 2024-25', '2024-2025', DATE '2025-01-10', DATE '2025-05-30', 'Y');
COMMIT;

-- ── FACULTY ───────────────────────────────────────────────
INSERT INTO FACULTY (FacultyID, Name, Email, Phone, Department, Designation, Password)
VALUES (1, 'Dr. Anita Sharma', 'anita@vnit.edu', '9800000001', 'CSE', 'Professor', 'pass123');
INSERT INTO FACULTY (FacultyID, Name, Email, Phone, Department, Designation, Password)
VALUES (2, 'Prof. Rajesh Mehta', 'rajesh@vnit.edu', '9800000002', 'CSE', 'Associate Professor', 'pass123');
INSERT INTO FACULTY (FacultyID, Name, Email, Phone, Department, Designation, Password)
VALUES (3, 'Dr. Priya Nair', 'priya@vnit.edu', '9800000003', 'ECE', 'Professor', 'pass123');
INSERT INTO FACULTY (FacultyID, Name, Email, Phone, Department, Designation, Password)
VALUES (4, 'Prof. Arjun Rao', 'arjun@vnit.edu', '9800000004', 'EEE', 'Lecturer', 'pass123');
INSERT INTO FACULTY (FacultyID, Name, Email, Phone, Department, Designation, Password)
VALUES (5, 'Dr. Samyak Singh', 'samyak@vnit.edu', '9800000005', 'MEC', 'Associate Professor', 'pass123');
COMMIT;

-- ── ADMINS ────────────────────────────────────────────────
INSERT INTO ADMINS (Name, Email, Password)
VALUES ('System Administrator', 'admin@vnit.edu', 'admin123');
COMMIT;

-- ── COURSES (Categorized) ─────────────────────────────────
-- CSE Courses
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (1, 'CS101', 'Intro to Programming', 4, 'CSE', 'UG', 'Both', 'DC', 1);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (2, 'CS201', 'Data Structures', 4, 'CSE', 'UG', 'Both', 'DC', 2);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (3, 'CS301', 'Database Systems', 4, 'CSE', 'UG', 'Both', 'DC', 3);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (4, 'CS401', 'Artificial Intelligence', 4, 'CSE', 'UG', 'Both', 'DE', 4);

-- ECE Courses
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (5, 'EC101', 'Network Theory', 4, 'ECE', 'UG', 'Both', 'DC', 1);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (6, 'EC201', 'Analog Circuits', 4, 'ECE', 'UG', 'Both', 'DC', 2);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (7, 'EC301', 'Digital Communication', 4, 'ECE', 'UG', 'Both', 'DC', 3);

-- EEE Courses
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (10, 'EE101', 'Basic Electrical', 4, 'EEE', 'UG', 'Both', 'DC', 1);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (11, 'EE201', 'Electrical Machines', 4, 'EEE', 'UG', 'Both', 'DC', 2);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (12, 'EE301', 'Control Systems', 4, 'EEE', 'UG', 'Both', 'DC', 3);

-- MEC Courses
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (13, 'ME101', 'Thermodynamics', 4, 'MEC', 'UG', 'Both', 'DC', 1);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (14, 'ME201', 'Manufacturing Processes', 4, 'MEC', 'UG', 'Both', 'DC', 2);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (15, 'ME301', 'Heat Transfer', 4, 'MEC', 'UG', 'Both', 'DC', 3);

-- OC/HM (Open to All)
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (8, 'HM101', 'Professional Ethics', 2, 'GEN', 'UG', 'Both', 'HM', 1);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (9, 'OC201', 'Entrepreneurship', 3, 'GEN', 'UG', 'Both', 'OC', 2);
COMMIT;
/

-- ── STUDENTS (100 Students Generation) ────────────────────
DECLARE
    v_branches SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('CSE', 'ECE', 'EEE', 'MEC');
    v_years    SYS.ODCINUMBERLIST   := SYS.ODCINUMBERLIST(1, 2, 3, 4);
    v_batch    NUMBER;
    v_sid      NUMBER;
    v_msg      VARCHAR2(500);
    v_roll     VARCHAR2(50);
    v_counter  NUMBER := 0;
BEGIN
    FOR i IN 1..100 LOOP
        v_counter := v_counter + 1;
        
        -- Distribute across branches and years
        v_batch := 2025 - v_years(MOD(TRUNC((i-1)/4), 4) + 1);
        
        PKG_REGISTRATION.SP_ADMIT_STUDENT(
            p_Name        => 'Student ' || v_counter,
            p_Email       => 'student' || v_counter || '@vnit.edu',
            p_Phone       => '900000' || LPAD(v_counter, 4, '0'),
            p_DOB         => DATE '2000-01-01' + (v_counter * 10),
            p_Branch      => v_branches(MOD(i-1, 4) + 1),
            p_BatchYear   => v_batch,
            p_CurrentYear => (2025 - v_batch),
            p_ProgramLevel => 'UG',
            p_PerformedBy => 'Migration',
            p_StudentID   => v_sid,
            p_RollNumber  => v_roll,
            p_Message     => v_msg
        );
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Inserted exactly 100 students.');
END;
/
COMMIT;

-- ── COURSE INSTANCES & SECTIONS (Current Session) ──────────
INSERT INTO COURSE_INSTANCES (InstanceID, CourseID, SessionID, MaxCapacity)
SELECT SEQ_COURSE_INSTANCES.NEXTVAL, CourseID, 2, 120 FROM COURSES;

-- Map some Faculty to Sections
INSERT INTO SECTIONS (SectionID, InstanceID, SectionName, FacultyID, Room, Slot1, Slot2, MaxStudents)
SELECT SEQ_SECTIONS.NEXTVAL, InstanceID, 'A', 
       CASE 
         WHEN MOD(InstanceID, 5) + 1 IN (1,2,3,4,5) THEN MOD(InstanceID, 5) + 1 
         ELSE 1 
       END,
       'Room ' || InstanceID, '09:00-10:20', NULL, 60
FROM COURSE_INSTANCES WHERE SessionID = 2;
COMMIT;
/

-- ── AUTO-REGISTRATION ─────────────────────────────────────
DECLARE
    v_rid   NUMBER;
    v_msg   VARCHAR2(500);
BEGIN
    FOR s IN (SELECT StudentID, Branch, CurrentYear FROM STUDENTS) LOOP
        -- Register in DC courses for their branch and year
        FOR sec IN (
            SELECT s.SectionID 
            FROM SECTIONS s
            JOIN COURSE_INSTANCES ci ON s.InstanceID = ci.InstanceID
            JOIN COURSES c ON ci.CourseID = c.CourseID
            WHERE ci.SessionID = 2
              AND (c.Department = s.Branch OR c.Department = 'GEN')
              AND c.RecommendedYear = s.CurrentYear
        ) LOOP
            PKG_REGISTRATION.SP_REGISTER_STUDENT(s.StudentID, sec.SectionID, 'admin', v_rid, v_msg);
        END LOOP;
    END LOOP;
    
    -- Auto-approve all registrations for seed data visibility
    UPDATE STUDENT_REGISTRATIONS SET RegStatus = 'Registered' WHERE RegStatus = 'Pending';
    COMMIT;
END;
/

PROMPT Success: Overhauled sample data populated with registrations.
