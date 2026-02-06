// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Sync Operation Applicator - CRDT Conflict Resolution
// ═══════════════════════════════════════════════════════════════════════════
//
// CONFLICT RESOLUTION STRATEGY: Last-Write-Wins (LWW)
//
// We use Lamport timestamps to provide causal ordering:
// 1. Each operation has a Lamport timestamp
// 2. When receiving a remote operation, update local clock: max(local, remote) + 1
// 3. For conflicts (same entity modified), higher timestamp wins
// 4. For timestamp ties, use opId lexicographic order (deterministic)
//
// OPERATION APPLICATION:
// - CreateNote: Add note if doesn't exist, or merge if created concurrently
// - UpdateNote: Apply if timestamp > local timestamp, else skip
// - DeleteNote: Always apply (delete wins over update)
// - MoveNote: Apply if timestamp > local timestamp
// - Notebooks: Same logic as notes
//
// CONFLICT TYPES:
// - NoConflict: Operation applied cleanly
// - TimestampConflict: Remote timestamp > local, remote wins
// - DeleteConflict: Delete operation trumps concurrent updates
// - CreateConflict: Concurrent creates merged
// ═══════════════════════════════════════════════════════════════════════════

import 'package:built_collection/built_collection.dart';
import 'package:witflo_app/core/crypto/crypto.dart';
import 'package:witflo_app/core/logging/app_logger.dart';
import 'package:witflo_app/core/sync/sync_operation.dart';
import 'package:witflo_app/core/sync/sync_payloads.dart';
import 'package:witflo_app/core/vault/vault.dart';
import 'package:witflo_app/features/notes/data/note_repository.dart';
import 'package:witflo_app/features/notes/data/notebook_repository.dart';
import 'package:witflo_app/features/notes/models/note.dart';
import 'package:witflo_app/features/notes/models/notebook.dart';

/// Type of conflict detected during operation application.
enum ConflictType {
  /// No conflict, operation applied cleanly
  noConflict,

  /// Remote timestamp > local, remote wins
  timestampConflict,

  /// Delete operation trumps concurrent updates
  deleteConflict,

  /// Concurrent creates merged
  createConflict,
}

/// Result of applying a sync operation.
class ApplyResult {
  final bool success;
  final ConflictType conflictType;
  final String? message;

  ApplyResult({
    required this.success,
    required this.conflictType,
    this.message,
  });

  factory ApplyResult.noConflict() =>
      ApplyResult(success: true, conflictType: ConflictType.noConflict);

  factory ApplyResult.timestampConflict(String message) => ApplyResult(
    success: true,
    conflictType: ConflictType.timestampConflict,
    message: message,
  );

  factory ApplyResult.deleteConflict(String message) => ApplyResult(
    success: true,
    conflictType: ConflictType.deleteConflict,
    message: message,
  );

  factory ApplyResult.createConflict(String message) => ApplyResult(
    success: true,
    conflictType: ConflictType.createConflict,
    message: message,
  );

  factory ApplyResult.error(String message) => ApplyResult(
    success: false,
    conflictType: ConflictType.noConflict,
    message: message,
  );
}

/// Applies sync operations with CRDT conflict resolution.
class SyncOperationApplicator {
  final UnlockedVault _vault;
  // ignore: unused_field
  final CryptoService _crypto; // Reserved for future payload decryption
  final EncryptedNoteRepository _noteRepo;
  final EncryptedNotebookRepository _notebookRepo;
  final _log = AppLogger.get('SyncOperationApplicator');

  /// Lamport clock for operation ordering
  int _lamportClock = 0;

  SyncOperationApplicator({
    required UnlockedVault vault,
    required CryptoService crypto,
    required EncryptedNoteRepository noteRepo,
    required EncryptedNotebookRepository notebookRepo,
  }) : _vault = vault,
       _crypto = crypto,
       _noteRepo = noteRepo,
       _notebookRepo = notebookRepo;

  /// Gets the current Lamport clock value.
  int get lamportClock => _lamportClock;

  /// Increments the Lamport clock and returns the new value.
  int incrementClock() {
    _lamportClock++;
    return _lamportClock;
  }

