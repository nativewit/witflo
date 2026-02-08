# Contributing to Witflo

Thank you for your interest in contributing to Witflo! We welcome contributions from everyone.

---

## 🚀 Quick Start

### 1. Set Up Your Environment

![Development Setup](../docs/screenshots/dev-setup.png)

```bash
# Fork and clone the repository
git clone https://github.com/YOUR-USERNAME/witflo-platform.git
cd witflo-platform/witflo

# Install Flutter via FVM (recommended)
dart pub global activate fvm
fvm install
fvm use

# Install dependencies
fvm flutter pub get

# Run the app
fvm flutter run
```

### 2. Run Tests

```bash
# Run all tests
fvm flutter test

# Run with coverage
fvm flutter test --coverage

# Format code
dart format .

# Analyze code
dart analyze
```

---

## 📁 Project Structure

```
witflo/
├── lib/
│   ├── core/              # Business logic & crypto
│   │   ├── crypto/        # Cryptographic primitives
│   │   ├── vault/         # Vault management
│   │   ├── identity/      # User & device identity
│   │   └── sync/          # Sync operations
│   ├── features/          # Feature modules
│   │   └── notes/         # Notes feature
│   ├── providers/         # Riverpod state management
│   └── ui/                # Flutter UI layer
└── test/                  # Unit & integration tests
```

---

## 🏗️ Architecture Principles

### 1. **File-based Storage**
All data stored as encrypted JSONL files for simplicity and portability.

### 2. **Zero-Knowledge Encryption**
All encryption happens client-side. Servers never see plaintext.

### 3. **Riverpod State Management**
Consistent state management pattern throughout the app.

### 4. **built_value Immutability**
Immutable data models with code generation.

---

## 🔒 Security Guidelines

**Critical Rules:**

1. ✅ **Use libsodium primitives only** - No custom crypto implementations
2. ✅ **Document key lifecycle** - Creation, use, and disposal must be explicit
3. ✅ **Zeroize secrets** - Always dispose `SecureBytes` properly
4. ✅ **Test crypto code** - Every cryptographic function needs comprehensive tests
5. ✅ **Constant-time operations** - Avoid timing side-channels

**Example - Proper SecureBytes Handling:**

```dart
Future<void> processSecret(SecureBytes secret) async {
  try {
    // Use the secret
    final result = await encryptData(secret);
    return result;
  } finally {
    // ALWAYS dispose secrets
    secret.dispose();
  }
}
```

---

## 🔧 Development Workflow

### Making Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow Dart/Flutter conventions
   - Write tests for new functionality
   - Update documentation if needed

3. **Run checks**
   ```bash
   dart format .
   dart analyze
   fvm flutter test
   ```

4. **Commit with clear messages**
   ```bash
   git commit -m "feat: add X feature"
   git commit -m "fix: resolve Y issue"
   git commit -m "docs: update Z documentation"
   ```

5. **Push and create PR**
   ```bash
   git push origin feature/your-feature-name
   ```
   Then open a Pull Request on GitHub with:
   - Clear description of changes
   - Screenshots for UI changes
   - Reference to related issues

---

## 🧪 Testing Guidelines

### Test Coverage Requirements

- **Crypto code**: 100% coverage required
- **Core business logic**: Minimum 80% coverage
- **UI components**: Integration tests for critical flows

### Writing Tests

```dart
// Example test structure
void main() {
  group('Feature Name', () {
    test('should do X when Y happens', () {
      // Arrange
      final sut = SystemUnderTest();
      
      // Act
      final result = sut.doSomething();
      
      // Assert
      expect(result, expectedValue);
    });
  });
}
```

---

## 📝 Code Style

### Follow Dart/Flutter Best Practices

- Use `dart format .` before committing
- Run `dart analyze` and fix all issues
- Prefer `const` constructors where possible
- Use meaningful variable names
- Add comments for complex logic only

### Riverpod Patterns

```dart
// Good: Use code generation
@riverpod
class MyNotifier extends _$MyNotifier {
  @override
  MyState build() => MyState.initial();
}

// Good: Dispose resources
@override
void dispose() {
  _subscription?.cancel();
  super.dispose();
}
```

---

## 🐛 Reporting Issues

### Bug Reports

Include:
- Steps to reproduce
- Expected behavior
- Actual behavior
- Screenshots/logs if applicable
- Device/platform information

### Feature Requests

Include:
- Use case description
- Proposed solution
- Alternative approaches considered

---

## 🔐 Security Vulnerability Reporting

**Do NOT open public issues for security vulnerabilities.**

Email security@nativewit.com with:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We'll respond within 48 hours and work with you to address the issue.

---

## 📜 License

By contributing, you agree that your contributions will be licensed under the AGPL-3.0 license.

---

## 🙏 Questions?

- Check existing issues and discussions
- Ask in our community channels
- Read the [main README](README.md) for architecture details

Thank you for making Witflo better! 🎉
