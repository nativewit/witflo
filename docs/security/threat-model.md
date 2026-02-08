# Threat Model

Understanding what Witflo protects against and its security boundaries.

## Security Objectives

Witflo aims to provide:

1. **Confidentiality** - Your notes remain private
2. **Integrity** - Your notes cannot be tampered with
3. **Availability** - You can always access your notes (with password)
4. **Zero-knowledge** - No one but you can read your notes

## Adversary Model

### Threat Actors

#### 🔴 Strong Adversary (Nation-state, Advanced Persistent Threat)

**Capabilities**:
- Network surveillance (intercept all traffic)
- Server compromise (full control of sync server)
- Advanced malware
- Physical device access
- Legal coercion

**Witflo's Defense**:
- ✅ End-to-end encryption defeats network surveillance
- ✅ Zero-knowledge architecture defeats server compromise
- ⚠️ Partial: Auto-lock limits exposure during physical access
- ❌ Cannot protect against device malware
- ❌ Cannot protect against legal coercion

#### 🟡 Moderate Adversary (Hackers, Criminals)

**Capabilities**:
- Network attacks (MITM, eavesdropping)
- Server attacks (SQL injection, RCE)
- Social engineering
- Phishing
- Stolen device

**Witflo's Defense**:
- ✅ TLS + E2E encryption defeats network attacks
- ✅ Zero-knowledge defeats server attacks
- ⚠️ Depends on user awareness (phishing, social engineering)
- ✅ Strong encryption defeats stolen device attacks

#### 🟢 Weak Adversary (Curious individuals)

**Capabilities**:
- Casual snooping
- Accessing unlocked device
- Looking over shoulder

**Witflo's Defense**:
- ✅ Auto-lock prevents casual access
- ✅ Encryption protects stored data
- ⚠️ Cannot prevent shoulder-surfing while unlocked

## Attack Scenarios

### 1. Server Compromise

**Scenario**: An attacker gains full control of the sync server.

**Attack**:
- Read database
- Modify stored data
- Inject malicious data

**Witflo's Defense**:
- ✅ Server only stores **encrypted ciphertext**
- ✅ Attacker cannot decrypt without user's password
- ✅ AEAD (Poly1305) prevents tampering
- ✅ Client verifies integrity before decryption

**Outcome**: ✅ **Protected** - Server compromise yields no plaintext

---

### 2. Network Interception

**Scenario**: Attacker intercepts network traffic (e.g., MITM attack).

**Attack**:
- Eavesdrop on sync traffic
- Modify data in transit
- Impersonate server

**Witflo's Defense**:
- ✅ TLS encrypts transport layer
- ✅ E2E encryption: Even if TLS broken, payload is encrypted
- ✅ Certificate pinning (planned) prevents MITM
- ✅ Integrity checks prevent data modification

**Outcome**: ✅ **Protected** - Network attacker sees only ciphertext

---

### 3. Stolen Device (Locked)

**Scenario**: Attacker steals a locked device with Witflo installed.

**Attack**:
- Extract encrypted database
- Brute-force password offline

**Witflo's Defense**:
- ✅ All data encrypted with Argon2id-derived keys
- ✅ Memory-hard KDF makes brute-force expensive
- ⚠️ Strong password required (user responsibility)

**Outcome**: 
- ✅ **Protected** if password is strong (12+ chars, complex)
- ❌ **Vulnerable** if password is weak ("password123")

**Recommendation**: Use a strong, unique password or passphrase.

---

### 4. Device Malware

**Scenario**: Malware running on user's device.

**Attack**:
- Keylogger captures password
- Memory dump while workspace unlocked
- Screen recording

**Witflo's Defense**:
- ❌ Cannot detect or prevent malware
- ⚠️ Auto-lock limits window of opportunity
- ⚠️ Memory zeroization helps (but not perfect)

**Outcome**: ❌ **Not Protected** - Malware with sufficient privileges can compromise

**Recommendation**: 
- Keep OS and antivirus updated
- Avoid installing untrusted software
- Use device encryption (FileVault, BitLocker)

---

### 5. Physical Access (Device Unlocked)

**Scenario**: Attacker accesses an unlocked device.

**Attack**:
- Read notes directly
- Export workspace
- Copy encryption keys from memory

**Witflo's Defense**:
- ⚠️ Auto-lock after inactivity
- ⚠️ Manual lock button
- ❌ If device is unlocked, notes are accessible

**Outcome**: ❌ **Not Protected** while unlocked

**Recommendation**:
- Configure short auto-lock timeout (5-15 min)
- Lock manually when stepping away
- Enable device lock screen

---

### 6. Shoulder Surfing

**Scenario**: Attacker observes screen while user works.

**Attack**:
- Read notes over shoulder
- Observe password entry

**Witflo's Defense**:
- ❌ Cannot prevent visual observation

**Outcome**: ❌ **Not Protected** against visual observation

**Recommendation**:
- Be aware of surroundings
- Privacy screen protector
- Work in private spaces

---

### 7. Brute-Force Password Attack

**Scenario**: Attacker attempts to guess password.

**Attack**:
- Online: Repeatedly try passwords via app
- Offline: Extract encrypted keyring, brute-force locally

