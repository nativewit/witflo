# Features

Discover everything Witflo can do to keep your notes secure and organized.

---

## Core Features

<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 2rem; margin: 2rem 0;">

<div style="padding: 2rem; background: linear-gradient(135deg, #667eea15 0%, #764ba215 100%); border-radius: 12px; border-left: 4px solid #667eea;">

### 🔒 Zero-Trust Encryption

- **Client-side only** - All encryption happens on your device
- **libsodium** - Industry-standard cryptographic library  
- **No backdoors** - Source code is open and auditable
- **Memory safety** - Keys are zeroized after use

[Learn more about encryption →](/security/encryption)

</div>

<div style="padding: 2rem; background: linear-gradient(135deg, #f093fb15 0%, #f5576c15 100%); border-radius: 12px; border-left: 4px solid #f093fb;">

### 📴 Offline-First Architecture

- **Works without internet** - Full functionality offline
- **Local-first storage** - Your data lives on your device
- **No cloud required** - Works completely offline
- **Sync coming soon** - Cross-device sync in development

</div>

<div style="padding: 2rem; background: linear-gradient(135deg, #4facfe15 0%, #00f2fe15 100%); border-radius: 12px; border-left: 4px solid #4facfe;">

### 🗂️ Multi-Workspace Support

- **Unlimited workspaces** - Create as many as you need
- **Independent passwords** - Each workspace has its own key
- **Quick switching** - Easily jump between workspaces
- **Isolated data** - Complete separation between vaults

</div>

<div style="padding: 2rem; background: linear-gradient(135deg, #ffecd215 0%, #fcb69f15 100%); border-radius: 12px; border-left: 4px solid #ffecd2;">

### ✍️ Rich Text Editor

- **Formatting** - Bold, italic, underline, strikethrough
- **Lists** - Ordered and unordered lists
- **Code blocks** - Syntax highlighting
- **Links** - Hyperlinks and anchors
- **Markdown** - Full markdown support

</div>

<div style="padding: 2rem; background: linear-gradient(135deg, #a8edea15 0%, #fed6e315 100%); border-radius: 12px; border-left: 4px solid #a8edea;">

### 📓 Notebooks

- **Unlimited notebooks** - Create any number of notebooks
- **Custom colors** - Multiple color options for organization
- **Visual identification** - Easy to distinguish at a glance
- **Filtering** - View notes by specific notebook

</div>

<div style="padding: 2rem; background: linear-gradient(135deg, #ff9a9e15 0%, #fecfef15 100%); border-radius: 12px; border-left: 4px solid #ff9a9e;">

### 🎨 Beautiful Design

- **Light & Dark themes** - Choose your preferred appearance
- **Warm aesthetics** - Paper-like design for comfortable reading
- **Clean interface** - Focus on your content
- **Cross-platform consistency** - Same experience everywhere

</div>

</div>

---

## Security Features

<div style="background: linear-gradient(135deg, #667eea15 0%, #764ba215 100%); padding: 2rem; border-radius: 12px; margin: 2rem 0;">

### 🔐 Auto-Lock

Automatically lock workspaces after inactivity to protect your data:

<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin-top: 1rem;">
  <div style="background: white; padding: 1rem; border-radius: 8px;">
    <strong>⏱️ Configurable timeout</strong>
    <p style="margin: 0.5rem 0 0 0; color: #476582; font-size: 0.9rem;">5, 15, 30 minutes, or custom</p>
  </div>
  <div style="background: white; padding: 1rem; border-radius: 8px;">
    <strong>🧹 Memory clearing</strong>
    <p style="margin: 0.5rem 0 0 0; color: #476582; font-size: 0.9rem;">All keys removed from RAM</p>
  </div>
  <div style="background: white; padding: 1rem; border-radius: 8px;">
    <strong>🔒 Instant lock</strong>
    <p style="margin: 0.5rem 0 0 0; color: #476582; font-size: 0.9rem;">Manual lock button available</p>
  </div>
  <div style="background: white; padding: 1rem; border-radius: 8px;">
    <strong>🚪 Lock on close</strong>
    <p style="margin: 0.5rem 0 0 0; color: #476582; font-size: 0.9rem;">Option to lock when app closes</p>
  </div>
