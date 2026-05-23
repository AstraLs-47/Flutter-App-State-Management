// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcements_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$announcementRepositoryHash() =>
    r'6941751df3a5c2535d5a2346254a7de587b6eeea';

/// See also [announcementRepository].
@ProviderFor(announcementRepository)
final announcementRepositoryProvider =
    AutoDisposeProvider<AnnouncementRepositoryImpl>.internal(
      announcementRepository,
      name: r'announcementRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$announcementRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef AnnouncementRepositoryRef =
    AutoDisposeProviderRef<AnnouncementRepositoryImpl>;
String _$announcementsNotifierHash() =>
    r'8ef7cecff131dcef432f69ec8b6162e1440d05ae';

/// See also [AnnouncementsNotifier].
@ProviderFor(AnnouncementsNotifier)
final announcementsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      AnnouncementsNotifier,
      List<Announcement>
    >.internal(
      AnnouncementsNotifier.new,
      name: r'announcementsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$announcementsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AnnouncementsNotifier = AutoDisposeAsyncNotifier<List<Announcement>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
