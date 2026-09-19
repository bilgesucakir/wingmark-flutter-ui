import '../core/api_client.dart';
import '../models/auth_response.dart';

/// Wraps the public /api/auth/* endpoints (see AuthController.java).
class AuthService {
  AuthService(this._client);

  final ApiClient _client;

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String username,
    String? firstName,
    String? lastName,
  }) async {
    final json = await _client.post(
      '/api/auth/register',
      auth: false,
      body: {
        'email': email,
        'password': password,
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
      },
    );
    return AuthResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final json = await _client.post(
      '/api/auth/login',
      auth: false,
      body: {'email': email, 'password': password},
    );
    return AuthResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<void> logout(String refreshToken) => _client.post(
        '/api/auth/logout',
        auth: false,
        body: {'refreshToken': refreshToken},
      );

  Future<void> logoutAll() => _client.post('/api/auth/logout-all');

  Future<void> forgotPassword(String email) => _client.post(
        '/api/auth/forgot-password',
        auth: false,
        body: {'email': email},
      );

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) =>
      _client.post(
        '/api/auth/reset-password',
        auth: false,
        body: {'token': token, 'newPassword': newPassword},
      );

  Future<void> resendVerificationEmail(String email) => _client.post(
        '/api/auth/resend-verification-email',
        auth: false,
        body: {'email': email},
      );
}
