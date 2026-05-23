const pool = require('./src/config/db');
const fs = require('fs');
const path = require('path');

const initDb = async () => {
  try {
    const schemaPath = path.join(__dirname, 'src', 'config', 'schema.sql');
    const sql = fs.readFileSync(schemaPath, 'utf8');

    console.log('Initializing database schema...');
    await pool.query(sql);
    console.log('Database tables created successfully.');
  } catch (err) {
    console.error('Database initialization failed:', err.message);
  } finally {
    await pool.end();
  }
};

initDb();
