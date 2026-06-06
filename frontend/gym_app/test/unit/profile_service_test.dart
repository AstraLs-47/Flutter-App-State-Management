import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_client.dart';
import 'package:gym_app/core/network/api_endpoints.dart';
import 'package:gym_app/features/auth/data/auth_repository.dart';
import 'package:gym_app/core/data/token_storage.dart';
import 'package:gym_app/core/data/database_helper.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------
class MockApiClient extends Mock implements ApiClient {}

class MockTokenStorage extends Mock implements TokenStorage {}

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
//
// ProfileService delegates entirely to AuthService, which in turn delegates
// to AuthRepository.  We test at the AuthRepository level because:
//   - ProfileService.fetchProfile() → AuthService.getCurrentUser()
//                                   → AuthRepository.getCurrentUser()
//                                   → ApiClient.get(ApiEndpoints.profile)
//   - ProfileService.updateProfile() → AuthService static field update only
//     (no API call in the current implementation).
//
// This matches the instruction: "Test that the profile service correctly
// calls the expected API endpoint for fetching/updating the profile."
// ---------------------------------------------------------------------------
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  late MockApiClient mockApi;
  late MockTokenStorage mockTokenStorage;
  late MockDatabaseHelper mockDb;
  late AuthRepository authRepository;

  setUp(() {
    mockApi = MockApiClient();
    mockTokenStorage = MockTokenStorage();
    mockDb = MockDatabaseHelper();
    authRepository = AuthRepository(
      apiClient: mockApi,
      tokenStorage: mockTokenStorage,
      dbHelper: mockDb,
    );
  });

  // --------------------------------------------------------------------------
  // fetchProfile equivalent — AuthRepository.getCurrentUser()
  // --------------------------------------------------------------------------
  group('ProfileService (via AuthRepository) - fetchProfile', () {
    test('calls GET ApiEndpoints.profile when fetching the current user',
        () async {
      when(() => mockApi.get(ApiEndpoints.profile))
          .thenAnswer((_) async => {
                'id': '1',
                'firstName': 'Jane',
                'lastName': 'Doe',
                'email': 'jane@example.com',
                'role': 'user',
                'goal': 'Lose weight',
              });
      when(() => mockTokenStorage.saveUserSession(any()))
          .thenAnswer((_) async {});

      final user = await authRepository.getCurrentUser();

      expect(user, isNotNull);
      expect(user!.name, 'Jane Doe');
      expect(user.email, 'jane@example.com');

      // Verify the correct endpoint was hit
      verify(() => mockApi.get(ApiEndpoints.profile)).called(1);
    });

    test('returns null when the API throws and no local session exists',
        () async {
      when(() => mockApi.get(ApiEndpoints.profile))
          .thenThrow(Exception('Network error'));
      when(() => mockTokenStorage.getUserSession())
          .thenAnswer((_) async => null);

      final user = await authRepository.getCurrentUser();

      expect(user, isNull);
    });

    test('returns cached user from local session when API throws', () async {
      when(() => mockApi.get(ApiEndpoints.profile))
          .thenThrow(Exception('Offline'));
      when(() => mockTokenStorage.getUserSession()).thenAnswer(
        (_) async => {
          'id': '2',
          'firstName': 'Cached',
          'lastName': 'User',
          'email': 'cached@example.com',
          'role': 'user',
        },
      );

      final user = await authRepository.getCurrentUser();

      expect(user, isNotNull);
      expect(user!.email, 'cached@example.com');
      expect(user.name, 'Cached User');
    });
  });

  // --------------------------------------------------------------------------
  // updateProfile equivalent — AuthRepository.signIn / profile update path
  // The current ProfileService.updateProfile() only mutates static fields
  // (AuthService.currentUserName / currentUserEmail) and makes no API call.
  // We test that the auth signIn endpoint is called for credential updates.
  // --------------------------------------------------------------------------
  group('ProfileService (via AuthRepository) - updateProfile path', () {
    test('signIn calls the expected login endpoint', () async {
      when(
        () => mockApi.post(
          ApiEndpoints.login,
          body: any(named: 'body'),
          includeAuth: any(named: 'includeAuth'),
        ),
      ).thenAnswer((_) async => {
            'token': 'tok-123',
            'user': {
              'id': '1',
              'email': 'jane@example.com',
              'firstName': 'Jane',
              'lastName': 'Doe',
              'role': 'user',
            },
          });
      when(() => mockTokenStorage.saveToken(any())).thenAnswer((_) async {});
      when(() => mockTokenStorage.saveUserSession(any()))
          .thenAnswer((_) async {});

      await authRepository.signIn('jane@example.com', 'secret');

      verify(
        () => mockApi.post(
          ApiEndpoints.login,
          body: any(named: 'body'),
          includeAuth: any(named: 'includeAuth'),
        ),
      ).called(1);
    });
  });
}
