import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/data/database_helper.dart';
import 'package:gym_app/core/models/product_model.dart';
import 'package:gym_app/core/network/api_client.dart';
import 'package:gym_app/features/products/data/product_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  late MockApiClient mockApiClient;
  late MockDatabaseHelper mockDbHelper;
  late ProductRepository repository;

  final testProduct = Product(
    id: 'p1',
    title: 'Protein',
    description: 'Whey',
    category: 'Supplements',
    image: 'http://localhost/uploads/protein.png',
  );

  final testDbRow = {
    'id': 'p1',
    'name': 'Protein',
    'description': 'Whey',
    'category': 'Supplements',
    'image_url': 'http://localhost/uploads/protein.png',
  };

  setUp(() {
    mockApiClient = MockApiClient();
    mockDbHelper = MockDatabaseHelper();
    repository = ProductRepository(
      apiClient: mockApiClient,
      dbHelper: mockDbHelper,
    );
  });

  group('ProductRepository', () {
    test('should return cached data and NOT call API on cache hit', () async {
      when(
        () => mockDbHelper.queryAll('products'),
      ).thenAnswer((_) async => [testDbRow]);

      final result = await repository.getProducts(forceRefresh: false);

      expect(result, hasLength(1));
      expect(result.first.id, 'p1');
      verify(() => mockDbHelper.queryAll('products')).called(1);
      verifyNever(() => mockApiClient.get(any()));
    });

    test(
      'should fetch from API, clear cache, and insertAll on cache miss',
      () async {
        when(
          () => mockDbHelper.queryAll('products'),
        ).thenAnswer((_) async => []);
        when(() => mockApiClient.get(any())).thenAnswer(
          (_) async => [
            {
              'id': 'p1',
              'name': 'Protein',
              'description': 'Whey',
              'category': 'Supplements',
              'imageUrl': 'protein.png',
            },
          ],
        );
        when(
          () => mockDbHelper.clearTable('products'),
        ).thenAnswer((_) async {});
        when(
          () => mockDbHelper.insertAll('products', any()),
        ).thenAnswer((_) async {});

        final result = await repository.getProducts(forceRefresh: false);

        expect(result, hasLength(1));
        expect(result.first.id, 'p1');
        verify(() => mockDbHelper.queryAll('products')).called(1);
        verify(() => mockApiClient.get(any())).called(1);
        verify(() => mockDbHelper.clearTable('products')).called(1);
        verify(() => mockDbHelper.insertAll('products', any())).called(1);
      },
    );

    test(
      'should fetch from API, clear cache, and insertAll on force refresh even if cache has data',
      () async {
        when(() => mockApiClient.get(any())).thenAnswer(
          (_) async => [
            {
              'id': 'p1',
              'name': 'Protein',
              'description': 'Whey',
              'category': 'Supplements',
              'imageUrl': 'protein.png',
            },
          ],
        );
        when(
          () => mockDbHelper.clearTable('products'),
        ).thenAnswer((_) async {});
        when(
          () => mockDbHelper.insertAll('products', any()),
        ).thenAnswer((_) async {});

        final result = await repository.getProducts(forceRefresh: true);

        expect(result, hasLength(1));
        expect(result.first.id, 'p1');
        verifyNever(() => mockDbHelper.queryAll('products'));
        verify(() => mockApiClient.get(any())).called(1);
        verify(() => mockDbHelper.clearTable('products')).called(1);
        verify(() => mockDbHelper.insertAll('products', any())).called(1);
      },
    );

    test(
      'should return cached data on force refresh when API throws but cache exists',
      () async {
        when(
          () => mockDbHelper.queryAll('products'),
        ).thenAnswer((_) async => [testDbRow]);
        when(() => mockApiClient.get(any())).thenThrow(Exception('API error'));

        final result = await repository.getProducts(forceRefresh: true);

        expect(result, hasLength(1));
        expect(result.first.id, 'p1');
        verify(() => mockApiClient.get(any())).called(1);
        verify(() => mockDbHelper.queryAll('products')).called(1);
      },
    );

    test('should throw exception on force refresh when API throws', () async {
      when(() => mockDbHelper.queryAll('products')).thenAnswer((_) async => []);
      when(() => mockApiClient.get(any())).thenThrow(Exception('API error'));

      expect(() => repository.getProducts(forceRefresh: true), throwsException);
      verify(() => mockApiClient.get(any())).called(1);
      verify(() => mockDbHelper.queryAll('products')).called(1);
    });

    test(
      'should create product, insert into database, and return new product',
      () async {
        final inputProduct = Product(
          id: '',
          title: 'P',
          description: 'D',
          category: 'C',
          image: 'img.png',
        );
        when(
          () => mockApiClient.post(any(), body: any(named: 'body')),
        ).thenAnswer(
          (_) async => {
            'id': 'p_new',
            'name': 'P',
            'description': 'D',
            'category': 'C',
            'imageUrl': 'img.png',
          },
        );
        when(
          () => mockDbHelper.insert('products', any()),
        ).thenAnswer((_) async {});

        final result = await repository.createProduct(inputProduct);

        expect(result.id, 'p_new');
        verify(
          () => mockApiClient.post(any(), body: any(named: 'body')),
        ).called(1);
        verify(() => mockDbHelper.insert('products', any())).called(1);
      },
    );

    test(
      'should update product, update cache, and return updated product',
      () async {
        when(
          () => mockApiClient.put(any(), body: any(named: 'body')),
        ).thenAnswer(
          (_) async => {
            'id': 'p1',
            'name': 'P Updated',
            'description': 'D',
            'category': 'C',
            'imageUrl': 'img.png',
          },
        );
        when(
          () => mockDbHelper.insert('products', any()),
        ).thenAnswer((_) async {});

        final result = await repository.updateProduct(testProduct);

        expect(result.title, 'P Updated');
        verify(
          () => mockApiClient.put(any(), body: any(named: 'body')),
        ).called(1);
        verify(() => mockDbHelper.insert('products', any())).called(1);
      },
    );

    test('should delete product from cache and API', () async {
      when(
        () => mockDbHelper.delete('products', 'p1'),
      ).thenAnswer((_) async {});
      when(() => mockApiClient.delete(any())).thenAnswer((_) async => {});

      await repository.deleteProduct('p1');

      verify(() => mockDbHelper.delete('products', 'p1')).called(1);
      verify(() => mockApiClient.delete(any())).called(1);
    });
  });
}
