import 'package:flutter_test/flutter_test.dart';
import 'package:wingmark_flutter/core/api_client.dart';
import 'package:wingmark_flutter/services/auth_service.dart';

import 'fake_api_client.dart';

void main() {
  late FakeApiClient client;
  late AuthService service;

  setUp(() {
    client = FakeApiClient();
    service = AuthService(client);
  });

  test('register posts to /api/auth/register without auth and parses tokens',
      () async {
    client.response = {
      'accessToken': 'a1',
      'refreshToken': 'r1',
      'expiresInMs': 900000,
    };

    final result = await service.register(
      email: 'a@b.com',
      password: 'password1',
      username: 'bilgesu',
      firstName: 'Bilgesu',
      lastName: 'Cakir',
    );

    expect(client.lastMethod, 'POST');
    expect(client.lastPath, '/api/auth/register');
    expect(client.lastAuth, isFalse);
    expect(client.lastBody, {
      'email': 'a@b.com',
      'password': 'password1',
      'username': 'bilgesu',
      'firstName': 'Bilgesu',
      'lastName': 'Cakir',
    });
    expect(result.accessToken, 'a1');
    expect(result.refreshToken, 'r1');
  });

  test('login posts email/password to /api/auth/login without auth', () async {
    client.response = {
      'accessToken': 'a2',
      'refreshToken': 'r2',
      'expiresInMs': 900000,
    };

    await service.login(email: 'a@b.com', password: 'pw');

    expect(client.lastPath, '/api/auth/login');
    expect(client.lastAuth, isFalse);
    expect(client.lastBody, {'email': 'a@b.com', 'password': 'pw'});
  });

  test('logout posts the refresh token without auth', () async {
    client.response = null;
    await service.logout('r-token');

    expect(client.lastPath, '/api/auth/logout');
    expect(client.lastAuth, isFalse);
    expect(client.lastBody, {'refreshToken': 'r-token'});
  });

  test('logoutAll posts with auth (requires the caller\'s own JWT)', () async {
    client.response = null;
    await service.logoutAll();

    expect(client.lastPath, '/api/auth/logout-all');
    expect(client.lastAuth, isNot(false));
  });

  test('forgotPassword posts email without auth', () async {
    client.response = null;
    await service.forgotPassword('a@b.com');

    expect(client.lastPath, '/api/auth/forgot-password');
    expect(client.lastAuth, isFalse);
    expect(client.lastBody, {'email': 'a@b.com'});
  });

  test('resetPassword posts token and newPassword without auth', () async {
    client.response = null;
    await service.resetPassword(token: 'tok', newPassword: 'newpw123');

    expect(client.lastPath, '/api/auth/reset-password');
    expect(client.lastAuth, isFalse);
    expect(client.lastBody, {'token': 'tok', 'newPassword': 'newpw123'});
  });

  test('resendVerificationEmail posts email without auth', () async {
    client.response = null;
    await service.resendVerificationEmail('a@b.com');

    expect(client.lastPath, '/api/auth/resend-verification-email');
    expect(client.lastAuth, isFalse);
    expect(client.lastBody, {'email': 'a@b.com'});
  });

  test('propagates ApiException from the underlying client', () async {
    client.errorToThrow = ApiException(403, 'Email not verified');

    await expectLater(
      service.login(email: 'a@b.com', password: 'pw'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403)),
    );
  });
}
