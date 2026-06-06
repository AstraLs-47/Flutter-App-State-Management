// Dart imports:
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

// Flutter imports:
import 'package:flutter/foundation.dart' show kIsWeb;
// Package imports:
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// Project imports:
import '../data/token_storage.dart';

class ApiClient {
  /// If an explicit client is provided (e.g. in tests), it is stored here and
  /// reused. Otherwise a client is created lazily when first needed. Creating
  /// the client lazily ensures that tests which use `http.runWithClient` can
  /// register a zone-local factory before the real client is constructed.
  http.Client? _httpClient;
  final TokenStorage _tokenStorage;
  final Duration defaultTimeout;
  final int maxRetries;
  final void Function()? onUnauthorized;

  ApiClient({
    http.Client? client,
    TokenStorage? tokenStorage,
    this.defaultTimeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.onUnauthorized,
  }) : _httpClient = client,
       _tokenStorage = tokenStorage ?? TokenStorage();

  http.Client get _client {
    _httpClient ??= http.Client();
    return _httpClient!;
  }

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await _tokenStorage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  bool get _isTest {
    if (kIsWeb) return false;
    return Platform.environment.containsKey('FLUTTER_TEST');
  }

  Future<http.Response> _executeWithRetryAndTimeout(
    Future<http.Response> Function() requestFn,
  ) async {
    int attempts = 0;
    while (true) {
      attempts++;
      try {
        final response = await requestFn().timeout(defaultTimeout);
        if (response.statusCode == 401) {
          await _tokenStorage.clearAll();
          if (onUnauthorized != null) {
            onUnauthorized!();
          }
        }

        // Retry on 5xx errors
        if (response.statusCode >= 500 && attempts < maxRetries) {
          // In test environments the clock is fake, so skip the delay to
          // avoid deadlocks — but still retry so retry-logic tests pass.
          if (!_isTest) {
            final backoff = Duration(milliseconds: 200 * (1 << attempts));
            await Future.delayed(backoff);
          }
          continue;
        }
        return response;
      } catch (e) {
        // Retry on network/SocketException or timeout
        if (attempts < maxRetries &&
            (e is SocketException ||
                e is TimeoutException ||
                e is http.ClientException)) {
          if (!_isTest) {
            final backoff = Duration(milliseconds: 200 * (1 << attempts));
            await Future.delayed(backoff);
          }
          continue;
        }
        rethrow;
      }
    }
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final responseBody = response.body;

    if (statusCode >= 200 && statusCode < 300) {
      if (responseBody.isEmpty) return null;
      return json.decode(responseBody);
    } else {
      Map<String, dynamic> errorMap = {};
      try {
        errorMap = json.decode(responseBody) as Map<String, dynamic>;
      } catch (_) {}

      final errorMessage =
          errorMap['error'] ?? errorMap['message'] ?? 'Network request failed';
      throw ApiException(message: errorMessage, statusCode: statusCode);
    }
  }

  Future<dynamic> _mapNetworkError(Object e) async {
    if (e is ApiException) throw e;

    final errorStr = e.toString().toLowerCase();
    // Detect connection failures (including Web XMLHttpRequest errors)
    if (e is SocketException ||
        (kIsWeb && errorStr.contains('xmlhttprequest'))) {
      throw const ApiException(
        message: 'No internet connection',
        statusCode: 503,
      );
    } else if (e is TimeoutException) {
      throw const ApiException(message: 'Request timed out', statusCode: 408);
    }
    throw ApiException(message: e.toString(), statusCode: 500);
  }

