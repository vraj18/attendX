const fs = require('fs');
const path = require('path');
const db = require('./db');

function stripComments(content) {
  // Remove single line comments
  let stripped = content.replace(/--.*$/gm, '');
  // Remove multi-line comments
  stripped = stripped.replace(/\/\*[\s\S]*?\*\//g, '');
  return stripped;
}

function parseSqlFile(content) {
  const stmts = [];
  // Split by / on a line by itself
  const chunks = content.split(/\r?\n\s*\/\s*(\r?\n|$)/);
  
  for (let chunk of chunks) {
    let raw = chunk.trim();
    if (!raw) continue;
    
    // Logic: If the chunk contains standard PL/SQL keywords, treat as ONE block.
    // We check for these keywords AFTER stripping comments to be sure.
    const strippedChunk = stripComments(raw).trim();
    if (!strippedChunk) continue;

    const isPlSql = /BEGIN|DECLARE|CREATE\s+OR\s+REPLACE\s+(FUNCTION|PROCEDURE|PACKAGE|TRIGGER|TYPE)/i.test(strippedChunk);
    
    if (isPlSql) {
      stmts.push(raw); 
    } else {
      // Split by ; for regular SQL statements
      // We need to split the original but based on positions in stripped
      // OR just split the stripped and execute that.
      // Easiest is to split the stripped chunk.
      const parts = strippedChunk.split(';');
      for (let p of parts) {
        const s = p.trim();
        if (s && !s.toUpperCase().startsWith('PROMPT') && !s.toUpperCase().startsWith('SET ')) {
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
    const files = [
      '01_schema.sql',
      '02_sequences.sql',
      '03_types.sql',
      '04_triggers.sql',
      '05_functions.sql',
      '06_pkg_registration.sql',
      '07_pkg_attendance.sql',
      '08_sample_data.sql'
    ];
    
    for (const f of files) {
      console.log(`🚀 Processing ${f}...`);
      const p = path.join(__dirname, '../sql', f);
      if (!fs.existsSync(p)) {
        console.warn(`  ⚠️ File not found: ${f}`);
        continue;
      }
      
      const content = fs.readFileSync(p, 'utf8');
      const stmts = parseSqlFile(content);
      
      for (let i = 0; i < stmts.length; i++) {
        let s = stmts[i];
        try {
          // If it's a PL/SQL block, make sure it DOES NOT have trailing / but MUST have END;
          // oracledb execute() handles PL/SQL blocks ending in END;
          await db.execute(s);
          // console.log(`  ✅ Success [stmt ${i+1}]`);
        } catch (err) {
          const ignorable = ['ORA-00942','ORA-00955','ORA-01430','ORA-02260','ORA-02261','ORA-02275','ORA-01432','ORA-04043','ORA-00001','ORA-02291'];
          if (!ignorable.some(code => err.message.includes(code))) {
             console.error(`  ❌ Error in ${f} at statement ${i+1}:`);
             console.error(`     ${err.message.substring(0, 150)}`);
             console.error(`     SQL snippet: ${s.substring(0, 100)}...`);
          }
        }
      }
    }
    console.log('\n✨ Database repair and synchronization complete.');
  } catch (err) {
    console.error('FATAL ERROR:', err.message);
  } finally {
    await db.close();
  }
}

main();
