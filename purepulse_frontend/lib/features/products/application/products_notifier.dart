import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/database_helper.dart';
import '../../../domain/core/result.dart';
import '../../../domain/core/failures.dart';
import '../infrastructure/product_local_data_source.dart';
import '../infrastructure/product_remote_data_source.dart';
import '../infrastructure/product_repository_impl.dart';

part 'products_notifier.g.dart';

@riverpod
ProductRepositoryImpl productRepository(Ref ref) {
  final local = ProductLocalDataSource(DatabaseHelper());
  final remote = ProductRemoteDataSource();
  return ProductRepositoryImpl(local, remote);
}

@riverpod
class ProductsNotifier extends _$ProductsNotifier {
  @override
  FutureOr<List<Product>> build() async {
    return _fetchProducts();
  }

  Future<List<Product>> _fetchProducts() async {
    final repo = ref.read(productRepositoryProvider);
    final result = await repo.getProducts();
    if (result is Success<List<Product>, CoreFailure>) {
      return result.value;
    } else {
      throw Exception((result as Failure).error.message);
    }
  }

  Future<void> add(Product product) async {
    state = const AsyncValue.loading();
    final repo = ref.read(productRepositoryProvider);
    await repo.addProduct(product);
    state = AsyncValue.data(await _fetchProducts());
  }

  Future<void> updateProduct(Product product) async {
    state = const AsyncValue.loading();
    final repo = ref.read(productRepositoryProvider);
    await repo.updateProduct(product);
    state = AsyncValue.data(await _fetchProducts());
  }

  Future<void> delete(String id) async {
    state = const AsyncValue.loading();
    final repo = ref.read(productRepositoryProvider);
    await repo.deleteProduct(id);
    state = AsyncValue.data(await _fetchProducts());
  }
}
