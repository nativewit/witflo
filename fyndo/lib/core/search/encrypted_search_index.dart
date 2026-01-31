// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Encrypted Search Index - Blind Token Search
// ═══════════════════════════════════════════════════════════════════════════
//
// SEARCH PHILOSOPHY:
// Search must work locally without revealing plaintext to any server.
// We use blind token hashing to enable search without decrypting all notes.
//
// BLIND TOKEN SEARCH:
// 1. When indexing a note:
//    - Extract tokens (words) from plaintext
//    - Hash each token with search key: HMAC(searchKey, token)
//    - Store: {hashedToken → [noteId1, noteId2, ...]}
//
// 2. When searching:
//    - Hash query tokens with same search key
//    - Look up hashed tokens in index
//    - Return matching note IDs
//    - Decrypt those notes to verify matches
//
// SECURITY PROPERTIES:
// - Index stores hashed tokens, not plaintext
// - Same token in different notes produces same hash (deterministic)
// - Without searchKey, index is meaningless
// - Index file is also encrypted at rest
//
// LIMITATIONS:
// - Exact token match only (no fuzzy search)
// - No substring search (would leak too much)
// - Semantic search requires separate encrypted embeddings
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:typed_data';

import 'package:fyndo_app/core/crypto/crypto.dart';
import 'package:fyndo_app/core/vault/vault.dart';

/// A blind search index entry.
class SearchIndexEntry {
  final String hashedToken;
  final Set<String> noteIds;

  SearchIndexEntry({required this.hashedToken, required this.noteIds});

  Map<String, dynamic> toJson() => {
    'hash': hashedToken,
    'notes': noteIds.toList(),
  };

  factory SearchIndexEntry.fromJson(Map<String, dynamic> json) {
    return SearchIndexEntry(
      hashedToken: json['hash'] as String,
      noteIds: (json['notes'] as List<dynamic>).cast<String>().toSet(),
    );
  }
}

/// Encrypted search index for blind token search.
class EncryptedSearchIndex {
  final UnlockedVault _vault;
  final CryptoService _crypto;

  // In-memory index: hashedToken → noteIds
  final Map<String, Set<String>> _index = {};

  // Token hash cache for performance
  final Map<String, String> _tokenHashCache = {};

  bool _loaded = false;

  EncryptedSearchIndex({
    required UnlockedVault vault,
    required CryptoService crypto,
  }) : _vault = vault,
       _crypto = crypto;

  /// Derives the search key from vault key.
  ContentKey _deriveSearchKey() {
    return _vault.deriveSearchIndexKey();
  }

  /// Hashes a token for blind search.
  String _hashToken(String token, ContentKey searchKey) {
    // Normalize: lowercase, trim
    final normalized = token.toLowerCase().trim();

    // Check cache
    if (_tokenHashCache.containsKey(normalized)) {
      return _tokenHashCache[normalized]!;
    }

    // Hash with search key using keyed BLAKE3
    final tokenBytes = Uint8List.fromList(utf8.encode(normalized));
    final hash = _crypto.blake3.keyedHash(tokenBytes, searchKey.material);

    // Use first 16 bytes (128 bits) as token hash
    final shortHash = hash.hex.substring(0, 32);
    _tokenHashCache[normalized] = shortHash;

    return shortHash;
  }

