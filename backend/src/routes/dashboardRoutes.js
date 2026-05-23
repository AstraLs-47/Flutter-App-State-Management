const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');

// Apply authentication to all dashboard routes
router.use(authenticate);

router.get('/stats', async (req, res) => {
  try {
    const { Pool } = require('pg');
    const pool = new Pool({
      connectionString: process.env.DATABASE_URL
    });

    // Get total products
    const productsResult = await pool.query('SELECT COUNT(*) FROM products WHERE is_active = true');
    const totalProducts = parseInt(productsResult.rows[0].count);

    // Get total users
    const usersResult = await pool.query('SELECT COUNT(*) FROM users');
    const totalUsers = parseInt(usersResult.rows[0].count);

    // Get announcements count
    const announcementsResult = await pool.query('SELECT COUNT(*) FROM announcements WHERE is_active = true');
    const announcementsCount = parseInt(announcementsResult.rows[0].count);

    // Get user's progress stats (if any)
    const progressResult = await pool.query(`
      SELECT 
        COUNT(*) as workouts_count,
        COALESCE(SUM(duration_minutes), 0) as total_minutes
      FROM progress_entries 
      WHERE user_id = $1 AND entry_date > NOW() - INTERVAL '30 days'
    `, [req.user.id]);

    const workoutsCount = parseInt(progressResult.rows[0].workouts_count);
    const totalCalories = workoutsCount * 200; // Approximate calories per workout

    // Return stats
    res.json({
      avgBmi: 22.5,
      avgHr: 72,
      totalActivities: workoutsCount,
      totalProducts: totalProducts,
      totalUsers: totalUsers,
      announcementsCount: announcementsCount,
      hasNewAnnouncements: announcementsCount > 0,
      userName: req.user.email.split('@')[0],
      dailyGoalPercentage: Math.min(100, workoutsCount * 20),
      totalCalories: totalCalories,
      workoutsCount: workoutsCount,
      recentActivity: {}
    });
  } catch (error) {
    console.error('Dashboard error:', error);
    res.status(500).json({ error: 'Failed to fetch dashboard stats' });
  }
});

module.exports = router;