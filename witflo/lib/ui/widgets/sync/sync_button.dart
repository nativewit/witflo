// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Sync Button - Manual Sync Trigger Widget
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witflo_app/core/logging/app_logger.dart';
import 'package:witflo_app/core/sync/sync_service.dart';
import 'package:witflo_app/providers/sync_providers.dart';

/// Sync button widget that triggers manual sync and shows sync state.
///
/// Features:
/// - Shows animated sync icon when syncing
/// - Displays sync state (idle/syncing/error/offline)
/// - Shows success/error messages in snackbar
/// - Disabled when offline or already syncing
///
/// **Usage:**
/// ```dart
/// AppBar(
///   actions: [
///     const SyncButton(),
///   ],
/// )
/// ```
class SyncButton extends ConsumerStatefulWidget {
  const SyncButton({super.key});

  @override
  ConsumerState<SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends ConsumerState<SyncButton>
    with SingleTickerProviderStateMixin {
  final _log = AppLogger.get('SyncButton');
  late AnimationController _controller;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSync() async {
    if (_isSyncing) {
      _log.debug('Sync already in progress, ignoring tap');
      return;
    }

    setState(() => _isSyncing = true);
    _controller.repeat();

    try {
      _log.info('User triggered manual sync');
      final triggerSync = ref.read(triggerSyncProvider);
      final result = await triggerSync();

      if (!mounted) return;

      if (result.success) {
        _showSnackBar(
          'Synced ${result.pulled} operations in ${result.duration.inMilliseconds}ms',
          isError: false,
        );
        _log.info('Sync completed successfully: $result');
      } else {
        _showSnackBar(
          'Sync failed: ${result.error ?? "Unknown error"}',
          isError: true,
        );
        _log.error('Sync failed', error: result.error ?? 'Unknown error');
      }
    } catch (e, st) {
      _log.error('Error during manual sync', error: e, stackTrace: st);
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
        _controller.stop();
        _controller.reset();
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primaryContainer,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch sync state to update button appearance
    final syncStateAsync = ref.watch(syncStateProvider);

    return syncStateAsync.when(
      data: (state) {
        final isOffline = state == SyncState.offline;
        final hasError = state == SyncState.error;

        return IconButton(
          icon: RotationTransition(
            turns: _controller,
            child: Icon(
              _isSyncing
                  ? Icons.sync
                  : hasError
                  ? Icons.sync_problem
                  : isOffline
                  ? Icons.cloud_off
                  : Icons.cloud_done,
              color: hasError
                  ? Theme.of(context).colorScheme.error
                  : _isSyncing
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
          ),
          onPressed: (isOffline || _isSyncing) ? null : _handleSync,
          tooltip: _getSyncTooltip(state),
        );
      },
      loading: () => IconButton(
        icon: const Icon(Icons.cloud_queue),
        onPressed: null,
        tooltip: 'Loading sync state...',
      ),
      error: (error, stackTrace) {
        // Log the error for debugging
        _log.error(
          'SyncButton error state',
          error: error,
          stackTrace: stackTrace,
        );

        // Gracefully handle cases where sync is not available yet
        // (e.g., no vault unlocked, workspace just initialized)
        final errorStr = error.toString();
        final isVaultNotReady =
            errorStr.contains('No vaults available') ||
            errorStr.contains('Workspace is not unlocked') ||
            errorStr.contains('Workspace must be unlocked');

        if (isVaultNotReady) {
          _log.debug('Sync not available yet (no vault ready): $error');
          // Don't show error icon, just show disabled state
          return IconButton(
            icon: const Icon(Icons.cloud_off),
            onPressed: null,
            tooltip: 'Sync not available',
          );
        }

        // For other errors, show error icon and log it
        _log.warning('Unexpected sync error: $error');
        return IconButton(
          icon: Icon(
            Icons.cloud_off,
            color: Theme.of(context).colorScheme.error,
          ),
          onPressed: null,
          tooltip: 'Sync error: $error',
        );
      },
    );
  }

  String _getSyncTooltip(SyncState state) {
    if (_isSyncing) return 'Syncing...';
    switch (state) {
      case SyncState.idle:
        return 'Sync';
      case SyncState.syncing:
        return 'Syncing...';
      case SyncState.error:
        return 'Sync error - tap to retry';
      case SyncState.offline:
        return 'Offline - sync unavailable';
    }
  }
}
