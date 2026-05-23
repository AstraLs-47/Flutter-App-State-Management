class Activity {
  final String id;
  final String title;
  final String description;
  final String image;
  final String category;
  final String duration;
  final String warmup;
  final String mainWorkout;
  final String rest;

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.category,
    this.duration = '',
    this.warmup = '',
    this.mainWorkout = '',
    this.rest = '',
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      image: json['image'],
      category: json['category'],
      duration: json['duration'] ?? '',
      warmup: json['warmup'] ?? '',
      mainWorkout: json['mainWorkout'] ?? '',
      rest: json['rest'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image': image,
      'category': category,
      'duration': duration,
      'warmup': warmup,
      'mainWorkout': mainWorkout,
      'rest': rest,
    };
  }

  Activity copyWith({
    String? id,
    String? title,
    String? description,
    String? image,
    String? category,
    String? duration,
    String? warmup,
    String? mainWorkout,
    String? rest,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      warmup: warmup ?? this.warmup,
      mainWorkout: mainWorkout ?? this.mainWorkout,
      rest: rest ?? this.rest,
    );
  }
}
