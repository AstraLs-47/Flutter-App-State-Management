import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/models/announcement_model.dart';
import 'package:gym_app/core/providers/core_providers.dart';
import 'package:gym_app/features/announcement/application/create_announcement_use_case.dart';
import 'package:gym_app/features/announcement/application/delete_announcement_use_case.dart';
import 'package:gym_app/features/announcement/application/get_announcements_use_case.dart';
import 'package:gym_app/features/announcement/application/update_announcement_use_case.dart';
import 'package:gym_app/features/announcement/presentation/providers/announcement_providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockGetAnnouncementsUseCase extends Mock implements GetAnnouncementsUseCase {}
class MockCreateAnnouncementUseCase extends Mock implements CreateAnnouncementUseCase {}
class MockUpdateAnnouncementUseCase extends Mock implements UpdateAnnouncementUseCase {}
class MockDeleteAnnouncementUseCase extends Mock implements DeleteAnnouncementUseCase {}

void main() {
  late MockGetAnnouncementsUseCase mockGetAnnouncementsUseCase;
  late MockCreateAnnouncementUseCase mockCreateAnnouncementUseCase;
  late MockUpdateAnnouncementUseCase mockUpdateAnnouncementUseCase;
  late MockDeleteAnnouncementUseCase mockDeleteAnnouncementUseCase;

  final testAnnouncement = Announcement(
    id: 'a1',
    title: 'Hours Change',
    description: 'Gym will close at 8 PM today.',
    date: '2026-05-31',
  );

  setUpAll(() {
    registerFallbackValue(Announcement(id: '', title: '', description: '', date: ''));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockGetAnnouncementsUseCase = MockGetAnnouncementsUseCase();
    mockCreateAnnouncementUseCase = MockCreateAnnouncementUseCase();
    mockUpdateAnnouncementUseCase = MockUpdateAnnouncementUseCase();
    mockDeleteAnnouncementUseCase = MockDeleteAnnouncementUseCase();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        getAnnouncementsUseCaseProvider.overrideWithValue(mockGetAnnouncementsUseCase),
        createAnnouncementUseCaseProvider.overrideWithValue(mockCreateAnnouncementUseCase),
        updateAnnouncementUseCaseProvider.overrideWithValue(mockUpdateAnnouncementUseCase),
        deleteAnnouncementUseCaseProvider.overrideWithValue(mockDeleteAnnouncementUseCase),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AnnouncementsNotifier', () {
    test('initial state loads announcements and sets new announcement status', () async {
      when(() => mockGetAnnouncementsUseCase.call(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => [testAnnouncement]);

      final container = makeContainer();
      final state = await container.read(announcementsProvider.future);

      expect(state, [testAnnouncement]);
      expect(container.read(hasNewAnnouncementsProvider), true);
      verify(() => mockGetAnnouncementsUseCase.call(forceRefresh: false)).called(1);
    });

    test('markAnnouncementsAsViewed resets new announcement status', () async {
      when(() => mockGetAnnouncementsUseCase.call(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => [testAnnouncement]);

      final container = makeContainer();
      await container.read(announcementsProvider.future);
      expect(container.read(hasNewAnnouncementsProvider), true);

      final notifier = container.read(announcementsProvider.notifier);
      await notifier.markAnnouncementsAsViewed();

      expect(container.read(hasNewAnnouncementsProvider), false);
    });

    test('addAnnouncement adds to state and checks new status', () async {
      when(() => mockGetAnnouncementsUseCase.call(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => []);
      when(() => mockCreateAnnouncementUseCase.call(any()))
          .thenAnswer((_) async => testAnnouncement);

      final container = makeContainer();
      await container.read(announcementsProvider.future);

      final notifier = container.read(announcementsProvider.notifier);
      await notifier.addAnnouncement(testAnnouncement);

      final state = container.read(announcementsProvider);
      expect(state.value, [testAnnouncement]);
      expect(container.read(hasNewAnnouncementsProvider), true);
    });

    test('updateAnnouncement updates state element', () async {
      when(() => mockGetAnnouncementsUseCase.call(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => [testAnnouncement]);

      final updatedAnnouncement = testAnnouncement.copyWith(title: 'Updated Title');
      when(() => mockUpdateAnnouncementUseCase.call(any()))
          .thenAnswer((_) async => updatedAnnouncement);

      final container = makeContainer();
      await container.read(announcementsProvider.future);

      final notifier = container.read(announcementsProvider.notifier);
      await notifier.updateAnnouncement(updatedAnnouncement);

      final state = container.read(announcementsProvider);
      expect(state.value!.first.title, 'Updated Title');
    });

    test('deleteAnnouncement removes element from list', () async {
      when(() => mockGetAnnouncementsUseCase.call(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => [testAnnouncement]);
      when(() => mockDeleteAnnouncementUseCase.call(any())).thenAnswer((_) async => {});

      final container = makeContainer();
      await container.read(announcementsProvider.future);

      final notifier = container.read(announcementsProvider.notifier);
      await notifier.deleteAnnouncement('a1');

      final state = container.read(announcementsProvider);
      expect(state.value, isEmpty);
    });
  });
}
