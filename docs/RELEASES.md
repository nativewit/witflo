# Creating Releases for Witflo

This guide explains how to create and publish releases for the Witflo app.

## Release Workflow Overview

The release workflow (`.github/workflows/release.yml`) automatically:
- ✅ Builds the app for **all platforms** (macOS, Linux, Windows, Web, Android, iOS)
- ✅ Creates platform-specific packages (DMG, tar.gz, ZIP, APK)
- ✅ Creates a **GitHub Release** with all downloads
- ✅ Generates release notes automatically

## How to Create a Release

### Method 1: Using Git Tags (Recommended)

**Step 1: Update version in pubspec.yaml**
```bash
cd witflo
# Edit pubspec.yaml and update version: 0.1.0+1 to your new version
```

**Step 2: Commit and create a tag**
```bash
git add witflo/pubspec.yaml
git commit -m "Bump version to 0.1.0"
git tag v0.1.0
git push origin main
git push origin v0.1.0
```

**Step 3: Wait for builds**
- The workflow automatically triggers when you push a tag starting with `v`
- Go to **Actions** tab to watch the progress
- All 7 builds run in parallel (takes ~15-20 minutes)

**Step 4: Release is created**
- Once all builds complete, the release is created automatically
- Find it at: https://github.com/nativewit/witflo/releases

### Method 2: Manual Trigger

**Step 1: Go to Actions**
1. Visit: https://github.com/nativewit/witflo/actions
2. Click **Build and Release** workflow
3. Click **Run workflow**
4. Enter version (e.g., `0.1.0`)
5. Click **Run workflow**

**Step 2: Wait for completion**
- Workflow will build all platforms
- Creates release automatically

## What Gets Built

The workflow builds:

| Platform | File | Description |
|----------|------|-------------|
| **macOS** | `Witflo-macOS.dmg` | Universal binary (Intel + Apple Silicon) |
| **Linux** | `Witflo-Linux-x64.tar.gz` | 64-bit Linux |
| **Windows** | `Witflo-Windows-x64.zip` | 64-bit Windows |
| **Web** | `Witflo-Web.tar.gz` | Static web build |
| **Android** | `app-arm64-v8a-release.apk` | Modern Android devices (64-bit) |
| **Android** | `app-armeabi-v7a-release.apk` | Older Android devices (32-bit) |
| **Android** | `app-x86_64-release.apk` | Android emulators |
| **iOS** | `Witflo-iOS.zip` | iOS build (unsigned) |

## Download Button

The homepage already links to:
```
https://github.com/nativewit/witflo/releases/latest
```

This automatically redirects to the **latest release**, so users always get the newest version!

## Release Notes

Each release includes:
- Version number
- Platform-specific download links
- Installation instructions link
- What's new section
- Known issues
- Full changelog

You can edit the release notes after creation:
1. Go to the release page
2. Click **Edit release**
3. Update the description
4. Click **Update release**

## Version Numbering

Follow Semantic Versioning (semver):
- **Major.Minor.Patch+Build**
- Example: `0.1.0+1`
  - `0` = Major version (breaking changes)
  - `1` = Minor version (new features)
  - `0` = Patch version (bug fixes)
  - `1` = Build number (increases with each build)

**For preview releases:**
- `0.1.0` = First preview
- `0.2.0` = Second preview with new features
- `0.2.1` = Bug fix for preview 2
- `1.0.0` = First stable release

## Pre-release vs Stable

Currently, releases are marked as **pre-release** (see `prerelease: true` in workflow).

When ready for stable:
1. Edit `.github/workflows/release.yml`
2. Change `prerelease: true` to `prerelease: false`
3. Commit and push

## Customizing Release Notes

To customize the release notes template:

Edit `.github/workflows/release.yml` and update the `body:` section:

```yaml
body: |
  ## Your custom release notes here
  
  ### Downloads
  Choose your platform...
```

## Code Signing (Future)

Currently, builds are **unsigned**:
- macOS: Users need to right-click → Open
- Windows: Users need to allow unsigned app
- iOS: Requires Xcode to install
- Android: Users need to enable "Install from unknown sources"

**To add code signing:**
1. Get certificates/keys for each platform
2. Add as GitHub Secrets
3. Update workflows to use signing

## Troubleshooting

### Build Fails on a Platform

If one platform fails:
1. Check the **Actions** tab
2. Click on the failed job
3. Read the error logs
4. Fix the issue
5. Re-run the workflow or create a new tag

### Release Not Created

If builds succeed but release not created:
- Check the `create-release` job in Actions
- Verify GitHub token has write permissions
- Go to **Settings** → **Actions** → **General**
- Set **Workflow permissions** to "Read and write"

### Wrong Files in Release

If wrong files are uploaded:
- Check artifact paths in workflow
- Verify build output locations
- Update file paths in the `files:` section

## Next Steps

**To create your first release:**

1. Update version:
   ```bash
   cd witflo
   # Edit pubspec.yaml: version: 0.1.0+1
   ```

2. Commit and tag:
   ```bash
   git add witflo/pubspec.yaml
   git commit -m "Release v0.1.0 - Initial preview"
   git tag v0.1.0
   git push origin main
   git push origin v0.1.0
   ```

3. Watch it build:
   - Go to https://github.com/nativewit/witflo/actions
   - Wait ~15-20 minutes

4. Share the release:
   - https://github.com/nativewit/witflo/releases/latest

Your download button will automatically point to the latest release! 🎉
