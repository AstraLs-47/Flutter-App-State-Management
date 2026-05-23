const Exercise = require('../models/Exercise');

class ExerciseService {
  static async listExercises({ categoryId, limit, offset }) {
    const exercises = await Exercise.findAll(categoryId, limit, offset);
    const total = await Exercise.count(categoryId);

    return {
      exercises,
      pagination: {
        total,
        limit,
        offset,
        hasMore: offset + limit < total
      }
    };
  }

  static async getExercise(id) {
    const exercise = await Exercise.findById(id);
    if (!exercise) {
      throw new Error('EXERCISE_NOT_FOUND');
    }
    return exercise;
  }

  static async createExercise(data, userId) {
    if (!data.name) {
      throw new Error('VALIDATION_ERROR:Exercise name is required');
    }

    return await Exercise.create({
      name: data.name,
      description: data.description,
      categoryId: data.categoryId || data.category_id,
      phases: data.phases,
      createdBy: userId
    });
  }

  static async updateExercise(id, data) {
    const exercise = await Exercise.findById(id);
    if (!exercise) {
      throw new Error('EXERCISE_NOT_FOUND');
    }

    const updated = await Exercise.update(id, {
      name: data.name,
      description: data.description,
      categoryId: data.categoryId || data.category_id,
      phases: data.phases
    });

    return updated;
  }

  static async deleteExercise(id) {
    const exercise = await Exercise.findById(id);
    if (!exercise) {
      throw new Error('EXERCISE_NOT_FOUND');
    }

    await Exercise.delete(id);
    return { id };
  }
}

module.exports = ExerciseService;