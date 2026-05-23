import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise.freezed.dart';

@freezed
class Exercise with _$Exercise {
  const factory Exercise({
    required String id,
    required String workoutId,
    required String name,
    required int sets,
    required int reps,
    required double weight,
  }) = _Exercise;
}
