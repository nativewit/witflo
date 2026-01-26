# Fyndo - Zero-Trust Notes OS

**Version:** 0.1.0  
**Last Updated:** January 26, 2026

---

## 🔐 Vision

Fyndo is a **zero-trust, privacy-first, offline-first** note-taking and LifeOS application. Built on the principle that:

> **The server is hostile, the network is compromised, and your notes are worth millions.**

Every design decision prioritizes user privacy and data sovereignty over convenience or speed.

---

## 🏗️ Architecture Overview

### Technology Stack

| Layer | Technology |
|-------|------------|
| **Client** | Flutter (iOS, Android, macOS, Linux, Windows) |
| **Cryptography** | libsodium via FFI |
| **Local Storage** | File-system based encrypted vault |
| **State Management** | Riverpod |
| **Sync Relay** | Firebase (ciphertext-only) |

### Security Principles

1. **Zero Trust** - Servers never see plaintext
2. **Local-First** - Full offline functionality
3. **Explicit Cryptography** - Audited primitives only
4. **Deterministic Recovery** - Password + salt = full recovery
5. **No Magic** - Every key has a documented lifecycle

---

## 🔑 Cryptographic Primitives

All cryptography uses **libsodium** audited implementations:

| Primitive | Algorithm | Purpose |
|-----------|-----------|---------|
| **Password KDF** | Argon2id | Master password → Master Unlock Key |
| **AEAD Encryption** | XChaCha20-Poly1305 | All symmetric encryption |
| **Key Derivation** | HKDF-SHA256 | Derive sub-keys from Vault Key |
| **Hashing** | BLAKE3 (BLAKE2b fallback) | Content addressing |
| **Signing** | Ed25519 | Digital signatures |
| **Key Exchange** | X25519 | Key wrapping for sharing |
| **Random** | libsodium CSPRNG | All random values |

---

## 🗝️ Key Hierarchy

```
Master Password (user input, never stored)
    ↓ Argon2id (salt + params from vault.header)
Master Unlock Key (MUK) — memory only, never persisted
    ↓ decrypts vault.vk
Vault Key (VK) — 256-bit random, stored encrypted
    ↓ HKDF with context strings
    ├── Content Key (CK) — per note: "fyndo.content.{noteId}.v1"
    ├── Notebook Key (NK) — per notebook: "fyndo.notebook.{id}.v1"
    ├── Group Key (GK) — shared vaults: "fyndo.group.{id}.v1"
    ├── Note Share Key (NSK) — one-off shares: "fyndo.share.{id}.v1"
    └── Search Index Key — "fyndo.search.index.v1"
```

### Security Invariants

- ❌ Password is NEVER stored
- ❌ MUK is NEVER persisted
- ❌ VK/NK/GK/NSK are NEVER stored in plaintext
- ✅ All scope keys are wrapped per device

---

## 📁 Vault Filesystem Layout

```
/VaultRoot/
├── vault.header          # PLAINTEXT: version, Argon2 params, salt
├── vault.vk              # VK encrypted with MUK
├── device.key            # VK wrapped with device key (fast unlock)
├── objects/              # Encrypted content-addressed blobs
│   ├── 00/
│   ├── 01/
│   │   └── 23456789...   # Hash-based filename
│   └── ff/
├── refs/                 # Encrypted index files
│   ├── notes.jsonl.enc
│   ├── tags.jsonl.enc
│   ├── notebooks.jsonl.enc
│   └── search.db.enc
└── sync/                 # Sync state
    ├── cursor.enc
    └── pending/
        └── {opId}.op.enc
```

### What's in vault.header (ONLY plaintext file)

```json
{
  "version": 1,
  "salt": "base64...",
  "kdf": {
    "memory_kib": 65536,
    "iterations": 3,
    "parallelism": 1,
    "version": 1
  },
  "created_at": "2026-01-26T10:00:00Z",
  "vault_id": "uuid"
}
```

---

## 🔄 Sync Architecture

Firebase serves as a **dumb mailbox**:

- ✅ Stores encrypted operation blobs
- ✅ Provides ordering via timestamps
- ✅ Delivers blobs to devices
- ❌ Never decrypts content
- ❌ Never generates/derives keys
- ❌ Never processes plaintext

