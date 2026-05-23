const express = require('express');
const router = express.Router();
const announcementController = require('../controllers/announcementController');
const { authenticate, authorize } = require('../middleware/auth');

router.get('/', (req, res, next) => announcementController.list(req, res, next));
router.get('/:id', (req, res, next) => announcementController.getById(req, res, next));
router.post('/', authenticate, authorize('admin'), (req, res, next) => announcementController.create(req, res, next));
router.put('/:id', authenticate, authorize('admin'), (req, res, next) => announcementController.update(req, res, next));
router.delete('/:id', authenticate, authorize('admin'), (req, res, next) => announcementController.delete(req, res, next));

module.exports = router;