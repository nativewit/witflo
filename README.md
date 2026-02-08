# Witflo

**Zero-trust, privacy-first, offline-first encrypted notes.**

All data is end-to-end encrypted on your device. The server — if you sync at all — only sees ciphertext.

Built with Flutter for iOS, Android, macOS, Linux, Windows, and Web.

## Features

- **Zero-trust encryption** — All crypto happens client-side with libsodium
- **Offline-first** — Works fully without internet
- **Multi-workspace / Multi-vault** — Isolated encrypted containers
- **Rich text editor** — Quill-based with markdown support
- **Notebooks** — Color-coded organization
- **Auto-lock** — Configurable idle timeout
- **Dark/Light themes** — Warm paper aesthetic
- **Export** — Markdown and JSON

## Quick Start

```bash
git clone https://github.com/nativewit/witflo.git
cd witflo/witflo

# Requires FVM (Flutter Version Management)
fvm install && fvm use
fvm flutter pub get
fvm flutter run
```

## Architecture

```
Master Password
    ↓ Argon2id
Master Unlock Key (memory-only)
    ↓ decrypts
Workspace Keyring
    ↓ HKDF
Per-note derived keys
    ↓ XChaCha20-Poly1305
Encrypted files on disk
```

All storage is file-based — notes are encrypted blobs in a content-addressed layout.

See [SYSTEM_DESIGN.md](SYSTEM_DESIGN.md) for details.

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Flutter 3.38+ |
| Crypto | libsodium |
| State | Riverpod |
| Models | built_value |
| Editor | Flutter Quill |

## Security

- Password is never stored
- Keys exist only in memory while unlocked
- All keys zeroized on lock
- Authenticated encryption (AEAD)

## Contributing

See [SYSTEM_DESIGN.md](SYSTEM_DESIGN.md) for architecture. PRs welcome.

## License

[AGPL-3.0](LICENSE)
