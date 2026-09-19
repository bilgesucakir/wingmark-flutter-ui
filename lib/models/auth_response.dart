/// Mirrors backend AuthResponseDto returned by register/login/refresh.
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresInMs;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInMs,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresInMs: (json['expiresInMs'] as num).toInt(),
    );
  }
}
