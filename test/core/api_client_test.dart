import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wingmark_flutter/core/api_client.dart';

import '../support/fake_jwt.dart';
import '../support/fake_token_store.dart';

void main() {
  late FakeTokenStore tokenStore;

  setUp(() {
    tokenStore = FakeTokenStore();
  });

  group('ApiClient request building', () {
    test('sends Accept-Language and no Authorization header when unauthenticated',
        () async {
      http.Request? captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'ok': true}), 200);
      });
      final apiClient = ApiClient(tokenStore, client: client)..languageCode = 'tr';

      await apiClient.get('/api/species', auth: false);

      expect(captured!.headers['Accept-Language'], 'tr');
      expect(captured!.headers.containsKey('Authorization'), isFalse);
    });

    test('adds Authorization header when authenticated', () async {
      await tokenStore.save(accessToken: 'abc123', refreshToken: 'r1');
      http.Request? captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'ok': true}), 200);
      });
      final apiClient = ApiClient(tokenStore, client: client);

      await apiClient.get('/api/bird-logs/user/u1');

      expect(captured!.headers['Authorization'], 'Bearer abc123');
    });

    test('includes query parameters in the URL', () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(jsonEncode([]), 200);
      });
      final apiClient = ApiClient(tokenStore, client: client);

      await apiClient
          .get('/api/species', query: {'search': 'sparrow', 'page': '1'}, auth: false);

      expect(capturedUri!.queryParameters, {'search': 'sparrow', 'page': '1'});
    });

    test('JSON-encodes the request body for POST', () async {
      String? capturedBody;
      final client = MockClient((request) async {
        capturedBody = request.body;
        return http.Response(jsonEncode({'ok': true}), 201);
      });
      final apiClient = ApiClient(tokenStore, client: client);

      await apiClient.post('/api/auth/login',
          auth: false, body: {'email': 'a@b.com', 'password': 'pw'});

      expect(jsonDecode(capturedBody!), {'email': 'a@b.com', 'password': 'pw'});
    });
  });

  group('ApiClient success responses', () {
    test('returns decoded JSON map', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'id': '1', 'name': 'x'}), 200);
      });
      final apiClient = ApiClient(tokenStore, client: client);

      final result = await apiClient.get('/api/x', auth: false);
      expect(result, {'id': '1', 'name': 'x'});
    });

    test('returns decoded JSON list', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode([1, 2, 3]), 200);
      });
      final apiClient = ApiClient(tokenStore, client: client);

      final result = await apiClient.get('/api/x', auth: false);
      expect(result, [1, 2, 3]);
    });

    test('returns null for an empty 204 response', () async {
      final client = MockClient((request) async => http.Response('', 204));
      final apiClient = ApiClient(tokenStore, client: client);

      final result = await apiClient.delete('/api/x');
      expect(result, isNull);
    });
  });

  group('ApiClient error handling', () {
    test('throws ApiException with the backend message field', () async {
      final client = MockClient((request) async {
        return http.Response(
            jsonEncode({
              'status': 404,
              'error': 'Not Found',
              'message': 'Bird log not found',
            }),
            404);
      });
      final apiClient = ApiClient(tokenStore, client: client);

      await expectLater(
        apiClient.get('/api/bird-logs/x'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.message, 'message', 'Bird log not found')),
      );
    });

    test('falls back to a generic message when the body has no message field',
        () async {
      final client = MockClient((request) async => http.Response('', 500));
      final apiClient = ApiClient(tokenStore, client: client);

      await expectLater(
        apiClient.get('/api/x'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.message, 'message',
                contains('Request failed with status 500'))),
      );
    });

    test('does not throw for 2xx status codes', () async {
      final client = MockClient((request) async => http.Response('{}', 201));
      final apiClient = ApiClient(tokenStore, client: client);

      await expectLater(apiClient.post('/api/x', auth: false), completes);
    });
  });

  group('ApiClient 401 refresh-and-retry', () {
    test('refreshes the token and retries once on 401, succeeding with the new token',
        () async {
      await tokenStore.save(accessToken: 'expired', refreshToken: 'still-valid');
      final authHeadersSeen = <String?>[];
      final client = MockClient((request) async {
        authHeadersSeen.add(request.headers['Authorization']);
        if (request.headers['Authorization'] == 'Bearer expired') {
          return http.Response(jsonEncode({'message': 'expired'}), 401);
        }
        return http.Response(jsonEncode({'ok': true}), 200);
      });
      final apiClient = ApiClient(tokenStore, client: client);

      final result = await apiClient.get('/api/bird-logs/user/u1');

      expect(result, {'ok': true});
      expect(tokenStore.refreshCallCount, 1);
      expect(authHeadersSeen, ['Bearer expired', 'Bearer ${fakeJwt('u1')}']);
    });

    test('throws the original 401 if the refresh token itself is rejected',
        () async {
      await tokenStore.save(accessToken: 'expired', refreshToken: 'also-expired');
      tokenStore.refreshShouldSucceed = false;
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'unauthorized'}), 401);
      });
      final apiClient = ApiClient(tokenStore, client: client);

      await expectLater(
        apiClient.get('/api/bird-logs/user/u1'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
      // Only one refresh attempt, no infinite retry loop.
      expect(tokenStore.refreshCallCount, 1);
    });

    test('does not attempt refresh when there is no refresh token at all',
        () async {
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        return http.Response(jsonEncode({'message': 'unauthorized'}), 401);
      });
      final apiClient = ApiClient(tokenStore, client: client);

      await expectLater(
          apiClient.get('/api/bird-logs/user/u1'), throwsA(isA<ApiException>()));
      expect(tokenStore.refreshCallCount, 0);
      expect(callCount, 1);
    });

    test('does not attempt refresh for a public (auth: false) request', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'unauthorized'}), 401);
      });
      final apiClient = ApiClient(tokenStore, client: client);

      await expectLater(apiClient.get('/api/species', auth: false),
          throwsA(isA<ApiException>()));
      expect(tokenStore.refreshCallCount, 0);
    });
  });

  group('ApiClient.uploadPhoto', () {
    late File tempFile;

    setUp(() async {
      tempFile = File('${Directory.systemTemp.path}/wingmark_test_upload.jpg');
      await tempFile.writeAsBytes([1, 2, 3, 4]);
    });

    tearDown(() async {
      if (await tempFile.exists()) await tempFile.delete();
    });

    test('sends a multipart request and returns the relative URL', () async {
      String? capturedContentType;
      final client = MockClient((request) async {
        capturedContentType = request.headers['content-type'];
        return http.Response(jsonEncode({'url': '/uploads/abc.jpg'}), 201);
      });
      final apiClient = ApiClient(tokenStore, client: client);

      final url = await apiClient.uploadPhoto(tempFile.path);

      expect(url, '/uploads/abc.jpg');
      expect(capturedContentType, contains('multipart/form-data'));
    });

    test('throws ApiException when the upload fails', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'file too large'}), 413);
      });
      final apiClient = ApiClient(tokenStore, client: client);

      await expectLater(
        apiClient.uploadPhoto(tempFile.path),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 413)),
      );
    });
  });
}
