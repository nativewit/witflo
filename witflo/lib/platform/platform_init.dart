// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Platform Initialization - Default/Stub
// ═══════════════════════════════════════════════════════════════════════════
//
// This is the default stub - actual implementations are in
// platform_init_web.dart and platform_init_native.dart

import 'package:witflo_app/platform/database/drift/database_providers.dart';
import 'package:witflo_app/platform/storage/storage_provider.dart';
import 'package:witflo_app/platform/storage/web_storage.dart';

/// Initialize platform-specific dependencies.
/// This is the default stub that uses in-memory implementations.
Future<void> initializePlatform() async {
  // Use in-memory storage by default
  final storage = WebStorageProvider();
  await storage.initialize();
  setStorageProvider(storage);

  // Initialize Drift database
  await initializeDatabase();
}

/// Get the application documents directory path.
Future<String> getAppDocumentsPath() async {
  return '/witflo_vault';
}

/// Check if running on web.
bool get isWeb => false;
