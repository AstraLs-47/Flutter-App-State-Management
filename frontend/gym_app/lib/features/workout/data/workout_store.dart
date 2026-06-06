// Flutter imports:
import 'package:flutter/foundation.dart';

// Project imports:
import 'models/workout_entry_model.dart';
import 'progress_repository.dart';

/// Singleton store for workout entries.
/// Extends [ChangeNotifier] so any widget can listen and rebuild
/// automatically whenever entries are added, removed or synced.
class WorkoutStore extends ChangeNotifier {
  // Private constructor
  WorkoutStore._internal();

  // Singleton instance
  static final WorkoutStore _instance = WorkoutStore._internal();

  factory WorkoutStore() => _instance;

  final List<WorkoutEntry> _entries = [];

  List<WorkoutEntry> get entries => List.unmodifiable(_entries);

  int get count => _entries.length;

  int get todayCount {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    int count = 0;
    for (final entry in _entries) {
      final dateStr = entry.createdAt ?? entry.date;
      final parsedDate = DateTime.tryParse(dateStr);
      if (parsedDate != null) {
        final diffMs = nowMs - parsedDate.millisecondsSinceEpoch;
        if (diffMs.abs() < 24 * 60 * 60 * 1000) {
          count++;
        }
      }
    }
    return count;
  }

  int get todayGoalPercentage {
    final c = todayCount;
    if (c <= 0) return 0;
    if (c >= 4) return 100;
    return c * 25;
  }

  int get todayCalories {
    final today = DateTime.now().toIso8601String().split('T').first;
    int sum = 0;
    for (final entry in _entries) {
      if (entry.date == today) {
        sum += int.tryParse(entry.calories ?? '') ?? 0;
      }
    }
    return sum;
  }

  int get totalCalories {
    int sum = 0;
    for (final entry in _entries) {
      sum += int.tryParse(entry.calories ?? '') ?? 0;
    }
    return sum;
  }

  void setEntries(List<WorkoutEntry> newEntries) {
    _entries
      ..clear()
      ..addAll(newEntries)
      ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  void addEntryInMemoryOnly(WorkoutEntry entry) {
    _entries
      ..add(entry)
      ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  void removeEntryInMemoryOnly(String id) {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void updateEntryInMemoryOnly(WorkoutEntry updatedEntry) {
    final index = _entries.indexWhere((e) => e.id == updatedEntry.id);
    if (index != -1) {
      _entries[index] = updatedEntry;
    }
    _entries.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<WorkoutEntry> addEntry(WorkoutEntry entry) async {
    final newEntry = await ProgressRepository().createWorkoutEntry(entry);
    addEntryInMemoryOnly(newEntry);
    return newEntry;
  }

  Future<void> removeEntry(String id) async {
    await ProgressRepository().deleteWorkoutEntry(id);
    removeEntryInMemoryOnly(id);
  }

  Future<WorkoutEntry> updateEntry(WorkoutEntry updatedEntry) async {
    final newEntry = await ProgressRepository().updateWorkoutEntry(updatedEntry);
    updateEntryInMemoryOnly(newEntry);
    return newEntry;
  }
}
