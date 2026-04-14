-- =============================================================
-- File: 08_sample_data.sql  (FIXED — uses subqueries for IDs)
-- =============================================================
SET SERVEROUTPUT ON;

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
DELETE FROM SESSIONS;
COMMIT;

-- Reset sequences
BEGIN
  FOR s IN (SELECT sequence_name FROM user_sequences
            WHERE sequence_name IN (
              'SEQ_SESSIONS','SEQ_FACULTY','SEQ_COURSES','SEQ_STUDENTS',
              'SEQ_COURSE_INSTANCES','SEQ_SECTIONS','SEQ_BATCHES',
              'SEQ_REGISTRATIONS','SEQ_ATTENDANCE','SEQ_ADM_DROP_LOG'
            ))
  LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
  END LOOP;
END;
/
CREATE SEQUENCE SEQ_SESSIONS         START WITH 1    INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_FACULTY          START WITH 1    INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_COURSES          START WITH 1    INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_STUDENTS         START WITH 1000 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_COURSE_INSTANCES START WITH 1    INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_SECTIONS         START WITH 1    INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_BATCHES          START WITH 1    INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_REGISTRATIONS    START WITH 1    INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_ATTENDANCE       START WITH 1    INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_ADM_DROP_LOG     START WITH 1    INCREMENT BY 1 NOCACHE NOCYCLE;

-- ── SESSIONS ──────────────────────────────────────────────
INSERT INTO SESSIONS VALUES (SEQ_SESSIONS.NEXTVAL,'Even Semester 2024-25','2024-2025',DATE '2025-01-10',DATE '2025-05-30','Y');
INSERT INTO SESSIONS VALUES (SEQ_SESSIONS.NEXTVAL,'Odd Semester 2025-26', '2025-2026',DATE '2025-07-15',DATE '2025-11-30','N');
COMMIT;

-- ── FACULTY ───────────────────────────────────────────────
INSERT INTO FACULTY VALUES (SEQ_FACULTY.NEXTVAL,'Dr. Anita Sharma',  'anita.sharma@college.edu', '9800000001','Computer Science','Professor');
INSERT INTO FACULTY VALUES (SEQ_FACULTY.NEXTVAL,'Prof. Rajesh Mehta','rajesh.mehta@college.edu', '9800000002','Computer Science','Associate Professor');
INSERT INTO FACULTY VALUES (SEQ_FACULTY.NEXTVAL,'Dr. Priya Nair',    'priya.nair@college.edu',   '9800000003','Information Tech', 'Professor');
INSERT INTO FACULTY VALUES (SEQ_FACULTY.NEXTVAL,'Prof. Sanjay Patel','sanjay.patel@college.edu', '9800000004','Electronics',      'Assistant Professor');
INSERT INTO FACULTY VALUES (SEQ_FACULTY.NEXTVAL,'Dr. Kavita Joshi',  'kavita.joshi@college.edu', '9800000005','Mathematics',      'Professor');
INSERT INTO FACULTY VALUES (SEQ_FACULTY.NEXTVAL,'Prof. Arjun Rao',   'arjun.rao@college.edu',    '9800000006','Computer Science','Lecturer');
COMMIT;

-- ── COURSES ───────────────────────────────────────────────
INSERT INTO COURSES VALUES (SEQ_COURSES.NEXTVAL,'CS301','Database Management Systems',4,'Computer Science','UG');
INSERT INTO COURSES VALUES (SEQ_COURSES.NEXTVAL,'CS302','Operating Systems',          4,'Computer Science','UG');
INSERT INTO COURSES VALUES (SEQ_COURSES.NEXTVAL,'CS401','Machine Learning',           4,'Computer Science','UG');
INSERT INTO COURSES VALUES (SEQ_COURSES.NEXTVAL,'CS501','Advanced DBMS',              4,'Computer Science','PG');
INSERT INTO COURSES VALUES (SEQ_COURSES.NEXTVAL,'CS502','Cloud Computing',            3,'Computer Science','PG');
INSERT INTO COURSES VALUES (SEQ_COURSES.NEXTVAL,'MA301','Discrete Mathematics',       3,'Mathematics',     'BOTH');
INSERT INTO COURSES VALUES (SEQ_COURSES.NEXTVAL,'IT301','Web Technologies',           3,'Information Tech','UG');
INSERT INTO COURSES VALUES (SEQ_COURSES.NEXTVAL,'EC301','Digital Electronics',        4,'Electronics',     'UG');
COMMIT;

