const db = require('./db');

(async () => {
   try {
     await db.init();
     const studentId = 13;
     
     console.log('--- Testing Registration Eligibility for Student ID 13 ---');
     
     // 1. Check failed courses
     const failed = await db.execute(`
        SELECT c.CourseCode, c.CourseName, c.SemesterType
        FROM STUDENT_REGISTRATIONS sr
        JOIN SECTIONS sec ON sr.SectionID = sec.SectionID
        JOIN COURSE_INSTANCES ci ON sec.InstanceID = ci.InstanceID
        JOIN COURSES c ON ci.CourseID = c.CourseID
        WHERE sr.StudentID = :id AND sr.Grade = 'FF'
     `, [studentId]);
     console.log('Failed Courses:', failed.rows);

     // 2. Fetch available sections via API
     const response = await fetch(`http://localhost:3000/api/registration/sections?studentId=${studentId}`);
     const resData = await response.json();
     const sections = resData.data;
     
     console.log('Total Available Sections for Student:', sections.length);
     
     // Check each failed course
     for (const f of failed.rows) {
        const match = sections.find(s => s.COURSECODE === f.COURSECODE);
        if (match) {
           console.log(`⚠️ Course ${f.COURSECODE} is available. Checking parity...`);
           const sessionParity = match.SESSIONNAME.toUpperCase().includes('ODD') ? 'Odd' : 'Even';
           if (f.SEMESTERTYPE !== 'Both' && f.SEMESTERTYPE !== sessionParity) {
               console.error(`❌ FAIL: ${f.COURSECODE} (${f.SEMESTERTYPE}) is available in ${sessionParity} session!`);
           } else {
               console.log(`✅ OK: ${f.COURSECODE} is available in ${sessionParity} session (Matches parity).`);
           }
        } else {
           console.log(`✅ OK: ${f.COURSECODE} is currently hidden (likely due to parity mismatch).`);
        }
     }

     // Look for a course the student already passed
     const passedCode = 'CS201'; // From screenshot
     const matchPassed = sections.find(s => s.COURSECODE === passedCode);
     if (matchPassed) {
        console.error(`❌ FAIL: ${passedCode} (Passed) is still available!`);
     } else {
        console.log(`✅ SUCCESS: Passed courses are correctly hidden.`);
     }

   } catch(e) { console.error('Error during verification:', e.message); }
   process.exit(0);
})();
