const pool = require('../config/db');

class UserProfile {
  /**
   * Find profile by user ID with user info
   */
  static async findByUserId(userId) {
    const result = await pool.query(
      `SELECT 
        up.*,
        u.email,
        u.first_name,
        u.last_name,
        u.role
      FROM user_profiles up
      JOIN users u ON up.user_id = u.id
      WHERE up.user_id = $1`,
      [userId]
    );
    return result.rows[0] || null;
  }

  /**
   * Create or update user profile (upsert)
   */
  static async upsert({ userId, age, gender, goal, activityLevel, dateOfBirth, height, currentWeight, goalWeight }) {
    const result = await pool.query(
      `INSERT INTO user_profiles (user_id, age, gender, goal, activity_level, date_of_birth, height, current_weight, goal_weight)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       ON CONFLICT (user_id) DO UPDATE SET
         age = COALESCE(EXCLUDED.age, user_profiles.age),
         gender = COALESCE(EXCLUDED.gender, user_profiles.gender),
         goal = COALESCE(EXCLUDED.goal, user_profiles.goal),
         activity_level = COALESCE(EXCLUDED.activity_level, user_profiles.activity_level),
         date_of_birth = COALESCE(EXCLUDED.date_of_birth, user_profiles.date_of_birth),
         height = COALESCE(EXCLUDED.height, user_profiles.height),
         current_weight = COALESCE(EXCLUDED.current_weight, user_profiles.current_weight),
         goal_weight = COALESCE(EXCLUDED.goal_weight, user_profiles.goal_weight),
         updated_at = CURRENT_TIMESTAMP
       RETURNING *`,
      [userId, age, gender, goal, activityLevel, dateOfBirth, height, currentWeight, goalWeight]
    );
    return result.rows[0];
  }

  /**
   * Update specific profile fields
   */
  static async update(userId, updates) {
    const fields = [];
    const values = [];
    let paramCount = 1;

    // Map camelCase to snake_case
    const fieldMap = {
      age: 'age',
      gender: 'gender',
      goal: 'goal',
      activityLevel: 'activity_level',
      dateOfBirth: 'date_of_birth',
      height: 'height',
      currentWeight: 'current_weight',
      goalWeight: 'goal_weight'
    };

    for (const [key, dbField] of Object.entries(fieldMap)) {
      if (updates[key] !== undefined) {
        fields.push(`${dbField} = $${paramCount}`);
        values.push(updates[key]);
        paramCount++;
      }
    }

    if (fields.length === 0) return null;

    fields.push(`updated_at = CURRENT_TIMESTAMP`);
    values.push(userId);

    const result = await pool.query(
      `UPDATE user_profiles 
       SET ${fields.join(', ')}
       WHERE user_id = $${paramCount}
       RETURNING *`,
      values
    );
    return result.rows[0];
  }

  /**
   * Update user names (first_name, last_name)
   */
  static async updateUserNames(userId, userData) {
    const fields = [];
    const values = [];
    let paramCount = 1;

    if (userData.first_name !== undefined && userData.first_name !== null) {
      fields.push(`first_name = $${paramCount}`);
      values.push(userData.first_name);
      paramCount++;
    }
    if (userData.last_name !== undefined && userData.last_name !== null) {
      fields.push(`last_name = $${paramCount}`);
      values.push(userData.last_name);
      paramCount++;
    }

    if (fields.length === 0) return null;

    fields.push(`updated_at = CURRENT_TIMESTAMP`);
    values.push(userId);

    const result = await pool.query(
      `UPDATE users 
       SET ${fields.join(', ')}
       WHERE id = $${paramCount}
       RETURNING id`,
      values
    );
    return result.rows[0];
  }

  /**
   * Complete onboarding with transaction (kept for backward compatibility)
   */
  static async onboard(userId, profileData, userData) {
    // First update user names if provided
    if (userData.first_name || userData.last_name) {
      await this.updateUserNames(userId, userData);
    }
    
    // Then upsert profile
    return await this.upsert({
      userId,
      age: profileData.age,
      gender: profileData.gender,
      goal: profileData.goal,
      activityLevel: profileData.activityLevel,
      dateOfBirth: profileData.dateOfBirth,
      height: profileData.height,
      currentWeight: profileData.currentWeight,
      goalWeight: profileData.goalWeight
    });
  }
}

module.exports = UserProfile;