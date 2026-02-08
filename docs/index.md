---
layout: home

hero:
  name: "Witflo"
  text: "Zero-Trust Encrypted Notes"
  tagline: Save space for your thoughts to flow
  image:
    src: /logo.svg
    alt: Witflo
  actions:
    - theme: brand
      text: Download App
      link: https://github.com/nativewit/witflo/releases/latest
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
layout: home

hero:
  name: "Witflo"
  text: "Zero-Trust Encrypted Notes"
  tagline: Save space for your thoughts to flow
  image:
    src: /logo.svg
    alt: Witflo
  actions:
    - theme: brand
      text: Download App
      link: https://github.com/nativewit/witflo/releases/latest
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

<div style="max-width: 1200px; margin: 3rem auto; padding: 0 1.5rem;">

::: warning Initial Preview Release
Witflo is currently in **initial preview** for early adopters to try. Core features are working (encrypted notes, notebooks, workspaces), but many features are still in development. We're actively building tags, search, sync, and more. [See what's coming →](#whats-coming)
:::

## Why Witflo?

<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 2rem; margin: 3rem 0;">
  <div style="padding: 2rem; background: linear-gradient(135deg, #667eea15 0%, #764ba215 100%); border-radius: 12px; border-left: 4px solid #667eea;">
    <h3 style="margin-top: 0; color: #2c3e50;">🔐 Military-Grade Security</h3>
    <p style="color: #476582; line-height: 1.7;">Your notes are protected by zero-trust encryption. Every note is encrypted with unique keys before touching the disk. Your password never leaves your device.</p>
    <a href="/security/encryption" style="color: #667eea; font-weight: 600; text-decoration: none;">How It Works →</a>
  </div>
  
  <div style="padding: 2rem; background: linear-gradient(135deg, #f093fb15 0%, #f5576c15 100%); border-radius: 12px; border-left: 4px solid #f093fb;">
    <h3 style="margin-top: 0; color: #2c3e50;">🛡️ True Privacy</h3>
    <p style="color: #476582; line-height: 1.7;">Zero analytics, zero tracking, zero telemetry. We don't collect anything. Your data is yours, encrypted and stored locally on your device.</p>
    <a href="/security/privacy" style="color: #f093fb; font-weight: 600; text-decoration: none;">Privacy Guarantees →</a>
  </div>
  
  <div style="padding: 2rem; background: linear-gradient(135deg, #4facfe15 0%, #00f2fe15 100%); border-radius: 12px; border-left: 4px solid #4facfe;">
    <h3 style="margin-top: 0; color: #2c3e50;">🔍 Threat Protected</h3>
    <p style="color: #476582; line-height: 1.7;">Built to withstand real-world threats. From memory safety to auto-lock, we've analyzed and protected against common attack vectors.</p>
    <a href="/security/threat-model" style="color: #4facfe; font-weight: 600; text-decoration: none;">Threat Model →</a>
  </div>
</div>

---

## What's Coming

<div style="display: grid; grid-template-columns: 1fr 1fr; gap: 2rem; margin: 2rem 0;">
  <div>
    <h3 style="color: #2c3e50;">🚀 Coming Soon</h3>
    <ul style="line-height: 2; color: #476582;">
      <li><strong>End-to-end encrypted sync</strong> - Sync across devices with zero-knowledge</li>
      <li><strong>Mobile apps</strong> - iOS and Android (in beta)</li>
      <li><strong>Biometric unlock</strong> - Face ID, Touch ID, Fingerprint</li>
      <li><strong>Browser extension</strong> - Quick capture from web</li>
    </ul>
  </div>
  
  <div>
    <h3 style="color: #2c3e50;">🔮 On the Roadmap</h3>
    <ul style="line-height: 2; color: #476582;">
      <li><strong>Collaborative editing</strong> - Share notes securely (E2E encrypted)</li>
      <li><strong>File attachments</strong> - Encrypted PDFs, images, documents</li>
      <li><strong>Note templates</strong> - Reusable note structures</li>
      <li><strong>Post-quantum crypto</strong> - Future-proof encryption</li>
    </ul>
  </div>
</div>

<div style="background: linear-gradient(135deg, #ffecd215 0%, #fcb69f15 100%); padding: 1.5rem; border-radius: 12px; border-left: 4px solid #ffecd2; margin: 2rem 0;">
  <p style="margin: 0; color: #476582;">💡 <strong>Have an idea?</strong> <a href="https://github.com/nativewit/witflo/issues" style="color: #667eea; font-weight: 600;">Submit a feature request on GitHub</a></p>
</div>

---

## Open Source & Free Forever

<div style="text-align: center; margin: 3rem 0;">
  <p style="font-size: 1.2rem; color: #2c3e50; margin-bottom: 2rem;">Witflo is <strong>free and open source</strong> under the AGPL-3.0 license.</p>
  
  <div style="display: flex; justify-content: center; gap: 2rem; flex-wrap: wrap; margin: 2rem 0;">
    <a href="https://github.com/nativewit/witflo" style="display: inline-flex; align-items: center; gap: 0.5rem; padding: 12px 24px; background: #24292e; color: white; text-decoration: none; border-radius: 8px; font-weight: 600; transition: transform 0.2s ease;">
      <span>⭐</span> Star on GitHub
    </a>
    <a href="https://github.com/nativewit/witflo/issues" style="display: inline-flex; align-items: center; gap: 0.5rem; padding: 12px 24px; background: #f5f5f5; color: #2c3e50; text-decoration: none; border-radius: 8px; font-weight: 600; border: 2px solid #ddd; transition: transform 0.2s ease;">
      <span>🐛</span> Report Issues
    </a>
  </div>
</div>

---

<div style="text-align: center; margin: 4rem 0;">
  <h2 style="font-size: 2rem; margin-bottom: 1rem; color: #2c3e50;">Ready to Take Control of Your Notes?</h2>
  <p style="font-size: 1.1rem; color: #476582; margin-bottom: 2rem;">Download Witflo today and experience truly private note-taking.</p>
  
  <a href="https://github.com/nativewit/witflo/releases/latest" style="display: inline-block; padding: 16px 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-decoration: none; border-radius: 12px; font-weight: 700; font-size: 1.1rem; box-shadow: 0 8px 20px rgba(102, 126, 234, 0.4); transition: transform 0.2s ease, box-shadow 0.2s ease;">
    Download Witflo
  </a>
  
  <p style="margin-top: 1.5rem; color: #888;">
    Or <a href="/guide/installation" style="color: #667eea; font-weight: 600;">view the installation guide</a> for detailed instructions
  </p>
</div>

</div>
