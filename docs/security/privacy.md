# Privacy Guarantees

How Witflo protects your privacy and what data practices we follow.

## Core Privacy Principles

1. **Zero data collection** - We don't collect analytics, telemetry, or usage data
2. **Zero knowledge** - Your notes are encrypted on your device with keys only you have
3. **No tracking** - No cookies, pixels, or third-party trackers
4. **Offline-first** - Works completely without internet connection
5. **Open source** - Code is auditable by anyone

## Your Data Stays Private

### Everything Is Encrypted Locally

All your data is stored **encrypted on your device**:

| Data Type | Location | Encrypted |
|-----------|----------|-----------|
| Note content | Local file system | ✅ Yes |
| Note titles | SQLite database | ✅ Yes |
| Note metadata | SQLite database | ✅ Yes |
| Tags & Notebooks | SQLite database | ✅ Yes |
| Workspace settings | Local config | ✅ Yes |
| App preferences | Local config | Only non-sensitive data |

**Storage Locations:**
- macOS: `~/Library/Application Support/witflo/`
- Linux: `~/.local/share/witflo/`
- Windows: `%APPDATA%/witflo/`
- iOS: App sandbox
- Android: App-private storage

## What We Collect

### The Short Answer: Nothing

Witflo is designed to collect zero information about you or your usage.

**Personal Information**
- No name, email, or contact information required
- No account registration
- No user profiles

**Usage Data**
- No analytics (Google Analytics, etc.)
- No telemetry
- No feature usage tracking
- No crash reports sent automatically

**Note Content**
- Your notes stay on your device, encrypted
- We never see your note content
- No search queries logged
- No content indexing on our servers

**Metadata**
- No timestamp tracking on our servers
- No device fingerprinting
- No IP address logging
- No geolocation tracking

**Technical Data**
- No automatic error reporting
- No performance metrics collection
- No A/B testing
- No behavioral analytics

## How Sync Works (When Enabled)

### Only Encrypted Data Leaves Your Device

When you enable sync (optional feature):

**What the server receives:**
- Encrypted note blobs (unreadable ciphertext)
- Encrypted metadata (unreadable ciphertext)
- Sync timestamps (for conflict resolution)
- Workspace ID (random UUID, non-identifying)

**What the server never sees:**
- Your password or encryption keys
- Note content in readable form
- Note titles in readable form
- Tags or notebook names in readable form
- Any personal information

### Network Activity

Witflo is **offline-first** and connects to the internet only for:

**1. Sync (Optional)**
- Only when you enable and configure sync
- Only encrypted data transmitted
- End-to-end encrypted before leaving your device

**2. Updates (Optional)**
- Checks for new app versions
- Connects to GitHub API (not controlled by us)
- Can be disabled in settings

**3. Nothing Else**
- No analytics requests
- No telemetry transmissions
- No tracking pixels or beacons

### Self-Hosting

Take complete control of your data:
- Run your own sync server
- No third-party involvement
- Full ownership of all data
- Open-source sync server code (coming soon)

## Browser & Web Version

### Local Storage Only

**What's stored in your browser:**
- Encrypted workspace state in IndexedDB
- Session storage for encrypted data
- Cleared automatically when you lock the workspace

**What's NOT in your browser:**
- Third-party cookies
- Tracking scripts
- Analytics code
- Any unencrypted note data

## Mobile Apps

### Minimal Permissions

Witflo only requests permissions it actually needs:

| Permission | Required? | Why? |
|------------|-----------|------|
| Storage | ✅ Yes | Store your encrypted notes |
| Network | Optional | Only if using sync |
| Biometric | Optional | Biometric unlock feature |
| Camera | ❌ Never | Not used |
| Microphone | ❌ Never | Not used |
| Location | ❌ Never | Not used |
| Contacts | ❌ Never | Not used |

### App Store Privacy Labels

**iOS Privacy Nutrition Label:**
- Data collected: **None**
- Data linked to you: **None**
- Data used to track you: **None**