-- ── STUDENTS ──────────────────────────────────────────────
INSERT INTO STUDENTS VALUES (SEQ_STUDENTS.NEXTVAL,'Aarav Gupta',  'aarav.gupta@student.edu',  '9100000001',DATE '2003-05-15','UG','Computer Science',DATE '2022-07-01','Active');
INSERT INTO STUDENTS VALUES (SEQ_STUDENTS.NEXTVAL,'Bhavna Shah',  'bhavna.shah@student.edu',  '9100000002',DATE '2003-09-22','UG','Computer Science',DATE '2022-07-01','Active');
INSERT INTO STUDENTS VALUES (SEQ_STUDENTS.NEXTVAL,'Chirag Desai', 'chirag.desai@student.edu', '9100000003',DATE '2002-03-10','UG','Information Tech', DATE '2021-07-01','Active');
INSERT INTO STUDENTS VALUES (SEQ_STUDENTS.NEXTVAL,'Divya Pillai', 'divya.pillai@student.edu', '9100000004',DATE '2001-11-30','PG','Computer Science',DATE '2023-07-01','Active');
INSERT INTO STUDENTS VALUES (SEQ_STUDENTS.NEXTVAL,'Eshan Verma',  'eshan.verma@student.edu',  '9100000005',DATE '2001-07-04','PG','Computer Science',DATE '2023-07-01','Active');
INSERT INTO STUDENTS VALUES (SEQ_STUDENTS.NEXTVAL,'Fatima Khan',  'fatima.khan@student.edu',  '9100000006',DATE '2003-02-18','UG','Electronics',      DATE '2022-07-01','Active');
INSERT INTO STUDENTS VALUES (SEQ_STUDENTS.NEXTVAL,'Gaurav Tiwari','gaurav.tiwari@student.edu','9100000007',DATE '2003-06-25','UG','Computer Science',DATE '2022-07-01','Active');
INSERT INTO STUDENTS VALUES (SEQ_STUDENTS.NEXTVAL,'Harini Menon', 'harini.menon@student.edu', '9100000008',DATE '2002-08-14','UG','Mathematics',      DATE '2021-07-01','Active');
COMMIT;

-- ── COURSE_INSTANCES (Session 1 = Even Sem 2024-25) ───────
-- Using subquery to get session/course IDs dynamically
DECLARE
  v_sess1 NUMBER; v_sess2 NUMBER;
  c_dbms  NUMBER; c_os NUMBER; c_ml NUMBER; c_adbms NUMBER;
  c_cc    NUMBER; c_dm NUMBER;  c_wt NUMBER;  c_de NUMBER;
