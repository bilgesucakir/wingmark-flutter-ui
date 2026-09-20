import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wingmark_flutter/core/api_client.dart';
import 'package:wingmark_flutter/core/token_store.dart';
import 'package:wingmark_flutter/models/auth_response.dart';
import 'package:wingmark_flutter/models/enums.dart';
import 'package:wingmark_flutter/models/user.dart';
import 'package:wingmark_flutter/services/auth_service.dart';
import 'package:wingmark_flutter/services/user_service.dart';
import 'package:wingmark_flutter/state/auth_session.dart';

import '../support/fake_jwt.dart';
import '../support/fake_token_store.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(ApiClient(TokenStore()));

  AuthResponse? loginResponse;
  Object? loginError;
  AuthResponse? registerResponse;
  Object? registerError;
  String? lastLogoutToken;
  bool logoutAllCalled = false;
  String? lastResendEmail;

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    if (loginError != null) throw loginError!;
    return loginResponse!;
  }

  @override
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String username,
    String? firstName,
    String? lastName,
  }) async {
    if (registerError != null) throw registerError!;
    return registerResponse!;
  }

  @override
  Future<void> logout(String refreshToken) async {
    lastLogoutToken = refreshToken;
  }

  @override
  Future<void> logoutAll() async {
    logoutAllCalled = true;
  }

  @override
  Future<void> resendVerificationEmail(String email) async {
    lastResendEmail = email;
  }
}

class _FakeUserService extends UserService {
  _FakeUserService() : super(ApiClient(TokenStore()));

  UserProfile? profileToReturn;
  Object? profileError;
  int getProfileCallCount = 0;
  String? lastRequestedUserId;

  @override
  Future<UserProfile> getProfile(String userId) async {
    getProfileCallCount++;
    lastRequestedUserId = userId;
    if (profileError != null) throw profileError!;
    return profileToReturn!;
  }
}

UserProfile _profile({String id = 'u1'}) => UserProfile(
      id: id,
      email: 'a@b.com',
      username: 'bilgesu',
      firstName: 'Bilgesu',
      lastName: 'Cakir',
      role: Role.user,
      emailVerified: true,
      createdAt: DateTime.utc(2026, 1, 1),
    );

