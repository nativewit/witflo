// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Vault Export Providers
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witflo_app/features/vault/services/vault_export_service.dart';
import 'package:witflo_app/providers/note_providers.dart';
import 'package:witflo_app/providers/notebook_providers.dart';

/// Provider for vault export service
final vaultExportServiceProvider = Provider<VaultExportService>((ref) {
  return VaultExportService();
});

/// Notifier for export operations
class VaultExportNotifier extends StateNotifier<AsyncValue<ExportResult?>> {
  final Ref _ref;

  VaultExportNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Exports a vault to the specified directory
  Future<ExportResult> exportVault({
    required String vaultId,
    required String exportPath,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Get unlocked vault
      final vault = await _ref.read(unlockedActiveVaultProvider.future);

      // Get note repository
      final noteRepository = await _ref.read(noteRepositoryProvider.future);

      // Get notebooks
      final notebooksState = await _ref.read(notebooksProvider.future);
      final notebooks = notebooksState.notebooks.toList();

      // Perform export
      final exportService = _ref.read(vaultExportServiceProvider);
      final result = await exportService.exportVault(
        vault: vault,
        exportPath: exportPath,
        noteRepository: noteRepository,
        notebooks: notebooks,
      );

      state = AsyncValue.data(result);
      return result;
    } catch (e, stack) {
      final result = ExportResult.failure('Export failed: $e');
      state = AsyncValue.error(e, stack);
      return result;
    }
  }
}

/// Provider for export operations
final vaultExportProvider =
    StateNotifierProvider<VaultExportNotifier, AsyncValue<ExportResult?>>(
      (ref) => VaultExportNotifier(ref),
    );