  /// Updates the Lamport clock from a remote operation.
  void updateClock(int remoteTimestamp) {
    _lamportClock = _lamportClock > remoteTimestamp
        ? _lamportClock + 1
        : remoteTimestamp + 1;
  }

  /// Applies a sync operation to local state.
  Future<ApplyResult> apply(SyncOperation op) async {
    try {
      _log.info('Applying sync operation: ${op.type.name} for ${op.targetId}');

      // Update Lamport clock
      updateClock(op.timestamp);

      // Apply based on operation type
      switch (op.type) {
        case SyncOpType.createNote:
          return await _applyCreateNote(op);
        case SyncOpType.updateNote:
          return await _applyUpdateNote(op);
        case SyncOpType.deleteNote:
          return await _applyDeleteNote(op);
        case SyncOpType.moveNote:
          return await _applyMoveNote(op);
        case SyncOpType.createNotebook:
          return await _applyCreateNotebook(op);
        case SyncOpType.updateNotebook:
          return await _applyUpdateNotebook(op);
        case SyncOpType.deleteNotebook:
          return await _applyDeleteNotebook(op);
        case SyncOpType.addTag:
        case SyncOpType.removeTag:
          // TODO: Implement tag operations
          _log.warning('Tag operations not yet implemented');
          return ApplyResult.noConflict();
      }
    } catch (e, stack) {
      _log.error('Failed to apply operation', error: e, stackTrace: stack);
      return ApplyResult.error(e.toString());
    }
  }

  /// Applies a CreateNote operation.
  Future<ApplyResult> _applyCreateNote(SyncOperation op) async {
    final payload = CreateNotePayload.fromJson(op.payload);

    // Check if note already exists
    final existing = await _noteRepo.load(payload.noteId);

    if (existing != null) {
      // Concurrent create - use timestamp to decide winner
      if (op.timestamp > existing.modifiedAt.millisecondsSinceEpoch) {
        _log.info(
          'Create conflict: remote timestamp wins (${op.timestamp} > ${existing.modifiedAt.millisecondsSinceEpoch})',
        );

        final note = Note(
          (b) => b
            ..id = payload.noteId
            ..title = payload.title
            ..content = payload.content
            ..notebookId = payload.notebookId
            ..tags = ListBuilder<String>(payload.tags)
            ..isPinned = payload.isPinned
            ..isArchived = payload.isArchived
            ..isTrashed = false
            ..createdAt = payload.createdAt
            ..modifiedAt = payload.modifiedAt
            ..version = 1,
        );

        await _noteRepo.save(note);
        return ApplyResult.createConflict('Remote create wins');
      } else if (op.timestamp == existing.modifiedAt.millisecondsSinceEpoch) {
        // Timestamp tie - use opId for deterministic ordering
        if (op.opId.compareTo(existing.id) > 0) {
          _log.info('Create conflict: opId tie-breaker wins');

          final note = Note(
            (b) => b
              ..id = payload.noteId
              ..title = payload.title
              ..content = payload.content
              ..notebookId = payload.notebookId
              ..tags = ListBuilder<String>(payload.tags)
              ..isPinned = payload.isPinned
              ..isArchived = payload.isArchived
              ..isTrashed = false
              ..createdAt = payload.createdAt
              ..modifiedAt = payload.modifiedAt
              ..version = 1,
          );

          await _noteRepo.save(note);
          return ApplyResult.createConflict('OpId tie-breaker wins');
        } else {
          _log.info('Create conflict: local wins');
          return ApplyResult.createConflict('Local create wins');
        }
      } else {
        _log.info('Create conflict: local timestamp wins');
        return ApplyResult.createConflict('Local create wins');
      }
    }

    // Note doesn't exist, create it
    final note = Note(
      (b) => b
        ..id = payload.noteId
        ..title = payload.title
        ..content = payload.content
        ..notebookId = payload.notebookId
        ..tags = ListBuilder<String>(payload.tags)
        ..isPinned = payload.isPinned
        ..isArchived = payload.isArchived
        ..isTrashed = false
        ..createdAt = payload.createdAt
        ..modifiedAt = payload.modifiedAt
        ..version = 1,
    );

    await _noteRepo.save(note);
    return ApplyResult.noConflict();
  }

