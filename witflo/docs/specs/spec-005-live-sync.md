# SPEC-005: Live File System Monitoring & Sync Integration

**Status:** Draft  
**Version:** 1.0  
**Created:** 2026-02-04  
**Author:** Witflo Team  

---

## 1. Overview

### 1.1 Purpose

Enable Witflo to automatically detect and respond to external file system changes, allowing seamless third-party synchronization via Google Drive, OneDrive, Dropbox, and other file sync services.

### 1.2 Goals

- **Live Updates:** Detect file changes within 1 second on native platforms
- **Zero Restart:** Users never need to restart the app to see synced changes
- **Zero Trust:** Maintain end-to-end encryption while syncing via untrusted cloud services
- **CRDT Merge:** Resolve conflicts deterministically using Lamport clock ordering
- **Pure File-Based:** No local database caching (Drift removal)

### 1.3 Non-Goals

- **Web Platform:** Parked for future implementation (polling strategy TBD)
- **Built-in Sync:** Not building a native sync service (users bring their own)
- **Real-time Collaboration:** Not supporting simultaneous multi-user editing
- **Automatic Cloud Setup:** Users manually configure third-party sync

---

## 2. Architecture

### 2.1 High-Level Design

```
┌─────────────────────────────────────────────────────────────┐
│                    FILE MONITORING FLOW                      │
└─────────────────────────────────────────────────────────────┘

1. OS File System Event
   ↓
2. NativeFileWatcher (Dart's FileSystemEntity.watch)
   ↓
3. WorkspaceFileWatcher / VaultFileWatcher
   ├─ Debounce (300ms)
   ├─ Hash verification (BLAKE3)
   └─ Pattern filtering
   ↓
4. VaultReloadService
   ├─ Read encrypted file
   ├─ Decrypt with vault key
   ├─ Parse JSONL
   └─ Update repository._metadataCache
   ↓
5. Invalidate Riverpod Providers
   ref.invalidate(activeNotesProvider)
   ↓
6. Providers rebuild from repository.getActiveNotes()
   ↓
7. UI updates automatically (Consumer/ConsumerWidget)
```

### 2.2 Monitoring Scope

#### Workspace Level (WorkspaceFileWatcher)

**Directory:** `<workspace-root>/`

**Files Monitored:**
- `.witflo-workspace` - Workspace metadata (version, config)
- `.witflo-keyring.enc` - Encrypted vault keys
- `vaults/` directory - New vault detection

**Actions:**
- **`.witflo-workspace` changed:** Log warning (future: reload workspace)
- **`.witflo-keyring.enc` changed:** Notify user to re-unlock workspace
- **New `vault.header` in vaults/:** Run vault discovery, update registry, notify UI

#### Vault Level (VaultFileWatcher per vault)

**Directory:** `<workspace-root>/vaults/<vault-id>/`

**Files Monitored:**
- `vault.header` - Vault metadata
- `refs/notes.jsonl.enc` - Note metadata index
- `refs/notebooks.jsonl.enc` - Notebook index
- `refs/tags.jsonl.enc` - Tag index
- `sync/cursor.enc` - Sync position
- `sync/pending/*.op.enc` - Sync operations

**Actions:**
- **`notes.jsonl.enc` changed:** Reload note index, invalidate note providers
- **`notebooks.jsonl.enc` changed:** Reload notebook index, invalidate notebook providers
- **`tags.jsonl.enc` changed:** Reload tag index
- **`*.op.enc` added:** Trigger sync service to pull and apply operations

### 2.3 Vault Unlocking Model

**Key Insight:** ALL vaults are unlocked simultaneously when workspace unlocks.

```
WORKSPACE LOCKED
  ├─ Master password NOT in memory
  ├─ Keyring encrypted on disk
  └─ ALL vaults inaccessible
         ↓
   [User enters master password]
         ↓
WORKSPACE UNLOCKED
  ├─ Master Unlock Key (MUK) in memory
  ├─ Keyring decrypted into memory
  ├─ ALL vault keys cached
  └─ User can switch vaults instantly (UI state change only)
```

