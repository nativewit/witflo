// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// FolderPicker - Platform-agnostic folder selection interface
// ═══════════════════════════════════════════════════════════════════════════

/// Platform-agnostic interface for selecting workspace folders.
///
/// Implementations:
/// - [FolderPickerDesktop] - Uses file_selector for macOS/Windows/Linux
/// - [FolderPickerMobile] - Uses path_provider for iOS/Android
///
/// Usage:
/// ```dart
/// final picker = FolderPicker.create();
/// final path = await picker.pickFolder();
/// if (path != null) {
///   // User selected a folder
/// }
/// ```
///
/// Spec: docs/specs/spec-001-workspace-management.md (Section 4.1)
abstract class FolderPicker {
  /// Opens the platform's folder picker dialog.
  ///
  /// Desktop: Opens native file picker in directory selection mode.
  /// Mobile: Returns app-scoped documents directory (no user interaction).
  ///
  /// Returns:
  /// - Absolute path to selected folder (Desktop)
  /// - App documents directory path (Mobile)
  /// - null if user cancelled (Desktop only)
  ///
  /// Throws:
  /// - [FolderPickerException] if permission denied or system error
  Future<String?> pickFolder();

  /// Returns the default workspace directory for the platform.
  ///
  /// Desktop: ~/Documents/FyndoWorkspace (or localized equivalent)
  /// Mobile: App-scoped documents directory
  ///
  /// This directory may not exist yet - use [WorkspaceService] to initialize.
  Future<String> getDefaultWorkspaceDirectory();

  /// Checks if the given path is accessible for read/write operations.
  ///
  /// Returns true if the app has permission to read and write to [path].
  /// Returns false if path doesn't exist, is not a directory, or lacks permissions.
  Future<bool> canAccessDirectory(String path);

  /// Factory constructor that returns the appropriate platform implementation.
  ///
  /// Automatically detects platform and returns:
  /// - [FolderPickerDesktop] on macOS, Windows, Linux
  /// - [FolderPickerMobile] on iOS, Android
  ///
  /// Throws:
  /// - [UnsupportedError] on Web (use different storage strategy)
  factory FolderPicker.create() {
    // Implementation in folder_picker_desktop.dart and folder_picker_mobile.dart
    // uses Platform.isXXX to determine which implementation to return
    throw UnimplementedError(
      'FolderPicker.create() must be implemented by platform-specific files',
    );
  }
}

/// Exception thrown by FolderPicker operations.
class FolderPickerException implements Exception {
  final String message;
  final Object? cause;

  FolderPickerException(this.message, [this.cause]);

  @override
  String toString() =>
      'FolderPickerException: $message${cause != null ? ' ($cause)' : ''}';
}
