// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Vault Tests - Vault Creation, Unlock, and Management Tests
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fyndo_app/core/crypto/crypto.dart';
import 'package:fyndo_app/core/vault/vault.dart';

void main() {
  late CryptoService crypto;
  late VaultService vaultService;
  late Directory tempDir;

  setUpAll(() async {
    crypto = await CryptoService.initialize();
    vaultService = VaultService(crypto);
  });

  setUp(() async {
    // Create a fresh temp directory for each test
    tempDir = await Directory.systemTemp.createTemp('fyndo_test_');
  });

  tearDown(() async {
    // Clean up temp directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('VaultHeader', () {
    test('should create header with correct fields', () {
      final salt = crypto.random.salt();
      final params = Argon2Params.standard;

      final header = VaultHeader.create(
        salt: salt,
        kdfParams: params,
        vaultId: 'test-vault-id',
      );

      expect(header.version, equals(currentVaultVersion));
      expect(header.salt, equals(salt));
      expect(header.kdfParams.memoryKiB, equals(params.memoryKiB));
      expect(header.vaultId, equals('test-vault-id'));
      expect(header.createdAt, isNotNull);
    });

    test('should serialize and deserialize', () {
      final salt = crypto.random.salt();
      final header = VaultHeader.create(
        salt: salt,
        kdfParams: Argon2Params.test,
        vaultId: 'test-id',
      );

      final bytes = header.toBytes();
      final restored = VaultHeader.fromBytes(bytes);

      expect(restored.version, equals(header.version));
      expect(restored.salt, equals(header.salt));
      expect(restored.vaultId, equals(header.vaultId));
      expect(restored.kdfParams.memoryKiB, equals(header.kdfParams.memoryKiB));
    });

    test('should update modification time on touch', () {
      final header = VaultHeader.create(
        salt: crypto.random.salt(),
        kdfParams: Argon2Params.test,
        vaultId: 'test',
      );

      final originalCreated = header.createdAt;
      expect(header.modifiedAt, isNull);

      final touched = header.touch();

      expect(touched.createdAt, equals(originalCreated));
      expect(touched.modifiedAt, isNotNull);
    });
  });

  group('VaultFilesystem', () {
    test('should initialize directory structure', () async {
      final vaultPath = '${tempDir.path}/vault';
      final filesystem = VaultFilesystem(vaultPath);

      await filesystem.initialize();

      expect(await Directory(filesystem.paths.rootPath).exists(), isTrue);
      expect(await Directory(filesystem.paths.objectsDir).exists(), isTrue);
      expect(await Directory(filesystem.paths.refsDir).exists(), isTrue);
      expect(await Directory(filesystem.paths.syncDir).exists(), isTrue);

      // Check hash prefix directories
      expect(
        await Directory('${filesystem.paths.objectsDir}/00').exists(),
        isTrue,
      );
      expect(
        await Directory('${filesystem.paths.objectsDir}/ff').exists(),
        isTrue,
      );
    });

    test('should report vault existence correctly', () async {
      final vaultPath = '${tempDir.path}/vault';
      final filesystem = VaultFilesystem(vaultPath);

      expect(await filesystem.exists(), isFalse);

      // Create minimal vault files
      await filesystem.initialize();
      await File(filesystem.paths.header).writeAsString('{}');
      await File(filesystem.paths.vaultKey).writeAsBytes([1, 2, 3]);

      expect(await filesystem.exists(), isTrue);
    });

    test('should write and read objects', () async {
      final vaultPath = '${tempDir.path}/vault';
      final filesystem = VaultFilesystem(vaultPath);
      await filesystem.initialize();

      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      final hash = 'abcdef1234567890abcdef1234567890';

      await filesystem.writeObject(hash, data);

      final read = await filesystem.readObject(hash);

      expect(read, equals(data));
    });

    test('should generate correct object path', () {
      final filesystem = VaultFilesystem('/vault');
      final hash = 'abcdef1234567890';

      final path = filesystem.paths.objectPath(hash);

      expect(path, equals('/vault/objects/ab/cdef1234567890'));
    });

    test('should write atomically', () async {
      final vaultPath = '${tempDir.path}/vault';
      final filesystem = VaultFilesystem(vaultPath);
      await filesystem.initialize();

      final filePath = '$vaultPath/test.txt';
      final data = [1, 2, 3, 4, 5];

      await filesystem.writeAtomic(filePath, data);

      expect(await File(filePath).exists(), isTrue);
      expect(await File('$filePath.tmp').exists(), isFalse);
      expect(await File(filePath).readAsBytes(), equals(data));
    });
  });

  group('VaultService - Creation', () {
    test('should create new vault', () async {
      final vaultPath = '${tempDir.path}/vault';
      final password = SecureBytes.fromList(utf8.encode('test-password'));

      final result = await vaultService.createVault(
        vaultPath: vaultPath,
        password: password,
        kdfParams: Argon2Params.test, // Use fast params for testing
      );

      expect(result.vaultPath, equals(vaultPath));
      expect(result.header.version, equals(currentVaultVersion));
      expect(await File('$vaultPath/vault.header').exists(), isTrue);
      expect(await File('$vaultPath/vault.vk').exists(), isTrue);
    });

    test('should fail if vault already exists', () async {
      final vaultPath = '${tempDir.path}/vault';
      final password1 = SecureBytes.fromList(utf8.encode('pass1'));
      final password2 = SecureBytes.fromList(utf8.encode('pass2'));

      await vaultService.createVault(
        vaultPath: vaultPath,
        password: password1,
        kdfParams: Argon2Params.test,
      );

      expect(
        () => vaultService.createVault(
          vaultPath: vaultPath,
          password: password2,
          kdfParams: Argon2Params.test,
        ),
        throwsA(isA<VaultException>()),
      );
    });
  });

  group('VaultService - Unlock', () {
    test('should unlock vault with correct password', () async {
      final vaultPath = '${tempDir.path}/vault';
      final password = SecureBytes.fromList(utf8.encode('correct-password'));

      await vaultService.createVault(
        vaultPath: vaultPath,
        password: password,
        kdfParams: Argon2Params.test,
      );

      final unlockPassword =
          SecureBytes.fromList(utf8.encode('correct-password'));
      final vault = await vaultService.unlockVault(
        vaultPath: vaultPath,
        password: unlockPassword,
      );

      expect(vault.vaultKey, isNotNull);
      expect(vault.vaultKey.isDisposed, isFalse);

      vault.dispose();
    });

    test('should fail unlock with wrong password', () async {
      final vaultPath = '${tempDir.path}/vault';
      final password = SecureBytes.fromList(utf8.encode('correct-password'));

      await vaultService.createVault(
        vaultPath: vaultPath,
        password: password,
        kdfParams: Argon2Params.test,
      );

      final wrongPassword = SecureBytes.fromList(utf8.encode('wrong-password'));

      expect(
        () => vaultService.unlockVault(
          vaultPath: vaultPath,
          password: wrongPassword,
        ),
        throwsA(isA<VaultException>().having(
          (e) => e.error,
          'error',
          VaultError.invalidPassword,
        )),
      );
    });

    test('should fail unlock if vault not found', () async {
      final vaultPath = '${tempDir.path}/nonexistent';
      final password = SecureBytes.fromList(utf8.encode('password'));

      expect(
        () => vaultService.unlockVault(
          vaultPath: vaultPath,
          password: password,
        ),
        throwsA(isA<VaultException>().having(
          (e) => e.error,
          'error',
          VaultError.vaultNotFound,
        )),
      );
    });
  });

  group('VaultService - Key Derivation', () {
    test('should derive content keys from unlocked vault', () async {
      final vaultPath = '${tempDir.path}/vault';
      final password = SecureBytes.fromList(utf8.encode('password'));

      await vaultService.createVault(
        vaultPath: vaultPath,
        password: password,
        kdfParams: Argon2Params.test,
      );

      final unlockPassword = SecureBytes.fromList(utf8.encode('password'));
      final vault = await vaultService.unlockVault(
        vaultPath: vaultPath,
        password: unlockPassword,
      );

      final ck1 = vault.deriveContentKey('note-1');
      final ck2 = vault.deriveContentKey('note-2');
      final ck1Again = vault.deriveContentKey('note-1');

      expect(ck1.material.bytes, equals(ck1Again.material.bytes));
      expect(ck1.material.bytes, isNot(equals(ck2.material.bytes)));

      vault.dispose();
    });

    test('should derive notebook keys', () async {
      final vaultPath = '${tempDir.path}/vault';
      final password = SecureBytes.fromList(utf8.encode('password'));

      await vaultService.createVault(
        vaultPath: vaultPath,
        password: password,
        kdfParams: Argon2Params.test,
      );

      final unlockPassword = SecureBytes.fromList(utf8.encode('password'));
      final vault = await vaultService.unlockVault(
        vaultPath: vaultPath,
        password: unlockPassword,
      );

      final nk = vault.deriveNotebookKey('notebook-123');

      expect(nk.notebookId, equals('notebook-123'));
      expect(nk.material.length, equals(32));

      vault.dispose();
    });
  });

  group('VaultService - Password Change', () {
    test('should change password successfully', () async {
      final vaultPath = '${tempDir.path}/vault';
      final oldPassword = SecureBytes.fromList(utf8.encode('old-password'));

      await vaultService.createVault(
        vaultPath: vaultPath,
        password: oldPassword,
        kdfParams: Argon2Params.test,
      );

      // Unlock with old password
      final unlockOld = SecureBytes.fromList(utf8.encode('old-password'));
      final vault = await vaultService.unlockVault(
        vaultPath: vaultPath,
        password: unlockOld,
      );

      // Change password
      final newPassword = SecureBytes.fromList(utf8.encode('new-password'));
      await vaultService.changePassword(
        vault: vault,
        newPassword: newPassword,
      );

      vault.dispose();

      // Should fail with old password
      final tryOld = SecureBytes.fromList(utf8.encode('old-password'));
      expect(
        () => vaultService.unlockVault(
          vaultPath: vaultPath,
          password: tryOld,
        ),
        throwsA(isA<VaultException>()),
      );

      // Should succeed with new password
      final tryNew = SecureBytes.fromList(utf8.encode('new-password'));
      final reopened = await vaultService.unlockVault(
        vaultPath: vaultPath,
        password: tryNew,
      );

      expect(reopened.vaultKey, isNotNull);
      reopened.dispose();
    });
  });

  group('VaultService - Verify Password', () {
    test('should verify correct password', () async {
      final vaultPath = '${tempDir.path}/vault';
      final password = SecureBytes.fromList(utf8.encode('password'));

      await vaultService.createVault(
        vaultPath: vaultPath,
        password: password,
        kdfParams: Argon2Params.test,
      );

      final correct = SecureBytes.fromList(utf8.encode('password'));
      final result = await vaultService.verifyPassword(
        vaultPath: vaultPath,
        password: correct,
      );

      expect(result, isTrue);
    });

    test('should reject wrong password', () async {
      final vaultPath = '${tempDir.path}/vault';
      final password = SecureBytes.fromList(utf8.encode('password'));

      await vaultService.createVault(
        vaultPath: vaultPath,
        password: password,
        kdfParams: Argon2Params.test,
      );

      final wrong = SecureBytes.fromList(utf8.encode('wrong'));
      final result = await vaultService.verifyPassword(
        vaultPath: vaultPath,
        password: wrong,
      );

      expect(result, isFalse);
    });
  });

  group('Unlocked Vault Lifecycle', () {
    test('should dispose all keys on vault dispose', () async {
      final vaultPath = '${tempDir.path}/vault';
      final password = SecureBytes.fromList(utf8.encode('password'));

      await vaultService.createVault(
        vaultPath: vaultPath,
        password: password,
        kdfParams: Argon2Params.test,
      );

      final unlockPassword = SecureBytes.fromList(utf8.encode('password'));
      final vault = await vaultService.unlockVault(
        vaultPath: vaultPath,
        password: unlockPassword,
      );

      // Derive some keys
      vault.deriveContentKey('note-1');
      vault.deriveNotebookKey('notebook-1');

      // Dispose vault
      vault.dispose();

      // Vault key should be disposed
      expect(vault.vaultKey.isDisposed, isTrue);
    });
  });
}