</div>

### 🔑 Advanced Key Management

- **Argon2id KDF** - Memory-hard password hashing resistant to GPU attacks
- **HKDF** - Secure key derivation for multiple encryption keys
- **Per-note keys** - Each note has unique encryption keys
- **Key rotation** - Change workspace password anytime with automatic re-encryption

### 🛡️ Threat Protection

- **No telemetry** - Zero analytics or tracking
- **Local logging only** - Logs never leave your device
- **Memory protection** - Sensitive data cleared after use
- **Screenshot protection** - Optional (mobile platforms)

[View our threat model →](/security/threat-model)

</div>

---

## Platform Support

<div style="overflow-x: auto; margin: 2rem 0;">

| Feature | Desktop | Mobile | Web |
|---------|:-------:|:------:|:---:|
| Core encryption | ✅ | ✅ | ✅ |
| Offline mode | ✅ | ✅ | ⚠️ Limited |
| Multi-workspace | ✅ | ✅ | ✅ |
| Rich text editor | ✅ | ✅ | ✅ |
| Auto-lock | ✅ | ✅ | ✅ |
| Biometric unlock | ❌ | ✅ | ❌ |

</div>

---

## Coming Soon

We're actively working on these features:

<div style="display: grid; grid-template-columns: 1fr 1fr; gap: 2rem; margin: 2rem 0;">

<div style="padding: 1.5rem; background: linear-gradient(135deg, #667eea15 0%, #764ba215 100%); border-radius: 12px;">

### 🚀 In Active Development

- **Tags UI** - Visual tag management and organization
- **Search** - Full-text encrypted search across all notes
- **End-to-end encrypted sync** - Sync across devices with zero-knowledge
- **Mobile apps** - iOS and Android releases
- **Biometric unlock** - Face ID, Touch ID, Fingerprint

</div>

<div style="padding: 1.5rem; background: linear-gradient(135deg, #f093fb15 0%, #f5576c15 100%); border-radius: 12px;">

### 🔮 On the Roadmap

- **Browser extension** - Quick capture from web
- **Collaborative editing** - Share notes securely (E2E encrypted)
- **File attachments** - Encrypted PDFs, images, documents
- **Note templates** - Reusable note structures
- **Voice notes** - Encrypted voice recordings
- **Post-quantum crypto** - Future-proof encryption

</div>

</div>

---

## Learn More

<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1.5rem; margin: 2rem 0;">
  <a href="/guide/getting-started" style="display: block; padding: 1.5rem; background: #f8f9fa; border-radius: 8px; border-left: 3px solid #667eea; text-decoration: none; color: inherit;">
    <strong style="color: #2c3e50;">🚀 Getting Started</strong>
    <p style="margin: 0.5rem 0 0 0; color: #476582;">Create your first workspace</p>
  </a>
  <a href="/security/encryption" style="display: block; padding: 1.5rem; background: #f8f9fa; border-radius: 8px; border-left: 3px solid #4facfe; text-decoration: none; color: inherit;">
    <strong style="color: #2c3e50;">🔐 Security Details</strong>
    <p style="margin: 0.5rem 0 0 0; color: #476582;">How your data is protected</p>
  </a>
  <a href="/security/threat-model" style="display: block; padding: 1.5rem; background: #f8f9fa; border-radius: 8px; border-left: 3px solid #f093fb; text-decoration: none; color: inherit;">
    <strong style="color: #2c3e50;">🛡️ Threat Model</strong>
    <p style="margin: 0.5rem 0 0 0; color: #476582;">What we protect against</p>
  </a>
</div>
