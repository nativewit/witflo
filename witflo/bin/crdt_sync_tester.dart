// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// CRDT Sync Tester CLI - Test CRDT merge when files are synced externally
// ═══════════════════════════════════════════════════════════════════════════
//
// PURPOSE:
// This CLI tool simulates a third-party sync service (Dropbox, iCloud, etc.)
// modifying vault files and tests that the app correctly:
// 1. Detects file changes via file watchers
// 2. Applies CRDT merge logic (Last-Write-Wins with Lamport timestamps)
// 3. Updates UI state automatically
//
// USAGE:
//   dart run bin/crdt_sync_tester.dart --workspace <path> [options]
//
// COMMANDS:
//   watch       - Watch a workspace for file changes (monitoring mode)
//   simulate    - Simulate external sync by writing operations to a vault
//   verify      - Verify CRDT merge by comparing expected vs actual state
//   stress      - Run stress test with concurrent modifications
//
// EXAMPLES:
//   # Watch workspace for changes
//   dart run bin/crdt_sync_tester.dart watch --workspace ~/witflo-workspace
//
//   # Simulate creating a note from "another device"
//   dart run bin/crdt_sync_tester.dart simulate create-note \
//     --workspace ~/witflo-workspace \
//     --vault <vault-id> \
//     --title "Synced Note" \
//     --content "Content from another device"
//
//   # Run stress test with concurrent edits
//   dart run bin/crdt_sync_tester.dart stress \
//     --workspace ~/witflo-workspace \
//     --operations 100 \
//     --concurrency 10
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Entry point for the CRDT sync tester CLI.
void main(List<String> args) async {
  final tester = CrdtSyncTester();
  await tester.run(args);
}

/// CLI tool for testing CRDT sync behavior.
class CrdtSyncTester {
  final _uuid = const Uuid();
  int _lamportClock = 0;
  String _deviceId = '';

  CrdtSyncTester() {
    _deviceId = 'test-device-${_uuid.v4().substring(0, 8)}';
  }

  Future<void> run(List<String> args) async {
    if (args.isEmpty) {
      _printUsage();
      return;
    }

    final command = args[0];
    final options = _parseOptions(args.skip(1).toList());

    switch (command) {
      case 'watch':
        await _runWatch(options);
        break;
      case 'simulate':
        if (args.length < 2) {
          _printError('simulate requires a subcommand');
          return;
        }
        await _runSimulate(args[1], options);
        break;
      case 'verify':
        await _runVerify(options);
        break;
      case 'stress':
        await _runStress(options);
        break;
      case 'help':
      case '--help':
      case '-h':
        _printUsage();
        break;
      default:
        _printError('Unknown command: $command');
        _printUsage();
    }
  }

