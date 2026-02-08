# Getting Started

Welcome to Witflo! This guide will help you get started with your first encrypted workspace.

## What You'll Need

- A strong master password (you won't be able to recover your data without it!)
- 5 minutes of your time

## Installation

::: warning Important
Choose your master password carefully. This password cannot be recovered. If you forget it, your data cannot be decrypted.
:::

### Desktop (macOS, Linux, Windows)

Download the latest release from [GitHub Releases](https://github.com/nativewit/witflo/releases):

- **macOS**: Download `.dmg` file
- **Linux**: Download `.AppImage` or `.deb` package
- **Windows**: Download `.exe` installer

### Mobile (iOS, Android)

- **iOS**: Download from App Store (coming soon)
- **Android**: Download from Google Play or F-Droid (coming soon)

### Build from Source

```bash
# Clone the repository
git clone https://github.com/nativewit/witflo.git
cd witflo/witflo

# Install dependencies (requires FVM)
fvm install && fvm use
fvm flutter pub get

# Run on your platform
fvm flutter run
```

## First Launch

When you first launch Witflo, you'll be greeted with the onboarding flow.

### Step 1: Choose Workspace Location

First, select where you want to store your encrypted workspace data.

![Workspace Location](/screenshots/01-onboarding-welcome-workspace-location.png)

### Step 2: Create Master Password

Set up your master password - this is the key to all your encrypted data. Make it strong and memorable!

![Create Master Password](/screenshots/04-onboarding-create-master-password.png)

### Creating Your First Workspace

1. **Choose a workspace name** - e.g., "Personal", "Work", "Projects"
2. **Set a master password** - Make it strong and memorable
3. **Confirm your password** - Type it again to confirm
4. **Create workspace** - Your encrypted workspace is ready!

![Create First Vault](/screenshots/05-onboarding-create-first-vault.png)

![Vault Form Filled](/screenshots/06-onboarding-create-vault-filled.png)

::: tip Password Tips
- Use a passphrase: "correct horse battery staple"
- Use a password manager to generate and store it
- Minimum 12 characters recommended
- Mix letters, numbers, and symbols
:::

## Creating Your First Note

Once your workspace is created, you'll see the main app interface.

![Empty Vault View](/screenshots/07-main-app-empty-vault-view.png)

### Create a Notebook (Optional)

Before creating notes, you can organize them into notebooks:

1. Click the **"Create Notebook"** button
2. Give your notebook a name
3. Choose a color to visually distinguish it
4. Click **"Create"**

![Create Notebook](/screenshots/08-create-notebook-dialog.png)

![Notebook Form Filled](/screenshots/09-create-notebook-dialog-filled.png)

### Write Your First Note

1. Click the **"New Note"** button (+ icon)
2. Give your note a title
3. Start writing!
4. Your note is automatically encrypted and saved

![Empty Note Editor](/screenshots/13-note-editor-empty.png)

![Note with Title](/screenshots/14-note-editor-titled.png)

![Note with Content](/screenshots/15-note-editor-with-content.png)

## Understanding Workspaces

Witflo uses **workspaces** (also called vaults) to organize your notes into isolated, encrypted containers.

- Each workspace has its own master password
- Notes in one workspace cannot be accessed from another
- You can have unlimited workspaces

**Example use cases:**
- Personal workspace for private thoughts
- Work workspace for professional notes
- Project workspace for specific initiatives

## Auto-Lock Feature

For security, Witflo automatically locks your workspace after a period of inactivity.

![Unlock Workspace](/screenshots/18-unlock-workspace-screen.png)

- Default: 15 minutes
- Configurable in Settings
- All encryption keys are cleared from memory when locked

### Settings & Customization

Access the settings to customize your Witflo experience:

![Settings Overview](/screenshots/17-settings-overview.png)

## Next Steps

- Learn about [Features](/guide/features) to discover what Witflo can do
- Read about [Security](/security/encryption) to understand how your data is protected
- Check the [FAQ](/guide/faq) for common questions

::: info Need Help?
If you encounter any issues, please [open an issue on GitHub](https://github.com/nativewit/witflo/issues).
:::
