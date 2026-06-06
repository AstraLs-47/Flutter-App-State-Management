// Integration test helpers
//
// Shared utilities used across all integration test files:
//   - safePump()        : bounded pump that avoids pumpAndSettle timeouts
//   - pumpFor()         : fixed-duration pump for async data loads
//   - landingScreenFinder : locates the RichText landing title
//   - goToSignIn()      : taps "Get Started" and pumps
//   - signIn()          : fills email/password and submits sign-in
//   - buildMockClient() : returns a MockClient intercepting all API calls

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gym_app/core/widgets/custom_button.dart';
import 'package:gym_app/core/data/database_helper.dart';

// ---------------------------------------------------------------------------
// Mock Database State
// ---------------------------------------------------------------------------

/// In-memory store to simulate persistent database storage during tests.
final Map<String, Map<String, dynamic>> _mockDb = {};
final Map<String, String> _tokens = {}; // token -> email lookup

/// Resets the mock database and populates it with default test accounts.
/// This ensures tests start from a clean state but have access to expected users.
Future<void> resetMockDb() async {
  _mockDb.clear();
  _tokens.clear();
  // Reset the SQLite singleton to prevent deadlocks between tests
  await DatabaseHelper().close();

  // Seed default admin account
  _mockDb['admin@example.com'] = {
    'id': 'admin-1',
    'email': 'admin@example.com',
    'firstName': 'Admin',
    'lastName': 'User',
    'role': 'admin',
  };
  _tokens['mock-token-admin'] = 'admin@example.com';
  // Seed default user account
  _mockDb['user@example.com'] = {
    'id': 'user-1',
    'email': 'user@example.com',
    'firstName': 'Regular',
    'lastName': 'User',
    'role': 'user',
  };
  _tokens['mock-token-user'] = 'user@example.com';
}

// ---------------------------------------------------------------------------
// Pump helpers
// ---------------------------------------------------------------------------

/// Resizes the test surface to a larger height to ensure all form fields and
/// buttons are within the hit-test area. Default is 800x600.
void setLargeDisplay(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1500);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

/// Pumps the widget tree up to [maxFrames] times (100 ms each), stopping as
/// soon as no more frames are scheduled. This avoids the infinite-wait
/// behaviour of [WidgetTester.pumpAndSettle] on screens with persistent
/// animations or image-loading placeholders.
///
/// IMPORTANT: Never call `Future.delayed` inside pump helpers — in widget
/// tests the clock is **fake** and `Future.delayed` will never fire unless
/// `tester.pump(duration)` advances it first, causing a deadlock.
Future<void> safePump(WidgetTester tester, {int maxFrames = 20}) async {
  // At least 2 pumps so microtasks, FutureBuilder, and route transitions
  // have time to register and start scheduling frames.
  for (var i = 0; i < maxFrames; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (!tester.binding.hasScheduledFrame) break;
  }
}

/// Pumps in 100 ms steps for the full [duration], then runs [safePump] to
/// drain any remaining scheduled frames.
/// Use this after actions that trigger network calls, routing, and state rebuilds.
Future<void> pumpFor(WidgetTester tester, Duration duration) async {
  final steps = (duration.inMilliseconds / 100).ceil();
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await safePump(tester);
}

// ---------------------------------------------------------------------------
// Finders
// ---------------------------------------------------------------------------

/// Finds the PurePulse landing-screen title.
/// The title is a [RichText] with two [TextSpan]s ("Pure" and "Pulse"), so
/// [find.text('PurePulse')] will not match it. This predicate checks the
/// plain-text representation instead.
Finder get landingScreenFinder => find.byWidgetPredicate(
  (w) => w is RichText && w.text.toPlainText().contains('PurePulse'),
);

// ---------------------------------------------------------------------------
// Navigation helpers
// ---------------------------------------------------------------------------

/// Taps the "Get Started" button on the landing screen and pumps.
Future<void> goToSignIn(WidgetTester tester) async {
  final btn = find.widgetWithText(CustomButton, 'Get Started');
  await tester.ensureVisible(btn);
  await tester.tap(btn);
  await safePump(tester);
}

/// Enters [email] and [password] in the sign-in form and submits it.
/// Uses [TextFormField] because [CustomTextField] wraps TextFormField, not
/// a plain TextField. Waits for the auth response and router
/// redirect to complete.
Future<void> signIn(WidgetTester tester, String email, String password) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), password);
  final btn = find.widgetWithText(CustomButton, 'Sign In');
  await tester.ensureVisible(btn);
  await tester.tap(btn);
  await safePump(tester);
}

/// Finds the "Sign Up" link on the Sign In screen.
/// The link is rendered as a [RichText] inside a [GestureDetector], so
/// [find.text('Sign Up')] will not match it.
Finder get signUpLinkFinder => find.byWidgetPredicate(
  (w) => w is RichText && w.text.toPlainText().contains('Sign Up'),
);

