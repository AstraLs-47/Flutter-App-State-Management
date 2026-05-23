const UserService = require('../services/userService');

class UserController {
  /**
   * GET /api/user/profile
   */
  static async getProfile(req, res) {
    try {
      const userId = req.user.id;
      const profile = await UserService.getProfile(userId);
      
      res.json({
        success: true,
        data: profile
      });
    } catch (error) {
      if (error.message === 'PROFILE_NOT_FOUND') {
        return res.status(404).json({
          success: false,
          message: 'Profile not found. Please complete onboarding.'
        });
      }

      console.error('Get profile error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch profile'
      });
    }
  }

  /**
   * PUT /api/user/profile
   */
  static async updateProfile(req, res) {
    try {
      const userId = req.user.id;

      if (Object.keys(req.body).length === 0) {
        return res.status(400).json({
          success: false,
          message: 'No data provided for update'
        });
      }

      const profile = await UserService.updateProfile(userId, req.body);
      
      res.json({
        success: true,
        message: 'Profile updated successfully',
        data: profile
      });
    } catch (error) {
      if (error.message === 'PROFILE_NOT_FOUND') {
        return res.status(404).json({
          success: false,
          message: 'Profile not found. Please complete onboarding first.'
        });
      }

      if (error.message.startsWith('VALIDATION_ERROR:')) {
        return res.status(400).json({
          success: false,
          message: error.message.replace('VALIDATION_ERROR:', '')
        });
      }

      console.error('Update profile error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update profile'
      });
    }
  }

  /**
   * POST /api/user/onboard
   */
  static async onboard(req, res) {
    try {
      const userId = req.user.id;

      if (Object.keys(req.body).length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Onboarding data is required'
        });
      }

      const profile = await UserService.onboard(userId, req.body);
      
      res.status(201).json({
        success: true,
        message: 'Onboarding completed successfully',
        data: profile
      });
    } catch (error) {
      if (error.message.startsWith('VALIDATION_ERROR:')) {
        return res.status(400).json({
          success: false,
          message: error.message.replace('VALIDATION_ERROR:', '')
        });
      }

      console.error('Onboarding error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to complete onboarding'
      });
    }
  }
}

module.exports = UserController;