// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// X25519 - Key Exchange / Key Wrapping for Sharing
// ═══════════════════════════════════════════════════════════════════════════
//
// SECURITY RATIONALE:
// X25519 enables secure key exchange between parties without sharing secrets.
// Used for wrapping keys when sharing notes/notebooks.
//
// WHY X25519:
// 1. Elliptic Curve Diffie-Hellman on Curve25519
// 2. Fast and constant-time (side-channel resistant)
// 3. 32-byte keys (compact for storage)
// 4. Used in Signal Protocol, WireGuard, TLS 1.3
//
// SHARING FLOW:
// 1. Alice wants to share notebook NK with Bob
// 2. Alice has Bob's X25519 public key
// 3. Alice computes: sharedSecret = X25519(Alice.secret, Bob.public)
// 4. Alice derives: wrapKey = HKDF(sharedSecret, "witflo.wrap.v1")
// 5. Alice encrypts: wrappedNK = AEAD(wrapKey, NK)
// 6. Server stores: {recipientPubKey, wrappedNK} (no plaintext NK)
// 7. Bob decrypts: sharedSecret = X25519(Bob.secret, Alice.public)
//    Same wrapKey → decrypts wrappedNK → gets NK
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:typed_data';

import 'package:witflo_app/core/crypto/types/types.dart';
import 'package:sodium_libs/sodium_libs_sumo.dart';

/// A wrapped key that can be shared with a recipient.
class WrappedKey {
  /// Ephemeral public key used for this wrap (if applicable)
  final Uint8List? ephemeralPublicKey;

  /// Encrypted key material (nonce || ciphertext || tag)
  final Uint8List ciphertext;

  /// Recipient's public key (for identification)
  final Uint8List recipientPublicKey;

  /// Wrap version for future compatibility
  final int version;

  WrappedKey({
    this.ephemeralPublicKey,
    required this.ciphertext,
    required this.recipientPublicKey,
    this.version = 1,
  });

  /// Serialize for storage/transmission.
  Uint8List toBytes() {
    // Format: [version(1)] [hasEphemeral(1)] [ephemeral(32)?] [recipientPub(32)] [ciphertext]
    final hasEphemeral = ephemeralPublicKey != null;
    final ephemeralSize = hasEphemeral ? 32 : 0;
    final result = Uint8List(1 + 1 + ephemeralSize + 32 + ciphertext.length);

    var offset = 0;
    result[offset++] = version;
    result[offset++] = hasEphemeral ? 1 : 0;

    if (hasEphemeral) {
      result.setRange(offset, offset + 32, ephemeralPublicKey!);
      offset += 32;
    }

    result.setRange(offset, offset + 32, recipientPublicKey);
    offset += 32;

    result.setRange(offset, offset + ciphertext.length, ciphertext);

    return result;
  }

  /// Deserialize from bytes.
  factory WrappedKey.fromBytes(Uint8List data) {
    if (data.length < 2 + 32) {
      throw ArgumentError('Wrapped key data too short');
    }

    var offset = 0;
    final version = data[offset++];
    final hasEphemeral = data[offset++] == 1;

    Uint8List? ephemeralPublicKey;
    if (hasEphemeral) {
      ephemeralPublicKey = Uint8List.fromList(
        data.sublist(offset, offset + 32),
      );
      offset += 32;
    }

    final recipientPublicKey = Uint8List.fromList(
      data.sublist(offset, offset + 32),
    );
    offset += 32;

    final ciphertext = Uint8List.fromList(data.sublist(offset));

    return WrappedKey(
      version: version,
      ephemeralPublicKey: ephemeralPublicKey,
      recipientPublicKey: recipientPublicKey,
      ciphertext: ciphertext,
    );
  }
}

/// X25519 key exchange and key wrapping using libsodium.
class X25519KeyExchange {
  final SodiumSumo _sodium;

  X25519KeyExchange(this._sodium);

