import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_app/core/domain/repositories/i_product_repository.dart';
import 'package:gym_app/core/providers/core_providers.dart';
import 'package:gym_app/features/products/presentation/screens/products_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockProductRepository extends Mock implements IProductRepository {}

GoRouter _testRouter() => GoRouter(
  initialLocation: '/shop',
  routes: [
    GoRoute(path: '/shop', builder: (_, _) => const ProductsScreen()),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (_, _) => const Scaffold(body: Text('Home')),
    ),
    GoRoute(
      path: '/tracking',
      name: 'tracking',
      builder: (_, _) => const Scaffold(body: Text('Tracking')),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (_, _) => const Scaffold(body: Text('Profile')),
    ),
    GoRoute(
      path: '/contact',
      name: 'contactUs',
      builder: (_, _) => const Scaffold(body: Text('Contact')),
    ),
  ],
);

Widget _wrap(MockProductRepository mockRepo) => ProviderScope(
  overrides: [productRepositoryProvider.overrideWithValue(mockRepo)],
  child: MaterialApp.router(routerConfig: _testRouter()),
);

void main() {
  late MockProductRepository mockRepo;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    mockRepo = MockProductRepository();
    // Default stub to prevent 'Null' is not a subtype of 'Future' errors
    when(
      () => mockRepo.getProducts(forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer((_) async => []);
  });

  group('ProductsScreen', () {
    testWidgets('renders Product heading', (tester) async {
      await tester.pumpWidget(_wrap(mockRepo));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const Key('productsScreenTitle')), findsOneWidget);
    });

    testWidgets('renders Arena subheading', (tester) async {
      await tester.pumpWidget(_wrap(mockRepo));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Arena'), findsOneWidget);
    });

    testWidgets('renders All category chip by default', (tester) async {
      await tester.pumpWidget(_wrap(mockRepo));
      await tester.pump(const Duration(milliseconds: 200));

      // The "All" category chip is always first
      expect(find.text('All'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows loading indicator while fetching products', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(mockRepo));
      // Pump once without waiting for async to resolve
      await tester.pump();

      // CircularProgressIndicator appears during the FutureBuilder wait state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
