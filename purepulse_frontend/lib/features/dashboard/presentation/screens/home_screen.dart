// Flutter imports:
import 'package:flutter/material.dart';
import 'package:gym_app/features/auth/application/auth_notifier.dart';
import 'package:gym_app/features/workout/application/workouts_notifier.dart';
import 'package:gym_app/features/progress/application/health_metrics_notifier.dart';
import 'package:gym_app/features/announcement/application/announcements_notifier.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Project imports:
import '../../../../core/constants/route_constants.dart';
import '../../../../core/widgets/user_bottom_nav.dart';

import '../../../../core/utils/navigation_helper.dart';
import '../widgets/daily_goal_progress.dart';
import '../widgets/health_snapshot_card.dart';
import '../widgets/metric_column.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateNotifierProvider).valueOrNull;
    final userName = user?.name ?? 'User';

    // Watch providers for stats
    final workouts = ref.watch(workoutsNotifierProvider).valueOrNull ?? [];
    final healthRecords = ref.watch(healthMetricsNotifierProvider).valueOrNull ?? [];
    final announcements = ref.watch(announcementsNotifierProvider).valueOrNull ?? [];

    // Calculate metrics
    final latestHR = healthRecords.isNotEmpty
        ? healthRecords.first.heartRate.toInt().toString()
        : '0';

    int totalCalories = 0;
    for (var w in workouts) {
      totalCalories +=
          int.tryParse((w.calories ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ??
          0;
    }

    final totalActivities = workouts.length;

    // Simplistic daily goal percentage (e.g. 1 activity = 100%)
    final dailyGoalPercentage = totalActivities > 0 ? 100 : 0;

    // Assume new announcements if the list is not empty for now.
    final hasNewAnnouncements = announcements.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'THE PULSE',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hey, $userName 💪',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      context.pushNamed(RouteConstants.announcementsName);
                    },
                    child: Stack(
                      children: [
                        const Icon(
                          Icons.notifications_none_outlined,
                          size: 28,
                          color: Colors.black54,
                        ),
                        if (hasNewAnnouncements)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Daily Goal
              Center(child: DailyGoalProgress(percentage: dailyGoalPercentage)),
              const SizedBox(height: 40),

              // Metrics Row (HR, Calories, Activities)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MetricColumn(
                    icon: Icons.favorite,
                    value: latestHR,
                    title: 'HEART RATE',
                    unit: 'BPM',
                  ),
                  MetricColumn(
                    icon: Icons.local_fire_department,
                    value: totalCalories.toString(),
                    title: 'CALORIES',
                    unit: 'KCAL',
                  ),
                  MetricColumn(
                    icon: Icons.directions_run,
                    value: totalActivities.toString(),
                    title: 'ACTIVITIES',
                    unit: 'DONE',
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Health Snapshot
              const HealthSnapshotCard(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const UserBottomNav(
        currentItem: BottomNavItem.dashboard,
      ),
    );
  }
}
