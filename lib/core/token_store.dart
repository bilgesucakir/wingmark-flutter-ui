import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'constants.dart';

/// Persists the JWT access/refresh token pair and knows how to rotate them
/// against POST /api/auth/refresh (single-use refresh tokens — the backend
/// revokes the old one on every refresh).
class TokenStore {
  TokenStore({FlutterSecureStorage? storage, http.Client? client})
      : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

  final FlutterSecureStorage _storage;
  final http.Client _client;

  static const _accessKey = 'wingmark.accessToken';
  static const _refreshKey = 'wingmark.refreshToken';

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get hasRefreshToken => _refreshToken != null;

  Future<void> loadFromStorage() async {
    _accessToken = await _storage.read(key: _accessKey);
    _refreshToken = await _storage.read(key: _refreshKey);
  }

  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  /// Rotates the refresh token pair. Returns false (and clears the stored
  /// session) if the refresh token is missing, expired, or already revoked.
  Future<bool> refresh() async {
    final currentRefresh = _refreshToken;
    if (currentRefresh == null) return false;
    try {
      final response = await _client
          .post(
            Uri.parse('$kApiBaseUrl/api/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': currentRefresh}),
          )
          .timeout(kApiTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await clear();
        return false;
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      await save(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
