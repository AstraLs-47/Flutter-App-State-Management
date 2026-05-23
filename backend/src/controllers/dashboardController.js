const DashboardService = require('../services/dashboardService');

class DashboardController {
  static async getStats(req, res) {
    try {
      const stats = await DashboardService.getStats(req.user.id);
      res.json(stats);
    } catch (error) {
      console.error('Dashboard error:', error);
      res.status(500).json({ success: false, message: 'Failed to fetch dashboard stats' });
    }
  }
}

module.exports = DashboardController;