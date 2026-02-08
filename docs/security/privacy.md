# Privacy Guarantees

What Witflo does and doesn't collect, and how we protect your privacy.

## Core Privacy Principles

1. **Zero data collection** - We don't collect analytics, telemetry, or usage data
2. **Zero knowledge** - We cannot access your notes, even if we wanted to
3. **No tracking** - No cookies, pixels, or third-party trackers
4. **Offline-first** - Works completely without internet
5. **Open source** - Code is auditable by anyone

## What Witflo Does NOT Collect

### ❌ Personal Information
- No name, email, or contact information
- No account registration required
- No user profiles

### ❌ Usage Data
- No analytics (Google Analytics, etc.)
- No telemetry
- No feature usage tracking
- No crash reports (unless manually shared)

### ❌ Note Content
- Your notes never leave your device unencrypted
- Server (if using sync) only sees ciphertext
- No search queries logged
- No content indexing

### ❌ Metadata
- No timestamp tracking
- No device fingerprinting
- No IP address logging
- No geolocation

### ❌ Technical Data
- No error reporting (automatic)
- No performance metrics
- No A/B testing
- No behavioral analytics

## What Witflo DOES Store

### ✅ Locally on Your Device

All data is stored **encrypted on your device**:

| Data Type | Location | Encrypted |
|-----------|----------|-----------|
| Note content | Local file system | ✅ Yes |
| Note metadata | SQLite database | ✅ Yes |
| Workspace settings | Local config | ✅ Yes |
| App preferences | Local config | ❌ No (non-sensitive) |

**Where?**
- macOS: `~/Library/Application Support/witflo/`
- Linux: `~/.local/share/witflo/`
- Windows: `%APPDATA%/witflo/`
- iOS: App sandbox
- Android: App-private storage

### ⚠️ On Sync Server (When Sync is Enabled)

**Only encrypted data**:
- Encrypted note blobs (ciphertext only)
- Encrypted metadata (ciphertext only)
- Sync timestamps (for conflict resolution)
- Workspace ID (random UUID, non-identifying)

**Server cannot see**:
- Your password
- Note content (plaintext)
- Note titles
- Tags or notebooks
- Any personal information

## Network Activity

### When Does Witflo Connect to the Internet?

Witflo is **offline-first** and only uses the network for:

1. **Sync** (optional, when enabled)
   - Only encrypted data transmitted
   - End-to-end encrypted

2. **Updates** (optional)
   - Check for new versions
   - Sent to GitHub API (not controlled by us)

3. **Nothing else**
   - No analytics requests
   - No telemetry
   - No tracking pixels

### Network Requests Breakdown

When sync is enabled:

```
POST https://sync.witflo.app/v1/sync
Content-Type: application/octet-stream
Body: <encrypted blob>

Response: 
{
  "status": "ok",
  "timestamp": "2025-02-08T12:00:00Z"
}
```

That's it. No cookies, no tracking headers, no analytics.

### Self-Hosting

You can run your own sync server:
- Full control over your data
- No third-party involvement
- Open-source sync server (coming soon)

## Browser/Web Version

### Cookies
- ❌ No third-party cookies
- ✅ Local session storage (encrypted workspace state)

### Local Storage
- Only encrypted data stored in IndexedDB
- Cleared when workspace is locked

### Web Analytics
- ❌ None

## Mobile Apps

### Permissions

| Permission | Required? | Why? |
|------------|-----------|------|
| Storage | ✅ Yes | Store encrypted notes |
| Network | ⚠️ Optional | Sync only |
| Biometric | ⚠️ Optional | Biometric unlock |
| Camera | ❌ No | Not used |
| Microphone | ❌ No | Not used |
| Location | ❌ No | Not used |
| Contacts | ❌ No | Not used |

### App Store Privacy Labels

**iOS Privacy Nutrition Label**:
- Data collected: **None**
- Data linked to you: **None**
- Data used to track you: **None**

**Google Play Data Safety**:
- No data shared with third parties
- No data collected

## Third-Party Services

### What Third Parties Does Witflo Use?

**None** for core functionality.

Optional:
- **GitHub** (for updates, if enabled)
- **Your self-hosted sync server** (if configured)

