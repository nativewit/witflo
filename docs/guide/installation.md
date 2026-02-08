# Installation

Get Witflo up and running on your device in minutes.

## System Requirements

<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1rem; margin: 2rem 0;">
  <div style="padding: 1.5rem; background: #f8f9fa; border-radius: 8px; border-left: 3px solid #667eea;">
    <strong style="color: #2c3e50;">🍎 macOS</strong>
    <p style="margin: 0.5rem 0 0 0; color: #476582;">macOS 10.15 (Catalina) or later</p>
  </div>
  <div style="padding: 1.5rem; background: #f8f9fa; border-radius: 8px; border-left: 3px solid #667eea;">
    <strong style="color: #2c3e50;">🪟 Windows</strong>
    <p style="margin: 0.5rem 0 0 0; color: #476582;">Windows 10 or later</p>
  </div>
  <div style="padding: 1.5rem; background: #f8f9fa; border-radius: 8px; border-left: 3px solid #667eea;">
    <strong style="color: #2c3e50;">🐧 Linux</strong>
    <p style="margin: 0.5rem 0 0 0; color: #476582;">Modern distribution (X11/Wayland)</p>
  </div>
  <div style="padding: 1.5rem; background: #f8f9fa; border-radius: 8px; border-left: 3px solid #667eea;">
    <strong style="color: #2c3e50;">📱 iOS</strong>
    <p style="margin: 0.5rem 0 0 0; color: #476582;">iOS 13.0 or later</p>
  </div>
  <div style="padding: 1.5rem; background: #f8f9fa; border-radius: 8px; border-left: 3px solid #667eea;">
    <strong style="color: #2c3e50;">🤖 Android</strong>
    <p style="margin: 0.5rem 0 0 0; color: #476582;">Android 5.0 (API 21) or later</p>
  </div>
</div>

---

## Download & Install

### Desktop Applications

<div style="margin: 2rem 0;">

#### macOS
1. Download the latest `.dmg` from [GitHub Releases](https://github.com/nativewit/witflo/releases/latest)
2. Open the DMG file
3. Drag Witflo to your Applications folder
4. Launch from Applications

::: warning First Launch
macOS may show a security warning since the app is not yet notarized. Right-click the app and select "Open", then click "Open" in the dialog.
:::

#### Windows
1. Download `Witflo-Setup.exe` from [GitHub Releases](https://github.com/nativewit/witflo/releases/latest)
2. Run the installer
3. Follow the installation wizard
4. Launch from Start Menu or Desktop

::: warning Windows Defender
Windows Defender may show a warning since the app is not signed. Click "More info" → "Run anyway" to proceed.
:::

#### Linux

**Ubuntu/Debian (.deb)**
```bash
wget https://github.com/nativewit/witflo/releases/latest/download/witflo.deb
sudo dpkg -i witflo.deb
```

**Universal (AppImage)**
```bash
wget https://github.com/nativewit/witflo/releases/latest/download/Witflo.AppImage
chmod +x Witflo.AppImage
./Witflo.AppImage
```

**Required dependencies:**
```bash
sudo apt-get install libsecret-1-dev libsodium-dev
```

</div>

### Mobile Applications

::: info Coming Soon
- **iOS**: App Store release planned
- **Android**: Google Play and F-Droid releases planned

Mobile apps are currently in beta. Check [GitHub Releases](https://github.com/nativewit/witflo/releases) for beta builds.
:::

---

## Build from Source

Want to build Witflo yourself? Here's how.

### Prerequisites

<div style="background: linear-gradient(135deg, #667eea15 0%, #764ba215 100%); padding: 1.5rem; border-radius: 8px; margin: 1.5rem 0;">

**Required:**
- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.38+
- [FVM](https://fvm.app/) (recommended for version management)
- Git

**Platform-specific:**
- **macOS/iOS**: Xcode 14+
- **Android**: Android Studio with SDK
- **Linux**: Build essentials, GTK 3.0
- **Windows**: Visual Studio 2019+

</div>

### Clone & Setup

```bash
# Clone repository
git clone https://github.com/nativewit/witflo.git
cd witflo/witflo

# Install Flutter version with FVM
fvm install
fvm use

# Get dependencies
fvm flutter pub get
```

### Run Development Build

```bash
# macOS
fvm flutter run -d macos

# Linux
fvm flutter run -d linux

# Windows
fvm flutter run -d windows

# iOS (requires Mac + Xcode)
fvm flutter run -d ios

# Android
fvm flutter run -d android

# Web
fvm flutter run -d chrome
```

### Build Release

```bash
# macOS
fvm flutter build macos --release

# Linux
fvm flutter build linux --release

# Windows
fvm flutter build windows --release

# iOS
fvm flutter build ios --release

# Android APK
fvm flutter build apk --release

# Android App Bundle
fvm flutter build appbundle --release

# Web
fvm flutter build web --release
```

---

## Troubleshooting

<div style="margin: 2rem 0;">

### macOS: "App is damaged"

```bash
xattr -cr /Applications/Witflo.app
```

### Linux: Missing Libraries

```bash
sudo apt-get install -f
```

### Build Fails

1. Check Flutter version: `flutter --version`
2. Run diagnostics: `flutter doctor`
3. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### Still Having Issues?

[Report an issue on GitHub](https://github.com/nativewit/witflo/issues) with:
- Your OS and version
- Flutter version (`flutter --version`)
- Error logs
- Steps to reproduce

</div>

---

## Next Steps

<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1.5rem; margin: 2rem 0;">
  <a href="/guide/getting-started" style="display: block; padding: 1.5rem; background: linear-gradient(135deg, #667eea15 0%, #764ba215 100%); border-radius: 8px; border-left: 3px solid #667eea; text-decoration: none; color: inherit;">
    <strong style="color: #2c3e50;">🚀 Getting Started</strong>
    <p style="margin: 0.5rem 0 0 0; color: #476582;">Create your first encrypted workspace</p>
  </a>
  <a href="/guide/features" style="display: block; padding: 1.5rem; background: linear-gradient(135deg, #f093fb15 0%, #f5576c15 100%); border-radius: 8px; border-left: 3px solid #f093fb; text-decoration: none; color: inherit;">
    <strong style="color: #2c3e50;">✨ Features</strong>
    <p style="margin: 0.5rem 0 0 0; color: #476582;">Discover what Witflo can do</p>
  </a>
  <a href="/security/encryption" style="display: block; padding: 1.5rem; background: linear-gradient(135deg, #4facfe15 0%, #00f2fe15 100%); border-radius: 8px; border-left: 3px solid #4facfe; text-decoration: none; color: inherit;">
    <strong style="color: #2c3e50;">🔐 Security</strong>
    <p style="margin: 0.5rem 0 0 0; color: #476582;">Understand how your data is protected</p>
  </a>
</div>
