# Frequently Asked Questions

Got questions? We've got answers.

## 🌟 General

<details>
<summary>What is Witflo?</summary>

Witflo is a zero-trust, privacy-first, offline-first encrypted note-taking application. It's designed for people who care about their privacy and want complete control over their data.

</details>

<details>
<summary>Is Witflo really free?</summary>

Yes! Witflo is free and open-source software licensed under AGPL-3.0. You can use it and modify it without paying anything.

</details>

<details>
<summary>What platforms does Witflo support?</summary>

Witflo runs on:
- 🍎 macOS (10.15+)
- 🐧 Linux (all major distros)
- 🪟 Windows (10+)
- 📱 iOS - Coming soon
- 🤖 Android - Coming soon
- 🌐 Web browsers

</details>
## 🔒 Security

<details>
<summary>How secure is Witflo?</summary>

Witflo uses military-grade encryption:
- **Argon2id** for password hashing (memory-hard KDF)
- **XChaCha20-Poly1305** for authenticated encryption
- **HKDF** for key derivation
- **libsodium** as the cryptographic foundation

All encryption happens client-side. Your password never leaves your device.

[Learn more about our encryption →](/security/encryption)

</details>

<details>
<summary>What if I forget my master password?</summary>

::: danger Cannot Be Recovered
Your data **cannot be recovered** if you forget your password. This is by design—there are no backdoors, password resets, or recovery mechanisms.
:::

**We recommend:**
- Use a strong, memorable passphrase
- Store it in a password manager
- Export regular encrypted backups

</details>

<details>
<summary>Can the developers access my notes?</summary>

**Absolutely not.** We never see your data. All encryption happens on your device before anything touches the disk. Even if you use sync (when available), the server only sees encrypted ciphertext.

This is the core principle of **zero-knowledge architecture**.

</details>

<details>
<summary>Is my data safe if my device is stolen?</summary>

Yes. Without your master password, your notes are just random encrypted bytes. Even with physical access to your device and unlimited computing power, an attacker cannot decrypt your notes in any reasonable timeframe.

</details>

<details>
<summary>Can I change my master password?</summary>

Yes! You can change your workspace password anytime. Witflo will re-encrypt all notes with the new password. We recommend exporting a backup before changing passwords.

</details>

## 💡 Usage

<details>
<summary>How many workspaces can I create?</summary>

Unlimited! Create as many workspaces as you need for different contexts (personal, work, projects, etc.).

</details>

<details>
<summary>How many notes can I store?</summary>

There's no artificial limit. Storage is only limited by your device's available disk space. Witflo has been tested with 10,000+ notes.

</details>

<details>
<summary>Can I use Witflo without internet?</summary>

Yes! Witflo is **offline-first**. It works completely without internet. Sync (when available) is optional.

</details>

<details>
<summary>How do I backup my notes?</summary>

Export your workspace:
1. Open **Settings** → **Export Workspace**
2. Choose format (encrypted JSON recommended)
3. Save to a secure location

::: tip Backup Regularly
We recommend regular backups, especially before:
- Changing your master password
- Major updates
- Switching devices
:::

</details>

<details>
<summary>Can I sync across devices?</summary>

End-to-end encrypted sync is planned but not yet available. For now, you can:
- Export/import workspaces manually
- Use file sync services (Syncthing, etc.) with the encrypted workspace files

</details>

## 🔐 Privacy

<details>
<summary>Does Witflo collect any data?</summary>

**No.** Witflo does not collect:
- ❌ Analytics
- ❌ Telemetry
- ❌ Usage statistics
- ❌ Error reports
- ❌ Personal information

The only network activity is sync (when enabled and it's E2E encrypted).

[Read our privacy policy →](/security/privacy)

</details>

<details>
<summary>Are there any trackers?</summary>

No. Zero trackers. No ads. No analytics. No telemetry. Nothing.

</details>

<details>
<summary>What about crash reports?</summary>

Crash logs are stored **locally only**. They never leave your device unless you manually choose to share them when reporting a bug.

</details>

## 🔧 Technical

<details>
<summary>Where is data stored?</summary>

Data is stored locally on your device:
- **macOS**: `~/Library/Application Support/witflo/`
- **Linux**: `~/.local/share/witflo/`
- **Windows**: `%APPDATA%/witflo/`
- **iOS**: App sandbox (iCloud not used)
- **Android**: App-private storage

All files are encrypted blobs. Without your password, they're completely useless.

</details>

<details>
<summary>Why Flutter?</summary>

Flutter allows us to:
- Build for all platforms from one codebase
- Maintain consistent UX across platforms
- Deliver performant, native-like apps
- Iterate quickly on features and fixes

</details>

<details>
<summary>Can I self-host the sync server?</summary>

When sync is released, yes! Self-hosting will be fully supported with documentation and Docker images.

</details>

<details>
<summary>How does the encryption work?</summary>

See our detailed [Encryption Architecture →](/security/encryption) for the technical deep dive.

</details>

<details>
<summary>Is the code audited?</summary>

The code is open-source and can be audited by anyone. We welcome security researchers to review the codebase.

A formal third-party security audit is planned for the v1.0 release.

</details>

## 🛠️ Troubleshooting

<details>
<summary>The app won't start</summary>

Try these steps:
1. Restart your device
2. Reinstall the app
3. Check [system requirements](/guide/installation#system-requirements)
4. Review error logs in the app data folder

</details>

<details>
<summary>I can't unlock my workspace</summary>

If you forgot your password, unfortunately **your data cannot be recovered**. This is a fundamental security feature.

If you're sure the password is correct, check:
- ✓ Typos or extra spaces
- ✓ Keyboard layout (US vs. international)
- ✓ Caps Lock status
- ✓ Try copy-pasting the password

</details>

<details>
<summary>Notes aren't saving</summary>

Check:
- Available disk space
- File permissions on the data folder
- Console logs for errors

</details>

<details>
<summary>Performance is slow</summary>

Try:
- Reduce number of notebooks and tags
- Lower auto-save frequency in settings
- Close other resource-intensive apps
- Restart Witflo

Note: Performance may degrade with >10,000 notes.

</details>

---

## Need More Help?

Browse our comprehensive documentation for detailed guides and information.

[📚 Browse Documentation →](/guide/getting-started)
