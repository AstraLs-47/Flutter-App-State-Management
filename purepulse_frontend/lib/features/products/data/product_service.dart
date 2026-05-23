import '../../../core/services/database_helper.dart';
import '../../../core/models/product_model.dart';

class ProductService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Product>> fetchProducts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return maps.map((p) => Product.fromJson(p)).toList();
  }

  Future<void> addProduct(Product product) async {
    final db = await _dbHelper.database;
    await db.insert(
      'products',
      product.toJson().map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Future<void> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      product.toJson().map((k, v) => MapEntry(k, v.toString())),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(String id) async {
    final db = await _dbHelper.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }
}
