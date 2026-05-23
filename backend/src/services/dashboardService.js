const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

class DashboardService {
  static async getStats(userId) {
    // Get total products
    const productsResult = await pool.query('SELECT COUNT(*) FROM products WHERE is_active = true');
    const totalProducts = parseInt(productsResult.rows[0].count);

    // Get total users
    const usersResult = await pool.query('SELECT COUNT(*) FROM users');
    const totalUsers = parseInt(usersResult.rows[0].count);

    // Get announcements count
    const announcementsResult = await pool.query('SELECT COUNT(*) FROM announcements WHERE is_active = true');
    const announcementsCount = parseInt(announcementsResult.rows[0].count);

    // Get user's activity stats
    const activityResult = await pool.query(`
      SELECT 
        COUNT(*) as workouts_count,
        COALESCE(SUM(duration_minutes), 0) as total_calories
      FROM progress_entries 
      WHERE user_id = $1 AND entry_date > NOW() - INTERVAL '30 days'
    `, [userId]);

    return {
      avgBmi: 22.5,
      avgHr: 72,
      totalActivities: parseInt(activityResult.rows[0].workouts_count) || 0,
      totalProducts: totalProducts,
      totalUsers: totalUsers,
      announcementsCount: announcementsCount,
      hasNewAnnouncements: false,
      userName: 'Admin',
      dailyGoalPercentage: Math.min(100, Math.floor((activityResult.rows[0].workouts_count / 5) * 100)) || 0,
      totalCalories: parseInt(activityResult.rows[0].total_calories) || 0,
      workoutsCount: parseInt(activityResult.rows[0].workouts_count) || 0,
      recentActivity: {},
    };
  }
}

module.exports = DashboardService;