# Encryption

How Witflo keeps your notes secure with industry-standard encryption.

## Overview

Witflo uses **military-grade encryption** to protect your notes. Every note is encrypted on your device before it's saved or synced, ensuring that only you can read your data.

**Core principles**:
- **Zero-trust**: Server never sees your actual notes
- **Client-side encryption**: All encryption happens on your device
- **Tamper-proof**: Prevents anyone from modifying your notes
- **Unique keys**: Each note has its own encryption key

## Encryption Technology

Witflo uses [libsodium](https://libsodium.gitbook.io/), a well-audited cryptographic library trusted by security professionals worldwide.

### What We Use

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Password Protection | Argon2id | Turns your password into encryption keys |
| Key Generation | HKDF | Creates unique keys for each note |
| Note Encryption | XChaCha20-Poly1305 | Encrypts and protects your notes |
| Random Numbers | libsodium RNG | Generates secure random values |

All encryption algorithms are **NIST-approved** and recommended by security experts.

## How Your Notes Are Protected

### The Encryption Process

When you create or edit a note, here's what happens:

1. **You unlock your workspace** with your master password
2. **Your password creates keys** - Special encryption keys are derived from your password
3. **Each note gets a unique key** - Every note is encrypted with its own key
4. **Everything is encrypted** - Note content, titles, tags, and metadata are all encrypted
5. **Only encrypted data is saved** - Your device stores only encrypted files

### Key Security Features

**Password Protection**
- Your password is transformed using Argon2id, a memory-intensive algorithm
- This makes it extremely expensive for attackers to guess passwords
- Winner of the Password Hashing Competition and recommended by OWASP

**Unique Keys Per Note**
- Every note has its own encryption key
- If one key is compromised, other notes remain protected
- Limits damage and enables secure key rotation

**Tamper-Proof Encryption**
- XChaCha20-Poly1305 provides authenticated encryption
- Any attempt to modify encrypted notes is detected
- Ensures note integrity and authenticity

**Secure Random Generation**
- All random values use cryptographically secure generators
- Proper nonce generation prevents encryption attacks
- Different random values for every encryption operation

## What Gets Encrypted

### Fully Encrypted

Everything about your notes is encrypted:

| Data | Encrypted |
|------|-----------|
| Note content | ✅ Yes |
| Note titles | ✅ Yes |
| Note metadata | ✅ Yes |
| Tags | ✅ Yes |
| Notebooks | ✅ Yes |
| Timestamps | ✅ Yes |
| Workspace settings | ✅ Yes |

### App Preferences

Only non-sensitive app preferences (like theme choice) are stored unencrypted on your device.

## How Encryption Protects You

### Your Notes Are Safe From:

**Server Breaches**
- The sync server only sees encrypted data
- Even if the server is hacked, your notes remain secure
- Attackers only get useless encrypted bytes

**Network Interception**
- Your notes are already encrypted before transmission
- Network attackers cannot read intercepted data
- All data in transit is protected

**Device Theft**
- Encrypted files are useless without your password
- Even with physical access, notes cannot be decrypted
- Your data stays private

**Memory Dumps**
- Keys are cleared from memory when you lock the workspace
- Reduces risk from memory access attacks
- Automatic cleanup on app close

**Brute Force Attacks**
- Argon2id makes password guessing extremely expensive
- Each password attempt requires significant computing resources
- Makes automated attacks impractical

## Password Security

### Your Master Password

Your master password is the foundation of your security:

- **Never stored** - Only kept in memory while unlocked
- **Not recoverable** - We cannot reset or recover your password
- **You need to remember it** - Choose something memorable but strong
- **Cleared on lock** - Removed from memory when you lock the workspace

### Changing Your Password

You can change your master password anytime:

1. Unlock your workspace with your current password
2. Enter your new password
3. Witflo re-encrypts your workspace with the new password
4. All notes remain accessible with the new password

The process is seamless and your notes are never at risk during the password change.

## Encryption Standards

### Industry Compliance

| Standard | Status |
|----------|--------|
| NIST | Uses NIST-recommended algorithms |
| OWASP | Follows OWASP cryptographic guidelines |
| GDPR | Supports "encryption by design" requirements |

### Why These Algorithms?

**Argon2id (Password Hashing)**
- Memory-hard design makes GPU attacks expensive
- Resistant to side-channel attacks
- Recommended by security organizations worldwide

**XChaCha20-Poly1305 (Encryption)**
- Fast on all devices, no special hardware needed
- Authenticated encryption prevents tampering
- Large nonce space prevents encryption collisions
- Modern and extensively studied

**HKDF (Key Derivation)**
- Creates unique keys from master keys
- Enables key isolation per note
- Supports secure key rotation

## Memory Protection

### Keeping Keys Secure

Witflo takes extra steps to protect encryption keys in memory:

**Automatic Clearing**
- Keys are removed from memory when you lock your workspace
- App automatically clears keys on close
- Reduces window of vulnerability

**Secure Comparison**
- Password verification uses constant-time comparison
- Prevents timing attacks that could leak information
- Protects against advanced cryptographic attacks

**Memory Zeroization**
- Sensitive memory is overwritten with zeros
- Prevents recovery from memory dumps
- Protects against cold boot attacks

## What You Can Trust

### You DON'T Need to Trust:

- **The sync server** - It only sees encrypted data
- **Network infrastructure** - Everything is encrypted before transmission
- **Witflo developers** - Code is open source and auditable

### You DO Need to Trust:

- **Your device** - Must not be compromised by malware
- **Your password** - Must be strong and kept secret
- **Cryptographic libraries** - libsodium is widely audited and trusted
- **Your platform** - Flutter/Dart runtime and your operating system

## Future Security Enhancements

We're continuously improving security:

- Post-quantum cryptography (preparing for quantum computers)
- Hardware-backed key storage (TPM, Secure Enclave)
- Zero-knowledge sync improvements
- Enhanced key recovery options (Shamir's Secret Sharing)

## Learn More

Want to dive deeper into the cryptography?

- [libsodium Documentation](https://libsodium.gitbook.io/)
- [Argon2 RFC 9106](https://www.rfc-editor.org/rfc/rfc9106.html)
- [XChaCha20-Poly1305 Specification](https://tools.ietf.org/html/rfc8439)
- [HKDF RFC 5869](https://tools.ietf.org/html/rfc5869)
- [OWASP Cryptographic Storage Guide](https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html)

---

**Have questions about security?** Check out our [Privacy Guarantees](/security/privacy) or [Getting Started Guide](/guide/getting-started).
