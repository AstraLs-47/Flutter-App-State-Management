const request = require('supertest');
const app = require('../src/server');
const db = require('../src/config/db');

jest.mock('../src/config/db', () => {
  return {
    query: jest.fn(),
    on: jest.fn(),
  };
});

jest.mock('../src/middleware/auth', () => {
  return {
    auth: (req, res, next) => {
      req.user = { id: 'admin-1', role: 'admin' };
      next();
    },
    authorize: (...roles) => (req, res, next) => next(),
  };
});

describe('Admin Endpoints', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('GET /api/admin/dashboard - success', async () => {
    // Mock the queries inside getDashboard: users count, exercises count, products count, announcements count, etc.
    db.query
      .mockResolvedValueOnce({ rows: [{ total_users: '10', admin_count: '1', regular_user_count: '9', new_users_30_days: '2' }] }) // 1. getUserStats
      .mockResolvedValueOnce({ rows: [{ total_exercises: '5', categories_used: '2' }] }) // 2. getExerciseStats
      .mockResolvedValueOnce({ rows: [] }) // 3. getExerciseCategoryBreakdown
      .mockResolvedValueOnce({ rows: [{ total_entries: '20' }] }) // 4. getProgressStats
      .mockResolvedValueOnce({ rows: [] }) // 5. getProgressLast7Days
      .mockResolvedValueOnce({ rows: [] }) // 6. getRecentProgressActivities
      .mockResolvedValueOnce({ rows: [{ total_weekly_entries: '4' }] }) // 7. getProgressWeeklyTotal
      .mockResolvedValueOnce({ rows: [{ total_announcements: '3' }] }) // 8. getAnnouncementCount
      .mockResolvedValueOnce({ rows: [{ total_products: '8', active_products: '7', total_stock: '100', average_price: '25.0' }] }) // 9. getProductStats
      .mockResolvedValueOnce({ rows: [] }) // 10. getProductCategoryBreakdown
      .mockResolvedValueOnce({ rows: [] }) // 11. getHealthLast7Days
      .mockResolvedValueOnce({ rows: [{ average_bmi: '22.5', average_heart_rate: '72.0' }] }) // 12. getHealthBannerStats
      .mockResolvedValueOnce({ rows: [{ total_actions: '50', active_users: '5', active_days: '10' }] }) // 13. getActivityStats
      .mockResolvedValueOnce({ rows: [] }) // 14. getUserSignupStats
      .mockResolvedValueOnce({ rows: [] }); // 15. getRecentExercises

    const res = await request(app).get('/api/admin/dashboard');

    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('totalUsers');
    expect(res.body).toHaveProperty('totalExercises');
    expect(res.body).toHaveProperty('totalProducts');
  });
});
