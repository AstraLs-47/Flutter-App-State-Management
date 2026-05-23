const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');
const { authenticate, authorize } = require('../middleware/auth');

router.get('/', (req, res, next) => productController.list(req, res, next));
router.get('/:id', (req, res, next) => productController.getById(req, res, next));
router.post('/', authenticate, authorize('admin'), (req, res, next) => productController.create(req, res, next));
router.put('/:id', authenticate, authorize('admin'), (req, res, next) => productController.update(req, res, next));
router.delete('/:id', authenticate, authorize('admin'), (req, res, next) => productController.delete(req, res, next));

module.exports = router;