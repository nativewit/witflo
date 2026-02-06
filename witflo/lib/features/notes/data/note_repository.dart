// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Encrypted Note Repository - CRUD for Encrypted Notes
// ═══════════════════════════════════════════════════════════════════════════
//
// SECURITY MODEL:
// - Notes are encrypted with ContentKey derived from VaultKey
// - Each note has its own ContentKey: HKDF(VK, "fyndo.content.{noteId}.v1")
// - Encrypted note is stored in /objects/ with hash-based path
// - Note index stores metadata (also encrypted)
//
// STORAGE:
// /objects/{hash[0:2]}/{hash[2:]} - Encrypted note content
// /refs/notes.jsonl.enc - Encrypted metadata index
//
// ENCRYPTION FORMAT:
// Each stored blob: [nonce (24)] [ciphertext] [auth tag (16)]
// Associated data: note ID (binds encryption to specific note)
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:typed_data';

import 'package:witflo_app/core/crypto/crypto.dart';
import 'package:witflo_app/core/vault/vault.dart';
import 'package:witflo_app/features/notes/models/note.dart';

/// Repository for encrypted note storage.
class EncryptedNoteRepository {
  final UnlockedVault _vault;
  final CryptoService _crypto;

  // In-memory cache of note metadata
  final Map<String, NoteMetadata> _metadataCache = {};
  bool _indexLoaded = false;

  EncryptedNoteRepository({
    required UnlockedVault vault,
    required CryptoService crypto,
  }) : _vault = vault,
       _crypto = crypto;

  /// Saves a note (creates or updates).
  Future<Note> save(Note note) async {
    // Derive content key for this note (cached in vault, do NOT dispose)
    final contentKey = _vault.deriveContentKey(note.id);

    // Serialize note to bytes
    final plaintext = SecureBytes(note.toBytes());

    // Create associated data (binds encryption to note ID)
    final aad = Uint8List.fromList(utf8.encode(note.id));

    // Encrypt note content
    final encrypted = _crypto.xchacha20.encrypt(
      plaintext: plaintext,
      key: contentKey,
      associatedData: aad,
    );

    // Compute content hash for storage path
    final hash = _crypto.blake3.hash(encrypted.ciphertext);

    // Store encrypted blob
    await _vault.filesystem.writeObject(hash.hex, encrypted.ciphertext);

    // Update note with content hash
    final updatedNote = note.copyWith(contentHash: hash.hex);

    // Update metadata index
    await _updateMetadataIndex(NoteMetadata.fromNote(updatedNote));

    return updatedNote;
  }

  /// Loads a note by ID.
  Future<Note?> load(String noteId) async {
    // Ensure index is loaded
    await _ensureIndexLoaded();

    // Get metadata to find content hash
    final metadata = _metadataCache[noteId];
    if (metadata == null || metadata.contentHash == null) {
      return null;
    }

    // Read encrypted blob
    final encryptedBytes = await _vault.filesystem.readObject(
      metadata.contentHash!,
    );
    if (encryptedBytes == null) {
      return null;
    }

    // Derive content key (cached in vault, do NOT dispose)
    final contentKey = _vault.deriveContentKey(noteId);

    // Create AAD for verification
    final aad = Uint8List.fromList(utf8.encode(noteId));

    // Decrypt
    final plaintext = _crypto.xchacha20.decrypt(
      ciphertext: Uint8List.fromList(encryptedBytes),
      key: contentKey,
      associatedData: aad,
    );

    try {
      final note = Note.fromBytes(Uint8List.fromList(plaintext.unsafeBytes));
      return note;
    } finally {
      plaintext.dispose();
    }
  }

  /// Deletes a note permanently.
  Future<void> delete(String noteId) async {
    await _ensureIndexLoaded();

    // Remove from metadata cache
    final metadata = _metadataCache.remove(noteId);

    // Note: We don't delete the object blob because:
    // 1. It might be referenced by sync state
    // 2. Garbage collection should handle orphaned blobs
    // 3. This is safer for recovery

    // Persist index update
    await _persistMetadataIndex();

    if (metadata != null) {
      // Optionally mark for garbage collection
      // await _markForGc(metadata.contentHash);
    }
  }

  /// Lists all note metadata.
  Future<List<NoteMetadata>> listAll() async {
    await _ensureIndexLoaded();
    return _metadataCache.values.toList();
  }

  /// Lists notes in a notebook.
  Future<List<NoteMetadata>> listByNotebook(String? notebookId) async {
    await _ensureIndexLoaded();
    return _metadataCache.values
        .where((m) => m.notebookId == notebookId && !m.isTrashed)
        .toList();
  }

  /// Lists notes with a specific tag.
  Future<List<NoteMetadata>> listByTag(String tag) async {
    await _ensureIndexLoaded();
    return _metadataCache.values
        .where((m) => m.tags.contains(tag) && !m.isTrashed)
        .toList();
  }

  /// Lists trashed notes.
  Future<List<NoteMetadata>> listTrashed() async {
    await _ensureIndexLoaded();
    return _metadataCache.values.where((m) => m.isTrashed).toList();
  }

