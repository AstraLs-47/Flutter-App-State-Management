const pool = require('../config/db');

class Exercise {
  static async findAll(categoryId, limit = 50, offset = 0) {
    let query = `
      SELECT e.*, c.name as category_name 
      FROM exercises e
      LEFT JOIN categories c ON e.category_id = c.id
      WHERE 1=1
    `;
    const values = [];
    let paramCount = 1;

    if (categoryId) {
      query += ` AND e.category_id = $${paramCount++}`;
      values.push(categoryId);
    }

    query += ` ORDER BY e.created_at DESC LIMIT $${paramCount++} OFFSET $${paramCount++}`;
    values.push(limit, offset);

    const result = await pool.query(query, values);
    return result.rows;
  }

  static async findById(id) {
    const result = await pool.query(
      `SELECT e.*, c.name as category_name 
       FROM exercises e
       LEFT JOIN categories c ON e.category_id = c.id
       WHERE e.id = $1`,
      [id]
    );
    return result.rows[0] || null;
  }

  static async create({ name, description, categoryId, phases, createdBy }) {
    const result = await pool.query(
      `INSERT INTO exercises (name, description, category_id, phases, created_by)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [name, description || null, categoryId || null, phases ? JSON.stringify(phases) : null, createdBy]
    );
    return result.rows[0];
  }

  static async update(id, { name, description, categoryId, phases }) {
    const fields = [];
    const values = [];
    let paramCount = 1;

    if (name !== undefined) {
      fields.push(`name = $${paramCount++}`);
      values.push(name);
    }
    if (description !== undefined) {
      fields.push(`description = $${paramCount++}`);
      values.push(description);
    }
    if (categoryId !== undefined) {
      fields.push(`category_id = $${paramCount++}`);
      values.push(categoryId);
    }
    if (phases !== undefined) {
      fields.push(`phases = $${paramCount++}`);
      values.push(JSON.stringify(phases));
    }

    if (fields.length === 0) return null;

    fields.push(`updated_at = CURRENT_TIMESTAMP`);
    values.push(id);

    const result = await pool.query(
      `UPDATE exercises SET ${fields.join(', ')} WHERE id = $${paramCount} RETURNING *`,
      values
    );
    return result.rows[0];
  }

  static async delete(id) {
    const result = await pool.query('DELETE FROM exercises WHERE id = $1 RETURNING id', [id]);
    return result.rows[0];
  }

  static async count(categoryId) {
    let query = 'SELECT COUNT(*) as total FROM exercises WHERE 1=1';
    const values = [];
    let paramCount = 1;

    if (categoryId) {
      query += ` AND category_id = $${paramCount++}`;
      values.push(categoryId);
    }

    const result = await pool.query(query, values);
    return parseInt(result.rows[0].total, 10);
  }
}

module.exports = Exercise;