// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// FolderPicker IO - Platform detection for native platforms
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:witflo_app/core/workspace/folder_picker.dart';
import 'package:witflo_app/core/workspace/folder_picker_desktop.dart';
import 'package:witflo_app/core/workspace/folder_picker_mobile.dart';

/// Creates the appropriate FolderPicker for the current native platform.
FolderPicker createFolderPicker() {
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    return FolderPickerDesktop();
  } else if (Platform.isIOS || Platform.isAndroid) {
    return FolderPickerMobile();
  } else {
    throw UnsupportedError(
      'FolderPicker is not supported on ${Platform.operatingSystem}',
    );
  }
}
