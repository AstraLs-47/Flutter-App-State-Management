import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/progress/data/health_store.dart';
import 'package:gym_app/features/progress/data/models/health_record_model.dart';
import 'package:gym_app/features/progress/presentation/widgets/health_metrics_tab.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Seeds the HealthStore singleton with [records] so HealthMetricsTab
/// renders them without making real network calls.
void _seedStore(List<HealthRecord> records) {
  HealthStore().setRecords(records);
}

HealthRecord _makeRecord({String id = 'h1'}) => HealthRecord(
      id: id,
      systolic: 120,
      diastolic: 80,
      heartRate: 70,
      bloodSugar: 90,
      weight: 70,
      height: 1.75,
      bmi: 22.8,
      date: DateTime(2026, 5, 31),
    );

Widget _buildApp() => ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: const HealthMetricsTab()),
      ),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  tearDown(() {
    // Clear the singleton store after each test.
    HealthStore().setRecords([]);
  });

  group('HealthMetricsTab widget tests', () {
    testWidgets(
        'displays the BMI toggle button when the widget is rendered',
        (tester) async {
      _seedStore([_makeRecord()]);

      await tester.pumpWidget(_buildApp());
      // Pump enough frames to let initState / _loadHealthRecords complete.
      // Since HealthService makes a real async call that will fail in test,
      // we pump a few frames and then let the finally block mark isLoading=false.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // The metric toggle row is always rendered after loading.
      expect(find.text('BMI'), findsWidgets);
    });

    testWidgets(
        'displays the Heart Rate toggle button',
        (tester) async {
      _seedStore([_makeRecord()]);

      await tester.pumpWidget(_buildApp());
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Heart Rate'), findsWidgets);
    });

    testWidgets(
        'displays at least one health metric card (Blood Pressure)',
        (tester) async {
      _seedStore([_makeRecord()]);

      await tester.pumpWidget(_buildApp());
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Blood Pressure card is always present once a record is loaded.
      expect(find.text('Blood Pressure'), findsOneWidget);
    });

    testWidgets(
        'displays the BMI value from the seeded health record',
        (tester) async {
      _seedStore([_makeRecord()]);

      await tester.pumpWidget(_buildApp());
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // The BMI is 22.8 → shown as "22.8" in the current metric header.
      expect(find.text('22.8'), findsWidgets);
    });

    testWidgets(
        'displays no-data message when the store is empty',
        (tester) async {
      _seedStore([]);

      await tester.pumpWidget(_buildApp());
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(
        find.text(
          'No data recorded yet.\nAdd your health metrics to see progress.',
        ),
        findsOneWidget,
      );
    });
  });
}
