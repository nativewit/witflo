// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Feature Flags - Controls visibility of WIP features
// ═══════════════════════════════════════════════════════════════════════════

/// Feature flags to control visibility of work-in-progress features.
///
/// These flags allow hiding incomplete features from users while keeping
/// the code in the repository for development purposes.
///
/// To enable a feature for development/testing:
/// 1. Change the flag value here
/// 2. Hot restart the app
///
/// Production releases should have all WIP features disabled.
class FeatureFlags {
  FeatureFlags._();

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARING FEATURES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enable sharing UI (share dialogs, share menu items).
  ///
  /// When disabled:
  /// - Share menu items are hidden from vault/note/notebook context menus
  /// - Share dialog is not accessible
  ///
  /// Status: Backend crypto is implemented, but no server integration exists.
  static const bool shareEnabled = false;

  // ═══════════════════════════════════════════════════════════════════════════
  // SYNC FEATURES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enable sync functionality (sync button, sync operations).
  ///
  /// When disabled:
  /// - Sync button is hidden from the UI
  /// - No sync operations are performed
  ///
  /// Status: CRDT-based sync engine exists, but uses LocalOnlyBackend (no-op).
  static const bool syncEnabled = false;

  /// Enable cloud/HTTP sync backend.
  ///
  /// When disabled, uses LocalOnlyBackend even if syncEnabled is true.
  ///
  /// Status: HTTP backend is a stub - no actual server exists.
  static const bool cloudSyncEnabled = false;

  // ═══════════════════════════════════════════════════════════════════════════
  // IDENTITY FEATURES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enable user identity features (identity string, shareable identity).
  ///
  /// When disabled:
  /// - User identity UI is hidden
  /// - Identity-based sharing is not available
  ///
  /// Status: Crypto operations complete, no backend for identity exchange.
  static const bool userIdentityEnabled = false;

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH FEATURES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enable encrypted search functionality.
  ///
  /// When disabled:
  /// - Search button shows "coming soon" message
  /// - EncryptedSearchIndex is not used
  ///
  /// Status: Blind-token search index exists but is not wired up.
  static const bool encryptedSearchEnabled = false;

  // ═══════════════════════════════════════════════════════════════════════════
  // DEBUG FEATURES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enable debug/development features.
  ///
  /// When enabled:
  /// - Shows additional debug info in UI
  /// - Enables verbose logging
  static const bool debugFeaturesEnabled = false;
}
