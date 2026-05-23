const AuthService = require('../services/authService');

class AuthController {
  static async signup(req, res) {
    try {
      const { email, password, first_name, last_name } = req.body;

      if (!email || !password) {
        return res.status(400).json({
          success: false,
          message: 'Email and password are required'
        });
      }

      const result = await AuthService.signup({ email, password, first_name, last_name });

      res.status(201).json({
        success: true,
        message: 'User created successfully',
        token: result.token,
        user: {
          id: result.user.id,
          email: result.user.email,
          first_name: result.user.firstName,
          last_name: result.user.lastName,
          role: result.user.role
        }
      });
    } catch (error) {
      if (error.message === 'Email already registered') {
        return res.status(409).json({
          success: false,
          message: error.message
        });
      }

      console.error('Signup error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to create account'
      });
    }
  }

  static async signin(req, res) {
    try {
      const { email, password } = req.body;

      if (!email || !password) {
        return res.status(400).json({
          success: false,
          message: 'Email and password are required'
        });
      }

      const result = await AuthService.signin({ email, password });

      res.json({
        success: true,
        message: 'Login successful',
        token: result.token,
        user: {
          id: result.user.id,
          email: result.user.email,
          first_name: result.user.firstName,
          last_name: result.user.lastName,
          role: result.user.role
        }
      });
    } catch (error) {
      if (error.message === 'Invalid email or password') {
        return res.status(401).json({
          success: false,
          message: error.message
        });
      }

      console.error('Signin error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to login'
      });
    }
  }

  static async getMe(req, res) {
    try {
      const user = await AuthService.getMe(req.user.id);

      res.json({
        success: true,
        user: {
          id: user.id,
          email: user.email,
          first_name: user.firstName,
          last_name: user.lastName,
          role: user.role
        }
      });
    } catch (error) {
      console.error('GetMe error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to get user info'
      });
    }
  }

  static async signout(req, res) {
    res.json({
      success: true,
      message: 'Logged out successfully'
    });
  }
}

module.exports = AuthController;