BEGIN
  SELECT SessionID INTO v_sess1 FROM SESSIONS WHERE SessionName='Even Semester 2024-25';
  SELECT CourseID  INTO c_dbms  FROM COURSES  WHERE CourseCode='CS301';
  SELECT CourseID  INTO c_os    FROM COURSES  WHERE CourseCode='CS302';
  SELECT CourseID  INTO c_ml    FROM COURSES  WHERE CourseCode='CS401';
  SELECT CourseID  INTO c_adbms FROM COURSES  WHERE CourseCode='CS501';
  SELECT CourseID  INTO c_cc    FROM COURSES  WHERE CourseCode='CS502';
  SELECT CourseID  INTO c_dm    FROM COURSES  WHERE CourseCode='MA301';
  SELECT CourseID  INTO c_wt    FROM COURSES  WHERE CourseCode='IT301';
  SELECT CourseID  INTO c_de    FROM COURSES  WHERE CourseCode='EC301';

  INSERT INTO COURSE_INSTANCES VALUES (SEQ_COURSE_INSTANCES.NEXTVAL, c_dbms,  v_sess1, 120);
  INSERT INTO COURSE_INSTANCES VALUES (SEQ_COURSE_INSTANCES.NEXTVAL, c_os,    v_sess1, 120);
  INSERT INTO COURSE_INSTANCES VALUES (SEQ_COURSE_INSTANCES.NEXTVAL, c_ml,    v_sess1, 100);
  INSERT INTO COURSE_INSTANCES VALUES (SEQ_COURSE_INSTANCES.NEXTVAL, c_adbms, v_sess1,  60);
  INSERT INTO COURSE_INSTANCES VALUES (SEQ_COURSE_INSTANCES.NEXTVAL, c_cc,    v_sess1,  60);
  INSERT INTO COURSE_INSTANCES VALUES (SEQ_COURSE_INSTANCES.NEXTVAL, c_dm,    v_sess1, 200);
  INSERT INTO COURSE_INSTANCES VALUES (SEQ_COURSE_INSTANCES.NEXTVAL, c_wt,    v_sess1,  80);
  INSERT INTO COURSE_INSTANCES VALUES (SEQ_COURSE_INSTANCES.NEXTVAL, c_de,    v_sess1,  80);
  COMMIT;
END;
/

-- ── SECTIONS (dynamic lookup via subquery) ─────────────────
DECLARE
  v_dbms_inst  NUMBER; v_os_inst  NUMBER; v_ml_inst   NUMBER;
  v_adm_inst   NUMBER; v_cc_inst  NUMBER; v_dm_inst   NUMBER;
  v_wt_inst    NUMBER; v_de_inst  NUMBER;
  f1 NUMBER; f2 NUMBER; f3 NUMBER; f4 NUMBER; f5 NUMBER; f6 NUMBER;
  v_sess1 NUMBER;
