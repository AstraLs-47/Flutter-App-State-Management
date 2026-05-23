const express = require('express');
const router = express.Router();
const CategoryController = require('../controllers/categoryController');
const { authenticate, authorize } = require('../middleware/auth');

// Public
router.get('/', CategoryController.listCategories);

// Admin
router.post('/', authenticate, authorize('admin'), CategoryController.createCategory);
router.delete('/:id', authenticate, authorize('admin'), CategoryController.deleteCategory);

module.exports = router;