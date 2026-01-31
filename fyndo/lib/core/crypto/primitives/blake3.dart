// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// BLAKE3 - Fast Cryptographic Hash for Content Addressing
// ═══════════════════════════════════════════════════════════════════════════
//
// SECURITY RATIONALE:
// BLAKE3 is used for content-addressing encrypted chunks.
// The hash of ciphertext becomes the storage key (blob ID).
//
// WHY BLAKE3:
// 1. Extremely fast (4x faster than SHA-256)
// 2. Secure (based on BLAKE2 with proven security margins)
// 3. Tree/streaming mode for large files
// 4. Keyed mode for MAC operations
//
// USAGE IN FYNDO:
// - Hash encrypted chunks → blob IDs for /objects/ directory
// - Content-addressed storage enables deduplication of ciphertext
// - Hash is computed on CIPHERTEXT, not plaintext (zero-knowledge)
//
// NOTE: libsodium doesn't include BLAKE3, so we use BLAKE2b as fallback.
// BLAKE2b is also excellent and available in libsodium.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';

import 'package:fyndo_app/core/crypto/types/types.dart';
import 'package:sodium_libs/sodium_libs_sumo.dart';

/// Content hash result with hex representation.
class ContentHash {
  /// Raw hash bytes (32 bytes)
  final Uint8List bytes;

  ContentHash(this.bytes) {
    if (bytes.length != KeySizes.blake3Hash) {
      throw ArgumentError('Hash must be ${KeySizes.blake3Hash} bytes');
    }
  }

  /// Hexadecimal representation of the hash.
  String get hex {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Short prefix for display (first 8 hex chars).
  String get shortHex => hex.substring(0, 8);

  /// Path format for content-addressed storage: ab/cdef...
  /// First byte as directory, rest as filename.
  String get storagePath {
    final h = hex;
    return '${h.substring(0, 2)}/${h.substring(2)}';
  }

  @override
  bool operator ==(Object other) {
    if (other is! ContentHash) return false;
    if (bytes.length != other.bytes.length) return false;
    for (var i = 0; i < bytes.length; i++) {
      if (bytes[i] != other.bytes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(bytes);

  @override
  String toString() => 'ContentHash($shortHex...)';
}

/// BLAKE2b hashing (BLAKE3 fallback using libsodium).
///
/// Used for:
/// - Content-addressing encrypted blobs
/// - Generating deterministic IDs
/// - Creating HMACs for search index tokens
class Blake3Hash {
  final SodiumSumo _sodium;

  Blake3Hash(this._sodium);

  /// Hash arbitrary data and return a ContentHash.
  ///
  /// [data] - Data to hash (typically ciphertext)
  ///
  /// Returns [ContentHash] for content-addressed storage.
  ContentHash hash(Uint8List data) {
    final result = _sodium.crypto.genericHash.call(
      message: data,
      outLen: KeySizes.blake3Hash,
    );
    return ContentHash(result);
  }

  /// Hash with a key for keyed hashing (MAC).
  ///
  /// Used for search index token hashing:
  /// HMAC(searchKey, token) → token hash for blind search
  ///
  /// [data] - Data to hash
  /// [key] - Secret key for keyed hashing
  ContentHash keyedHash(Uint8List data, SecureBytes key) {
    // Create a SecureKey from the key bytes
    final secureKey = SecureKey.fromList(_sodium, key.unsafeBytes);
    try {
      final result = _sodium.crypto.genericHash.call(
        message: data,
        key: secureKey,
        outLen: KeySizes.blake3Hash,
      );
      return ContentHash(result);
    } finally {
      secureKey.dispose();
    }
  }

  /// Streaming hash for large data.
  ///
  /// Use for hashing files/blobs that don't fit in memory.
  StreamingHash createStreamingHash() {
    return StreamingHash(_sodium);
  }
}

/// Streaming hash for large data that doesn't fit in memory.
class StreamingHash {
  final SodiumSumo _sodium;
  late final GenericHashConsumer _state;
  bool _finalized = false;

  StreamingHash(this._sodium) {
    _state = _sodium.crypto.genericHash.createConsumer(
      outLen: KeySizes.blake3Hash,
    );
  }

  /// Add data chunk to the hash.
  void update(Uint8List chunk) {
    if (_finalized) {
      throw StateError('Hash already finalized');
    }
    _state.addStream(Stream.value(chunk));
  }

  /// Finalize and get the hash.
  Future<ContentHash> finalize() async {
    if (_finalized) {
      throw StateError('Hash already finalized');
    }
    _finalized = true;

    final result = await _state.close();
    return ContentHash(result);
  }
}
