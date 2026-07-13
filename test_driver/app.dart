/// Driver entrypoint.
///
/// Runs the same app as `lib/main.dart` with the Flutter Driver extension
/// enabled, so tooling can drive the UI on a device:
///
///   flutter run -t test_driver/app.dart
///
/// Release builds always target `lib/main.dart`, so this never ships.
library;

import 'package:chungmo/main.dart' as app;
import 'package:flutter_driver/driver_extension.dart';

void main() {
  enableFlutterDriverExtension();
  app.main();
}
