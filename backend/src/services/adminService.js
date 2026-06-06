const AdminStats = require('../models/AdminStats');

class AdminService {
  async getDashboardSummary() {
    const stats = await AdminStats.getDashboardSummary();
    return this.formatDashboardSummary(stats);
  }

  async getDashboardStats() {
    const stats = await AdminStats.getDashboardSummary();
    
    // Transform signupStats to engagementData (counts only as doubles)
    const engagementData = stats.signupStats && Array.isArray(stats.signupStats)
      ? stats.signupStats.map(d => parseFloat(d.count) || 0)
      : [];

    return {
      averageBmi: parseFloat(stats.health?.averageBmi) || 0,
      averageHeartRate: parseFloat(stats.health?.averageHeartRate) || 0,
      userActivity: stats.signupStats && Array.isArray(stats.signupStats)
        ? stats.signupStats.map(d => ({
            date: d.date,
            count: parseInt(d.count) || 0,
          }))
        : [],
      engagementData: engagementData
    };
  }

  async getUserStats() {
    const stats = await AdminStats.getUserStats();
    return stats ? stats.map(s => ({
      date: s.date,
      count: parseInt(s.count) || 0
    })) : [];
  }

  async getExerciseStats() {
    const stats = await AdminStats.getExerciseStats();
    return stats ? stats.map(s => ({
      category: s.category_name || s.category,
      count: parseInt(s.count) || 0
    })) : [];
  }

  async getProgressStats() {
    return await AdminStats.getProgressStats();
  }

  async getHealthStats() {
    return await AdminStats.getHealthStats();
  }

  async getProductStats() {
    return await AdminStats.getProductStats();
  }

  async getActivityLogs(page = 1, limit = 100) {
    const offset = (page - 1) * limit;
    const logs = await AdminStats.getActivityLogs(limit, offset);
    return {
      logs: logs.map(log => this.formatActivityLog(log)),
      pagination: { page, limit }
    };
  }

  async getActivityStats() {
    return await AdminStats.getActivityStats();
  }

  async logActivity(userId, action, entityType, entityId, metadata, ipAddress, userAgent) {
    return await AdminStats.logActivity(userId, action, entityType, entityId, metadata, ipAddress, userAgent);
  }

  formatActivityLog(log) {
    return {
      id: log.id,
      userId: log.user_id,
      userEmail: log.user_email,
      userName: log.first_name && log.last_name ? `${log.first_name} ${log.last_name}` : null,
      action: log.action,
      entityType: log.entity_type,
      entityId: log.entity_id,
      metadata: log.metadata,
      ipAddress: log.ip_address,
      userAgent: log.user_agent,
      createdAt: log.created_at
    };
  }

  formatDashboardSummary(stats) {
    if (!stats) return null;
    const categoryDistribution = {};
    if (stats.exercises && stats.exercises.byCategory) {
      stats.exercises.byCategory.forEach(c => {
        categoryDistribution[c.category] = parseFloat(c.count) || 0;
      });
    }

    const productTypeData = [];
    const productTypeLabels = [];
    const productCategoryDistribution = {};
    if (stats.products?.byCategory && Array.isArray(stats.products.byCategory)) {
      stats.products.byCategory.forEach(c => {
        const label = c.category?.toString() ?? 'Unknown';
        productTypeLabels.push(label);
        productTypeData.push(parseFloat(c.count) || 0);
        if (label && label.toLowerCase() !== 'all') {
          productCategoryDistribution[label] = parseFloat(c.count) || 0;
        }
      });
    }

    // Convert signupStats to engagementData (just the counts as numbers)
    const engagementData = stats.signupStats && Array.isArray(stats.signupStats)
      ? stats.signupStats.map(d => parseFloat(d.count) || 0)
      : [];
    
    const engagementLabels = stats.signupStats && Array.isArray(stats.signupStats)
      ? stats.signupStats.map(d => d.label || d.date)
      : [];

    const recentActivities = stats.exercises?.recentExercises && Array.isArray(stats.exercises.recentExercises)
      ? stats.exercises.recentExercises.map(a => {
          let createdDate = '';
          if (a.createdAt) {
            const createdAtValue = a.createdAt instanceof Date ? a.createdAt : new Date(a.createdAt);
            if (!Number.isNaN(createdAtValue.getTime())) {
              createdDate = createdAtValue.toISOString().split('T')[0];
            }
          }

          return {
            title: a.title ?? a.name ?? 'Exercise',
            subtitle: a.category
              ? `${a.category} • ${createdDate}`
              : createdDate
          };
        })
      : [];

    const avgBmi = parseFloat(stats.health?.averageBmi) || 0;
    const avgHr = parseFloat(stats.health?.averageHeartRate) || 0;

    return {
      totalUsers: parseInt(stats.users?.total) || 0,
      activeUsers: parseInt(stats.activity?.activeUsers) || 0,
      totalExercises: parseInt(stats.exercises?.total) || 0,
      totalWorkouts: parseInt(stats.progress?.totalEntries) || 0,
      totalProducts: parseInt(stats.products?.total) || 0,
      totalAnnouncements: parseInt(stats.announcements?.total) || 0,
      avgBmi: avgBmi,
      avgHr: avgHr,
      averageBmi: avgBmi,
      averageHeartRate: avgHr,
      categoryDistribution: categoryDistribution,
      productCategoryDistribution: productCategoryDistribution,
      productTypeData: productTypeData,
      productTypeLabels: productTypeLabels,
      engagementData: engagementData,
      engagementLabels: engagementLabels,
      signupStats: stats.signupStats,
      recentActivities: recentActivities
    };
  }
}

module.exports = new AdminService();