BEGIN
  SELECT SessionID INTO v_sess1 FROM SESSIONS WHERE SessionName='Even Semester 2024-25';

  SELECT ci.InstanceID INTO v_dbms_inst FROM COURSE_INSTANCES ci JOIN COURSES c ON ci.CourseID=c.CourseID WHERE c.CourseCode='CS301' AND ci.SessionID=v_sess1;
  SELECT ci.InstanceID INTO v_os_inst   FROM COURSE_INSTANCES ci JOIN COURSES c ON ci.CourseID=c.CourseID WHERE c.CourseCode='CS302' AND ci.SessionID=v_sess1;
  SELECT ci.InstanceID INTO v_ml_inst   FROM COURSE_INSTANCES ci JOIN COURSES c ON ci.CourseID=c.CourseID WHERE c.CourseCode='CS401' AND ci.SessionID=v_sess1;
  SELECT ci.InstanceID INTO v_adm_inst  FROM COURSE_INSTANCES ci JOIN COURSES c ON ci.CourseID=c.CourseID WHERE c.CourseCode='CS501' AND ci.SessionID=v_sess1;
  SELECT ci.InstanceID INTO v_cc_inst   FROM COURSE_INSTANCES ci JOIN COURSES c ON ci.CourseID=c.CourseID WHERE c.CourseCode='CS502' AND ci.SessionID=v_sess1;
  SELECT ci.InstanceID INTO v_dm_inst   FROM COURSE_INSTANCES ci JOIN COURSES c ON ci.CourseID=c.CourseID WHERE c.CourseCode='MA301' AND ci.SessionID=v_sess1;
  SELECT ci.InstanceID INTO v_wt_inst   FROM COURSE_INSTANCES ci JOIN COURSES c ON ci.CourseID=c.CourseID WHERE c.CourseCode='IT301' AND ci.SessionID=v_sess1;
  SELECT ci.InstanceID INTO v_de_inst   FROM COURSE_INSTANCES ci JOIN COURSES c ON ci.CourseID=c.CourseID WHERE c.CourseCode='EC301' AND ci.SessionID=v_sess1;

  SELECT FacultyID INTO f1 FROM FACULTY WHERE Email='anita.sharma@college.edu';
  SELECT FacultyID INTO f2 FROM FACULTY WHERE Email='rajesh.mehta@college.edu';
  SELECT FacultyID INTO f3 FROM FACULTY WHERE Email='priya.nair@college.edu';
  SELECT FacultyID INTO f4 FROM FACULTY WHERE Email='sanjay.patel@college.edu';
  SELECT FacultyID INTO f5 FROM FACULTY WHERE Email='kavita.joshi@college.edu';
  SELECT FacultyID INTO f6 FROM FACULTY WHERE Email='arjun.rao@college.edu';

  -- DBMS sections
  INSERT INTO SECTIONS VALUES (SEQ_SECTIONS.NEXTVAL, v_dbms_inst,'A',f1,'Lab 101',  '09:00-10:30','14:00-15:30',60);
  INSERT INTO SECTIONS VALUES (SEQ_SECTIONS.NEXTVAL, v_dbms_inst,'B',f2,'Lab 102',  '11:00-12:30',NULL,60);
  -- OS sections
  INSERT INTO SECTIONS VALUES (SEQ_SECTIONS.NEXTVAL, v_os_inst,  'A',f2,'Room 201', '09:00-10:30',NULL,60);
  INSERT INTO SECTIONS VALUES (SEQ_SECTIONS.NEXTVAL, v_os_inst,  'B',f3,'Room 202', '13:00-14:30',NULL,60);
  -- ML section
  INSERT INTO SECTIONS VALUES (SEQ_SECTIONS.NEXTVAL, v_ml_inst,  'A',f1,'Lab 103',  '10:30-12:00',NULL,50);
  -- Advanced DBMS (PG)
  INSERT INTO SECTIONS VALUES (SEQ_SECTIONS.NEXTVAL, v_adm_inst, 'A',f3,'PG Room 1','09:00-10:30','15:00-16:30',30);
  -- Cloud Computing (PG)
  INSERT INTO SECTIONS VALUES (SEQ_SECTIONS.NEXTVAL, v_cc_inst,  'A',f4,'PG Room 2','11:00-12:30',NULL,30);
  -- Discrete Math
  INSERT INTO SECTIONS VALUES (SEQ_SECTIONS.NEXTVAL, v_dm_inst,  'A',f5,'Room 301', '08:00-09:30',NULL,80);
  INSERT INTO SECTIONS VALUES (SEQ_SECTIONS.NEXTVAL, v_dm_inst,  'B',f5,'Room 302', '13:00-14:30',NULL,80);
  -- Web Tech
  INSERT INTO SECTIONS VALUES (SEQ_SECTIONS.NEXTVAL, v_wt_inst,  'A',f6,'Lab 201',  '10:30-12:00',NULL,40);
  -- Digital Electronics
  INSERT INTO SECTIONS VALUES (SEQ_SECTIONS.NEXTVAL, v_de_inst,  'A',f4,'Room 401', '08:00-09:30',NULL,60);
  COMMIT;
END;
/

-- ── BATCHES ───────────────────────────────────────────────
DECLARE
  c_dbms NUMBER; c_adbms NUMBER; c_cc NUMBER;
  f1 NUMBER; f3 NUMBER; f2 NUMBER;
  v_sess1 NUMBER;
BEGIN
  SELECT SessionID INTO v_sess1  FROM SESSIONS WHERE SessionName='Even Semester 2024-25';
  SELECT CourseID  INTO c_dbms   FROM COURSES  WHERE CourseCode='CS301';
  SELECT CourseID  INTO c_adbms  FROM COURSES  WHERE CourseCode='CS501';
  SELECT CourseID  INTO c_cc     FROM COURSES  WHERE CourseCode='CS502';
  SELECT FacultyID INTO f1       FROM FACULTY  WHERE Email='anita.sharma@college.edu';
  SELECT FacultyID INTO f2       FROM FACULTY  WHERE Email='rajesh.mehta@college.edu';
  SELECT FacultyID INTO f3       FROM FACULTY  WHERE Email='priya.nair@college.edu';

  INSERT INTO BATCHES VALUES (SEQ_BATCHES.NEXTVAL,'CS 2022 Batch A', c_dbms,  v_sess1, f1);
  INSERT INTO BATCHES VALUES (SEQ_BATCHES.NEXTVAL,'CS 2022 Batch B', c_dbms,  v_sess1, f2);
  INSERT INTO BATCHES VALUES (SEQ_BATCHES.NEXTVAL,'CS PG Batch 2023',c_adbms, v_sess1, f3);
  COMMIT;
