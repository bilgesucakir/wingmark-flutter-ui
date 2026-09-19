import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wingmark_flutter/app.dart';

void main() {
  testWidgets('App boots to the auth gate without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const WingmarkApp());

    // AuthSession.bootstrap() kicks off an async token-refresh call, so the
    // first frame should be the loading spinner rather than a crash.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
