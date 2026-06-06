// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Package imports:
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../providers/auth_providers.dart';
// Project imports:
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'user'; // Defaults to 'user'
  bool _isLoading = false;

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final error = await ref
          .read(authProvider.notifier)
          .signUp(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            role: _selectedRole,
          );
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (error == null) {
        if (_selectedRole == 'admin') {
          context.goNamed(RouteConstants.adminName);
        } else {
          context.goNamed(RouteConstants.onboardingName);
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildRoleOption(String role, IconData icon, String label) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : const Color(0xFFF8F9FE),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                            ),
                            onPressed: () => context.canPop()
                                ? context.pop()
                                : context.goNamed(RouteConstants.rootName),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              text: 'PURE',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                fontSize: 16,
                              ),
                              children: [
                                TextSpan(
                                  text: 'PULSE',
                                  style: TextStyle(
                                    color: Color.fromRGBO(2, 143, 225, 1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Create Account',
                            style: textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start your fitness journey today',
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          CustomTextField(
                            controller: _nameController,
                            hintText: 'Full Name',
                            label: 'Full Name',
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              size: 20,
                            ),
                            validator: Validators.validateName,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _emailController,
                            hintText: 'Email address',
                            label: 'Email',
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              size: 20,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.validateEmail,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _passwordController,
                            hintText: 'Password',
                            label: 'Password',
                            isPassword: true,
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              size: 20,
                            ),
                            validator: Validators.validatePassword,
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'ROLE',
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildRoleOption('user', Icons.person, 'User'),
                              const SizedBox(width: 16),
                              _buildRoleOption(
                                'admin',
                                Icons.shield_outlined,
                                'Admin',
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (authState.error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                authState.error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator())
                          else
                            CustomButton(
                              text: 'Sign Up',
                              onPressed: () => _handleSignUp(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Center(
                          child: GestureDetector(
                            onTap: () => context.pop(),
                            child: RichText(
                              text: const TextSpan(
                                text: "Already have an account? ",
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Sign In',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
