import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_app/features/announcement/presentation/screens/announcements_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

GoRouter _testRouter() => GoRouter(
  initialLocation: '/announcements',
  routes: [
    GoRoute(
      path: '/announcements',
      builder: (_, _) => const AnnouncementsScreen(),
    ),
  ],
);

Widget _wrap() => MaterialApp.router(routerConfig: _testRouter());

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async {
            return '.';
          },
        );
  });

  group('AnnouncementsScreen Widget', () {
    testWidgets('renders error text on load failure', (tester) async {
      // The test HTTP binding returns 400, but the response goes through real
      // async I/O that doesn't advance with pump().  tester.runAsync lets the
      // real Future complete (HttpClient → 400 → ApiException), after which a
      // plain pump() triggers the FutureBuilder rebuild to the error state.
      await tester.runAsync(() async {
        await tester.pumpWidget(_wrap());
        // Give the HTTP future time to resolve in real-async context.
        await Future.delayed(const Duration(milliseconds: 500));
      });
      await tester.pump(); // rebuild with error state

      expect(find.textContaining('Error:'), findsOneWidget);
    });

    testWidgets('shows loading progress indicator initially', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
