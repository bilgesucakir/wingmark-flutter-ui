import 'package:flutter_test/flutter_test.dart';
import 'package:wingmark_flutter/models/auth_response.dart';

void main() {
  test('AuthResponse.fromJson parses tokens and expiry', () {
    final auth = AuthResponse.fromJson({
      'accessToken': 'access123',
      'refreshToken': 'refresh456',
      'expiresInMs': 900000,
    });

    expect(auth.accessToken, 'access123');
    expect(auth.refreshToken, 'refresh456');
    expect(auth.expiresInMs, 900000);
  });
}
