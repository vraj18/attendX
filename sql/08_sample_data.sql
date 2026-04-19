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
VALUES (1, 'Odd Semester 2024-25', '2024-2025', DATE '2024-07-15', DATE '2024-11-30', 'Y');
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
VALUES (1, 'CS101', 'Intro to Programming', 4, 'CSE', 'UG', 'Odd', 'DC', 1);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (2, 'CS102', 'Object Oriented Concepts', 4, 'CSE', 'UG', 'Even', 'DC', 1);

INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (3, 'CS201', 'Data Structures', 4, 'CSE', 'UG', 'Odd', 'DC', 2);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (4, 'CS202', 'Operating Systems', 4, 'CSE', 'UG', 'Even', 'DC', 2);

INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (5, 'CS301', 'Database Systems', 4, 'CSE', 'UG', 'Odd', 'DC', 3);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (6, 'CS302', 'Computer Networks', 4, 'CSE', 'UG', 'Even', 'DC', 3);

INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (7, 'CS401', 'Artificial Intelligence', 4, 'CSE', 'UG', 'Odd', 'DE', 4);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (8, 'CS402', 'Cloud Computing', 4, 'CSE', 'UG', 'Even', 'DE', 4);

-- ECE Courses
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (9, 'EC101', 'Network Theory', 4, 'ECE', 'UG', 'Odd', 'DC', 1);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (10, 'EC102', 'Basic Electronics', 4, 'ECE', 'UG', 'Even', 'DC', 1);

INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (11, 'EC201', 'Analog Circuits', 4, 'ECE', 'UG', 'Odd', 'DC', 2);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (12, 'EC202', 'Digital Logic Design', 4, 'ECE', 'UG', 'Even', 'DC', 2);

INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (13, 'EC301', 'Digital Communication', 4, 'ECE', 'UG', 'Odd', 'DC', 3);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (14, 'EC302', 'Microprocessors', 4, 'ECE', 'UG', 'Even', 'DC', 3);

-- EEE Courses
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (15, 'EE101', 'Basic Electrical', 4, 'EEE', 'UG', 'Odd', 'DC', 1);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (16, 'EE102', 'Electromagnetic Fields', 4, 'EEE', 'UG', 'Even', 'DC', 1);

INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (17, 'EE201', 'Electrical Machines', 4, 'EEE', 'UG', 'Odd', 'DC', 2);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (18, 'EE202', 'Power Systems', 4, 'EEE', 'UG', 'Even', 'DC', 2);

INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (19, 'EE301', 'Control Systems', 4, 'EEE', 'UG', 'Odd', 'DC', 3);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (20, 'EE302', 'Power Electronics', 4, 'EEE', 'UG', 'Even', 'DC', 3);

-- MEC Courses
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (21, 'ME101', 'Thermodynamics', 4, 'MEC', 'UG', 'Odd', 'DC', 1);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (22, 'ME102', 'Engineering Mechanics', 4, 'MEC', 'UG', 'Even', 'DC', 1);

INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (23, 'ME201', 'Manufacturing Processes', 4, 'MEC', 'UG', 'Odd', 'DC', 2);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (24, 'ME202', 'Fluid Mechanics', 4, 'MEC', 'UG', 'Even', 'DC', 2);

INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (25, 'ME301', 'Heat Transfer', 4, 'MEC', 'UG', 'Odd', 'DC', 3);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (26, 'ME302', 'Machine Design', 4, 'MEC', 'UG', 'Even', 'DC', 3);

-- OC/HM (Open to All)
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (27, 'HM101', 'Professional Ethics', 2, 'GEN', 'UG', 'Both', 'HM', 1);
INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear)
VALUES (28, 'OC201', 'Entrepreneurship', 3, 'GEN', 'UG', 'Both', 'OC', 2);
COMMIT;
/

-- ── COURSE PREREQUISITES ───────────────────────────────────
-- CS101 (Intro) is prereq for CS201 (Data Structures)
INSERT INTO COURSE_PREREQUISITES (CourseID, PrereqCourseID) VALUES (3, 1);
-- CS201 (DS) is prereq for CS301 (DBMS)
INSERT INTO COURSE_PREREQUISITES (CourseID, PrereqCourseID) VALUES (5, 3);
-- CS301 (DBMS) is prereq for CS401 (AI)
INSERT INTO COURSE_PREREQUISITES (CourseID, PrereqCourseID) VALUES (7, 5);

