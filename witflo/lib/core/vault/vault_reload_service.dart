// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Vault Reload Service - Reload Index Files from Filesystem
// ═══════════════════════════════════════════════════════════════════════════
//
// PURPOSE:
// Handles reloading encrypted index files from the filesystem and updating
// repository caches. Used when external changes are detected by file watchers.
//
// RESPONSIBILITIES:
// 1. Read encrypted index files from disk
// 2. Decrypt using vault's search index key
// 3. Parse JSONL format
// 4. Update repository metadata caches
// 5. Handle missing/corrupted files gracefully
//
// USAGE:
// final reloadService = VaultReloadService(crypto: cryptoService);
//
// // Reload notes index
// await reloadService.reloadNotesIndex(
//   vault: unlockedVault,
//   metadataCache: noteRepository.metadataCache,
// );
//
// NOTES:
// - Designed to be called from VaultFileWatcher when index files change
// - Does not trigger UI updates (that's handled by Riverpod invalidation)
// - Handles decryption errors and corrupted files gracefully
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:typed_data';
import 'package:witflo_app/core/crypto/crypto.dart';
import 'package:witflo_app/core/vault/vault_service.dart';
import 'package:witflo_app/features/notes/models/note.dart';
import 'package:witflo_app/features/notes/models/notebook.dart';

/// Service for reloading encrypted index files into repository caches.
class VaultReloadService {
  final CryptoService _crypto;

  VaultReloadService({required CryptoService crypto}) : _crypto = crypto;

  /// Reload notes index from filesystem into metadata cache.
  ///
  /// Returns true if successful, false if file doesn't exist or is corrupted.
  Future<bool> reloadNotesIndex(
    UnlockedVault vault,
    Map<String, NoteMetadata> metadataCache,
  ) async {
    try {
      final indexPath = vault.filesystem.paths.notesIndex;
      final indexBytes = await vault.filesystem.readIfExists(indexPath);

      if (indexBytes == null) {
        // Index file doesn't exist yet - clear cache
        metadataCache.clear();
        return true;
      }

      // Derive index encryption key (cached in vault, do NOT dispose)
      final indexKey = vault.deriveSearchIndexKey();

      // Decrypt index
      final plaintext = _crypto.xchacha20.decrypt(
        ciphertext: Uint8List.fromList(indexBytes),
        key: indexKey,
      );

      try {
        // Clear existing cache
        metadataCache.clear();

        // Parse JSONL format
        final lines = utf8.decode(plaintext.unsafeBytes).split('\n');
        for (final line in lines) {
          if (line.trim().isEmpty) continue;

          try {
            final metadata = NoteMetadata.fromJson(
              jsonDecode(line) as Map<String, dynamic>,
            );
            metadataCache[metadata.id] = metadata;
          } catch (e) {
            // Log but continue processing other entries
            print('Warning: Failed to parse note metadata line: $e');
          }
        }

        return true;
      } finally {
        plaintext.dispose();
      }
    } catch (e, stack) {
      print('Error reloading notes index: $e');
      print(stack);
      return false;
    }
  }

  /// Reload notebooks index from filesystem into metadata cache.
  ///
  /// Returns true if successful, false if file doesn't exist or is corrupted.
  Future<bool> reloadNotebooksIndex(
    UnlockedVault vault,
    Map<String, Notebook> notebookCache,
  ) async {
    try {
      final indexPath = vault.filesystem.paths.notebooksIndex;
      final indexBytes = await vault.filesystem.readIfExists(indexPath);

      if (indexBytes == null) {
        // Index file doesn't exist yet - clear cache
        notebookCache.clear();
        return true;
      }

      // Derive index encryption key (cached in vault, do NOT dispose)
      final indexKey = vault.deriveSearchIndexKey();

      // Decrypt index
      final plaintext = _crypto.xchacha20.decrypt(
        ciphertext: Uint8List.fromList(indexBytes),
        key: indexKey,
      );

      try {
        // Clear existing cache
        notebookCache.clear();

        // Parse JSONL format
        final lines = utf8.decode(plaintext.unsafeBytes).split('\n');
        for (final line in lines) {
          if (line.trim().isEmpty) continue;

          try {
            final notebook = Notebook.fromJson(
              jsonDecode(line) as Map<String, dynamic>,
            );
            notebookCache[notebook.id] = notebook;
          } catch (e) {
            // Log but continue processing other entries
            print('Warning: Failed to parse notebook line: $e');
          }
        }

        return true;
      } finally {
        plaintext.dispose();
      }
    } catch (e, stack) {
      print('Error reloading notebooks index: $e');
      print(stack);
      return false;
    }
  }

  /// Reload tags index from filesystem.
  ///
  /// Tags are stored as a simple JSON array of tag names.
  /// Returns the list of tags, or empty list on error.
  Future<List<String>> reloadTagsIndex(UnlockedVault vault) async {
    try {
      final indexPath = vault.filesystem.paths.tagsIndex;
      final indexBytes = await vault.filesystem.readIfExists(indexPath);

      if (indexBytes == null) {
        return [];
      }

      // Derive index encryption key (cached in vault, do NOT dispose)
      final indexKey = vault.deriveSearchIndexKey();

      // Decrypt index
      final plaintext = _crypto.xchacha20.decrypt(
        ciphertext: Uint8List.fromList(indexBytes),
        key: indexKey,
      );

      try {
        final json = jsonDecode(utf8.decode(plaintext.unsafeBytes));
        if (json is List) {
          return json.cast<String>();
        }
        return [];
      } finally {
        plaintext.dispose();
      }
    } catch (e, stack) {
      print('Error reloading tags index: $e');
      print(stack);
      return [];
    }
  }
}
