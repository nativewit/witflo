// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Device Identity Provider - Riverpod State Management for Device Identity
// ═══════════════════════════════════════════════════════════════════════════
//
// DEVICE IDENTITY MANAGEMENT:
// - DeviceIdentity is created once per workspace
// - Stored in workspace directory as device_identity.json (encrypted)
// - Contains Ed25519 signing key + X25519 encryption key
// - Used for signing sync operations and device-based vault unlocking
//
// STORAGE LOCATION:
// - <workspace_root>/device_identity.enc
//
// LIFECYCLE:
// - Created on first access if doesn't exist
// - Cached in memory while workspace is unlocked
// - Zeroized when workspace is locked
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witflo_app/core/crypto/crypto.dart';
import 'package:witflo_app/core/identity/identity.dart';
import 'package:witflo_app/core/logging/app_logger.dart';
import 'package:witflo_app/providers/crypto_providers.dart';
import 'package:witflo_app/providers/unlocked_workspace_provider.dart';
import 'package:path/path.dart' as p;

/// Provider for DeviceIdentityService.
final deviceIdentityServiceProvider = Provider<DeviceIdentityService>((ref) {
  final crypto = ref.watch(cryptoServiceProvider);
  return DeviceIdentityService(crypto);
});

/// Provider for the current device's identity.
///
/// This provider:
/// - Loads device identity from workspace directory
/// - Creates new identity if doesn't exist
/// - Caches identity in memory while workspace is unlocked
/// - Auto-disposes when workspace is locked
///
/// **Storage:**
/// Device identity is stored at `<workspace_root>/device_identity.json`
/// as a JSON file containing the device ID, name, and key pairs.
///
/// **Security Note:**
/// The secret keys are stored in plaintext in the JSON file. In a production
/// system, these should be stored in platform secure storage (Keychain/KeyStore).
/// For now, we rely on filesystem permissions and workspace encryption.
///
/// **Example Usage:**
/// ```dart
/// final deviceIdentity = await ref.watch(deviceIdentityProvider.future);
/// print('Device ID: ${deviceIdentity.deviceId}');
/// ```
final deviceIdentityProvider = FutureProvider.autoDispose<DeviceIdentity>((
  ref,
) async {
  final log = AppLogger.get('deviceIdentityProvider');

  // Get workspace and dependencies
  final workspace = ref.watch(unlockedWorkspaceProvider);
  if (workspace == null) {
    throw StateError('Workspace must be unlocked to access device identity');
  }

  final deviceService = ref.watch(deviceIdentityServiceProvider);
  final crypto = ref.watch(cryptoServiceProvider);

  // Path to device identity file
  final identityPath = p.join(workspace.rootPath, 'device_identity.json');
  final identityFile = File(identityPath);

  DeviceIdentity deviceIdentity;

  // Load existing identity or create new one
  if (await identityFile.exists()) {
    try {
      log.debug('Loading device identity from: $identityPath');
      final json = jsonDecode(await identityFile.readAsString());
      deviceIdentity = _deviceIdentityFromJson(json, crypto);
      log.info('Device identity loaded: ${deviceIdentity.deviceId}');
    } catch (e) {
      log.error('Failed to load device identity, creating new one', error: e);
      // If loading fails, create new identity
      deviceIdentity = await _createAndSaveDeviceIdentity(
        deviceService,
        identityFile,
        log,
      );
    }
  } else {
    log.info('Device identity not found, creating new one');
    deviceIdentity = await _createAndSaveDeviceIdentity(
      deviceService,
      identityFile,
      log,
    );
  }

  // Dispose keys when provider is disposed
  ref.onDispose(() {
    log.debug('Disposing device identity: ${deviceIdentity.deviceId}');
    deviceIdentity.dispose();
  });

  return deviceIdentity;
});

/// Creates a new device identity and saves it to disk.
Future<DeviceIdentity> _createAndSaveDeviceIdentity(
  DeviceIdentityService deviceService,
  File identityFile,
  AppLogger log,
) async {
  // Get device name (platform-specific)
  final deviceName = _getDeviceName();

  // Generate new identity
  final deviceIdentity = deviceService.generateIdentity(deviceName: deviceName);

  // Save to disk
  final json = _deviceIdentityToJson(deviceIdentity);
  await identityFile.parent.create(recursive: true);
  await identityFile.writeAsString(jsonEncode(json));

  log.info('Created new device identity: ${deviceIdentity.deviceId}');
  return deviceIdentity;
}

/// Gets a human-readable device name.
String _getDeviceName() {
  // In production, this should use platform-specific APIs to get device name
  // For now, use hostname or platform
  try {
    return Platform.localHostname;
  } catch (e) {
    return 'Unknown Device';
  }
}

/// Serializes DeviceIdentity to JSON.
///
/// **Security Warning:**
/// This stores secret keys in plaintext JSON. In production, use platform
/// secure storage (Keychain/KeyStore) instead.
Map<String, dynamic> _deviceIdentityToJson(DeviceIdentity identity) {
  return {
    'device_id': identity.deviceId,
    'device_name': identity.deviceName,
    'registered_at': identity.registeredAt.toIso8601String(),
    'signing_key': {
      'public': identity.signingKey.publicKey.toList(),
      'secret': identity.signingKey.secretKey.bytes.toList(),
    },
    'encryption_key': {
      'public': identity.encryptionKey.publicKey.toList(),
      'secret': identity.encryptionKey.secretKey.bytes.toList(),
    },
  };
}

/// Deserializes DeviceIdentity from JSON.
DeviceIdentity _deviceIdentityFromJson(
  Map<String, dynamic> json,
  CryptoService crypto,
) {
  final signingPublic = (json['signing_key']['public'] as List).cast<int>();
  final signingSecret = (json['signing_key']['secret'] as List).cast<int>();
  final encryptionPublic = (json['encryption_key']['public'] as List)
      .cast<int>();
  final encryptionSecret = (json['encryption_key']['secret'] as List)
      .cast<int>();

  return DeviceIdentity(
    deviceId: json['device_id'] as String,
    deviceName: json['device_name'] as String,
    registeredAt: DateTime.parse(json['registered_at'] as String),
    signingKey: Ed25519KeyPair(
      publicKey: Uint8List.fromList(signingPublic),
      secretKey: SecureBytes.fromList(signingSecret),
    ),
    encryptionKey: X25519KeyPair(
      publicKey: Uint8List.fromList(encryptionPublic),
      secretKey: SecureBytes.fromList(encryptionSecret),
    ),
  );
}
