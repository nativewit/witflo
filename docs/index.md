---
layout: home

hero:
  name: "Witflo"
  text: "Zero-Trust Encrypted Notes"
  tagline: Safe space for your thoughts to flow
  image:
    src: /logo.svg
    alt: Witflo
  actions:
    - theme: brand
      text: Launch App
      link: https://app.witflo.com
    - theme: alt
      text: Get Started
      link: /guide/getting-started
    - theme: alt
      text: View on GitHub
      link: https://github.com/nativewit/witflo

features:
  - icon: 🔒
    title: Zero-Trust Encryption
    details: All crypto happens client-side with libsodium. Your data is encrypted before it touches the disk.
  
  - icon: 📴
    title: Offline-First
    details: Works fully without internet. Your notes are always accessible, sync when you're ready.
  
  - icon: 🗂️
    title: Multi-Workspace
    details: Isolated encrypted containers for different contexts. Keep work, personal, and projects separate.
  
  - icon: ✍️
    title: Rich Text Editor
    details: Quill-based editor with markdown support. Write naturally, export easily.
  
  - icon: 🎨
    title: Beautiful Design
    details: Dark and light themes with a warm paper aesthetic. Designed for focus.
  
  - icon: 🌍
    title: Cross-Platform
    details: Built with Flutter for iOS, Android, macOS, Linux, Windows, and Web.

---

<div style="max-width: 1200px; margin: 2rem auto 3rem auto; padding: 0 1.5rem;">