  /// Searches notes by text (requires search index - basic implementation).
  Future<List<NoteMetadata>> searchByTitle(String query) async {
    await _ensureIndexLoaded();
    final lowerQuery = query.toLowerCase();
    return _metadataCache.values
        .where(
          (m) =>
              m.title.toLowerCase().contains(lowerQuery) ||
              (m.preview?.toLowerCase().contains(lowerQuery) ?? false),
        )
        .where((m) => !m.isTrashed)
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIVE FILE SYNC SUPPORT - Phase 2
  // ═══════════════════════════════════════════════════════════════════════════

  /// Exposes metadata cache for VaultReloadService.
  ///
  /// This allows the reload service to update the cache when index files
  /// change externally (e.g., from cloud sync).
  Map<String, NoteMetadata> get metadataCache => _metadataCache;

  /// Reloads the note index from disk.
  ///
  /// Call this when the index file changes externally (detected by file watcher).
  /// This will decrypt and reload the entire index, replacing the cache.
  ///
  /// Returns true if successful, false if the index doesn't exist or is corrupted.
  Future<bool> reloadIndex() async {
    try {
      // Clear the loaded flag to force reload
      _indexLoaded = false;
      _metadataCache.clear();

      // Load fresh from disk
      await _ensureIndexLoaded();
      return true;
    } catch (e) {
      print('Error reloading notes index: $e');
      return false;
    }
  }

  /// Gets active (non-trashed, non-archived) notes.
  ///
  /// This is the primary query for displaying notes in the main view.
  Future<List<NoteMetadata>> getActiveNotes() async {
    await _ensureIndexLoaded();
    return _metadataCache.values
        .where((m) => !m.isTrashed && !m.isArchived)
        .toList();
  }

  /// Gets pinned notes (excluding trashed/archived).
  Future<List<NoteMetadata>> getPinnedNotes() async {
    await _ensureIndexLoaded();
    return _metadataCache.values
        .where((m) => m.isPinned && !m.isTrashed && !m.isArchived)
        .toList();
  }

  /// Gets archived notes (excluding trashed).
  Future<List<NoteMetadata>> getArchivedNotes() async {
    await _ensureIndexLoaded();
    return _metadataCache.values
        .where((m) => m.isArchived && !m.isTrashed)
        .toList();
  }

  /// Gets notes by notebook ID (excluding trashed).
  /// Pass null to get notes without a notebook.
  Future<List<NoteMetadata>> getNotesByNotebook(String? notebookId) async {
    await _ensureIndexLoaded();
    return _metadataCache.values
        .where((m) => m.notebookId == notebookId && !m.isTrashed)
        .toList();
  }

  /// Gets notes by tag (excluding trashed).
  Future<List<NoteMetadata>> getNotesByTag(String tag) async {
    await _ensureIndexLoaded();
    return _metadataCache.values
        .where((m) => m.tags.contains(tag) && !m.isTrashed)
        .toList();
  }

  /// Gets total note count.
  Future<int> getNoteCount() async {
    await _ensureIndexLoaded();
    return _metadataCache.length;
  }

  /// Ensures the metadata index is loaded.
  Future<void> _ensureIndexLoaded() async {
    if (_indexLoaded) return;

    final indexBytes = await _vault.filesystem.readIfExists(
      _vault.filesystem.paths.notesIndex,
    );

    if (indexBytes == null) {
      _indexLoaded = true;
      return;
    }

    // Derive index encryption key (cached in vault, do NOT dispose)
    final indexKey = _vault.deriveSearchIndexKey();

    // Decrypt index
    final plaintext = _crypto.xchacha20.decrypt(
      ciphertext: Uint8List.fromList(indexBytes),
      key: indexKey,
    );

    try {
      // Parse JSONL format
      final lines = utf8.decode(plaintext.unsafeBytes).split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final metadata = NoteMetadata.fromJson(
          jsonDecode(line) as Map<String, dynamic>,
        );
        _metadataCache[metadata.id] = metadata;
      }
    } finally {
      plaintext.dispose();
    }

    _indexLoaded = true;
  }

  /// Updates metadata in the index.
  Future<void> _updateMetadataIndex(NoteMetadata metadata) async {
    await _ensureIndexLoaded();
    _metadataCache[metadata.id] = metadata;
    await _persistMetadataIndex();
  }

  /// Persists the metadata index to disk.
  Future<void> _persistMetadataIndex() async {
    // Build JSONL content
    final lines = _metadataCache.values
        .map((m) => jsonEncode(m.toJson()))
        .join('\n');

    final plaintext = SecureBytes(Uint8List.fromList(utf8.encode(lines)));

    // Derive index key (cached in vault, do NOT dispose)
    final indexKey = _vault.deriveSearchIndexKey();

    // Encrypt
    final encrypted = _crypto.xchacha20.encrypt(
      plaintext: plaintext,
      key: indexKey,
    );

    // Write atomically
    await _vault.filesystem.writeAtomic(
      _vault.filesystem.paths.notesIndex,
      encrypted.ciphertext,
    );
  }

  /// Gets statistics about stored notes.
  Future<NoteStats> getStats() async {
    await _ensureIndexLoaded();

    var total = 0;
    var active = 0;
    var archived = 0;
    var trashed = 0;
    var pinned = 0;

    for (final m in _metadataCache.values) {
      total++;
      if (m.isTrashed) {
        trashed++;
      } else if (m.isArchived) {
        archived++;
      } else {
        active++;
      }
      if (m.isPinned && !m.isTrashed && !m.isArchived) {
        pinned++;
      }
    }

    return NoteStats(
      total: total,
      active: active,
      archived: archived,
      trashed: trashed,
      pinned: pinned,
    );
  }
}

/// Statistics about notes in the vault.
class NoteStats {
  final int total;
  final int active;
  final int archived;
  final int trashed;
  final int pinned;

  const NoteStats({
    required this.total,
    required this.active,
    required this.archived,
    required this.trashed,
    required this.pinned,
  });
}
