// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Centralized Widget Keys for Marionette MCP Integration
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/widgets.dart';

/// Centralized repository of all widget keys used in Witflo.
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
///   key: AppKeys.btnGetStarted,
///   onPressed: () => ...,
///   child: Text('Get Started'),
/// )
/// ```
///
/// For dynamic keys with IDs:
/// ```dart
/// ListTile(
///   key: AppKeys.vaultItem(vaultId),
///   ...
/// )
/// ```
class AppKeys {
  AppKeys._(); // Private constructor to prevent instantiation

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

  /// Vaults list in sidebar
  static const listVaultsSidebar = Key('list_vaults_sidebar');

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
  // VAULT CREATE DIALOG
  // ═══════════════════════════════════════════════════════════════════════════

  /// Vault name input (create dialog)
  static const inputVaultNameCreate = Key('input_vault_name_create');

  /// Vault description input
  static const inputVaultDescription = Key('input_vault_description');

  /// Cancel vault creation button
  static const btnVaultCancel = Key('btn_vault_cancel');

  /// Confirm vault creation button
  static const btnVaultCreateConfirm = Key('btn_vault_create_confirm');

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTE SHARE DIALOG
  // ═══════════════════════════════════════════════════════════════════════════

  /// Email input for sharing
  static const inputShareEmail = Key('input_share_email');

  /// Role dropdown (viewer/editor)
  static const dropdownShareRole = Key('dropdown_share_role');

  /// Invite user button
  static const btnShareInvite = Key('btn_share_invite');

  /// Generate share link button
  static const btnShareGenerateLink = Key('btn_share_generate_link');

  /// Copy share link button
  static const btnShareCopyLink = Key('btn_share_copy_link');

  /// Done button (close dialog)
  static const btnShareDone = Key('btn_share_done');

  // ═══════════════════════════════════════════════════════════════════════════
  // VAULT EXPORT DIALOG
  // ═══════════════════════════════════════════════════════════════════════════

  /// Export vault button (settings)
  static const btnExportVault = Key('btn_export_vault');

  /// Vault selection dropdown in export dialog
  static const dropdownExportVaultSelect = Key('dropdown_export_vault_select');

  /// Select export folder button
  static const btnExportSelectFolder = Key('btn_export_select_folder');

  /// Confirm export button
  static const btnExportConfirm = Key('btn_export_confirm');

  /// Cancel export button
  static const btnExportCancel = Key('btn_export_cancel');

  /// Security warning checkbox
  static const checkboxExportWarning = Key('checkbox_export_warning');

  // ═══════════════════════════════════════════════════════════════════════════
  // SETTINGS PAGE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Change master password button (settings)
  static const btnSettingsChangePassword = Key('btn_settings_change_password');

  /// Auto-lock timer button
  static const btnAutoLockTimer = Key('btn_auto_lock_timer');

  /// Lock on background switch
  static const switchLockOnBackground = Key('switch_lock_on_background');

  /// Lock workspace now button
  static const btnLockWorkspaceNow = Key('btn_lock_workspace_now');

  // Change Password Dialog (Settings)

  /// Current password input
  static const inputCurrentPassword = Key('input_current_password');

  /// New password input
  static const inputNewPassword = Key('input_new_password');

  /// Confirm new password input
  static const inputConfirmNewPassword = Key('input_confirm_new_password');

  /// Cancel password change button
  static const btnPasswordCancel = Key('btn_password_cancel');

  /// Confirm password change button
  static const btnPasswordConfirm = Key('btn_password_confirm');

  // Auto-Lock Duration Dialog

  /// Auto-lock disabled option
  static const radioAutoLockDisabled = Key('radio_autolock_disabled');

  /// Auto-lock 5 minutes option
  static const radioAutoLock5Min = Key('radio_autolock_5min');

  /// Auto-lock 15 minutes option
  static const radioAutoLock15Min = Key('radio_autolock_15min');

  /// Auto-lock 30 minutes option
  static const radioAutoLock30Min = Key('radio_autolock_30min');

  /// Auto-lock 60 minutes option
  static const radioAutoLock60Min = Key('radio_autolock_60min');

  /// Cancel auto-lock dialog button
  static const btnAutoLockCancel = Key('btn_autolock_cancel');

  // ═══════════════════════════════════════════════════════════════════════════
  // VAULT SWITCHER DIALOG
  // ═══════════════════════════════════════════════════════════════════════════

  /// Vault switcher dialog container
  static const vaultSwitcherDialog = Key('vault_switcher_dialog');

  /// Vault list in switcher
  static const vaultList = Key('vault_list');

  /// Create vault button in switcher
  static const btnCreateVaultSwitcher = Key('btn_create_vault_switcher');

  /// Vault switcher item with dynamic ID
  static Key vaultSwitcherItem(String id) => Key('vault_switcher_item_$id');

  /// Vault card on home page (tappable to open switcher)
  static const vaultCardHome = Key('vault_card_home');

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
    listVaultsSidebar,
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

    // Vault Create Dialog
    inputVaultNameCreate,
    inputVaultDescription,
    btnVaultCancel,
    btnVaultCreateConfirm,

    // Note Share Dialog
    inputShareEmail,
    dropdownShareRole,
    btnShareInvite,
    btnShareGenerateLink,
    btnShareCopyLink,
    btnShareDone,

    // Vault Export Dialog
    btnExportVault,
    dropdownExportVaultSelect,
    btnExportSelectFolder,
    btnExportConfirm,
    btnExportCancel,
    checkboxExportWarning,

    // Settings Page
    btnSettingsChangePassword,
    btnAutoLockTimer,
    switchLockOnBackground,
    btnLockWorkspaceNow,

    // Change Password Dialog
    inputCurrentPassword,
    inputNewPassword,
    inputConfirmNewPassword,
    btnPasswordCancel,
    btnPasswordConfirm,

    // Auto-Lock Duration Dialog
    radioAutoLockDisabled,
    radioAutoLock5Min,
    radioAutoLock15Min,
    radioAutoLock30Min,
    radioAutoLock60Min,
    btnAutoLockCancel,

    // Vault Switcher Dialog
    vaultSwitcherDialog,
    vaultList,
    btnCreateVaultSwitcher,
    vaultCardHome,
  ];

  /// Get count of all static keys
  static int get keyCount => allKeys.length;
}
