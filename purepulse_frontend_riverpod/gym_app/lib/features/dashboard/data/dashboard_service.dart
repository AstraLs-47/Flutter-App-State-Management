// Project imports:
import '../../admin/data/admin_repository.dart';
import '../../announcement/data/announcement_repository.dart';
import '../../progress/data/health_repository.dart';
import '../../progress/data/health_store.dart';
import '../../workout/data/progress_repository.dart';
import '../../workout/data/workout_store.dart';

class DashboardService {
  final HealthRepository _healthRepo = HealthRepository();
  final ProgressRepository _progressRepo = ProgressRepository();
  final AnnouncementRepository _announcementRepo = AnnouncementRepository();
  final HealthStore _healthStore = HealthStore();
  final WorkoutStore _workoutStore = WorkoutStore();
  final AdminRepository _db = AdminRepository();

  Future<Map<String, dynamic>> fetchDashboardStats() async {
    // 1. Sync health records → HealthStore (so avgBmi / avgHr are real)
    try {
      final records = await _healthRepo.getHealthRecords();
      _healthStore.setRecords(records);
    } catch (_) {}

    // 2. Sync workout entries → WorkoutStore (so progress counters are real)
    try {
      final entries = await _progressRepo.getWorkoutEntries();
      _workoutStore.setEntries(entries);
    } catch (_) {}

    // 3. Check for any announcements
    bool hasNewAnnouncements = _db.hasNewAnnouncements;
    try {
      final announcements = await _announcementRepo.getAnnouncements();
      hasNewAnnouncements = announcements.isNotEmpty;
    } catch (_) {}

    return {
      'avgBmi': _healthStore.latestBmi,
      'avgHr': _healthStore.latestHeartRate,
      'totalActivities': _workoutStore.count,
      'hasNewAnnouncements': hasNewAnnouncements,
    };
  }
}
