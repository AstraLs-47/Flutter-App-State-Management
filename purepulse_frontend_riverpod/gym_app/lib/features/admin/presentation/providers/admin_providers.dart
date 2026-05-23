// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/providers/core_providers.dart';

final adminDashboardStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.adminDashboard);
  
  // Format data types for safety (e.g. converting Map<String, dynamic> categories to Map<String, double>)
  final stats = Map<String, dynamic>.from(response as Map);
  
  final catDist = stats['categoryDistribution'];
  if (catDist is Map) {
    stats['categoryDistribution'] = catDist.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
  } else {
    stats['categoryDistribution'] = <String, double>{};
  }

  final prodType = stats['productTypeData'];
  if (prodType is List) {
    stats['productTypeData'] = prodType.map((v) => (v as num).toDouble()).toList();
  } else {
    stats['productTypeData'] = <double>[0, 0, 0, 0];
  }

  final engagement = stats['engagementData'];
  if (engagement is List) {
    stats['engagementData'] = engagement.map((v) => (v as num).toDouble()).toList();
  } else {
    stats['engagementData'] = <double>[0, 0, 0, 0, 0, 0, 0];
  }

  return stats;
});