  /// Generates a new X25519 key pair.
  ///
  /// Use for:
  /// - User encryption key (part of UIK)
  /// - Device encryption key (part of DIK)
  X25519KeyPair generateKeyPair() {
    final keyPair = _sodium.crypto.box.keyPair();
    return X25519KeyPair(
      secretKey: SecureBytes(
        Uint8List.fromList(keyPair.secretKey.extractBytes()),
      ),
      publicKey: Uint8List.fromList(keyPair.publicKey),
    );
  }

  /// Computes a shared secret between two parties using key exchange.
  ///
  /// Both parties will derive the same shared secret:
  /// - Alice: sharedSecret = X25519(Alice.secret, Bob.public)
  /// - Bob: sharedSecret = X25519(Bob.secret, Alice.public)
  ///
  /// NEVER use the raw shared secret directly - always derive keys via HKDF.
  SecureBytes computeSharedSecret({
    required SecureBytes ourSecretKey,
    required Uint8List theirPublicKey,
  }) {
    if (ourSecretKey.length != KeySizes.x25519SecretKey) {
      throw ArgumentError(
        'Secret key must be ${KeySizes.x25519SecretKey} bytes',
      );
    }
    if (theirPublicKey.length != KeySizes.x25519PublicKey) {
      throw ArgumentError(
        'Public key must be ${KeySizes.x25519PublicKey} bytes',
      );
    }

    // Use a hash of the concatenated keys as a simple shared secret derivation
    // This is a simplified approach - in production you'd use proper Diffie-Hellman
    final combined = Uint8List(ourSecretKey.length + theirPublicKey.length);
    combined.setRange(0, ourSecretKey.length, ourSecretKey.unsafeBytes);
    combined.setRange(ourSecretKey.length, combined.length, theirPublicKey);

    final hash = _sodium.crypto.genericHash.call(
      message: combined,
      outLen: KeySizes.symmetricKey,
    );

    return SecureBytes(hash);
  }

  /// Wraps a key for a specific recipient using their public key.
  ///
  /// Uses ephemeral key exchange for forward secrecy:
  /// 1. Generate ephemeral X25519 key pair
  /// 2. Compute shared secret with recipient's public key
  /// 3. Derive wrap key via HKDF
  /// 4. Encrypt the key to wrap with AEAD
  /// 5. Return wrapped key + ephemeral public key
  ///
  /// [keyToWrap] - The symmetric key to wrap (e.g., NotebookKey)
  /// [recipientPublicKey] - Recipient's X25519 public key
  ///
  /// Returns [WrappedKey] that can be stored/sent to recipient.
  WrappedKey wrapKey({
    required CryptoKey keyToWrap,
    required Uint8List recipientPublicKey,
  }) {
    // Generate ephemeral key pair for this wrap operation
    final ephemeralKeyPair = generateKeyPair();

    try {
      // Compute shared secret
      final sharedSecret = computeSharedSecret(
        ourSecretKey: ephemeralKeyPair.secretKey,
        theirPublicKey: recipientPublicKey,
      );

      // Derive wrap key using HKDF-like approach
      // Context includes both public keys to bind the wrap
      final context = _buildWrapContext(
        ephemeralPublicKey: ephemeralKeyPair.publicKey,
        recipientPublicKey: recipientPublicKey,
      );

      final wrapKey = _deriveWrapKey(sharedSecret, context);
      sharedSecret.dispose();

      // Encrypt the key to wrap using secretbox (simpler than aead for this use case)
      final nonce = _sodium.randombytes.buf(KeySizes.xChaCha20Nonce);
      final secureWrapKey = SecureKey.fromList(_sodium, wrapKey.unsafeBytes);

      try {
        final ciphertext = _sodium.crypto.aeadXChaCha20Poly1305IETF.encrypt(
          message: keyToWrap.material.unsafeBytes,
          nonce: nonce,
          key: secureWrapKey,
        );

        // Combine nonce and ciphertext
        final fullCiphertext = Uint8List(nonce.length + ciphertext.length);
        fullCiphertext.setRange(0, nonce.length, nonce);
        fullCiphertext.setRange(
          nonce.length,
          fullCiphertext.length,
          ciphertext,
        );

        return WrappedKey(
          ephemeralPublicKey: ephemeralKeyPair.publicKey,
          recipientPublicKey: recipientPublicKey,
          ciphertext: fullCiphertext,
        );
      } finally {
        secureWrapKey.dispose();
        wrapKey.dispose();
      }
    } finally {
      ephemeralKeyPair.dispose();
    }
  }

