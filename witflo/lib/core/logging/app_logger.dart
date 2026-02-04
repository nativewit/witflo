// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// AppLogger - Centralized Logging with MCP Exposure
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:collection';
import 'package:logging/logging.dart' as pkg;
import 'package:flutter/foundation.dart';

/// Log levels matching Flutter's debug levels
enum LogLevel {
  verbose, // Detailed trace logs
  debug, // Debug information
  info, // Informational messages
  warning, // Warning messages
  error, // Error messages
  fatal; // Critical failures

  /// Convert to logging package level
  pkg.Level toPackageLevel() {
    switch (this) {
      case LogLevel.verbose:
        return pkg.Level.FINEST;
      case LogLevel.debug:
        return pkg.Level.FINE;
      case LogLevel.info:
        return pkg.Level.INFO;
      case LogLevel.warning:
        return pkg.Level.WARNING;
      case LogLevel.error:
        return pkg.Level.SEVERE;
      case LogLevel.fatal:
        return pkg.Level.SHOUT;
    }
  }

  /// Convert from logging package level
  static LogLevel fromPackageLevel(pkg.Level level) {
    if (level.value <= pkg.Level.FINEST.value) {
      return LogLevel.verbose;
    } else if (level.value <= pkg.Level.FINE.value) {
      return LogLevel.debug;
    } else if (level.value <= pkg.Level.INFO.value) {
      return LogLevel.info;
    } else if (level.value <= pkg.Level.WARNING.value) {
      return LogLevel.warning;
    } else if (level.value < pkg.Level.SHOUT.value) {
      return LogLevel.error;
    } else {
      return LogLevel.fatal;
    }
  }
}

/// Log entry for MCP exposure
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final String? error;
  final String? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level.name,
    'tag': tag,
    'message': message,
    if (error != null) 'error': error,
    if (stackTrace != null) 'stackTrace': stackTrace,
  };

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}] ');
    buffer.write('[${level.name.toUpperCase()}] ');
    buffer.write('[$tag] ');
    buffer.write(message);
    if (error != null) {
      buffer.write(' | Error: $error');
    }
    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }
    return buffer.toString();
  }
}

/// Centralized application logger with MCP exposure.
///
/// Usage:
/// ```dart
/// final log = AppLogger.get('NotebookService');
/// log.debug('Loading notebooks for vault: $vaultId');
/// log.error('Failed to load notebooks', error: e, stackTrace: st);
/// ```
abstract class AppLogger {
  /// Get logger for a specific tag/component
  factory AppLogger.get(String tag) = _AppLoggerImpl;

  /// Initialize logger system (call once at app startup)
  static Future<void> initialize({required LogLevel minLevel}) async {
    _AppLoggerImpl._initialize(minLevel: minLevel);
  }

  /// Get all logs for MCP exposure (with filtering)
  static Future<List<LogEntry>> getLogs({
    DateTime? since,
    LogLevel? minLevel,
    String? tag,
    String? searchTerm,
    int? limit,
  }) async {
    return _AppLoggerImpl._getLogs(
      since: since,
      minLevel: minLevel,
      tag: tag,
      searchTerm: searchTerm,
      limit: limit,
    );
  }

  /// Stream logs in real-time for MCP
  static Stream<LogEntry> streamLogs({LogLevel? minLevel, String? tag}) {
    return _AppLoggerImpl._streamLogs(minLevel: minLevel, tag: tag);
  }

  /// Clear all stored logs
  static void clearLogs() {
    _AppLoggerImpl._clearLogs();
  }

  // Logging methods
  void verbose(String message, {Object? error, StackTrace? stackTrace});
  void debug(String message, {Object? error, StackTrace? stackTrace});
  void info(String message, {Object? error, StackTrace? stackTrace});
  void warning(String message, {Object? error, StackTrace? stackTrace});
  void error(String message, {required Object error, StackTrace? stackTrace});
  void fatal(String message, {required Object error, StackTrace? stackTrace});
}

// ═══════════════════════════════════════════════════════════════════════════
// IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════════

class _AppLoggerImpl implements AppLogger {
  final pkg.Logger _logger;
  // ignore: unused_field
  final String _tag;

  // Static storage for log history (for MCP exposure)
  static final Queue<LogEntry> _logHistory = Queue<LogEntry>();
  static const int _maxLogHistory = 10000; // Keep last 10k logs in memory

  // Stream controller for real-time log streaming
  static final StreamController<LogEntry> _logStreamController =
      StreamController<LogEntry>.broadcast();

  // ignore: unused_field
  static LogLevel _minLevel = LogLevel.debug;
  static bool _initialized = false;

