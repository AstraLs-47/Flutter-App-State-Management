import '../../../core/models/product_model.dart';
import '../../../domain/core/result.dart';
import '../../../domain/core/failures.dart';

abstract class ProductRepositoryFacade {
  Future<Result<List<Product>, CoreFailure>> getProducts();
  Future<Result<Product, CoreFailure>> addProduct(Product product);
  Future<Result<Product, CoreFailure>> updateProduct(Product product);
  Future<Result<void, CoreFailure>> deleteProduct(String id);
}
