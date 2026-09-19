/// Deployed backend (see wingmark-backend/render.yaml). Render's starter plan
/// cold-starts a sleeping instance, so requests use a generous timeout below.
const String kApiBaseUrl = 'https://wingmark-backend.onrender.com';

/// Matches the Swift client's URLSessionConfiguration.timeoutIntervalForRequest,
/// which was bumped from the 60s default to cover Render cold starts.
const Duration kApiTimeout = Duration(seconds: 90);

/// Backend serves uploaded photos back as relative paths (e.g. "/uploads/x.jpg");
/// prepend this to display them.
String resolveMediaUrl(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return '$kApiBaseUrl${path.startsWith('/') ? path : '/$path'}';
}
