// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// WorkspaceService Tests - Workspace initialization and management tests
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fyndo_app/core/workspace/workspace_service.dart';

void main() {
  late WorkspaceService service;
  late Directory tempDir;

  setUpAll(() {
    // Initialize Flutter binding for SharedPreferences
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    service = WorkspaceService();
    // Create a fresh temp directory for each test
    tempDir = await Directory.systemTemp.createTemp('fyndo_workspace_test_');
  });

  tearDown(() async {
    // Clean up temp directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('WorkspaceService.initializeWorkspace', () {
    test('should create workspace marker file', () async {
      final workspacePath = tempDir.path;
      await service.initializeWorkspace(workspacePath);

      final markerFile = File('$workspacePath/.fyndo-workspace');
      expect(await markerFile.exists(), isTrue);
    });

    test('should create vaults directory', () async {
      final workspacePath = tempDir.path;
      await service.initializeWorkspace(workspacePath);

      final vaultsDir = Directory('$workspacePath/vaults');
      expect(await vaultsDir.exists(), isTrue);
    });

    test('should save workspace config', () async {
      final workspacePath = tempDir.path;
      final config = await service.initializeWorkspace(workspacePath);

      expect(config.rootPath, equals(workspacePath));

      // Should be able to load the config back
      final loaded = await service.loadWorkspaceConfig();
      expect(loaded, isNotNull);
      expect(loaded!.rootPath, equals(workspacePath));
    });

    test('should not reinitialize existing workspace', () async {
      final workspacePath = tempDir.path;

      // First initialization
      await service.initializeWorkspace(workspacePath);

      // Wait a bit
      await Future.delayed(const Duration(milliseconds: 10));

      // Try to initialize again - should return existing config
      final config2 = await service.initializeWorkspace(workspacePath);

      // Should have same root path but might have updated timestamp
      expect(config2.rootPath, equals(workspacePath));
    });
  });

  group('WorkspaceService.isValidWorkspace', () {
    test('should return true for initialized workspace', () async {
      final workspacePath = tempDir.path;
      await service.initializeWorkspace(workspacePath);

      expect(await service.isValidWorkspace(workspacePath), isTrue);
    });

    test('should return false for non-existent path', () async {
      expect(await service.isValidWorkspace('/nonexistent/path'), isFalse);
    });

    test('should return false for path without marker file', () async {
      // Create directory but don't initialize
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
      await service.initializeWorkspace(workspacePath);

      final vaults = await service.discoverVaults(workspacePath);
      expect(vaults, isEmpty);
    });

    test('should discover vaults with vault.header files', () async {
      final workspacePath = tempDir.path;
      await service.initializeWorkspace(workspacePath);

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
      await service.initializeWorkspace(workspacePath);

      final vaultPath = service.getNewVaultPath(workspacePath, 'test-vault-id');

      expect(vaultPath, contains('$workspacePath/vaults/'));
      expect(vaultPath, contains('test-vault-id'));
    });

    test('should generate unique paths for different IDs', () async {
      final workspacePath = tempDir.path;
      await service.initializeWorkspace(workspacePath);

      final path1 = service.getNewVaultPath(workspacePath, 'vault-1');
      final path2 = service.getNewVaultPath(workspacePath, 'vault-2');

      expect(path1, isNot(equals(path2)));
    });

    test('should create valid directory structure', () async {
      final workspacePath = tempDir.path;
      await service.initializeWorkspace(workspacePath);

      final vaultPath = service.getNewVaultPath(workspacePath, 'test-vault');
      final vaultDir = Directory(vaultPath);

      // The path should be creatable
      await vaultDir.create(recursive: true);
      expect(await vaultDir.exists(), isTrue);
    });
  });

  group('WorkspaceService.switchWorkspace', () {
    test('should update config with new root path', () async {
      // Initialize first workspace
      final workspace1 = await Directory.systemTemp.createTemp('fyndo_ws1_');
      await service.initializeWorkspace(workspace1.path);

      // Switch to second workspace
      final workspace2 = await Directory.systemTemp.createTemp('fyndo_ws2_');
      final config = await service.switchWorkspace(workspace2.path);

      expect(config.rootPath, equals(workspace2.path));
      expect(config.recentWorkspaces, contains(workspace1.path));

      // Clean up
      await workspace1.delete(recursive: true);
      await workspace2.delete(recursive: true);
    });

    test('should add old workspace to recent list', () async {
      final workspace1 = await Directory.systemTemp.createTemp('fyndo_ws1_');
      await service.initializeWorkspace(workspace1.path);

      final workspace2 = await Directory.systemTemp.createTemp('fyndo_ws2_');
      final config = await service.switchWorkspace(workspace2.path);

      expect(config.recentWorkspaces.first, equals(workspace1.path));

      // Clean up
      await workspace1.delete(recursive: true);
      await workspace2.delete(recursive: true);
    });
  });
}
