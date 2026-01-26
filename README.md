# Fyndo Platform

A zero-trust, privacy-first, offline-first notes and LifeOS platform.

## Repository Structure

This is a monorepo containing multiple packages:

```
fyndo-platform/
├── fyndo/              # Flutter app (iOS, Android, macOS, Linux, Windows, Web)
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

### fyndo/ - Flutter App

The main Fyndo application built with Flutter. Supports all platforms.

```bash
cd fyndo
fvm flutter pub get
fvm flutter run
```

See [fyndo/README.md](fyndo/README.md) for more details.

## Development

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) (3.38.7+)
- [FVM](https://fvm.app/) - Flutter Version Management (recommended)
- Xcode (for iOS/macOS)
- Android Studio (for Android)

### Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/fyndo-platform.git
cd fyndo-platform

# Navigate to the Flutter app
cd fyndo

# Install FVM and set Flutter version
fvm install
fvm use

# Get dependencies
fvm flutter pub get

# Run the app
fvm flutter run
```

## Architecture

Fyndo follows a zero-trust security model:

- **Client-side encryption**: All data is encrypted on-device before storage or sync
- **No server trust**: Servers only see ciphertext
- **Local-first**: Works fully offline
- **Key hierarchy**: Password → MUK → VaultKey → ContentKeys

See [fyndo/docs/PRODUCT.md](fyndo/docs/PRODUCT.md) for detailed architecture documentation.

## Future Packages

This monorepo is structured to accommodate future packages:

- `fyndo-server/` - Optional sync server (stores only ciphertext)
- `fyndo-cli/` - Command-line tools
- `fyndo-web/` - Web-only lightweight client
- `packages/` - Shared Dart packages

## License

[Add your license here]
