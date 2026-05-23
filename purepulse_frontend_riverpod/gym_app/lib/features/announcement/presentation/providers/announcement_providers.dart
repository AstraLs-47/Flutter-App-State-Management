import 'dart:async';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import '../../../../core/models/announcement_model.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/announcement_repository.dart';

class AnnouncementsNotifier extends AsyncNotifier<List<Announcement>> {
  AnnouncementRepository get _repository => ref.read(announcementRepositoryProvider);

  @override
  FutureOr<List<Announcement>> build() async {
    return _fetchAnnouncements();
  }

  Future<List<Announcement>> _fetchAnnouncements({bool forceRefresh = false}) async {
    final announcements = await _repository.getAnnouncements(forceRefresh: forceRefresh);
    await _checkNewAnnouncements(announcements);
    return announcements;
  }

  Future<void> loadAnnouncements({bool forceRefresh = false}) async {
    if (!forceRefresh) state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAnnouncements(forceRefresh: forceRefresh));
  }

  Future<void> _checkNewAnnouncements(List<Announcement> list) async {
    final prefs = await SharedPreferences.getInstance();
    final lastViewedId = prefs.getString('last_viewed_announcement_id');

    if (list.isNotEmpty && lastViewedId != list.first.id) {
      ref.read(hasNewAnnouncementsProvider.notifier).state = true;
    } else {
      ref.read(hasNewAnnouncementsProvider.notifier).state = false;
    }
  }

  Future<void> markAnnouncementsAsViewed() async {
    state.whenData((list) async {
      if (list.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_viewed_announcement_id', list.first.id);
        ref.read(hasNewAnnouncementsProvider.notifier).state = false;
      }
    });
  }

  Future<void> addAnnouncement(Announcement announcement) async {
    state = await AsyncValue.guard(() async {
      final response = await _repository.createAnnouncement(announcement);
      final currentList = state.value ?? [];
      final updatedList = [response, ...currentList];
      await _checkNewAnnouncements(updatedList);
      
      return updatedList;
    });
  }

  Future<void> updateAnnouncement(Announcement announcement) async {
    state = await AsyncValue.guard(() async {
      final response = await _repository.updateAnnouncement(announcement);
      final currentList = state.value ?? [];
      return currentList.map((e) => e.id == response.id ? response : e).toList();
    });
  }

  Future<void> deleteAnnouncement(String id) async {
    state = await AsyncValue.guard(() async {
      await _repository.deleteAnnouncement(id);
      final currentList = state.value ?? [];
      return currentList.where((e) => e.id != id).toList();
    });
  }
}

// Providers
final announcementsProvider = AsyncNotifierProvider<AnnouncementsNotifier, List<Announcement>>(() {
  return AnnouncementsNotifier();
});

final hasNewAnnouncementsProvider = StateProvider<bool>((ref) => false);
