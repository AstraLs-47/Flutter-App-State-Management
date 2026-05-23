const pool = require('../config/db');

class Product {
  constructor(row) {
    this.id = row.id;
    this.name = row.name;
    this.description = row.description;
    this.category = row.category;
    this.price = parseFloat(row.price);
    this.stockQuantity = row.stock_quantity;
    this.imageUrl = row.image_url;
    this.isActive = row.is_active;
    this.createdBy = row.created_by;
    this.createdAt = row.created_at;
    this.updatedAt = row.updated_at;
  }

  static mapRow(row) {
    return row ? new Product(row) : null;
  }

  static async findActive(limit = 50, offset = 0) {
    console.log('🔍 Product.findActive called');
    const result = await pool.query(
      `SELECT * FROM products 
       WHERE is_active = true 
       ORDER BY id 
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );
    console.log(`📊 Found ${result.rows.length} active products`);
    return result.rows.map(row => new Product(row));
  }

  static async findById(id) {
    const result = await pool.query(
      'SELECT * FROM products WHERE id = $1',
      [id]
    );
    return Product.mapRow(result.rows[0]);
  }

  static async count() {
    const result = await pool.query(
      'SELECT COUNT(*) as total FROM products WHERE is_active = true'
    );
    return parseInt(result.rows[0].total, 10);
  }

  static async create(data) {
    const { name, description, category, price, stockQuantity, imageUrl, createdBy } = data;
    const result = await pool.query(
      `INSERT INTO products (name, description, category, price, stock_quantity, image_url, created_by, is_active)
       VALUES ($1, $2, $3, $4, $5, $6, $7, true)
       RETURNING *`,
      [name, description, category, price, stockQuantity || 0, imageUrl, createdBy]
    );
    return Product.mapRow(result.rows[0]);
  }

  static async update(id, fields) {
    const updates = [];
    const values = [];
    let paramCount = 1;

    if (fields.name !== undefined) {
      updates.push(`name = $${paramCount++}`);
      values.push(fields.name);
    }
    if (fields.description !== undefined) {
      updates.push(`description = $${paramCount++}`);
      values.push(fields.description);
    }
    if (fields.category !== undefined) {
      updates.push(`category = $${paramCount++}`);
      values.push(fields.category);
    }
    if (fields.price !== undefined) {
      updates.push(`price = $${paramCount++}`);
      values.push(fields.price);
    }
    if (fields.stockQuantity !== undefined) {
      updates.push(`stock_quantity = $${paramCount++}`);
      values.push(fields.stockQuantity);
    }
    if (fields.imageUrl !== undefined) {
      updates.push(`image_url = $${paramCount++}`);
      values.push(fields.imageUrl);
    }
    if (fields.isActive !== undefined) {
      updates.push(`is_active = $${paramCount++}`);
      values.push(fields.isActive);
    }

    if (updates.length === 0) {
      return Product.findById(id);
    }

    updates.push('updated_at = CURRENT_TIMESTAMP');
    values.push(id);

    console.log('🔄 Executing UPDATE with:', updates);
    console.log('📦 Values:', values);

    const result = await pool.query(
      `UPDATE products SET ${updates.join(', ')} WHERE id = $${paramCount}
       RETURNING *`,
      values
    );
    
    console.log('✅ UPDATE result:', result.rows[0] ? 'Product updated' : 'No product found');
    return Product.mapRow(result.rows[0]);
  }

  static async delete(id) {
    // Soft delete - just set is_active to false
    const result = await pool.query(
      'UPDATE products SET is_active = false, updated_at = CURRENT_TIMESTAMP WHERE id = $1 RETURNING id',
      [id]
    );
    return result.rows[0];
  }
}

module.exports = Product;