import '../../../core/data/local_data_source.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/database_helper.dart';

class ProductLocalDataSource implements LocalDataSource<Product> {
  final DatabaseHelper _dbHelper;

  ProductLocalDataSource(this._dbHelper);

  @override
  Future<void> clear() async {
    final db = await _dbHelper.database;
    await db.delete('products');
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Product>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return maps.map((p) => Product.fromJson(p)).toList();
  }

  @override
  Future<void> save(Product item) async {
    final db = await _dbHelper.database;
    await db.insert(
      'products',
      item.toJson().map((k, v) => MapEntry(k, v.toString())),
    );
  }

  @override
  Future<void> saveAll(List<Product> items) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var item in items) {
      batch.insert(
        'products',
        item.toJson().map((k, v) => MapEntry(k, v.toString())),
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> update(Product item) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      item.toJson().map((k, v) => MapEntry(k, v.toString())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }
}
