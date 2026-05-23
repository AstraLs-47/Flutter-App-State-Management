import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/admin/data/admin_service.dart';
import '../../features/exercises/application/exercises_notifier.dart';
import '../../features/products/application/products_notifier.dart';
import '../../features/announcement/application/announcements_notifier.dart';
import '../../features/progress/application/health_metrics_notifier.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

/// Admin Dashboard stats provider.
/// Watches all feature providers so the dashboard reloads whenever
/// activities, products, announcements, or health records change.
final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.watch(activitiesNotifierProvider);
  ref.watch(productsNotifierProvider);
  ref.watch(announcementsNotifierProvider);
  ref.watch(healthMetricsNotifierProvider);

  final adminService = ref.watch(adminServiceProvider);
  return await adminService.fetchDashboardStats();
});
