// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';

// Project imports:
import '../../../../core/constants/route_constants.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../../../../core/widgets/user_bottom_nav.dart';
import '../../../auth/data/auth_service.dart';
import '../../../progress/data/health_store.dart';
import '../../../workout/data/workout_store.dart';
import '../../data/dashboard_service.dart';
import '../widgets/daily_goal_progress.dart';
import '../widgets/health_snapshot_card.dart';
import '../widgets/metric_column.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  final _workoutStore = WorkoutStore();
  final _dashboardService = DashboardService();
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _workoutStore.addListener(_onWorkoutStoreChanged);
    _loadData();
  }

  @override
  void dispose() {
    _workoutStore.removeListener(_onWorkoutStoreChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onWorkoutStoreChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh dashboard when user returns to the app (e.g. after adding progress)
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  void _loadData() {
    final future = _dashboardService.fetchDashboardStats();
    // Force a setState after the future resolves so WorkoutStore-driven
    // widgets (todayCalories, todayGoalPercentage, todayCount) repaint.
    future.then((_) {
      if (mounted) setState(() {});
    }).catchError((_) {});
    setState(() {
      _statsFuture = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _statsFuture,
          builder: (context, snapshot) {
            final stats = snapshot.data ?? {};
            final hasNewAnnouncements = stats['hasNewAnnouncements'] ?? false;

            return SingleChildScrollView(
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
                            'Hey, ${AuthService.currentUserName} 💪',
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
                  Center(
                    child: DailyGoalProgress(
                      percentage: _workoutStore.todayGoalPercentage,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Metrics Row (HR, Calories, Activities)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MetricColumn(
                        icon: Icons.favorite,
                        value:
                            HealthStore().latestRecord?.heartRate
                                .toInt()
                                .toString() ??
                            '0',
                        title: 'HEART RATE',
                        unit: 'BPM',
                      ),
                      MetricColumn(
                        icon: Icons.local_fire_department,
                        value: _workoutStore.todayCalories.toString(),
                        title: 'CALORIES',
                        unit: 'KCAL',
                      ),
                      MetricColumn(
                        icon: Icons.directions_run,
                        value: _workoutStore.todayCount.toString(),
                        title: 'ACTIVITIES',
                        unit: 'DONE',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Health Snapshot
                  HealthSnapshotCard(),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const UserBottomNav(
        currentItem: BottomNavItem.dashboard,
      ),
    );
  }
}
