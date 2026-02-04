// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Vault Consumer - Wrapper for Vault State
// ═══════════════════════════════════════════════════════════════════════════
//
// USAGE:
// VaultConsumer(
//   builder: (context, vaultState, child) {
//     if (vaultState.isUnlocked) return HomeView();
//     return UnlockView();
//   },
// )
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witflo_app/core/vault/vault_service.dart';
import 'package:witflo_app/providers/vault_providers.dart';

/// Consumer widget for vault state.
///
/// This widget wraps Riverpod's Consumer and provides vault state
/// through a builder pattern, keeping UI widgets pure and stateless.
class VaultConsumer extends ConsumerWidget {
  /// Builder function called with vault state.
  final Widget Function(
    BuildContext context,
    VaultState vaultState,
    Widget? child,
  )
  builder;

  /// Optional child widget that doesn't depend on vault state.
  final Widget? child;

  const VaultConsumer({super.key, required this.builder, this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultState = ref.watch(vaultProvider);
    return builder(context, vaultState, child);
  }
}

/// Consumer widget that only rebuilds on vault status changes.
class VaultStatusConsumer extends ConsumerWidget {
  /// Builder function called with vault status.
  final Widget Function(BuildContext context, VaultStatus status, Widget? child)
  builder;

  /// Optional child widget.
  final Widget? child;

  const VaultStatusConsumer({super.key, required this.builder, this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(vaultProvider.select((state) => state.status));
    return builder(context, status, child);
  }
}

/// Consumer widget that requires an unlocked vault.
///
/// Shows loading/error states automatically.
class UnlockedVaultConsumer extends ConsumerWidget {
  /// Builder function called when vault is unlocked.
  final Widget Function(
    BuildContext context,
    UnlockedVault vault,
    Widget? child,
  )
  builder;

  /// Widget to show when vault is locked.
  final Widget? lockedWidget;

  /// Widget to show when loading.
  final Widget? loadingWidget;

  /// Widget to show on error.
  final Widget Function(String error)? errorBuilder;

  /// Optional child widget.
  final Widget? child;

  const UnlockedVaultConsumer({
    super.key,
    required this.builder,
    this.lockedWidget,
    this.loadingWidget,
    this.errorBuilder,
    this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultState = ref.watch(vaultProvider);

    switch (vaultState.status) {
      case VaultStatus.unlocked:
        if (vaultState.vault != null) {
          return builder(context, vaultState.vault!, child);
        }
        return lockedWidget ?? const _DefaultLockedWidget();

      case VaultStatus.unlocking:
      case VaultStatus.creating:
        return loadingWidget ?? const _DefaultLoadingWidget();

      case VaultStatus.error:
        return errorBuilder?.call(vaultState.error ?? 'Unknown error') ??
            _DefaultErrorWidget(error: vaultState.error ?? 'Unknown error');

      case VaultStatus.uninitialized:
      case VaultStatus.locked:
        return lockedWidget ?? const _DefaultLockedWidget();
    }
  }
}

/// Selector consumer for specific vault properties.
class VaultSelector<T> extends ConsumerWidget {
  /// Selector function to extract specific value from vault state.
  final T Function(VaultState state) selector;

  /// Builder function called with selected value.
  final Widget Function(BuildContext context, T value, Widget? child) builder;

  /// Optional child widget.
  final Widget? child;

  const VaultSelector({
    super.key,
    required this.selector,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(vaultProvider.select(selector));
    return builder(context, value, child);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DEFAULT WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _DefaultLockedWidget extends StatelessWidget {
  const _DefaultLockedWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 48),
          SizedBox(height: 16),
          Text('Vault is locked'),
        ],
      ),
    );
  }
}

class _DefaultLoadingWidget extends StatelessWidget {
  const _DefaultLoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading...'),
        ],
      ),
    );
  }
}

class _DefaultErrorWidget extends StatelessWidget {
  final String error;

  const _DefaultErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text('Error', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
