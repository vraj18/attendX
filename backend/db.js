// =============================================================
// db.js — Oracle Connection Pool
// Update DB_CONFIG with your Oracle credentials
// =============================================================
const oracledb = require('oracledb');

// ── CONFIGURE THESE ──────────────────────────────────────────
const DB_CONFIG = {
  user:             process.env.DB_USER     || 'system',
  password:         process.env.DB_PASSWORD || 'oracle123',
  connectString:    process.env.DB_CONNECT  || 'localhost:1521/XE',
  poolMin:  2,
  poolMax:  10,
  poolIncrement: 2
};
// ─────────────────────────────────────────────────────────────

// Use Thick mode if Oracle Instant Client is installed at a custom path.
// Comment out if oracledb finds the client automatically.
// oracledb.initOracleClient({ libDir: '/opt/oracle/instantclient_21_3' });

// Return rows as plain JS objects (not array-of-arrays)
oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
// Auto-commit helper OFF by default (we commit inside PL/SQL)
oracledb.autoCommit = false;

let pool;

async function init() {
  pool = await oracledb.createPool(DB_CONFIG);
  console.log('✅  Oracle connection pool created');
}

async function execute(sql, binds = [], opts = {}) {
  let conn;
  try {
    conn = await pool.getConnection();
    const result = await conn.execute(sql, binds, { outFormat: oracledb.OUT_FORMAT_OBJECT, ...opts });
    return result;
  } finally {
    if (conn) await conn.close();
  }
}

async function close() {
  if (pool) await pool.close(0);
}

module.exports = { init, execute, close };
