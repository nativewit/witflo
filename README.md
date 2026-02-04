# Witflo Platform

A zero-trust, privacy-first, offline-first notes and LifeOS platform.

## Repository Structure

This is a monorepo containing multiple packages:

```
witflo-platform/
├── witflo/              # Flutter app (iOS, Android, macOS, Linux, Windows, Web)
│   ├── lib/            # Dart source code
│   ├── android/        # Android platform code
│   ├── ios/            # iOS platform code
│   ├── macos/          # macOS platform code
│   ├── linux/          # Linux platform code
│   ├── windows/        # Windows platform code
│   ├── web/            # Web platform code
│   ├── test/           # Tests
│   └── docs/           # Product documentation
└── README.md           # This file
```

## Packages

### witflo/ - Flutter App

The main Witflo application built with Flutter. Supports all platforms.

```bash
cd witflo
fvm flutter pub get
fvm flutter run
```

See [witflo/README.md](witflo/README.md) for more details.

## Development

### For AI Agents

**📖 Start Here:** [`docs/README.md`](docs/README.md) - Complete documentation index

**Quick Links:**
- **Connect to running app:** [`docs/flutter-ai-agent-guide.md`](docs/flutter-ai-agent-guide.md)
- **Coding patterns:** [`.opencode/skills/flutter-patterns/SKILL.md`](.opencode/skills/flutter-patterns/SKILL.md)
- **MCP Quick Reference:** [`docs/flutter-ai-mcp-reference.md`](docs/flutter-ai-mcp-reference.md)

**AI-First Development Features:**
- ✅ Marionette MCP for runtime UI testing
- ✅ Screenshot capture (1600x1200 PNG)
- ✅ Interactive element inspection
- ✅ UI interaction simulation (tap, scroll, text)
- ✅ Application log monitoring

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) (3.38.7+)
- [FVM](https://fvm.app/) - Flutter Version Management (**required**)
- Xcode (for iOS/macOS)
- Android Studio (for Android)
- Marionette MCP (for AI development) - auto-installed via `dart pub global activate marionette_mcp`

### Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/witflo-platform.git
cd witflo-platform

# Navigate to the Flutter app
cd witflo

# Install FVM and set Flutter version
fvm install
fvm use

# Get dependencies
fvm flutter pub get

# Run the app
fvm flutter run
```

## Architecture

Witflo follows a zero-trust security model:

- **Client-side encryption**: All data is encrypted on-device before storage or sync
- **No server trust**: Servers only see ciphertext
- **Local-first**: Works fully offline
- **Key hierarchy**: Password → MUK → VaultKey → ContentKeys

See [witflo/docs/PRODUCT.md](witflo/docs/PRODUCT.md) for detailed architecture documentation.

## Future Packages

This monorepo is structured to accommodate future packages:

- `witflo-server/` - Optional sync server (stores only ciphertext)
- `witflo-cli/` - Command-line tools
- `witflo-web/` - Web-only lightweight client
- `packages/` - Shared Dart packages

## License

[Add your license here]
