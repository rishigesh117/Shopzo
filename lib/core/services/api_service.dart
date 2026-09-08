import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (_authToken != null && _authToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_authToken';
      }
      if (_activeShopId != null && _activeShopId!.isNotEmpty) {
        headers['x-shop-id'] = _activeShopId!;
      }

      http.Response response;
      final bodyString = body != null ? jsonEncode(body) : null;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 5));
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: bodyString).timeout(const Duration(seconds: 5));
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: bodyString).timeout(const Duration(seconds: 5));
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 5));
          break;
        default:
          throw UnsupportedError('HTTP method $method not supported');
      }

      final responseBody = response.body;

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