  /// Parse command-line options into a map.
  Map<String, String> _parseOptions(List<String> args) {
    final options = <String, String>{};
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg.startsWith('--')) {
        final key = arg.substring(2);
        if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
          options[key] = args[i + 1];
          i++;
        } else {
          options[key] = 'true';
        }
      }
    }
    return options;
  }

  /// Watch command - monitor workspace for file changes.
  Future<void> _runWatch(Map<String, String> options) async {
    final workspace = options['workspace'];
    if (workspace == null) {
      _printError('--workspace is required');
      return;
    }

    final workspacePath = _expandPath(workspace);
    if (!await Directory(workspacePath).exists()) {
      _printError('Workspace not found: $workspacePath');
      return;
    }

    _printInfo('Watching workspace: $workspacePath');
    _printInfo('Press Ctrl+C to stop');
    _printSeparator();

    // Find all vault directories
    final vaults = await _findVaults(workspacePath);
    if (vaults.isEmpty) {
      _printWarning('No vaults found in workspace');
      return;
    }

    _printInfo('Found ${vaults.length} vault(s):');
    for (final vault in vaults) {
      _printInfo('  - ${p.basename(vault)}');
    }
    _printSeparator();

    // Set up file watchers for each vault
    final watchers = <StreamSubscription>[];

    for (final vaultPath in vaults) {
      final refsDir = Directory(p.join(vaultPath, 'refs'));
      final syncDir = Directory(p.join(vaultPath, 'sync'));

      if (await refsDir.exists()) {
        final watcher = refsDir.watch(
          events: FileSystemEvent.all,
          recursive: true,
        );
        watchers.add(
          watcher.listen((event) {
            _handleFileEvent(vaultPath, event);
          }),
        );
      }

      if (await syncDir.exists()) {
        final watcher = syncDir.watch(
          events: FileSystemEvent.all,
          recursive: true,
        );
        watchers.add(
          watcher.listen((event) {
            _handleFileEvent(vaultPath, event);
          }),
        );
      }
    }

    // Keep running until interrupted
    await ProcessSignal.sigint.watch().first;

    _printInfo('\nStopping watchers...');
    for (final sub in watchers) {
      await sub.cancel();
    }
  }

  /// Handle a file system event.
  void _handleFileEvent(String vaultPath, FileSystemEvent event) {
    final vaultId = p.basename(vaultPath);
    final relativePath = event.path.replaceFirst(vaultPath, '');
    final eventType = _eventTypeName(event.type);
    final timestamp = DateTime.now().toIso8601String();

    _printEvent('[$timestamp] [$vaultId] $eventType: $relativePath');

    // Highlight important files
    if (relativePath.contains('notes.jsonl.enc')) {
      _printHighlight('  -> Notes index changed! App should reload notes.');
    } else if (relativePath.contains('notebooks.jsonl.enc')) {
      _printHighlight(
        '  -> Notebooks index changed! App should reload notebooks.',
      );
    } else if (relativePath.endsWith('.op.enc')) {
      _printHighlight(
        '  -> New sync operation detected! App should apply CRDT merge.',
      );
    }
  }

  /// Simulate command - create synthetic sync operations.
  Future<void> _runSimulate(
    String subCommand,
    Map<String, String> options,
  ) async {
    final workspace = options['workspace'];
    if (workspace == null) {
      _printError('--workspace is required');
      return;
    }

    final workspacePath = _expandPath(workspace);
    final vaultId = options['vault'];

    String? targetVault;
    if (vaultId != null) {
      targetVault = p.join(workspacePath, 'vaults', vaultId);
      if (!await Directory(targetVault).exists()) {
        _printError('Vault not found: $vaultId');
        return;
      }
    } else {
      // Find first vault
      final vaults = await _findVaults(workspacePath);
      if (vaults.isEmpty) {
        _printError('No vaults found in workspace');
        return;
      }
      targetVault = vaults.first;
      _printInfo('Using vault: ${p.basename(targetVault)}');
    }

    switch (subCommand) {
      case 'create-note':
        await _simulateCreateNote(targetVault, options);
        break;
      case 'update-note':
        await _simulateUpdateNote(targetVault, options);
        break;
      case 'delete-note':
        await _simulateDeleteNote(targetVault, options);
        break;
      case 'create-notebook':
        await _simulateCreateNotebook(targetVault, options);
        break;
      case 'touch-index':
        await _simulateTouchIndex(targetVault, options);
        break;
      default:
        _printError('Unknown simulate subcommand: $subCommand');
        _printInfo(
          'Available: create-note, update-note, delete-note, create-notebook, touch-index',
        );
    }
  }

  /// Simulate creating a note from another device.
  Future<void> _simulateCreateNote(
    String vaultPath,
    Map<String, String> options,
  ) async {
    final noteId = options['id'] ?? _uuid.v4();
    final title =
        options['title'] ??
        'Synced Note ${DateTime.now().millisecondsSinceEpoch}';
    final content =
        options['content'] ?? 'Content created by external sync tester';
    final notebookId = options['notebook'];

    _lamportClock++;
    final now = DateTime.now().toUtc();

    final operation = {
      'op_id': _uuid.v4(),
      'type': 'createNote',
      'target_id': noteId,
      'timestamp': _lamportClock,
      'device_id': _deviceId,
      'created_at': now.toIso8601String(),
      'payload': {
        'note_id': noteId,
        'title': title,
        'content': content,
        'notebook_id': notebookId,
        'tags': <String>[],
        'is_pinned': false,
        'is_archived': false,
        'created_at': now.toIso8601String(),
        'modified_at': now.toIso8601String(),
      },
    };

    await _writeSyncOperation(vaultPath, operation);
    _printSuccess('Created sync operation for note: $noteId');
    _printInfo('  Title: $title');
    _printInfo('  Timestamp: $_lamportClock');
    _printInfo('  Device: $_deviceId');
  }

  /// Simulate updating a note from another device.
  Future<void> _simulateUpdateNote(
    String vaultPath,
    Map<String, String> options,
  ) async {
    final noteId = options['id'];
    if (noteId == null) {
      _printError('--id is required for update-note');
      return;
    }

    _lamportClock++;
    final now = DateTime.now().toUtc();

    final payload = <String, dynamic>{
      'note_id': noteId,
      'modified_at': now.toIso8601String(),
    };

    if (options['title'] != null) payload['title'] = options['title'];
    if (options['content'] != null) payload['content'] = options['content'];

    final operation = {
      'op_id': _uuid.v4(),
      'type': 'updateNote',
      'target_id': noteId,
      'timestamp': _lamportClock,
      'device_id': _deviceId,
      'created_at': now.toIso8601String(),
      'payload': payload,
    };

    await _writeSyncOperation(vaultPath, operation);
    _printSuccess('Created update operation for note: $noteId');
    _printInfo('  Timestamp: $_lamportClock');
  }

  /// Simulate deleting a note from another device.
  Future<void> _simulateDeleteNote(
    String vaultPath,
    Map<String, String> options,
  ) async {
    final noteId = options['id'];
    if (noteId == null) {
      _printError('--id is required for delete-note');
      return;
    }

    _lamportClock++;
    final now = DateTime.now().toUtc();

    final operation = {
      'op_id': _uuid.v4(),
      'type': 'deleteNote',
      'target_id': noteId,
      'timestamp': _lamportClock,
      'device_id': _deviceId,
      'created_at': now.toIso8601String(),
      'payload': {'note_id': noteId, 'deleted_at': now.toIso8601String()},
    };

    await _writeSyncOperation(vaultPath, operation);
    _printSuccess('Created delete operation for note: $noteId');
    _printWarning(
      '  Note: Delete operations always win over concurrent updates (CRDT rule)',
    );
  }

  /// Simulate creating a notebook from another device.
  Future<void> _simulateCreateNotebook(
    String vaultPath,
    Map<String, String> options,
  ) async {
    final notebookId = options['id'] ?? _uuid.v4();
    final name =
        options['name'] ??
        'Synced Notebook ${DateTime.now().millisecondsSinceEpoch}';
    final description = options['description'];
    final color = options['color'];
    final icon = options['icon'];

    _lamportClock++;
    final now = DateTime.now().toUtc();

    final operation = {
      'op_id': _uuid.v4(),
      'type': 'createNotebook',
      'target_id': notebookId,
      'timestamp': _lamportClock,
      'device_id': _deviceId,
      'created_at': now.toIso8601String(),
      'payload': {
        'notebook_id': notebookId,
        'name': name,
        'description': description,
        'color': color,
        'icon': icon,
        'created_at': now.toIso8601String(),
        'modified_at': now.toIso8601String(),
      },
    };

    await _writeSyncOperation(vaultPath, operation);
    _printSuccess('Created sync operation for notebook: $notebookId');
    _printInfo('  Name: $name');
    _printInfo('  Timestamp: $_lamportClock');
  }

  /// Simulate touching an index file (triggers reload).
  Future<void> _simulateTouchIndex(
    String vaultPath,
    Map<String, String> options,
  ) async {
    final indexType = options['type'] ?? 'notes';

    String indexPath;
    switch (indexType) {
      case 'notes':
        indexPath = p.join(vaultPath, 'refs', 'notes.jsonl.enc');
        break;
      case 'notebooks':
        indexPath = p.join(vaultPath, 'refs', 'notebooks.jsonl.enc');
        break;
      case 'tags':
        indexPath = p.join(vaultPath, 'refs', 'tags.jsonl.enc');
        break;
      default:
        _printError('Unknown index type: $indexType');
        return;
    }

    final file = File(indexPath);
    if (await file.exists()) {
      // Touch file by appending empty content (doesn't corrupt encrypted data)
      final stat = await file.stat();
      await file.setLastModified(DateTime.now());
      _printSuccess('Touched $indexType index file');
      _printInfo('  Path: $indexPath');
      _printInfo('  Previous modified: ${stat.modified}');
      _printInfo('  New modified: ${DateTime.now()}');
    } else {
      _printWarning('Index file does not exist: $indexPath');
      _printInfo('Creating empty marker file...');
      await file.parent.create(recursive: true);
      await file.writeAsBytes([]);
      _printSuccess('Created empty index file');
    }
  }

  /// Write a sync operation to the vault's pending directory.
  Future<void> _writeSyncOperation(
    String vaultPath,
    Map<String, dynamic> operation,
  ) async {
    final pendingDir = Directory(p.join(vaultPath, 'sync', 'pending'));
    if (!await pendingDir.exists()) {
      await pendingDir.create(recursive: true);
    }

    final opId = operation['op_id'] as String;

    // Write both .op.json (for human readability) and .op.enc (for app detection)
    // The app's file watcher monitors for *.op.enc files
    final jsonFile = File(p.join(pendingDir.path, '$opId.op.json'));
    final encFile = File(p.join(pendingDir.path, '$opId.op.enc'));

    final content = const JsonEncoder.withIndent('  ').convert(operation);

    // Write human-readable JSON
    await jsonFile.writeAsString(content);

    // Write .op.enc so the app's file watcher detects it
    // NOTE: This is plaintext JSON, not encrypted - for testing only!
    await encFile.writeAsBytes(utf8.encode(content));

    _printInfo('  Operation files:');
    _printInfo('    JSON (readable): ${jsonFile.path}');
    _printInfo('    ENC (app trigger): ${encFile.path}');
  }

  /// Verify command - check CRDT merge results.
  Future<void> _runVerify(Map<String, String> options) async {
    final workspace = options['workspace'];
    if (workspace == null) {
      _printError('--workspace is required');
      return;
    }

    final workspacePath = _expandPath(workspace);
    final vaults = await _findVaults(workspacePath);

    _printInfo('Verifying CRDT state in workspace: $workspacePath');
    _printSeparator();

    for (final vaultPath in vaults) {
      final vaultId = p.basename(vaultPath);
      _printInfo('Vault: $vaultId');

      // Check pending operations
      final pendingDir = Directory(p.join(vaultPath, 'sync', 'pending'));
      if (await pendingDir.exists()) {
        final pendingOps = await pendingDir
            .list()
            .where(
              (e) => e.path.endsWith('.op.json') || e.path.endsWith('.op.enc'),
            )
            .toList();
        _printInfo('  Pending operations: ${pendingOps.length}');

        for (final op in pendingOps) {
          final fileName = p.basename(op.path);
          _printInfo('    - $fileName');
        }
      }

      // Check index files
      final refsDir = Directory(p.join(vaultPath, 'refs'));
      if (await refsDir.exists()) {
        final notesIndex = File(p.join(refsDir.path, 'notes.jsonl.enc'));
        final notebooksIndex = File(
          p.join(refsDir.path, 'notebooks.jsonl.enc'),
        );

        if (await notesIndex.exists()) {
          final stat = await notesIndex.stat();
          _printInfo(
            '  Notes index: ${stat.size} bytes, modified ${stat.modified}',
          );
        }

        if (await notebooksIndex.exists()) {
          final stat = await notebooksIndex.stat();
          _printInfo(
            '  Notebooks index: ${stat.size} bytes, modified ${stat.modified}',
          );
        }
      }

      _printSeparator();
    }
  }

  /// Stress test command - concurrent modifications.
  Future<void> _runStress(Map<String, String> options) async {
    final workspace = options['workspace'];
    if (workspace == null) {
      _printError('--workspace is required');
      return;
    }

    final workspacePath = _expandPath(workspace);
    final operationCount = int.tryParse(options['operations'] ?? '50') ?? 50;
    final concurrency = int.tryParse(options['concurrency'] ?? '5') ?? 5;

    final vaults = await _findVaults(workspacePath);
    if (vaults.isEmpty) {
      _printError('No vaults found in workspace');
      return;
    }

    final targetVault = vaults.first;
    _printInfo('Stress testing vault: ${p.basename(targetVault)}');
    _printInfo('Operations: $operationCount');
    _printInfo('Concurrency: $concurrency');
    _printSeparator();

    final random = Random();
    final stopwatch = Stopwatch()..start();
    var completedOps = 0;
    final errors = <String>[];

    // Create multiple "devices" that will generate operations concurrently
    final futures = <Future>[];

    for (var device = 0; device < concurrency; device++) {
      final deviceId = 'stress-device-$device';
      final opsPerDevice = operationCount ~/ concurrency;

      futures.add(
        _runDeviceOperations(targetVault, deviceId, opsPerDevice, random, (
          count,
        ) {
          completedOps += count;
          stdout.write(
            '\rCompleted: $completedOps / $operationCount operations',
          );
        }, (error) => errors.add(error)),
      );
    }

    await Future.wait(futures);
    stopwatch.stop();

    print(''); // New line after progress
    _printSeparator();
    _printSuccess('Stress test completed!');
    _printInfo('  Total time: ${stopwatch.elapsedMilliseconds}ms');
    _printInfo('  Operations: $completedOps');
    _printInfo(
      '  Rate: ${(completedOps / stopwatch.elapsedMilliseconds * 1000).toStringAsFixed(1)} ops/sec',
    );

    if (errors.isNotEmpty) {
      _printWarning('  Errors: ${errors.length}');
      for (final error in errors.take(5)) {
        _printError('    - $error');
      }
    }

    _printInfo('\nNow verify the app correctly applies these operations:');
    _printInfo('  1. Open the app and navigate to the vault');
    _printInfo('  2. Check that notes are being merged with CRDT logic');
    _printInfo(
      '  3. Run: dart run bin/crdt_sync_tester.dart verify --workspace $workspace',
    );
  }

  /// Run operations for a simulated device.
  Future<void> _runDeviceOperations(
    String vaultPath,
    String deviceId,
    int operationCount,
    Random random,
    void Function(int) onProgress,
    void Function(String) onError,
  ) async {
    final pendingDir = Directory(p.join(vaultPath, 'sync', 'pending'));
    await pendingDir.create(recursive: true);

    final noteIds = <String>[];
    var localClock = random.nextInt(
      1000,
    ); // Start with random clock to simulate different devices

    for (var i = 0; i < operationCount; i++) {
      try {
        localClock++;
        final now = DateTime.now().toUtc();
        final opId = _uuid.v4();

        // Randomly choose operation type
        final opType = random.nextInt(10);
        Map<String, dynamic> operation;

        if (noteIds.isEmpty || opType < 3) {
          // Create note (30% chance or if no notes exist)
          final noteId = _uuid.v4();
          noteIds.add(noteId);

          operation = {
            'op_id': opId,
            'type': 'createNote',
            'target_id': noteId,
            'timestamp': localClock,
            'device_id': deviceId,
            'created_at': now.toIso8601String(),
            'payload': {
              'note_id': noteId,
              'title': 'Stress Note $i from $deviceId',
              'content': 'Content generated at $now',
              'notebook_id': null,
              'tags': <String>[],
              'is_pinned': random.nextBool(),
              'is_archived': false,
              'created_at': now.toIso8601String(),
              'modified_at': now.toIso8601String(),
            },
          };
        } else if (opType < 8) {
          // Update note (50% chance)
          final noteId = noteIds[random.nextInt(noteIds.length)];

          operation = {
            'op_id': opId,
            'type': 'updateNote',
            'target_id': noteId,
            'timestamp': localClock,
            'device_id': deviceId,
            'created_at': now.toIso8601String(),
            'payload': {
              'note_id': noteId,
              'title': 'Updated at $now by $deviceId',
              'content': 'Updated content iteration $i',
              'modified_at': now.toIso8601String(),
            },
          };
        } else {
          // Delete note (20% chance)
          final noteId = noteIds[random.nextInt(noteIds.length)];
          noteIds.remove(noteId);

          operation = {
            'op_id': opId,
            'type': 'deleteNote',
            'target_id': noteId,
            'timestamp': localClock,
            'device_id': deviceId,
            'created_at': now.toIso8601String(),
            'payload': {'note_id': noteId, 'deleted_at': now.toIso8601String()},
          };
        }

        // Write both .op.json and .op.enc for app detection
        final jsonFile = File(p.join(pendingDir.path, '$opId.op.json'));
        final encFile = File(p.join(pendingDir.path, '$opId.op.enc'));
        final content = jsonEncode(operation);

        await jsonFile.writeAsString(content);
        await encFile.writeAsBytes(utf8.encode(content));

        onProgress(1);

        // Small delay to avoid overwhelming the filesystem
        await Future.delayed(const Duration(milliseconds: 10));
      } catch (e) {
        onError(e.toString());
      }
    }
  }

  /// Find all vault directories in a workspace.
  Future<List<String>> _findVaults(String workspacePath) async {
    final vaultsDir = Directory(p.join(workspacePath, 'vaults'));
    if (!await vaultsDir.exists()) {
      return [];
    }

    final vaults = <String>[];
    await for (final entity in vaultsDir.list()) {
      if (entity is Directory) {
        final headerFile = File(p.join(entity.path, 'vault.header'));
        if (await headerFile.exists()) {
          vaults.add(entity.path);
        }
      }
    }
    return vaults;
  }

  /// Expand ~ in path.
  String _expandPath(String path) {
    if (path.startsWith('~/')) {
      final home =
          Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '';
      return p.join(home, path.substring(2));
    }
    return path;
  }

  /// Get event type name.
  String _eventTypeName(int type) {
    switch (type) {
      case FileSystemEvent.create:
        return 'CREATE';
      case FileSystemEvent.modify:
        return 'MODIFY';
      case FileSystemEvent.delete:
        return 'DELETE';
      case FileSystemEvent.move:
        return 'MOVE';
      default:
        return 'UNKNOWN';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Output Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  void _printUsage() {
    print('''
CRDT Sync Tester - Test CRDT merge behavior for Witflo

USAGE:
  dart run bin/crdt_sync_tester.dart <command> [options]

COMMANDS:
  watch                     Monitor workspace for file changes
  simulate <action>         Simulate external sync operations
    create-note             Create a note as if from another device
    update-note             Update a note as if from another device
    delete-note             Delete a note as if from another device
    create-notebook         Create a notebook as if from another device
    touch-index             Touch an index file to trigger reload
  verify                    Verify CRDT merge state
  stress                    Run stress test with concurrent operations

OPTIONS:
  --workspace <path>        Path to Witflo workspace (required)
  --vault <id>              Target vault ID (optional, uses first vault if not specified)
  
  For simulate create-note:
    --id <uuid>             Note ID (optional, auto-generated)
    --title <text>          Note title
    --content <text>        Note content
    --notebook <id>         Notebook ID
  
  For simulate update-note:
    --id <uuid>             Note ID (required)
    --title <text>          New title
    --content <text>        New content
  
  For simulate delete-note:
    --id <uuid>             Note ID (required)
  
  For simulate create-notebook:
    --id <uuid>             Notebook ID (optional)
    --name <text>           Notebook name
    --description <text>    Description
    --color <hex>           Color code
    --icon <name>           Icon name
  
  For simulate touch-index:
    --type <notes|notebooks|tags>  Index type (default: notes)
  
  For stress:
    --operations <count>    Number of operations (default: 50)
    --concurrency <count>   Number of concurrent devices (default: 5)

EXAMPLES:
  # Watch for changes
  dart run bin/crdt_sync_tester.dart watch --workspace ~/witflo-workspace

  # Create a note from "another device"
  dart run bin/crdt_sync_tester.dart simulate create-note \\
    --workspace ~/witflo-workspace \\
    --title "Remote Note" \\
    --content "Created on another device"

  # Run stress test
  dart run bin/crdt_sync_tester.dart stress \\
    --workspace ~/witflo-workspace \\
    --operations 100 \\
    --concurrency 10
''');
  }

  void _printInfo(String message) {
    print('\x1B[36m$message\x1B[0m'); // Cyan
  }

  void _printSuccess(String message) {
    print('\x1B[32m$message\x1B[0m'); // Green
  }

  void _printWarning(String message) {
    print('\x1B[33m$message\x1B[0m'); // Yellow
  }

  void _printError(String message) {
    print('\x1B[31mError: $message\x1B[0m'); // Red
  }

  void _printEvent(String message) {
    print('\x1B[35m$message\x1B[0m'); // Magenta
  }

  void _printHighlight(String message) {
    print('\x1B[1;33m$message\x1B[0m'); // Bold yellow
  }

  void _printSeparator() {
    print('\x1B[90m${'─' * 60}\x1B[0m'); // Gray line
  }
}
