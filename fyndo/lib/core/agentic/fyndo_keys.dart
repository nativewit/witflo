// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Centralized Widget Keys for Marionette MCP Integration
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/widgets.dart';

/// Centralized repository of all widget keys used in Fyndo.
///
/// This class provides a single source of truth for all widget keys,
/// making them easy to manage, discover, and use consistently across
/// the application. All keys follow the naming pattern: `<feature>_<action>`.
///
/// Keys are organized by page/feature for easy navigation.
///
/// Usage:
/// ```dart
/// ElevatedButton(
///   key: FyndoKeys.btnGetStarted,
///   onPressed: () => ...,
///   child: Text('Get Started'),
/// )
/// ```
///
/// For dynamic keys with IDs:
/// ```dart
/// ListTile(
///   key: FyndoKeys.vaultItem(vaultId),
///   ...
/// )
/// ```
class FyndoKeys {
  FyndoKeys._(); // Private constructor to prevent instantiation

  // ═══════════════════════════════════════════════════════════════════════════
  // WELCOME PAGE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Start onboarding button
  static const btnGetStarted = Key('btn_get_started');

  /// Master password input field
  static const inputMasterPassword = Key('input_master_password');

  /// Unlock workspace button
  static const btnUnlockWorkspace = Key('btn_unlock_workspace');

  /// Lock workspace button (app bar)
  static const btnLockWorkspace = Key('btn_lock_workspace');

  /// Create vault button (header)
  static const btnVaultCreate = Key('btn_vault_create');

  /// Create vault button (empty state)
  static const btnVaultCreateEmpty = Key('btn_vault_create_empty');

  /// Vault list item with dynamic ID
  static Key vaultItem(String id) => Key('vault_item_$id');

  // ═══════════════════════════════════════════════════════════════════════════
  // ONBOARDING WIZARD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Choose workspace folder button
  static const btnWorkspaceChoose = Key('btn_workspace_choose');

  /// Use default workspace location button
  static const btnWorkspaceDefault = Key('btn_workspace_default');

  /// Change selected workspace folder button
  static const btnWorkspaceChange = Key('btn_workspace_change');

  /// Master password creation input
  static const inputMasterPasswordCreate = Key('input_master_password_create');

  /// Master password confirmation input
  static const inputMasterPasswordConfirm = Key(
    'input_master_password_confirm',
  );

  /// Vault name input (onboarding)
  static const inputVaultName = Key('input_vault_name');

  /// Next/Finish button in onboarding
  static const btnOnboardingNext = Key('btn_onboarding_next');

  /// Back button in onboarding
  static const btnOnboardingBack = Key('btn_onboarding_back');

  // ═══════════════════════════════════════════════════════════════════════════
  // HOME PAGE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Search button (app bar)
  static const btnSearch = Key('btn_search');

  /// Settings navigation button
  static const navSettings = Key('nav_settings');

  /// More actions menu (app bar)
  static const menuMoreActions = Key('menu_more_actions');

  /// All notes navigation (sidebar)
  static const navAllNotes = Key('nav_all_notes');

  /// Pinned notes navigation (sidebar)
  static const navPinned = Key('nav_pinned');

  /// Archived notes navigation (sidebar)
  static const navArchived = Key('nav_archived');

  /// Notebooks list in sidebar
  static const listNotebooksSidebar = Key('list_notebooks_sidebar');

  /// Create notebook button (FAB)
  static const btnNotebookCreate = Key('btn_notebook_create');

  /// Create notebook button (sidebar)
  static const btnNotebookCreateSidebar = Key('btn_notebook_create_sidebar');

  /// Create notebook button (header)
  static const btnNotebookCreateHeader = Key('btn_notebook_create_header');

  /// Notebook list item with dynamic ID (sidebar)
  static Key notebookItem(String id) => Key('notebook_item_$id');

  /// Notebook card with dynamic ID (grid)
  static Key notebookCard(String id) => Key('notebook_card_$id');

