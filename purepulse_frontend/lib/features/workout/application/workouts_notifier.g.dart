// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workouts_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$workoutRepositoryHash() =>
    r'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0';

/// See also [workoutRepository].
@ProviderFor(workoutRepository)
final workoutRepositoryProvider =
    AutoDisposeProvider<WorkoutRepositoryImpl>.internal(
      workoutRepository,
      name: r'workoutRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$workoutRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef WorkoutRepositoryRef = AutoDisposeProviderRef<WorkoutRepositoryImpl>;

String _$workoutsNotifierHash() =>
    r'b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0';

/// See also [WorkoutsNotifier].
@ProviderFor(WorkoutsNotifier)
final workoutsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<WorkoutsNotifier, List<WorkoutEntry>>.internal(
      WorkoutsNotifier.new,
      name: r'workoutsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$workoutsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$WorkoutsNotifier = AutoDisposeAsyncNotifier<List<WorkoutEntry>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
