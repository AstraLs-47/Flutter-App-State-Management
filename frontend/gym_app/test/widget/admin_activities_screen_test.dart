import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_app/features/admin/presentation/screens/admin_activities_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

GoRouter _testRouter() => GoRouter(
  initialLocation: '/admin/activities',
  routes: [
    GoRoute(
      path: '/admin/activities',
      builder: (_, _) => const AdminActivitiesScreen(),
    ),
  ],
);

Widget _wrap() => MaterialApp.router(routerConfig: _testRouter());

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AdminActivitiesScreen Widget', () {
    testWidgets('renders activity management headers', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.text('MANAGE'), findsOneWidget);
      expect(find.text('Activities'), findsNWidgets(2));
    });

    testWidgets('renders categories and add icons', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byIcon(Icons.local_offer), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows loading state initially', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
