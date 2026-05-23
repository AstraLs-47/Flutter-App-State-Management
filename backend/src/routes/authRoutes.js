const express = require('express');
const router = express.Router();
const AuthController = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');

router.post('/signup', AuthController.signup);
router.post('/signin', AuthController.signin);
router.post('/login', AuthController.signin);  // ← Add this line
router.post('/signout', authenticate, AuthController.signout);
router.get('/me', authenticate, AuthController.getMe);

module.exports = router;