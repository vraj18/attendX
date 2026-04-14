const db = require('./db');

async function checkErrors() {
  try {
    await db.init();
    const result = await db.execute(
      `SELECT type, line, position, text 
       FROM user_errors 
       WHERE name = 'PKG_REGISTRATION' 
       ORDER BY type, line`
    );
    if (result.rows.length > 0) {
      console.log('❌ Package Compilation Errors:');
      result.rows.forEach(err => {
        console.log(`${err.TYPE} - Line ${err.LINE}:${err.POSITION} - ${err.TEXT}`);
      });
    } else {
      console.log('✅ No errors found in PKG_REGISTRATION BODY');
    }
  } catch (err) {
    console.error('Error querying user_errors:', err.message);
  } finally {
    await db.close();
  }
}

checkErrors();
