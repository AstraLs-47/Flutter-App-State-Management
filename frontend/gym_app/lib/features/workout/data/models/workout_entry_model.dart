class WorkoutEntry {
  final String id;
  final String title;
  final String date;
  final String duration;
  final String exercise;
  final String intensity;
  final String weight;
  final String sets;
  final String reps;
  final String? calories; // optional
  final String? achievement; // optional
  final String? notes; // optional
  final String? createdAt; // optional

  WorkoutEntry({
    required this.id,
    required this.title,
    required this.date,
    required this.duration,
    required this.exercise,
    required this.intensity,
    required this.weight,
    required this.sets,
    required this.reps,
    this.calories,
    this.achievement,
    this.notes,
    this.createdAt,
  });

  factory WorkoutEntry.fromJson(Map<String, dynamic> json) {
    return WorkoutEntry(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      duration: json['duration'] ?? '',
      exercise: json['exercise'] ?? '',
      intensity: json['intensity'] ?? '',
      weight: json['weight']?.toString() ?? '',
      sets: json['sets']?.toString() ?? '',
      reps: json['reps']?.toString() ?? '',
      calories: json['calories']?.toString(),
      achievement: json['achievement']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'duration': duration,
      'exercise': exercise,
      'intensity': intensity,
      'weight': weight,
      'sets': sets,
      'reps': reps,
      'calories': calories,
      'achievement': achievement,
      'notes': notes,
      'createdAt': createdAt,
    };
  }
}
