// Unit tests for domain models and business logic
// Tests: WorkoutEntry, HealthRecord, Activity, Announcement, Product, Result, Failures

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/models/activity_model.dart';
import 'package:gym_app/core/models/announcement_model.dart';
import 'package:gym_app/core/models/product_model.dart';
import 'package:gym_app/domain/core/failures.dart';
import 'package:gym_app/domain/core/result.dart';
import 'package:gym_app/features/workout/domain/workout_entry_model.dart';
import 'package:gym_app/features/progress/domain/health_record_model.dart';
import 'package:gym_app/domain/auth/user.dart';

void main() {
  // ─────────────────────────────────────────────
  // WorkoutEntry model tests
  // ─────────────────────────────────────────────
  group('WorkoutEntry', () {
    final workout = WorkoutEntry(
      id: 'w1',
      title: 'Morning Run',
      date: '2024-01-15',
      duration: '30 MIN',
      exercise: 'Running (Cardio)',
      intensity: 'Moderate',
      weight: '0',
      sets: '3',
      reps: '10',
      calories: '250',
      achievement: 'New PB!',
      notes: 'Felt great',
    );

    test('creates from constructor with all fields', () {
      expect(workout.id, 'w1');
      expect(workout.title, 'Morning Run');
      expect(workout.date, '2024-01-15');
      expect(workout.duration, '30 MIN');
      expect(workout.intensity, 'Moderate');
      expect(workout.calories, '250');
      expect(workout.achievement, 'New PB!');
      expect(workout.notes, 'Felt great');
    });

    test('toJson returns correct map', () {
      final json = workout.toJson();
      expect(json['id'], 'w1');
      expect(json['title'], 'Morning Run');
      expect(json['date'], '2024-01-15');
      expect(json['exercise'], 'Running (Cardio)');
      expect(json['intensity'], 'Moderate');
      expect(json['calories'], '250');
    });

    test('fromJson reconstructs correctly', () {
      final json = workout.toJson();
      final fromJson = WorkoutEntry.fromJson(json);
      expect(fromJson.id, workout.id);
      expect(fromJson.title, workout.title);
      expect(fromJson.date, workout.date);
      expect(fromJson.duration, workout.duration);
      expect(fromJson.sets, workout.sets);
      expect(fromJson.reps, workout.reps);
    });

    test('optional fields can be null', () {
      final minimal = WorkoutEntry(
        id: 'w2',
        title: 'Quick Session',
        date: '2024-01-16',
        duration: '15 MIN',
        exercise: 'Cycling (Cardio)',
        intensity: 'Light',
        weight: '0',
        sets: '1',
        reps: '1',
      );
      expect(minimal.calories, isNull);
      expect(minimal.achievement, isNull);
      expect(minimal.notes, isNull);
    });

    test('toJson / fromJson round-trip with nulls', () {
      final minimal = WorkoutEntry(
        id: 'w3',
        title: 'Test',
        date: '2024-02-01',
        duration: '20 MIN',
        exercise: 'Jump Rope (Cardio)',
        intensity: 'Intense',
        weight: '5',
        sets: '4',
        reps: '12',
      );
      final roundTrip = WorkoutEntry.fromJson(minimal.toJson());
      expect(roundTrip.id, 'w3');
      expect(roundTrip.calories, isNull);
    });
  });

  // ─────────────────────────────────────────────
  // HealthRecord model tests
  // ─────────────────────────────────────────────
  group('HealthRecord', () {
    final record = HealthRecord(
      id: 'h1',
      systolic: 120.0,
      diastolic: 80.0,
      heartRate: 72.0,
      bloodSugar: 95.0,
      weight: 70.0,
      height: 175.0,
      bmi: 22.9,
      date: DateTime(2024, 1, 15),
    );

    test('creates with all fields', () {
      expect(record.id, 'h1');
      expect(record.systolic, 120.0);
      expect(record.diastolic, 80.0);
      expect(record.heartRate, 72.0);
      expect(record.bloodSugar, 95.0);
      expect(record.weight, 70.0);
      expect(record.height, 175.0);
      expect(record.bmi, 22.9);
    });

    test('toJson includes date as ISO string', () {
      final json = record.toJson();
      expect(json['id'], 'h1');
      expect(json['systolic'], 120.0);
      expect(json['date'], record.date.toIso8601String());
    });

    test('fromJson reconstructs with correct types', () {
      final json = record.toJson();
      final fromJson = HealthRecord.fromJson(json);
      expect(fromJson.id, 'h1');
      expect(fromJson.systolic, 120.0);
      expect(fromJson.bmi, 22.9);
      expect(fromJson.date, record.date);
    });

    test('bmiCategory returns Normal for bmi 22.9', () {
      expect(record.bmiCategory, 'Normal');
    });

    test('bmiCategory returns Underweight for bmi < 18.5', () {
      final r = HealthRecord(
        id: 'h2', systolic: 110, diastolic: 70, heartRate: 65,
        bloodSugar: 90, weight: 50, height: 175, bmi: 16.3,
        date: DateTime.now(),
      );
      expect(r.bmiCategory, 'Underweight');
    });

    test('bmiCategory returns Overweight for bmi 27', () {
      final r = HealthRecord(
        id: 'h3', systolic: 130, diastolic: 85, heartRate: 78,
        bloodSugar: 100, weight: 85, height: 175, bmi: 27.8,
        date: DateTime.now(),
      );
      expect(r.bmiCategory, 'Overweight');
    });

    test('bmiCategory returns Obese for bmi >= 30', () {
      final r = HealthRecord(
        id: 'h4', systolic: 140, diastolic: 90, heartRate: 82,
        bloodSugar: 110, weight: 100, height: 175, bmi: 32.7,
        date: DateTime.now(),
      );
      expect(r.bmiCategory, 'Obese');
    });
  });

  // ─────────────────────────────────────────────
  // Activity model tests
  // ─────────────────────────────────────────────
  group('Activity', () {
    final activity = Activity(
      id: 'a1',
      title: 'Full Cardio Burn',
      description: 'Complete cardio session',
      image: 'assets/full_cardioburn_image.jpg',
      category: 'Cardio',
      duration: '45 mins',
      warmup: '5 mins jog',
      mainWorkout: 'HIIT intervals',
      rest: '5 mins stretch',
    );

    test('creates with all fields', () {
      expect(activity.id, 'a1');
      expect(activity.title, 'Full Cardio Burn');
      expect(activity.category, 'Cardio');
      expect(activity.duration, '45 mins');
    });

    test('toJson and fromJson round-trip', () {
      final json = activity.toJson();
      final restored = Activity.fromJson(json);
      expect(restored.id, activity.id);
      expect(restored.title, activity.title);
      expect(restored.category, activity.category);
      expect(restored.warmup, activity.warmup);
      expect(restored.mainWorkout, activity.mainWorkout);
    });

    test('copyWith produces updated instance', () {
      final updated = activity.copyWith(title: 'Updated Cardio');
      expect(updated.title, 'Updated Cardio');
      expect(updated.id, activity.id);
      expect(updated.category, activity.category);
    });

    test('default values for optional fields', () {
      final minimal = Activity(
        id: 'a2',
        title: 'Test',
        description: 'desc',
        image: 'img',
        category: 'Strength',
      );
      expect(minimal.duration, '');
      expect(minimal.warmup, '');
      expect(minimal.mainWorkout, '');
      expect(minimal.rest, '');
    });
  });

  // ─────────────────────────────────────────────
  // Announcement model tests
  // ─────────────────────────────────────────────
  group('Announcement', () {
    final ann = Announcement(
      id: 'n1',
      title: 'Holiday Hours',
      description: 'Gym closes at 3PM on holidays.',
      date: '2024-12-25',
    );

    test('creates with all fields', () {
      expect(ann.id, 'n1');
      expect(ann.title, 'Holiday Hours');
      expect(ann.date, '2024-12-25');
    });

    test('toJson / fromJson round-trip', () {
      final json = ann.toJson();
      final restored = Announcement.fromJson(json);
      expect(restored.id, ann.id);
      expect(restored.title, ann.title);
      expect(restored.description, ann.description);
      expect(restored.date, ann.date);
    });

    test('copyWith updates only specified field', () {
      final updated = ann.copyWith(title: 'New Year Special');
      expect(updated.title, 'New Year Special');
      expect(updated.id, ann.id);
      expect(updated.date, ann.date);
    });
  });

  // ─────────────────────────────────────────────
  // Product model tests
  // ─────────────────────────────────────────────
  group('Product', () {
    final product = Product(
      id: 'p1',
      title: 'Speed Jump Rope',
      description: 'A jump rope with a thin PVC cord.',
      category: 'EQUIPMENT',
      image: 'assets/speed_jump_rope.png',
    );

    test('creates with all fields', () {
      expect(product.id, 'p1');
      expect(product.title, 'Speed Jump Rope');
      expect(product.category, 'EQUIPMENT');
    });

    test('toJson / fromJson round-trip', () {
      final json = product.toJson();
      final restored = Product.fromJson(json);
      expect(restored.id, product.id);
      expect(restored.title, product.title);
      expect(restored.category, product.category);
      expect(restored.image, product.image);
    });

    test('copyWith updates description only', () {
      final updated = product.copyWith(description: 'Updated description');
      expect(updated.description, 'Updated description');
      expect(updated.id, product.id);
      expect(updated.category, product.category);
    });
  });

  // ─────────────────────────────────────────────
  // Result sealed class tests
  // ─────────────────────────────────────────────
  group('Result<S, F>', () {
    test('Success holds its value', () {
      const result = Success<String, String>('hello');
      expect(result.value, 'hello');
      expect(result, isA<Success<String, String>>());
    });

    test('Failure holds its error', () {
      const result = Failure<String, String>('error message');
      expect(result.error, 'error message');
      expect(result, isA<Failure<String, String>>());
    });

    test('Success is not Failure', () {
      const result = Success<int, String>(42);
      expect(result is Failure, isFalse);
    });

    test('Failure is not Success', () {
      const result = Failure<int, String>('fail');
      expect(result is Success, isFalse);
    });

    test('Success with null value allowed', () {
      const result = Success<void, String>(null);
      expect(result, isA<Success>());
    });
  });

  // ─────────────────────────────────────────────
  // Failure classes tests
  // ─────────────────────────────────────────────
  group('Failure classes', () {
    test('AuthFailure stores message', () {
      const f = AuthFailure('Invalid credentials');
      expect(f.message, 'Invalid credentials');
    });

    test('AuthFailure has default message', () {
      const f = AuthFailure();
      expect(f.message, 'Authentication Error');
    });

    test('ServerFailure stores message', () {
      const f = ServerFailure('Server is down');
      expect(f.message, 'Server is down');
    });

    test('ServerFailure has default message', () {
      const f = ServerFailure();
      expect(f.message, 'Server Error');
    });

    test('CacheFailure stores message', () {
      const f = CacheFailure('DB locked');
      expect(f.message, 'DB locked');
    });

    test('CacheFailure has default message', () {
      const f = CacheFailure();
      expect(f.message, 'Cache Error');
    });

    test('Failures are subtypes of CoreFailure', () {
      expect(const AuthFailure(), isA<CoreFailure>());
      expect(const ServerFailure(), isA<CoreFailure>());
      expect(const CacheFailure(), isA<CoreFailure>());
    });
  });

  // ─────────────────────────────────────────────
  // User domain model tests
  // ─────────────────────────────────────────────
  group('User domain model', () {
    const user = User(
      id: 'u1',
      name: 'John Doe',
      email: 'john@example.com',
      role: UserRole.user,
    );

    test('creates user with all fields', () {
      expect(user.id, 'u1');
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.role, UserRole.user);
    });

    test('admin role can be set', () {
      const admin = User(
        id: 'admin-1',
        name: 'Admin',
        email: 'admin@purepulse.com',
        role: UserRole.admin,
      );
      expect(admin.role, UserRole.admin);
    });

    test('copyWith updates role', () {
      final promoted = user.copyWith(role: UserRole.admin);
      expect(promoted.role, UserRole.admin);
      expect(promoted.id, user.id);
      expect(promoted.name, user.name);
    });

    test('equality works for identical users', () {
      const user2 = User(
        id: 'u1',
        name: 'John Doe',
        email: 'john@example.com',
        role: UserRole.user,
      );
      expect(user, equals(user2));
    });

    test('inequality for different ids', () {
      const user3 = User(
        id: 'u2',
        name: 'John Doe',
        email: 'john@example.com',
        role: UserRole.user,
      );
      expect(user, isNot(equals(user3)));
    });
  });

  // ─────────────────────────────────────────────
  // Business logic: BMI calculation tests
  // ─────────────────────────────────────────────
  group('BMI business logic', () {
    HealthRecord makeRecord(double bmi) => HealthRecord(
          id: 'test',
          systolic: 120,
          diastolic: 80,
          heartRate: 70,
          bloodSugar: 90,
          weight: 70,
          height: 175,
          bmi: bmi,
          date: DateTime.now(),
        );

    test('bmi exactly 18.5 is Normal', () {
      expect(makeRecord(18.5).bmiCategory, 'Normal');
    });

    test('bmi exactly 25 is Overweight', () {
      expect(makeRecord(25.0).bmiCategory, 'Overweight');
    });

    test('bmi exactly 30 is Obese', () {
      expect(makeRecord(30.0).bmiCategory, 'Obese');
    });

    test('bmi 17.9 is Underweight', () {
      expect(makeRecord(17.9).bmiCategory, 'Underweight');
    });
  });
}
