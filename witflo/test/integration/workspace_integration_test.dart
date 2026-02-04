// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Integration Tests - Full workspace lifecycle and scenarios
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:witflo_app/core/crypto/crypto.dart';
import 'package:witflo_app/core/workspace/workspace_service.dart';

import '../helpers/crypto_test_helper.dart';

void main() {
  late CryptoService crypto;
  late WorkspaceService workspaceService;
  late Directory tempDir;

  setUpAll(() async {
    crypto = await initializeCryptoForTests();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fyndo_integration_');
    workspaceService = WorkspaceService();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Workspace Integration Tests', () {
    test('full onboarding flow - initialize and unlock', () async {
      final workspacePath = tempDir.path;
      final password = SecureBytes.fromList(utf8.encode('test-password-123'));

      // Step 1: Initialize workspace
      final unlockedWorkspace = await workspaceService.initializeWorkspace(
        rootPath: workspacePath,
        masterPassword: password,
      );

      expect(unlockedWorkspace, isNotNull);
      expect(unlockedWorkspace.rootPath, equals(workspacePath));
      expect(unlockedWorkspace.keyring.vaults.isEmpty, isTrue);

      // Lock workspace
      unlockedWorkspace.dispose();

      // Step 2: Unlock workspace
      final password2 = SecureBytes.fromList(utf8.encode('test-password-123'));
      final reopened = await workspaceService.unlockWorkspace(
        rootPath: workspacePath,
        masterPassword: password2,
      );

      expect(reopened, isNotNull);
      expect(reopened.rootPath, equals(workspacePath));

      reopened.dispose();
    });

    test('create multiple vaults in workspace', () async {
      final workspacePath = tempDir.path;
      final password = SecureBytes.fromList(utf8.encode('password'));

      final workspace = await workspaceService.initializeWorkspace(
        rootPath: workspacePath,
        masterPassword: password,
      );

      // Add multiple vaults to keyring
      workspace.keyring = workspace.keyring
          .addVault('vault-1', 'key-1-base64')
          .addVault('vault-2', 'key-2-base64')
          .addVault('vault-3', 'key-3-base64');

      expect(workspace.keyring.vaults.length, equals(3));
      expect(workspace.getVaultKey('vault-1'), isNotNull);
      expect(workspace.getVaultKey('vault-2'), isNotNull);
      expect(workspace.getVaultKey('vault-3'), isNotNull);

      workspace.dispose();
    });

    test('lock and unlock cycle', () async {
      final workspacePath = tempDir.path;
      final password1 = SecureBytes.fromList(utf8.encode('my-password'));

      // Initialize
      final workspace1 = await workspaceService.initializeWorkspace(
        rootPath: workspacePath,
        masterPassword: password1,
      );

      workspace1.keyring = workspace1.keyring.addVault('vault-1', 'key-1');

      // Lock
      workspace1.dispose();

      // Unlock
      final password2 = SecureBytes.fromList(utf8.encode('my-password'));
      final workspace2 = await workspaceService.unlockWorkspace(
        rootPath: workspacePath,
        masterPassword: password2,
      );

      // Verify vault is still there
      expect(workspace2.keyring.vaults.length, equals(1));
      expect(workspace2.getVaultKey('vault-1'), isNotNull);

      workspace2.dispose();
    });

    test('change master password', () async {
      final workspacePath = tempDir.path;
      final oldPassword = SecureBytes.fromList(utf8.encode('old-password'));

      // Initialize with old password
      final workspace = await workspaceService.initializeWorkspace(
        rootPath: workspacePath,
        masterPassword: oldPassword,
      );

      workspace.keyring = workspace.keyring.addVault('vault-1', 'key-1');

      // Change password
      final currentPassword = SecureBytes.fromList(utf8.encode('old-password'));
      final newPassword = SecureBytes.fromList(utf8.encode('new-password'));

      await workspaceService.changeMasterPassword(
        workspace: workspace,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      workspace.dispose();

      // Try unlocking with old password (should fail)
      final tryOld = SecureBytes.fromList(utf8.encode('old-password'));
      expect(
        () => workspaceService.unlockWorkspace(
          rootPath: workspacePath,
          masterPassword: tryOld,
        ),
        throwsA(isA<WorkspaceException>()),
      );

      // Try unlocking with new password (should succeed)
      final tryNew = SecureBytes.fromList(utf8.encode('new-password'));
      final reopened = await workspaceService.unlockWorkspace(
        rootPath: workspacePath,
        masterPassword: tryNew,
      );

      expect(reopened.keyring.vaults.length, equals(1));
      expect(reopened.getVaultKey('vault-1'), isNotNull);

      reopened.dispose();
    });

    test('invalid password handling', () async {
      final workspacePath = tempDir.path;
      final password = SecureBytes.fromList(utf8.encode('correct-password'));

      await workspaceService.initializeWorkspace(
          rootPath: workspacePath,
          masterPassword: password,
        )
        ..dispose();

      // Try unlocking with wrong password
      final wrongPassword = SecureBytes.fromList(utf8.encode('wrong-password'));

      expect(
        () => workspaceService.unlockWorkspace(
          rootPath: workspacePath,
          masterPassword: wrongPassword,
        ),
        throwsA(isA<WorkspaceException>()),
      );
    });

    test('auto-lock scenario - simulate app background', () async {
      final workspacePath = tempDir.path;
      final password = SecureBytes.fromList(utf8.encode('password'));

      final workspace = await workspaceService.initializeWorkspace(
        rootPath: workspacePath,
        masterPassword: password,
      );

      workspace.keyring = workspace.keyring.addVault('vault-1', 'key-1');

      // Simulate auto-lock
      workspaceService.lockWorkspace(workspace);

      // Workspace should be disposed
      expect(workspace.muk.isDisposed, isTrue);

      // Must unlock again
      final password2 = SecureBytes.fromList(utf8.encode('password'));
      final reopened = await workspaceService.unlockWorkspace(
        rootPath: workspacePath,
        masterPassword: password2,
      );

      expect(reopened.keyring.vaults.length, equals(1));

      reopened.dispose();
    });

    test('workspace with no vaults', () async {
      final workspacePath = tempDir.path;
      final password = SecureBytes.fromList(utf8.encode('password'));

      final workspace = await workspaceService.initializeWorkspace(
        rootPath: workspacePath,
        masterPassword: password,
      );

      // No vaults created yet
      expect(workspace.keyring.vaults.isEmpty, isTrue);

      workspace.dispose();

      // Reopen
      final password2 = SecureBytes.fromList(utf8.encode('password'));
      final reopened = await workspaceService.unlockWorkspace(
        rootPath: workspacePath,
        masterPassword: password2,
      );

      expect(reopened.keyring.vaults.isEmpty, isTrue);

      reopened.dispose();
    });

    test('get vault key from unlocked workspace', () async {
      final workspacePath = tempDir.path;
      final password = SecureBytes.fromList(utf8.encode('password'));

      final workspace = await workspaceService.initializeWorkspace(
        rootPath: workspacePath,
        masterPassword: password,
      );

      workspace.keyring = workspace.keyring.addVault(
        'vault-1',
        'abc123base64==',
      );

      final vaultKey = workspace.getVaultKey('vault-1');

      expect(vaultKey, isNotNull);
      expect(vaultKey.isDisposed, isFalse);

      workspace.dispose();

      // After dispose, vault key should be disposed too
      expect(vaultKey.isDisposed, isTrue);
    });

    test('attempt to access nonexistent vault', () async {
      final workspacePath = tempDir.path;
      final password = SecureBytes.fromList(utf8.encode('password'));

      final workspace = await workspaceService.initializeWorkspace(
        rootPath: workspacePath,
        masterPassword: password,
      );

      workspace.keyring = workspace.keyring.addVault('vault-1', 'key-1');

      expect(
        () => workspace.getVaultKey('vault-999'),
        throwsA(isA<StateError>()),
      );

      workspace.dispose();
    });
  });
}
