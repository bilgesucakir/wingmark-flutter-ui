import '../core/api_client.dart';

/// Wraps POST /api/uploads/photo (see UploadController.java) — a plain
/// multipart upload, not a presigned-URL flow. Returns a relative URL
/// ("/uploads/xxxx.jpg") to store as a bird log's photoUrl.
class UploadService {
  UploadService(this._client);

  final ApiClient _client;

  Future<String> uploadPhoto(String filePath) => _client.uploadPhoto(filePath);
}
