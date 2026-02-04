// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// WorkspaceService Tests - Workspace initialization and management tests (v2)
// ═══════════════════════════════════════════════════════════════════════════
//
// UPDATED FOR SPEC-002: Workspace Master Password Architecture
//
// These tests use the new workspace API where:
// - initializeWorkspace() requires master password and returns UnlockedWorkspace
// - Workspace keyring is encrypted with master password
// - Vault keys are stored in keyring (not derived from vault passwords)
//
// See: docs/specs/spec-002-workspace-master-password.md
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:witflo_app/core/crypto/crypto.dart';
import 'package:witflo_app/core/workspace/workspace_service.dart';

void main() {
  late WorkspaceService service;
  late Directory tempDir;
  late CryptoService crypto;

  // Test password (weak for faster tests)
  late SecureBytes testPassword;

  setUpAll(() async {
    // Initialize Flutter binding for SharedPreferences
    TestWidgetsFlutterBinding.ensureInitialized();
    crypto = await CryptoService.initialize();
  });

  setUp(() async {
    service = WorkspaceService();
    tempDir = await Directory.systemTemp.createTemp('fyndo_workspace_test_');
    testPassword = SecureBytes.fromList(utf8.encode('test-password-123'));
  });

  tearDown(() async {
    // Clean up temp directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    testPassword.dispose();
  });

  group('WorkspaceService.initializeWorkspace (v2 API)', () {
    test('should create workspace marker file', () async {
      final workspacePath = tempDir.path;
      final unlocked = await service.initializeWorkspace(
        rootPath: workspacePath,
        masterPassword: testPassword,
      );

      final markerFile = File('$workspacePath/.fyndo-workspace');
      expect(await markerFile.exists(), isTrue);

      // Should have rootPath, muk, and keyring
      expect(unlocked.rootPath, equals(workspacePath));
      expect(unlocked.muk, isNotNull);
      expect(unlocked.muk.isDisposed, isFalse);
      expect(unlocked.keyring, isNotNull);

      unlocked.dispose();
    });

    test('should create vaults directory', () async {
      final workspacePath = tempDir.path;
      final unlocked = await service.initializeWorkspace(
        rootPath: workspacePath,
        masterPassword: testPassword,
      );

      final vaultsDir = Directory('$workspacePath/vaults');
      expect(await vaultsDir.exists(), isTrue);

      unlocked.dispose();
    });

    test('should create encrypted keyring', () async {
      final workspacePath = tempDir.path;
      final unlocked = await service.initializeWorkspace(
        rootPath: workspacePath,
        masterPassword: testPassword,
      );

      final keyringFile = File('$workspacePath/.fyndo-keyring.enc');
      expect(await keyringFile.exists(), isTrue);

      // Keyring should start empty (no vaults yet)
      expect(unlocked.keyring.vaults, isEmpty);

      unlocked.dispose();
    });

    test('should create workspace metadata', () async {
      final workspacePath = tempDir.path;
      final unlocked = await service.initializeWorkspace(
        rootPath: workspacePath,
        masterPassword: testPassword,
      );

      final metadataFile = File('$workspacePath/.fyndo-workspace.json');
      expect(await metadataFile.exists(), isTrue);

      // Metadata file should contain crypto params (salt, kdfParams)
      final metadataContent = await metadataFile.readAsString();
      expect(metadataContent, contains('salt'));
      expect(metadataContent, contains('kdfParams'));

      unlocked.dispose();
    });

    test('should fail if workspace already exists', () async {
      final workspacePath = tempDir.path;

      // Initialize once
      final unlocked1 = await service.initializeWorkspace(
        rootPath: workspacePath,
        masterPassword: testPassword,
      );
      unlocked1.dispose();

      // Try to initialize again - should fail
      expect(
        () => service.initializeWorkspace(
          rootPath: workspacePath,
          masterPassword: testPassword,
        ),
        throwsA(isA<WorkspaceException>()),
      );
    });
  });

  group('WorkspaceService.unlockWorkspace (v2 API)', () {
    test('should unlock workspace with correct password', () async {
      final workspacePath = tempDir.path;

      // Initialize
      final unlocked1 = await service.initializeWorkspace(
        rootPath: workspacePath,
        masterPassword: testPassword,
      );
      unlocked1.dispose();

      // Unlock
      final unlocked2 = await service.unlockWorkspace(
        rootPath: workspacePath,
        masterPassword: testPassword,
      );

      expect(unlocked2.rootPath, equals(workspacePath));
      expect(unlocked2.muk, isNotNull);
      expect(unlocked2.keyring, isNotNull);

      unlocked2.dispose();
    });

    test('should fail with wrong password', () async {
      final workspacePath = tempDir.path;

      // Initialize
      final unlocked = await service.initializeWorkspace(
        rootPath: workspacePath,
        masterPassword: testPassword,
      );
      unlocked.dispose();

      // Try to unlock with wrong password
      final wrongPassword = SecureBytes.fromList(utf8.encode('wrong-password'));

      expect(
        () => service.unlockWorkspace(
          rootPath: workspacePath,
          masterPassword: wrongPassword,
        ),
        throwsA(isA<WorkspaceException>()),
      );

      wrongPassword.dispose();
    });

    test('should fail if workspace not initialized', () async {
      final workspacePath = tempDir.path;

      expect(
        () => service.unlockWorkspace(
          rootPath: workspacePath,
          masterPassword: testPassword,
        ),
        throwsA(isA<WorkspaceException>()),
      );
    });
  });

  group('WorkspaceService.isValidWorkspace', () {
    test('should return true for initialized workspace', () async {
      final workspacePath = tempDir.path;
      final unlocked = await service.initializeWorkspace(
        rootPath: workspacePath,
        masterPassword: testPassword,
      );
      unlocked.dispose();

      expect(await service.isValidWorkspace(workspacePath), isTrue);
    });

    test('should return false for non-existent path', () async {
      expect(await service.isValidWorkspace('/nonexistent/path'), isFalse);
    });

    test('should return false for path without marker file', () async {
      final workspacePath = tempDir.path;
      expect(await service.isValidWorkspace(workspacePath), isFalse);
    });

    test('should return false for path without vaults directory', () async {
      final workspacePath = tempDir.path;
      // Create only marker file
      final markerFile = File('$workspacePath/.fyndo-workspace');
      await markerFile.create(recursive: true);
      await markerFile.writeAsString('{}');

      expect(await service.isValidWorkspace(workspacePath), isFalse);
    });
  });

  group('WorkspaceService.discoverVaults', () {
    test('should return empty list for new workspace', () async {
      final workspacePath = tempDir.path;
      final unlocked = await service.initializeWorkspace(
        rootPath: workspacePath,
        masterPassword: testPassword,
      );
      unlocked.dispose();

      final vaults = await service.discoverVaults(workspacePath);
      expect(vaults, isEmpty);
    });

    test('should discover vaults with vault.header files', () async {
      final workspacePath = tempDir.path;
      final unlocked = await service.initializeWorkspace(
        rootPath: workspacePath,
        masterPassword: testPassword,
      );
      unlocked.dispose();

      // Create some vault directories with vault.header files
      final vault1 = Directory('$workspacePath/vaults/vault-1');
      await vault1.create(recursive: true);
      await File('${vault1.path}/vault.header').writeAsString('test');

      final vault2 = Directory('$workspacePath/vaults/vault-2');
      await vault2.create(recursive: true);
      await File('${vault2.path}/vault.header').writeAsString('test');

      // Create a directory without vault.header (should be ignored)
      final notVault = Directory('$workspacePath/vaults/not-a-vault');
      await notVault.create(recursive: true);

      final vaults = await service.discoverVaults(workspacePath);

      expect(vaults, hasLength(2));
      expect(vaults.any((v) => v.endsWith('vault-1')), isTrue);
      expect(vaults.any((v) => v.endsWith('vault-2')), isTrue);
      expect(vaults.any((v) => v.contains('not-a-vault')), isFalse);
    });
  });

  group('WorkspaceService.getNewVaultPath', () {
    test('should generate path in vaults directory', () async {
      final workspacePath = tempDir.path;
      final vaultPath = service.getNewVaultPath(workspacePath, 'test-vault-id');

      expect(vaultPath, contains('$workspacePath/vaults/'));
      expect(vaultPath, contains('test-vault-id'));
    });

    test('should generate unique paths for different IDs', () async {
      final workspacePath = tempDir.path;
      final path1 = service.getNewVaultPath(workspacePath, 'vault-1');
      final path2 = service.getNewVaultPath(workspacePath, 'vault-2');

      expect(path1, isNot(equals(path2)));
    });

    test('should create valid directory structure', () async {
      final workspacePath = tempDir.path;
      final vaultPath = service.getNewVaultPath(workspacePath, 'test-vault');
      final vaultDir = Directory(vaultPath);

      // The path should be creatable
      await vaultDir.create(recursive: true);
      expect(await vaultDir.exists(), isTrue);
    });
  });

  group('WorkspaceService.changeMasterPassword (v2 API)', () {
    test('should change password and re-encrypt keyring', () async {
      final workspacePath = tempDir.path;

      // Initialize with first password
      final unlocked1 = await service.initializeWorkspace(
        rootPath: workspacePath,
        masterPassword: testPassword,
      );

      // Add a vault to keyring to ensure re-encryption works
      final vaultId = 'test-vault-123';
      final vaultKeyBytes = crypto.random.symmetricKey();
      unlocked1.keyring.addVault(vaultId, base64Encode(vaultKeyBytes.bytes));

      // Change password
      final newPassword = SecureBytes.fromList(utf8.encode('new-password-456'));
      await service.changeMasterPassword(
        workspace: unlocked1,
        currentPassword: testPassword,
        newPassword: newPassword,
      );

      unlocked1.dispose();

      // Old password should fail
      expect(
        () => service.unlockWorkspace(
          rootPath: workspacePath,
          masterPassword: testPassword,
        ),
        throwsA(isA<WorkspaceException>()),
      );

      // New password should work
      final unlocked2 = await service.unlockWorkspace(
        rootPath: workspacePath,
        masterPassword: newPassword,
      );

      // Keyring should still have the vault
      expect(unlocked2.keyring.vaults, hasLength(1));
      expect(unlocked2.keyring.vaults.containsKey(vaultId), isTrue);

      unlocked2.dispose();
      newPassword.dispose();
      vaultKeyBytes.dispose();
    });

    test('should fail with wrong current password', () async {
      final workspacePath = tempDir.path;

      final unlocked = await service.initializeWorkspace(
        rootPath: workspacePath,
        masterPassword: testPassword,
      );

      final wrongPassword = SecureBytes.fromList(utf8.encode('wrong'));
      final newPassword = SecureBytes.fromList(utf8.encode('new'));

      expect(
        () => service.changeMasterPassword(
          workspace: unlocked,
          currentPassword: wrongPassword,
          newPassword: newPassword,
        ),
        throwsA(isA<WorkspaceException>()),
      );

      unlocked.dispose();
      wrongPassword.dispose();
      newPassword.dispose();
    });
  });
}
