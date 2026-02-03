// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Encrypted Notebook Repository - CRUD for Encrypted Notebooks
// ═══════════════════════════════════════════════════════════════════════════
//
// SECURITY MODEL:
// - Notebooks are encrypted with SearchIndexKey derived from VaultKey
// - SearchIndexKey: HKDF(VK, "fyndo.search_index.v1")
// - Notebook metadata stored in /refs/notebooks.jsonl.enc
//
// STORAGE:
// /refs/notebooks.jsonl.enc - Encrypted notebook metadata (JSONL format)
//
// ENCRYPTION FORMAT:
// File: [nonce (24)] [ciphertext] [auth tag (16)]
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:typed_data';

import 'package:fyndo_app/core/crypto/crypto.dart';
import 'package:fyndo_app/core/vault/vault.dart';
import 'package:fyndo_app/features/notes/models/notebook.dart';

/// Repository for encrypted notebook storage.
class EncryptedNotebookRepository {
  final UnlockedVault _vault;
  final CryptoService _crypto;

  // In-memory cache of notebooks
  final Map<String, Notebook> _notebookCache = {};
  bool _indexLoaded = false;

  EncryptedNotebookRepository({
    required UnlockedVault vault,
    required CryptoService crypto,
  }) : _vault = vault,
       _crypto = crypto;

  /// Saves a notebook (creates or updates).
  Future<Notebook> save(Notebook notebook) async {
    await _ensureIndexLoaded();

    // Update notebook in cache with modifiedAt timestamp
    final updatedNotebook = notebook.copyWith(
      modifiedAt: DateTime.now().toUtc(),
    );
    _notebookCache[updatedNotebook.id] = updatedNotebook;

    // Persist to disk
    await _persistIndex();

    return updatedNotebook;
  }

  /// Loads a notebook by ID.
  Future<Notebook?> load(String notebookId) async {
    await _ensureIndexLoaded();
    return _notebookCache[notebookId];
  }

  /// Deletes a notebook permanently.
  Future<void> delete(String notebookId) async {
    await _ensureIndexLoaded();

    // Remove from cache
    _notebookCache.remove(notebookId);

    // Persist index update
    await _persistIndex();
  }

  /// Lists all notebooks in the vault.
  Future<List<Notebook>> listAll() async {
    await _ensureIndexLoaded();
    return _notebookCache.values.toList();
  }

  /// Lists active (non-archived) notebooks.
  Future<List<Notebook>> listActive() async {
    await _ensureIndexLoaded();
    return _notebookCache.values.where((n) => !n.isArchived).toList();
  }

  /// Lists archived notebooks.
  Future<List<Notebook>> listArchived() async {
    await _ensureIndexLoaded();
    return _notebookCache.values.where((n) => n.isArchived).toList();
  }

  /// Ensures the notebook index is loaded from disk.
  Future<void> _ensureIndexLoaded() async {
    if (_indexLoaded) return;

    final indexBytes = await _vault.filesystem.readIfExists(
      _vault.filesystem.paths.notebooksIndex,
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
        final notebook = Notebook.fromJson(
          jsonDecode(line) as Map<String, dynamic>,
        );
        _notebookCache[notebook.id] = notebook;
      }
    } finally {
      plaintext.dispose();
    }

    _indexLoaded = true;
  }

  /// Persists the notebook index to disk.
  Future<void> _persistIndex() async {
    // Build JSONL content
    final lines = _notebookCache.values
        .map((n) => jsonEncode(n.toJson()))
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
      _vault.filesystem.paths.notebooksIndex,
      encrypted.ciphertext,
    );
  }

  /// Gets count of notebooks.
  Future<int> count() async {
    await _ensureIndexLoaded();
    return _notebookCache.length;
  }

  /// Gets count of active notebooks.
  Future<int> countActive() async {
    await _ensureIndexLoaded();
    return _notebookCache.values.where((n) => !n.isArchived).length;
  }
}
