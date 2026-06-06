import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/models/activity_model.dart';
import 'package:gym_app/core/providers/core_providers.dart';
import 'package:gym_app/features/exercises/application/create_exercise_use_case.dart';
import 'package:gym_app/features/exercises/application/delete_exercise_use_case.dart';
import 'package:gym_app/features/exercises/application/get_exercises_use_case.dart';
import 'package:gym_app/features/exercises/application/update_exercise_use_case.dart';
import 'package:gym_app/features/exercises/presentation/providers/exercise_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockGetExercisesUseCase extends Mock implements GetExercisesUseCase {}
class MockCreateExerciseUseCase extends Mock implements CreateExerciseUseCase {}
class MockUpdateExerciseUseCase extends Mock implements UpdateExerciseUseCase {}
class MockDeleteExerciseUseCase extends Mock implements DeleteExerciseUseCase {}

void main() {
  late MockGetExercisesUseCase mockGetExercisesUseCase;
  late MockCreateExerciseUseCase mockCreateExerciseUseCase;
  late MockUpdateExerciseUseCase mockUpdateExerciseUseCase;
  late MockDeleteExerciseUseCase mockDeleteExerciseUseCase;

  final testActivity = Activity(
    id: 'e1',
    title: 'Push Up',
    description: 'Chest',
    category: 'Chest',
    image: 'pushup.png',
  );

  setUpAll(() {
    registerFallbackValue(Activity(id: '', title: '', description: '', category: '', image: ''));
  });

  setUp(() {
    mockGetExercisesUseCase = MockGetExercisesUseCase();
    mockCreateExerciseUseCase = MockCreateExerciseUseCase();
    mockUpdateExerciseUseCase = MockUpdateExerciseUseCase();
    mockDeleteExerciseUseCase = MockDeleteExerciseUseCase();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        getExercisesUseCaseProvider.overrideWithValue(mockGetExercisesUseCase),
        createExerciseUseCaseProvider.overrideWithValue(mockCreateExerciseUseCase),
        updateExerciseUseCaseProvider.overrideWithValue(mockUpdateExerciseUseCase),
        deleteExerciseUseCaseProvider.overrideWithValue(mockDeleteExerciseUseCase),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('ExercisesNotifier', () {
    test('initial state is loaded list of activities from use case', () async {
      when(() => mockGetExercisesUseCase.call(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => [testActivity]);

      final container = makeContainer();
      final state = await container.read(exercisesProvider.future);

      expect(state, [testActivity]);
      verify(() => mockGetExercisesUseCase.call(forceRefresh: false)).called(1);
    });

    test('loadExercises with forceRefresh updates the state', () async {
      when(() => mockGetExercisesUseCase.call(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => [testActivity]);

      final container = makeContainer();
      await container.read(exercisesProvider.future);

      final notifier = container.read(exercisesProvider.notifier);
      await notifier.loadExercises(forceRefresh: true);

      final state = container.read(exercisesProvider);
      expect(state.value, [testActivity]);
      verify(() => mockGetExercisesUseCase.call(forceRefresh: true)).called(1);
    });

    test('addExercise calls use case and appends to state list', () async {
      when(() => mockGetExercisesUseCase.call(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => []);
      when(() => mockCreateExerciseUseCase.call(any()))
          .thenAnswer((_) async => testActivity);

      final container = makeContainer();
      await container.read(exercisesProvider.future);

      final notifier = container.read(exercisesProvider.notifier);
      await notifier.addExercise(testActivity);

      final state = container.read(exercisesProvider);
      expect(state.value, [testActivity]);
      verify(() => mockCreateExerciseUseCase.call(testActivity)).called(1);
    });

    test('updateExercise calls use case and updates matching activity in state list', () async {
      when(() => mockGetExercisesUseCase.call(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => [testActivity]);
      
      final updatedActivity = testActivity.copyWith(title: 'Push Up Updated');
      when(() => mockUpdateExerciseUseCase.call(any()))
          .thenAnswer((_) async => updatedActivity);

      final container = makeContainer();
      await container.read(exercisesProvider.future);

      final notifier = container.read(exercisesProvider.notifier);
      await notifier.updateExercise(updatedActivity);

      final state = container.read(exercisesProvider);
      expect(state.value!.first.title, 'Push Up Updated');
      verify(() => mockUpdateExerciseUseCase.call(updatedActivity)).called(1);
    });

    test('deleteExercise calls use case and removes activity from state list', () async {
      when(() => mockGetExercisesUseCase.call(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => [testActivity]);
      when(() => mockDeleteExerciseUseCase.call(any())).thenAnswer((_) async => {});

      final container = makeContainer();
      await container.read(exercisesProvider.future);

      final notifier = container.read(exercisesProvider.notifier);
      await notifier.deleteExercise('e1');

      final state = container.read(exercisesProvider);
      expect(state.value, isEmpty);
      verify(() => mockDeleteExerciseUseCase.call('e1')).called(1);
    });
  });

  group('filteredExercisesProvider', () {
    test('filters exercises based on selected category', () async {
      final activityChest = Activity(id: '1', title: 'A', description: '', category: 'Chest', image: '');
      final activityLegs = Activity(id: '2', title: 'B', description: '', category: 'Legs', image: '');

      when(() => mockGetExercisesUseCase.call(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => [activityChest, activityLegs]);

      final container = makeContainer();
      await container.read(exercisesProvider.future);

      // Check default category 'All'
      var filtered = container.read(filteredExercisesProvider);
      expect(filtered.value, [activityChest, activityLegs]);

      // Set category to 'Chest'
      container.read(selectedCategoryProvider.notifier).setCategory('Chest');
      filtered = container.read(filteredExercisesProvider);
      expect(filtered.value, [activityChest]);
    });
  });
}
