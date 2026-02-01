// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// IUserIdentityService - User Identity Service Interface
// ═══════════════════════════════════════════════════════════════════════════

import 'package:fyndo_app/core/crypto/crypto.dart';
import 'package:fyndo_app/core/identity/user_identity.dart';

/// Service for managing user identities.
abstract interface class IUserIdentityService {
  /// Derives user identity from vault key.
  ///
  /// This is deterministic - same VK always produces same identity.
  UserIdentity deriveFromVaultKey(VaultKey vaultKey);

  /// Wraps a key for a user (for sharing).
  WrappedKey wrapKeyForUser({
    required CryptoKey keyToWrap,
    required UserPublicIdentity recipient,
  });

  /// Unwraps a key received from another user.
  SecureBytes unwrapKey({
    required WrappedKey wrappedKey,
    required UserIdentity ourIdentity,
  });
}
