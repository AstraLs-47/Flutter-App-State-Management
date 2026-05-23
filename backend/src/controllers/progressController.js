const progressService = require('../services/progressService');

class ProgressController {
  async listMyEntries(req, res, next) {
    try {
      const { page = 1, limit = 50 } = req.query;
      const result = await progressService.listMyEntries(req.user.id, parseInt(page), parseInt(limit));
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async getById(req, res, next) {
    try {
      const entry = await progressService.getById(parseInt(req.params.id), req.user.id);
      res.json(entry);
    } catch (error) {
      next(error);
    }
  }

  async create(req, res, next) {
    try {
      const { exerciseId, weight, reps, sets, durationMinutes, notes, entryDate } = req.body;
      const entry = await progressService.create(req.user.id, {
        exerciseId: exerciseId ? parseInt(exerciseId) : null,
        weight: weight ? parseFloat(weight) : null,
        reps: reps ? parseInt(reps) : null,
        sets: sets ? parseInt(sets) : null,
        durationMinutes: durationMinutes ? parseInt(durationMinutes) : null,
        notes, entryDate
      });
      res.status(201).json(entry);
    } catch (error) {
      next(error);
    }
  }

  async update(req, res, next) {
    try {
      const { exerciseId, weight, reps, sets, durationMinutes, notes, entryDate } = req.body;
      const entry = await progressService.update(parseInt(req.params.id), req.user.id, {
        exerciseId: exerciseId ? parseInt(exerciseId) : null,
        weight: weight ? parseFloat(weight) : null,
        reps: reps ? parseInt(reps) : null,
        sets: sets ? parseInt(sets) : null,
        durationMinutes: durationMinutes ? parseInt(durationMinutes) : null,
        notes, entryDate
      });
      res.json(entry);
    } catch (error) {
      next(error);
    }
  }

  async delete(req, res, next) {
    try {
      const result = await progressService.delete(parseInt(req.params.id), req.user.id);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async getStats(req, res, next) {
    try {
      const stats = await progressService.getStats(req.user.id);
      res.json(stats);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ProgressController();