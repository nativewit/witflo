// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Platform Initialization - Native (iOS, Android, macOS, Linux, Windows)
// ═══════════════════════════════════════════════════════════════════════════
//
// Native platform initialization:
// - Initialize Drift database with SQLite
// - Use path_provider for file paths
// - Initialize native storage provider
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:witflo_app/platform/database/drift/database_providers.dart';
import 'package:witflo_app/platform/storage/native_storage.dart';
import 'package:witflo_app/platform/storage/storage_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

/// Initialize platform-specific dependencies for native platforms.
Future<void> initializePlatform() async {
  // Apply workaround for old Android versions
  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  }

  // Initialize storage provider
  final storage = NativeStorageProvider();
  await storage.initialize();
  setStorageProvider(storage);

  // Initialize Drift database
  await initializeDatabase();
}

/// Get the application documents directory path.
Future<String> getAppDocumentsPath() async {
  final appDir = await getApplicationDocumentsDirectory();
  final vaultDir = Directory('${appDir.path}/fyndo_vault');
  if (!await vaultDir.exists()) {
    await vaultDir.create(recursive: true);
  }
  return vaultDir.path;
}

/// Check if running on web.
bool get isWeb => false;