-- Prerequisites for Even Semester Courses (Session 2)
-- CS101 (Odd) is prereq for CS102 (Even)
INSERT INTO COURSE_PREREQUISITES (CourseID, PrereqCourseID) VALUES (2, 1);
-- CS201 (Odd) is prereq for CS202 (Even)
INSERT INTO COURSE_PREREQUISITES (CourseID, PrereqCourseID) VALUES (4, 3);
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

-- ── COURSE INSTANCES & SECTIONS (Past Session: Odd Semester) ──
INSERT INTO COURSE_INSTANCES (InstanceID, CourseID, SessionID, MaxCapacity)
SELECT SEQ_COURSE_INSTANCES.NEXTVAL, CourseID, 1, 120 
FROM COURSES 
WHERE SemesterType IN ('Odd', 'Both');

INSERT INTO SECTIONS (SectionID, InstanceID, SectionName, FacultyID, Room, Slot1, Slot2, MaxStudents)
SELECT SEQ_SECTIONS.NEXTVAL, InstanceID, 'A', 
       CASE WHEN MOD(InstanceID, 5) + 1 IN (1,2,3,4,5) THEN MOD(InstanceID, 5) + 1 ELSE 1 END,
       'Room ' || InstanceID, '10:00-11:20', NULL, 60
FROM COURSE_INSTANCES WHERE SessionID = 1;
COMMIT;
/

-- ── AUTO-REGISTRATION FOR PAST SESSION (Simulate Academic History) ──
DECLARE
    v_rid   NUMBER;
    v_msg   VARCHAR2(500);
    TYPE grade_array IS VARRAY(8) OF VARCHAR2(2);
    grades grade_array := grade_array('AA', 'AB', 'BB', 'BC', 'CC', 'CD', 'DD', 'FF');
    v_grade VARCHAR2(2);
BEGIN
    FOR s IN (SELECT StudentID, Branch, CurrentYear FROM STUDENTS WHERE CurrentYear >= 1) LOOP
        -- Register in DC/DE/OC/HM courses suitable for previous years
        FOR sec IN (
            SELECT ss.SectionID 
            FROM SECTIONS ss
            JOIN COURSE_INSTANCES ci ON ss.InstanceID = ci.InstanceID
            JOIN COURSES c ON ci.CourseID = c.CourseID
            WHERE ci.SessionID = 1
              AND (c.Department = s.Branch OR c.Department = 'GEN')
              AND c.RecommendedYear <= s.CurrentYear
        ) LOOP
            PKG_REGISTRATION.SP_REGISTER_STUDENT(s.StudentID, sec.SectionID, 'Migration', v_rid, v_msg);
            
            IF v_rid > 0 THEN
               -- Randomly assign a grade (including FF for about 12.5% of cases)
               v_grade := grades(TRUNC(DBMS_RANDOM.VALUE(1, 9)));
               UPDATE STUDENT_REGISTRATIONS 
               SET RegStatus = 'Registered', Grade = v_grade 
               WHERE RegistrationID = v_rid;
            END IF;
        END LOOP;
    END LOOP;
    COMMIT;
END;
/

-- Deactivate Session 1 to move it to history
UPDATE SESSIONS SET IsActive = 'N' WHERE SessionID = 1;
COMMIT;

-- ── COURSE INSTANCES & SECTIONS (Current Session: Even Semester) ──
INSERT INTO COURSE_INSTANCES (InstanceID, CourseID, SessionID, MaxCapacity)
SELECT SEQ_COURSE_INSTANCES.NEXTVAL, CourseID, 2, 120 
FROM COURSES 
WHERE SemesterType IN ('Even', 'Both');

INSERT INTO SECTIONS (SectionID, InstanceID, SectionName, FacultyID, Room, Slot1, Slot2, MaxStudents)
SELECT SEQ_SECTIONS.NEXTVAL, InstanceID, 'A', 
       CASE WHEN MOD(InstanceID, 5) + 1 IN (1,2,3,4,5) THEN MOD(InstanceID, 5) + 1 ELSE 1 END,
       'Room ' || (InstanceID + 100), '09:00-10:20', NULL, 60
FROM COURSE_INSTANCES WHERE SessionID = 2;
COMMIT;
/

-- ── AUTO-REGISTRATION (Current Session) ────────────────────
DECLARE
    v_rid   NUMBER;
    v_msg   VARCHAR2(500);
BEGIN
    FOR s IN (SELECT StudentID, Branch, CurrentYear FROM STUDENTS) LOOP
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

PROMPT Success: Sample data populated with odd semester academic history and even semester current registrations.
