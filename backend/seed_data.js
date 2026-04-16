const db = require('./db');
const oracledb = require('oracledb');

async function seed() {
    console.log('🚀 Starting Massive Database Seeding with Academic History...');
    await db.init();
    const connection = await db.getPool().getConnection();

    try {
        // 1. Clean Slate
        console.log('🧹 Cleaning existing data...');
        const tablesToClean = [
            'ATTENDANCE', 'ADMISSION_DROP_LOG', 'STUDENT_REGISTRATIONS', 
            'BATCHES', 'SECTIONS', 'COURSE_INSTANCES', 'STUDENTS', 
            'COURSES', 'FACULTY', 'ADMINS', 'SESSIONS'
        ];
        for (const table of tablesToClean) {
            try { await connection.execute(`DELETE FROM ${table}`); } catch (e) { console.log(`   (Note: Could not clean ${table})`); }
        }
        await connection.commit();

        // 2. Sessions (Current + History)
        console.log('📅 Inserting Sessions (Current & 2023-24 History)...');
        await connection.execute(`INSERT INTO SESSIONS (SessionID, SessionName, AcademicYear, StartDate, EndDate, IsActive) VALUES (1, 'Odd Semester 2024-25', '2024-2025', DATE '2024-07-15', DATE '2024-11-30', 'N')`);
        await connection.execute(`INSERT INTO SESSIONS (SessionID, SessionName, AcademicYear, StartDate, EndDate, IsActive) VALUES (2, 'Even Semester 2024-25', '2024-2025', DATE '2025-01-10', DATE '2025-05-30', 'Y')`);
        await connection.execute(`INSERT INTO SESSIONS (SessionID, SessionName, AcademicYear, StartDate, EndDate, IsActive) VALUES (3, 'Odd Semester 2023-24', '2023-2024', DATE '2023-07-15', DATE '2023-11-30', 'N')`);
        await connection.execute(`INSERT INTO SESSIONS (SessionID, SessionName, AcademicYear, StartDate, EndDate, IsActive) VALUES (4, 'Even Semester 2023-24', '2023-2024', DATE '2024-01-10', DATE '2024-05-30', 'N')`);

        // 3. Faculty (20 total, 5 per dept)
        console.log('👨‍🏫 Inserting 20 Faculty Members...');
        const depts = ['CSE', 'ECE', 'EEE', 'MEC'];
        const roles = ['Professor', 'Associate Professor', 'Assistant Professor', 'Lecturer'];
        let facultyId = 1;
        for (const dept of depts) {
            for (let i = 1; i <= 5; i++) {
                const name = `Prof. ${dept} Teacher ${i}`;
                const email = `${dept.toLowerCase()}${i}@vnit.edu`;
                const role = roles[i % 4];
                await connection.execute(
                    `INSERT INTO FACULTY (FacultyID, Name, Email, Phone, Department, Designation, Password) VALUES (:1, :2, :3, :4, :5, :6, :7)`,
                    [facultyId++, name, email, `98000000${facultyId.toString().padStart(2, '0')}`, dept, role, 'pass123']
                );
            }
        }

        // 4. Admin
        await connection.execute(`INSERT INTO ADMINS (Name, Email, Password) VALUES ('System Administrator', 'admin@vnit.edu', 'admin123')`);

        // 5. Massive Course Catalog (96 Courses)
        console.log('📚 Generating Massive Course Catalog...');
        const courseNames = {
            CSE: ['Algorithms', 'Systems', 'Computing', 'Networks', 'Intelligence', 'Security'],
            ECE: ['Circuits', 'Signals', 'Communication', 'VLSI', 'Processing', 'Antennas'],
            EEE: ['Power', 'Machines', 'Control', 'Electromagnetics', 'Instrumentation', 'Storage'],
            MEC: ['Dynamics', 'Thermodynamics', 'Mechanics', 'Manufacturing', 'Robotics', 'Design']
        };
        const years = [1, 2, 3, 4];
        const sems = ['Odd', 'Even'];
        let courseId = 1;

        for (const dept of depts) {
            for (const year of years) {
                for (const sem of sems) {
                    for (let cIdx = 1; cIdx <= 3; cIdx++) {
                        const nameBase = courseNames[dept][(year + cIdx) % 6];
                        const courseName = `${dept} ${sem === 'Odd' ? 'I' : 'II'} - ${nameBase} ${cIdx}`;
                        const courseCode = `${dept}${year}${sem === 'Odd' ? '1' : '2'}${cIdx}`;
                        await connection.execute(
                            `INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear) 
                             VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9)`,
                            [courseId++, courseCode, courseName, 4, dept, 'UG', sem, 'DC', year]
                        );
                    }
                }
            }
        }
        await connection.commit();

        // 6. Instances & Sections for ALL Courses (Across all 4 sessions)
        console.log('🏗️ Creating Course Instances and Sections for ALL sessions (Catalog expansion)...');
        const allCourses = await connection.execute('SELECT CourseID, Department, SemesterType FROM COURSES');
        const sessIds = [1, 2, 3, 4];
        for (const c of allCourses.rows) {
            for (const sid of sessIds) {
                // Only create instances for matching semester types (Session 1 & 3 are Odd, 2 & 4 are Even)
                const sessSem = (sid === 1 || sid === 3) ? 'Odd' : 'Even';
                if (c.SEMESTERTYPE !== sessSem) continue;

                const res = await connection.execute(
                    `INSERT INTO COURSE_INSTANCES (InstanceID, CourseID, SessionID, MaxCapacity) 
                     VALUES (SEQ_COURSE_INSTANCES.NEXTVAL, :1, :2, 60) RETURN InstanceID INTO :out_id`,
                    { 1: c.COURSEID, 2: sid, out_id: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT } }
                );
                const instanceId = res.outBinds.out_id[0];

                const facRes = await connection.execute(
                    `SELECT FacultyID FROM FACULTY WHERE Department = :1 ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROWS ONLY`,
                    [c.DEPARTMENT]
                );
                await connection.execute(
                    `INSERT INTO SECTIONS (SectionID, InstanceID, SectionName, FacultyID, Room, Slot1, MaxStudents) 
                     VALUES (SEQ_SECTIONS.NEXTVAL, :1, 'A', :2, :3, '10:00', 60)`,
                    [instanceId, facRes.rows[0].FACULTYID, `LH-${c.COURSEID}-${sid}`]
                );
            }
        }
        await connection.commit();

        // 7. Admit 100 Students
        console.log('🎓 Admitting 100 Students...');
        for (let i = 1; i <= 100; i++) {
            const dept = depts[(i - 1) % 4];
            const year = years[Math.floor((i - 1) / 4) % 4];
            const batch = 2025 - year;
            await connection.execute(
                `BEGIN PKG_REGISTRATION.SP_ADMIT_STUDENT(:1, :2, :3, :4, :5, :6, :7, :8, :9, :sid, :roll, :msg); END;`,
                {
                    1: `Student ${i}`, 2: `student${i}@vnit.edu`, 3: `900000${i.toString().padStart(4, '0')}`,
                    4: new Date(2000, 0, 1 + i), 5: dept, 6: batch, 7: year, 8: 'UG', 9: 'Seeding',
                    sid: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
                    roll: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 50 },
                    msg: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 500 }
                }
            );
        }
        await connection.commit();

        // 8. Registrations (Current + History)
        console.log('📝 Generating Registrations (Current Active + Historical Records)...');
        const students = await connection.execute('SELECT StudentID, Branch, CurrentYear FROM STUDENTS');
        const grades = ['AA', 'AB', 'BB', 'BC', 'CC', 'CD', 'DD'];

        for (const s of students.rows) {
            // Find current Even semester courses (Session 2)
            const currentAvail = await connection.execute(
                `SELECT sec.SectionID FROM SECTIONS sec JOIN COURSE_INSTANCES ci ON sec.InstanceID = ci.InstanceID JOIN COURSES c ON ci.CourseID = c.CourseID WHERE ci.SessionID = 2 AND c.Department = :1 AND c.RecommendedYear = :2`,
                [s.BRANCH, s.CURRENTYEAR]
            );
            for (const sec of currentAvail.rows) {
                await connection.execute(`BEGIN PKG_REGISTRATION.SP_REGISTER_STUDENT(:sid, :sec, 'admin', :rid, :msg); END;`, { sid: s.STUDENTID, sec: sec.SECTIONID, rid: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }, msg: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 500 } });
            }

            // Historical Data (Session 3 and 4)
            if (s.CURRENTYEAR > 1) {
                const prevYear = s.CURRENTYEAR - 1;
                const histAvail = await connection.execute(
                    `SELECT sec.SectionID FROM SECTIONS sec JOIN COURSE_INSTANCES ci ON sec.InstanceID = ci.InstanceID JOIN COURSES c ON ci.CourseID = c.CourseID WHERE ci.SessionID IN (3, 4) AND c.Department = :1 AND c.RecommendedYear = :2`,
                    [s.BRANCH, prevYear]
                );
                for (const sec of histAvail.rows) {
                    const rid = (await connection.execute(`SELECT SEQ_REGISTRATIONS.NEXTVAL AS ID FROM DUAL`)).rows[0].ID;
                    const grade = grades[Math.floor(Math.random() * grades.length)];
                    await connection.execute(
                        `INSERT INTO STUDENT_REGISTRATIONS (RegistrationID, StudentID, SectionID, RegistrationDate, RegStatus, Grade) 
                         VALUES (:1, :2, :3, SYSDATE - 365, 'Registered', :4)`,
                        [rid, s.STUDENTID, sec.SECTIONID, grade]
                    );
                }
            }
        }
        await connection.execute(`UPDATE STUDENT_REGISTRATIONS SET RegStatus = 'Registered' WHERE RegStatus = 'Pending'`);
        await connection.execute(`UPDATE SECTIONS s SET EnrolledCount = (SELECT COUNT(*) FROM STUDENT_REGISTRATIONS sr WHERE sr.SectionID = s.SectionID AND sr.RegStatus = 'Registered')`);
        await connection.commit();

        // 9. Attendance (Only for Current session 2)
        console.log('📉 Generating Attendance for Current Session (Session 2)...');
        const regs = await connection.execute(
            `SELECT sr.StudentID, sr.SectionID FROM STUDENT_REGISTRATIONS sr JOIN SECTIONS sec ON sr.SectionID = sec.SectionID JOIN COURSE_INSTANCES ci ON sec.InstanceID = ci.InstanceID WHERE ci.SessionID = 2`
        );
        const startDate = new Date(2025, 0, 10);
        for (const r of regs.rows) {
            const secFac = await connection.execute('SELECT FacultyID FROM SECTIONS WHERE SectionID = :1', [r.SECTIONID]);
            for (let d = 0; d < 20; d++) {
                const attDate = new Date(startDate);
                attDate.setDate(startDate.getDate() + d * 3);
                if (attDate > new Date()) continue;
                const status = Math.random() < 0.85 ? 'Present' : 'Absent';
                await connection.execute(
                    `BEGIN PKG_ATTENDANCE.SP_MARK_ATTENDANCE(:1, :2, :3, 1, :4, :5, :6); END;`,
                    { 1: r.STUDENTID, 2: r.SECTIONID, 3: attDate, 4: status, 5: secFac.rows[0].FACULTYID, 6: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 500 } }
                );
            }
        }
        await connection.commit();

        const statCourses = await connection.execute('SELECT COUNT(*) AS C FROM COURSES');
        const statRegs = await connection.execute('SELECT COUNT(*) AS C FROM STUDENT_REGISTRATIONS');
        const statGrades = await connection.execute('SELECT COUNT(*) AS C FROM STUDENT_REGISTRATIONS WHERE Grade IS NOT NULL');
        console.log(`✅ Success! Courses: ${statCourses.rows[0].C}. Total Regs: ${statRegs.rows[0].C}. Historical Passed: ${statGrades.rows[0].C}.`);

    } catch (err) {
        console.error('❌ Seeding Failed:', err);
    } finally {
        await connection.close();
        await db.close();
    }
}

seed();
