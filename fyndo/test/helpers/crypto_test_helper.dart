// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Crypto Test Helper - Initialize crypto for tests
// ═══════════════════════════════════════════════════════════════════════════
//
// USAGE:
// In test files, call initializeCryptoForTests() in setUpAll:
//
// ```dart
// setUpAll(() async {
//   await initializeCryptoForTests();
// });
// ```
//
// This ensures libsodium (SodiumSumo) is properly initialized before any
// crypto operations are performed in tests.
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';
import 'package:fyndo_app/core/crypto/crypto.dart';

/// Global crypto service instance for tests.
/// Initialized once and reused across all tests.
CryptoService? _testCrypto;

/// Whether crypto initialization failed (used to skip tests).
bool _cryptoInitFailed = false;

/// Gets whether crypto is available for tests.
bool get isCryptoAvailable => _testCrypto != null && !_cryptoInitFailed;

/// Initializes cryptography for tests.
///
/// Call this in setUpAll() before running any tests that use crypto.
/// This function is idempotent - safe to call multiple times.
///
/// Example:
/// ```dart
/// void main() {
///   setUpAll(() async {
///     await initializeCryptoForTests();
///   });
///
///   test('some crypto test', () async {
///     final crypto = getTestCrypto();
///     // Use crypto service...
///   });
/// }
/// ```
Future<CryptoService> initializeCryptoForTests() async {
  if (_testCrypto != null && CryptoService.isInitialized) {
    return _testCrypto!;
  }

  if (_cryptoInitFailed) {
    throw StateError(
      'Crypto initialization previously failed. '
      'Tests requiring crypto should be skipped.',
    );
  }

  // Ensure Flutter test binding is initialized
  TestWidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize crypto service
    // CryptoService.initialize() handles SodiumSumo initialization internally
    _testCrypto = await CryptoService.initialize();
    return _testCrypto!;
  } catch (e) {
    // Check if this is the FFI library loading issue
    if (e.toString().contains('LateInitializationError') ||
        e.toString().contains('_instance') ||
        e.toString().contains('SodiumPlatform')) {
      // This happens when sodium_libs FFI bindings can't load native libraries
      // in the test environment. This is a known limitation on some platforms.
      _cryptoInitFailed = true;
      throw StateError(
        'Crypto initialization failed - native FFI libraries not available in test environment.\n\n'
        'KNOWN ISSUE: sodium_libs requires native FFI bindings that may not be\n'
        'available in Flutter test VM on some platforms (especially macOS).\n\n'
        'WORKAROUND: Tests requiring crypto should check isCryptoAvailable and skip:\n'
        '  if (!isCryptoAvailable) {\n'
        '    test.skip("Crypto not available in test environment");\n'
        '  }\n\n'
        'Original error: $e',
      );
    }

    _cryptoInitFailed = true;
    throw StateError(
      'Failed to initialize crypto for tests: $e\n\n'
      'This usually means:\n'
      '1. sodium_libs package is not properly configured\n'
      '2. Native libraries are missing for your platform\n'
      '3. Test environment cannot access crypto libraries\n\n'
      'Try running: flutter pub get\n\n'
      'Original error: $e',
    );
  }
}

/// Gets the initialized crypto service for tests.
///
/// Throws if [initializeCryptoForTests] hasn't been called.
CryptoService getTestCrypto() {
  if (_testCrypto == null) {
    throw StateError(
      'Crypto not initialized for tests. '
      'Call initializeCryptoForTests() in setUpAll() first.',
    );
  }
  return _testCrypto!;
}

/// Disposes the test crypto service.
///
/// Typically called in tearDownAll() if you need to clean up.
/// However, since CryptoService is stateless, this is usually not necessary.
void disposeTestCrypto() {
  // CryptoService doesn't have cleanup, but we clear the reference
  _testCrypto = null;
}