  /// Tokenizes text into searchable tokens.
  List<String> _tokenize(String text) {
    // Simple tokenization: split on whitespace and punctuation
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 2) // Skip very short tokens
        .toSet() // Deduplicate
        .toList();
  }

  /// Indexes a note.
  Future<void> indexNote({
    required String noteId,
    required String title,
    required String content,
    List<String>? tags,
  }) async {
    await _ensureLoaded();

    final searchKey = _deriveSearchKey();
    try {
      // Combine all searchable text
      final allText = [title, content, ...(tags ?? [])].join(' ');
      final tokens = _tokenize(allText);

      // Add to index
      for (final token in tokens) {
        final hashedToken = _hashToken(token, searchKey);
        _index.putIfAbsent(hashedToken, () => {});
        _index[hashedToken]!.add(noteId);
      }

      await _persist();
    } finally {
      searchKey.dispose();
    }
  }

  /// Removes a note from the index.
  Future<void> removeNote(String noteId) async {
    await _ensureLoaded();

    // Remove noteId from all entries
    for (final entry in _index.values) {
      entry.remove(noteId);
    }

    // Clean up empty entries
    _index.removeWhere((_, noteIds) => noteIds.isEmpty);

    await _persist();
  }

  /// Searches for notes matching all query tokens.
  Future<List<String>> search(String query) async {
    await _ensureLoaded();

    final searchKey = _deriveSearchKey();
    try {
      final queryTokens = _tokenize(query);
      if (queryTokens.isEmpty) return [];

      // Find notes matching each token
      List<Set<String>>? matchingSets;
      for (final token in queryTokens) {
        final hashedToken = _hashToken(token, searchKey);
        final noteIds = _index[hashedToken];

        if (noteIds == null || noteIds.isEmpty) {
          // If any token has no matches, result is empty
          return [];
        }

        if (matchingSets == null) {
          matchingSets = [noteIds];
        } else {
          matchingSets.add(noteIds);
        }
      }

      if (matchingSets == null || matchingSets.isEmpty) return [];

      // Intersect all sets (AND search)
      var result = matchingSets.first;
      for (final set in matchingSets.skip(1)) {
        result = result.intersection(set);
      }

      return result.toList();
    } finally {
      searchKey.dispose();
    }
  }

  /// Ensures index is loaded from disk.
  Future<void> _ensureLoaded() async {
    if (_loaded) return;

    final data = await _vault.filesystem.readIfExists(
      _vault.filesystem.paths.searchIndex,
    );

    if (data != null) {
      final searchKey = _deriveSearchKey();
      try {
        final plaintext = _crypto.xchacha20.decrypt(
          ciphertext: Uint8List.fromList(data),
          key: searchKey,
        );

        try {
          final json =
              jsonDecode(utf8.decode(plaintext.unsafeBytes))
                  as Map<String, dynamic>;
          final entries = (json['entries'] as List<dynamic>)
              .cast<Map<String, dynamic>>();

          for (final entryJson in entries) {
            final entry = SearchIndexEntry.fromJson(entryJson);
            _index[entry.hashedToken] = entry.noteIds;
          }
        } finally {
          plaintext.dispose();
        }
      } finally {
        searchKey.dispose();
      }
    }

    _loaded = true;
  }

  /// Persists index to disk.
  Future<void> _persist() async {
    final entries = _index.entries
        .map(
          (e) =>
              SearchIndexEntry(hashedToken: e.key, noteIds: e.value).toJson(),
        )
        .toList();

    final json = {'entries': entries};
    final plaintext = SecureBytes(
      Uint8List.fromList(utf8.encode(jsonEncode(json))),
    );

    final searchKey = _deriveSearchKey();
    try {
      final encrypted = _crypto.xchacha20.encrypt(
        plaintext: plaintext,
        key: searchKey,
      );

      await _vault.filesystem.writeAtomic(
        _vault.filesystem.paths.searchIndex,
        encrypted.ciphertext,
      );
    } finally {
      searchKey.dispose();
    }
  }

  /// Rebuilds the entire index (for maintenance).
  Future<void> rebuild(List<IndexableNote> notes) async {
    _index.clear();
    _tokenHashCache.clear();

    final searchKey = _deriveSearchKey();
    try {
      for (final note in notes) {
        final allText = [note.title, note.content, ...note.tags].join(' ');
        final tokens = _tokenize(allText);

        for (final token in tokens) {
          final hashedToken = _hashToken(token, searchKey);
          _index.putIfAbsent(hashedToken, () => {});
          _index[hashedToken]!.add(note.noteId);
        }
      }

      await _persist();
    } finally {
      searchKey.dispose();
    }
  }

  /// Gets index statistics.
  Future<SearchIndexStats> getStats() async {
    await _ensureLoaded();

    final uniqueNotes = <String>{};
    for (final noteIds in _index.values) {
      uniqueNotes.addAll(noteIds);
    }

    return SearchIndexStats(
      tokenCount: _index.length,
      noteCount: uniqueNotes.length,
    );
  }
}

/// A note to be indexed.
class IndexableNote {
  final String noteId;
  final String title;
  final String content;
  final List<String> tags;

  IndexableNote({
    required this.noteId,
    required this.title,
    required this.content,
    this.tags = const [],
  });
}

/// Search index statistics.
class SearchIndexStats {
  final int tokenCount;
  final int noteCount;

  SearchIndexStats({required this.tokenCount, required this.noteCount});
}
