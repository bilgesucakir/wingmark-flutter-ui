import 'package:wingmark_flutter/core/token_store.dart';

import 'fake_jwt.dart';

/// A TokenStore that keeps state in memory instead of the real secure
/// storage plugin (which needs platform channels unavailable in plain unit
/// tests), with a fully controllable refresh() instead of hitting the
/// network like the production implementation does.
class FakeTokenStore extends TokenStore {
  String? _fakeAccess;
  String? _fakeRefresh;
  bool refreshShouldSucceed = true;
  int refreshCallCount = 0;

  /// The `sub` claim baked into the JWT that a successful refresh() rotates
  /// in — AuthSession decodes this to know which user id to fetch.
  String refreshedSub = 'u1';

  @override
  String? get accessToken => _fakeAccess;

  @override
  String? get refreshToken => _fakeRefresh;

  @override
  bool get hasRefreshToken => _fakeRefresh != null;

  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    _fakeAccess = accessToken;
    _fakeRefresh = refreshToken;
  }

  @override
  Future<void> clear() async {
    _fakeAccess = null;
    _fakeRefresh = null;
  }

  @override
  Future<bool> refresh() async {
    refreshCallCount++;
    if (refreshShouldSucceed) {
      await save(
          accessToken: fakeJwt(refreshedSub), refreshToken: 'refreshed-refresh');
      return true;
    }
    await clear();
    return false;
  }
}
