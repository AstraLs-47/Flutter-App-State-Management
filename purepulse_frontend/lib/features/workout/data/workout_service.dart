// Project imports:
import '../domain/workout_entry_model.dart';
import 'workout_store.dart';

class WorkoutService {
  final WorkoutStore _store = WorkoutStore();

  Future<List<WorkoutEntry>> fetchWorkoutLogs() async {
    await Future.delayed(const Duration(seconds: 1));
    return _store.entries;
  }

  Future<void> logWorkout(WorkoutEntry entry) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _store.addEntry(entry);
  }

  Future<void> updateWorkout(WorkoutEntry entry) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _store.updateEntry(entry);
  }

  Future<void> deleteWorkout(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _store.removeEntry(id);
  }
}
