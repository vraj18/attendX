const db = require('./db');

(async () => {
   try {
     await db.init();
     const studentId = 17;
     
     console.log(`--- Verifying Prerequisites for Student ID ${studentId} (Failed CS101) ---`);
     
     // 1. Check prerequisite status
     const prereqs = await db.execute(`
        SELECT cp.PrereqCourseID, c.CourseCode, c.CourseName, sr.Grade
        FROM COURSE_PREREQUISITES cp
        JOIN COURSES c ON cp.PrereqCourseID = c.CourseID
        LEFT JOIN (
           SELECT ci.CourseID, sr.Grade
           FROM STUDENT_REGISTRATIONS sr
           JOIN SECTIONS sec ON sr.SectionID = sec.SectionID
           JOIN COURSE_INSTANCES ci ON sec.InstanceID = ci.InstanceID
           WHERE sr.StudentID = :sid
        ) sr ON cp.PrereqCourseID = sr.CourseID
        WHERE cp.CourseID = 2 -- CS102
     `, { sid: studentId });
     console.log('Prerequisites for CS102:', prereqs.rows);

     // 2. Fetch available sections via API
     const response = await fetch(`http://localhost:3000/api/registration/sections?studentId=${studentId}`);
     const resData = await response.json();
     const sections = resData.data;
     
     // Look for CS102 (Prereq is CS101 which is failed)
     const cs102 = sections.find(s => s.COURSECODE === 'CS102');
     if (cs102) {
        console.error('❌ FAIL: CS102 is available even though CS101 was failed!');
     } else {
        console.log('✅ SUCCESS: CS102 is correctly hidden due to failed prerequisite.');
     }

     // 3. Check Student ID 13 (Passed CS101)
     const sidPassed = 13;
     console.log(`\n--- Verifying Prerequisites for Student ID ${sidPassed} (Passed CS101) ---`);
     const resp2 = await fetch(`http://localhost:3000/api/registration/sections?studentId=${sidPassed}`);
     const data2 = await resp2.json();
     const cs102_2 = data2.data.find(s => s.COURSECODE === 'CS102');
     if (cs102_2) {
        console.log('✅ SUCCESS: CS102 is visible for student who passed CS101.');
     } else {
        console.error('❌ FAIL: CS102 is hidden even though CS101 was passed!');
     }

   } catch(e) { console.error('Error during verification:', e.message); }
   process.exit(0);
})();
