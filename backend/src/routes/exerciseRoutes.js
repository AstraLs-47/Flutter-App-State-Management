const express = require('express');
const router = express.Router();
const ExerciseController = require('../controllers/exerciseController');
const { authenticate, authorize } = require('../middleware/auth');

// Public routes
router.get('/', ExerciseController.listExercises);
router.get('/:id', ExerciseController.getExercise);

// Admin routes
router.post('/', authenticate, authorize('admin'), ExerciseController.createExercise);
router.put('/:id', authenticate, authorize('admin'), ExerciseController.updateExercise);
router.delete('/:id', authenticate, authorize('admin'), ExerciseController.deleteExercise);

module.exports = router;