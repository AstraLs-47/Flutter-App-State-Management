import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/domain/repositories/i_admin_repository.dart';
import 'package:gym_app/core/domain/repositories/i_announcement_repository.dart';
import 'package:gym_app/core/domain/repositories/i_health_repository.dart';
import 'package:gym_app/core/domain/repositories/i_progress_repository.dart';
import 'package:gym_app/core/models/announcement_model.dart';
import 'package:gym_app/features/dashboard/application/get_dashboard_stats_use_case.dart';
import 'package:gym_app/features/progress/data/health_store.dart';
import 'package:gym_app/features/progress/data/models/health_record_model.dart';
import 'package:gym_app/features/workout/data/models/workout_entry_model.dart';
import 'package:gym_app/features/workout/data/workout_store.dart';
import 'package:mocktail/mocktail.dart';

class MockHealthRepository extends Mock implements IHealthRepository {}
class MockProgressRepository extends Mock implements IProgressRepository {}
class MockAnnouncementRepository extends Mock implements IAnnouncementRepository {}
class MockAdminRepository extends Mock implements IAdminRepository {}
class MockHealthStore extends Mock implements HealthStore {}
class MockWorkoutStore extends Mock implements WorkoutStore {}

void main() {
  late MockHealthRepository mockHealthRepo;
  late MockProgressRepository mockProgressRepo;
  late MockAnnouncementRepository mockAnnouncementRepo;
  late MockAdminRepository mockAdminRepo;
  late MockHealthStore mockHealthStore;
  late MockWorkoutStore mockWorkoutStore;
  late GetDashboardStatsUseCase useCase;

  setUp(() {
    mockHealthRepo = MockHealthRepository();
    mockProgressRepo = MockProgressRepository();
    mockAnnouncementRepo = MockAnnouncementRepository();
    mockAdminRepo = MockAdminRepository();
    mockHealthStore = MockHealthStore();
    mockWorkoutStore = MockWorkoutStore();

    useCase = GetDashboardStatsUseCase(
      healthRepo: mockHealthRepo,
      progressRepo: mockProgressRepo,
      announcementRepo: mockAnnouncementRepo,
      adminRepo: mockAdminRepo,
      healthStore: mockHealthStore,
      workoutStore: mockWorkoutStore,
    );
  });

  group('GetDashboardStatsUseCase', () {
    final healthRecords = <HealthRecord>[];
    final workoutEntries = <WorkoutEntry>[];
    final announcements = <Announcement>[
      Announcement(id: '1', title: 'T', description: 'D', date: '2026-05-31')
    ];

    test('should succeed and return correct stats when all calls succeed', () async {
      when(() => mockHealthRepo.getHealthRecords()).thenAnswer((_) async => healthRecords);
      when(() => mockHealthStore.setRecords(any())).thenAnswer((_) {});
      when(() => mockHealthStore.latestBmi).thenReturn(22.5);
      when(() => mockHealthStore.latestHeartRate).thenReturn(72.0);

      when(() => mockProgressRepo.getWorkoutEntries()).thenAnswer((_) async => workoutEntries);
      when(() => mockWorkoutStore.setEntries(any())).thenAnswer((_) {});
      when(() => mockWorkoutStore.count).thenReturn(5);

      when(() => mockAdminRepo.hasNewAnnouncements).thenReturn(false);
      when(() => mockAnnouncementRepo.getAnnouncements()).thenAnswer((_) async => announcements);

      final result = await useCase.call();

      expect(result['avgBmi'], 22.5);
      expect(result['avgHr'], 72.0);
      expect(result['totalActivities'], 5);
      expect(result['hasNewAnnouncements'], true);

      verify(() => mockHealthRepo.getHealthRecords()).called(1);
      verify(() => mockHealthStore.setRecords(healthRecords)).called(1);
      verify(() => mockProgressRepo.getWorkoutEntries()).called(1);
      verify(() => mockWorkoutStore.setEntries(workoutEntries)).called(1);
      verify(() => mockAnnouncementRepo.getAnnouncements()).called(1);
    });

    test('should degrade gracefully when individual repository calls throw errors', () async {
      // 1. healthRepo throws
      when(() => mockHealthRepo.getHealthRecords()).thenThrow(Exception('Health error'));
      when(() => mockHealthStore.latestBmi).thenReturn(0.0);
      when(() => mockHealthStore.latestHeartRate).thenReturn(0.0);

      // 2. progressRepo throws
      when(() => mockProgressRepo.getWorkoutEntries()).thenThrow(Exception('Progress error'));
      when(() => mockWorkoutStore.count).thenReturn(0);

      // 3. announcementRepo throws, fallback to adminRepo.hasNewAnnouncements (true)
      when(() => mockAdminRepo.hasNewAnnouncements).thenReturn(true);
      when(() => mockAnnouncementRepo.getAnnouncements()).thenThrow(Exception('Announcement error'));

      final result = await useCase.call();

      expect(result['avgBmi'], 0.0);
      expect(result['avgHr'], 0.0);
      expect(result['totalActivities'], 0);
      expect(result['hasNewAnnouncements'], true);

      verify(() => mockHealthRepo.getHealthRecords()).called(1);
      verifyNever(() => mockHealthStore.setRecords(any()));
      verify(() => mockProgressRepo.getWorkoutEntries()).called(1);
      verifyNever(() => mockWorkoutStore.setEntries(any()));
      verify(() => mockAnnouncementRepo.getAnnouncements()).called(1);
    });
  });
}