  // ═══════════════════════════════════════════════════════════════════════════
  // VAULT PAGE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Vault actions menu (app bar)
  static const menuVaultActions = Key('menu_vault_actions');

  /// Change password button
  static const btnChangePassword = Key('btn_change_password');

  /// Recovery options button
  static const btnRecoveryOptions = Key('btn_recovery_options');

  /// Linked devices button
  static const btnLinkedDevices = Key('btn_linked_devices');

  /// Enable sync switch
  static const switchEnableSync = Key('switch_enable_sync');

  /// Backup to cloud button
  static const btnBackupCloud = Key('btn_backup_cloud');

  /// Delete vault button
  static const btnDeleteVault = Key('btn_delete_vault');

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTEBOOK PAGE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create note button (app bar)
  static const btnNoteCreate = Key('btn_note_create');

  /// Notebook actions menu (app bar)
  static const menuNotebookActions = Key('menu_notebook_actions');

  /// Back to notes button (mobile)
  static const btnBackToNotes = Key('btn_back_to_notes');

  /// Notes list container
  static const listNotes = Key('list_notes');

  /// Pin/unpin note button (editor toolbar)
  static const btnNotePin = Key('btn_note_pin');

  /// Note actions menu (editor toolbar)
  static const menuNoteActions = Key('menu_note_actions');

  /// Note list item with dynamic ID
  static Key noteItem(String id) => Key('note_item_$id');

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTE PAGE (Standalone)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Pin/unpin note button (standalone page)
  static const btnNotePinToggle = Key('btn_note_pin_toggle');

  /// Note actions menu (standalone page)
  static const menuNoteActionsStandalone = Key('menu_note_actions_standalone');

  /// Note title input field
  static const inputNoteTitle = Key('input_note_title');

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTEBOOK CREATE DIALOG
  // ═══════════════════════════════════════════════════════════════════════════

  /// Notebook name input
  static const inputNotebookName = Key('input_notebook_name');

  /// Notebook description input
  static const inputNotebookDescription = Key('input_notebook_description');

  /// Cancel notebook creation button
  static const btnNotebookCancel = Key('btn_notebook_cancel');

  /// Confirm notebook creation button
  static const btnNotebookCreateConfirm = Key('btn_notebook_create_confirm');

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all static keys (for documentation/testing)
  static List<Key> get allKeys => [
    // Welcome Page
    btnGetStarted,
    inputMasterPassword,
    btnUnlockWorkspace,
    btnLockWorkspace,
    btnVaultCreate,
    btnVaultCreateEmpty,

    // Onboarding
    btnWorkspaceChoose,
    btnWorkspaceDefault,
    btnWorkspaceChange,
    inputMasterPasswordCreate,
    inputMasterPasswordConfirm,
    inputVaultName,
    btnOnboardingNext,
    btnOnboardingBack,

    // Home Page
    btnSearch,
    navSettings,
    menuMoreActions,
    navAllNotes,
    navPinned,
    navArchived,
    listNotebooksSidebar,
    btnNotebookCreate,
    btnNotebookCreateSidebar,
    btnNotebookCreateHeader,

    // Vault Page
    menuVaultActions,
    btnChangePassword,
    btnRecoveryOptions,
    btnLinkedDevices,
    switchEnableSync,
    btnBackupCloud,
    btnDeleteVault,

    // Notebook Page
    btnNoteCreate,
    menuNotebookActions,
    btnBackToNotes,
    listNotes,
    btnNotePin,
    menuNoteActions,

    // Note Page
    btnNotePinToggle,
    menuNoteActionsStandalone,
    inputNoteTitle,

    // Notebook Create Dialog
    inputNotebookName,
    inputNotebookDescription,
    btnNotebookCancel,
    btnNotebookCreateConfirm,
  ];

  /// Get count of all static keys
  static int get keyCount => allKeys.length;
}
