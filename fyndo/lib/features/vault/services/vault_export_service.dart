// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Vault Export Service - Export vault data in unencrypted format
// ═══════════════════════════════════════════════════════════════════════════
//
// ⚠️ SECURITY WARNING:
// This service exports vault data WITHOUT ENCRYPTION. The exported data is
// highly sensitive and should be stored securely. Users should be warned
// about the security implications before using this feature.
//
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

import 'package:fyndo_app/core/logging/app_logger.dart';
import 'package:fyndo_app/core/vault/vault_service.dart';
import 'package:fyndo_app/features/notes/data/note_repository.dart';
import 'package:fyndo_app/features/notes/models/note.dart';
import 'package:fyndo_app/providers/notebook_providers.dart';
import 'package:path/path.dart' as p;

/// Result of an export operation.
class ExportResult {
  final bool success;
  final String? error;
  final String? exportPath;
  final int notebookCount;
  final int noteCount;

  ExportResult.success({
    required this.exportPath,
    required this.notebookCount,
    required this.noteCount,
  }) : success = true,
       error = null;

  ExportResult.failure(this.error)
    : success = false,
      exportPath = null,
      notebookCount = 0,
      noteCount = 0;
}

/// Service for exporting vault data in unencrypted format.
///
/// ⚠️ WARNING: Exported data is NOT ENCRYPTED and should be handled carefully.
class VaultExportService {
  VaultExportService();

  /// Exports a vault to a specified directory in unencrypted JSON format.
  ///
  /// [vault] - The unlocked vault to export
  /// [exportPath] - Directory where export files will be created
  /// [noteRepository] - Repository for accessing notes
  /// [notebooks] - List of notebooks to export
  ///
  /// Returns [ExportResult] with export status and counts.
  Future<ExportResult> exportVault({
    required UnlockedVault vault,
    required String exportPath,
    required EncryptedNoteRepository noteRepository,
    required List<Notebook> notebooks,
  }) async {
    try {
      // Create export directory
      final exportDir = Directory(exportPath);
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      // 1. Export vault metadata
      await _exportVaultMetadata(vault, exportPath);

      // 2. Export notebooks
      await _exportNotebooks(notebooks, exportPath);

      // 3. Export notes
      final noteCount = await _exportNotes(noteRepository, exportPath);

      return ExportResult.success(
        exportPath: exportPath,
        notebookCount: notebooks.length,
        noteCount: noteCount,
      );
    } catch (e, stack) {
      final log = AppLogger.get('VaultExport');
      log.error('Export failed', error: e, stackTrace: stack);
      return ExportResult.failure('Export failed: $e');
    }
  }

  /// Exports vault metadata to vault-metadata.json
  Future<void> _exportVaultMetadata(
    UnlockedVault vault,
    String exportPath,
  ) async {
    final metadataFile = File(p.join(exportPath, 'vault-metadata.json'));

    final metadata = {
      'vault_id': vault.header.vaultId,
      'exported_at': DateTime.now().toIso8601String(),
    };

    await metadataFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(metadata),
    );

    final log = AppLogger.get('VaultExport');
    log.debug('Exported vault metadata');
  }

  /// Exports notebooks to notebooks.json
  Future<void> _exportNotebooks(
    List<Notebook> notebooks,
    String exportPath,
  ) async {
    final notebooksFile = File(p.join(exportPath, 'notebooks.json'));

    final notebooksData = notebooks.map((notebook) {
      return {
        'id': notebook.id,
        'name': notebook.name,
        'description': notebook.description,
        'vault_id': notebook.vaultId,
        'color': notebook.color,
        'icon': notebook.icon,
        'created_at': notebook.createdAt.toIso8601String(),
        'modified_at': notebook.modifiedAt.toIso8601String(),
        'is_archived': notebook.isArchived,
      };
    }).toList();

    await notebooksFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(notebooksData),
    );

    final log = AppLogger.get('VaultExport');
    log.debug('Exported ${notebooks.length} notebooks');
  }

  /// Exports all notes to individual JSON files in notes/ directory
  Future<int> _exportNotes(
    EncryptedNoteRepository noteRepository,
    String exportPath,
  ) async {
    // Create notes directory
    final notesDir = Directory(p.join(exportPath, 'notes'));
    if (!await notesDir.exists()) {
      await notesDir.create(recursive: true);
    }

    // Get all notes metadata
    final allMetadata = await noteRepository.listAll();
    final log = AppLogger.get('VaultExport');

    // Export each note
    int exportedCount = 0;
    for (final metadata in allMetadata) {
      try {
        // Load full note
        final note = await noteRepository.load(metadata.id);
        if (note == null) {
          log.warning('Note ${metadata.id} not found, skipping');
          continue;
        }

        // Create note JSON
        final noteData = _noteToJson(note, metadata);

        // Write to file
        final noteFile = File(p.join(notesDir.path, '${note.id}.json'));
        await noteFile.writeAsString(
          const JsonEncoder.withIndent('  ').convert(noteData),
        );

        exportedCount++;
      } catch (e) {
        log.warning('Failed to export note ${metadata.id}: $e');
      }
    }

    log.debug('Exported $exportedCount notes');
    return exportedCount;
  }

  /// Converts a note to JSON format
  Map<String, dynamic> _noteToJson(Note note, NoteMetadata metadata) {
    return {
      'id': note.id,
      'title': note.title,
      'content': note.content,
      'notebook_id': note.notebookId,
      'tags': note.tags.toList(), // Convert BuiltList to List
      'created_at': note.createdAt.toIso8601String(),
      'modified_at': note.modifiedAt.toIso8601String(),
      'is_pinned': note.isPinned,
      'is_archived': note.isArchived,
      'is_trashed': note.isTrashed,
      'metadata': {'content_hash': metadata.contentHash},
    };
  }
}