  _AppLoggerImpl(this._tag) : _logger = pkg.Logger(_tag) {
    if (!_initialized) {
      _initialize(minLevel: LogLevel.debug);
    }
  }

  static void _initialize({required LogLevel minLevel}) {
    if (_initialized) return;

    _minLevel = minLevel;

    // Configure hierarchical logging
    pkg.hierarchicalLoggingEnabled = true;
    pkg.Logger.root.level = minLevel.toPackageLevel();

    // Listen to all log records
    pkg.Logger.root.onRecord.listen((record) {
      final entry = LogEntry(
        timestamp: record.time,
        level: LogLevel.fromPackageLevel(record.level),
        tag: record.loggerName,
        message: record.message,
        error: record.error?.toString(),
        stackTrace: record.stackTrace?.toString(),
      );

      // Add to history (with circular buffer behavior)
      _logHistory.add(entry);
      if (_logHistory.length > _maxLogHistory) {
        _logHistory.removeFirst();
      }

      // Emit to stream
      _logStreamController.add(entry);

      // Print to console in debug mode
      if (kDebugMode) {
        _printToConsole(entry);
      }
    });

    _initialized = true;
  }

  static void _printToConsole(LogEntry entry) {
    // Use ANSI colors for terminal output
    const reset = '\x1B[0m';
    const grey = '\x1B[90m';
    const blue = '\x1B[34m';
    const green = '\x1B[32m';
    const yellow = '\x1B[33m';
    const red = '\x1B[31m';
    const magenta = '\x1B[35m';

    String color;
    String emoji;

    switch (entry.level) {
      case LogLevel.verbose:
        color = grey;
        emoji = '🔍';
        break;
      case LogLevel.debug:
        color = blue;
        emoji = '🐛';
        break;
      case LogLevel.info:
        color = green;
        emoji = 'ℹ️';
        break;
      case LogLevel.warning:
        color = yellow;
        emoji = '⚠️';
        break;
      case LogLevel.error:
        color = red;
        emoji = '❌';
        break;
      case LogLevel.fatal:
        color = magenta;
        emoji = '💀';
        break;
    }

    final timestamp = entry.timestamp.toIso8601String().substring(
      11,
      23,
    ); // HH:mm:ss.SSS
    final levelStr = entry.level.name.toUpperCase().padRight(7);

    debugPrint(
      '$color$emoji [$timestamp] [$levelStr] [${entry.tag}] ${entry.message}$reset',
    );

    if (entry.error != null) {
      debugPrint('$red   ↳ Error: ${entry.error}$reset');
    }

    if (entry.stackTrace != null) {
      final lines = entry.stackTrace!.split('\n').take(5); // First 5 lines only
      for (final line in lines) {
        debugPrint('$grey   $line$reset');
      }
    }
  }

  static Future<List<LogEntry>> _getLogs({
    DateTime? since,
    LogLevel? minLevel,
    String? tag,
    String? searchTerm,
    int? limit,
  }) async {
    var filtered = _logHistory.where((entry) {
      // Filter by timestamp
      if (since != null && entry.timestamp.isBefore(since)) {
        return false;
      }

      // Filter by level
      if (minLevel != null && entry.level.index < minLevel.index) {
        return false;
      }

      // Filter by tag
      if (tag != null && !entry.tag.contains(tag)) {
        return false;
      }

      // Filter by search term
      if (searchTerm != null &&
          !entry.message.toLowerCase().contains(searchTerm.toLowerCase()) &&
          (entry.error == null ||
              !entry.error!.toLowerCase().contains(searchTerm.toLowerCase()))) {
        return false;
      }

      return true;
    }).toList();

    // Apply limit
    if (limit != null && filtered.length > limit) {
      filtered = filtered.skip(filtered.length - limit).toList();
    }

    return filtered;
  }

  static Stream<LogEntry> _streamLogs({LogLevel? minLevel, String? tag}) {
    return _logStreamController.stream.where((entry) {
      if (minLevel != null && entry.level.index < minLevel.index) {
        return false;
      }
      if (tag != null && !entry.tag.contains(tag)) {
        return false;
      }
      return true;
    });
  }

  static void _clearLogs() {
    _logHistory.clear();
  }

  void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.log(level.toPackageLevel(), message, error, stackTrace);
  }

  @override
  void verbose(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.verbose, message, error: error, stackTrace: stackTrace);
  }

  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, error: error, stackTrace: stackTrace);
  }

  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, error: error, stackTrace: stackTrace);
  }

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, error: error, stackTrace: stackTrace);
  }

  @override
  void error(String message, {required Object error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }

  @override
  void fatal(String message, {required Object error, StackTrace? stackTrace}) {
    _log(LogLevel.fatal, message, error: error, stackTrace: stackTrace);
  }
}
