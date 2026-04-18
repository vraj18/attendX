const db = require('./db');
const axios = require('axios');

async function test() {
  await db.init();
  try {
    console.log("---- Testing Admin Student Registration ----");
    
    // Find an active session and a section
    const secRes = await db.execute(`SELECT SectionID FROM SECTIONS FETCH FIRST 1 ROWS ONLY`);
    const sectionId = secRes.rows[0].SECTIONID;
    
    const stuRes = await db.execute(`SELECT RollNumber, StudentID FROM STUDENTS FETCH FIRST 1 ROWS ONLY`);
    const studentIdNum = stuRes.rows[0].STUDENTID;
    const rollNumber = stuRes.rows[0].ROLLNUMBER;

    console.log(`Using RollNumber: ${rollNumber}, numeric ID: ${studentIdNum}, Section: ${sectionId}`);

    // Register
    console.log("-> Registering using Roll Number");
    const regRes = await axios.post('http://localhost:3000/api/registration/register', {
      studentId: rollNumber,
      sectionId: sectionId
    });
    console.log("Registration Response:", regRes.data);

    // Drop
    console.log("-> Dropping using Roll Number");
    const dropRes = await axios.post('http://localhost:3000/api/registration/drop-section', {
      studentId: rollNumber,
      sectionId: sectionId,
      reason: "Test Drop"
    });
    console.log("Drop Response:", dropRes.data);

    // Re-register
    console.log("-> Re-registering using Roll Number");
    const reRegRes = await axios.post('http://localhost:3000/api/registration/register', {
      studentId: rollNumber,
      sectionId: sectionId
    });
    console.log("Re-registration Response:", reRegRes.data);
    
    console.log("✅ All Registration Flows OK!");
  } catch(e) {
    console.error("Test failed:", e.response ? e.response.data : e.message);
  } finally {
    await db.close();
  }
}
test();
