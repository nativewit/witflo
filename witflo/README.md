# 🔐 Witflo

**Zero-Trust, Privacy-First, Offline-First Notes OS**

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MPL--2.0-blue.svg)](https://opensource.org/licenses/MPL-2.0)
[![Security](https://img.shields.io/badge/Security-Zero%20Trust-red.svg)]()

---

## 🎯 What is Witflo?

Witflo is a note-taking and personal knowledge management app built on one unwavering principle:

> **The server is hostile, the network is compromised, and your notes are worth millions.**

Every design decision prioritizes **your privacy** and **data sovereignty** over convenience.

### Key Features

- 🔒 **End-to-End Encrypted** - All content encrypted on your device
- 📱 **Local-First** - Works fully offline, sync is optional
- 🚫 **Zero-Trust** - Servers never see your data
- 🔑 **Deterministic Recovery** - Password + salt = full vault recovery
- 🔐 **Audited Cryptography** - libsodium primitives only

---

## 🚀 Quick Start

### 1. Create Your First Vault

![Create Vault](docs/screenshots/create-vault.png)

1. Launch Witflo
2. Tap "Create New Vault"
3. Choose a **strong master password** (this is your encryption key!)
4. Optional: Add a salt phrase for extra security

**Important**: Your password is never stored. If you forget it, your data is unrecoverable.

### 2. Create a Notebook

![Create Notebook](docs/screenshots/create-notebook.png)

1. Tap the "+" button
2. Name your notebook
3. Start organizing your notes

### 3. Write Your First Note

![Write Note](docs/screenshots/write-note.png)

1. Open a notebook
2. Tap "New Note"
3. Write freely - everything is encrypted automatically

---

## ❓ Frequently Asked Questions

<details>
<summary><strong>How do I get started with Witflo?</strong></summary>

Download Witflo, create a vault with a strong password, and start writing. Your notes are encrypted locally by default. Sync is optional and can be configured later in Settings.

</details>

<details>
<summary><strong>What happens if I forget my password?</strong></summary>

**Your data cannot be recovered.** Witflo uses zero-knowledge encryption - we don't have a "reset password" option because we never see your password or your data. Choose a password you'll remember, or use a password manager.

</details>

<details>
<summary><strong>Is my data really private?</strong></summary>

Yes. All encryption happens on your device. The server (if you choose to sync) only sees encrypted blobs. Even if our servers are compromised, your notes remain secure. We use audited cryptography (libsodium) with industry-standard algorithms like XChaCha20-Poly1305 and Argon2id.

</details>

<details>
<summary><strong>Can I use Witflo offline?</strong></summary>

Absolutely! Witflo is offline-first. All features work without an internet connection. Sync is completely optional.

</details>

<details>
<summary><strong>How do I sync across devices?</strong></summary>

Enable sync in Settings. You can choose from:
- Custom server (HTTP/REST API)
- Cloud providers (coming soon: Firebase, Supabase)
- No sync (local-only, default)

All synced data is end-to-end encrypted before leaving your device.

</details>

<details>
<summary><strong>What encryption does Witflo use?</strong></summary>

- **Argon2id** for password hashing (resistant to GPU/ASIC attacks)
- **XChaCha20-Poly1305** for authenticated encryption
- **HKDF-SHA256** for key derivation
- **Ed25519** for digital signatures
- **X25519** for key exchange (sharing)

All primitives come from libsodium, an audited cryptographic library.

</details>

<details>
<summary><strong>Can I share notes with others?</strong></summary>

Yes! Sharing uses public-key cryptography:
1. Share a note/notebook with someone's public key
2. They decrypt it with their private key
3. The server never sees the content
4. You can revoke access anytime

</details>

<details>
<summary><strong>Which platforms are supported?</strong></summary>

Witflo runs on:
- iOS (iPhone & iPad)
- Android
- macOS
- Linux
- Windows
- Web (browser)

</details>

---

## 👨‍💻 Developer Setup

### Prerequisites

- Flutter 3.38.7+ (via FVM recommended)
- Dart 3.10.7+
- FVM (Flutter Version Management)

## 📥 Installation

### For Users

Download the latest release for your platform from [GitHub Releases](https://github.com/nativewit/witflo/releases).

#### macOS
1. Download `Witflo-macOS.zip`
2. Extract and drag `Witflo.app` to Applications folder
3. **First launch**: Right-click → **"Open"** (due to unsigned app)
4. Click **"Open"** in the security dialog

> **Why the security warning?** The app is not yet code-signed with an Apple Developer certificate. This is safe to bypass - the source code is open and auditable. We're working on code signing for future releases.

#### Windows
1. Download `Witflo-Windows.zip`
2. Extract to your preferred location
3. Run `witflo.exe`

#### Linux
1. Download `Witflo-Linux.tar.gz`
2. Extract: `tar -xzf Witflo-Linux.tar.gz`
3. Run: `./witflo`

### For Developers

#### Installation

```bash
# Clone the repository
git clone https://github.com/your-org/witflo-platform.git
cd witflo-platform/witflo

# Install FVM if not already installed
dart pub global activate fvm

# Install and use the correct Flutter version
fvm install
fvm use

# Install dependencies
fvm flutter pub get

# Run the app
fvm flutter run
```

### Running Tests

```bash
# Run all tests
fvm flutter test

# Run with coverage
fvm flutter test --coverage
```

---

## 🏗️ Technical Architecture

### Cryptographic Primitives

| Algorithm | Purpose |
|-----------|---------|
| **Argon2id** | Password → Master Unlock Key |
| **XChaCha20-Poly1305** | AEAD encryption |
| **HKDF-SHA256** | Key derivation |
| **BLAKE3/BLAKE2b** | Content hashing |
| **Ed25519** | Digital signatures |
| **X25519** | Key exchange for sharing |

### Key Hierarchy

```
Master Password (never stored)
    ↓ Argon2id
Master Unlock Key (memory only)
    ↓ decrypts
Vault Key (stored encrypted)
    ↓ HKDF
├── Content Keys (per note)
├── Notebook Keys (per notebook)
├── Group Keys (shared vaults)
└── Share Keys (one-off shares)
```

---

## 📁 Project Structure

```
lib/
├── core/                    # Core functionality
│   ├── crypto/              # Cryptographic primitives
│   │   ├── types/           # SecureBytes, key types
│   │   └── primitives/      # Argon2id, XChaCha20, HKDF, etc.
│   ├── vault/               # Vault management
│   ├── identity/            # User & device identity
│   ├── sync/                # Sync operations
│   ├── sharing/             # Sharing service
│   └── search/              # Encrypted search
├── features/
│   └── notes/               # Notes feature
│       ├── models/          # Note data models
│       └── data/            # Repository layer
├── providers/               # Riverpod providers
└── main.dart                # Entry point

test/
├── core/
│   ├── crypto/              # Crypto tests
│   └── vault/               # Vault tests
└── features/
    └── notes/               # Note tests
```

---

## 🔒 Security Model

### What We Protect Against

✅ Server compromise - Server only sees ciphertext  
✅ Network interception - All traffic encrypted  
✅ Malicious cloud providers - Zero knowledge  
✅ Key leakage - Keys zeroized after use  
✅ Timing attacks - Constant-time operations  

### What We Don't Protect Against

❌ Compromised device (root/malware)  
❌ Weak passwords (Argon2id helps)  
❌ Physical coercion  
❌ Hardware side-channels  

---

## 🔄 Sync Architecture

Witflo uses a **pluggable sync backend** architecture:

| Backend | Status | Description |
|---------|--------|-------------|
| `LocalOnlySyncBackend` | ✅ Ready | No sync, local storage only (default) |
| `HttpSyncBackend` | ✅ Stub | Generic REST API for custom servers |
| `FirebaseSyncBackend` | 🔜 Future | Firebase Firestore/Storage |
| `SupabaseSyncBackend` | 🔜 Future | Supabase implementation |

### Implementing Custom Sync Backends

```dart
class MyCustomBackend implements SyncBackend {
  // Implement the interface methods
  // All data passed to these methods is already encrypted
  // Your server NEVER sees plaintext
}

// Use it
syncService.setBackend(MyCustomBackend());
```

---

## 💾 Database Architecture

Witflo uses a **pluggable database** architecture:

| Provider | Platform | Description |
|----------|----------|-------------|
| `SqliteDatabaseProvider` | Native | SQLite for iOS, Android, Desktop |
| `InMemoryDatabaseProvider` | All | In-memory storage for testing/web |
| `IndexedDbProvider` | 🔜 Web | Persistent IndexedDB for web |

### Implementing Custom Database Providers

```dart
class MyCustomDatabase implements DatabaseProvider {
  // Implement query, insert, update, delete methods
  // All data stored is already encrypted
}

// Use it during platform initialization
setDatabaseProvider(MyCustomDatabase());
```

---

## 📦 Storage Architecture

Witflo uses a **pluggable storage** architecture for file system operations:

| Provider | Platform | Description |
|----------|----------|-------------|
| `NativeStorageProvider` | Native | File system for iOS, Android, Desktop |
| `WebStorageProvider` | Web | In-memory storage (IndexedDB planned) |

---

## 👥 Sharing

Sharing works via public-key cryptography:

1. You wrap a scope key with recipient's public key
2. Server stores the wrapped key (cannot decrypt)
3. Recipient unwraps with their secret key
4. Revocation rotates the key

---

## 🛠️ Development

### Tech Stack

- **Flutter** - Cross-platform UI (iOS, Android, macOS, Linux, Windows, Web)
- **Riverpod** - State management
- **libsodium** - Cryptography (via sodium_libs)
- **SQLite** - Local search index
- **Pluggable Sync** - HTTP, Firebase, or custom backends

### Code Generation

```bash
# Generate freezed/json_serializable code
dart run build_runner build
```

---

## 📄 Documentation

- [Product Overview](docs/PRODUCT.md) - Full architecture documentation
- [Crypto Primitives](lib/core/crypto/) - Cryptographic implementations
- [Vault System](lib/core/vault/) - Vault management

---

## 🤝 Contributing

Contributions are welcome! Please read our security guidelines before submitting PRs.

### Security Guidelines

1. **No custom crypto** - Use libsodium primitives only
2. **Explicit key lifecycle** - Document key creation, use, disposal
3. **Zeroize secrets** - Always dispose SecureBytes
4. **Test crypto code** - Every primitive needs tests

---

## 📜 License

Witflo is licensed under the [Mozilla Public License 2.0 (MPL-2.0)](LICENSE).

---

## 🙏 Acknowledgments

- [libsodium](https://libsodium.org/) - Cryptographic library
- [sodium_libs](https://pub.dev/packages/sodium_libs) - Flutter bindings
- [Argon2](https://github.com/P-H-C/phc-winner-argon2) - Password hashing

---

*Built with the belief that privacy is a fundamental right, not a feature.*

