// Flutter imports:
import 'package:flutter/material.dart';
import 'package:gym_app/features/auth/application/auth_notifier.dart';
import 'package:gym_app/features/progress/application/health_metrics_notifier.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// Project imports:
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../progress/domain/health_record_model.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  String? _selectedGoal;
  String? _selectedActivityLevel;

  void _next() {
    if (_currentPage < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _completeOnboarding({
    required String sex,
    required String birthDate,
    required String height,
    required String weight,
    required String goalWeight,
  }) async {
    final double? h = double.tryParse(height);
    final double? w = double.tryParse(weight);

    if (h != null && w != null && h > 0) {
      final bmi = w / (h * h);
      final record = HealthRecord(
        id: const Uuid().v4(),
        systolic: 120,
        diastolic: 80,
        heartRate: 72,
        bloodSugar: 90,
        weight: w,
        height: h,
        bmi: bmi,
        date: DateTime.now(),
      );

      // Save initial progress record to SQLite
      await ref.read(healthMetricsNotifierProvider.notifier).addRecord(record);
    }

    if (mounted) {
      context.goNamed(RouteConstants.dashboardName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: PageView(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (i) => setState(() => _currentPage = i),
          children: [
            _GoalSelectionPage(
              onNext: (goal) {
                _selectedGoal = goal;
                _next();
              },
            ),
            _ActivityLevelPage(
              onNext: (level) {
                _selectedActivityLevel = level;
                _next();
              },
              onBack: _back,
            ),
            _UserInfoPage(
              onComplete: (sex, birthDate, height, weight, goalWeight) {
                _completeOnboarding(
                  sex: sex,
                  birthDate: birthDate,
                  height: height,
                  weight: weight,
                  goalWeight: goalWeight,
                );
              },
              onBack: _back,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingHeader extends ConsumerWidget {
  final String question;
  const _OnboardingHeader({required this.question});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateNotifierProvider).valueOrNull;
    final userName = user?.name ?? 'User';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'THE PULSE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'Hey, $userName ',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const Text('💪', style: TextStyle(fontSize: 18)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          question,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _GoalSelectionPage extends StatefulWidget {
  final ValueChanged<String> onNext;
  const _GoalSelectionPage({required this.onNext});

  @override
  State<_GoalSelectionPage> createState() => _GoalSelectionPageState();
}

class _GoalSelectionPageState extends State<_GoalSelectionPage> {
  String? selectedGoal;
  final List<String> goals = [
    'Lose Weight',
    'Gain Weight',
    'Gain Muscle',
    'Manage Stress',
    'Maintain Weight',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _OnboardingHeader(question: 'What is your goal?'),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          ...goals.map(
                            (goal) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _OptionButton(
                                label: goal,
                                isSelected: selectedGoal == goal,
                                onTap: () {
                                  setState(() => selectedGoal = goal);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _NavButton(
                      label: 'Next',
                      onTap: () {
                        if (selectedGoal == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select your goal to continue',
                              ),
                            ),
                          );
                        } else {
                          widget.onNext(selectedGoal!);
                        }
                      },
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityLevelPage extends StatefulWidget {
  final ValueChanged<String> onNext;
  final VoidCallback onBack;
  const _ActivityLevelPage({required this.onNext, required this.onBack});

  @override
  State<_ActivityLevelPage> createState() => _ActivityLevelPageState();
}

class _ActivityLevelPageState extends State<_ActivityLevelPage> {
  String? selectedLevel;
  final List<String> levels = [
    'Active',
    'Very Active',
    'Lightly Active',
    'Not Active',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _OnboardingHeader(
            question: 'What is your baseline activity level?',
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          ...levels.map(
                            (level) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _OptionButton(
                                label: level,
                                isSelected: selectedLevel == level,
                                onTap: () {
                                  setState(() => selectedLevel = level);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _NavButton(
                        label: 'Back',
                        onTap: widget.onBack,
                        isPrimary: false,
                      ),
                      _NavButton(
                        label: 'Next',
                        onTap: () {
                          if (selectedLevel == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please select your activity level',
                                ),
                              ),
                            );
                          } else {
                            widget.onNext(selectedLevel!);
                          }
                        },
                        isPrimary: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserInfoPage extends StatefulWidget {
  final Function(
    String sex,
    String birthDate,
    String height,
    String weight,
    String goalWeight,
  )
  onComplete;
  final VoidCallback onBack;
  const _UserInfoPage({required this.onComplete, required this.onBack});

  @override
  State<_UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<_UserInfoPage> {
  String selectedSex = 'Female';
  final _birthController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _goalWeightController = TextEditingController();

  @override
  void dispose() {
    _birthController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _goalWeightController.dispose();
    super.dispose();
  }

  void _validateAndProceed() {
    if (_birthController.text.isEmpty ||
        _heightController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _goalWeightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in all information to complete your profile',
          ),
        ),
      );
      return;
    }

    widget.onComplete(
      selectedSex,
      _birthController.text,
      _heightController.text,
      _weightController.text,
      _goalWeightController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _OnboardingHeader(
                    question:
                        'Please select which sex we should use to calculate your calorie needs.',
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      _SexOption(
                        label: 'Female',
                        isSelected: selectedSex == 'Female',
                        onTap: () => setState(() => selectedSex = 'Female'),
                      ),
                      const SizedBox(width: 48),
                      _SexOption(
                        label: 'Male',
                        isSelected: selectedSex == 'Male',
                        onTap: () => setState(() => selectedSex = 'Male'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _InputField(
                    label: 'When were you born?',
                    hint: 'mm/dd/yyyy',
                    controller: _birthController,
                  ),
                  const SizedBox(height: 24),
                  _InputField(
                    label: 'How tall are you?',
                    hint: 'Height (meter)',
                    controller: _heightController,
                  ),
                  const SizedBox(height: 24),
                  _InputField(
                    label: 'How much do you weight?',
                    hint: 'Current weight(kg)',
                    controller: _weightController,
                  ),
                  const SizedBox(height: 24),
                  _InputField(
                    label: 'What\'s your goal weight?',
                    hint: 'Goal weight(kg)',
                    controller: _goalWeightController,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavButton(label: 'Back', onTap: widget.onBack, isPrimary: false),
              _NavButton(
                label: 'Next',
                onTap: _validateAndProceed,
                isPrimary: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primary : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _SexOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SexOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : const Color(0xFFEEEEEE),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;

  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              isCollapsed: true,
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _NavButton({
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? AppColors.primary
              : const Color(0xFFF0F0F0),
          foregroundColor: isPrimary ? Colors.white : AppColors.textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
