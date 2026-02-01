// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Device Identity - Per-Device Keys for Wrapping and Fast Unlock
// ═══════════════════════════════════════════════════════════════════════════
//
// DEVICE IDENTITY CONCEPT:
// Each device has its own identity keypair used for:
// 1. Wrapping VK for fast/biometric unlock (without password)
// 2. Receiving shared notebooks (wrapped with device's public key)
// 3. Signing sync operations (to prove device ownership)
//
// KEY STORAGE:
// - Device secret keys are stored in platform keychain/keystore
// - On iOS: Secure Enclave / Keychain
// - On Android: AndroidKeyStore
// - On desktop: Platform-specific secure storage
//
// DEVICE REGISTRATION:
// When a device is first used with a vault:
// 1. Generate DeviceIdentityKey (Ed25519 for signing + X25519 for encryption)
// 2. Store secret keys in platform keychain
// 3. Wrap VK with device key → store as device.key
// 4. Register public key with vault's device list
//
// FAST UNLOCK:
// 1. User authenticates with biometric/PIN
// 2. Device secret key is unlocked from keychain
// 3. Unwrap VK from device.key
// 4. Vault is unlocked without password
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:typed_data';

import 'package:fyndo_app/core/crypto/crypto.dart';
import 'package:fyndo_app/core/identity/device_identity_service_interface.dart';
import 'package:uuid/uuid.dart';

/// Device identity containing signing and encryption keys.
class DeviceIdentity {
  /// Unique device ID
  final String deviceId;

  /// Human-readable device name
  final String deviceName;

  /// Ed25519 signing key pair
  final Ed25519KeyPair signingKey;

  /// X25519 encryption key pair (for key wrapping)
  final X25519KeyPair encryptionKey;

  /// When this device was registered
  final DateTime registeredAt;

  DeviceIdentity({
    required this.deviceId,
    required this.deviceName,
    required this.signingKey,
    required this.encryptionKey,
    required this.registeredAt,
  });

  /// Public portion of device identity (safe to share/store).
  DevicePublicIdentity get publicIdentity => DevicePublicIdentity(
    deviceId: deviceId,
    deviceName: deviceName,
    signingPublicKey: signingKey.publicKey,
    encryptionPublicKey: encryptionKey.publicKey,
    registeredAt: registeredAt,
  );

  /// Disposes secret keys.
  void dispose() {
    signingKey.dispose();
    encryptionKey.dispose();
  }
}

/// Public portion of device identity (no secrets).
class DevicePublicIdentity {
  final String deviceId;
  final String deviceName;
  final Uint8List signingPublicKey;
  final Uint8List encryptionPublicKey;
  final DateTime registeredAt;

  DevicePublicIdentity({
    required this.deviceId,
    required this.deviceName,
    required this.signingPublicKey,
    required this.encryptionPublicKey,
    required this.registeredAt,
  });

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'device_name': deviceName,
    'signing_public_key': base64Encode(signingPublicKey),
    'encryption_public_key': base64Encode(encryptionPublicKey),
    'registered_at': registeredAt.toIso8601String(),
  };

  factory DevicePublicIdentity.fromJson(Map<String, dynamic> json) {
    return DevicePublicIdentity(
      deviceId: json['device_id'] as String,
      deviceName: json['device_name'] as String,
      signingPublicKey: base64Decode(json['signing_public_key'] as String),
      encryptionPublicKey: base64Decode(
        json['encryption_public_key'] as String,
      ),
      registeredAt: DateTime.parse(json['registered_at'] as String),
    );
  }
}

/// Wrapped vault key for device-based unlock.
class DeviceWrappedVaultKey {
  /// Device ID this key is wrapped for
  final String deviceId;

  /// The wrapped key blob
  final WrappedKey wrappedKey;

  /// When this wrap was created
  final DateTime wrappedAt;

  DeviceWrappedVaultKey({
    required this.deviceId,
    required this.wrappedKey,
    required this.wrappedAt,
  });

  Uint8List toBytes() {
    final json = {
      'device_id': deviceId,
      'wrapped_at': wrappedAt.toIso8601String(),
    };
    final metadata = Uint8List.fromList(utf8.encode(jsonEncode(json)));
    final wrappedBytes = wrappedKey.toBytes();

    // Format: [metadata_len (4 bytes)] [metadata] [wrapped_key]
    final result = Uint8List(4 + metadata.length + wrappedBytes.length);
    result.buffer.asByteData().setUint32(0, metadata.length);
    result.setRange(4, 4 + metadata.length, metadata);
    result.setRange(4 + metadata.length, result.length, wrappedBytes);

    return result;
  }

  factory DeviceWrappedVaultKey.fromBytes(Uint8List bytes) {
    final metadataLen = bytes.buffer.asByteData().getUint32(0);
    final metadataBytes = bytes.sublist(4, 4 + metadataLen);
    final wrappedBytes = bytes.sublist(4 + metadataLen);

    final json = jsonDecode(utf8.decode(metadataBytes)) as Map<String, dynamic>;
    final wrappedKey = WrappedKey.fromBytes(Uint8List.fromList(wrappedBytes));

    return DeviceWrappedVaultKey(
      deviceId: json['device_id'] as String,
      wrappedKey: wrappedKey,
      wrappedAt: DateTime.parse(json['wrapped_at'] as String),
    );
  }
}

/// Service for managing device identity.
class DeviceIdentityService implements IDeviceIdentityService {
  final CryptoService _crypto;

  DeviceIdentityService(this._crypto);

  /// Generates a new device identity.
  @override
  DeviceIdentity generateIdentity({required String deviceName}) {
    final deviceId = const Uuid().v4();
    final signingKey = _crypto.ed25519.generateKeyPair();
    final encryptionKey = _crypto.x25519.generateKeyPair();

    return DeviceIdentity(
      deviceId: deviceId,
      deviceName: deviceName,
      signingKey: signingKey,
      encryptionKey: encryptionKey,
      registeredAt: DateTime.now().toUtc(),
    );
  }

  /// Wraps a vault key for device-based unlock.
  @override
  DeviceWrappedVaultKey wrapVaultKeyForDevice({
    required VaultKey vaultKey,
    required DevicePublicIdentity device,
  }) {
    final wrappedKey = _crypto.x25519.wrapKey(
      keyToWrap: vaultKey,
      recipientPublicKey: device.encryptionPublicKey,
    );

    return DeviceWrappedVaultKey(
      deviceId: device.deviceId,
      wrappedKey: wrappedKey,
      wrappedAt: DateTime.now().toUtc(),
    );
  }

  /// Unwraps a vault key using device's secret key.
  @override
  VaultKey unwrapVaultKey({
    required DeviceWrappedVaultKey wrapped,
    required DeviceIdentity device,
  }) {
    if (wrapped.deviceId != device.deviceId) {
      throw ArgumentError('Wrapped key is for different device');
    }

    final unwrapped = _crypto.x25519.unwrapKey(
      wrappedKey: wrapped.wrappedKey,
      ourSecretKey: device.encryptionKey.secretKey,
    );

    return VaultKey(unwrapped);
  }

  /// Signs data with device's signing key.
  @override
  Signature signWithDevice({
    required Uint8List data,
    required DeviceIdentity device,
  }) {
    return _crypto.ed25519.sign(message: data, keyPair: device.signingKey);
  }

  /// Verifies a signature from a device.
  @override
  bool verifyDeviceSignature({
    required Uint8List data,
    required Signature signature,
    required DevicePublicIdentity device,
  }) {
    return _crypto.ed25519.verify(
      message: data,
      signature: signature,
      publicKey: device.signingPublicKey,
    );
  }
}
