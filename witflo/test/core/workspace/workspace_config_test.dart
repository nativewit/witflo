// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// WorkspaceConfig Tests - Model and serialization tests
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:witflo_app/core/workspace/workspace_config.dart';

void main() {
  group('WorkspaceConfig', () {
    test('should create config with required fields', () {
      final config = WorkspaceConfig.create(rootPath: '/test/workspace');

      expect(config.rootPath, equals('/test/workspace'));
      expect(config.recentWorkspaces, isEmpty);
      expect(config.lastAccessedAt, isNotNull);
    });

    test('should serialize to JSON correctly', () {
      final config = WorkspaceConfig.create(rootPath: '/test/workspace');
      final json = config.toJson();

      expect(json['rootPath'], equals('/test/workspace'));
      expect(json['recentWorkspaces'], isA<List>());
      expect(json['lastAccessedAt'], isA<String>());
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'rootPath': '/test/workspace',
        'recentWorkspaces': ['/recent/one', '/recent/two'],
        'lastAccessedAt': DateTime.now().toIso8601String(),
      };

      final config = WorkspaceConfig.fromJson(json);

      expect(config.rootPath, equals('/test/workspace'));
      expect(config.recentWorkspaces, hasLength(2));
      expect(config.recentWorkspaces.first, equals('/recent/one'));
    });

    test('should add workspace to recent list', () {
      final config = WorkspaceConfig.create(rootPath: '/test/workspace');
      final updated = config.addRecentWorkspace('/new/workspace');

      expect(updated.recentWorkspaces, contains('/new/workspace'));
      expect(updated.recentWorkspaces.first, equals('/new/workspace'));
    });

    test('should limit recent workspaces to 10', () {
      var config = WorkspaceConfig.create(rootPath: '/test/workspace');

      // Add 15 workspaces
      for (var i = 0; i < 15; i++) {
        config = config.addRecentWorkspace('/workspace/$i');
      }

      expect(config.recentWorkspaces, hasLength(10));
      expect(config.recentWorkspaces.first, equals('/workspace/14'));
    });

    test('should not duplicate recent workspaces', () {
      var config = WorkspaceConfig.create(rootPath: '/test/workspace');

      config = config.addRecentWorkspace('/workspace/one');
      config = config.addRecentWorkspace('/workspace/two');
      config = config.addRecentWorkspace('/workspace/one'); // Duplicate

      expect(config.recentWorkspaces, hasLength(2));
      expect(config.recentWorkspaces.first, equals('/workspace/one'));
    });

    test('should update lastAccessedAt on touch', () async {
      final config = WorkspaceConfig.create(rootPath: '/test/workspace');
      final oldTimestamp = DateTime.parse(config.lastAccessedAt);

      // Wait a bit to ensure timestamp difference
      await Future.delayed(const Duration(milliseconds: 10));

      final touched = config.touch();
      final newTimestamp = DateTime.parse(touched.lastAccessedAt);

      expect(newTimestamp.isAfter(oldTimestamp), isTrue);
    });

    test('should round-trip through JSON', () {
      final original = WorkspaceConfig.create(
        rootPath: '/test/workspace',
      ).addRecentWorkspace('/recent/one').addRecentWorkspace('/recent/two');

      final json = jsonEncode(original.toJson());
      final decoded = WorkspaceConfig.fromJson(jsonDecode(json));

      expect(decoded.rootPath, equals(original.rootPath));
      expect(decoded.recentWorkspaces, equals(original.recentWorkspaces));
    });
  });
}
