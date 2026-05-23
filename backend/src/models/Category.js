const pool = require('../config/db');

class Category {
  static async findAll() {
    const result = await pool.query('SELECT * FROM categories ORDER BY name');
    return result.rows;
  }

  static async findById(id) {
    const result = await pool.query('SELECT * FROM categories WHERE id = $1', [id]);
    return result.rows[0] || null;
  }

  static async create({ name, icon }) {
    const result = await pool.query(
      'INSERT INTO categories (name, icon) VALUES ($1, $2) RETURNING *',
      [name, icon || null]
    );
    return result.rows[0];
  }

  static async delete(id) {
    const result = await pool.query('DELETE FROM categories WHERE id = $1 RETURNING id', [id]);
    return result.rows[0];
  }
}

module.exports = Category;