### No Third-Party SDKs

Witflo does not include:
- ❌ Google Analytics
- ❌ Firebase
- ❌ Sentry
- ❌ Crashlytics
- ❌ Facebook SDK
- ❌ Ad networks
- ❌ Any tracking SDKs

## Data Retention

### How Long is Data Kept?

**On your device**: Indefinitely (until you delete it)

**On sync server** (if using sync):
- Deleted notes: 30 days (soft delete for conflict resolution)
- Inactive workspaces: No automatic deletion
- After account deletion: Immediate (all data purged)

### Deleting Your Data

**Locally**:
1. Delete workspace → Data immediately removed
2. Uninstall app → All data removed

**On sync server**:
1. Delete workspace in app → Soft delete (30-day recovery)
2. Request permanent deletion → Immediate purge

## Compliance

### GDPR (General Data Protection Regulation)

Witflo is GDPR-friendly:
- ✅ No personal data collected
- ✅ Data minimization (only what's needed)
- ✅ Encryption by design
- ✅ Right to deletion (built-in)
- ✅ Data portability (export feature)
- ✅ No automated decision-making

### CCPA (California Consumer Privacy Act)

- ✅ No personal information sold
- ✅ No personal information shared
- ✅ No personal information collected

### Other Regulations

- **HIPAA**: Not HIPAA-compliant (not audited)
- **COPPA**: No data collection, but under-13 use discouraged
- **SOC 2**: Not certified (small project)

## Privacy Comparison

| Feature | Witflo | Evernote | Notion | Apple Notes |
|---------|--------|----------|--------|-------------|
| E2E Encryption | ✅ Yes | ❌ No | ❌ No | ⚠️ Partial |
| Zero-knowledge | ✅ Yes | ❌ No | ❌ No | ⚠️ Partial |
| Analytics | ❌ None | ✅ Yes | ✅ Yes | ⚠️ Limited |
| Open source | ✅ Yes | ❌ No | ❌ No | ❌ No |
| Self-hosting | ✅ Yes | ❌ No | ❌ No | ❌ No |

## Transparency

### How We Ensure Privacy

1. **Open source** - All code is public and auditable
2. **No accounts** - No registration or login required
3. **Local-first** - Data stays on your device
4. **Minimal network** - Only encrypted sync traffic
5. **No telemetry** - Zero data collection

### Privacy Policy (TL;DR)

> We don't collect, store, or transmit any personal information. Your notes are encrypted on your device. We cannot read them, and we don't want to.

Full privacy policy: [witflo.app/privacy](https://witflo.app/privacy) (coming soon)

## Questions & Concerns

### Can Witflo see my notes?

**No.** Your notes are encrypted on your device before being stored or synced. We only ever see encrypted ciphertext.

### Can government agencies access my notes?

Not through us. We don't have your encryption keys or password. However, if they have physical access to your device and your password, they could unlock it (like any encrypted system).

### What if Witflo is subpoenaed?

We can only provide:
- Encrypted blobs (useless without password)
- Sync timestamps
- Workspace IDs (random UUIDs)

We cannot provide:
- Passwords (we don't have them)
- Note content (encrypted)
- Personal information (we don't collect it)

### Can you recover my password?

**No.** By design, we cannot recover passwords. This is a feature, not a bug. No backdoors means no one (including us) can access your data without your password.

### What data do you share with law enforcement?

Only what we're legally required to provide:
- Encrypted data (which they cannot decrypt)
- Public metadata (timestamps, UUIDs)

We do NOT share (because we don't have):
- Passwords
- Decryption keys
- Plaintext notes

### Will this change in the future?

We commit to:
- ✅ Never collecting personal data
- ✅ Never selling data
- ✅ Never adding tracking
- ✅ Remaining open source

If we ever need to collect data (e.g., for fraud prevention), we will:
1. Announce it publicly
2. Update privacy policy
3. Make it optional
4. Keep it minimal

## Contact

Privacy concerns? Email: privacy@witflo.app (coming soon)

Or open a discussion: [GitHub Discussions](https://github.com/nativewit/witflo/discussions)

---

**Last updated**: February 2025  
**Effective date**: February 2025
