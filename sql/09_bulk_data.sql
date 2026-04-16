-- =============================================================
-- File: 09_bulk_data.sql
-- Generates 100 students, registers them in courses, and marks 10 days of attendance
-- =============================================================
SET SERVEROUTPUT ON;

DECLARE
    TYPE name_array IS VARRAY(20) OF VARCHAR2(50);
    first_names name_array := name_array('Aarav', 'Vihaan', 'Vivaan', 'Ananya', 'Diya', 'Advik', 'Kabir', 'Anika', 'Navya', 'Ojas', 'Dhruv', 'Ayaan', 'Aadhya', 'Kiara', 'Neha', 'Pranav', 'Riya', 'Rohan', 'Sneha', 'Yash');
    last_names name_array := name_array('Sharma', 'Verma', 'Gupta', 'Malhotra', 'Bhatia', 'Kaur', 'Singh', 'Patel', 'Reddy', 'Rao', 'Das', 'Sen', 'Nair', 'Pillai', 'Menon', 'Joshi', 'Kulkarni', 'Deshmukh', 'Yadav', 'Dubey');
    depts name_array := name_array('CSE', 'ECE', 'EEE', 'MEC');
    
    v_name VARCHAR2(100);
    v_email VARCHAR2(100);
    v_dept VARCHAR2(100);
    v_level VARCHAR2(10);
    v_sid NUMBER;
    v_roll VARCHAR2(50);
    v_msg VARCHAR2(500);
    v_rid NUMBER;
    
    CURSOR c_sections IS 
        SELECT sec.SectionID, c.CourseLevel, ci.SessionID 
        FROM SECTIONS sec 
        JOIN COURSE_INSTANCES ci ON sec.InstanceID = ci.InstanceID 
        JOIN COURSES c ON ci.CourseID = c.CourseID;
        
    v_sess1 NUMBER;
    v_att_msg VARCHAR2(200);
BEGIN
    SELECT SessionID INTO v_sess1 FROM SESSIONS WHERE SessionName='Even Semester 2024-25' FETCH FIRST 1 ROWS ONLY;

    -- Generate 100 students
    FOR i IN 1..100 LOOP
        v_name := first_names(TRUNC(DBMS_RANDOM.VALUE(1, 21))) || ' ' || last_names(TRUNC(DBMS_RANDOM.VALUE(1, 21)));
        v_email := LOWER(REPLACE(v_name, ' ', '.')) || DBMS_RANDOM.VALUE(100,999) || i || '@student.edu';
        v_dept := depts(TRUNC(DBMS_RANDOM.VALUE(1, 5))); -- Random branch
        
        -- Default to Year 1 (2024 batch) for simplicity or randomize
        PKG_REGISTRATION.SP_ADMIT_STUDENT(
            p_Name        => v_name,
            p_Email       => v_email,
            p_Phone       => '9' || TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(100000000, 999999999))),
            p_DOB         => ADD_MONTHS(SYSDATE, -240),
            p_Branch      => v_dept,
            p_BatchYear   => 2024,
            p_CurrentYear => 1,
            p_ProgramLevel => 'UG',
            p_PerformedBy => 'admin',
            p_StudentID   => v_sid,
            p_RollNumber  => v_roll,
            p_Message     => v_msg
        );
        
        -- Register in a few random courses
        FOR rec IN c_sections LOOP
            IF DBMS_RANDOM.VALUE(0,1) > 0.7 AND (rec.CourseLevel = v_level OR rec.CourseLevel = 'BOTH') AND rec.SessionID = v_sess1 THEN
                PKG_REGISTRATION.SP_REGISTER_STUDENT(v_sid, rec.SectionID, 'admin', v_rid, v_msg);
            END IF;
        END LOOP;
    END LOOP;
    
    -- Mark 10 days of attendance for all registered students
    FOR rec IN (SELECT sr.StudentID, sr.SectionID FROM STUDENT_REGISTRATIONS sr WHERE sr.RegStatus = 'Registered') LOOP
        FOR day IN 1..10 LOOP
            IF DBMS_RANDOM.VALUE(0, 1) > 0.2 THEN
                PKG_ATTENDANCE.SP_MARK_ATTENDANCE(rec.StudentID, rec.SectionID, SYSDATE - day, 1, 'Present', 1, v_att_msg);
            ELSE
                PKG_ATTENDANCE.SP_MARK_ATTENDANCE(rec.StudentID, rec.SectionID, SYSDATE - day, 1, 'Absent', 1, v_att_msg);
            END IF;
        END LOOP;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully inserted 100 students and marked random attendance.');
END;
/
