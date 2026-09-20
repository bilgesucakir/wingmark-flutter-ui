import 'dart:convert';

import 'package:http/http.dart' as http;

import 'constants.dart';
import 'token_store.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Thin REST client for the wingmark-backend API: base URL, JSON
/// encode/decode, bearer-token injection, and a single transparent
/// refresh-and-retry on 401 (access tokens expire after 15 minutes).
class ApiClient {
  ApiClient(this._tokenStore, {http.Client? client})
      : _client = client ?? http.Client();

  final TokenStore _tokenStore;
  final http.Client _client;

  /// Drives the Accept-Language header so the backend resolves locale-keyed
  /// text (species names, favoriteSpeciesName, etc.) correctly. Kept in
  /// sync with the app's effective locale from app.dart.
  String languageCode = 'en';

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) =>
      _send('GET', path, query: query, auth: auth);

  Future<dynamic> post(String path, {Object? body, bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);

  Future<dynamic> put(String path, {Object? body, bool auth = true}) =>
      _send('PUT', path, body: body, auth: auth);

  Future<dynamic> delete(String path, {bool auth = true}) =>
      _send('DELETE', path, auth: auth);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool auth = true,
    bool isRetry = false,
  }) async {
    final uri = Uri.parse('$kApiBaseUrl$path').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );

    final request = http.Request(method, uri);
    request.headers['Content-Type'] = 'application/json';
    request.headers['Accept-Language'] = languageCode;
    if (auth && _tokenStore.accessToken != null) {
      request.headers['Authorization'] = 'Bearer ${_tokenStore.accessToken}';
    }
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final response = await _client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(kApiTimeout);

    if (response.statusCode == 401 &&
        auth &&
        !isRetry &&
        _tokenStore.hasRefreshToken) {
      final refreshed = await _tokenStore.refresh();
      if (refreshed) {
        return _send(method, path,
            query: query, body: body, auth: auth, isRetry: true);
      }
    }

    if (response.body.isEmpty) {
      _throwIfError(response, null);
      return null;
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    _throwIfError(response, decoded);
    return decoded;
  }

  void _throwIfError(http.Response response, dynamic decoded) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    var message = 'Request failed with status ${response.statusCode}';
    if (decoded is Map && decoded['message'] is String) {
      message = decoded['message'] as String;
    }
    throw ApiException(response.statusCode, message);
  }

  /// POST /api/uploads/photo — multipart upload, returns the relative URL
  /// (e.g. "/uploads/xxxx.jpg") the caller must resolve via [resolveMediaUrl].
  Future<String> uploadPhoto(String filePath) async {
    final uri = Uri.parse('$kApiBaseUrl/api/uploads/photo');
    final request = http.MultipartRequest('POST', uri);
    if (_tokenStore.accessToken != null) {
      request.headers['Authorization'] = 'Bearer ${_tokenStore.accessToken}';
    }
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamed = await _client.send(request).timeout(kApiTimeout);
    final response = await http.Response.fromStream(streamed);

    Map<String, dynamic>? decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      decoded = null;
    }
    _throwIfError(response, decoded);
    return decoded!['url'] as String;
  }
}