### Sync Flow

1. Local change → Create SyncOperation
2. Sign operation with device key
3. Encrypt with vault-derived sync key
4. Push to Firebase
5. Other devices pull encrypted ops
6. Decrypt, verify signature, apply locally

### Conflict Resolution

- Lamport timestamps for ordering
- Last-writer-wins for conflicts
- Future: CRDT-based text merging

---

## 👥 Sharing Model

### Identity

Each user has:
- **User Identity Key (UIK)**: Ed25519 + X25519 derived from Vault Key
- **Device Identity Key (DIK)**: Per-device Ed25519 + X25519

### Sharing Flow

1. Alice wants to share notebook with Bob
2. Alice gets Bob's X25519 public key
3. Alice wraps NotebookKey with Bob's public key
4. Server stores: `{wrappedKey, role, metadata}` (all ciphertext)
5. Bob unwraps NotebookKey with his secret key
6. Bob can now decrypt notebook content

### Revocation

1. Revoke access
2. Generate NEW NotebookKey
3. Re-encrypt all content
4. Re-wrap for remaining members
5. Old key cannot decrypt new content

---

## 🔍 Search

### Blind Token Search

1. **Indexing**: Hash tokens with search key → store `{hashedToken → noteIds}`
2. **Searching**: Hash query tokens → lookup → return matching noteIds
3. **Verification**: Decrypt matched notes to verify

### Properties

- ✅ Works without decrypting all notes
- ✅ Index is encrypted at rest
- ❌ No fuzzy/substring search (by design)

---

## 🔌 Plugin System (Planned)

Plugins will:
- Run in isolates or WASM
- Declare required permissions
- Be cryptographically signed
- Access notes only via capability broker
- Never receive raw keys

---

## ☁️ Cloud Backup (Planned)

BYOC (Bring Your Own Cloud):
- Google Drive
- OneDrive
- S3-compatible

Uploads only:
- vault.header
- vault.vk (encrypted)
- Encrypted objects

Restore requires password + salt.

---

## 📊 Implementation Status

| Component | Status |
|-----------|--------|
| Core crypto module | ✅ Complete |
| Key types & lifecycle | ✅ Complete |
| Vault creation/unlock | ✅ Complete |
| Encrypted local storage | ✅ Complete |
| Note CRUD | ✅ Complete |
| Device identity | ✅ Complete |
| User identity | ✅ Complete |
| Sync operations | ✅ Complete |
| Sharing model | ✅ Complete |
| Encrypted search | ✅ Complete |
| Riverpod providers | ✅ Complete |
| UI scaffold | ✅ Complete |
| Firebase integration | 🔄 Pending |
| Plugin sandbox | 🔄 Pending |
| Cloud backup | 🔄 Pending |
| CRDT text merging | 🔄 Pending |

---

## 🛡️ Security Considerations

### What We Protect Against

- ✅ Server compromise
- ✅ Network interception
- ✅ Malicious cloud providers
- ✅ Key logging (keys zeroized after use)
- ✅ Timing attacks (constant-time operations)

### What We Don't Protect Against

- ❌ Compromised device (root/malware)
- ❌ Weak passwords (but Argon2id helps)
- ❌ Rubber-hose cryptanalysis
- ❌ Side-channel attacks on device

---

## 🚀 Getting Started

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Build for production
flutter build apk
flutter build macos
```

---

## 📚 Code Structure

```
lib/
├── core/
│   ├── crypto/           # Cryptographic primitives
│   │   ├── types/        # SecureBytes, key types
│   │   └── primitives/   # Argon2id, XChaCha20, HKDF, etc.
│   ├── vault/            # Vault management
│   ├── identity/         # User & device identity
│   ├── sync/             # Sync operations
│   ├── sharing/          # Sharing service
│   └── search/           # Encrypted search index
├── features/
│   └── notes/            # Note feature
│       ├── models/
│       └── data/
├── providers/            # Riverpod providers
└── main.dart             # Entry point
```

---

## 📄 License

[To be determined]

---

*Built with the belief that privacy is a fundamental right, not a feature.*

