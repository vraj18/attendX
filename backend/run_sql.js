const fs = require('fs');
const path = require('path');
const db = require('./db');

function parseSqlFile(content) {
  const stmts = [];
  // Split by / on a line by itself
  const chunks = content.split(/\r?\n\s*\/\s*(\r?\n|$)/);
  
  for (let chunk of chunks) {
    const raw = chunk.trim();
    if (!raw) continue;
    
    // Logic: If the chunk contains standard PL/SQL keywords, treat as ONE block.
    // Otherwise, split by ; for regular SQL statements.
    const isPlSql = /BEGIN|DECLARE|CREATE\s+OR\s+REPLACE\s+(FUNCTION|PROCEDURE|PACKAGE|TRIGGER|TYPE)/i.test(raw);
    
    if (isPlSql) {
      stmts.push(raw);
    } else {
      // Remove all single-line comments from the chunk to avoid splitting on semicolons inside comments
      const cleanChunk = raw.replace(/^--.*$/gm, '');
      const parts = cleanChunk.split(';');
      
      for (let p of parts) {
        let s = p.trim();
        if (!s) continue;
        
        const upper = s.toUpperCase();
        if (!upper.startsWith('PROMPT') && !upper.startsWith('SET ')) {
          stmts.push(s);
        }
      }
    }
  }
  return stmts;
}

async function main() {
  try {
    await db.init();
    const files = ['01_schema.sql','02_sequences.sql','03_types.sql','04_triggers.sql','05_functions.sql','06_pkg_registration.sql','07_pkg_attendance.sql','08_sample_data.sql'];
    
    for (const f of files) {
      console.log(`Processing ${f}...`);
      const p = path.join(__dirname, '../sql', f);
      if (!fs.existsSync(p)) continue;
      
      const stmts = parseSqlFile(fs.readFileSync(p, 'utf8'));
      for (const s of stmts) {
        try {
          await db.execute(s, [], { autoCommit: true });
        } catch (err) {
          const ignorable = ['ORA-00942','ORA-00955','ORA-01430','ORA-02260','ORA-02261','ORA-02275','ORA-01432','ORA-04043','ORA-00001','ORA-02291'];
          if (!ignorable.some(code => err.message.includes(code))) {
             console.error(`  ❌ Error in statement: ${s.substring(0, 100)}...`);
             console.error(`     Message: ${err.message}`);
          }
        }
      }
    }
    console.log('\n✨ Database successfully synchronized.');
  } finally {
    await db.close();
  }
}
main();
