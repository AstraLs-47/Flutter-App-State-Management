const UserProfile = require('../models/UserProfile');

class UserService {
  /**
   * Get user profile
   */
  static async getProfile(userId) {
    const profile = await UserProfile.findByUserId(userId);
    
    if (!profile) {
      throw new Error('PROFILE_NOT_FOUND');
    }

    return {
      id: profile.id,
      user_id: profile.user_id,
      email: profile.email,
      first_name: profile.first_name,
      last_name: profile.last_name,
      role: profile.role,
      profile: {
        age: profile.age,
        gender: profile.gender,
        goal: profile.goal,
        activity_level: profile.activity_level,
        date_of_birth: profile.date_of_birth,
        height: profile.height,
        current_weight: profile.current_weight,
        goal_weight: profile.goal_weight
      },
      created_at: profile.created_at,
      updated_at: profile.updated_at
    };
  }

  /**
   * Update user profile
   */
  static async updateProfile(userId, data) {
    // Convert camelCase to the format expected by the model
    const profileData = {
      age: data.age,
      gender: data.gender,
      goal: data.goal,
      activityLevel: data.activity_level || data.activityLevel,
      dateOfBirth: data.date_of_birth || data.dateOfBirth,
      height: data.height,
      currentWeight: data.current_weight || data.currentWeight,
      goalWeight: data.goal_weight || data.goalWeight
    };

    // Remove undefined fields
    Object.keys(profileData).forEach(key => {
      if (profileData[key] === undefined) delete profileData[key];
    });

    this.validateProfileData(profileData);

    const updatedProfile = await UserProfile.update(userId, profileData);
    
    if (!updatedProfile) {
      throw new Error('PROFILE_NOT_FOUND');
    }

    return await this.getProfile(userId);
  }

  /**
   * Complete onboarding - creates or updates profile
   */
  static async onboard(userId, data) {
    const { first_name, last_name, ...profileInput } = data;

    // Convert to model format
    const profileData = {
      age: profileInput.age,
      gender: profileInput.gender,
      goal: profileInput.goal,
      activityLevel: profileInput.activity_level || profileInput.activityLevel,
      dateOfBirth: profileInput.date_of_birth || profileInput.dateOfBirth,
      height: profileInput.height,
      currentWeight: profileInput.current_weight || profileInput.currentWeight,
      goalWeight: profileInput.goal_weight || profileInput.goalWeight
    };

    const userData = { first_name, last_name };

    // Remove undefined fields from profileData
    Object.keys(profileData).forEach(key => {
      if (profileData[key] === undefined) delete profileData[key];
    });

    // Validate if there's at least some data (skip validation if all null)
    const hasProfileData = Object.keys(profileData).length > 0;
    const hasUserData = (userData.first_name && userData.first_name !== '') || 
                        (userData.last_name && userData.last_name !== '');

    if (!hasProfileData && !hasUserData) {
      throw new Error('VALIDATION_ERROR:At least one profile field or name is required');
    }

    if (hasProfileData) {
      this.validateProfileData(profileData);
    }
    if (hasUserData) {
      this.validateUserData(userData);
    }

    // Use upsert to create or update profile
    const result = await UserProfile.upsert({
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

    // Update user names if provided
    if (hasUserData) {
      await UserProfile.updateUserNames(userId, userData);
    }

    return await this.getProfile(userId);
  }

  /**
   * Validate profile fields
   */
  static validateProfileData(data) {
    if (data.age !== undefined && data.age !== null) {
      const age = parseInt(data.age);
      if (isNaN(age) || age < 13 || age > 120) {
        throw new Error('VALIDATION_ERROR:Age must be between 13 and 120');
      }
    }

    if (data.gender !== undefined && data.gender !== null) {
      const valid = ['male', 'female', 'other'];
      if (!valid.includes(data.gender.toLowerCase())) {
        throw new Error(`VALIDATION_ERROR:Gender must be one of: ${valid.join(', ')}`);
      }
    }

    if (data.goal !== undefined && data.goal !== null) {
      const valid = ['lose weight', 'gain weight', 'gain muscle', 'manage stress', 'maintain weight'];
      if (!valid.includes(data.goal.toLowerCase())) {
        throw new Error(`VALIDATION_ERROR:Goal must be one of: ${valid.join(', ')}`);
      }
    }

    if (data.activityLevel !== undefined && data.activityLevel !== null) {
      const valid = ['Active', 'Very Active', 'Lightly Active', 'Not active'];
      const match = valid.find(v => v.toLowerCase() === data.activityLevel.toLowerCase());
      if (!match) {
        throw new Error(`VALIDATION_ERROR:Activity level must be one of: ${valid.join(', ')}`);
      }
    }

    if (data.height !== undefined && data.height !== null) {
      const h = parseFloat(data.height);
      if (isNaN(h) || h < 50 || h > 300) {
        throw new Error('VALIDATION_ERROR:Height must be between 50 and 300 cm');
      }
    }

    if (data.currentWeight !== undefined && data.currentWeight !== null) {
      const w = parseFloat(data.currentWeight);
      if (isNaN(w) || w < 20 || w > 500) {
        throw new Error('VALIDATION_ERROR:Weight must be between 20 and 500 kg');
      }
    }

    if (data.goalWeight !== undefined && data.goalWeight !== null) {
      const w = parseFloat(data.goalWeight);
      if (isNaN(w) || w < 20 || w > 500) {
        throw new Error('VALIDATION_ERROR:Goal weight must be between 20 and 500 kg');
      }
    }

    if (data.dateOfBirth !== undefined && data.dateOfBirth && data.dateOfBirth !== null) {
      const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
      if (!dateRegex.test(data.dateOfBirth)) {
        throw new Error('VALIDATION_ERROR:Date must be in YYYY-MM-DD format');
      }
      const d = new Date(data.dateOfBirth);
      if (isNaN(d.getTime()) || d > new Date()) {
        throw new Error('VALIDATION_ERROR:Invalid date of birth');
      }
    }
  }

  /**
   * Validate user data
   */
  static validateUserData(data) {
    if (data.first_name !== undefined && data.first_name !== null && typeof data.first_name !== 'string') {
      throw new Error('VALIDATION_ERROR:First name must be text');
    }
    if (data.last_name !== undefined && data.last_name !== null && typeof data.last_name !== 'string') {
      throw new Error('VALIDATION_ERROR:Last name must be text');
    }
  }
}

module.exports = UserService;