import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gym_app/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite FFI for integration tests on desktop/CI environments
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('End-to-End App Onboarding and Authentication Flow', (
    tester,
  ) async {
    // 1. Launch the app
    await tester.pumpWidget(const ProviderScope(child: app.MyApp()));
    await tester.pumpAndSettle();

    // Verify we land on the landing/onboarding start screen
    expect(find.text('PurePulse'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    // 2. Tap Get Started to go to Sign In screen
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Verify Sign In screen renders
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
