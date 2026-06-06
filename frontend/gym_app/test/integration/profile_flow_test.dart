// Integration test: Profile flow
//
// Flow: sign in → navigate to profile tab → verify name/email shown → tap sign out
//       → verify redirected to sign-in screen.
//
// Uses MockAuthRepository so no real HTTP calls are made.

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
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------
class MockAuthRepository extends Mock implements IAuthRepository {}

// ---------------------------------------------------------------------------
// Test app — minimal shell that mirrors the sign-in → profile tab flow
// ---------------------------------------------------------------------------

/// A minimal sign-in form widget that drives the auth flow through
/// AuthNotifier (same as the real app).
class _SignInForm extends ConsumerStatefulWidget {
  const _SignInForm();

  @override
  ConsumerState<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<_SignInForm> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(key: const Key('email'), controller: _emailCtrl),
        TextField(
          key: const Key('password'),
          controller: _passCtrl,
          obscureText: true,
        ),
        ElevatedButton(
          key: const Key('signInBtn'),
          onPressed: () async {
            final err = await ref
                .read(authProvider.notifier)
                .signIn(_emailCtrl.text, _passCtrl.text);
            if (err == null && context.mounted) {
              context.goNamed('profile');
            }
          },
          child: const Text('Sign In'),
        ),
      ],
    ),
  );
}

/// A minimal profile page that shows name/email from AuthService statics
/// and a sign-out button.
class _ProfilePage extends ConsumerWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(AuthService.currentUserName, key: const Key('profileName')),
        Text(AuthService.currentUserEmail, key: const Key('profileEmail')),
        ElevatedButton(
          key: const Key('signOutBtn'),
          onPressed: () async {
            await ref.read(authProvider.notifier).signOut();
            if (context.mounted) {
              context.goNamed('signIn');
            }
          },
          child: const Text('Sign Out'),
        ),
      ],
    ),
  );
}

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/sign-in',
  routes: [
    GoRoute(
      path: '/sign-in',
      name: 'signIn',
      builder: (_, _) => const _SignInForm(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (_, _) => const _ProfilePage(),
    ),
  ],
);

Widget _buildApp(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp.router(routerConfig: _buildRouter()),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late MockAuthRepository mockAuthRepo;

  final testUser = User(id: '1', name: 'Jane Doe', email: 'jane@example.com');

  setUpAll(() {
    registerFallbackValue(UserRole.invalid);
  });

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    when(() => mockAuthRepo.isLoggedIn()).thenAnswer((_) async => false);
    when(() => mockAuthRepo.signOut()).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('Profile flow integration', () {
    testWidgets(
      'sign in → navigate to profile → name and email are displayed',
      (tester) async {
        when(
          () => mockAuthRepo.signIn(any(), any()),
        ).thenAnswer((_) async => UserRole.user);
        when(
          () => mockAuthRepo.getCurrentUser(),
        ).thenAnswer((_) async => testUser);
        when(
          () => mockAuthRepo.getStoredRole(),
        ).thenAnswer((_) async => UserRole.user);

        // Set static fields so the profile page can display them.
        AuthService.currentUserName = testUser.name;
        AuthService.currentUserEmail = testUser.email;

        final container = makeContainer();
        await tester.pumpWidget(_buildApp(container));
        await tester.pumpAndSettle();

        // Enter credentials and sign in.
        await tester.enterText(find.byKey(const Key('email')), testUser.email);
        await tester.enterText(
          find.byKey(const Key('password')),
          'password123',
        );
        await tester.tap(find.byKey(const Key('signInBtn')));
        await tester.pumpAndSettle();

        // Should now be on the profile page with name and email visible.
        expect(find.text('Jane Doe'), findsOneWidget);
        expect(find.text('jane@example.com'), findsOneWidget);
      },
    );

    testWidgets(
      'sign in → navigate to profile → tap sign out → redirected to sign-in',
      (tester) async {
        when(
          () => mockAuthRepo.signIn(any(), any()),
        ).thenAnswer((_) async => UserRole.user);
        when(
          () => mockAuthRepo.getCurrentUser(),
        ).thenAnswer((_) async => testUser);
        when(
          () => mockAuthRepo.getStoredRole(),
        ).thenAnswer((_) async => UserRole.user);

        AuthService.currentUserName = testUser.name;
        AuthService.currentUserEmail = testUser.email;

        final container = makeContainer();
        await tester.pumpWidget(_buildApp(container));
        await tester.pumpAndSettle();

        // Sign in.
        await tester.enterText(find.byKey(const Key('email')), testUser.email);
        await tester.enterText(
          find.byKey(const Key('password')),
          'password123',
        );
        await tester.tap(find.byKey(const Key('signInBtn')));
        await tester.pumpAndSettle();

        // Tap sign out.
        await tester.tap(find.byKey(const Key('signOutBtn')));
        await tester.pumpAndSettle();

        // Should be redirected back to sign-in.
        expect(find.text('Sign In'), findsOneWidget);
        expect(find.text('Jane Doe'), findsNothing);
      },
    );
  });
}
