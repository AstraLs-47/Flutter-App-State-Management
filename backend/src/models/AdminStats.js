const pool = require('../config/db');

class AdminStats {
  static async getUserStats() {
    const result = await pool.query(`
      SELECT 
        COUNT(*) as total_users,
        COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin_count,
        COUNT(CASE WHEN role = 'user' THEN 1 END) as regular_user_count,
        COUNT(CASE WHEN created_at > NOW() - INTERVAL '30 days' THEN 1 END) as new_users_30_days
      FROM users
    `);
    return result.rows[0];
  }

  static async getExerciseStats() {
    const result = await pool.query(`
      SELECT 
        COUNT(*) as total_exercises,
        COUNT(DISTINCT category_id) as categories_used
      FROM exercises
    `);
    return result.rows[0];
  }

  static async getProgressStats() {
    const result = await pool.query(`
      SELECT 
        COUNT(*) as total_entries,
        COUNT(DISTINCT user_id) as active_users,
        SUM(duration_minutes) as total_minutes,
        SUM(sets * reps) as total_volume
      FROM progress_entries
      WHERE entry_date > NOW() - INTERVAL '30 days'
    `);
    return result.rows[0];
  }

  static async getHealthStats() {
    const result = await pool.query(`
      SELECT 
        COUNT(*) as total_entries,
        COUNT(DISTINCT user_id) as users_tracking
      FROM health_metrics
    `);
    return result.rows[0];
  }

  static async getProductStats() {
    const result = await pool.query(`
      SELECT 
        COUNT(*) as total_products,
        AVG(price) as average_price,
        MIN(price) as min_price,
        MAX(price) as max_price
      FROM products
    `);
    return result.rows[0];
  }

  static async getActivityLogs(limit = 100, offset = 0) {
    const result = await pool.query(
      `SELECT al.*, u.email as user_email, u.first_name, u.last_name
       FROM activity_logs al
       LEFT JOIN users u ON al.user_id = u.id
       ORDER BY al.created_at DESC LIMIT $1 OFFSET $2`,
      [limit, offset]
    );
    return result.rows;
  }

  static async getActivityStats() {
    const result = await pool.query(`
      SELECT 
        COUNT(*) as total_actions,
        COUNT(DISTINCT user_id) as active_users,
        COUNT(DISTINCT DATE(created_at)) as active_days
      FROM activity_logs
      WHERE created_at > NOW() - INTERVAL '30 days'
    `);
    return result.rows[0];
  }

  static async getDashboardSummary() {
    const [userStats, exerciseStats, progressStats, healthStats, productStats, activityStats] = await Promise.all([
      AdminStats.getUserStats(),
      AdminStats.getExerciseStats(),
      AdminStats.getProgressStats(),
      AdminStats.getHealthStats(),
      AdminStats.getProductStats(),
      AdminStats.getActivityStats()
    ]);

    return {
      users: {
        total: parseInt(userStats.total_users) || 0,
        admins: parseInt(userStats.admin_count) || 0,
        regular: parseInt(userStats.regular_user_count) || 0,
        newLast30Days: parseInt(userStats.new_users_30_days) || 0
      },
      exercises: {
        total: parseInt(exerciseStats.total_exercises) || 0,
        categoriesUsed: parseInt(exerciseStats.categories_used) || 0
      },
      progress: {
        entriesLast30Days: parseInt(progressStats.total_entries) || 0,
        activeUsers: parseInt(progressStats.active_users) || 0,
        totalMinutes: parseInt(progressStats.total_minutes) || 0,
        totalVolume: parseInt(progressStats.total_volume) || 0
      },
      health: {
        totalEntries: parseInt(healthStats.total_entries) || 0,
        usersTracking: parseInt(healthStats.users_tracking) || 0
      },
      products: {
        total: parseInt(productStats.total_products) || 0,
        averagePrice: parseFloat(productStats.average_price) || 0,
        minPrice: parseFloat(productStats.min_price) || 0,
        maxPrice: parseFloat(productStats.max_price) || 0
      },
      activity: {
        actionsLast30Days: parseInt(activityStats.total_actions) || 0,
        activeUsers: parseInt(activityStats.active_users) || 0,
        activeDays: parseInt(activityStats.active_days) || 0
      }
    };
  }

  static async logActivity(userId, action, entityType, entityId, metadata = {}, ipAddress = null, userAgent = null) {
    const result = await pool.query(
      `INSERT INTO activity_logs (user_id, action, entity_type, entity_id, metadata, ip_address, user_agent)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
      [userId, action, entityType, entityId, JSON.stringify(metadata), ipAddress, userAgent]
    );
    return result.rows[0];
  }
}

module.exports = AdminStats;