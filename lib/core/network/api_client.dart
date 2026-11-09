import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.tokenProvider,
    this._onUnauthorized,
  });

  final String baseUrl;
  final Future<String?> Function() tokenProvider;
  Future<void> Function()? _onUnauthorized;

  set onUnauthorized(Future<void> Function()? handler) {
    _onUnauthorized = handler;
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final uri = _buildUri(path, queryParams);
    final headers = await _headers();
    final response = await http.get(uri, headers: headers);
    await _handleUnauthorized(response);
    return response;
  }

  Future<http.Response> post(
    String path, {
    Object? body,
    Map<String, String>? queryParams,
  }) async {
    final uri = _buildUri(path, queryParams);
    final headers = await _headers();
    final encoded = body == null ? null : jsonEncode(body);
    final response = await http.post(uri, body: encoded, headers: headers);
    await _handleUnauthorized(response);
    return response;
  }

  Future<http.Response> put(
    String path, {
    Object? body,
    Map<String, String>? queryParams,
  }) async {
    final uri = _buildUri(path, queryParams);
    final headers = await _headers();
    final encoded = body == null ? null : jsonEncode(body);
    final response = await http.put(uri, body: encoded, headers: headers);
    await _handleUnauthorized(response);
    return response;
  }

  Future<http.Response> delete(
    String path, {
    Object? body,
    Map<String, String>? queryParams,
  }) async {
    final uri = _buildUri(path, queryParams);
    final headers = await _headers();
    final encoded = body == null ? null : jsonEncode(body);
    final response = await http.delete(uri, body: encoded, headers: headers);
    await _handleUnauthorized(response);
    return response;
  }

  Uri _buildUri(String path, Map<String, String>? queryParams) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalized')
        .replace(queryParameters: queryParams);
  }

  Future<Map<String, String>> _headers() async {
    final token = await tokenProvider();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _handleUnauthorized(http.Response response) async {
    if (response.statusCode == 401 && _onUnauthorized != null) {
      await _onUnauthorized!.call();
    }
  }
}
