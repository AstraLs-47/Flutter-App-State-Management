// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_metrics_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$healthRepositoryHash() =>
    r'c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0';

/// See also [healthRepository].
@ProviderFor(healthRepository)
final healthRepositoryProvider =
    AutoDisposeProvider<HealthRepositoryImpl>.internal(
      healthRepository,
      name: r'healthRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$healthRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef HealthRepositoryRef = AutoDisposeProviderRef<HealthRepositoryImpl>;

String _$healthMetricsNotifierHash() =>
    r'd1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0';

/// See also [HealthMetricsNotifier].
@ProviderFor(HealthMetricsNotifier)
final healthMetricsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<HealthMetricsNotifier, List<HealthRecord>>.internal(
      HealthMetricsNotifier.new,
      name: r'healthMetricsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$healthMetricsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$HealthMetricsNotifier = AutoDisposeAsyncNotifier<List<HealthRecord>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