  /// Applies an UpdateNote operation.
  Future<ApplyResult> _applyUpdateNote(SyncOperation op) async {
    final payload = UpdateNotePayload.fromJson(op.payload);

    // Load existing note
    final existing = await _noteRepo.load(payload.noteId);

    if (existing == null) {
      _log.warning('Cannot update non-existent note: ${payload.noteId}');
      return ApplyResult.error('Note does not exist');
    }

    // Check timestamp - only apply if remote is newer
    final remoteTimestamp = payload.modifiedAt.millisecondsSinceEpoch;
    final localTimestamp = existing.modifiedAt.millisecondsSinceEpoch;

    if (remoteTimestamp < localTimestamp) {
      _log.info(
        'Update skipped: local is newer ($localTimestamp > $remoteTimestamp)',
      );
      return ApplyResult.timestampConflict(
        'Local is newer, remote update skipped',
      );
    }

    if (remoteTimestamp == localTimestamp) {
      // Timestamp tie - use opId
      if (op.opId.compareTo(existing.id) <= 0) {
        _log.info('Update skipped: opId tie-breaker, local wins');
        return ApplyResult.timestampConflict('OpId tie-breaker, local wins');
      }
    }

    // Remote is newer, apply the update
    _log.info(
      'Applying remote update (timestamp: $remoteTimestamp > $localTimestamp)',
    );

    var updated = existing;
    if (payload.title != null) updated = updated.copyWith(title: payload.title);
    if (payload.content != null)
      updated = updated.copyWith(content: payload.content);
    if (payload.notebookId != null)
      updated = updated.copyWith(notebookId: payload.notebookId);
    if (payload.tags != null)
      updated = updated.rebuild((b) => b..tags.replace(payload.tags!));
    if (payload.isPinned != null)
      updated = updated.copyWith(isPinned: payload.isPinned);
    if (payload.isArchived != null)
      updated = updated.copyWith(isArchived: payload.isArchived);
    if (payload.isTrashed != null)
      updated = updated.copyWith(isTrashed: payload.isTrashed);
    updated = updated.copyWith(modifiedAt: payload.modifiedAt);

    await _noteRepo.save(updated);

    if (remoteTimestamp == localTimestamp) {
      return ApplyResult.timestampConflict('OpId tie-breaker, remote wins');
    }

    return ApplyResult.timestampConflict('Remote is newer, applied');
  }

  /// Applies a DeleteNote operation.
  Future<ApplyResult> _applyDeleteNote(SyncOperation op) async {
    final payload = DeleteNotePayload.fromJson(op.payload);

    // Check if note exists
    final existing = await _noteRepo.load(payload.noteId);

    if (existing == null) {
      _log.info('Delete: note already deleted or never existed');
      return ApplyResult.noConflict();
    }

    // Delete always wins (even if local has newer edits)
    _log.info('Applying delete operation for note: ${payload.noteId}');
    await _noteRepo.delete(payload.noteId);

    return ApplyResult.deleteConflict('Delete wins over concurrent updates');
  }

  /// Applies a MoveNote operation.
  Future<ApplyResult> _applyMoveNote(SyncOperation op) async {
    final payload = MoveNotePayload.fromJson(op.payload);

    // Load existing note
    final existing = await _noteRepo.load(payload.noteId);

    if (existing == null) {
      _log.warning('Cannot move non-existent note: ${payload.noteId}');
      return ApplyResult.error('Note does not exist');
    }

    // Check timestamp
    final remoteTimestamp = payload.movedAt.millisecondsSinceEpoch;
    final localTimestamp = existing.modifiedAt.millisecondsSinceEpoch;

    if (remoteTimestamp < localTimestamp) {
      _log.info('Move skipped: local is newer');
      return ApplyResult.timestampConflict('Local is newer, move skipped');
    }

    // Apply the move
    _log.info(
      'Moving note ${payload.noteId} to notebook ${payload.newNotebookId}',
    );
    final updated = existing.copyWith(
      notebookId: payload.newNotebookId,
      modifiedAt: payload.movedAt,
    );

    await _noteRepo.save(updated);
    return ApplyResult.timestampConflict('Remote move applied');
  }

