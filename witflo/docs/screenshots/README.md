# Witflo Documentation Screenshots

This directory contains screenshots used in the documentation.

## Required Screenshots

### User Guide (README.md)

1. **create-vault.png** (800x600 recommended)
   - Shows the "Create New Vault" screen
   - Master password input field visible
   - Optional salt phrase field visible
   - "Create" button visible

2. **create-notebook.png** (800x600 recommended)
   - Shows the main screen with "+" button
   - Notebook creation dialog/screen
   - Name input field visible

3. **write-note.png** (800x600 recommended)
   - Shows a notebook open with notes list
   - "New Note" button or editor visible
   - Example note content (can be placeholder text)

### Developer Guide (CONTRIBUTING.md)

4. **dev-setup.png** (800x600 recommended)
   - Terminal showing successful `fvm flutter run`
   - OR IDE with project open
   - Shows the app running on a device/simulator

## Screenshot Guidelines

- **Resolution**: Minimum 800x600, preferably 1920x1080 for retina displays
- **Format**: PNG with transparency where appropriate
- **Content**: Use example/dummy data, no personal information
- **Theme**: Show the app in light mode (or both light/dark if desired)
- **Annotations**: Add arrows or highlights if needed to draw attention to key elements

## How to Capture Screenshots

### Mobile (iOS/Android)
```bash
# Run the app
fvm flutter run

# Take screenshot from simulator/emulator
# iOS Simulator: Cmd+S
# Android Emulator: Use emulator toolbar
```

### Desktop (macOS/Linux/Windows)
```bash
# Run the app
fvm flutter run -d macos  # or linux/windows

# Use system screenshot tool
# macOS: Cmd+Shift+4
# Linux: Screenshot utility
# Windows: Win+Shift+S
```

### Automated (using flutter driver)
```bash
# See MCP_TOOLS_TEST_REPORT.md for automated screenshot capture
```

## Naming Convention

- Use kebab-case: `feature-name.png`
- Be descriptive: `create-vault.png` not `screenshot1.png`
- Include state if multiple: `note-empty.png`, `note-editing.png`

## Adding New Screenshots

1. Capture screenshot following guidelines above
2. Save to this directory with appropriate name
3. Update relevant documentation (README.md, CONTRIBUTING.md, etc.)
4. Commit both screenshot and doc updates together

---

*Last updated: Feb 2026*
