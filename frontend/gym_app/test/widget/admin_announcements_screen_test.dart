import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_app/features/admin/presentation/screens/admin_announcements_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

GoRouter _testRouter() => GoRouter(
  initialLocation: '/admin/announcements',
  routes: [
    GoRoute(
      path: '/admin/announcements',
      builder: (_, _) => const AdminAnnouncementsScreen(),
    ),
  ],
);

Widget _wrap() => MaterialApp.router(routerConfig: _testRouter());

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AdminAnnouncementsScreen Widget', () {
    testWidgets('renders announcement management headers', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      // Look for the "Manage" and "Announcements" text
      expect(find.text('Manage'), findsOneWidget);
      expect(find.text('Announcements'), findsOneWidget);
    });

    testWidgets('renders add button icon', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows loading state initially', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
