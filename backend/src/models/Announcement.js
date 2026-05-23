const pool = require('../config/db');

class Announcement {
  static async findActive(limit = 20, offset = 0) {
    const result = await pool.query(
      `SELECT * FROM announcements 
       WHERE is_active = true AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP)
       ORDER BY priority DESC, published_at DESC LIMIT $1 OFFSET $2`,
      [limit, offset]
    );
    return result.rows;
  }

  static async findById(id) {
    const result = await pool.query('SELECT * FROM announcements WHERE id = $1', [id]);
    return result.rows[0];
  }

  static async count() {
    const result = await pool.query(
      `SELECT COUNT(*) as total FROM announcements 
       WHERE is_active = true AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP)`
    );
    return parseInt(result.rows[0].total, 10);
  }

  static async create(data) {
    const { title, content, priority, expiresAt } = data;
    const result = await pool.query(
      `INSERT INTO announcements (title, content, priority, expires_at)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [title, content, priority || 'normal', expiresAt]
    );
    return result.rows[0];
  }

  static async update(id, data) {
    const { title, content, priority, isActive, expiresAt } = data;
    const result = await pool.query(
      `UPDATE announcements SET title = $1, content = $2, priority = $3,
       is_active = $4, expires_at = $5, updated_at = CURRENT_TIMESTAMP
       WHERE id = $6 RETURNING *`,
      [title, content, priority, isActive, expiresAt, id]
    );
    return result.rows[0];
  }

  static async delete(id) {
    await pool.query('UPDATE announcements SET is_active = false WHERE id = $1', [id]);
  }
}

module.exports = Announcement;
