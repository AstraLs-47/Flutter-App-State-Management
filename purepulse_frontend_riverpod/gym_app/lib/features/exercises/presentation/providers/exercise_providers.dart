// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// Project imports:
import '../../../../core/models/activity_model.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/exercise_repository.dart';

class ExercisesNotifier extends StateNotifier<AsyncValue<List<Activity>>> {
  final ExerciseRepository _repository;

  ExercisesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadExercises();
  }

  Future<void> loadExercises({bool forceRefresh = false}) async {
    try {
      final exercises = await _repository.getExercises(forceRefresh: forceRefresh);
      state = AsyncValue.data(exercises);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addExercise(Activity exercise) async {
    final response = await _repository.createExercise(exercise);
    state.whenData((list) {
      state = AsyncValue.data([...list, response]);
    });
  }

  Future<void> updateExercise(Activity exercise) async {
    final response = await _repository.updateExercise(exercise);
    state.whenData((list) {
      state = AsyncValue.data(list.map((e) => e.id == response.id ? response : e).toList());
    });
  }

  Future<void> deleteExercise(String id) async {
    await _repository.deleteExercise(id);
    state.whenData((list) {
      state = AsyncValue.data(list.where((e) => e.id != id).toList());
    });
  }
}

// Providers
final exercisesProvider = StateNotifierProvider<ExercisesNotifier, AsyncValue<List<Activity>>>((ref) {
  final repository = ref.watch(exerciseRepositoryProvider);
  return ExercisesNotifier(repository);
});

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

final filteredExercisesProvider = Provider<AsyncValue<List<Activity>>>((ref) {
  final exercisesAsync = ref.watch(exercisesProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);

  return exercisesAsync.when(
    data: (exercises) {
      if (selectedCategory == 'All') {
        return AsyncValue.data(exercises);
      }
      final filtered = exercises.where((e) {
        return e.category.toLowerCase().contains(selectedCategory.toLowerCase());
      }).toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});
