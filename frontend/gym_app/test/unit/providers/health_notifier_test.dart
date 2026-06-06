import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/providers/core_providers.dart';
import 'package:gym_app/features/progress/application/get_health_records_use_case.dart';
import 'package:gym_app/features/progress/application/add_health_record_use_case.dart';
import 'package:gym_app/features/progress/data/models/health_record_model.dart';
import 'package:gym_app/features/progress/presentation/providers/health_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockGetHealthRecordsUseCase extends Mock implements GetHealthRecordsUseCase {}
class MockAddHealthRecordUseCase extends Mock implements AddHealthRecordUseCase {}

void main() {
  late MockGetHealthRecordsUseCase mockGetHealthRecordsUseCase;
  late MockAddHealthRecordUseCase mockAddHealthRecordUseCase;

  final testRecord = HealthRecord(
    id: 'h1',
    systolic: 120.0,
    diastolic: 80.0,
    heartRate: 70.0,
    bloodSugar: 90.0,
    weight: 70.0,
    height: 1.75,
    bmi: 22.8,
    date: DateTime.parse('2026-05-31T00:00:00Z'),
  );

  setUpAll(() {
    registerFallbackValue(HealthRecord(
      id: '',
      systolic: 0.0,
      diastolic: 0.0,
      heartRate: 0.0,
      bloodSugar: 0.0,
      weight: 0.0,
      height: 0.0,
      bmi: 0.0,
      date: DateTime.now(),
    ));
  });

  setUp(() {
    mockGetHealthRecordsUseCase = MockGetHealthRecordsUseCase();
    mockAddHealthRecordUseCase = MockAddHealthRecordUseCase();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        getHealthRecordsUseCaseProvider.overrideWithValue(mockGetHealthRecordsUseCase),
        addHealthRecordUseCaseProvider.overrideWithValue(mockAddHealthRecordUseCase),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('HealthNotifier', () {
    test('initial state loads health records', () async {
      when(() => mockGetHealthRecordsUseCase.call(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => [testRecord]);

      final container = makeContainer();
      final state = await container.read(healthRecordsProvider.future);

      expect(state, [testRecord]);
      verify(() => mockGetHealthRecordsUseCase.call(forceRefresh: false)).called(1);
    });

    test('addHealthRecord calls use case and updates state', () async {
      when(() => mockGetHealthRecordsUseCase.call(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => []);
      when(() => mockAddHealthRecordUseCase.call(any()))
          .thenAnswer((_) async => testRecord);

      final container = makeContainer();
      await container.read(healthRecordsProvider.future);

      final notifier = container.read(healthRecordsProvider.notifier);
      await notifier.addHealthRecord(testRecord);

      final state = container.read(healthRecordsProvider);
      expect(state.value, [testRecord]);
      verify(() => mockAddHealthRecordUseCase.call(testRecord)).called(1);
    });

    test('latestHealthRecordProvider returns the first record or null', () async {
      when(() => mockGetHealthRecordsUseCase.call(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => [testRecord]);

      final container = makeContainer();
      await container.read(healthRecordsProvider.future);

      final latest = container.read(latestHealthRecordProvider);
      expect(latest, testRecord);
    });
  });
}