// ---------------------------------------------------------------------------
// Mock HTTP client
// ---------------------------------------------------------------------------

/// Builds a [MockClient] that intercepts every API route used by the app and
/// returns realistic JSON payloads. Call this once per test.
MockClient buildMockClient() {
  resetMockDb();
  return MockClient((request) async {
    final path = request.url.path;
    final method = request.method;

    // --- Auth ---
    if (path.endsWith('/auth/signin')) {
      final body = json.decode(request.body) as Map<String, dynamic>;
      final email = body['email'] as String;

      if (_mockDb.containsKey(email)) {
        final user = _mockDb[email]!;
        final token = 'mock-token-${user['id']}';
        _tokens[token] = email;
        return http.Response(json.encode({'token': token, 'user': user}), 200);
      }
      return http.Response(json.encode({'error': 'Invalid credentials'}), 401);
    }

    if (path.endsWith('/auth/signup')) {
      final body = json.decode(request.body) as Map<String, dynamic>;
      final email = body['email'] as String;
      final role = body['role'] as String? ?? 'user';

      final newUser = {
        'id': 'user-${DateTime.now().millisecondsSinceEpoch}',
        'email': email,
        'firstName': body['firstName'] ?? 'New',
        'lastName': body['lastName'] ?? 'User',
        'role': role,
      };

      _mockDb[email] = newUser;

      final token = 'mock-token-${newUser['id']}';
      _tokens[token] = email;

      return http.Response(json.encode({'token': token, 'user': newUser}), 200);
    }

    if (path.endsWith('/auth/me')) {
      final authHeader = request.headers['Authorization'] ?? '';

      final token = authHeader.replaceFirst('Bearer ', '');
      final email = _tokens[token];

      if (email == null) return http.Response('Unauthorized', 401);
      final user = _mockDb[email]!;

      return http.Response(json.encode(user), 200);
    }

    // --- Onboarding ---
    if (path.endsWith('/user/onboard')) {
      return http.Response(
        json.encode({
          'id': 'user-1',
          'email': 'john@example.com',
          'firstName': 'John',
          'lastName': 'Doe',
          'role': 'user',
        }),
        200,
      );
    }

    // --- Categories ---
    if (path.endsWith('/categories')) {
      return http.Response(
        json.encode([
          {'id': 'c1', 'name': 'Chest', 'type': 'exercise'},
          {'id': 'c2', 'name': 'Supplements', 'type': 'product'},
        ]),
        200,
      );
    }

    // --- Products ---
    if (path.endsWith('/products')) {
      if (method == 'GET') {
        return http.Response(
          json.encode([
            {
              'id': 'p1',
              'title': 'Protein Powder',
              'description': 'Whey Protein',
              'category': 'Supplements',
              'image': 'protein.png',
            },
          ]),
          200,
        );
      } else if (method == 'POST') {
        return http.Response(
          json.encode({
            'id': 'p_new',
            'title': 'Creatine',
            'description': 'Pure creatine monohydrate',
            'category': 'Supplements',
            'image': 'protein.png',
          }),
          200,
        );
      }
    }
    if (path.contains('/products/')) {
      if (method == 'PUT') {
        return http.Response(
          json.encode({
            'id': 'p1',
            'title': 'Updated Product',
            'description': 'Whey Protein',
            'category': 'Supplements',
            'image': 'protein.png',
          }),
          200,
        );
      } else if (method == 'DELETE') {
        return http.Response('{}', 200);
      }
    }

    // --- Exercises ---
    if (path.endsWith('/exercises')) {
      if (method == 'GET') {
        return http.Response(
          json.encode([
            {
              'id': 'e1',
              'title': 'Push Up',
              'description': 'Chest exercise',
              'category': 'Chest',
              'image': 'pushup.png',
              'duration': '15 min',
              'warmup': 'Arm circles',
              'main_workout': '3 sets of 15 pushups',
              'rest': '60 seconds',
            },
          ]),
          200,
        );
      } else if (method == 'POST') {
        return http.Response(
          json.encode({
            'id': 'e_new',
            'title': 'Power Lifting',
            'description': 'Chest building workout',
            'category': 'Chest',
            'image': 'pushup.png',
            'duration': '60 min',
            'warmup': 'Stretches',
            'main_workout': 'Heavy bench press',
            'rest': '2 min',
          }),
          200,
        );
      }
    }
    if (path.contains('/exercises/')) {
      if (method == 'PUT') {
        return http.Response(
          json.encode({
            'id': 'e1',
            'title': 'Updated Exercise',
            'description': 'Chest exercise',
            'category': 'Chest',
            'image': 'pushup.png',
          }),
          200,
        );
      } else if (method == 'DELETE') {
        return http.Response('{}', 200);
      }
    }

    // --- Announcements ---
    if (path.endsWith('/announcements')) {
      if (method == 'GET') {
        return http.Response(
          json.encode([
            {
              'id': 'a1',
              'title': 'Gym Closed',
              'description': 'Closed on Monday',
              'date': '2026-05-31',
            },
          ]),
          200,
        );
      } else if (method == 'POST') {
        return http.Response(
          json.encode({
            'id': 'a_new',
            'title': 'Gym Closed',
            'description': 'For renovations',
            'date': '2026-05-31',
          }),
          200,
        );
      }
    }
    if (path.contains('/announcements/')) {
      if (method == 'PUT') {
        return http.Response(
          json.encode({
            'id': 'a1',
            'title': 'Updated Announcement',
            'description': 'Closed on Monday',
            'date': '2026-05-31',
          }),
          200,
        );
      } else if (method == 'DELETE') {
        return http.Response('{}', 200);
      }
    }

    // --- Health ---
    if (path.endsWith('/health')) {
      if (method == 'GET') {
        return http.Response(
          json.encode({
            'entries': [
              {
                'id': 'h1',
                'systolic': 120.0,
                'diastolic': 80.0,
                'restingHeartRate': 70.0,
                'bloodSugar': 90.0,
                'weight': 70.0,
                'height': 1.75,
                'bmi': 22.8,
                'measurementDate': '2026-05-31',
              },
            ],
          }),
          200,
        );
      } else if (method == 'POST') {
        return http.Response(
          json.encode({
            'id': 'h_new',
            'systolic': 120.0,
            'diastolic': 80.0,
            'restingHeartRate': 70.0,
            'bloodSugar': 90.0,
            'weight': 70.0,
            'height': 1.75,
            'bmi': 22.8,
            'measurementDate': '2026-05-31',
          }),
          200,
        );
      }
    }
    if (path.endsWith('/health/latest')) {
      return http.Response(
        json.encode({
          'id': 'h1',
          'systolic': 120.0,
          'diastolic': 80.0,
          'restingHeartRate': 70.0,
          'bloodSugar': 90.0,
          'weight': 70.0,
          'height': 1.75,
          'bmi': 22.8,
          'measurementDate': '2026-05-31',
        }),
        200,
      );
    }

    // --- Progress / Workout entries ---
    if (path.endsWith('/progress')) {
      if (method == 'GET') {
        return http.Response(
          json.encode({
            'entries': [
              {
                'id': 'w1',
                'exerciseName': 'Bench Press',
                'entryDate': '2026-05-31',
                'durationMinutes': 45,
                'sets': 4,
                'reps': 10,
                'weight': 80.0,
                'intensity': 'Intense',
                'calories': 300,
                'achievement': 'PR',
                'notes': 'Good',
              },
            ],
          }),
          200,
        );
      } else if (method == 'POST') {
        return http.Response(
          json.encode({
            'id': 'w_new',
            'exerciseName': 'Bench Press',
            'entryDate': '2026-05-31',
            'durationMinutes': 45,
            'sets': 4,
            'reps': 10,
            'weight': 80.0,
            'intensity': 'Intense',
            'calories': 300,
            'achievement': 'PR',
            'notes': 'Good',
          }),
          200,
        );
      }
    }
    if (path.contains('/progress/')) {
      if (method == 'PUT') {
        return http.Response(
          json.encode({
            'id': 'w1',
            'exerciseName': 'Bench Press Updated',
            'entryDate': '2026-05-31',
            'durationMinutes': 50,
            'sets': 4,
            'reps': 10,
            'weight': 80.0,
            'intensity': 'Intense',
            'calories': 300,
            'achievement': 'PR',
            'notes': 'Good',
          }),
          200,
        );
      } else if (method == 'DELETE') {
        return http.Response('{}', 200);
      }
    }

    // --- Progress stats ---
    if (path.endsWith('/progress/stats')) {
      return http.Response(
        json.encode({
          'totalEntries': 1,
          'totalMinutes': 45,
          'exercisesUsed': 1,
        }),
        200,
      );
    }

    // --- Admin Dashboard ---
    if (path.endsWith('/admin/dashboard')) {
      return http.Response(
        json.encode({
          'totalProducts': 1,
          'totalActivities': 1,
          'announcementsCount': 1,
          'avgBmi': 22.8,
          'avgHr': 70.0,
          'categoryDistribution': {'Chest': 1.0},
          'productDistribution': {'Supplements': 1.0},
          'engagementData': [1.0, 2.0, 3.0],
          'recentActivities': [
            {'title': 'Workout Logged', 'subtitle': 'Bench Press - 45 min'},
          ],
        }),
        200,
      );
    }

    // --- Image uploads ---
    if (path.endsWith('/uploads')) {
      return http.Response(
        json.encode({'imageUrl': 'http://localhost/uploads/img.png'}),
        200,
      );
    }

    return http.Response('Not Found', 404);
  });
}
