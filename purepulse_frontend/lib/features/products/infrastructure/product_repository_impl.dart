import '../../../core/models/product_model.dart';
import '../../../domain/core/failures.dart';
import '../../../domain/core/result.dart';
import '../domain/product_repository_facade.dart';
import 'product_local_data_source.dart';
import 'product_remote_data_source.dart';

/// Repository implementation for gym equipment catalog.
///
/// Cache-first strategy:
///   1. Check local SQLite cache (ProductLocalDataSource) first
///   2. Cache hit → return local data immediately
///   3. Cache miss → fetch from remote, persist, return
class ProductRepositoryImpl implements ProductRepositoryFacade {
  final ProductLocalDataSource _localDataSource;
  final ProductRemoteDataSource _remoteDataSource;

  ProductRepositoryImpl(this._localDataSource, this._remoteDataSource);

  @override
  Future<Result<List<Product>, CoreFailure>> getProducts() async {
    try {
      // ── Step 1: Cache hit check ───────────────────────────────────────────
      final localProducts = await _localDataSource.getAll();
      if (localProducts.isNotEmpty) {
        // Cache hit → return immediately without network request
        return Success(localProducts);
      }

      // ── Step 2: Cache miss → fetch from remote ────────────────────────────
      final remoteProducts = await _remoteDataSource.getAll();
      await _localDataSource.clear();
      await _localDataSource.saveAll(remoteProducts);
      return Success(remoteProducts);
    } catch (e) {
      try {
        final local = await _localDataSource.getAll();
        if (local.isNotEmpty) return Success(local);
      } catch (_) {}
      return Failure(ServerFailure('Failed to fetch products: $e'));
    }
  }

  @override
  Future<Result<Product, CoreFailure>> addProduct(Product product) async {
    try {
      Product toSave = product;
      try {
        toSave = await _remoteDataSource.create(product);
      } catch (_) {}
      await _localDataSource.save(toSave);
      return Success(toSave);
    } catch (e) {
      return Failure(ServerFailure('Failed to add product: $e'));
    }
  }

  @override
  Future<Result<Product, CoreFailure>> updateProduct(Product product) async {
    try {
      Product toSave = product;
      try {
        toSave = await _remoteDataSource.update(product);
      } catch (_) {}
      await _localDataSource.update(toSave);
      return Success(toSave);
    } catch (e) {
      return Failure(ServerFailure('Failed to update product: $e'));
    }
  }

  @override
  Future<Result<void, CoreFailure>> deleteProduct(String id) async {
    try {
      try {
        await _remoteDataSource.delete(id);
      } catch (_) {}
      await _localDataSource.delete(id);
      return const Success(null);
    } catch (e) {
      return Failure(ServerFailure('Failed to delete product: $e'));
    }
  }
}