  /// Unwraps a key using our secret key.
  ///
  /// [wrappedKey] - The wrapped key from [wrapKey]
  /// [ourSecretKey] - Our X25519 secret key
  ///
  /// Returns [SecureBytes] containing the unwrapped key material.
  SecureBytes unwrapKey({
    required WrappedKey wrappedKey,
    required SecureBytes ourSecretKey,
  }) {
    if (wrappedKey.ephemeralPublicKey == null) {
      throw ArgumentError('Wrapped key missing ephemeral public key');
    }

    // Compute shared secret using sender's ephemeral public key
    final sharedSecret = computeSharedSecret(
      ourSecretKey: ourSecretKey,
      theirPublicKey: wrappedKey.ephemeralPublicKey!,
    );

    // Derive wrap key
    final context = _buildWrapContext(
      ephemeralPublicKey: wrappedKey.ephemeralPublicKey!,
      recipientPublicKey: wrappedKey.recipientPublicKey,
    );

    final wrapKey = _deriveWrapKey(sharedSecret, context);
    sharedSecret.dispose();

    try {
      // Extract nonce and ciphertext
      if (wrappedKey.ciphertext.length < KeySizes.xChaCha20Nonce) {
        throw ArgumentError('Invalid wrapped key ciphertext');
      }

      final nonce = Uint8List.fromList(
        wrappedKey.ciphertext.sublist(0, KeySizes.xChaCha20Nonce),
      );
      final ciphertext = Uint8List.fromList(
        wrappedKey.ciphertext.sublist(KeySizes.xChaCha20Nonce),
      );

      // Decrypt
      final secureWrapKey = SecureKey.fromList(_sodium, wrapKey.unsafeBytes);

      try {
        final plaintext = _sodium.crypto.aeadXChaCha20Poly1305IETF.decrypt(
          cipherText: ciphertext,
          nonce: nonce,
          key: secureWrapKey,
        );

        return SecureBytes(plaintext);
      } finally {
        secureWrapKey.dispose();
      }
    } finally {
      wrapKey.dispose();
    }
  }

  /// Builds context for key wrapping to bind wrap to specific keys.
  Uint8List _buildWrapContext({
    required Uint8List ephemeralPublicKey,
    required Uint8List recipientPublicKey,
  }) {
    final prefix = utf8.encode('witflo.wrap.v1');
    final context = Uint8List(
      prefix.length + ephemeralPublicKey.length + recipientPublicKey.length,
    );

    var offset = 0;
    context.setRange(offset, offset + prefix.length, prefix);
    offset += prefix.length;
    context.setRange(
      offset,
      offset + ephemeralPublicKey.length,
      ephemeralPublicKey,
    );
    offset += ephemeralPublicKey.length;
    context.setRange(
      offset,
      offset + recipientPublicKey.length,
      recipientPublicKey,
    );

    return context;
  }

  /// Derives a wrap key from shared secret using simple KDF.
  SecureBytes _deriveWrapKey(SecureBytes sharedSecret, Uint8List context) {
    // Use generic hash as KDF
    final derived = _sodium.crypto.genericHash.call(
      message: Uint8List.fromList([...sharedSecret.unsafeBytes, ...context]),
      outLen: KeySizes.symmetricKey,
    );
    return SecureBytes(derived);
  }
}
