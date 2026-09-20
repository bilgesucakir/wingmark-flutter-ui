import 'package:wingmark_flutter/core/api_client.dart';
import 'package:wingmark_flutter/core/token_store.dart';

/// Records the last call made through it and returns a preset [response]
/// (or throws [errorToThrow]) — lets service classes be tested without any
/// real HTTP traffic.
class FakeApiClient extends ApiClient {
  FakeApiClient() : super(TokenStore());

  String? lastMethod;
  String? lastPath;
  Map<String, String>? lastQuery;
  Object? lastBody;
  bool? lastAuth;
  String? lastUploadPath;

  dynamic response;
  Object? errorToThrow;

  void _record(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool? auth,
  }) {
    lastMethod = method;
    lastPath = path;
    lastQuery = query;
    lastBody = body;
    lastAuth = auth;
  }

  @override
  Future<dynamic> get(String path, {Map<String, String>? query, bool auth = true}) async {
    _record('GET', path, query: query, auth: auth);
    if (errorToThrow != null) throw errorToThrow!;
    return response;
  }

  @override
  Future<dynamic> post(String path, {Object? body, bool auth = true}) async {
    _record('POST', path, body: body, auth: auth);
    if (errorToThrow != null) throw errorToThrow!;
    return response;
  }

  @override
  Future<dynamic> put(String path, {Object? body, bool auth = true}) async {
    _record('PUT', path, body: body, auth: auth);
    if (errorToThrow != null) throw errorToThrow!;
    return response;
  }

  @override
  Future<dynamic> delete(String path, {bool auth = true}) async {
    _record('DELETE', path, auth: auth);
    if (errorToThrow != null) throw errorToThrow!;
    return response;
  }

  @override
  Future<String> uploadPhoto(String filePath) async {
    lastUploadPath = filePath;
    if (errorToThrow != null) throw errorToThrow!;
    return response as String;
  }
}
