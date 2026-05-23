const CategoryService = require('../services/categoryService');

class CategoryController {
  static async listCategories(req, res) {
    try {
      const categories = await CategoryService.listCategories();

      res.json({
        success: true,
        data: categories
      });
    } catch (error) {
      console.error('List categories error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch categories'
      });
    }
  }

  static async createCategory(req, res) {
    try {
      const category = await CategoryService.createCategory(req.body);

      res.status(201).json({
        success: true,
        message: 'Category created successfully',
        data: category
      });
    } catch (error) {
      if (error.message.startsWith('VALIDATION_ERROR:')) {
        return res.status(400).json({
          success: false,
          message: error.message.replace('VALIDATION_ERROR:', '')
        });
      }

      console.error('Create category error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to create category'
      });
    }
  }

  static async deleteCategory(req, res) {
    try {
      await CategoryService.deleteCategory(req.params.id);

      res.json({
        success: true,
        message: 'Category deleted successfully'
      });
    } catch (error) {
      if (error.message === 'CATEGORY_NOT_FOUND') {
        return res.status(404).json({
          success: false,
          message: 'Category not found'
        });
      }

      console.error('Delete category error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to delete category'
      });
    }
  }
}

module.exports = CategoryController;