**Implication for Monitoring:**
- Start watchers for ALL vaults when workspace unlocks
- When new vault discovered, it's already "unlocked" (key in keyring)
- Stop ALL watchers when workspace locks

### 2.4 Data Architecture

**Before (Hybrid - Drift + File):**
```
EncryptedNoteRepository (file-based)
  ↓
Drift Database (SQLite cache)
  ↓
Riverpod Providers
  ↓
UI
```

**After (Pure File-Based):**
```
EncryptedNoteRepository (file-based)
  ├─ Map<String, NoteMetadata> _metadataCache
  └─ Query methods: getActiveNotes(), getNotesByNotebook(), etc.
  ↓
Riverpod Providers (AsyncNotifier)
  ↓
UI (Consumer/ConsumerWidget)
```

**Benefits:**
- ✅ Simpler architecture (one less layer)
- ✅ No database migrations
- ✅ Faster startup (no DB hydration)
- ✅ True file-based sync (no DB drift)

---

## 3. Component Specifications

### 3.1 FileChangeNotifier (Abstract Interface)

**File:** `lib/core/vault/file_change_notifier.dart`

```dart
abstract class FileChangeNotifier {
  Stream<FileChange> get changes;
  void dispose();
}

class FileChange {
  final String path;
  final FileChangeType type;
  final DateTime timestamp;
  final String? contentHash;  // BLAKE3 hex
}

enum FileChangeType { created, modified, deleted, moved }
```

### 3.2 NativeFileWatcher

**File:** `lib/core/vault/native_file_watcher.dart`

**Responsibilities:**
- Watch directory using `Directory.watch(recursive: true)`
- Filter by file patterns (e.g., `['*.enc', '*.jsonl.enc']`)
- Debounce rapid changes (300ms window)
- Compute content hashes (BLAKE3) for deduplication
- Emit `FileChange` events

**Configuration:**
```dart
NativeFileWatcher(
  directoryPath: '/path/to/dir',
  filePatterns: ['*.enc', 'vault.header'],
  crypto: cryptoService,
  debounceInterval: Duration(milliseconds: 300),
)
```

**Deduplication Strategy:**
- Maintain `Map<String, String> _lastKnownHashes`
- On modify event: compute hash, compare with last known
- Skip event if hash unchanged (prevents false positives from temp files)

### 3.3 WorkspaceFileWatcher

**File:** `lib/core/workspace/workspace_file_watcher.dart`

**Responsibilities:**
- Monitor workspace metadata files
- Monitor `vaults/` directory for new vaults
- Handle keyring changes (notify user to re-unlock)
- Trigger vault discovery on new `vault.header`

**Lifecycle:**
- **Start:** When workspace unlocks (`UnlockedWorkspaceProvider.build()`)
- **Stop:** When workspace locks or app exits

### 3.4 VaultFileWatcher

**File:** `lib/core/vault/vault_file_watcher.dart`

**Responsibilities:**
- Monitor vault `refs/` directory (indexes)
- Monitor vault `sync/` directory (operations)
- Trigger index reload via `VaultReloadService`
- Invalidate Riverpod providers

**Lifecycle:**
- **Start:** When workspace unlocks (all vaults simultaneously)
- **Stop:** When workspace locks

**One watcher per vault** - stored in `Map<String, VaultFileWatcher>` by vault ID

### 3.5 VaultReloadService

**File:** `lib/core/vault/vault_reload_service.dart`

**Responsibilities:**
- Read and decrypt index files (`refs/*.jsonl.enc`)
- Parse JSONL into metadata objects
- Update repository's `_metadataCache`
- Handle missing/corrupted index files gracefully