::: warning Initial Preview Release
Witflo is currently in **initial preview** for early adopters to try. Core features are working (encrypted notes, notebooks, workspaces), but many features are still in development. We're actively building tags, search, sync, and more. [See what's coming →](#what-s-coming)
:::

</div>

<div style="max-width: 1200px; margin: 3rem auto; padding: 0 1.5rem;">

## Why Witflo?

<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 2rem; margin: 3rem 0;">
  <div style="padding: 2rem; background: linear-gradient(135deg, #667eea15 0%, #764ba215 100%); border-radius: 12px; border-left: 4px solid #667eea;">
    <h3 style="margin-top: 0; color: #6b7280;">🔐 Military-Grade Security</h3>
    <p style="color: #9ca3af; line-height: 1.7;">Your notes are protected by zero-trust encryption. Every note is encrypted with unique keys before touching the disk. Your password never leaves your device.</p>
    <a href="/security/encryption" style="color: #667eea; font-weight: 600; text-decoration: none;">How It Works →</a>
  </div>
  
  <div style="padding: 2rem; background: linear-gradient(135deg, #f093fb15 0%, #f5576c15 100%); border-radius: 12px; border-left: 4px solid #f093fb;">
    <h3 style="margin-top: 0; color: #6b7280;">🛡️ True Privacy</h3>
    <p style="color: #9ca3af; line-height: 1.7;">Zero analytics, zero tracking, zero telemetry. We don't collect anything. Your data is yours, encrypted and stored locally on your device.</p>
    <a href="/security/privacy" style="color: #f093fb; font-weight: 600; text-decoration: none;">Privacy Guarantees →</a>
  </div>
  
  <div style="padding: 2rem; background: linear-gradient(135deg, #4facfe15 0%, #00f2fe15 100%); border-radius: 12px; border-left: 4px solid #4facfe;">
    <h3 style="margin-top: 0; color: #6b7280;">🔍 Secure by Design</h3>
    <p style="color: #9ca3af; line-height: 1.7;">Built with security at every level. From memory safety to auto-lock, military-grade encryption protects your notes from unauthorized access.</p>
    <a href="/security/encryption" style="color: #4facfe; font-weight: 600; text-decoration: none;">Learn About Encryption →</a>
  </div>
  
  <div style="padding: 2rem; background: linear-gradient(135deg, #ffecd215 0%, #fcb69f15 100%); border-radius: 12px; border-left: 4px solid #ffecd2;">
    <h3 style="margin-top: 0; color: #6b7280;">🤖 AI-Proof by Design</h3>
    <p style="color: #9ca3af; line-height: 1.7;">Your notes never become training data. With zero-knowledge encryption, your thoughts are encrypted before leaving your device. AI models, cloud providers, and third parties can't read what they can't decrypt.</p>
    <a href="/security/privacy" style="color: #ffecd2; font-weight: 600; text-decoration: none;">Privacy Guarantees →</a>
  </div>
</div>

---

## Your Thoughts Deserve Privacy

<div style="line-height: 1.8; color: #9ca3af; max-width: 800px; margin: 2rem auto;">

We live in an age where:
- **AI models are trained on user data** from cloud services
- **Data breaches expose millions** of accounts every year  
- **Your notes can become ad targeting data**, AI training material, or worse

Your journal entries, business ideas, therapy notes, personal thoughts — they all deserve a space that's **truly private**.

**Witflo gives you that space:**

<div style="margin: 2rem 0;">

✅ **Zero-knowledge encryption** — Your notes are encrypted on your device with keys only you have  
✅ **Offline-first** — Works completely without internet. No cloud required  
✅ **No account needed** — No email, no login, no tracking, no profiling  
✅ **Open source** — Don't trust us? Audit the code yourself

</div>

<div style="text-align: center; padding: 1.5rem; background: linear-gradient(135deg, #667eea15 0%, #764ba215 100%); border-radius: 12px; border-left: 4px solid #667eea; margin-top: 2rem;">
  <p style="margin: 0; font-weight: 600; color: #6b7280;">Your thoughts stay yours. Not training data. Not in a data breach. Not on someone's server.</p>
</div>

</div>

### How Witflo Compares

<div style="overflow-x: auto; margin: 3rem 0;">

| Feature | Witflo | Evernote | Notion | Apple Notes |
|---------|:------:|:--------:|:------:|:-----------:|
| **End-to-end encryption** | ✅ Yes | ❌ No | ❌ No | ⚠️ Partial |
| **Zero-knowledge** | ✅ Yes | ❌ No | ❌ No | ⚠️ Partial |
| **Safe from AI training** | ✅ Yes | ❌ No | ❌ No | ⚠️ Unknown |
| **Works offline** | ✅ Yes | ⚠️ Limited | ⚠️ Limited | ✅ Yes |
| **No analytics/tracking** | ✅ None | ❌ Yes | ❌ Yes | ⚠️ Limited |
| **Open source** | ✅ Yes | ❌ No | ❌ No | ❌ No |

</div>

<div style="margin: 1rem 0; padding: 1rem; background: linear-gradient(135deg, #4facfe15 0%, #00f2fe15 100%); border-radius: 8px;">
  <p style="margin: 0; font-size: 0.9rem; color: #9ca3af;">
    <strong>Legend:</strong> ✅ Yes (fully supported) • ⚠️ Partial (limited or opt-in) • ❌ No (not available)
  </p>
</div>

---

## What's Coming

<div style="display: grid; grid-template-columns: 1fr 1fr; gap: 2rem; margin: 2rem 0;">
  <div>
    <h3 style="color: #6b7280;">🚀 Coming Soon</h3>
    <ul style="line-height: 2; color: #9ca3af;">
      <li><strong>End-to-end encrypted sync</strong> - Sync across devices with zero-knowledge</li>
      <li><strong>Mobile apps</strong> - iOS and Android (in beta)</li>
      <li><strong>Biometric unlock</strong> - Face ID, Touch ID, Fingerprint</li>
      <li><strong>Browser extension</strong> - Quick capture from web</li>
    </ul>
  </div>
  
  <div>
    <h3 style="color: #6b7280;">🔮 On the Roadmap</h3>
    <ul style="line-height: 2; color: #9ca3af;">
      <li><strong>Collaborative editing</strong> - Share notes securely (E2E encrypted)</li>
      <li><strong>File attachments</strong> - Encrypted PDFs, images, documents</li>
      <li><strong>Note templates</strong> - Reusable note structures</li>
      <li><strong>Post-quantum crypto</strong> - Future-proof encryption</li>
    </ul>
  </div>
</div>

<div style="background: linear-gradient(135deg, #ffecd215 0%, #fcb69f15 100%); padding: 1.5rem; border-radius: 12px; border-left: 4px solid #ffecd2; margin: 2rem 0;">
  <p style="margin: 0; color: #9ca3af;">💡 <strong>Building the future:</strong> We're actively developing new features based on user feedback and privacy-first principles.</p>
</div>

---

<div style="text-align: center; margin: 4rem 0;">
  <h2 style="font-size: 2rem; margin-bottom: 1rem; color: #6b7280;">Ready to Take Control of Your Notes?</h2>
  <p style="font-size: 1.1rem; color: #9ca3af; margin-bottom: 2rem;">Download Witflo today and experience truly private note-taking.</p>
  
  <a href="https://app.witflo.com" style="display: inline-block; padding: 16px 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-decoration: none; border-radius: 12px; font-weight: 700; font-size: 1.1rem; box-shadow: 0 8px 20px rgba(102, 126, 234, 0.4); transition: transform 0.2s ease, box-shadow 0.2s ease;">
    Launch Witflo
  </a>
  
  <p style="margin-top: 1.5rem; color: #888;">
    Or <a href="/guide/installation" style="color: #667eea; font-weight: 600;">view the installation guide</a> for detailed instructions
  </p>
</div>

</div>
