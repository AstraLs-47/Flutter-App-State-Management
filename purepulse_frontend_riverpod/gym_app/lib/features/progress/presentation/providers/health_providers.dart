// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// Project imports:
import '../../../../core/providers/core_providers.dart';
import '../../data/health_repository.dart';
import '../../data/models/health_record_model.dart';

class HealthNotifier extends StateNotifier<AsyncValue<List<HealthRecord>>> {
  final HealthRepository _repository;

  HealthNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadHealthRecords();
  }

  Future<void> loadHealthRecords({bool forceRefresh = false}) async {
    try {
      final records = await _repository.getHealthRecords(
        forceRefresh: forceRefresh,
      );
      state = AsyncValue.data(records);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addHealthRecord(HealthRecord record) async {
    final response = await _repository.addHealthRecord(record);
    state.whenData((list) {
      final updatedList = [response, ...list];
      updatedList.sort((a, b) => b.date.compareTo(a.date));
      state = AsyncValue.data(updatedList);
    });
  }
}

// Providers
final healthRecordsProvider =
    StateNotifierProvider<HealthNotifier, AsyncValue<List<HealthRecord>>>((
      ref,
    ) {
      final repository = ref.watch(healthRepositoryProvider);
      return HealthNotifier(repository);
    });

final latestHealthRecordProvider = Provider<HealthRecord?>((ref) {
  final healthAsync = ref.watch(healthRecordsProvider);
  return healthAsync.when(
    data: (records) => records.isNotEmpty ? records.first : null,
    loading: () => null,
    error: (_, _) => null,
  );
});
