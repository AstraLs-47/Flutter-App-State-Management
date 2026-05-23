// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// Project imports:
import '../../../../core/models/product_model.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/product_repository.dart';

class ProductsNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final ProductRepository _repository;

  ProductsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  Future<void> loadProducts({bool forceRefresh = false}) async {
    try {
      final products = await _repository.getProducts(forceRefresh: forceRefresh);
      state = AsyncValue.data(products);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addProduct(Product product) async {
    final response = await _repository.createProduct(product);
    state.whenData((list) {
      state = AsyncValue.data([...list, response]);
    });
  }

  Future<void> updateProduct(Product product) async {
    final response = await _repository.updateProduct(product);
    state.whenData((list) {
      state = AsyncValue.data(list.map((e) => e.id == response.id ? response : e).toList());
    });
  }

  Future<void> deleteProduct(String id) async {
    await _repository.deleteProduct(id);
    state.whenData((list) {
      state = AsyncValue.data(list.where((e) => e.id != id).toList());
    });
  }
}

// Providers
final productsProvider = StateNotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return ProductsNotifier(repository);
});
