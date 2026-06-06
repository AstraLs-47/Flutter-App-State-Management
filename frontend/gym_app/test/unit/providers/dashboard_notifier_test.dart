import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/providers/core_providers.dart';
import 'package:gym_app/features/dashboard/application/get_dashboard_stats_use_case.dart';

void main() {
  group('getDashboardStatsUseCaseProvider', () {
    test('instantiates GetDashboardStatsUseCase correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final useCase = container.read(getDashboardStatsUseCaseProvider);

      expect(useCase, isA<GetDashboardStatsUseCase>());
    });
  });
}
