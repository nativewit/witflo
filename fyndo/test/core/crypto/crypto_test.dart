// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Crypto Tests - Core Cryptographic Primitives Tests
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fyndo_app/core/crypto/crypto.dart';

void main() {
  late CryptoService crypto;

  setUpAll(() async {
    // Initialize crypto service before all tests
    crypto = await CryptoService.initialize();
  });

  group('SecureBytes', () {
    test('should store bytes and provide access', () {
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      final secure = SecureBytes(data);

      expect(secure.length, equals(5));
      expect(secure.bytes, equals(data));
      expect(secure.isDisposed, isFalse);

      secure.dispose();
    });

    test('should zeroize memory on dispose', () {
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      final secure = SecureBytes(data);

      secure.dispose();

      expect(secure.isDisposed, isTrue);
      expect(() => secure.bytes, throwsStateError);
    });

    test('should perform constant-time comparison', () {
      final a = SecureBytes.fromList([1, 2, 3, 4, 5]);
      final b = SecureBytes.fromList([1, 2, 3, 4, 5]);
      final c = SecureBytes.fromList([1, 2, 3, 4, 6]);

      expect(a.constantTimeEquals(b), isTrue);
      expect(a.constantTimeEquals(c), isFalse);

      a.dispose();
      b.dispose();
      c.dispose();
    });

    test('should create copy', () {
      final original = SecureBytes.fromList([1, 2, 3]);
      final copy = original.copy();

      expect(copy.bytes, equals(original.bytes));

      original.dispose();
      expect(copy.isDisposed, isFalse); // Copy should still be valid

      copy.dispose();
    });
  });

  group('Key Types', () {
    test('MasterUnlockKey should require 32 bytes', () {
      final validBytes = SecureBytes(Uint8List(32));
      final muk = MasterUnlockKey(validBytes);

      expect(muk.expectedLength, equals(32));
      expect(muk.keyTypeName, equals('MasterUnlockKey'));

      muk.dispose();
    });

    test('VaultKey should require 32 bytes', () {
      final validBytes = SecureBytes(Uint8List(32));
      final vk = VaultKey(validBytes);

      expect(vk.expectedLength, equals(32));
      expect(vk.keyTypeName, equals('VaultKey'));

      vk.dispose();
    });

    test('should throw on invalid key size', () {
      final invalidBytes = SecureBytes(Uint8List(16)); // Too small

      expect(() => MasterUnlockKey(invalidBytes), throwsArgumentError);
    });

    test('ContentKey should store context', () {
      final bytes = SecureBytes(Uint8List(32));
      final ck = ContentKey(bytes, context: 'fyndo.content.note123.v1');

      expect(ck.context, equals('fyndo.content.note123.v1'));

      ck.dispose();
    });
  });

  group('Argon2id', () {
    test('should generate 16-byte salt', () {
      final salt = crypto.argon2id.generateSalt();

      expect(salt.length, equals(16));
    });

    test('should derive MUK from password', () async {
      final password = SecureBytes.fromList(utf8.encode('test-password'));
      final salt = crypto.argon2id.generateSalt();
      final params = Argon2Params.test; // Use test params for speed

      final muk = await crypto.argon2id.deriveKey(
        password: password,
        salt: salt,
        params: params,
      );

      expect(muk.material.length, equals(32));
      expect(muk.isDisposed, isFalse);

      muk.dispose();
    });

    test('should produce same MUK for same password and salt', () async {
      final salt = crypto.argon2id.generateSalt();
      final params = Argon2Params.test;

      final password1 = SecureBytes.fromList(utf8.encode('same-password'));
      final password2 = SecureBytes.fromList(utf8.encode('same-password'));

      final muk1 = await crypto.argon2id.deriveKey(
        password: password1,
        salt: salt,
        params: params,
      );

      final muk2 = await crypto.argon2id.deriveKey(
        password: password2,
        salt: salt,
        params: params,
      );

      expect(muk1.material.bytes, equals(muk2.material.bytes));

      muk1.dispose();
      muk2.dispose();
    });

    test('should produce different MUK for different passwords', () async {
      final salt = crypto.argon2id.generateSalt();
      final params = Argon2Params.test;

      final password1 = SecureBytes.fromList(utf8.encode('password1'));
      final password2 = SecureBytes.fromList(utf8.encode('password2'));

      final muk1 = await crypto.argon2id.deriveKey(
        password: password1,
        salt: salt,
        params: params,
      );

      final muk2 = await crypto.argon2id.deriveKey(
        password: password2,
        salt: salt,
        params: params,
      );

      expect(muk1.material.bytes, isNot(equals(muk2.material.bytes)));

      muk1.dispose();
      muk2.dispose();
    });

    test('should serialize/deserialize Argon2Params', () {
      final params = Argon2Params(
        memoryKiB: 65536,
        iterations: 3,
        parallelism: 1,
        version: 1,
      );

      final json = params.toJson();
      final restored = Argon2Params.fromJson(json);

      expect(restored.memoryKiB, equals(params.memoryKiB));
      expect(restored.iterations, equals(params.iterations));
      expect(restored.parallelism, equals(params.parallelism));
      expect(restored.version, equals(params.version));
    });
  });

  group('XChaCha20-Poly1305', () {
    test('should encrypt and decrypt data', () {
      final plaintext = SecureBytes.fromList(utf8.encode('Hello, World!'));
      final keyBytes = crypto.random.symmetricKey();
      final key = VaultKey(keyBytes);

      final encrypted = crypto.xchacha20.encrypt(
        plaintext: plaintext,
        key: key,
      );

      expect(encrypted.ciphertext.length, greaterThan(plaintext.length));

      final decrypted = crypto.xchacha20.decrypt(
        ciphertext: encrypted.ciphertext,
        key: key,
      );

      expect(utf8.decode(decrypted.bytes), equals('Hello, World!'));

      key.dispose();
      decrypted.dispose();
    });

    test('should include nonce in ciphertext', () {
      final plaintext = SecureBytes.fromList(utf8.encode('Test'));
      final key = VaultKey(crypto.random.symmetricKey());

      final encrypted = crypto.xchacha20.encrypt(
        plaintext: plaintext,
        key: key,
      );

      // Ciphertext should be: nonce (24) + encrypted data + tag (16)
      expect(
        encrypted.ciphertext.length,
        equals(24 + 4 + 16), // 24 nonce + 4 plaintext + 16 tag
      );

      key.dispose();
    });

    test('should fail decryption with wrong key', () {
      final plaintext = SecureBytes.fromList(utf8.encode('Secret'));
      final key1 = VaultKey(crypto.random.symmetricKey());
      final key2 = VaultKey(crypto.random.symmetricKey());

      final encrypted = crypto.xchacha20.encrypt(
        plaintext: plaintext,
        key: key1,
      );

      expect(
        () => crypto.xchacha20.decrypt(
          ciphertext: encrypted.ciphertext,
          key: key2,
        ),
        throwsA(anything),
      );

      key1.dispose();
      key2.dispose();
    });

    test('should authenticate associated data', () {
      final plaintext = SecureBytes.fromList(utf8.encode('Secret'));
      final key = VaultKey(crypto.random.symmetricKey());
      final aad = Uint8List.fromList(utf8.encode('note-id-123'));

      final encrypted = crypto.xchacha20.encrypt(
        plaintext: plaintext,
        key: key,
        associatedData: aad,
      );

      // Should succeed with correct AAD
      final decrypted = crypto.xchacha20.decrypt(
        ciphertext: encrypted.ciphertext,
        key: key,
        associatedData: aad,
      );
      expect(utf8.decode(decrypted.bytes), equals('Secret'));
      decrypted.dispose();

      // Should fail with wrong AAD
      final wrongAad = Uint8List.fromList(utf8.encode('wrong-id'));
      expect(
        () => crypto.xchacha20.decrypt(
          ciphertext: encrypted.ciphertext,
          key: key,
          associatedData: wrongAad,
        ),
        throwsA(anything),
      );

      key.dispose();
    });
  });

  group('HKDF', () {
    test('should derive content key from vault key', () {
      final vk = VaultKey(crypto.random.symmetricKey());

      final ck = crypto.hkdf.deriveContentKey(vaultKey: vk, noteId: 'note-123');

      expect(ck.material.length, equals(32));
      expect(ck.context, contains('note-123'));

      ck.dispose();
      vk.dispose();
    });

    test('should produce same key for same inputs', () {
      final vk = VaultKey(crypto.random.symmetricKey());

      final ck1 = crypto.hkdf.deriveContentKey(vaultKey: vk, noteId: 'note-1');
      final ck2 = crypto.hkdf.deriveContentKey(vaultKey: vk, noteId: 'note-1');

      expect(ck1.material.bytes, equals(ck2.material.bytes));

      ck1.dispose();
      ck2.dispose();
      vk.dispose();
    });

    test('should produce different keys for different note IDs', () {
      final vk = VaultKey(crypto.random.symmetricKey());

      final ck1 = crypto.hkdf.deriveContentKey(vaultKey: vk, noteId: 'note-1');
      final ck2 = crypto.hkdf.deriveContentKey(vaultKey: vk, noteId: 'note-2');

      expect(ck1.material.bytes, isNot(equals(ck2.material.bytes)));

      ck1.dispose();
      ck2.dispose();
      vk.dispose();
    });

    test('should derive notebook key', () {
      final vk = VaultKey(crypto.random.symmetricKey());

      final nk = crypto.hkdf.deriveNotebookKey(
        vaultKey: vk,
        notebookId: 'notebook-456',
      );

      expect(nk.material.length, equals(32));
      expect(nk.notebookId, equals('notebook-456'));

      nk.dispose();
      vk.dispose();
    });

    test('should derive search index key', () {
      final vk = VaultKey(crypto.random.symmetricKey());

      final sk = crypto.hkdf.deriveSearchIndexKey(vaultKey: vk);

      expect(sk.material.length, equals(32));
      expect(sk.context, contains('search'));

      sk.dispose();
      vk.dispose();
    });
  });

  group('BLAKE3 (BLAKE2b)', () {
    test('should hash data', () {
      final data = Uint8List.fromList(utf8.encode('Hello'));

      final hash = crypto.blake3.hash(data);

      expect(hash.bytes.length, equals(32));
      expect(hash.hex.length, equals(64));
    });

    test('should produce same hash for same input', () {
      final data1 = Uint8List.fromList(utf8.encode('Same'));
      final data2 = Uint8List.fromList(utf8.encode('Same'));

      final hash1 = crypto.blake3.hash(data1);
      final hash2 = crypto.blake3.hash(data2);

      expect(hash1, equals(hash2));
    });

    test('should produce different hash for different input', () {
      final data1 = Uint8List.fromList(utf8.encode('Data1'));
      final data2 = Uint8List.fromList(utf8.encode('Data2'));

      final hash1 = crypto.blake3.hash(data1);
      final hash2 = crypto.blake3.hash(data2);

      expect(hash1, isNot(equals(hash2)));
    });

    test('should generate storage path', () {
      final data = Uint8List.fromList(utf8.encode('Test'));
      final hash = crypto.blake3.hash(data);

      final path = hash.storagePath;

      expect(path, contains('/'));
      expect(path.split('/')[0].length, equals(2)); // First 2 hex chars
    });
  });

  group('Ed25519', () {
    test('should generate key pair', () {
      final keyPair = crypto.ed25519.generateKeyPair();

      expect(keyPair.publicKey.length, equals(32));
      expect(keyPair.secretKey.length, equals(64));

      keyPair.dispose();
    });

    test('should sign and verify', () {
      final keyPair = crypto.ed25519.generateKeyPair();
      final message = Uint8List.fromList(utf8.encode('Sign this'));

      final signature = crypto.ed25519.sign(message: message, keyPair: keyPair);

      expect(signature.bytes.length, equals(64));

      final valid = crypto.ed25519.verify(
        message: message,
        signature: signature,
        publicKey: keyPair.publicKey,
      );

      expect(valid, isTrue);

      keyPair.dispose();
    });

    test('should fail verification with wrong message', () {
      final keyPair = crypto.ed25519.generateKeyPair();
      final message = Uint8List.fromList(utf8.encode('Original'));
      final wrongMessage = Uint8List.fromList(utf8.encode('Tampered'));

      final signature = crypto.ed25519.sign(message: message, keyPair: keyPair);

      final valid = crypto.ed25519.verify(
        message: wrongMessage,
        signature: signature,
        publicKey: keyPair.publicKey,
      );

      expect(valid, isFalse);

      keyPair.dispose();
    });

    test('should fail verification with wrong key', () {
      final keyPair1 = crypto.ed25519.generateKeyPair();
      final keyPair2 = crypto.ed25519.generateKeyPair();
      final message = Uint8List.fromList(utf8.encode('Message'));

      final signature = crypto.ed25519.sign(
        message: message,
        keyPair: keyPair1,
      );

      final valid = crypto.ed25519.verify(
        message: message,
        signature: signature,
        publicKey: keyPair2.publicKey,
      );

      expect(valid, isFalse);

      keyPair1.dispose();
      keyPair2.dispose();
    });
  });

  group('X25519', () {
    test('should generate key pair', () {
      final keyPair = crypto.x25519.generateKeyPair();

      expect(keyPair.publicKey.length, equals(32));
      expect(keyPair.secretKey.length, equals(32));

      keyPair.dispose();
    });

    test('should compute same shared secret from both sides', () {
      final alice = crypto.x25519.generateKeyPair();
      final bob = crypto.x25519.generateKeyPair();

      final aliceShared = crypto.x25519.computeSharedSecret(
        ourSecretKey: alice.secretKey,
        theirPublicKey: bob.publicKey,
      );

      final bobShared = crypto.x25519.computeSharedSecret(
        ourSecretKey: bob.secretKey,
        theirPublicKey: alice.publicKey,
      );

      expect(aliceShared.bytes, equals(bobShared.bytes));

      alice.dispose();
      bob.dispose();
      aliceShared.dispose();
      bobShared.dispose();
    });

    test('should wrap and unwrap key', () {
      final alice = crypto.x25519.generateKeyPair();
      final bob = crypto.x25519.generateKeyPair();

      // Key to wrap (e.g., NotebookKey)
      final secretKey = VaultKey(crypto.random.symmetricKey());

      // Alice wraps for Bob
      final wrapped = crypto.x25519.wrapKey(
        keyToWrap: secretKey,
        recipientPublicKey: bob.publicKey,
      );

      // Bob unwraps
      final unwrapped = crypto.x25519.unwrapKey(
        wrappedKey: wrapped,
        ourSecretKey: bob.secretKey,
      );

      expect(unwrapped.bytes, equals(secretKey.material.bytes));

      alice.dispose();
      bob.dispose();
      secretKey.dispose();
      unwrapped.dispose();
    });

    test('should fail unwrap with wrong key', () {
      final alice = crypto.x25519.generateKeyPair();
      final bob = crypto.x25519.generateKeyPair();
      final eve = crypto.x25519.generateKeyPair();

      final secretKey = VaultKey(crypto.random.symmetricKey());

      final wrapped = crypto.x25519.wrapKey(
        keyToWrap: secretKey,
        recipientPublicKey: bob.publicKey,
      );

      // Eve tries to unwrap with her key
      expect(
        () => crypto.x25519.unwrapKey(
          wrappedKey: wrapped,
          ourSecretKey: eve.secretKey,
        ),
        throwsA(anything),
      );

      alice.dispose();
      bob.dispose();
      eve.dispose();
      secretKey.dispose();
    });
  });

  group('SecureRandom', () {
    test('should generate random bytes', () {
      final bytes1 = crypto.random.bytes(32);
      final bytes2 = crypto.random.bytes(32);

      expect(bytes1.length, equals(32));
      expect(bytes2.length, equals(32));
      expect(bytes1, isNot(equals(bytes2)));
    });

    test('should generate secure bytes', () {
      final secure1 = crypto.random.secureBytes(32);
      final secure2 = crypto.random.secureBytes(32);

      expect(secure1.length, equals(32));
      expect(secure1.bytes, isNot(equals(secure2.bytes)));

      secure1.dispose();
      secure2.dispose();
    });

    test('should generate symmetric key', () {
      final key = crypto.random.symmetricKey();

      expect(key.length, equals(32));

      key.dispose();
    });

    test('should generate salt', () {
      final salt = crypto.random.salt();

      expect(salt.length, equals(16));
    });

    test('should generate nonce', () {
      final nonce = crypto.random.nonce();

      expect(nonce.length, equals(24)); // XChaCha20 nonce
    });
  });
}
