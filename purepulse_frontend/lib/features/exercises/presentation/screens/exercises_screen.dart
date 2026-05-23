// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Project imports:
import '../../../../core/constants/route_constants.dart';
import '../../../../core/models/activity_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../../../../core/widgets/user_bottom_nav.dart';
import '../../application/exercises_notifier.dart';
import '../../../announcement/application/announcements_notifier.dart';

class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({super.key});

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  String _selectedCategory = 'All';

  List<Map<String, dynamic>> _buildCategories(List<Activity> activities) {
    final cats = <Map<String, dynamic>>[
      {'name': 'All', 'icon': null},
    ];
    final uniqueCats = activities.map((a) => a.category).toSet();
    for (final cat in uniqueCats) {
      cats.add({'name': cat, 'icon': null});
    }
    return cats;
  }

  List<Activity> _filterActivities(List<Activity> activities) {
    if (_selectedCategory == 'All') return activities;
    return activities.where((a) {
      return a.category.toUpperCase().contains(_selectedCategory.toUpperCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(activitiesNotifierProvider);
    final announcements = ref.watch(announcementsNotifierProvider).valueOrNull ?? [];
    final hasNewAnnouncements = announcements.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'WORKOUT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Exercises',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_none_outlined,
                          size: 32,
                          color: Colors.black54,
                        ),
                        onPressed: () {
                          context.pushNamed(RouteConstants.announcementsName);
                        },
                      ),
                      if (hasNewAnnouncements)
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Follow expert-designed workout sets',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ),
            const SizedBox(height: 24),

            // Workout List with Riverpod
            Expanded(
              child: activitiesAsync.when(
                data: (activities) {
                  if (activities.isEmpty) {
                    return const Center(
                      child: Text(
                        'No exercises found',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  final categories = _buildCategories(activities);
                  final filteredActivities = _filterActivities(activities);

                  return Column(
                    children: [
                      // Categories
                      SizedBox(
                        height: 44,
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              final isSelected = _selectedCategory == cat['name'];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedCategory = cat['name']),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF0E6CF2) : Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      cat['name'],
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                          child: filteredActivities.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No exercises found in this category',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                )
                              : GridView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.60,
                                  ),
                                  itemCount: filteredActivities.length,
                                  itemBuilder: (context, index) {
                                    return _buildActivityCard(filteredActivities[index]);
                                  },
                                ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0E6CF2)),
                ),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: UserBottomNav(currentItem: BottomNavItem.exercises),
    );
  }

  Widget _buildActivityCard(Activity workout) {
    return GestureDetector(
      onTap: () => context.pushNamed(
        RouteConstants.exerciseDetailName,
        extra: workout.toJson().map((k, v) => MapEntry(k, v.toString())),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF1F5F9),
                  child: SafeImage(
                    imageUrl: workout.image.isNotEmpty
                        ? workout.image
                        : 'assets/running_image.jpg',
                    fit: BoxFit.cover,
                    alignment: (workout.title.toLowerCase().contains('cardio') ||
                        workout.title.toLowerCase().contains('running'))
                        ? const Alignment(0, -0.2)
                        : Alignment.topCenter,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        workout.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          height: 1.4,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Text(
                            'View Details',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0E6CF2),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 14, color: Color(0xFF0E6CF2)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
