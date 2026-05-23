import '../../../core/data/remote_data_source.dart';
import '../../../core/models/product_model.dart';

class ProductRemoteDataSource implements RemoteDataSource<Product> {
  // Simulate network delay and return mock data for now
  @override
  Future<Product> create(Product item) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return item;
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<List<Product>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 800));
    throw Exception('Not implemented backend yet');
  }

  @override
  Future<Product> update(Product item) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return item;
  }
}