**API:**
```dart
class VaultReloadService {
  Future<void> reloadNotesIndex(UnlockedVault vault, EncryptedNoteRepository repo);
  Future<void> reloadNotebooksIndex(UnlockedVault vault, EncryptedNotebookRepository repo);
  Future<void> reloadTagsIndex(UnlockedVault vault, TagRepository repo);
}
```

### 3.6 Repository Query Methods

**File:** `lib/features/notes/data/note_repository.dart`

**New Methods:**
```dart
class EncryptedNoteRepository {
  // Existing
  Map<String, NoteMetadata> _metadataCache;
  bool _indexLoaded;
  
  // NEW: Reload from filesystem
  Future<void> reloadIndex();
  
  // NEW: Query methods
  Future<List<NoteMetadata>> getActiveNotes();
  Future<List<NoteMetadata>> getNotesByNotebook(String notebookId);
  Future<List<NoteMetadata>> getTrashedNotes();
  Future<List<NoteMetadata>> searchNotes(String query);
  Future<int> getNoteCount();
}
```

**Sorting:** Pinned notes first, then by `modifiedAt` descending

### 3.7 Riverpod Provider Updates

**File:** `lib/providers/note_providers.dart`

**Before (Drift):**
```dart
@riverpod
Stream<List<Note>> activeNotes(ActiveNotesRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchActiveNotes();
}
```

**After (File-Based):**
```dart
@riverpod
class ActiveNotes extends _$ActiveNotes {
  @override
  Future<List<NoteMetadata>> build() async {
    final vault = await ref.watch(activeVaultProvider.future);
    final noteRepo = ref.watch(noteRepositoryProvider(vault.header.vaultId));
    return await noteRepo.getActiveNotes();
  }
}
```

**Invalidation Pattern:**
```dart
// In VaultFileWatcher._handleRefChange()
_ref.invalidate(activeNotesProvider);
_ref.invalidate(allNotesProvider);
_ref.invalidate(noteProvider(noteId));
```

---

## 4. CRDT Conflict Resolution

### 4.1 Lamport Clock Ordering

**Algorithm:** Last-Write-Wins (LWW) based on Lamport timestamps

**SyncOperation Structure:**
```dart
class SyncOperation {
  final String opId;           // UUID
  final SyncOpType type;       // createNote, updateNote, deleteNote, etc.
  final String targetId;       // Note/notebook ID
  final int timestamp;         // Lamport clock value
  final String deviceId;       // Device that created operation
  final DateTime createdAt;    // Wall clock time
  final Map<String, dynamic> payload;
  final Signature? signature;  // Ed25519
}
```

**Clock Update Rules:**
```dart
// On local operation
_lamportClock++;

// On receiving remote operation
_lamportClock = max(_lamportClock, remoteTimestamp) + 1;
```

### 4.2 Conflict Resolution Strategy

**Case 1: Create Conflict**
- Device A creates note with ID `abc`
- Device B creates note with ID `abc` (unlikely but possible)
- Resolution: Higher Lamport timestamp wins

**Case 2: Update Conflict**
- Device A updates note title at T1
- Device B updates note title at T2
- Resolution:
  - If T2 > T1: Device B wins
  - If T2 == T1: Use `opId` lexicographic ordering (deterministic tie-breaker)

**Case 3: Delete-Update Conflict**
- Device A deletes note at T1
- Device B updates note at T2
- Resolution:
  - If T2 > T1: Update wins (note exists)
  - If T1 > T2: Delete wins (note deleted)

**Case 4: Content Merge**
- **Not implemented in v1** - no character-level CRDT
- Simple LWW: entire note content replaced by winner

### 4.3 SyncOperationApplicator

**File:** `lib/core/sync/sync_operation_applicator.dart`

**Responsibilities:**
- Apply sync operations to local state
- Verify Ed25519 signatures
- Update Lamport clock
- Handle idempotency (safe to apply multiple times)
- Return conflict results

