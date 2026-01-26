# 🔐 Fyndo

**Zero-Trust, Privacy-First, Offline-First Notes OS**

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-TBD-green.svg)]()
[![Security](https://img.shields.io/badge/Security-Zero%20Trust-red.svg)]()

---

## 🎯 What is Fyndo?

Fyndo is a note-taking and personal knowledge management app built on one unwavering principle:

> **The server is hostile, the network is compromised, and your notes are worth millions.**

Every design decision prioritizes **your privacy** and **data sovereignty** over convenience.

### Key Features

- 🔒 **End-to-End Encrypted** - All content encrypted on your device
- 📱 **Local-First** - Works fully offline, sync is optional
- 🚫 **Zero-Trust** - Servers never see your data
- 🔑 **Deterministic Recovery** - Password + salt = full vault recovery
- 🔐 **Audited Cryptography** - libsodium primitives only

---

## 🏗️ Architecture

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

## 🚀 Getting Started

### Prerequisites

- Flutter 3.38.7+ (via FVM recommended)
- Dart 3.10.7+
- FVM (Flutter Version Management)

### Installation

```bash
# Clone the repository
git clone https://github.com/your-org/fyndo-platform.git
cd fyndo-platform

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

Fyndo uses a **pluggable sync backend** architecture:

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

Fyndo uses a **pluggable database** architecture:

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

Fyndo uses a **pluggable storage** architecture for file system operations:

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

[To be determined]

---

## 🙏 Acknowledgments

- [libsodium](https://libsodium.org/) - Cryptographic library
- [sodium_libs](https://pub.dev/packages/sodium_libs) - Flutter bindings
- [Argon2](https://github.com/P-H-C/phc-winner-argon2) - Password hashing

---

*Built with the belief that privacy is a fundamental right, not a feature.*