void main() {
  late FakeTokenStore tokenStore;
  late _FakeAuthService authService;
  late _FakeUserService userService;
  late AuthSession session;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    tokenStore = FakeTokenStore();
    authService = _FakeAuthService();
    userService = _FakeUserService();
    session = AuthSession(
      tokenStore: tokenStore,
      apiClient: ApiClient(TokenStore()),
      authService: authService,
      userService: userService,
    );
  });

  group('bootstrap', () {
    test('goes straight to unauthenticated when there is no refresh token', () async {
      await session.bootstrap();
      expect(session.status, AuthStatus.unauthenticated);
    });

    test('goes to unauthenticated when the stored refresh token is rejected',
        () async {
      await tokenStore.save(accessToken: 'old', refreshToken: 'expired');
      tokenStore.refreshShouldSucceed = false;

      await session.bootstrap();

      expect(session.status, AuthStatus.unauthenticated);
    });

    test('loads the profile and becomes authenticated on a valid session',
        () async {
      await tokenStore.save(accessToken: 'old', refreshToken: 'still-good');
      userService.profileToReturn = _profile();

      await session.bootstrap();

      expect(session.status, AuthStatus.authenticated);
      expect(session.currentUser?.id, 'u1');
      // The freshly-rotated access token from FakeTokenStore.refresh().
      expect(userService.lastRequestedUserId, isNotNull);
    });
  });

  group('login', () {
    test('on success, saves tokens, loads profile, and returns true', () async {
      final jwt = fakeJwt('u1');
      authService.loginResponse =
          AuthResponse(accessToken: jwt, refreshToken: 'ref', expiresInMs: 900000);
      userService.profileToReturn = _profile();

      final result = await session.login(email: 'a@b.com', password: 'pw');

      expect(result, isTrue);
      expect(session.status, AuthStatus.authenticated);
      expect(session.isAuthenticated, isTrue);
      expect(session.currentUser?.username, 'bilgesu');
      expect(tokenStore.accessToken, jwt);
      expect(tokenStore.refreshToken, 'ref');
      expect(userService.lastRequestedUserId, 'u1');
      expect(session.isBusy, isFalse);
    });

    test('on 403 (unverified email), routes to needsVerification and keeps the email',
        () async {
      authService.loginError = ApiException(403, 'Email not verified');

      final result = await session.login(email: 'a@b.com', password: 'pw');

      expect(result, isFalse);
      expect(session.status, AuthStatus.needsVerification);
      expect(session.pendingVerificationEmail, 'a@b.com');
      expect(session.errorMessage, 'Email not verified');
    });

    test('on other ApiException, surfaces the message without changing status',
        () async {
      authService.loginError = ApiException(401, 'Invalid credentials');

      final result = await session.login(email: 'a@b.com', password: 'wrong');

      expect(result, isFalse);
      expect(session.status, isNot(AuthStatus.needsVerification));
      expect(session.errorMessage, 'Invalid credentials');
    });

    test('on a transport error, shows a generic message', () async {
      authService.loginError = Exception('socket closed');

      final result = await session.login(email: 'a@b.com', password: 'pw');

      expect(result, isFalse);
      expect(session.errorMessage, contains('Could not reach the server'));
    });

    test('sets isBusy while in flight', () async {
      authService.loginResponse = AuthResponse(
          accessToken: fakeJwt('u1'), refreshToken: 'ref', expiresInMs: 1);
      userService.profileToReturn = _profile();

      final future = session.login(email: 'a@b.com', password: 'pw');
      expect(session.isBusy, isTrue);
      await future;
      expect(session.isBusy, isFalse);
    });
  });

  group('register', () {
    test('on success, saves tokens and routes to needsVerification (not authenticated)',
        () async {
      authService.registerResponse =
          AuthResponse(accessToken: 'acc', refreshToken: 'ref', expiresInMs: 900000);

      final result = await session.register(
        email: 'a@b.com',
        password: 'pw12345',
        username: 'bilgesu',
      );

      expect(result, isTrue);
      expect(session.status, AuthStatus.needsVerification);
      expect(session.pendingVerificationEmail, 'a@b.com');
      expect(tokenStore.accessToken, 'acc');
      // Registration must not skip straight to authenticated even though
      // usable tokens came back — login() would reject them until verified.
      expect(session.status, isNot(AuthStatus.authenticated));
    });

    test('on failure, surfaces the backend message', () async {
      authService.registerError = ApiException(409, 'Username already taken');

      final result = await session.register(
        email: 'a@b.com',
        password: 'pw12345',
        username: 'bilgesu',
      );

      expect(result, isFalse);
      expect(session.errorMessage, 'Username already taken');
    });
  });

  group('resendVerification', () {
    test('does nothing when there is no pending email', () async {
      await session.resendVerification();
      expect(authService.lastResendEmail, isNull);
    });

    test('resends to the pending email after a needs-verification login', () async {
      authService.loginError = ApiException(403, 'Email not verified');
      await session.login(email: 'pending@b.com', password: 'pw');

      await session.resendVerification();

      expect(authService.lastResendEmail, 'pending@b.com');
    });

    test('swallows transport errors from the resend call', () async {
      final erroringSession = AuthSession(
        tokenStore: FakeTokenStore(),
        apiClient: ApiClient(TokenStore()),
        authService: _ThrowingResendAuthService(),
        userService: _FakeUserService(),
      );
      erroringSession.pendingVerificationEmail = 'a@b.com';

      await expectLater(erroringSession.resendVerification(), completes);
    });
  });

  group('backToLogin', () {
    test('clears the session and returns to unauthenticated', () async {
      authService.loginResponse = AuthResponse(
          accessToken: fakeJwt('u1'), refreshToken: 'ref', expiresInMs: 1);
      userService.profileToReturn = _profile();
      await session.login(email: 'a@b.com', password: 'pw');

      await session.backToLogin();

      expect(session.status, AuthStatus.unauthenticated);
      expect(session.currentUser, isNull);
      expect(tokenStore.accessToken, isNull);
    });
  });

  group('logout', () {
    test('revokes the refresh token, clears local state, and resets status',
        () async {
      authService.loginResponse = AuthResponse(
          accessToken: fakeJwt('u1'),
          refreshToken: 'ref-to-revoke',
          expiresInMs: 1);
      userService.profileToReturn = _profile();
      await session.login(email: 'a@b.com', password: 'pw');

      await session.logout();

      expect(authService.lastLogoutToken, 'ref-to-revoke');
      expect(session.status, AuthStatus.unauthenticated);
      expect(session.currentUser, isNull);
      expect(session.pendingVerificationEmail, isNull);
      expect(tokenStore.accessToken, isNull);
    });

    test('still clears local state even if revoking the token fails on the server',
        () async {
      await tokenStore.save(accessToken: 'acc', refreshToken: 'ref');
      final erroringSession = AuthSession(
        tokenStore: tokenStore,
        apiClient: ApiClient(TokenStore()),
        authService: _ThrowingLogoutAuthService(),
        userService: userService,
      );

      await erroringSession.logout();

      expect(erroringSession.status, AuthStatus.unauthenticated);
      expect(tokenStore.accessToken, isNull);
    });

    test('does nothing to revoke when there is no refresh token to revoke', () async {
      // Fresh session, never logged in — refreshToken is null.
      await session.logout();
      expect(authService.lastLogoutToken, isNull);
      expect(session.status, AuthStatus.unauthenticated);
    });
  });

  group('refreshProfile', () {
    test('does nothing when there is no current user', () async {
      await session.refreshProfile();
      expect(userService.getProfileCallCount, 0);
    });

    test('re-fetches and replaces the current user on success', () async {
      authService.loginResponse = AuthResponse(
          accessToken: fakeJwt('u1'), refreshToken: 'ref', expiresInMs: 1);
      userService.profileToReturn = _profile();
      await session.login(email: 'a@b.com', password: 'pw');

      final updated = UserProfile(
        id: 'u1',
        email: 'a@b.com',
        username: 'bilgesu',
        firstName: 'Updated',
        lastName: 'Cakir',
        role: Role.user,
        emailVerified: true,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      userService.profileToReturn = updated;

      await session.refreshProfile();

      expect(session.currentUser?.firstName, 'Updated');
    });

    test('keeps the stale profile if the refresh call fails', () async {
      authService.loginResponse = AuthResponse(
          accessToken: fakeJwt('u1'), refreshToken: 'ref', expiresInMs: 1);
      userService.profileToReturn = _profile();
      await session.login(email: 'a@b.com', password: 'pw');

      userService.profileError = ApiException(500, 'boom');
      await session.refreshProfile();

      expect(session.currentUser?.id, 'u1');
    });
  });

  group('clearError', () {
    test('resets errorMessage to null', () async {
      authService.loginError = ApiException(400, 'bad request');
      await session.login(email: 'a@b.com', password: 'pw');
      expect(session.errorMessage, isNotNull);

      session.clearError();

      expect(session.errorMessage, isNull);
    });
  });
}

class _ThrowingLogoutAuthService extends AuthService {
  _ThrowingLogoutAuthService() : super(ApiClient(TokenStore()));

  @override
  Future<void> logout(String refreshToken) async {
    throw Exception('network down');
  }
}

class _ThrowingResendAuthService extends AuthService {
  _ThrowingResendAuthService() : super(ApiClient(TokenStore()));

  @override
  Future<void> resendVerificationEmail(String email) async {
    throw Exception('network down');
  }
}