  Future<dynamic> get(String url, {bool includeAuth = true}) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final response = await _executeWithRetryAndTimeout(
        () => _client.get(Uri.parse(url), headers: headers),
      );
      return _handleResponse(response);
    } catch (e) {
      return _mapNetworkError(e);
    }
  }

  /// Sanitizes the request body to ensure numeric fields are sent as actual numbers.
  /// This is critical for backend aggregation logic (like SUM(calories)) and ensures
  /// consistent data types for daily progress tracking.
  dynamic _sanitizeBody(dynamic body) {
    if (body is! Map) return body;

    return Map.from(body).map((key, value) {
      final keyLower = key.toString().toLowerCase();
      final numericKeys = [
        'age',
        'height',
        'weight',
        'current_weight',
        'goal_weight',
        'duration',
        'bmi',
        'heart_rate',
        'heartrate',
        'pulse',
        'blood_pressure',
        'sets',
        'reps',
        'calories',
      ];

      if (numericKeys.contains(keyLower)) {
        if (value == null) return MapEntry(key, 0);

        if (value is num) {
          if (value is double && (value.isNaN || value.isInfinite)) {
            return MapEntry(key, 0);
          }
          return MapEntry(key, value);
        }

        if (value is String) {
          final val = value.trim().toLowerCase();
          if (val.isEmpty || val == 'nan') return MapEntry(key, 0);

          // Strip units/text: "10 KCAL" -> "10"
          final numericOnly = val.replaceAll(RegExp(r'[^0-9.]'), '');
          if (numericOnly.isEmpty) return MapEntry(key, 0);
          return MapEntry(key, num.tryParse(numericOnly) ?? 0);
        }
      }
      return MapEntry(key, value);
    });
  }

  Future<dynamic> post(
    String url, {
    dynamic body,
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final sanitizedBody = _sanitizeBody(body);

      final response = await _executeWithRetryAndTimeout(
        () => _client.post(
          Uri.parse(url),
          headers: headers,
          body: sanitizedBody != null ? json.encode(sanitizedBody) : null,
        ),
      );
      return _handleResponse(response);
    } catch (e) {
      return _mapNetworkError(e);
    }
  }

  Future<dynamic> put(
    String url, {
    dynamic body,
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final sanitizedBody = _sanitizeBody(body);

      final response = await _executeWithRetryAndTimeout(
        () => _client.put(
          Uri.parse(url),
          headers: headers,
          body: sanitizedBody != null ? json.encode(sanitizedBody) : null,
        ),
      );
      return _handleResponse(response);
    } catch (e) {
      return _mapNetworkError(e);
    }
  }

  Future<dynamic> uploadFile(
    String url,
    dynamic file, {
    bool includeAuth = true,
    String field = 'image',
  }) async {
    try {
      final response = await _executeWithRetryAndTimeout(() async {
        final headers = await _getHeaders(includeAuth: includeAuth);
        headers.remove('Content-Type');
        final request = http.MultipartRequest('POST', Uri.parse(url));
        request.headers.addAll(headers);

        // Support multiple input types: dart:io File, XFile (image_picker), bytes/Uint8List, or path string
        if (kIsWeb) {
          // On web we expect either an XFile or raw bytes
          if (file is XFile) {
            final bytes = await file.readAsBytes();
            final multipart = http.MultipartFile.fromBytes(
              field,
              bytes,
              filename: file.name,
            );
            request.files.add(multipart);
          } else if (file is Uint8List || file is List<int>) {
            final multipart = http.MultipartFile.fromBytes(
              field,
              file as List<int>,
              filename: '${DateTime.now().millisecondsSinceEpoch}.png',
            );
            request.files.add(multipart);
          } else if (file is String) {
            // Blob URLs can't be uploaded from the client; the caller must provide an XFile or bytes
            throw const ApiException(
              message:
                  'Cannot upload from a path on web; provide an XFile or bytes',
              statusCode: 400,
            );
          } else {
            throw const ApiException(
              message: 'Unsupported file type for web upload',
              statusCode: 400,
            );
          }
        } else {
          // Native platforms: accept File, XFile, or path string
          if (file is File) {
            request.files.add(
              await http.MultipartFile.fromPath(field, file.path),
            );
          } else if (file is XFile) {
            request.files.add(
              await http.MultipartFile.fromPath(field, file.path),
            );
          } else if (file is String) {
            request.files.add(await http.MultipartFile.fromPath(field, file));
          } else if (file is Uint8List || file is List<int>) {
            final multipart = http.MultipartFile.fromBytes(
              field,
              file as List<int>,
              filename: '${DateTime.now().millisecondsSinceEpoch}.png',
            );
            request.files.add(multipart);
          } else {
            throw const ApiException(
              message: 'Unsupported file type for upload',
              statusCode: 400,
            );
          }
        }

        final streamedResponse = await request.send();
        return http.Response.fromStream(streamedResponse);
      });
      return _handleResponse(response);
    } catch (e) {
      return _mapNetworkError(e);
    }
  }

  Future<dynamic> delete(String url, {bool includeAuth = true}) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final response = await _executeWithRetryAndTimeout(
        () => _client.delete(Uri.parse(url), headers: headers),
      );
      return _handleResponse(response);
    } catch (e) {
      return _mapNetworkError(e);
    }
  }

  /// Closes the underlying HTTP client.
  void dispose() {
    _httpClient?.close();
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException({required this.message, required this.statusCode});

  String get cleanMessage {
    final msg = message.toLowerCase();

    if (statusCode == 500) {
      if (msg.contains('relation') ||
          msg.contains('column') ||
          msg.contains('table') ||
          msg.contains('database') ||
          msg.contains('sql') ||
          msg.contains('postgres') ||
          msg.contains('exist')) {
        return 'A server database configuration error occurred. Please contact support.';
      }
      return 'An unexpected server error occurred. Please try again later.';
    }
    if (statusCode == 503) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (statusCode == 408) {
      return 'The request timed out. Please check your connection and try again.';
    }
    if (statusCode == 401) {
      return 'Your session has expired. Please sign in again.';
    }
    if (statusCode == 403) {
      return 'You do not have permission to perform this action.';
    }
    if (statusCode == 404) {
      return 'The requested resource was not found.';
    }

    if (msg.contains('column "') ||
        msg.contains('relation "') ||
        msg.contains('does not exist')) {
      return 'A database mapping error occurred. Please try again.';
    }

    return message;
  }

  @override
  String toString() => cleanMessage;
}
