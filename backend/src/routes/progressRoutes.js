const express = require('express');
const router = express.Router();
const progressController = require('../controllers/progressController');
const { authenticate } = require('../middleware/auth');

router.use(authenticate);

router.get('/stats', (req, res, next) => progressController.getStats(req, res, next));
router.get('/', (req, res, next) => progressController.listMyEntries(req, res, next));
router.get('/:id', (req, res, next) => progressController.getById(req, res, next));
router.post('/', (req, res, next) => progressController.create(req, res, next));
router.put('/:id', (req, res, next) => progressController.update(req, res, next));
router.delete('/:id', (req, res, next) => progressController.delete(req, res, next));

module.exports = router;