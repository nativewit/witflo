// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// WorkspaceKeyring Tests - Unit tests for workspace keyring
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:witflo_app/core/workspace/workspace_keyring.dart';
import 'package:witflo_app/core/workspace/vault_key_entry.dart';

void main() {
  group('WorkspaceKeyring', () {
    test('should create empty keyring', () {
      final keyring = WorkspaceKeyring.empty();

      expect(keyring.version, equals(1));
      expect(keyring.vaults.isEmpty, isTrue);
      expect(keyring.modifiedAt, isNotNull);
    });

    test('should add vault to keyring', () {
      final keyring = WorkspaceKeyring.empty();
      final vaultKey = 'abc123base64key==';

      final updated = keyring.addVault('vault-1', vaultKey);

      expect(updated.vaults.length, equals(1));
      expect(updated.vaults.containsKey('vault-1'), isTrue);
      expect(updated.vaults['vault-1']!.vaultKey, equals(vaultKey));
      expect(updated.modifiedAt.isAfter(keyring.modifiedAt), isTrue);
    });

    test('should replace existing vault on add', () {
      final keyring = WorkspaceKeyring.empty().addVault('vault-1', 'old-key');

      final updated = keyring.addVault('vault-1', 'new-key');

      expect(updated.vaults.length, equals(1));
      expect(updated.vaults['vault-1']!.vaultKey, equals('new-key'));
    });

    test('should add multiple vaults', () {
      final keyring = WorkspaceKeyring.empty()
          .addVault('vault-1', 'key-1')
          .addVault('vault-2', 'key-2')
          .addVault('vault-3', 'key-3');

      expect(keyring.vaults.length, equals(3));
      expect(keyring.vaults['vault-1']!.vaultKey, equals('key-1'));
      expect(keyring.vaults['vault-2']!.vaultKey, equals('key-2'));
      expect(keyring.vaults['vault-3']!.vaultKey, equals('key-3'));
    });

    test('should remove vault from keyring', () {
      final keyring = WorkspaceKeyring.empty()
          .addVault('vault-1', 'key-1')
          .addVault('vault-2', 'key-2');

      final updated = keyring.removeVault('vault-1');

      expect(updated.vaults.length, equals(1));
      expect(updated.vaults.containsKey('vault-1'), isFalse);
      expect(updated.vaults.containsKey('vault-2'), isTrue);
      expect(updated.modifiedAt.isAfter(keyring.modifiedAt), isTrue);
    });

    test('should return unchanged keyring when removing nonexistent vault', () {
      final keyring = WorkspaceKeyring.empty().addVault('vault-1', 'key-1');

      final updated = keyring.removeVault('vault-999');

      expect(updated, same(keyring));
    });

    test('should get vault key by ID', () {
      final keyring = WorkspaceKeyring.empty()
          .addVault('vault-1', 'key-1')
          .addVault('vault-2', 'key-2');

      final key1 = keyring.getVaultKey('vault-1');
      final key2 = keyring.getVaultKey('vault-2');
      final key3 = keyring.getVaultKey('vault-999');

      expect(key1, equals('key-1'));
      expect(key2, equals('key-2'));
      expect(key3, isNull);
    });

    test('should control sync enabled per vault', () {
      final keyring = WorkspaceKeyring.empty()
          .addVault('vault-1', 'key-1', syncEnabled: true)
          .addVault('vault-2', 'key-2', syncEnabled: false);

      expect(keyring.vaults['vault-1']!.syncEnabled, isTrue);
      expect(keyring.vaults['vault-2']!.syncEnabled, isFalse);
    });

    test('should serialize to JSON', () {
      final now = DateTime.utc(2026, 1, 31, 12, 0, 0);
      final keyring = WorkspaceKeyring.empty()
          .addVault('vault-1', 'key-1')
          .rebuild((b) => b..modifiedAt = now);

      final json = keyring.toJson();

      expect(json['version'], equals(1));
      expect(json['modified_at'], equals(now.toIso8601String()));

      // Check vaults structure (convert to dynamic for testing)
      final vaultsData = json['vaults'];
      expect(vaultsData, isNotNull);
    });

    test('should deserialize from JSON', () {
      final now = DateTime.utc(2026, 1, 31, 12, 0, 0);
      final json = {
        'version': 1,
        'vaults': {
          'vault-1': {
            'vault_key': 'key-1',
            'created_at': now.toIso8601String(),
            'sync_enabled': true,
          },
        },
        'modified_at': now.toIso8601String(),
      };

      final keyring = WorkspaceKeyring.fromJson(json);

      expect(keyring.version, equals(1));
      expect(keyring.vaults.length, equals(1));
      expect(keyring.vaults['vault-1']!.vaultKey, equals('key-1'));
      expect(keyring.modifiedAt, equals(now));
    });

    test('should deserialize from previously serialized JSON', () {
      // This tests the actual usage - JSON created manually (e.g., from file)
      final now = DateTime.utc(2026, 1, 31, 12, 0, 0);
      final json = {
        'version': 1,
        'vaults': {
          'vault-1': {
            'vault_key': 'key-1',
            'created_at': now.toIso8601String(),
            'sync_enabled': true,
          },
          'vault-2': {
            'vault_key': 'key-2',
            'created_at': now.toIso8601String(),
            'sync_enabled': false,
          },
        },
        'modified_at': now.toIso8601String(),
      };

      final keyring = WorkspaceKeyring.fromJson(json);

      expect(keyring.version, equals(1));
      expect(keyring.vaults.length, equals(2));
      expect(keyring.vaults['vault-1']!.vaultKey, equals('key-1'));
      expect(keyring.vaults['vault-1']!.syncEnabled, isTrue);
      expect(keyring.vaults['vault-2']!.vaultKey, equals('key-2'));
      expect(keyring.vaults['vault-2']!.syncEnabled, isFalse);
      expect(keyring.modifiedAt, equals(now));
    });

    test('should handle empty vaults in JSON', () {
      final json = {
        'version': 1,
        'vaults': <String, dynamic>{},
        'modified_at': DateTime.now().toIso8601String(),
      };

      final keyring = WorkspaceKeyring.fromJson(json);

      expect(keyring.vaults.isEmpty, isTrue);
    });

    test('should handle missing version in JSON (default to 1)', () {
      final json = {
        'vaults': <String, dynamic>{},
        'modified_at': DateTime.now().toIso8601String(),
      };

      final keyring = WorkspaceKeyring.fromJson(json);

      expect(keyring.version, equals(1));
    });
  });
}
