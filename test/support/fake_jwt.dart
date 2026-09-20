import 'dart:convert';

/// A syntactically valid (unsigned) JWT carrying the given `sub` claim —
/// enough for `JwtDecoder.decode()` to parse, without needing a real
/// signature or issuer. AuthSession reads `sub` to know which user id to
/// fetch the profile for right after login/refresh.
String fakeJwt(String sub) {
  final payload = base64Encode(utf8.encode(jsonEncode({'sub': sub})));
  return 'header.$payload.signature';
}
