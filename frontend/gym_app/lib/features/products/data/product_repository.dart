// Flutter imports:
import 'package:flutter/foundation.dart';

// Project imports:
import '../../../core/data/database_helper.dart';
import '../../../core/models/product_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/domain/repositories/i_product_repository.dart';

class ProductRepository implements IProductRepository {
  final ApiClient _apiClient;
  final DatabaseHelper _dbHelper;

  ProductRepository({ApiClient? apiClient, DatabaseHelper? dbHelper})
    : _apiClient = apiClient ?? ApiClient(),
      _dbHelper = dbHelper ?? DatabaseHelper();

  String get _serverBaseUrl {
    final uri = Uri.parse(ApiEndpoints.baseUrl);
    return uri.replace(path: '').toString();
  }

  String _normalizeImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http') ||
        path.startsWith('assets/') ||
        path.startsWith('blob:')) {
      return path;
    }
    if (path.startsWith('/uploads/')) {
      return '$_serverBaseUrl$path';
    }
    if (path.startsWith('uploads/')) {
      return '$_serverBaseUrl/$path';
    }
    if (path.startsWith('/') ||
        path.contains(':\\') ||
        path.startsWith('file://')) {
      return path;
    }
    return '$_serverBaseUrl/uploads/$path';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  Product _mapJsonToProduct(Map<String, dynamic> json) {
    String rawCategory =
        (json['category'] ??
                json['categoryName'] ??
                json['category_name'] ??
                '')
            .toString();

    // Safety: 'All' is a UI filter, not a valid category for storage
    if (rawCategory.toLowerCase() == 'all') {
      rawCategory = '';
    }

    return Product(
      id: (json['id'] ?? '').toString(),
      title: json['title'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      category: _capitalize(rawCategory),
      image: _normalizeImageUrl(
        json['image'] ?? json['imageUrl'] ?? json['image_url'] ?? '',
      ),
    );
  }

  Map<String, dynamic> _mapProductToDb(Product product) {
    return {
      'id': product.id,
      'name': product.title,
      'description': product.description,
      'category': product.category,
      'image_url': product.image,
      'is_active': 1,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  @override
  Future<List<Product>> getProducts({bool forceRefresh = false}) async {
    print('ProductRepository.getProducts called, forceRefresh: $forceRefresh');
    if (!forceRefresh) {
      final cachedRows = await _dbHelper.queryAll('products');
      print(
        'ProductRepository.getProducts cache query returned ${cachedRows.length} rows',
      );
      if (cachedRows.isNotEmpty) {
        return cachedRows.map((row) => _mapJsonToProduct(row)).toList();
      }
    }

    // Cache miss / force refresh
    print(
      'ProductRepository.getProducts cache miss, fetching from API: ${ApiEndpoints.products}',
    );
    try {
      final List<dynamic> response = await _apiClient.get(
        ApiEndpoints.products,
      );
      print('ProductRepository.getProducts API response: $response');
      final products = response
          .map((item) => _mapJsonToProduct(item as Map<String, dynamic>))
          .toList();

      // Cache in SQLite
      await _dbHelper.clearTable('products');
      final rows = products.map((p) => _mapProductToDb(p)).toList();
      await _dbHelper.insertAll('products', rows);
      print(
        'ProductRepository.getProducts successfully cached ${rows.length} rows in SQLite',
      );

      return products;
    } catch (e) {
      final staleRows = await _dbHelper.queryAll('products');
      if (staleRows.isNotEmpty) {
        return staleRows.map((row) => _mapJsonToProduct(row)).toList();
      }
      rethrow;
    }
  }

  @override
  Future<Product> createProduct(Product product) async {
    final response = await _apiClient.post(
      ApiEndpoints.products,
      body: {
        'name': product.title,
        'description': product.description,
        'category': product.category,
        'imageUrl': product.image,
      },
    );

    final newProduct = _mapJsonToProduct(response);
    await _dbHelper.insert('products', _mapProductToDb(newProduct));
    return newProduct;
  }

  @override
  Future<Product> updateProduct(Product product) async {
    final response = await _apiClient.put(
      ApiEndpoints.product(product.id),
      body: {
        'name': product.title,
        'description': product.description,
        'category': product.category,
        'imageUrl': product.image,
      },
    );

    final updatedProduct = _mapJsonToProduct(response);
    await _dbHelper.insert('products', _mapProductToDb(updatedProduct));
    return updatedProduct;
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _dbHelper.delete('products', id);

    _apiClient.delete(ApiEndpoints.product(id)).catchError((e) {
      debugPrint('Product API deletion failed (might be already gone): $e');
    });
  }
}
