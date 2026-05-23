// Project imports:
import '../domain/workout_entry_model.dart';

class WorkoutStore {
  // Private constructor
  WorkoutStore._internal();

  // Singleton instance
  static final WorkoutStore _instance = WorkoutStore._internal();

  factory WorkoutStore() => _instance;

  final List<WorkoutEntry> _entries = [];

  List<WorkoutEntry> get entries => List.unmodifiable(_entries);

  int get count => _entries.length;

  int get goalPercentage {
    if (_entries.isEmpty) return 0;
    if (_entries.length == 1) return 25;
    if (_entries.length == 2) return 50;
    if (_entries.length == 3) return 75;
    return 100;
  }

  int get totalCalories {
    int sum = 0;
    for (var entry in _entries) {
      if (entry.calories != null && entry.calories!.isNotEmpty) {
        sum += int.tryParse(entry.calories!) ?? 0;
      }
    }
    return sum;
  }

  void addEntry(WorkoutEntry entry) {
    _entries.add(entry);
  }

  void removeEntry(String id) {
    _entries.removeWhere((e) => e.id == id);
  }

  void updateEntry(WorkoutEntry updatedEntry) {
    final index = _entries.indexWhere((e) => e.id == updatedEntry.id);
    if (index != -1) {
      _entries[index] = updatedEntry;
    }
  }
}
