<div align="center">

<img src="docs/public/logo.svg" alt="Witflo Logo" width="120" height="120">

# Witflo

**Safe space for your thoughts to flow**

Zero-trust encrypted notes that never become AI training data.

[![License: MPL-2.0](https://img.shields.io/badge/License-MPL%202.0-brightgreen.svg)](https://opensource.org/licenses/MPL-2.0)
[![Flutter](https://img.shields.io/badge/Flutter-3.38%2B-blue.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android%20%7C%20macOS%20%7C%20Linux%20%7C%20Windows%20%7C%20Web-lightgrey.svg)](https://github.com/nativewit/witflo)

[Download](https://github.com/nativewit/witflo/releases/latest) • [Documentation](https://nativewit.github.io/witflo/) • [Getting Started](https://nativewit.github.io/witflo/guide/getting-started)

</div>

---

## Why Witflo?

In an age where:
- **AI models are trained on user data** from cloud services
- **Data breaches expose millions** of accounts every year
- **Your notes can become ad targeting data**, AI training material, or worse

**Your thoughts deserve a truly private space.**

Witflo gives you that space:

- ✅ **Zero-knowledge encryption** — Your notes are encrypted on your device with keys only you have
- ✅ **Offline-first** — Works completely without internet. No cloud required
- ✅ **No account needed** — No email, no login, no tracking, no profiling
- ✅ **Open source** — Don't trust us? Audit the code yourself

**Your thoughts stay yours.** Not training data. Not in a data breach. Not on someone's server.

---

## Features

### 🔐 **Security by Design**
- **Military-grade encryption** — Argon2id, XChaCha20-Poly1305, HKDF via libsodium
- **Zero-trust architecture** — All crypto happens client-side
- **Memory safety** — Keys zeroized on lock, never touch disk
- **Auto-lock** — Configurable idle timeout protection

### 📴 **Offline-First**
- Works 100% without internet
- All data stored locally, encrypted on disk
- Optional sync (coming soon) is end-to-end encrypted

### 🗂️ **Multi-Workspace / Multi-Vault**
- Isolated encrypted containers for different contexts
- Work, personal, projects — keep them completely separate
- Each workspace has its own password and encryption keys

### ✍️ **Rich Text Editor**
- Quill-based editor with markdown support
- Write naturally, export easily
- Syntax highlighting for code blocks

### 🎨 **Beautiful Design**
- Dark and light themes
- Warm paper aesthetic designed for focus
- Clean, distraction-free interface

### 🌍 **Cross-Platform**
Built with Flutter for:
- 🍎 macOS (10.15+)
- 🐧 Linux (all major distros)
- 🪟 Windows (10+)
- 📱 iOS (coming soon)
- 🤖 Android (coming soon)
- 🌐 Web browsers

---

## Quick Start

### Download Pre-Built App

**[Download latest release →](https://github.com/nativewit/witflo/releases/latest)**

Available for macOS, Linux, Windows, and Web.

### Build from Source

```bash
# Clone the repository
git clone https://github.com/nativewit/witflo.git
cd witflo/witflo

# Requires FVM (Flutter Version Management)
# Install FVM: https://fvm.app
fvm install && fvm use
fvm flutter pub get

# Run the app
fvm flutter run
```

**System Requirements:**
- Flutter 3.38+ (via FVM)
- Dart 3.10.7+
- Platform-specific build tools (Xcode for macOS/iOS, Android Studio for Android)

---

## Architecture

Witflo uses a hierarchical encryption model:

```
Master Password
    ↓ Argon2id (memory-hard KDF)
Master Unlock Key (memory-only, never persisted)
    ↓ decrypts
Workspace Keyring (encrypted on disk)
    ↓ HKDF (key derivation)
Per-note derived keys (unique for each note)
    ↓ XChaCha20-Poly1305 (AEAD)
Encrypted note files on disk
```

**Key Principles:**
- **File-based storage** — Notes are encrypted blobs in a content-addressed layout
- **Zero-knowledge** — Server (if you sync) only sees ciphertext
- **Memory safety** — All keys zeroized on lock
- **No backdoors** — If you forget your password, your data cannot be recovered

📖 **See [SYSTEM_DESIGN.md](SYSTEM_DESIGN.md) for detailed architecture**

---

## Security Guarantees

| What We Protect | How |
|----------------|-----|
| **Password** | Never stored. Only exists in memory during unlock (Argon2id hashed) |
| **Encryption keys** | Derived from password, exist only in memory while unlocked, zeroized on lock |
| **Notes at rest** | XChaCha20-Poly1305 AEAD encryption before touching disk |
| **Notes in transit** | End-to-end encrypted sync (when available) — server sees only ciphertext |
| **Against brute force** | Argon2id with high memory/time cost (infeasible to crack) |
| **Against data breaches** | Even with full disk access, notes are useless without password |
| **Against AI training** | Zero-knowledge encryption means no one can read your notes to train AI |

🔐 **[Read full security documentation →](https://nativewit.github.io/witflo/security/encryption)**

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| **Framework** | Flutter 3.38+ |
| **Language** | Dart 3.10.7+ |
| **Crypto** | libsodium (via FFI) |
| **State Management** | Riverpod 2.0 |
| **Immutable Models** | built_value |
| **Rich Text Editor** | Flutter Quill |
| **Local Storage** | Drift (SQLite ORM) |
| **File Sync** | Custom file-based engine (pluggable connectors) |

---

## Development

### Project Structure

```
witflo/                         # Main Flutter app
├── lib/
│   ├── core/                   # Core infrastructure
│   │   ├── crypto/            # Cryptography (libsodium FFI)
│   │   ├── storage/           # File-based storage engine
│   │   ├── logging/           # Structured logging
│   │   └── config/            # Feature flags, environment
│   ├── features/              # Feature modules (domain + presentation)
│   │   ├── vault/            # Workspace/vault management
│   │   ├── notes/            # Note editor and CRUD
│   │   └── settings/         # App settings
│   └── main.dart             # App entry point
├── test/                      # Unit and widget tests
└── integration_test/          # Integration tests

docs/                          # VitePress documentation
.github/workflows/             # CI/CD (releases, docs deployment)
```

### Running Tests

```bash
cd witflo

# Run all tests
fvm flutter test

# Run with coverage
fvm flutter test --coverage

# Run integration tests
fvm flutter test integration_test/
```

### Code Quality

```bash
# Format code
fvm dart format .

# Analyze code
fvm dart analyze

# Run pre-commit checks
./.git/hooks/pre-commit
```

---

## Roadmap

### ✅ **Current (v0.0.1 - Preview)**
- Zero-trust encrypted notes
- Multi-workspace/vault support
- Rich text editor with markdown
- Offline-first local storage
- Auto-lock and security features
- Dark/Light themes

### 🚀 **Coming Soon**
- End-to-end encrypted sync (multi-device)
- iOS and Android apps (in beta)
- Biometric unlock (Face ID, Touch ID, Fingerprint)
- Browser extension (quick capture)

### 🔮 **On the Roadmap**
- Collaborative editing (E2E encrypted)
- File attachments (encrypted PDFs, images, documents)
- Note templates
- Post-quantum cryptography
- Tags and advanced search (encrypted)

📋 **[View full roadmap →](https://nativewit.github.io/witflo/guide/features#what-s-coming)**

---

## Contributing

**Currently building core features.** We're not accepting external contributions yet, but we welcome:

- 🐛 **Bug reports** — [Open an issue](https://github.com/nativewit/witflo/issues)
- 💡 **Feature requests** — [Open an issue](https://github.com/nativewit/witflo/issues)
- 🔍 **Security audits** — The code is open for review

We plan to open contributions after v1.0 stable release.

### For Security Researchers

If you find a security vulnerability, please **do not** open a public issue. Contact us privately at:
- Email: [Create a GitHub issue with "SECURITY" tag]
- Or via GitHub Security Advisories

---

## Documentation

- 📚 **[Full Documentation](https://nativewit.github.io/witflo/)** — Complete user guide and technical docs
- 🚀 **[Getting Started](https://nativewit.github.io/witflo/guide/getting-started)** — Installation and first steps
- 🔐 **[Security](https://nativewit.github.io/witflo/security/encryption)** — How encryption works
- 🔧 **[System Design](SYSTEM_DESIGN.md)** — Architecture deep dive
- ❓ **[FAQ](https://nativewit.github.io/witflo/guide/faq)** — Common questions

---

## License

This project is licensed under the **Mozilla Public License 2.0 (MPL-2.0)**.

- ✅ **Free to use** — Personal and commercial use allowed
- ✅ **Modify freely** — Fork and customize as you need
- ✅ **Source available** — Full transparency
- ⚠️ **Share modifications** — Modified source files must be shared under MPL-2.0
- ✅ **Combine with other code** — Can be used in larger proprietary projects

**[Read full license →](witflo/LICENSE)**

---

## Support & Community

- 🌟 **Star this repo** — Show your support!
- 📖 **[Read the docs](https://nativewit.github.io/witflo/)** — Comprehensive guides
- 🐛 **[Report issues](https://github.com/nativewit/witflo/issues)** — Found a bug? Let us know
- 💬 **GitHub Discussions** — Coming soon

---

<div align="center">

**Built with ❤️ for privacy**

[Download Now](https://github.com/nativewit/witflo/releases/latest) • [Documentation](https://nativewit.github.io/witflo/) • [GitHub](https://github.com/nativewit/witflo)

</div>
