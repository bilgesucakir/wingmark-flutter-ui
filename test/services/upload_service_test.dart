import 'package:flutter_test/flutter_test.dart';
import 'package:wingmark_flutter/services/upload_service.dart';

import 'fake_api_client.dart';

void main() {
  test('uploadPhoto delegates to ApiClient.uploadPhoto and returns its URL',
      () async {
    final client = FakeApiClient()..response = '/uploads/abc.jpg';
    final service = UploadService(client);

    final url = await service.uploadPhoto('/tmp/photo.jpg');

    expect(client.lastUploadPath, '/tmp/photo.jpg');
    expect(url, '/uploads/abc.jpg');
  });
}
