import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/data/database_helper.dart';
import 'package:gym_app/features/progress/data/health_repository.dart';
import 'package:gym_app/features/progress/data/models/health_record_model.dart';
import 'package:gym_app/core/network/api_client.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  late MockApiClient mockApiClient;
  late MockDatabaseHelper mockDbHelper;
  late HealthRepository repository;

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

  final testDbRow = {
    'id': 'h1',
    'blood_pressure_systolic': 120,
    'blood_pressure_diastolic': 80,
    'resting_heart_rate': 70,
    'blood_sugar': 90.0,
    'weight': 70.0,
    'height': 1.75,
    'bmi': 22.8,
    'date': '2026-05-31T00:00:00.000Z',
  };

  setUp(() {
    mockApiClient = MockApiClient();
    mockDbHelper = MockDatabaseHelper();
    repository = HealthRepository(
      apiClient: mockApiClient,
      dbHelper: mockDbHelper,
    );
  });

  group('HealthRepository', () {
    test('should return cached data and NOT call API on cache hit', () async {
      when(
        () => mockDbHelper.queryAll('health_metrics'),
      ).thenAnswer((_) async => [testDbRow]);

      final result = await repository.getHealthRecords(forceRefresh: false);

      expect(result, hasLength(1));
      expect(result.first.id, 'h1');
      verify(() => mockDbHelper.queryAll('health_metrics')).called(1);
      verifyNever(() => mockApiClient.get(any()));
    });

    test(
      'should fetch from API, clear cache, and insertAll on cache miss',
      () async {
        when(
          () => mockDbHelper.queryAll('health_metrics'),
        ).thenAnswer((_) async => []);
        when(() => mockApiClient.get(any())).thenAnswer(
          (_) async => {
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
                'date': '2026-05-31T00:00:00Z',
              },
            ],
          },
        );
        when(
          () => mockDbHelper.clearTable('health_metrics'),
        ).thenAnswer((_) async {});
        when(
          () => mockDbHelper.insertAll('health_metrics', any()),
        ).thenAnswer((_) async {});

        final result = await repository.getHealthRecords(forceRefresh: false);

        expect(result, hasLength(1));
        expect(result.first.id, 'h1');
        verify(() => mockDbHelper.queryAll('health_metrics')).called(1);
        verify(() => mockApiClient.get(any())).called(1);
        verify(() => mockDbHelper.clearTable('health_metrics')).called(1);
        verify(() => mockDbHelper.insertAll('health_metrics', any())).called(1);
      },
    );

    test(
      'should fetch from API, clear cache, and insertAll on force refresh even if cache has data',
      () async {
        when(() => mockApiClient.get(any())).thenAnswer(
          (_) async => {
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
                'date': '2026-05-31T00:00:00Z',
              },
            ],
          },
        );
        when(
          () => mockDbHelper.clearTable('health_metrics'),
        ).thenAnswer((_) async {});
        when(
          () => mockDbHelper.insertAll('health_metrics', any()),
        ).thenAnswer((_) async {});

        final result = await repository.getHealthRecords(forceRefresh: true);

        expect(result, hasLength(1));
        expect(result.first.id, 'h1');
        verifyNever(() => mockDbHelper.queryAll('health_metrics'));
        verify(() => mockApiClient.get(any())).called(1);
        verify(() => mockDbHelper.clearTable('health_metrics')).called(1);
        verify(() => mockDbHelper.insertAll('health_metrics', any())).called(1);
      },
    );

    test(
      'should return cached data on force refresh when API throws but cache exists',
      () async {
        final testRow = {
          'id': 'h1',
          'blood_pressure_systolic': 120,
          'blood_pressure_diastolic': 80,
          'resting_heart_rate': 70,
          'blood_sugar': 100,
          'weight': 70.0,
          'height': 1.75,
          'bmi': 21.6,
          'date': '2026-05-31T00:00:00Z',
        };
        when(
          () => mockDbHelper.queryAll('health_metrics'),
        ).thenAnswer((_) async => [testRow]);
        when(() => mockApiClient.get(any())).thenThrow(Exception('API error'));

        final result = await repository.getHealthRecords(forceRefresh: true);

        expect(result, hasLength(1));
        expect(result.first.id, 'h1');
        verify(() => mockApiClient.get(any())).called(1);
        verify(() => mockDbHelper.queryAll('health_metrics')).called(1);
      },
    );

    test('should throw exception on force refresh when API throws', () async {
      when(
        () => mockDbHelper.queryAll('health_metrics'),
      ).thenAnswer((_) async => []);
      when(() => mockApiClient.get(any())).thenThrow(Exception('API error'));

      expect(
        () => repository.getHealthRecords(forceRefresh: true),
        throwsException,
      );
      verify(() => mockApiClient.get(any())).called(1);
      verify(() => mockDbHelper.queryAll('health_metrics')).called(1);
    });

    test(
      'should get latest metrics from API on success and update cache',
      () async {
        when(() => mockApiClient.get(any())).thenAnswer(
          (_) async => {
            'id': 'h1',
            'systolic': 120.0,
            'diastolic': 80.0,
            'restingHeartRate': 70.0,
            'bloodSugar': 90.0,
            'weight': 70.0,
            'height': 1.75,
            'bmi': 22.8,
            'date': '2026-05-31T00:00:00Z',
          },
        );
        when(
          () => mockDbHelper.insert('health_metrics', any()),
        ).thenAnswer((_) async {});

        final result = await repository.getLatestMetrics();

        expect(result, isNotNull);
        expect(result!.id, 'h1');
        verify(() => mockApiClient.get(any())).called(1);
        verify(() => mockDbHelper.insert('health_metrics', any())).called(1);
      },
    );

    test(
      'should return latest cache health metric when API latest throws',
      () async {
        when(() => mockApiClient.get(any())).thenThrow(Exception('API error'));
        when(
          () => mockDbHelper.queryAll('health_metrics'),
        ).thenAnswer((_) async => [testDbRow]);

        final result = await repository.getLatestMetrics();

        expect(result, isNotNull);
        expect(result!.id, 'h1');
        verify(() => mockDbHelper.queryAll('health_metrics')).called(1);
      },
    );

    test(
      'should add health record, insert into database, and return new record',
      () async {
        when(
          () => mockApiClient.post(any(), body: any(named: 'body')),
        ).thenAnswer(
          (_) async => {
            'id': 'h_new',
            'systolic': 120.0,
            'diastolic': 80.0,
            'restingHeartRate': 70.0,
            'bloodSugar': 90.0,
            'weight': 70.0,
            'height': 1.75,
            'bmi': 22.8,
            'date': '2026-05-31T00:00:00Z',
          },
        );
        when(
          () => mockDbHelper.insert('health_metrics', any()),
        ).thenAnswer((_) async {});

        final result = await repository.addHealthRecord(testRecord);

        expect(result.id, 'h_new');
        verify(
          () => mockApiClient.post(any(), body: any(named: 'body')),
        ).called(1);
        verify(() => mockDbHelper.insert('health_metrics', any())).called(1);
      },
    );
  });
}
