// Integration test: User Onboarding & Sign Up Flow
//
// Tests the complete new-user journey:
//   Landing → Sign Up form → Onboarding wizard (goal, activity, info) → Dashboard
//
// All HTTP calls are intercepted by a MockClient so no real backend is needed.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gym_app/core/network/api_client.dart';
import 'package:gym_app/core/providers/core_providers.dart';
import 'package:gym_app/main.dart' as app;
import 'package:gym_app/core/widgets/custom_button.dart';
import 'package:gym_app/core/data/database_helper.dart';

import 'test_helpers.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => '.',
        );
  });

  tearDown(() async {
    await DatabaseHelper().clearAllCaches();
    await DatabaseHelper().close();
    await resetMockDb();
  });

  group('User Onboarding & Sign Up Flow', () {
    testWidgets('new user completes sign-up wizard and lands on the Dashboard', (
      tester,
    ) async {
      final mockClient = buildMockClient();
      setLargeDisplay(tester);
      await http.runWithClient(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              apiClientProvider.overrideWithValue(
                ApiClient(client: mockClient),
              ),
            ],
            child: const app.MyApp(),
          ),
        );
        await safePump(tester);

        // 1. Landing screen – title is a RichText ("Pure" + "Pulse")
        expect(landingScreenFinder, findsWidgets);
        expect(
          find.widgetWithText(CustomButton, 'Get Started'),
          findsOneWidget,
        );

        await tester.tap(find.widgetWithText(CustomButton, 'Get Started'));
        await safePump(tester);

        // 2. Sign In screen → navigate to Sign Up
        expect(find.text('Welcome Back'), findsOneWidget);
        await tester.tap(signUpLinkFinder);
        await safePump(tester);

        // 3. Sign Up screen → fill form and submit
        expect(find.text('Create Account'), findsOneWidget);
        final signUpFields = find.byType(TextFormField);
        await tester.enterText(signUpFields.at(0), 'John Doe');
        await tester.enterText(signUpFields.at(1), 'john@example.com');
        await tester.enterText(signUpFields.at(2), 'Password123');

        // Select User role (default)
        await tester.tap(find.text('User').first);
        await tester.pump();

        final signUpBtn = find.widgetWithText(CustomButton, 'Sign Up');
        await tester.ensureVisible(signUpBtn);
        await tester.tap(signUpBtn);
        await safePump(tester);

        // 4. Onboarding step 1 – Goal selection
        expect(find.text('What is your goal?'), findsOneWidget);
        await tester.tap(find.text('Maintain Weight'));
        await tester.pump();
        await tester.tap(find.text('Next'));
        await safePump(tester);

        // 5. Onboarding step 2 – Activity level
        expect(
          find.text('What is your baseline activity level?'),
          findsOneWidget,
        );
        await tester.tap(find.text('Active'));
        await tester.pump();
        await tester.tap(find.text('Next'));
        await safePump(tester);

        // 6. Onboarding step 3 – Sex & personal info
        // The page header asks about sex calculation
        expect(
          find.text(
            'Please select which sex we should use to calculate your calorie needs.',
          ),
          findsOneWidget,
        );
        // The input fields in this page are plain TextField (inside _InputField widgets)
        final infoFields = find.byType(TextField);
        await tester.enterText(infoFields.at(0), '01/01/2000'); // birth date
        await tester.enterText(infoFields.at(1), '1.75'); // height
        await tester.enterText(infoFields.at(2), '70'); // weight
        await tester.enterText(infoFields.at(3), '70'); // goal weight
        await tester.tap(find.text('Next'));
        await pumpFor(tester, const Duration(seconds: 2));

        // 7. Verify dashboard
        expect(find.text('THE PULSE'), findsOneWidget);
      }, () => mockClient);
    });
  });
}