**API:**
```dart
class SyncOperationApplicator {
  Future<ConflictResult> apply(SyncOperation op);
}

class ConflictResult {
  final bool success;
  final ConflictType? conflictType;
  final String? message;
}

enum ConflictType { merged, discarded, failed }
```

---

## 5. Security Considerations

### 5.1 Signature Verification

**Why:** Prevent malicious operations from untrusted devices

**Implementation:**
```dart
void _verifySignature(SyncOperation op) {
  if (op.signature == null) {
    throw SecurityException('Operation missing signature');
  }
  
  final isValid = _crypto.ed25519.verify(
    message: op.toBytes(),
    signature: op.signature,
    publicKey: op.devicePublicKey,
  );
  
  if (!isValid) {
    throw SecurityException('Invalid signature');
  }
}
```

### 5.2 Content Hash Validation

**Why:** Detect file corruption or tampering

**Implementation:**
- Compute BLAKE3 hash of encrypted file
- Skip reload if hash matches last known hash
- Prevents processing unchanged files (temp file churn)

### 5.3 Replay Attack Prevention

**Why:** Prevent attacker from replaying old operations

**Implementation:**
- Reject operations with timestamp ≤ sync cursor
- Store operation IDs in "seen set" (optional)
- Lamport clock ensures monotonic ordering

---

## 6. Edge Cases & Error Handling

### 6.1 File Lock During Sync

**Scenario:** Cloud sync service has file locked (mid-write)

**Handling:**
- Catch `FileSystemException` on `File.readAsBytes()`
- Log warning, skip this cycle
- Watcher will catch next change after lock released

### 6.2 Partial File Writes

**Scenario:** File watcher detects change mid-write

**Handling:**
- Debounce (300ms) - wait for write to complete
- Hash verification - skip if decryption fails
- Retry on next file change event

### 6.3 Keyring Updated Remotely

**Scenario:** User changes master password on Device A, keyring re-encrypted

**Handling:**
- WorkspaceFileWatcher detects `.witflo-keyring.enc` change
- Show notification: "Workspace keyring updated. Please re-unlock workspace."
- User must lock and re-unlock with new password

### 6.4 Vault Deleted Externally

**Scenario:** User deletes vault folder on Device A

**Handling:**
- FileWatcher detects deletion event
- Remove vault from registry
- If currently selected, switch to another vault
- Show notification: "Vault 'X' was deleted"

### 6.5 Corrupted Index File

**Scenario:** `notes.jsonl.enc` corrupted during sync

**Handling:**
- Decryption fails → log error, skip reload
- Malformed JSON → skip line, continue parsing
- Empty file → clear cache (valid state: new vault)

---

## 7. Performance Optimizations

### 7.1 Debouncing

- **Window:** 300ms after last change
- **Rationale:** Prevents thrashing during rapid edits (e.g., auto-save every 500ms)

### 7.2 Hash-Based Deduplication

- **Strategy:** Track `Map<String, String>` of file path → content hash
- **Benefit:** Skip processing if file unchanged (cloud sync touching file metadata)

### 7.3 Lazy Content Loading

- **Strategy:** Only decrypt note content when user opens note
- **Benefit:** Fast listing (metadata-only), slower individual note load

### 7.4 In-Memory Cache

- **Strategy:** Reuse `_metadataCache` in repositories
- **Benefit:** No database overhead, instant queries

---

## 8. Testing Strategy

### 8.1 Unit Tests

**File Watchers:**
- `native_file_watcher_test.dart`: Creation, modification, deletion, debouncing

**Reload Service:**
- `vault_reload_service_test.dart`: Index parsing, cache update, error handling

**Operation Applicator:**
- `sync_operation_applicator_test.dart`: Each operation type, conflict resolution

### 8.2 Integration Tests

**Workspace Monitoring:**
- Create vault externally → verify registry update

**Vault Monitoring:**
- Modify `notes.jsonl.enc` externally → verify UI update

**Sync Operations:**
- Add `.op.enc` file → verify operation applied

