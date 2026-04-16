const fs = require('fs');
const path = require('path');
const db = require('./db');

async function patchDb() {
  try {
    await db.init();
    
    console.log('Applying Table Check Constraint Alteration...');
    await db.execute(`ALTER TABLE STUDENT_REGISTRATIONS DROP CONSTRAINT CHK_REG_STATUS`);
    await db.execute(`ALTER TABLE STUDENT_REGISTRATIONS ADD CONSTRAINT CHK_REG_STATUS CHECK (RegStatus IN ('Pending','Registered','Dropped','Waitlisted','Rejected'))`);
    await db.execute(`ALTER TABLE COURSES ADD SemesterType VARCHAR2(6) DEFAULT 'Both'`);
    await db.execute(`ALTER TABLE STUDENT_REGISTRATIONS ADD Grade VARCHAR2(3)`);
    await db.execute(`ALTER TABLE STUDENT_REGISTRATIONS ADD CONSTRAINT CHK_REG_GRADE CHECK (Grade IN ('AA','AB','BB','BC','CC','CD','DD','W','FF','LL') OR Grade IS NULL)`);
    console.log('✅ Altered STUDENT_REGISTRATIONS and COURSES tables successfully.');

    console.log('Applying PKG_REGISTRATION update...');
    const sqlFile = path.join(__dirname, '..', 'sql', '06_pkg_registration.sql');
    let pkgSql = fs.readFileSync(sqlFile, 'utf8');
    
    // We need to split CREATE OR REPLACE PACKAGE and CREATE OR REPLACE PACKAGE BODY
    const blocks = pkgSql.split(/-- ====== PACKAGE BODY =======================================/);
    if(blocks.length === 2) {
      let spec = blocks[0].replace(/--.*$/gm, '').trim().replace(/\/\s*$/, '').trim();
      let body = blocks[1].replace(/--.*$/gm, '').trim().replace(/\/\s*(PROMPT.*)?$/s, '').trim();
      await db.execute(spec);
      console.log('✅ Package specification updated.');
      await db.execute(body);
      console.log('✅ Package body updated.');
    } else {
      console.log('Could not parse pkg sql');
    }

    console.log('✨ Database patch complete.');
  } catch (err) {
    console.error('❌ Patch error:', err.message);
  } finally {
    await db.close();
  }
}

patchDb();
