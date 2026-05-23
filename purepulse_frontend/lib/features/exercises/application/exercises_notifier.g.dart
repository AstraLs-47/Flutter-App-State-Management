// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercises_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$exerciseRepositoryHash() =>
    r'01973cb1ab83a94770626cca9b5320d80a088d0d';

/// See also [exerciseRepository].
@ProviderFor(exerciseRepository)
final exerciseRepositoryProvider =
    AutoDisposeProvider<ExerciseRepositoryImpl>.internal(
      exerciseRepository,
      name: r'exerciseRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$exerciseRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef ExerciseRepositoryRef = AutoDisposeProviderRef<ExerciseRepositoryImpl>;
String _$activitiesNotifierHash() =>
    r'90de446da8449c29110c13e112880e64a069db84';

/// See also [ActivitiesNotifier].
@ProviderFor(ActivitiesNotifier)
final activitiesNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      ActivitiesNotifier,
      List<Activity>
    >.internal(
      ActivitiesNotifier.new,
      name: r'activitiesNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activitiesNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ActivitiesNotifier = AutoDisposeAsyncNotifier<List<Activity>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
