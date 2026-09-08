import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiResponse {
  final bool success;
  final dynamic data;
  final String? error;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    required this.statusCode,
  });
}

class ApiService {
  static final ApiService instance = ApiService._internal();

  String _baseUrl = 'http://localhost:3000/api';
  String? _authToken;
  String? _activeShopId;

  ApiService._internal();

  String get baseUrl => _baseUrl;
  String? get authToken => _authToken;
  String? get activeShopId => _activeShopId;

  void configure({String? baseUrl, String? authToken, String? activeShopId}) {
    if (baseUrl != null && baseUrl.isNotEmpty) {
      _baseUrl = baseUrl;
    }
    if (authToken != null) {
      _authToken = authToken;
    }
    if (activeShopId != null) {
      _activeShopId = activeShopId;
    }
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  void setActiveShopId(String? shopId) {
    _activeShopId = shopId;
  }

  Future<ApiResponse> get(String endpoint, {Map<String, String>? queryParams}) async {
    return _sendRequest('GET', endpoint, queryParams: queryParams);
  }

  Future<ApiResponse> post(String endpoint, {Map<String, dynamic>? body}) async {
    return _sendRequest('POST', endpoint, body: body);
  }

  Future<ApiResponse> put(String endpoint, {Map<String, dynamic>? body}) async {
    return _sendRequest('PUT', endpoint, body: body);
  }

  Future<ApiResponse> delete(String endpoint) async {
    return _sendRequest('DELETE', endpoint);
  }

  Future<ApiResponse> _sendRequest(
    String method,
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    try {
      Uri uri = Uri.parse('$_baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.openUrl(method, uri);

      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      if (_authToken != null && _authToken!.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_authToken');
      }
      if (_activeShopId != null && _activeShopId!.isNotEmpty) {
        request.headers.set('x-shop-id', _activeShopId!);
      }

      if (body != null) {
        final jsonString = jsonEncode(body);
        request.write(jsonString);
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      Map<String, dynamic> jsonMap = {};
      if (responseBody.isNotEmpty) {
        try {
          jsonMap = jsonDecode(responseBody) as Map<String, dynamic>;
        } catch (_) {}
      }

      final isSuccess = response.statusCode >= 200 && response.statusCode < 300 && (jsonMap['success'] ?? true);
      return ApiResponse(
        success: isSuccess,
        data: jsonMap['data'] ?? jsonMap,
        error: jsonMap['error'] as String?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[ApiService Error] $method $endpoint: $e');
      }
      return ApiResponse(
        success: false,
        error: 'Network error or server unavailable: $e',
        statusCode: 503,
      );
    }
  }
}
