// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Secure Bytes Type - Memory-safe byte container with automatic zeroization
// ═══════════════════════════════════════════════════════════════════════════
//
// SECURITY RATIONALE:
// This class wraps sensitive byte data (keys, plaintext) and ensures:
// 1. Explicit lifecycle management with dispose()
// 2. Automatic zeroization of memory on disposal
// 3. Prevention of accidental key logging/serialization
// 4. Constant-time comparison to prevent timing attacks
//
// USAGE:
// - Always call dispose() when done with sensitive data
// - Use try/finally or with SecureBytes pattern
// - Never log or serialize SecureBytes contents
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';

/// A secure container for sensitive byte data with automatic zeroization.
///
/// This class ensures that sensitive cryptographic material (keys, plaintext,
/// nonces) is properly cleaned from memory when no longer needed.
///
/// **CRITICAL**: Always call [dispose] when finished with the data.
class SecureBytes {
  /// The underlying byte data. Access with caution.
  /// This getter returns a copy to prevent external modification.
  Uint8List get bytes {
    _checkNotDisposed();
    // Return a copy to prevent external modification of internal state
    return Uint8List.fromList(_bytes);
  }

  /// Direct access to internal bytes (no copy).
  /// Use only for performance-critical crypto operations.
  /// NEVER store this reference - it may be zeroized.
  Uint8List get unsafeBytes {
    _checkNotDisposed();
    return _bytes;
  }

  /// The length of the secure bytes.
  int get length {
    _checkNotDisposed();
    return _bytes.length;
  }

  /// Whether this SecureBytes has been disposed.
  bool get isDisposed => _isDisposed;

  final Uint8List _bytes;
  bool _isDisposed = false;

  /// Creates SecureBytes from existing data.
  /// The input data is copied - the original should be zeroized separately.
  SecureBytes(Uint8List data) : _bytes = Uint8List.fromList(data);

  /// Creates SecureBytes from a list of integers.
  /// Useful for testing or creating from other sources.
  SecureBytes.fromList(List<int> data) : _bytes = Uint8List.fromList(data);

  /// Creates SecureBytes of specified length filled with zeros.
  /// Useful for pre-allocating buffers.
  SecureBytes.zero(int length) : _bytes = Uint8List(length);

  /// Zeroizes the internal memory and marks as disposed.
  ///
  /// **CRITICAL**: Always call this when done with sensitive data.
  /// After calling dispose, any access to [bytes] will throw.
  void dispose() {
    if (!_isDisposed) {
      // Zeroize memory - overwrite with zeros
      for (var i = 0; i < _bytes.length; i++) {
        _bytes[i] = 0;
      }
      _isDisposed = true;
    }
  }

  /// Constant-time comparison to prevent timing attacks.
  ///
  /// Returns true if both SecureBytes contain identical data.
  /// The comparison always takes the same amount of time regardless
  /// of where differences occur.
  bool constantTimeEquals(SecureBytes other) {
    _checkNotDisposed();
    other._checkNotDisposed();

    if (_bytes.length != other._bytes.length) {
      return false;
    }

    var result = 0;
    for (var i = 0; i < _bytes.length; i++) {
      result |= _bytes[i] ^ other._bytes[i];
    }
    return result == 0;
  }

  void _checkNotDisposed() {
    if (_isDisposed) {
      throw StateError(
        'SecureBytes has been disposed. '
        'Accessing disposed cryptographic material is a security violation.',
      );
    }
  }

  @override
  String toString() {
    if (_isDisposed) {
      return 'SecureBytes(disposed)';
    }
    // NEVER log actual bytes - this is intentional
    return 'SecureBytes(${_bytes.length} bytes)';
  }

  /// Creates a copy of this SecureBytes.
  /// The caller is responsible for disposing the copy.
  SecureBytes copy() {
    _checkNotDisposed();
    return SecureBytes(_bytes);
  }
}

/// Extension to zeroize a Uint8List in place.
extension Uint8ListZeroize on Uint8List {
  /// Zeroizes this byte array in place.
  /// Use for any sensitive data that isn't wrapped in SecureBytes.
  void zeroize() {
    for (var i = 0; i < length; i++) {
      this[i] = 0;
    }
  }
}

