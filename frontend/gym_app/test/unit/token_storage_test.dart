import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/data/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // SharedPreferences.setMockInitialValues({}) provides a clean in-memory
  // store for each test without touching real device storage.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TokenStorage', () {
    late TokenStorage storage;

    setUp(() {
      storage = TokenStorage();
    });

    test('saveToken() and getToken() round-trip returns the saved token',
        () async {
      await storage.saveToken('my-secure-token-123');
      final result = await storage.getToken();
      expect(result, 'my-secure-token-123');
    });

    test('getToken() returns null when no token has been saved', () async {
      final result = await storage.getToken();
      expect(result, isNull);
    });

    test('clearToken() removes the token', () async {
      await storage.saveToken('token-to-clear');
      await storage.clearToken();
      final result = await storage.getToken();
      expect(result, isNull);
    });

    test('saveUserSession() and getUserSession() round-trip with a sample user',
        () async {
      final userMap = {
        'id': 'user-1',
        'email': 'jane@example.com',
        'firstName': 'Jane',
        'lastName': 'Doe',
        'role': 'user',
      };
      await storage.saveUserSession(userMap);
      final result = await storage.getUserSession();
      expect(result, isNotNull);
      expect(result!['id'], 'user-1');
      expect(result['email'], 'jane@example.com');
      expect(result['firstName'], 'Jane');
      expect(result['role'], 'user');
    });

    test('getUserSession() returns null when no session has been saved',
        () async {
      final result = await storage.getUserSession();
      expect(result, isNull);
    });

    test('clearAll() removes both token and user session', () async {
      await storage.saveToken('tok-abc');
      await storage.saveUserSession({'id': 'u1', 'email': 'a@b.com'});

      await storage.clearAll();

      expect(await storage.getToken(), isNull);
      expect(await storage.getUserSession(), isNull);
    });

    test('clearToken() does not affect user session', () async {
      await storage.saveToken('tok-abc');
      await storage.saveUserSession({'id': 'u1', 'email': 'a@b.com'});
      await storage.clearToken();

      expect(await storage.getToken(), isNull);
      final session = await storage.getUserSession();
      expect(session, isNotNull);
      expect(session!['id'], 'u1');
    });

    test('overwriting a token via saveToken() replaces the previous value',
        () async {
      await storage.saveToken('first-token');
      await storage.saveToken('second-token');
      final result = await storage.getToken();
      expect(result, 'second-token');
    });
  });
}