END;
/

-- ── REGISTER STUDENTS via PKG_REGISTRATION ─────────────────
DECLARE
  v_rid  NUMBER;
  v_msg  VARCHAR2(500);
  -- Section IDs (dynamic lookup)
  sec_dbms_A  NUMBER; sec_dbms_B  NUMBER;
  sec_os_A    NUMBER; sec_os_B    NUMBER;
  sec_ml_A    NUMBER;
  sec_adm_A   NUMBER; sec_cc_A    NUMBER;
  sec_dm_A    NUMBER; sec_wt_A    NUMBER; sec_de_A NUMBER;
  -- Student IDs
  s_aarav  NUMBER; s_bhavna NUMBER; s_chirag NUMBER;
  s_divya  NUMBER; s_eshan  NUMBER; s_fatima NUMBER;
  s_gaurav NUMBER; s_harini NUMBER;
  v_sess1 NUMBER;
BEGIN
  SELECT SessionID INTO v_sess1 FROM SESSIONS WHERE SessionName='Even Semester 2024-25';

  -- Fetch section IDs
  SELECT sec.SectionID INTO sec_dbms_A FROM SECTIONS sec JOIN COURSE_INSTANCES ci ON sec.InstanceID=ci.InstanceID JOIN COURSES c ON ci.CourseID=c.CourseID WHERE c.CourseCode='CS301' AND sec.SectionName='A' AND ci.SessionID=v_sess1;
  SELECT sec.SectionID INTO sec_dbms_B FROM SECTIONS sec JOIN COURSE_INSTANCES ci ON sec.InstanceID=ci.InstanceID JOIN COURSES c ON ci.CourseID=c.CourseID WHERE c.CourseCode='CS301' AND sec.SectionName='B' AND ci.SessionID=v_sess1;
  SELECT sec.SectionID INTO sec_os_A   FROM SECTIONS sec JOIN COURSE_INSTANCES ci ON sec.InstanceID=ci.InstanceID JOIN COURSES c ON ci.CourseID=c.CourseID WHERE c.CourseCode='CS302' AND sec.SectionName='A' AND ci.SessionID=v_sess1;
  SELECT sec.SectionID INTO sec_os_B   FROM SECTIONS sec JOIN COURSE_INSTANCES ci ON sec.InstanceID=ci.InstanceID JOIN COURSES c ON ci.CourseID=c.CourseID WHERE c.CourseCode='CS302' AND sec.SectionName='B' AND ci.SessionID=v_sess1;
  SELECT sec.SectionID INTO sec_ml_A   FROM SECTIONS sec JOIN COURSE_INSTANCES ci ON sec.InstanceID=ci.InstanceID JOIN COURSES c ON ci.CourseID=c.CourseID WHERE c.CourseCode='CS401' AND sec.SectionName='A' AND ci.SessionID=v_sess1;
  SELECT sec.SectionID INTO sec_adm_A  FROM SECTIONS sec JOIN COURSE_INSTANCES ci ON sec.InstanceID=ci.InstanceID JOIN COURSES c ON ci.CourseID=c.CourseID WHERE c.CourseCode='CS501' AND sec.SectionName='A' AND ci.SessionID=v_sess1;
  SELECT sec.SectionID INTO sec_cc_A   FROM SECTIONS sec JOIN COURSE_INSTANCES ci ON sec.InstanceID=ci.InstanceID JOIN COURSES c ON ci.CourseID=c.CourseID WHERE c.CourseCode='CS502' AND sec.SectionName='A' AND ci.SessionID=v_sess1;
  SELECT sec.SectionID INTO sec_dm_A   FROM SECTIONS sec JOIN COURSE_INSTANCES ci ON sec.InstanceID=ci.InstanceID JOIN COURSES c ON ci.CourseID=c.CourseID WHERE c.CourseCode='MA301' AND sec.SectionName='A' AND ci.SessionID=v_sess1;
  SELECT sec.SectionID INTO sec_wt_A   FROM SECTIONS sec JOIN COURSE_INSTANCES ci ON sec.InstanceID=ci.InstanceID JOIN COURSES c ON ci.CourseID=c.CourseID WHERE c.CourseCode='IT301' AND sec.SectionName='A' AND ci.SessionID=v_sess1;
  SELECT sec.SectionID INTO sec_de_A   FROM SECTIONS sec JOIN COURSE_INSTANCES ci ON sec.InstanceID=ci.InstanceID JOIN COURSES c ON ci.CourseID=c.CourseID WHERE c.CourseCode='EC301' AND sec.SectionName='A' AND ci.SessionID=v_sess1;

  -- Fetch student IDs
  SELECT StudentID INTO s_aarav  FROM STUDENTS WHERE Email='aarav.gupta@student.edu';
  SELECT StudentID INTO s_bhavna FROM STUDENTS WHERE Email='bhavna.shah@student.edu';
  SELECT StudentID INTO s_chirag FROM STUDENTS WHERE Email='chirag.desai@student.edu';
  SELECT StudentID INTO s_divya  FROM STUDENTS WHERE Email='divya.pillai@student.edu';
  SELECT StudentID INTO s_eshan  FROM STUDENTS WHERE Email='eshan.verma@student.edu';
  SELECT StudentID INTO s_fatima FROM STUDENTS WHERE Email='fatima.khan@student.edu';
  SELECT StudentID INTO s_gaurav FROM STUDENTS WHERE Email='gaurav.tiwari@student.edu';
  SELECT StudentID INTO s_harini FROM STUDENTS WHERE Email='harini.menon@student.edu';

  -- Aarav (UG CS) → DBMS-A, OS-A, ML-A, Discrete-A
  PKG_REGISTRATION.SP_REGISTER_STUDENT(s_aarav, sec_dbms_A,'admin',v_rid,v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);
  PKG_REGISTRATION.SP_REGISTER_STUDENT(s_aarav, sec_os_A,  'admin',v_rid,v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);
  PKG_REGISTRATION.SP_REGISTER_STUDENT(s_aarav, sec_ml_A,  'admin',v_rid,v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);
  PKG_REGISTRATION.SP_REGISTER_STUDENT(s_aarav, sec_dm_A,  'admin',v_rid,v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);

  -- Bhavna (UG CS) → DBMS-B, OS-B
  PKG_REGISTRATION.SP_REGISTER_STUDENT(s_bhavna, sec_dbms_B,'admin',v_rid,v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);
  PKG_REGISTRATION.SP_REGISTER_STUDENT(s_bhavna, sec_os_B,  'admin',v_rid,v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);

  -- Chirag (UG IT) → Web Tech-A, Discrete-A
  PKG_REGISTRATION.SP_REGISTER_STUDENT(s_chirag, sec_wt_A,'admin',v_rid,v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);
  PKG_REGISTRATION.SP_REGISTER_STUDENT(s_chirag, sec_dm_A,'admin',v_rid,v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);

  -- Divya (PG CS) → Adv DBMS-A, Cloud-A
  PKG_REGISTRATION.SP_REGISTER_STUDENT(s_divya, sec_adm_A,'admin',v_rid,v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);
  PKG_REGISTRATION.SP_REGISTER_STUDENT(s_divya, sec_cc_A, 'admin',v_rid,v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);

  -- Eshan (PG CS) → Adv DBMS-A, Cloud-A
  PKG_REGISTRATION.SP_REGISTER_STUDENT(s_eshan, sec_adm_A,'admin',v_rid,v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);
  PKG_REGISTRATION.SP_REGISTER_STUDENT(s_eshan, sec_cc_A, 'admin',v_rid,v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);

  -- Fatima (UG EC) → Digital Electronics-A
  PKG_REGISTRATION.SP_REGISTER_STUDENT(s_fatima, sec_de_A,'admin',v_rid,v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);

  -- Gaurav (UG CS) → DBMS-A, Web Tech-A
  -- Note: DBMS-A already has Aarav; Gaurav can also join (different student)
  PKG_REGISTRATION.SP_REGISTER_STUDENT(s_gaurav, sec_dbms_A,'admin',v_rid,v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);
  PKG_REGISTRATION.SP_REGISTER_STUDENT(s_gaurav, sec_wt_A,  'admin',v_rid,v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);

  -- Harini (UG Math) → Discrete Math-A
  PKG_REGISTRATION.SP_REGISTER_STUDENT(s_harini, sec_dm_A,'admin',v_rid,v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);

  COMMIT;
