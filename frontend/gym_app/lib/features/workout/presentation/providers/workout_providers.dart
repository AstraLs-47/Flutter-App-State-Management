// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import '../../../../core/providers/core_providers.dart';
import '../../data/models/workout_entry_model.dart';

class WorkoutNotifier extends AsyncNotifier<List<WorkoutEntry>> {
  @override
  Future<List<WorkoutEntry>> build() async {
    final getWorkoutEntriesUseCase = ref.read(getWorkoutEntriesUseCaseProvider);
    return getWorkoutEntriesUseCase.call();
  }

  Future<void> loadWorkoutEntries({bool forceRefresh = false}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final getWorkoutEntriesUseCase = ref.read(getWorkoutEntriesUseCaseProvider);
      return getWorkoutEntriesUseCase.call(forceRefresh: forceRefresh);
    });
  }

  Future<void> addEntry(WorkoutEntry entry) async {
    final createWorkoutEntryUseCase = ref.read(createWorkoutEntryUseCaseProvider);
    final response = await createWorkoutEntryUseCase.call(entry);
    final updatedList = <WorkoutEntry>[response, ...state.value ?? <WorkoutEntry>[]];
    updatedList.sort((a, b) => b.date.compareTo(a.date));
    state = AsyncValue.data(updatedList);
  }

  Future<void> updateEntry(WorkoutEntry entry) async {
    final updateWorkoutEntryUseCase = ref.read(updateWorkoutEntryUseCaseProvider);
    final response = await updateWorkoutEntryUseCase.call(entry);
    state = AsyncValue.data(
      (state.value ?? []).map((e) => e.id == response.id ? response : e).toList(),
    );
  }

  Future<void> removeEntry(String id) async {
    final deleteWorkoutEntryUseCase = ref.read(deleteWorkoutEntryUseCaseProvider);
    await deleteWorkoutEntryUseCase.call(id);
    state = AsyncValue.data(
      (state.value ?? []).where((e) => e.id != id).toList(),
    );
  }
}

// Providers
final workoutEntriesProvider = AsyncNotifierProvider<WorkoutNotifier, List<WorkoutEntry>>(() {
  return WorkoutNotifier();
});

final workoutCountProvider = Provider<int>((ref) {
  final entriesAsync = ref.watch(workoutEntriesProvider);
  return entriesAsync.when(
    data: (list) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      return list.where((entry) {
        final dateStr = entry.createdAt ?? entry.date;
        final parsed = DateTime.tryParse(dateStr);
        if (parsed == null) return false;
        final diffMs = nowMs - parsed.millisecondsSinceEpoch;
        return diffMs.abs() < 24 * 60 * 60 * 1000;
      }).length;
    },
    loading: () => 0,
    error: (_, _) => 0,
  );
});

final goalPercentageProvider = Provider<int>((ref) {
  final count = ref.watch(workoutCountProvider);
  if (count <= 0) return 0;
  if (count >= 4) return 100;
  return count * 25;
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
