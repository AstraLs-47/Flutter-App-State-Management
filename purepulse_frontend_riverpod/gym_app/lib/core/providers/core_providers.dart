// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import '../data/database_helper.dart';
import '../data/token_storage.dart';
import '../network/api_client.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/products/data/product_repository.dart';
import '../../features/exercises/data/exercise_repository.dart';
import '../../features/announcement/data/announcement_repository.dart';
import '../../features/progress/data/health_repository.dart';
import '../../features/workout/data/progress_repository.dart';

// Infrastructure Providers
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
final databaseHelperProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper());

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(tokenStorage: tokenStorage);
});

// Repository Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final dbHelper = ref.watch(databaseHelperProvider);
  return AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage, dbHelper: dbHelper);
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final dbHelper = ref.watch(databaseHelperProvider);
  return ProductRepository(apiClient: apiClient, dbHelper: dbHelper);
});

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final dbHelper = ref.watch(databaseHelperProvider);
  return ExerciseRepository(apiClient: apiClient, dbHelper: dbHelper);
});

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final dbHelper = ref.watch(databaseHelperProvider);
  return AnnouncementRepository(apiClient: apiClient, dbHelper: dbHelper);
});

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final dbHelper = ref.watch(databaseHelperProvider);
  return HealthRepository(apiClient: apiClient, dbHelper: dbHelper);
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final dbHelper = ref.watch(databaseHelperProvider);
  return ProgressRepository(apiClient: apiClient, dbHelper: dbHelper);
});
