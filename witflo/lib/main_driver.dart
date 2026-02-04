// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Driver Entry Point - For Flutter Driver testing
// ═══════════════════════════════════════════════════════════════════════════
//
// This entry point enables Flutter Driver for automated UI testing.
// Use: flutter run --target=lib/main_driver.dart
//
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter_driver/driver_extension.dart';
import 'main.dart' as app;

void main() {
  // Enable Flutter Driver extension
  enableFlutterDriverExtension();

  // Run the main app
  app.main();
}
