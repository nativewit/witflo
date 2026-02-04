// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// MasterKeyDerivation Tests - Unit tests for master password key derivation
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:witflo_app/core/crypto/crypto.dart';
import 'package:witflo_app/core/workspace/master_key_derivation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CryptoService crypto;
  late MasterKeyDerivation derivation;

  setUpAll(() async {
    crypto = await CryptoService.initialize();
    derivation = MasterKeyDerivation.instance;
  });

  group('MasterKeyDerivation', () {
    test('should derive MUK from password and salt', () async {
      final password = SecureBytes.fromList(utf8.encode('test-password'));
      final salt = derivation.generateWorkspaceSalt();
      final params = Argon2Params.test; // Fast params for testing

      final muk = await derivation.deriveMasterUnlockKey(
        password,
        salt,
        params,
      );

      expect(muk, isNotNull);
      expect(muk.material.length, equals(32)); // 256 bits
      expect(muk.isDisposed, isFalse);

      muk.dispose();
    });

    test('should derive same MUK for same password and salt', () async {
      final salt = derivation.generateWorkspaceSalt();
      final params = Argon2Params.test;

      // Derive first MUK
      final password1 = SecureBytes.fromList(utf8.encode('same-password'));
      final muk1 = await derivation.deriveMasterUnlockKey(
        password1,
        salt,
        params,
      );

      // Derive second MUK with same password and salt
      final password2 = SecureBytes.fromList(utf8.encode('same-password'));
      final muk2 = await derivation.deriveMasterUnlockKey(
        password2,
        salt,
        params,
      );

      // Should be identical
      expect(muk1.material.bytes, equals(muk2.material.bytes));

      muk1.dispose();
      muk2.dispose();
    });

    test('should derive different MUK for different salt', () async {
      final password1 = SecureBytes.fromList(utf8.encode('test-password'));
      final password2 = SecureBytes.fromList(utf8.encode('test-password'));
      final salt1 = derivation.generateWorkspaceSalt();
      final salt2 = derivation.generateWorkspaceSalt();
      final params = Argon2Params.test;

      final muk1 = await derivation.deriveMasterUnlockKey(
        password1,
        salt1,
        params,
      );

      final muk2 = await derivation.deriveMasterUnlockKey(
        password2,
        salt2,
        params,
      );

      // Should be different (different salts)
      expect(muk1.material.bytes, isNot(equals(muk2.material.bytes)));

      muk1.dispose();
      muk2.dispose();
    });

    test('should derive different MUK for different password', () async {
      final salt = derivation.generateWorkspaceSalt();
      final params = Argon2Params.test;

      final password1 = SecureBytes.fromList(utf8.encode('password-1'));
      final muk1 = await derivation.deriveMasterUnlockKey(
        password1,
        salt,
        params,
      );

      final password2 = SecureBytes.fromList(utf8.encode('password-2'));
      final muk2 = await derivation.deriveMasterUnlockKey(
        password2,
        salt,
        params,
      );

      // Should be different (different passwords)
      expect(muk1.material.bytes, isNot(equals(muk2.material.bytes)));

      muk1.dispose();
      muk2.dispose();
    });

    test('should generate 16-byte salt', () {
      final salt = derivation.generateWorkspaceSalt();

      expect(salt, isA<Uint8List>());
      expect(salt.length, equals(16));
    });

    test('should generate different salts each time', () {
      final salt1 = derivation.generateWorkspaceSalt();
      final salt2 = derivation.generateWorkspaceSalt();

      expect(salt1, isNot(equals(salt2)));
    });

    test('should benchmark and return valid Argon2 params', () async {
      final params = await derivation.benchmarkArgon2Params(
        targetDurationMs: 100, // Fast benchmark for testing
        minMemoryKiB: 8192, // 8 MiB min
        maxMemoryKiB: 16384, // 16 MiB max
      );

      expect(params, isA<Argon2Params>());
      expect(params.memoryKiB, greaterThanOrEqualTo(8192));
      expect(params.memoryKiB, lessThanOrEqualTo(16384));
      expect(params.iterations, greaterThan(0));
      expect(params.parallelism, equals(1));
    });

    test('should dispose MUK and zeroize memory', () async {
      final password = SecureBytes.fromList(utf8.encode('test-password'));
      final salt = derivation.generateWorkspaceSalt();
      final params = Argon2Params.test;

      final muk = await derivation.deriveMasterUnlockKey(
        password,
        salt,
        params,
      );

      // Before dispose
      expect(muk.isDisposed, isFalse);

      // Dispose
      muk.dispose();

      // After dispose
      expect(muk.isDisposed, isTrue);
    });

    test('should handle long passwords', () async {
      final longPassword = SecureBytes.fromList(
        utf8.encode('a' * 1000), // 1000 character password
      );
      final salt = derivation.generateWorkspaceSalt();
      final params = Argon2Params.test;

      final muk = await derivation.deriveMasterUnlockKey(
        longPassword,
        salt,
        params,
      );

      expect(muk, isNotNull);
      expect(muk.material.length, equals(32));

      muk.dispose();
    });

    test('should handle unicode passwords', () async {
      final unicodePassword = SecureBytes.fromList(
        utf8.encode('🔒🔑🛡️ 密码 пароль'),
      );
      final salt = derivation.generateWorkspaceSalt();
      final params = Argon2Params.test;

      final muk = await derivation.deriveMasterUnlockKey(
        unicodePassword,
        salt,
        params,
      );

      expect(muk, isNotNull);
      expect(muk.material.length, equals(32));

      muk.dispose();
    });

    test('benchmark should respect memory constraints', () async {
      final params = await derivation.benchmarkArgon2Params(
        targetDurationMs: 100,
        minMemoryKiB: 16384, // 16 MiB
        maxMemoryKiB: 16384, // Same as min = exact constraint
      );

      expect(params.memoryKiB, equals(16384));
    });

    test('should complete derivation within reasonable time', () async {
      final password = SecureBytes.fromList(utf8.encode('test-password'));
      final salt = derivation.generateWorkspaceSalt();
      final params = Argon2Params.test; // Fast params

      final stopwatch = Stopwatch()..start();

      final muk = await derivation.deriveMasterUnlockKey(
        password,
        salt,
        params,
      );

      stopwatch.stop();

      // Test params should complete in < 1 second
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));

      muk.dispose();
    });
  });
}