  /// Applies a CreateNotebook operation.
  Future<ApplyResult> _applyCreateNotebook(SyncOperation op) async {
    final payload = CreateNotebookPayload.fromJson(op.payload);

    // Check if notebook already exists
    final existing = await _notebookRepo.load(payload.notebookId);

    if (existing != null) {
      // Concurrent create - use timestamp
      if (op.timestamp > existing.modifiedAt.millisecondsSinceEpoch) {
        _log.info('Create notebook conflict: remote wins');

        final notebook = Notebook(
          (b) => b
            ..id = payload.notebookId
            ..name = payload.name
            ..vaultId = _vault.header.vaultId
            ..description = payload.description
            ..color = payload.color
            ..icon = payload.icon
            ..isArchived = false
            ..noteCount = 0
            ..createdAt = payload.createdAt
            ..modifiedAt = payload.modifiedAt,
        );

        await _notebookRepo.save(notebook);
        return ApplyResult.createConflict('Remote create wins');
      } else {
        _log.info('Create notebook conflict: local wins');
        return ApplyResult.createConflict('Local create wins');
      }
    }

    // Notebook doesn't exist, create it
    final notebook = Notebook(
      (b) => b
        ..id = payload.notebookId
        ..name = payload.name
        ..vaultId = _vault.header.vaultId
        ..description = payload.description
        ..color = payload.color
        ..icon = payload.icon
        ..isArchived = false
        ..noteCount = 0
        ..createdAt = payload.createdAt
        ..modifiedAt = payload.modifiedAt,
    );

    await _notebookRepo.save(notebook);
    return ApplyResult.noConflict();
  }

  /// Applies an UpdateNotebook operation.
  Future<ApplyResult> _applyUpdateNotebook(SyncOperation op) async {
    final payload = UpdateNotebookPayload.fromJson(op.payload);

    // Load existing notebook
    final existing = await _notebookRepo.load(payload.notebookId);

    if (existing == null) {
      _log.warning(
        'Cannot update non-existent notebook: ${payload.notebookId}',
      );
      return ApplyResult.error('Notebook does not exist');
    }

    // Check timestamp
    final remoteTimestamp = payload.modifiedAt.millisecondsSinceEpoch;
    final localTimestamp = existing.modifiedAt.millisecondsSinceEpoch;

    if (remoteTimestamp < localTimestamp) {
      _log.info('Update notebook skipped: local is newer');
      return ApplyResult.timestampConflict('Local is newer, update skipped');
    }

    // Apply the update
    _log.info('Applying remote notebook update');
    var updated = existing;
    if (payload.name != null)
      updated = updated.rebuild((b) => b..name = payload.name!);
    if (payload.description != null)
      updated = updated.rebuild((b) => b..description = payload.description);
    if (payload.color != null)
      updated = updated.rebuild((b) => b..color = payload.color);
    if (payload.icon != null)
      updated = updated.rebuild((b) => b..icon = payload.icon);
    if (payload.isArchived != null)
      updated = updated.rebuild((b) => b..isArchived = payload.isArchived!);
    updated = updated.rebuild((b) => b..modifiedAt = payload.modifiedAt);

    await _notebookRepo.save(updated);
    return ApplyResult.timestampConflict('Remote notebook update applied');
  }

  /// Applies a DeleteNotebook operation.
  Future<ApplyResult> _applyDeleteNotebook(SyncOperation op) async {
    final payload = DeleteNotebookPayload.fromJson(op.payload);

    // Check if notebook exists
    final existing = await _notebookRepo.load(payload.notebookId);

    if (existing == null) {
      _log.info('Delete notebook: already deleted or never existed');
      return ApplyResult.noConflict();
    }

    // Delete always wins
    _log.info('Applying delete operation for notebook: ${payload.notebookId}');
    await _notebookRepo.delete(payload.notebookId);

    return ApplyResult.deleteConflict('Delete wins over concurrent updates');
  }
}
