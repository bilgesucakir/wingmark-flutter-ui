import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wingmark_flutter/core/token_store.dart';

void main() {
  // The package's own test double — swaps the platform channel-backed
  // storage for a real in-memory map, so read/write/delete all work without
  // needing a Flutter binding or platform channel.
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('persistence', () {
    test('starts with no tokens', () async {
      final store = TokenStore();
      await store.loadFromStorage();
      expect(store.accessToken, isNull);
      expect(store.refreshToken, isNull);
      expect(store.hasRefreshToken, isFalse);
    });

    test('save updates in-memory getters and persists to storage', () async {
      final store = TokenStore();
      await store.save(accessToken: 'a1', refreshToken: 'r1');

      expect(store.accessToken, 'a1');
      expect(store.refreshToken, 'r1');
      expect(store.hasRefreshToken, isTrue);

      // A fresh instance reading the same backing store should see it too.
      final reloaded = TokenStore();
      await reloaded.loadFromStorage();
      expect(reloaded.accessToken, 'a1');
      expect(reloaded.refreshToken, 'r1');
    });

    test('clear wipes both in-memory and persisted tokens', () async {
      final store = TokenStore();
      await store.save(accessToken: 'a1', refreshToken: 'r1');
      await store.clear();

      expect(store.accessToken, isNull);
      expect(store.refreshToken, isNull);
      expect(store.hasRefreshToken, isFalse);

      final reloaded = TokenStore();
      await reloaded.loadFromStorage();
      expect(reloaded.accessToken, isNull);
      expect(reloaded.refreshToken, isNull);
    });
  });

  group('refresh', () {
    test('returns false without calling the network when there is no refresh token',
        () async {
      var called = false;
      final client = MockClient((request) async {
        called = true;
        return http.Response('{}', 200);
      });
      final store = TokenStore(client: client);

      final result = await store.refresh();

      expect(result, isFalse);
      expect(called, isFalse);
    });

    test('rotates the token pair on a successful refresh', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/auth/refresh');
        expect(jsonDecode(request.body), {'refreshToken': 'old-refresh'});
        return http.Response(
            jsonEncode({
              'accessToken': 'new-access',
              'refreshToken': 'new-refresh',
              'expiresInMs': 900000,
            }),
            200);
      });
      final store = TokenStore(client: client);
      await store.save(accessToken: 'old-access', refreshToken: 'old-refresh');

      final result = await store.refresh();

      expect(result, isTrue);
      expect(store.accessToken, 'new-access');
      expect(store.refreshToken, 'new-refresh');
    });

    test('clears tokens and returns false when the backend rejects the refresh token',
        () async {
      final client = MockClient((request) async =>
          http.Response(jsonEncode({'message': 'invalid token'}), 401));
      final store = TokenStore(client: client);
      await store.save(accessToken: 'old-access', refreshToken: 'revoked-refresh');

      final result = await store.refresh();

      expect(result, isFalse);
      expect(store.accessToken, isNull);
      expect(store.refreshToken, isNull);
    });

    test('returns false (without crashing) on a network error', () async {
      final client = MockClient((request) async {
        throw Exception('network unreachable');
      });
      final store = TokenStore(client: client);
      await store.save(accessToken: 'old-access', refreshToken: 'old-refresh');

      final result = await store.refresh();

      expect(result, isFalse);
      // Tokens are left as-is on a transport error (only an explicit
      // rejection from the backend clears them).
      expect(store.accessToken, 'old-access');
    });
  });
}
