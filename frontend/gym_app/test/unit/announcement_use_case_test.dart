import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/domain/repositories/i_announcement_repository.dart';
import 'package:gym_app/core/models/announcement_model.dart';
import 'package:gym_app/features/announcement/application/get_announcements_use_case.dart';
import 'package:gym_app/features/announcement/application/create_announcement_use_case.dart';
import 'package:gym_app/features/announcement/application/update_announcement_use_case.dart';
import 'package:gym_app/features/announcement/application/delete_announcement_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockAnnouncementRepository extends Mock implements IAnnouncementRepository {}

void main() {
  late MockAnnouncementRepository mockAnnouncementRepository;
  late GetAnnouncementsUseCase getAnnouncementsUseCase;
  late CreateAnnouncementUseCase createAnnouncementUseCase;
  late UpdateAnnouncementUseCase updateAnnouncementUseCase;
  late DeleteAnnouncementUseCase deleteAnnouncementUseCase;

  final testAnnouncement = Announcement(
    id: '1',
    title: 'New Gym Equipment',
    description: 'We have received new gym equipment.',
    date: '2026-05-31',
  );

  setUpAll(() {
    registerFallbackValue(Announcement(
      id: '',
      title: '',
      description: '',
      date: '',
    ));
  });

  setUp(() {
    mockAnnouncementRepository = MockAnnouncementRepository();
    getAnnouncementsUseCase = GetAnnouncementsUseCase(mockAnnouncementRepository);
    createAnnouncementUseCase = CreateAnnouncementUseCase(mockAnnouncementRepository);
    updateAnnouncementUseCase = UpdateAnnouncementUseCase(mockAnnouncementRepository);
    deleteAnnouncementUseCase = DeleteAnnouncementUseCase(mockAnnouncementRepository);
  });

  group('GetAnnouncementsUseCase', () {
    test('should return list of announcements from repository', () async {
      when(() => mockAnnouncementRepository.getAnnouncements(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => [testAnnouncement]);

      final result = await getAnnouncementsUseCase.call(forceRefresh: true);

      expect(result, [testAnnouncement]);
      verify(() => mockAnnouncementRepository.getAnnouncements(forceRefresh: true)).called(1);
    });

    test('should propagate repository exceptions', () async {
      when(() => mockAnnouncementRepository.getAnnouncements(forceRefresh: any(named: 'forceRefresh')))
          .thenThrow(Exception('Repository error'));

      expect(() => getAnnouncementsUseCase.call(forceRefresh: true), throwsException);
    });
  });

  group('CreateAnnouncementUseCase', () {
    test('should return created announcement from repository', () async {
      when(() => mockAnnouncementRepository.createAnnouncement(any()))
          .thenAnswer((_) async => testAnnouncement);

      final result = await createAnnouncementUseCase.call(testAnnouncement);

      expect(result, testAnnouncement);
      verify(() => mockAnnouncementRepository.createAnnouncement(testAnnouncement)).called(1);
    });

    test('should propagate repository exceptions', () async {
      when(() => mockAnnouncementRepository.createAnnouncement(any()))
          .thenThrow(Exception('Repository error'));

      expect(() => createAnnouncementUseCase.call(testAnnouncement), throwsException);
    });
  });

  group('UpdateAnnouncementUseCase', () {
    test('should return updated announcement from repository', () async {
      when(() => mockAnnouncementRepository.updateAnnouncement(any()))
          .thenAnswer((_) async => testAnnouncement);

      final result = await updateAnnouncementUseCase.call(testAnnouncement);

      expect(result, testAnnouncement);
      verify(() => mockAnnouncementRepository.updateAnnouncement(testAnnouncement)).called(1);
    });

    test('should propagate repository exceptions', () async {
      when(() => mockAnnouncementRepository.updateAnnouncement(any()))
          .thenThrow(Exception('Repository error'));

      expect(() => updateAnnouncementUseCase.call(testAnnouncement), throwsException);
    });
  });

  group('DeleteAnnouncementUseCase', () {
    test('should complete successfully when repository delete succeeds', () async {
      when(() => mockAnnouncementRepository.deleteAnnouncement(any()))
          .thenAnswer((_) async {});

      await deleteAnnouncementUseCase.call('1');

      verify(() => mockAnnouncementRepository.deleteAnnouncement('1')).called(1);
    });

    test('should propagate repository exceptions', () async {
      when(() => mockAnnouncementRepository.deleteAnnouncement(any()))
          .thenThrow(Exception('Repository error'));

      expect(() => deleteAnnouncementUseCase.call('1'), throwsException);
    });
  });
}
