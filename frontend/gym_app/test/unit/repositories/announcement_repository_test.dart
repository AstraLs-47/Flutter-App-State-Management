import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/data/database_helper.dart';
import 'package:gym_app/core/models/announcement_model.dart';
import 'package:gym_app/core/network/api_client.dart';
import 'package:gym_app/features/announcement/data/announcement_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  late MockApiClient mockApiClient;
  late MockDatabaseHelper mockDbHelper;
  late AnnouncementRepository repository;

  final testAnnouncement = Announcement(
    id: 'a1',
    title: 'Hours',
    description: '24/7',
    date: '2026-05-31',
  );

  final testDbRow = {
    'id': 'a1',
    'title': 'Hours',
    'description': '24/7',
    'date': '2026-05-31',
  };

  setUp(() {
    mockApiClient = MockApiClient();
    mockDbHelper = MockDatabaseHelper();
    repository = AnnouncementRepository(
      apiClient: mockApiClient,
      dbHelper: mockDbHelper,
    );
  });

  group('AnnouncementRepository', () {
    test('should return cached data and NOT call API on cache hit', () async {
      when(
        () => mockDbHelper.queryAll('announcements'),
      ).thenAnswer((_) async => [testDbRow]);

      final result = await repository.getAnnouncements(forceRefresh: false);

      expect(result, hasLength(1));
      expect(result.first.id, 'a1');
      verify(() => mockDbHelper.queryAll('announcements')).called(1);
      verifyNever(() => mockApiClient.get(any()));
    });

    test(
      'should fetch from API, clear cache, and insertAll on cache miss',
      () async {
        when(
          () => mockDbHelper.queryAll('announcements'),
        ).thenAnswer((_) async => []);
        when(() => mockApiClient.get(any())).thenAnswer(
          (_) async => [
            {
              'id': 'a1',
              'title': 'Hours',
              'description': '24/7',
              'date': '2026-05-31',
            },
          ],
        );
        when(
          () => mockDbHelper.clearTable('announcements'),
        ).thenAnswer((_) async {});
        when(
          () => mockDbHelper.insertAll('announcements', any()),
        ).thenAnswer((_) async {});

        final result = await repository.getAnnouncements(forceRefresh: false);

        expect(result, hasLength(1));
        expect(result.first.id, 'a1');
        verify(() => mockDbHelper.queryAll('announcements')).called(1);
        verify(() => mockApiClient.get(any())).called(1);
        verify(() => mockDbHelper.clearTable('announcements')).called(1);
        verify(() => mockDbHelper.insertAll('announcements', any())).called(1);
      },
    );

    test(
      'should fetch from API, clear cache, and insertAll on force refresh even if cache has data',
      () async {
        when(() => mockApiClient.get(any())).thenAnswer(
          (_) async => [
            {
              'id': 'a1',
              'title': 'Hours',
              'description': '24/7',
              'date': '2026-05-31',
            },
          ],
        );
        when(
          () => mockDbHelper.clearTable('announcements'),
        ).thenAnswer((_) async {});
        when(
          () => mockDbHelper.insertAll('announcements', any()),
        ).thenAnswer((_) async {});

        final result = await repository.getAnnouncements(forceRefresh: true);

        expect(result, hasLength(1));
        expect(result.first.id, 'a1');
        verifyNever(() => mockDbHelper.queryAll('announcements'));
        verify(() => mockApiClient.get(any())).called(1);
        verify(() => mockDbHelper.clearTable('announcements')).called(1);
        verify(() => mockDbHelper.insertAll('announcements', any())).called(1);
      },
    );

    test(
      'should return cached data on force refresh when API throws but cache exists',
      () async {
        final testRow = {
          'id': 'a1',
          'title': 'Test Announcement',
          'description': 'Test Description',
          'date': '2024-01-01',
        };
        when(
          () => mockDbHelper.queryAll('announcements'),
        ).thenAnswer((_) async => [testRow]);
        when(() => mockApiClient.get(any())).thenThrow(Exception('API error'));

        final result = await repository.getAnnouncements(forceRefresh: true);

        expect(result, hasLength(1));
        expect(result.first.id, 'a1');
        verify(() => mockApiClient.get(any())).called(1);
        verify(() => mockDbHelper.queryAll('announcements')).called(1);
      },
    );

    test('should throw exception on force refresh when API throws', () async {
      when(
        () => mockDbHelper.queryAll('announcements'),
      ).thenAnswer((_) async => []);
      when(() => mockApiClient.get(any())).thenThrow(Exception('API error'));

      expect(
        () => repository.getAnnouncements(forceRefresh: true),
        throwsException,
      );
      verify(() => mockApiClient.get(any())).called(1);
      verify(() => mockDbHelper.queryAll('announcements')).called(1);
    });

    test(
      'should create announcement, insert into database, and return new announcement',
      () async {
        when(
          () => mockApiClient.post(any(), body: any(named: 'body')),
        ).thenAnswer(
          (_) async => {
            'id': 'a_new',
            'title': 'Hours',
            'description': '24/7',
            'date': '2026-05-31',
          },
        );
        when(
          () => mockDbHelper.insert('announcements', any()),
        ).thenAnswer((_) async {});

        final result = await repository.createAnnouncement(testAnnouncement);

        expect(result.id, 'a_new');
        verify(
          () => mockApiClient.post(any(), body: any(named: 'body')),
        ).called(1);
        verify(() => mockDbHelper.insert('announcements', any())).called(1);
      },
    );

    test(
      'should update announcement, update cache, and return updated announcement',
      () async {
        when(
          () => mockApiClient.put(any(), body: any(named: 'body')),
        ).thenAnswer(
          (_) async => {
            'id': 'a1',
            'title': 'Hours Updated',
            'description': '24/7',
            'date': '2026-05-31',
          },
        );
        when(
          () => mockDbHelper.insert('announcements', any()),
        ).thenAnswer((_) async {});

        final result = await repository.updateAnnouncement(testAnnouncement);

        expect(result.title, 'Hours Updated');
        verify(
          () => mockApiClient.put(any(), body: any(named: 'body')),
        ).called(1);
        verify(() => mockDbHelper.insert('announcements', any())).called(1);
      },
    );

    test('should delete announcement from cache and API', () async {
      when(
        () => mockDbHelper.delete('announcements', 'a1'),
      ).thenAnswer((_) async {});
      when(() => mockApiClient.delete(any())).thenAnswer((_) async => {});

      await repository.deleteAnnouncement('a1');

      verify(() => mockDbHelper.delete('announcements', 'a1')).called(1);
      verify(() => mockApiClient.delete(any())).called(1);
    });
  });
}
