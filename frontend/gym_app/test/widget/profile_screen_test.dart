import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_app/core/domain/repositories/i_auth_repository.dart';
import 'package:gym_app/core/models/user_model.dart';
import 'package:gym_app/core/providers/core_providers.dart';
import 'package:gym_app/features/auth/data/auth_service.dart';
import 'package:gym_app/features/auth/domain/user_role.dart';
import 'package:gym_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:gym_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------
class MockAuthRepository extends Mock implements IAuthRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
GoRouter _router() => GoRouter(
  initialLocation: '/profile',
  routes: [
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (_, _) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/sign-in',
      name: 'signIn',
      builder: (_, _) => const Scaffold(body: Text('Sign In Page')),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (_, _) => const Scaffold(body: Text('Dashboard')),
    ),
    GoRoute(
      path: '/tracking',
      name: 'tracking',
      builder: (_, _) => const Scaffold(body: Text('Tracking')),
    ),
    GoRoute(
      path: '/exercises',
      name: 'exercises',
      builder: (_, _) => const Scaffold(body: Text('Exercises')),
    ),
    GoRoute(
      path: '/products',
      name: 'products',
      builder: (_, _) => const Scaffold(body: Text('Products')),
    ),
  ],
);

Widget _buildApp({
  required MockAuthRepository mockAuthRepo,
  required String userName,
  required String userEmail,
}) {
  // Set up the static fields that ProfileScreen reads directly.
  AuthService.currentUserName = userName;
  AuthService.currentUserEmail = userEmail;

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(mockAuthRepo),
      authProvider.overrideWith(() {
        final notifier = AuthNotifier();
        return notifier;
      }),
    ],
    child: MaterialApp.router(routerConfig: _router()),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late MockAuthRepository mockAuthRepo;

  setUpAll(() {
    registerFallbackValue(UserRole.invalid);
  });

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    when(() => mockAuthRepo.isLoggedIn()).thenAnswer((_) async => true);
    when(() => mockAuthRepo.getCurrentUser()).thenAnswer(
      (_) async => User(id: '1', name: 'Jane Doe', email: 'jane@example.com'),
    );
    when(
      () => mockAuthRepo.getStoredRole(),
    ).thenAnswer((_) async => UserRole.user);
  });

  group('ProfileScreen widget tests', () {
    testWidgets('displays the user name from AuthService static field', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          mockAuthRepo: mockAuthRepo,
          userName: 'Jane Doe',
          userEmail: 'jane@example.com',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Jane Doe'), findsOneWidget);
    });

    testWidgets('displays the user email from AuthService static field', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          mockAuthRepo: mockAuthRepo,
          userName: 'Jane Doe',
          userEmail: 'jane@example.com',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('jane@example.com'), findsOneWidget);
    });

    testWidgets('sign-out button (Logout) is present', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          mockAuthRepo: mockAuthRepo,
          userName: 'Jane Doe',
          userEmail: 'jane@example.com',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // ProfileScreen renders a TextButton.icon with 'Logout' as the icon child text.
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('My Profile heading is displayed', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          mockAuthRepo: mockAuthRepo,
          userName: 'Jane Doe',
          userEmail: 'jane@example.com',
        ),
      );
      await tester.pump();

      expect(find.text('My Profile'), findsOneWidget);
    });

    testWidgets('Contact Information section is displayed', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          mockAuthRepo: mockAuthRepo,
          userName: 'Jane Doe',
          userEmail: 'jane@example.com',
        ),
      );
      await tester.pump();

      expect(find.text('Contact Information'), findsOneWidget);
    });
  });
}
