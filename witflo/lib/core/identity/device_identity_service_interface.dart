// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// IDeviceIdentityService - Device Identity Service Interface
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';

import 'package:witflo_app/core/crypto/crypto.dart';
import 'package:witflo_app/core/identity/device_identity.dart';

/// Service for managing device identities.
abstract interface class IDeviceIdentityService {
  /// Generates a new device identity.
  DeviceIdentity generateIdentity({required String deviceName});

  /// Wraps a vault key for device-based unlock.
  DeviceWrappedVaultKey wrapVaultKeyForDevice({
    required VaultKey vaultKey,
    required DevicePublicIdentity device,
  });

  /// Unwraps a vault key using device's secret key.
  VaultKey unwrapVaultKey({
    required DeviceWrappedVaultKey wrapped,
    required DeviceIdentity device,
  });

  /// Signs data with device's signing key.
  Signature signWithDevice({
    required Uint8List data,
    required DeviceIdentity device,
  });

  /// Verifies a signature from a device.
  bool verifyDeviceSignature({
    required Uint8List data,
    required Signature signature,
    required DevicePublicIdentity device,
  });
}
