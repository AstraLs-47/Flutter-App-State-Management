const healthService = require('../services/healthService');

class HealthController {
  async getLatestMetrics(req, res, next) {
    try {
      const metrics = await healthService.getLatestMetrics(req.user.id);
      if (!metrics) {
        return res.status(404).json({ error: 'No health metrics found' });
      }
      res.json(metrics);
    } catch (error) {
      next(error);
    }
  }

  async getById(req, res, next) {
    try {
      const metrics = await healthService.getById(parseInt(req.params.id), req.user.id);
      res.json(metrics);
    } catch (error) {
      next(error);
    }
  }

  async listHistory(req, res, next) {
    try {
      const { page = 1, limit = 50 } = req.query;
      const result = await healthService.listHistory(req.user.id, parseInt(page), parseInt(limit));
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async addEntry(req, res, next) {
    try {
      const { weight, height, bodyFatPercentage, muscleMass, waterPercentage, restingHeartRate, bloodPressureSystolic, bloodPressureDiastolic, measurementDate } = req.body;
      const entry = await healthService.addEntry(req.user.id, {
        weight: weight ? parseFloat(weight) : null,
        height: height ? parseFloat(height) : null,
        bodyFatPercentage: bodyFatPercentage ? parseFloat(bodyFatPercentage) : null,
        muscleMass: muscleMass ? parseFloat(muscleMass) : null,
        waterPercentage: waterPercentage ? parseFloat(waterPercentage) : null,
        restingHeartRate: restingHeartRate ? parseInt(restingHeartRate) : null,
        bloodPressureSystolic: bloodPressureSystolic ? parseInt(bloodPressureSystolic) : null,
        bloodPressureDiastolic: bloodPressureDiastolic ? parseInt(bloodPressureDiastolic) : null,
        measurementDate
      });
      res.status(201).json(entry);
    } catch (error) {
      next(error);
    }
  }

  async updateMetrics(req, res, next) {
    try {
      const { weight, height, bodyFatPercentage, muscleMass, waterPercentage, restingHeartRate, bloodPressureSystolic, bloodPressureDiastolic, measurementDate } = req.body;
      const entry = await healthService.updateMetrics(parseInt(req.params.id), req.user.id, {
        weight: weight ? parseFloat(weight) : null,
        height: height ? parseFloat(height) : null,
        bodyFatPercentage: bodyFatPercentage ? parseFloat(bodyFatPercentage) : null,
        muscleMass: muscleMass ? parseFloat(muscleMass) : null,
        waterPercentage: waterPercentage ? parseFloat(waterPercentage) : null,
        restingHeartRate: restingHeartRate ? parseInt(restingHeartRate) : null,
        bloodPressureSystolic: bloodPressureSystolic ? parseInt(bloodPressureSystolic) : null,
        bloodPressureDiastolic: bloodPressureDiastolic ? parseInt(bloodPressureDiastolic) : null,
        measurementDate
      });
      res.json(entry);
    } catch (error) {
      next(error);
    }
  }

  async deleteEntry(req, res, next) {
    try {
      const result = await healthService.deleteEntry(parseInt(req.params.id), req.user.id);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new HealthController();