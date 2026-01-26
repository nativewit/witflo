// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Platform Initialization - Web
// ═══════════════════════════════════════════════════════════════════════════
//
// Web-specific initialization:
// - Storage uses IndexedDB via web storage provider
// - Database uses Drift with sql.js (WASM SQLite)
// - Crypto uses sodium.js
// ═══════════════════════════════════════════════════════════════════════════

import 'package:fyndo_app/platform/database/drift/database_providers.dart';
import 'package:fyndo_app/platform/storage/storage_provider.dart';
import 'package:fyndo_app/platform/storage/web_storage.dart';

/// Initialize platform-specific dependencies for web.
Future<void> initializePlatform() async {
  // Initialize web storage
  final storage = WebStorageProvider();
  await storage.initialize();
  setStorageProvider(storage);

  // Initialize Drift database (uses sql.js on web)
  await initializeDatabase();
}

/// Get the application documents directory path.
/// On web, we use a virtual path since storage is IndexedDB-based.
Future<String> getAppDocumentsPath() async {
  return '/fyndo_vault';
}

/// Check if running on web.
bool get isWeb => true;
