// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// AutoLockSettings - Configurable auto-lock behavior for workspace sessions
// ═══════════════════════════════════════════════════════════════════════════
//
// AUTO-LOCK CONFIGURATION:
// - Enabled/disabled toggle
// - Idle duration (5/15/30/60 minutes)
// - Lock on background (iOS/Android app lifecycle)
//
// PERSISTENCE:
// Settings are stored in SharedPreferences as JSON for fast access.
//
// DEFAULT BEHAVIOR:
// - Enabled: true
// - Duration: 15 minutes
// - Lock on background: true
//
// Spec: docs/specs/spec-002-workspace-master-password.md (Section 3.5)
// ═══════════════════════════════════════════════════════════════════════════

// ignore_for_file: library_private_types_in_public_api
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'auto_lock_settings.g.dart';

/// Configuration for workspace auto-lock behavior.
///
/// This model controls when the workspace automatically locks to protect
/// sensitive data when the app is idle or in the background.
///
/// **Presets**:
/// - [standard]: Default recommended settings (15 min idle, lock on background)
/// - [security]: Higher security settings (5 min idle, lock on background)
/// - [convenience]: More convenient settings (60 min idle, no background lock)
/// - [disabled]: Auto-lock disabled (only manual lock)
///
/// **Usage**:
/// ```dart
/// // Use standard settings
/// final settings = AutoLockSettings.standard;
///
/// // Custom settings
/// final custom = AutoLockSettings((b) => b
///   ..enabled = true
///   ..duration = Duration(minutes: 30)
///   ..lockOnBackground = true
/// );
///
/// // Persistence
/// final json = settings.toJson();
/// final restored = AutoLockSettings.fromJson(json);
/// ```
abstract class AutoLockSettings
    implements Built<AutoLockSettings, AutoLockSettingsBuilder> {
  static Serializer<AutoLockSettings> get serializer =>
      _$autoLockSettingsSerializer;

  /// Whether auto-lock is enabled.
  ///
  /// When disabled, the workspace will only lock when the user explicitly
  /// triggers the lock action.
  @BuiltValueField(wireName: 'enabled')
  bool get enabled;

  /// Idle duration before auto-lock.
  ///
  /// The workspace will automatically lock after this duration of inactivity.
  /// Activity is defined as user interaction (taps, typing, navigation).
  ///
  /// **Valid values**: 5, 15, 30, or 60 minutes
  ///
  /// **Note**: Stored as seconds in JSON for compatibility.
  @BuiltValueField(wireName: 'duration_seconds')
  int get durationSeconds;

  /// Whether to lock when app goes to background.
  ///
  /// When enabled, the workspace will immediately lock when:
  /// - App is minimized (AppLifecycleState.paused)
  /// - App is terminated (AppLifecycleState.detached)
  ///
  /// This is recommended for maximum security.
  @BuiltValueField(wireName: 'lock_on_background')
  bool get lockOnBackground;

  AutoLockSettings._();

  factory AutoLockSettings([void Function(AutoLockSettingsBuilder) updates]) =
      _$AutoLockSettings;

  /// Getter for duration as Duration object.
  Duration get duration => Duration(seconds: durationSeconds);

  /// Standard settings (recommended default).
  ///
  /// - Enabled: true
  /// - Idle duration: 15 minutes
  /// - Lock on background: true
  static AutoLockSettings get standard => AutoLockSettings(
    (b) => b
      ..enabled = true
      ..durationSeconds =
          15 *
          60 // 15 minutes
      ..lockOnBackground = true,
  );

  /// Security-focused settings (maximum protection).
  ///
  /// - Enabled: true
  /// - Idle duration: 5 minutes
  /// - Lock on background: true
  static AutoLockSettings get security => AutoLockSettings(
    (b) => b
      ..enabled = true
      ..durationSeconds =
          5 *
          60 // 5 minutes
      ..lockOnBackground = true,
  );

  /// Convenience-focused settings (less interruption).
  ///
  /// - Enabled: true
  /// - Idle duration: 60 minutes
  /// - Lock on background: false
  static AutoLockSettings get convenience => AutoLockSettings(
    (b) => b
      ..enabled = true
      ..durationSeconds =
          60 *
          60 // 60 minutes
      ..lockOnBackground = false,
  );

  /// Disabled settings (only manual lock).
  ///
  /// - Enabled: false
  /// - Idle duration: 15 minutes (ignored when disabled)
  /// - Lock on background: false
  static AutoLockSettings get disabled => AutoLockSettings(
    (b) => b
      ..enabled = false
      ..durationSeconds =
          15 *
          60 // 15 minutes (ignored)
      ..lockOnBackground = false,
  );

  /// Serializes to JSON for persistence.
  ///
  /// Example output:
  /// ```json
  /// {
  ///   "enabled": true,
  ///   "duration_seconds": 900,
  ///   "lock_on_background": true
  /// }
  /// ```
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'duration_seconds': durationSeconds,
      'lock_on_background': lockOnBackground,
    };
  }

  /// Deserializes from JSON.
  ///
  /// Falls back to [standard] settings if JSON is invalid.
  static AutoLockSettings fromJson(Map<String, dynamic> json) {
    try {
      return AutoLockSettings(
        (b) => b
          ..enabled = (json['enabled'] as bool?) ?? true
          ..durationSeconds = (json['duration_seconds'] as int?) ?? (15 * 60)
          ..lockOnBackground = (json['lock_on_background'] as bool?) ?? true,
      );
    } catch (e) {
      // Fall back to standard settings on error
      return AutoLockSettings.standard;
    }
  }
}
