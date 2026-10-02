import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Salva os screenshots do teste de integração em `screenshots/`.
Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final file = File('screenshots/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return true;
  },
);
