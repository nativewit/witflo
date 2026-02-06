// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Sync Providers - Riverpod State Management for Sync
// ═══════════════════════════════════════════════════════════════════════════
//
// ARCHITECTURE:
// - SyncService is vault-specific (one instance per unlocked vault)
// - Automatically initializes when vault is unlocked
// - Automatically disposes when vault is locked
// - Uses workspace-based architecture from spec-002
//
// USAGE:
// ```dart
// // Get sync service for active vault
// final syncService = ref.watch(syncServiceProvider);
//
// // Trigger manual sync
// await syncService.sync();
//
// // Get sync state
// final state = syncService.state;
// ```
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witflo_app/core/logging/app_logger.dart';
import 'package:witflo_app/core/sync/sync_operation.dart';
import 'package:witflo_app/core/sync/sync_service.dart';
import 'package:witflo_app/providers/crypto_providers.dart';
import 'package:witflo_app/providers/device_identity_provider.dart';
import 'package:witflo_app/providers/note_providers.dart';
import 'package:witflo_app/providers/notebook_providers.dart';

/// Provider for the sync service for the active vault.
///
/// This provider:
/// - Creates a SyncService instance for the active vault
/// - Initializes the service on first access
/// - Auto-disposes when the vault is locked
/// - Provides access to sync operations and state
///
/// **Example Usage:**
/// ```dart
/// // Watch sync state
/// ref.watch(syncServiceProvider).when(
///   data: (syncService) => Text('Sync state: ${syncService.state}'),
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => Text('Error: $e'),
/// );
///
/// // Trigger manual sync
/// final syncService = await ref.read(syncServiceProvider.future);
/// await syncService.sync();
/// ```
final syncServiceProvider = FutureProvider.autoDispose<SyncService>((
  ref,
) async {
  final log = AppLogger.get('syncServiceProvider');
  log.debug('Creating SyncService for active vault');

  // Get dependencies
  final vault = await ref.watch(unlockedActiveVaultProvider.future);
  final crypto = ref.watch(cryptoServiceProvider);
  final noteRepo = await ref.watch(noteRepositoryProvider.future);
  final notebookRepo = await ref.watch(notebookRepositoryProvider.future);
  final deviceIdentity = await ref.watch(deviceIdentityProvider.future);

  // Create sync service
  final syncService = SyncService(
    vault: vault,
    crypto: crypto,
    deviceIdentity: deviceIdentity,
    noteRepository: noteRepo,
    notebookRepository: notebookRepo,
  );

  // Initialize the service
  await syncService.initialize();

  log.info('SyncService initialized for vault: ${vault.header.vaultId}');

  // Cleanup on dispose
  ref.onDispose(() async {
    log.debug('Disposing SyncService for vault: ${vault.header.vaultId}');
    await syncService.dispose();
  });

  return syncService;
});

/// Provider for sync state (idle, syncing, error, offline).
///
/// This provider watches the sync service and exposes only the state,
/// making it lightweight for UI components that only need to display sync status.
///
/// **Example Usage:**
/// ```dart
/// final syncState = ref.watch(syncStateProvider);
/// syncState.when(
///   data: (state) => Icon(
///     state == SyncState.syncing ? Icons.sync : Icons.cloud_done,
///   ),
///   loading: () => SizedBox.shrink(),
///   error: (e, st) => Icon(Icons.cloud_off),
/// );
/// ```
final syncStateProvider = FutureProvider.autoDispose<SyncState>((ref) async {
  final syncService = await ref.watch(syncServiceProvider.future);
  return syncService.state;
});

/// Provider for triggering manual sync.
///
/// This is a provider for a function that triggers sync and returns the result.
/// Use this when you want to trigger sync from a button or action.
///
/// **Example Usage:**
/// ```dart
/// // In a button's onPressed:
/// final triggerSync = ref.read(triggerSyncProvider);
/// final result = await triggerSync();
/// if (result.success) {
///   showSnackBar('Synced ${result.pulled} operations');
/// }
/// ```
final triggerSyncProvider = Provider.autoDispose<Future<SyncResult> Function()>((
  ref,
) {
  return () async {
    final log = AppLogger.get('triggerSync');
    log.info('Manual sync triggered');

    final syncService = await ref.read(syncServiceProvider.future);
    final result = await syncService.sync();

    if (result.success) {
      log.info(
        'Sync completed: pushed=${result.pushed}, pulled=${result.pulled}, duration=${result.duration}',
      );
    } else {
      log.error('Sync failed', error: result.error ?? 'Unknown error');
    }

    // Invalidate providers that depend on sync state
    ref.invalidate(syncStateProvider);

    return result;
  };
});

/// Provider for the sync cursor.
///
/// This provides read-only access to the current sync cursor,
/// useful for displaying sync progress in the UI.
///
/// **Example Usage:**
/// ```dart
/// final cursor = ref.watch(syncCursorProvider);
/// cursor.when(
///   data: (c) => Text('Synced ${c.syncedCount} operations'),
///   loading: () => Text('Loading...'),
///   error: (e, st) => Text('Error'),
/// );
/// ```
final syncCursorProvider = FutureProvider.autoDispose<SyncCursor>((ref) async {
  final syncService = await ref.watch(syncServiceProvider.future);
  return syncService.cursor;
});
