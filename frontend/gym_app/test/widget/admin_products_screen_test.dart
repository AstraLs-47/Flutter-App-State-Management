import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_app/features/admin/presentation/screens/admin_products_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

GoRouter _testRouter() => GoRouter(
  initialLocation: '/admin/products',
  routes: [
    GoRoute(
      path: '/admin/products',
      builder: (_, _) => const AdminProductsScreen(),
    ),
  ],
);

Widget _wrap() => MaterialApp.router(routerConfig: _testRouter());

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AdminProductsScreen Widget', () {
    testWidgets('renders product management headers', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.text('MANAGE'), findsOneWidget);
      expect(find.text('Products'), findsNWidgets(2));
    });

    testWidgets('renders category and add icons', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byIcon(Icons.local_offer), findsOneWidget);
      // It has add icon for creating products
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows loading state initially', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
