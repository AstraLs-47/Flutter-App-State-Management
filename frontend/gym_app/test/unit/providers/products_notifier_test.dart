import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/domain/repositories/i_product_repository.dart';
import 'package:gym_app/core/models/product_model.dart';
import 'package:gym_app/core/providers/core_providers.dart';
import 'package:gym_app/features/products/presentation/providers/product_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockProductRepository extends Mock implements IProductRepository {}

class MockListener<T> extends Mock {
  void call(T? previous, T next);
}

void main() {
  late MockProductRepository mockProductRepository;

  final testProduct = Product(
    id: '1',
    title: 'Protein Powder',
    description: 'Whey protein isolate',
    category: 'Supplements',
    image: 'protein.png',
  );

  setUpAll(() {
    registerFallbackValue(
      Product(id: '', title: '', description: '', category: '', image: ''),
    );
    // Required for any(that: isA<AsyncValue<...>>()) matchers
    registerFallbackValue(const AsyncLoading<List<Product>>());
    // Register a concrete AsyncData fallback for base type parameter matching
    registerFallbackValue(AsyncData<List<Product>>([]));
  });

  setUp(() {
    mockProductRepository = MockProductRepository();
    // Provide a default stub for the provider's build() method which calls getProducts(forceRefresh: false)
    when(
      () => mockProductRepository.getProducts(
        forceRefresh: any(named: 'forceRefresh'),
      ),
    ).thenAnswer((_) async => []);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(mockProductRepository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('ProductsNotifier', () {
    test('loads products correctly from repository use case', () async {
      when(
        () => mockProductRepository.getProducts(
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer((_) async => [testProduct]);

      final container = makeContainer();

      // Wait for build to execute
      await container.read(productsProvider.future);

      final state = container.read(productsProvider);
      expect(state.value, [testProduct]);
    });

    test('adds product and updates state list', () async {
      when(
        () => mockProductRepository.getProducts(
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer((_) async => []);
      when(
        () => mockProductRepository.createProduct(any()),
      ).thenAnswer((_) async => testProduct);

      final container = makeContainer();
      await container.read(productsProvider.future);

      final notifier = container.read(productsProvider.notifier);
      await notifier.addProduct(testProduct);

      final state = container.read(productsProvider);
      expect(state.value, [testProduct]);
    });

    test('loadProducts sets state to loading then data', () async {
      final products = [testProduct];
      when(
        () => mockProductRepository.getProducts(
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer((_) async => products);

      final container = makeContainer();

      final listener = MockListener<AsyncValue<List<Product>>>();
      container.listen(productsProvider, listener.call, fireImmediately: true);

      await container.read(productsProvider.future);

      verifyInOrder([
        () => listener(null, any()),
        () => listener(any(), AsyncData(products)),
      ]);
    });

    test(
      'loadProducts with forceRefresh=true calls repository and updates state',
      () async {
        final products = [testProduct];
        when(
          () => mockProductRepository.getProducts(forceRefresh: true),
        ).thenAnswer((_) async => products);

        final container = makeContainer();

        // Ensure the provider finishes its initial build() before we trigger a load
        await container.read(productsProvider.future);

        await container
            .read(productsProvider.notifier)
            .loadProducts(forceRefresh: true);

        expect(container.read(productsProvider).value, products);
        verify(
          () => mockProductRepository.getProducts(forceRefresh: true),
        ).called(1);
      },
    );

    test(
      'updateProduct calls repository updateProduct and replaces matching item in state',
      () async {
        final initialProducts = [testProduct];
        final updatedProduct = Product(
          id: '1',
          title: 'New Name',
          description: testProduct.description,
          category: testProduct.category,
          image: testProduct.image,
        );

        when(
          () => mockProductRepository.getProducts(
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer((_) async => initialProducts);
        when(
          () => mockProductRepository.updateProduct(updatedProduct),
        ).thenAnswer((_) async => updatedProduct);

        final container = makeContainer();
        await container.read(productsProvider.future);

        await container
            .read(productsProvider.notifier)
            .updateProduct(updatedProduct);

        final state = container.read(productsProvider).value;
        expect(state?.first.title, 'New Name');
        verify(
          () => mockProductRepository.updateProduct(updatedProduct),
        ).called(1);
      },
    );

    test(
      'deleteProduct calls repository deleteProduct and removes matching item from state',
      () async {
        final products = [testProduct];
        when(
          () => mockProductRepository.getProducts(
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer((_) async => products);
        when(
          () => mockProductRepository.deleteProduct('1'),
        ).thenAnswer((_) async => {});

        final container = makeContainer();
        await container.read(productsProvider.future);

        await container.read(productsProvider.notifier).deleteProduct('1');

        expect(container.read(productsProvider).value, isEmpty);
        verify(() => mockProductRepository.deleteProduct('1')).called(1);
      },
    );
  });
}
