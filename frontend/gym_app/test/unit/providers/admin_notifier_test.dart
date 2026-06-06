import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/providers/core_providers.dart';
import 'package:gym_app/features/admin/application/get_admin_dashboard_stats_use_case.dart';
import 'package:gym_app/features/admin/presentation/providers/admin_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockGetAdminDashboardStatsUseCase extends Mock implements GetAdminDashboardStatsUseCase {}

void main() {
  late MockGetAdminDashboardStatsUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetAdminDashboardStatsUseCase();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        getAdminDashboardStatsUseCaseProvider.overrideWithValue(mockUseCase),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('adminDashboardStatsProvider', () {
    test('resolves to value returned by use case on success', () async {
      final expectedStats = {'totalUsers': 100};
      when(() => mockUseCase.call()).thenAnswer((_) async => expectedStats);

      final container = makeContainer();
      final result = await container.read(adminDashboardStatsProvider.future);

      expect(result, expectedStats);
      verify(() => mockUseCase.call()).called(1);
    });

    test('resolves to error state when use case throws exception', () async {
      when(() => mockUseCase.call()).thenThrow(Exception('Admin error'));

      final container = makeContainer();
      // Keep the autoDispose provider alive by subscribing to it.
      final errorCompleter = Completer<AsyncValue<Map<String, dynamic>>>();

      container.listen<AsyncValue<Map<String, dynamic>>>(
        adminDashboardStatsProvider,
        (previous, next) {
          if (next.hasError && !errorCompleter.isCompleted) {
            errorCompleter.complete(next);
          }
        },
        fireImmediately: true,
      );

      // Trigger the provider by reading it (the listener above keeps it alive).
      final settled = await errorCompleter.future;
      expect(settled.hasError, isTrue);
    });
  });
}
