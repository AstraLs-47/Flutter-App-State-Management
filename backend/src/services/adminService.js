const AdminStats = require('../models/AdminStats');

class AdminService {
  static async getDashboard() {
    return await AdminStats.getDashboardSummary();
  }

  static async getUserStats() {
    const stats = await AdminStats.getUserStats();
    return {
      totalUsers: parseInt(stats.total_users) || 0,
      adminCount: parseInt(stats.admin_count) || 0,
      regularUserCount: parseInt(stats.regular_user_count) || 0,
      newUsers30Days: parseInt(stats.new_users_30_days) || 0
    };
  }

  static async getExerciseStats() {
    const stats = await AdminStats.getExerciseStats();
    return {
      totalExercises: parseInt(stats.total_exercises) || 0,
      categoriesUsed: parseInt(stats.categories_used) || 0
    };
  }

  static async getProgressStats() {
    const stats = await AdminStats.getProgressStats();
    return {
      totalEntries: parseInt(stats.total_entries) || 0,
      activeUsers: parseInt(stats.active_users) || 0,
      totalMinutes: parseInt(stats.total_minutes) || 0,
      totalVolume: parseInt(stats.total_volume) || 0
    };
  }

  static async getHealthStats() {
    const stats = await AdminStats.getHealthStats();
    return {
      totalEntries: parseInt(stats.total_entries) || 0,
      usersTracking: parseInt(stats.users_tracking) || 0
    };
  }

  static async getProductStats() {
    const stats = await AdminStats.getProductStats();
    return {
      totalProducts: parseInt(stats.total_products) || 0,
      averagePrice: parseFloat(stats.average_price) || 0,
      minPrice: parseFloat(stats.min_price) || 0,
      maxPrice: parseFloat(stats.max_price) || 0
    };
  }

  static async getActivityLogs(limit = 100, offset = 0) {
    return await AdminStats.getActivityLogs(limit, offset);
  }

  static async getActivityStats() {
    const stats = await AdminStats.getActivityStats();
    return {
      totalActions: parseInt(stats.total_actions) || 0,
      activeUsers: parseInt(stats.active_users) || 0,
      activeDays: parseInt(stats.active_days) || 0
    };
  }
}

module.exports = AdminService;