/// Remote data source for authentication.
/// Simulates a remote REST API for auth operations.
/// Per project requirements, the API runs locally (no internet hosting).
class AuthRemoteDataSource {
  /// Simulates a remote login API call.
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 300));
    // In a real app, this would make an HTTP POST request to a local REST API.
    // For now, we throw to signal the repository to fall back to local cache.
    throw UnimplementedError(
      'Remote auth API not available – using local SQLite',
    );
  }

  /// Simulates a remote registration API call.
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    throw UnimplementedError(
      'Remote auth API not available – using local SQLite',
    );
  }

  /// Simulates fetching the current user from a remote session endpoint.
  Future<Map<String, dynamic>?> getCurrentUser(String token) async {
    await Future.delayed(const Duration(milliseconds: 300));
    throw UnimplementedError(
      'Remote auth API not available – using local SQLite',
    );
  }
}
