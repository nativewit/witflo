# Copilot Instructions

- Project: Flutter app `fyndo_app` (zero-trust, offline-first notes OS). See [fyndo/docs/PRODUCT.md](fyndo/docs/PRODUCT.md) and [fyndo/README.md](fyndo/README.md).
- Flutter pinned via FVM (≥3.38.7, Dart 3.10.7+). **Always use `fvm flutter ...`** for commands.

## Architecture
- **Init order** in [fyndo/lib/main.dart](fyndo/lib/main.dart): `initializePlatform()` → `CryptoService.initialize()` → Riverpod app. Preserve this sequence.
- **Platform layer** ([fyndo/lib/platform](fyndo/lib/platform)): conditional imports swap web/native. Use `storageProvider` (not raw `File`); web uses in-memory stub (loses data on refresh).
- **Database**: Drift ORM in [app_database.dart](fyndo/lib/platform/database/drift/app_database.dart). Tables: notes, notebooks, note_fts, sync_state, key_store. **All content columns = ciphertext** except `note_fts.searchText`.
- **State**: Riverpod providers in [fyndo/lib/providers](fyndo/lib/providers). Access vault via `vaultProvider`, notes via `noteRepositoryProvider` (wraps encryption).
- **Routing**: `go_router` in [app_router.dart](fyndo/lib/ui/router/app_router.dart). Guard redirects to `/` when vault locked. Prefer declarative `context.go()`.
- **Crypto**: libsodium via `sodium_libs`. Key hierarchy: Password → Argon2id → MUK → VaultKey → ContentKeys. See [crypto_service.dart](fyndo/lib/core/crypto/crypto_service.dart).

## Critical Patterns
- **SecureBytes lifecycle**: Always `dispose()` after use; wrap in try/finally. Access via `.unsafeBytes` only for crypto ops—never store the reference.
  ```dart
  final key = crypto.random.randomBytes(32);
  try { /* use key */ } finally { key.dispose(); }
  ```
- **Vault unlock flow**: `vaultProvider` manages `VaultStatus`. Watch `unlockedVaultProvider` in providers that need decryption keys.
- **Repository pattern**: `EncryptedNoteRepository` handles encrypt/decrypt; UI never sees raw crypto—just call `repo.load(id)` / `repo.save(note)`.

## Workflows
```bash
cd fyndo
fvm install && fvm use && fvm flutter pub get   # setup
fvm flutter run                                  # run (add -d chrome for web)
fvm flutter test                                 # tests (--coverage optional)
fvm dart run build_runner build --delete-conflicting-outputs  # codegen
fvm flutter analyze                              # lints
```

## Conventions
- **Zero-trust**: persist ciphertext only. Plaintext in `note_fts.searchText` is the sole exception—audit exposure carefully.
- **IDs**: UUID v4 (`uuid` package). Models use `equatable`/`freezed`.
- **DB changes**: update Drift tables + bump `schemaVersion` + add migration in `MigrationStrategy` + regenerate.
- **Web caveat**: in-memory storage stub—features requiring persistence need IndexedDB implementation.

## Tests
- Unit tests for crypto/vault in [test/core](fyndo/test/core). Use in-memory Drift DB or platform stubs.
- Widget tests minimal—see [test/widget_test.dart](fyndo/test/widget_test.dart) placeholder.

## Checklist
1. Init platform + crypto before vault/storage/DB ops.
2. Use Riverpod providers, not direct `AppDatabase` instances.
3. Dispose `SecureBytes`; zeroize any `Uint8List` holding secrets.
4. Run `build_runner` after editing freezed/riverpod/drift files.
5. Keep offline-first: sync hooks must tolerate no network.
