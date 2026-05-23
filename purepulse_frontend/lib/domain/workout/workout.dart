import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout.freezed.dart';

@freezed
class Workout with _$Workout {
  const factory Workout({
    required String id,
    required String name,
    required DateTime date,
    @Default(false) bool isCompleted,
  }) = _Workout;
}
