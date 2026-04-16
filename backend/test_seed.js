const db = require('./db');
const oracledb = require('oracledb');

async function test() {
    await db.init();
    try {
        console.log('Inserting courses...');
        await db.execute("INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear) VALUES (1, 'CS101', 'Intro to Programming', 4, 'CSE', 'UG', 'Both', 'DC', 1)");
        await db.execute("INSERT INTO COURSES (CourseID, CourseCode, CourseName, Credits, Department, CourseLevel, SemesterType, CourseCategory, RecommendedYear) VALUES (2, 'CS201', 'Data Structures', 4, 'CSE', 'UG', 'Both', 'DC', 2)");
        await db.execute("COMMIT");
        console.log('Done.');
    } catch (err) {
        console.error('Error:', err);
    } finally {
        await db.close();
    }
}

test();
