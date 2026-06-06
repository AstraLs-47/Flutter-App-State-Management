import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/providers/core_providers.dart';
import 'package:gym_app/features/workout/application/create_workout_entry_use_case.dart';
import 'package:gym_app/features/workout/application/delete_workout_entry_use_case.dart';
import 'package:gym_app/features/workout/application/get_workout_entries_use_case.dart';
import 'package:gym_app/features/workout/application/update_workout_entry_use_case.dart';
import 'package:gym_app/features/workout/data/models/workout_entry_model.dart';
import 'package:gym_app/features/workout/presentation/providers/workout_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockGetWorkoutEntriesUseCase extends Mock implements GetWorkoutEntriesUseCase {}
class MockCreateWorkoutEntryUseCase extends Mock implements CreateWorkoutEntryUseCase {}
class MockUpdateWorkoutEntryUseCase extends Mock implements UpdateWorkoutEntryUseCase {}
class MockDeleteWorkoutEntryUseCase extends Mock implements DeleteWorkoutEntryUseCase {}

void main() {
  late MockGetWorkoutEntriesUseCase mockGetWorkoutEntriesUseCase;
  late MockCreateWorkoutEntryUseCase mockCreateWorkoutEntryUseCase;
  late MockUpdateWorkoutEntryUseCase mockUpdateWorkoutEntryUseCase;
  late MockDeleteWorkoutEntryUseCase mockDeleteWorkoutEntryUseCase;

  final testEntry = WorkoutEntry(
    id: 'w1',
    title: 'Bench Press',
    date: '2026-05-31',
    duration: '45 MIN',
    exercise: 'Bench Press',
    intensity: 'Intense',
    weight: '80.0',
    sets: '4',
    reps: '10',
    calories: '300',
    achievement: 'PR',
    notes: 'Good',
    createdAt: DateTime.now().toIso8601String(),
  );

  setUpAll(() {
    registerFallbackValue(WorkoutEntry(
      id: '',
      title: '',
      date: '',
      duration: '',
      exercise: '',
      intensity: '',
      weight: '',
      sets: '',
      reps: '',
    ));
  });

  setUp(() {
    mockGetWorkoutEntriesUseCase = MockGetWorkoutEntriesUseCase();
    mockCreateWorkoutEntryUseCase = MockCreateWorkoutEntryUseCase();
    mockUpdateWorkoutEntryUseCase = MockUpdateWorkoutEntryUseCase();
    mockDeleteWorkoutEntryUseCase = MockDeleteWorkoutEntryUseCase();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        getWorkoutEntriesUseCaseProvider.overrideWithValue(mockGetWorkoutEntriesUseCase),
        createWorkoutEntryUseCaseProvider.overrideWithValue(mockCreateWorkoutEntryUseCase),
        updateWorkoutEntryUseCaseProvider.overrideWithValue(mockUpdateWorkoutEntryUseCase),
        deleteWorkoutEntryUseCaseProvider.overrideWithValue(mockDeleteWorkoutEntryUseCase),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('WorkoutNotifier', () {
    test('initial state loads workout entries', () async {
      when(() => mockGetWorkoutEntriesUseCase.call(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => [testEntry]);

      final container = makeContainer();
      final state = await container.read(workoutEntriesProvider.future);

      expect(state, [testEntry]);
      verify(() => mockGetWorkoutEntriesUseCase.call(forceRefresh: false)).called(1);
    });

    test('addEntry calls use case and updates state', () async {
      when(() => mockGetWorkoutEntriesUseCase.call(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => []);
      when(() => mockCreateWorkoutEntryUseCase.call(any()))
          .thenAnswer((_) async => testEntry);

      final container = makeContainer();
      await container.read(workoutEntriesProvider.future);

      final notifier = container.read(workoutEntriesProvider.notifier);
      await notifier.addEntry(testEntry);

      final state = container.read(workoutEntriesProvider);
      expect(state.value, [testEntry]);
    });

    test('updateEntry calls use case and updates state', () async {
      when(() => mockGetWorkoutEntriesUseCase.call(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => [testEntry]);
      final updatedEntry = WorkoutEntry(
        id: testEntry.id,
        title: testEntry.title,
        date: testEntry.date,
        duration: testEntry.duration,
        exercise: 'Bench Press Updated',
        intensity: testEntry.intensity,
        weight: testEntry.weight,
        sets: testEntry.sets,
        reps: testEntry.reps,
        calories: testEntry.calories,
        achievement: testEntry.achievement,
        notes: testEntry.notes,
        createdAt: testEntry.createdAt,
      );
      when(() => mockUpdateWorkoutEntryUseCase.call(any()))
          .thenAnswer((_) async => updatedEntry);

      final container = makeContainer();
      await container.read(workoutEntriesProvider.future);

      final notifier = container.read(workoutEntriesProvider.notifier);
      await notifier.updateEntry(updatedEntry);

      final state = container.read(workoutEntriesProvider);
      expect(state.value!.first.exercise, 'Bench Press Updated');
    });

    test('removeEntry calls use case and removes from state', () async {
      when(() => mockGetWorkoutEntriesUseCase.call(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => [testEntry]);
      when(() => mockDeleteWorkoutEntryUseCase.call(any())).thenAnswer((_) async => {});

      final container = makeContainer();
      await container.read(workoutEntriesProvider.future);

      final notifier = container.read(workoutEntriesProvider.notifier);
      await notifier.removeEntry('w1');

      final state = container.read(workoutEntriesProvider);
      expect(state.value, isEmpty);
    });
  });

  group('Computation Providers', () {
    test('workoutCountProvider returns list length', () async {
      when(() => mockGetWorkoutEntriesUseCase.call(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => [testEntry, testEntry]);

      final container = makeContainer();
      await container.read(workoutEntriesProvider.future);

      expect(container.read(workoutCountProvider), 2);
    });

    test('goalPercentageProvider returns correct steps', () async {
      when(() => mockGetWorkoutEntriesUseCase.call(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => [testEntry]);

      final container = makeContainer();
      await container.read(workoutEntriesProvider.future);

      expect(container.read(goalPercentageProvider), 25);
    });

    test('totalCaloriesProvider sums calories correctly', () async {
      when(() => mockGetWorkoutEntriesUseCase.call(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => [
                testEntry,
                WorkoutEntry(
                  id: testEntry.id,
                  title: testEntry.title,
                  date: testEntry.date,
                  duration: testEntry.duration,
                  exercise: testEntry.exercise,
                  intensity: testEntry.intensity,
                  weight: testEntry.weight,
                  sets: testEntry.sets,
                  reps: testEntry.reps,
                  calories: '150',
                  achievement: testEntry.achievement,
                  notes: testEntry.notes,
                  createdAt: testEntry.createdAt,
                )
              ]);

      final container = makeContainer();
      await container.read(workoutEntriesProvider.future);

      expect(container.read(totalCaloriesProvider), 450);
    });
  });
}
