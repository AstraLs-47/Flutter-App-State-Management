const express = require('express');
const router = express.Router();
const healthController = require('../controllers/healthController');
const { authenticate } = require('../middleware/auth');

router.use(authenticate);

router.get('/latest', (req, res, next) => healthController.getLatestMetrics(req, res, next));
router.get('/', (req, res, next) => healthController.listHistory(req, res, next));
router.post('/', (req, res, next) => healthController.addEntry(req, res, next));
router.get('/:id', (req, res, next) => healthController.getById(req, res, next));
router.put('/:id', (req, res, next) => healthController.updateMetrics(req, res, next));
router.delete('/:id', (req, res, next) => healthController.deleteEntry(req, res, next));

module.exports = router;