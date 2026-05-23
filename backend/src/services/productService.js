const Product = require('../models/Product');

class ProductService {
  static formatProduct(product) {
    return {
      id: product.id,
      name: product.name,
      description: product.description,
      category: product.category,
      price: product.price,
      stockQuantity: product.stockQuantity,
      imageUrl: product.imageUrl,
      isActive: product.isActive,
      createdBy: product.createdBy,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt
    };
  }

  static async list(page = 1, limit = 50) {
    const offset = (page - 1) * limit;
    const products = await Product.findActive(limit, offset);
    const total = await Product.count();

    console.log('📋 Products found in list:', products.length);

    return {
      products: products.map(p => this.formatProduct(p)),
      pagination: { page, limit, total, pages: Math.ceil(total / limit) }
    };
  }

  static async getById(id) {
    const product = await Product.findById(id);
    if (!product) {
      const error = new Error('Product not found');
      error.statusCode = 404;
      throw error;
    }
    return this.formatProduct(product);
  }

  static async create(data) {
    const product = await Product.create(data);
    return this.formatProduct(product);
  }

  static async update(id, data) {
    const existing = await Product.findById(id);
    if (!existing) {
      const error = new Error('Product not found');
      error.statusCode = 404;
      throw error;
    }
    
    const product = await Product.update(id, data);
    console.log('✅ Product updated in service:', product ? 'Success' : 'Failed');
    return this.formatProduct(product);
  }

  static async delete(id) {
    const existing = await Product.findById(id);
    if (!existing) {
      const error = new Error('Product not found');
      error.statusCode = 404;
      throw error;
    }
    await Product.delete(id);
    return { message: 'Product deleted successfully' };
  }
}

module.exports = ProductService;