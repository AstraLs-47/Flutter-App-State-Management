// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// Project imports:
import '../../../../core/providers/core_providers.dart';
import '../../data/models/workout_entry_model.dart';
import '../../data/progress_repository.dart';

class WorkoutNotifier extends StateNotifier<AsyncValue<List<WorkoutEntry>>> {
  final ProgressRepository _repository;

  WorkoutNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadWorkoutEntries();
  }

  Future<void> loadWorkoutEntries({bool forceRefresh = false}) async {
    try {
      final entries = await _repository.getWorkoutEntries(
        forceRefresh: forceRefresh,
      );
      state = AsyncValue.data(entries);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addEntry(WorkoutEntry entry) async {
    final response = await _repository.createWorkoutEntry(entry);
    state.whenData((list) {
      final updatedList = [response, ...list];
      updatedList.sort((a, b) => b.date.compareTo(a.date));
      state = AsyncValue.data(updatedList);
    });
  }

  Future<void> updateEntry(WorkoutEntry entry) async {
    final response = await _repository.updateWorkoutEntry(entry);
    state.whenData((list) {
      state = AsyncValue.data(
        list.map((e) => e.id == response.id ? response : e).toList(),
      );
    });
  }

  Future<void> removeEntry(String id) async {
    await _repository.deleteWorkoutEntry(id);
    state.whenData((list) {
      state = AsyncValue.data(list.where((e) => e.id != id).toList());
    });
  }
}

// Providers
final workoutEntriesProvider =
    StateNotifierProvider<WorkoutNotifier, AsyncValue<List<WorkoutEntry>>>((
      ref,
    ) {
      final repository = ref.watch(progressRepositoryProvider);
      return WorkoutNotifier(repository);
    });

final workoutCountProvider = Provider<int>((ref) {
  final entriesAsync = ref.watch(workoutEntriesProvider);
  return entriesAsync.when(
    data: (list) => list.length,
    loading: () => 0,
    error: (_, _) => 0,
  );
});

final goalPercentageProvider = Provider<int>((ref) {
  final entriesAsync = ref.watch(workoutEntriesProvider);
  return entriesAsync.when(
    data: (list) {
      if (list.isEmpty) return 0;
      if (list.length == 1) return 25;
      if (list.length == 2) return 50;
      if (list.length == 3) return 75;
      return 100;
    },
    loading: () => 0,
    error: (_, _) => 0,
  );
});

final totalCaloriesProvider = Provider<int>((ref) {
  final entriesAsync = ref.watch(workoutEntriesProvider);
  return entriesAsync.when(
    data: (list) {
      int sum = 0;
      for (var entry in list) {
        if (entry.calories != null && entry.calories!.isNotEmpty) {
          sum += int.tryParse(entry.calories!) ?? 0;
        }
      }
      return sum;
    },
    loading: () => 0,
    error: (_, _) => 0,
  );
});
