const ExerciseService = require('../services/exerciseService');

class ExerciseController {
  static async listExercises(req, res) {
    try {
      const { category_id, limit = 50, offset = 0 } = req.query;

      const result = await ExerciseService.listExercises({
        categoryId: category_id,
        limit: parseInt(limit),
        offset: parseInt(offset)
      });

      res.json({
        success: true,
        data: result.exercises,
        pagination: result.pagination
      });
    } catch (error) {
      console.error('List exercises error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch exercises'
      });
    }
  }

  static async getExercise(req, res) {
    try {
      const exercise = await ExerciseService.getExercise(req.params.id);

      res.json({
        success: true,
        data: exercise
      });
    } catch (error) {
      if (error.message === 'EXERCISE_NOT_FOUND') {
        return res.status(404).json({
          success: false,
          message: 'Exercise not found'
        });
      }

      console.error('Get exercise error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch exercise'
      });
    }
  }

  static async createExercise(req, res) {
    try {
      const exercise = await ExerciseService.createExercise(req.body, req.user.id);

      res.status(201).json({
        success: true,
        message: 'Exercise created successfully',
        data: exercise
      });
    } catch (error) {
      if (error.message.startsWith('VALIDATION_ERROR:')) {
        return res.status(400).json({
          success: false,
          message: error.message.replace('VALIDATION_ERROR:', '')
        });
      }

      console.error('Create exercise error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to create exercise'
      });
    }
  }

  static async updateExercise(req, res) {
    try {
      const exercise = await ExerciseService.updateExercise(req.params.id, req.body);

      res.json({
        success: true,
        message: 'Exercise updated successfully',
        data: exercise
      });
    } catch (error) {
      if (error.message === 'EXERCISE_NOT_FOUND') {
        return res.status(404).json({
          success: false,
          message: 'Exercise not found'
        });
      }

      console.error('Update exercise error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update exercise'
      });
    }
  }

  static async deleteExercise(req, res) {
    try {
      await ExerciseService.deleteExercise(req.params.id);

      res.json({
        success: true,
        message: 'Exercise deleted successfully'
      });
    } catch (error) {
      if (error.message === 'EXERCISE_NOT_FOUND') {
        return res.status(404).json({
          success: false,
          message: 'Exercise not found'
        });
      }

      console.error('Delete exercise error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to delete exercise'
      });
    }
  }
}

module.exports = ExerciseController;