### 8.3 E2E Tests

**Two-Device Simulation:**
- Device A creates note → shared folder → Device B detects change

**Conflict Resolution:**
- Both devices edit same note offline → sync → verify deterministic merge

---

## 9. Migration Strategy

### 9.1 Drift Removal

**Phase:** Day 13-14

**Steps:**
1. Verify all providers use repository query methods
2. Remove `drift` and `drift_flutter` from `pubspec.yaml`
3. Delete `lib/platform/database/drift/` directory
4. Delete `test/platform/database/drift/`
5. Run `flutter pub get`
6. Full regression test

**Rollback Plan:** Git revert if critical issues found

### 9.2 User Impact

**Existing Users:**
- ✅ No data migration needed (already file-based)
- ✅ No configuration changes
- ✅ Transparent upgrade

**New Users:**
- ✅ Simpler architecture (no DB setup)
- ✅ Faster startup

---

## 10. Implementation Timeline

### Phase 1: File Watcher Foundation (Days 1-2)
- `file_change_notifier.dart`
- `native_file_watcher.dart`
- Unit tests

### Phase 2: Workspace & Vault Watchers (Days 3-4)
- `workspace_file_watcher.dart`
- `vault_file_watcher.dart`
- `vault_reload_service.dart`

### Phase 3: Repository Enhancement (Days 5-6)
- Add `reloadIndex()` to repositories
- Add query methods (`getActiveNotes()`, etc.)

### Phase 4: Provider Updates (Days 7-8)
- Remove Drift from `note_providers.dart`
- Remove Drift from `notebook_providers.dart`

### Phase 5: Lifecycle Integration (Days 9-10)
- Wire watchers into `UnlockedWorkspaceProvider`
- Start/stop watchers on unlock/lock

### Phase 6: CRDT & Sync (Days 11-12)
- `sync_payloads.dart`
- `sync_operation_applicator.dart`
- Complete `sync_service.dart:192`

### Phase 7: Drift Removal & Testing (Days 13-14)
- Remove Drift completely
- Integration tests
- Documentation

**Total: 14 days (2 weeks)**

---

## 11. Success Metrics

### Functional
- ✅ File changes detected within 1 second
- ✅ UI updates within 500ms of detection
- ✅ Zero data loss in conflict scenarios
- ✅ Deterministic conflict resolution

### Performance
- ✅ No memory leaks after 24h monitoring
- ✅ CPU usage <1% when idle
- ✅ Reload time <200ms for 1000 notes

### User Experience
- ✅ Sync "just works" with Google Drive
- ✅ No app restarts required
- ✅ No manual refresh button needed

---

## 12. Future Enhancements

### 12.1 Web Platform Support
- Polling-based file watcher (10-second interval)
- Configurable in settings
- Auto-disable if battery low (mobile web)

### 12.2 Sync Status UI
- Icon indicator: syncing / up-to-date / conflict / error
- Sync history viewer
- Manual sync trigger button

### 12.3 Advanced CRDT
- Character-level merge for rich text
- Operational Transformation (OT) for concurrent edits
- Version history with rollback

### 12.4 Native Sync Backend
- Built-in end-to-end encrypted sync
- WebSocket-based real-time updates
- Conflict resolution UI

---

## 13. References

### Internal Specs
- [SPEC-001: Workspace Management](spec-001-workspace-management.md)
- [SPEC-002: Vault Architecture](spec-002-vault-architecture.md) (if exists)

### External Resources
- [Dart FileSystemEntity.watch()](https://api.dart.dev/stable/dart-io/FileSystemEntity/watch.html)
- [Lamport Timestamps](https://en.wikipedia.org/wiki/Lamport_timestamp)
- [CRDTs Explained](https://crdt.tech/)
- [Riverpod Documentation](https://riverpod.dev/)

---

**Document Version History:**
- v1.0 (2026-02-04): Initial specification
