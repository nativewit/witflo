// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// ISharingService - Sharing Service Interface
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';

import 'package:fyndo_app/core/crypto/types/types.dart';
import 'package:fyndo_app/core/identity/identity.dart';
import 'package:fyndo_app/core/sharing/sharing_service.dart';

/// Service for managing zero-knowledge sharing.
abstract interface class ISharingService {
  /// Computes a hash of a public key for identification.
  String publicKeyHash(Uint8List publicKey);

  /// Creates a share for a notebook.
  Share shareNotebook({
    required NotebookKey notebookKey,
    required String notebookId,
    String? notebookName,
    required ShareRole role,
    required UserPublicIdentity recipient,
    required UserIdentity sharer,
    DateTime? expiresAt,
  });

  /// Creates a share for a single note.
  Share shareNote({
    required NoteShareKey noteShareKey,
    required String noteId,
    String? noteTitle,
    required ShareRole role,
    required UserPublicIdentity recipient,
    required UserIdentity sharer,
    DateTime? expiresAt,
  });

  /// Accepts a share and unwraps the key.
  SecureBytes acceptShare({
    required Share share,
    required UserIdentity recipient,
  });

  /// Lists shares where we are the recipient.
  List<Share> filterSharesForRecipient({
    required List<Share> allShares,
    required UserIdentity recipient,
  });

  /// Lists shares where we are the sharer.
  List<Share> filterSharesFromSharer({
    required List<Share> allShares,
    required UserIdentity sharer,
  });
}
