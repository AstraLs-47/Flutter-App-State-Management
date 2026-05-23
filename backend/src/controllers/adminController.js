const AdminService = require('../services/adminService');

class AdminController {
  static async getDashboard(req, res) {
    try {
      const dashboard = await AdminService.getDashboard();
      res.json({ success: true, data: dashboard });
    } catch (error) {
      console.error('Dashboard error:', error);
      res.status(500).json({ success: false, message: 'Failed to fetch dashboard' });
    }
  }

  static async getUserStats(req, res) {
    try {
      const stats = await AdminService.getUserStats();
      res.json({ success: true, data: stats });
    } catch (error) {
      console.error('User stats error:', error);
      res.status(500).json({ success: false, message: 'Failed to fetch user stats' });
    }
  }

  static async getExerciseStats(req, res) {
    try {
      const stats = await AdminService.getExerciseStats();
      res.json({ success: true, data: stats });
    } catch (error) {
      console.error('Exercise stats error:', error);
      res.status(500).json({ success: false, message: 'Failed to fetch exercise stats' });
    }
  }

  static async getProgressStats(req, res) {
    try {
      const stats = await AdminService.getProgressStats();
      res.json({ success: true, data: stats });
    } catch (error) {
      console.error('Progress stats error:', error);
      res.status(500).json({ success: false, message: 'Failed to fetch progress stats' });
    }
  }

  static async getHealthStats(req, res) {
    try {
      const stats = await AdminService.getHealthStats();
      res.json({ success: true, data: stats });
    } catch (error) {
      console.error('Health stats error:', error);
      res.status(500).json({ success: false, message: 'Failed to fetch health stats' });
    }
  }

  static async getProductStats(req, res) {
    try {
      const stats = await AdminService.getProductStats();
      res.json({ success: true, data: stats });
    } catch (error) {
      console.error('Product stats error:', error);
      res.status(500).json({ success: false, message: 'Failed to fetch product stats' });
    }
  }

  static async getActivityLogs(req, res) {
    try {
      const { limit = 100, offset = 0 } = req.query;
      const logs = await AdminService.getActivityLogs(parseInt(limit), parseInt(offset));
      res.json({ success: true, data: logs });
    } catch (error) {
      console.error('Activity logs error:', error);
      res.status(500).json({ success: false, message: 'Failed to fetch activity logs' });
    }
  }

  static async getActivityStats(req, res) {
    try {
      const stats = await AdminService.getActivityStats();
      res.json({ success: true, data: stats });
    } catch (error) {
      console.error('Activity stats error:', error);
      res.status(500).json({ success: false, message: 'Failed to fetch activity stats' });
    }
  }
}

module.exports = AdminController;