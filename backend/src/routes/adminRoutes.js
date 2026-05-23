const express = require('express');
const router = express.Router();
const AdminController = require('../controllers/adminController');
const { authenticate, authorize } = require('../middleware/auth');

router.use(authenticate, authorize('admin'));

router.get('/dashboard', AdminController.getDashboard);
router.get('/users/stats', AdminController.getUserStats);
router.get('/exercises/stats', AdminController.getExerciseStats);
router.get('/progress/stats', AdminController.getProgressStats);
router.get('/health/stats', AdminController.getHealthStats);
router.get('/products/stats', AdminController.getProductStats);
router.get('/activity/logs', AdminController.getActivityLogs);
router.get('/activity/stats', AdminController.getActivityStats);

module.exports = router;