**Witflo's Defense**:
- ✅ Argon2id parameters make each attempt expensive (~100ms)
- ✅ Rate limiting on unlock attempts (planned)
- ⚠️ Offline attacks are harder to prevent

**Outcome**:
- ✅ **Protected** against online attacks (rate limiting)
- ⚠️ **Partially protected** offline (depends on password strength)

**Cost to brute-force** (assuming 64 MiB memory, 4 iterations):
- 8-char lowercase: ~1 hour (weak)
- 12-char mixed: ~centuries (strong)
- 5-word passphrase: ~millennia (very strong)

---

### 8. Backup Compromise

**Scenario**: Attacker accesses exported backup file.

**Attack**:
- Download backup from cloud
- Steal USB drive with backup
- Access old backup on compromised machine

**Witflo's Defense**:
- ✅ Backups can be encrypted (recommended)
- ⚠️ Plain markdown exports are not encrypted

**Outcome**:
- ✅ **Protected** if encrypted backup used
- ❌ **Not Protected** if plain export used

**Recommendation**:
- Use encrypted JSON export format
- Store backups securely (encrypted USB, password manager vault)
- Avoid uploading unencrypted backups to cloud

---

### 9. Deleted Data Recovery

**Scenario**: Attacker attempts to recover deleted notes.

**Attack**:
- File system forensics
- Undelete tools
- Analyze disk sectors

**Witflo's Defense**:
- ⚠️ Deleted notes are removed from database
- ❌ File system may retain data until overwritten
- ❌ No secure erase implemented (yet)

**Outcome**: ⚠️ **Partially Protected** - Depends on file system

**Recommendation**:
- Use full-disk encryption (FileVault, BitLocker, LUKS)
- Manually wipe free space periodically

---

### 10. Supply Chain Attack

**Scenario**: Attacker compromises Witflo build process or dependencies.

**Attack**:
- Inject backdoor into app binary
- Compromise npm/pub package
- Malicious Flutter SDK

**Witflo's Defense**:
- ✅ Open-source code (auditable)
- ✅ Deterministic builds (planned)
- ✅ Signed releases (planned)
- ⚠️ Dependency auditing (ongoing)

**Outcome**: ⚠️ **Partially Protected** - Trust in build process required

**Recommendation**:
- Verify release signatures
- Build from source if paranoid
- Review dependency changes

---

## Security Boundaries

### What is Inside the Trust Boundary

You must trust:
- ✅ Your device is not compromised
- ✅ libsodium implementation
- ✅ Flutter/Dart runtime
- ✅ Your password is strong and secret
- ✅ Your physical security while unlocked

### What is Outside the Trust Boundary

You do NOT need to trust:
- ❌ Sync server (zero-knowledge)
- ❌ Network infrastructure (E2E encrypted)
- ❌ Cloud storage (if encrypted backups used)
- ❌ Witflo developers (open source, auditable)

## Out of Scope

Witflo does **not** protect against:
- Quantum computers (not yet post-quantum safe)
- Advanced forensics on device memory
- Legal coercion or court orders
- Compromised OS or bootloader
- Hardware keyloggers

## Risk Summary

| Threat | Risk Level | Protection |
|--------|------------|------------|
| Server compromise | 🟢 Low | ✅ Zero-knowledge E2E encryption |
| Network interception | 🟢 Low | ✅ TLS + E2E encryption |
| Stolen device (locked) | 🟡 Medium | ⚠️ Depends on password strength |
| Device malware | 🔴 High | ❌ Cannot protect |
| Physical access (unlocked) | 🟡 Medium | ⚠️ Auto-lock mitigates |
| Weak password | 🔴 High | ⚠️ User responsibility |
| Backup compromise | 🟡 Medium | ⚠️ Use encrypted backups |
| Supply chain attack | 🟡 Medium | ⚠️ Verify signatures |

## Recommendations for Users

### Essential

1. **Use a strong, unique password**
   - Minimum 12 characters
   - Mix of letters, numbers, symbols
   - Or use a 4-5 word passphrase

2. **Enable auto-lock**
   - Set to 5-15 minutes
   - Lock manually when leaving device

3. **Keep software updated**
   - Install Witflo updates promptly
   - Keep OS and security patches current

### Recommended

4. **Enable full-disk encryption**
   - FileVault (macOS)
   - BitLocker (Windows)
   - LUKS (Linux)

5. **Use encrypted backups**
   - Export in encrypted JSON format
   - Store securely (password manager, encrypted USB)

6. **Be aware of surroundings**
   - Avoid working in public with sensitive notes
   - Lock device when stepping away

### Advanced

7. **Verify release signatures** (when available)
8. **Build from source** for maximum assurance
9. **Review code changes** before updating
10. **Use hardware security keys** (planned feature)

## Future Improvements

- [ ] Post-quantum cryptography
- [ ] Hardware-backed key storage (TPM, Secure Enclave)
- [ ] Secure erase for deleted notes
- [ ] Canary tokens for tampering detection
- [ ] Biometric unlock with hardware isolation
- [ ] Rate limiting on unlock attempts

---

**Questions about security?** Open a [discussion on GitHub](https://github.com/nativewit/witflo/discussions).

**Found a vulnerability?** Email security@witflo.app (do not open public issue).
