const db = require('./db');
(async () => {
   try {
     await db.init();
     const res = await db.execute(`SELECT RegistrationID, StudentID, SectionID, RegStatus, Grade FROM STUDENT_REGISTRATIONS`);
     console.log('Total registrations:', res.rows.length);
     const res2 = await db.execute(`SELECT RegistrationID, StudentID, SectionID, RegStatus, Grade FROM STUDENT_REGISTRATIONS WHERE Grade IS NOT NULL`);
     console.log('Registrations with Grade:', res2.rows.length);
     const res3 = await db.execute(`SELECT RegistrationID, StudentID, SectionID, RegStatus, Grade FROM STUDENT_REGISTRATIONS WHERE Grade = 'FF'`);
     console.log('Registrations with Grade FF:', res3.rows.length);
     if (res3.rows.length > 0) {
        console.dir(res3.rows.slice(0, 5));
     }
   } catch(e) { console.error(e); }
   process.exit(0);
})();
