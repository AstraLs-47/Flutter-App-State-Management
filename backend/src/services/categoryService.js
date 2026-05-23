const Category = require('../models/Category');

class CategoryService {
  static async listCategories() {
    return await Category.findAll();
  }

  static async createCategory({ name, icon }) {
    if (!name) {
      throw new Error('VALIDATION_ERROR:Category name is required');
    }

    const existing = await Category.findAll();
    const duplicate = existing.find(c => c.name.toLowerCase() === name.toLowerCase());
    if (duplicate) {
      throw new Error('VALIDATION_ERROR:Category already exists');
    }

    return await Category.create({ name, icon });
  }

  static async deleteCategory(id) {
    const category = await Category.findById(id);
    if (!category) {
      throw new Error('CATEGORY_NOT_FOUND');
    }

    await Category.delete(id);
    return { id };
  }
}

module.exports = CategoryService;