**Google Play Data Safety:**
- No data shared with third parties
- No data collected

## Third-Party Services

### What We Use

**For core functionality:** Nothing

**Optional services:**
- **GitHub** - For app updates only (if you enable update checks)
- **Your sync server** - If you configure self-hosted sync

### What We Don't Use

Witflo includes zero third-party tracking or analytics:

- No Google Analytics
- No Firebase Analytics
- No Sentry crash reporting
- No Crashlytics
- No Facebook SDK
- No advertising networks
- No tracking SDKs of any kind

## Data Retention

### On Your Device

Your data stays on your device until you delete it:
- Stored indefinitely in encrypted form
- Removed when you delete a workspace
- Completely erased when you uninstall the app

### On Sync Server (If Using Sync)

**Active data:**
- Stored encrypted on the sync server
- Only you can decrypt it

**Deleted notes:**
- Soft deleted for 30 days (for conflict resolution)
- Permanently removed after 30 days

**Account deletion:**
- All data immediately purged from sync server
- No recovery possible after deletion

## Privacy Compliance

### GDPR (Europe)

Witflo is GDPR-compliant by design:
- ✅ No personal data collected
- ✅ Data minimization (only what's necessary)
- ✅ Encryption by design and default
- ✅ Right to deletion (built into the app)
- ✅ Data portability (export feature)
- ✅ No automated decision-making

### CCPA (California)

Witflo respects your privacy rights:
- ✅ No personal information sold (we don't collect it)
- ✅ No personal information shared
- ✅ No personal information collected

### Other Regulations

- **HIPAA**: Not certified (independent audit not performed)
- **COPPA**: No data collection, suitable for all ages
- **SOC 2**: Not certified (small project)

## Privacy Comparison

See how Witflo compares to other note-taking apps:

| Feature | Witflo | Evernote | Notion | Apple Notes |
|---------|--------|----------|--------|-------------|
| E2E Encryption | ✅ Yes | ❌ No | ❌ No | Partial |
| Zero-knowledge | ✅ Yes | ❌ No | ❌ No | Partial |
| Analytics | ❌ None | ✅ Yes | ✅ Yes | Limited |
| Open source | ✅ Yes | ❌ No | ❌ No | ❌ No |
| Self-hosting | ✅ Yes | ❌ No | ❌ No | ❌ No |

## Transparency Commitment

### How We Ensure Privacy

1. **Open source code** - All code is public and auditable on GitHub
2. **No accounts needed** - No registration or login required
3. **Local-first architecture** - Data stays on your device
4. **Minimal network use** - Only encrypted sync traffic when enabled
5. **Zero telemetry** - No data collection infrastructure

### Our Privacy Promise

Your notes are encrypted on your device. Only you have the keys to decrypt them. We build privacy into every feature from day one.

## Common Questions

### Can Witflo read my notes?

No. Your notes are encrypted on your device before storage or sync. We only ever see encrypted data that is useless without your password.

### What about government requests?

We only have encrypted data and cannot decrypt it. If legally required to provide data, we can only share:
- Encrypted data blobs (unreadable without your password)
- Sync timestamps
- Workspace IDs (random, non-identifying)

We never have access to:
- Your password or encryption keys
- Readable note content
- Personal information (we don't collect it)

### Can you recover my password?

No. By design, we have no way to recover passwords. This is a security feature. No backdoors means complete privacy - no one (including us) can access your data without your password.

### Will privacy practices change?

We commit to:
- ✅ Never collecting personal data
- ✅ Never selling any data
- ✅ Never adding tracking
- ✅ Remaining open source forever

If we ever need to collect any data (for example, to prevent fraud), we will:
1. Announce changes publicly
2. Update the privacy policy
3. Make collection optional
4. Keep data collection minimal

## Contact

Have privacy concerns or questions?

- Email: privacy@witflo.app (coming soon)
- Open source: [View code on GitHub](https://github.com/nativewit/witflo)

---

**Last updated**: February 2025  
**Effective date**: February 2025
