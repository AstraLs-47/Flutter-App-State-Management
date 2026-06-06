import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_client.dart';
import 'package:gym_app/features/admin/application/get_admin_dashboard_stats_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late GetAdminDashboardStatsUseCase useCase;

  setUp(() {
    mockApiClient = MockApiClient();
    useCase = GetAdminDashboardStatsUseCase(mockApiClient);
  });

  group('GetAdminDashboardStatsUseCase', () {
    test('should return formatted stats map when API call is successful', () async {
      final mockApiResponse = {
        'categoryDistribution': {'Chest': 12, 'Legs': 15},
        'productTypeData': [10.0, 20.0, 30.0, 40.0],
        'engagementData': [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0],
        'extraInfo': 'some-extra-info',
      };

      when(() => mockApiClient.get(any())).thenAnswer((_) async => mockApiResponse);

      final result = await useCase.call();

      expect(result['extraInfo'], 'some-extra-info');
      expect(result['categoryDistribution'], {'Chest': 12.0, 'Legs': 15.0});
      expect(result['productTypeData'], [10.0, 20.0, 30.0, 40.0]);
      expect(result['engagementData'], [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]);
    });

    test('should handle missing or malformed categoryDistribution, productTypeData, and engagementData gracefully', () async {
      final mockApiResponse = {
        'extraInfo': 'missing-fields',
      };

      when(() => mockApiClient.get(any())).thenAnswer((_) async => mockApiResponse);

      final result = await useCase.call();

      expect(result['extraInfo'], 'missing-fields');
      expect(result['categoryDistribution'], <String, double>{});
      expect(result['productTypeData'], <double>[0, 0, 0, 0]);
      expect(result['engagementData'], <double>[0, 0, 0, 0, 0, 0, 0]);
    });

    test('should propagate API exceptions', () async {
      when(() => mockApiClient.get(any())).thenThrow(const ApiException(message: 'Network Error', statusCode: 500));

      expect(() => useCase.call(), throwsA(isA<ApiException>()));
    });
  });
}