END;
/

-- ── SAMPLE ATTENDANCE ──────────────────────────────────────
DECLARE
  v_msg     VARCHAR2(200);
  s_aarav   NUMBER;
  s_bhavna  NUMBER;
  s_divya   NUMBER;
  sec_dbms_A NUMBER; sec_adm_A NUMBER;
  f1 NUMBER;
  v_sess1 NUMBER;
BEGIN
  SELECT SessionID INTO v_sess1   FROM SESSIONS WHERE SessionName='Even Semester 2024-25';
  SELECT StudentID INTO s_aarav   FROM STUDENTS WHERE Email='aarav.gupta@student.edu';
  SELECT StudentID INTO s_bhavna  FROM STUDENTS WHERE Email='bhavna.shah@student.edu';
  SELECT StudentID INTO s_divya   FROM STUDENTS WHERE Email='divya.pillai@student.edu';
  SELECT FacultyID INTO f1        FROM FACULTY  WHERE Email='anita.sharma@college.edu';
  SELECT sec.SectionID INTO sec_dbms_A FROM SECTIONS sec JOIN COURSE_INSTANCES ci ON sec.InstanceID=ci.InstanceID JOIN COURSES c ON ci.CourseID=c.CourseID WHERE c.CourseCode='CS301' AND sec.SectionName='A' AND ci.SessionID=v_sess1;
  SELECT sec.SectionID INTO sec_adm_A  FROM SECTIONS sec JOIN COURSE_INSTANCES ci ON sec.InstanceID=ci.InstanceID JOIN COURSES c ON ci.CourseID=c.CourseID WHERE c.CourseCode='CS501' AND sec.SectionName='A' AND ci.SessionID=v_sess1;

  -- Aarav in DBMS-A
  PKG_ATTENDANCE.SP_MARK_ATTENDANCE(s_aarav, sec_dbms_A, DATE '2025-01-13', 1, 'Present', f1, v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);
  PKG_ATTENDANCE.SP_MARK_ATTENDANCE(s_aarav, sec_dbms_A, DATE '2025-01-13', 2, 'Present', f1, v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);
  PKG_ATTENDANCE.SP_MARK_ATTENDANCE(s_aarav, sec_dbms_A, DATE '2025-01-14', 1, 'Absent',  f1, v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);
  PKG_ATTENDANCE.SP_MARK_ATTENDANCE(s_aarav, sec_dbms_A, DATE '2025-01-15', 1, 'Present', f1, v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);
  PKG_ATTENDANCE.SP_MARK_ATTENDANCE(s_aarav, sec_dbms_A, DATE '2025-01-15', 2, 'Late',    f1, v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);
  PKG_ATTENDANCE.SP_MARK_ATTENDANCE(s_aarav, sec_dbms_A, DATE '2025-01-16', 1, 'Present', f1, v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);

  -- Divya in Adv DBMS-A
  PKG_ATTENDANCE.SP_MARK_ATTENDANCE(s_divya, sec_adm_A, DATE '2025-01-13', 1, 'Present', f1, v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);
  PKG_ATTENDANCE.SP_MARK_ATTENDANCE(s_divya, sec_adm_A, DATE '2025-01-14', 1, 'Present', f1, v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);
  PKG_ATTENDANCE.SP_MARK_ATTENDANCE(s_divya, sec_adm_A, DATE '2025-01-15', 1, 'Absent',  f1, v_msg); DBMS_OUTPUT.PUT_LINE(v_msg);

  COMMIT;
END;
/

PROMPT Sample data inserted successfully.
