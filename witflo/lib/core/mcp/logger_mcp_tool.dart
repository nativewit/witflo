// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Logger MCP Tool - Expose logs for AI agent debugging
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:witflo_app/core/logging/app_logger.dart';

/// MCP tool for exposing application logs to AI agents.
///
/// Provides two main capabilities:
/// 1. Query historical logs with filters
/// 2. Stream real-time logs
class LoggerMcpTool {
  /// Get logs with filtering (for historical queries)
  ///
  /// Parameters:
  /// - since: ISO 8601 timestamp to filter logs after
  /// - minLevel: Minimum log level (verbose, debug, info, warning, error, fatal)
  /// - tag: Filter by logger tag (contains match)
  /// - search: Search term in message or error
  /// - limit: Maximum number of logs to return (default: 100)
  ///
  /// Returns:
  /// ```json
  /// {
  ///   "success": true,
  ///   "count": 15,
  ///   "logs": [
  ///     {
  ///       "timestamp": "2026-02-01T10:30:45.123",
  ///       "level": "error",
  ///       "tag": "NoteService",
  ///       "message": "Failed to create note",
  ///       "error": "Database locked",
  ///       "stackTrace": "..."
  ///     }
  ///   ]
  /// }
  /// ```
  static Future<Map<String, dynamic>> getLogs(
    Map<String, dynamic> params,
  ) async {
    try {
      final since = params['since'] != null
          ? DateTime.parse(params['since'] as String)
          : null;
      final minLevel = params['minLevel'] != null
          ? LogLevel.values.byName(params['minLevel'] as String)
          : null;
      final tag = params['tag'] as String?;
      final searchTerm = params['search'] as String?;
      final limit = params['limit'] as int? ?? 100;

      final logs = await AppLogger.getLogs(
        since: since,
        minLevel: minLevel,
        tag: tag,
        searchTerm: searchTerm,
        limit: limit,
      );

      return {
        'success': true,
        'count': logs.length,
        'logs': logs.map((e) => e.toJson()).toList(),
      };
    } catch (e, st) {
      return {
        'success': false,
        'error': e.toString(),
        'stackTrace': st.toString(),
      };
    }
  }

  /// Stream logs in real-time (for live debugging)
  ///
  /// Parameters:
  /// - minLevel: Minimum log level to stream
  /// - tag: Filter by logger tag
  ///
  /// Returns: Stream of log entry JSON objects
  static Stream<Map<String, dynamic>> streamLogs(
    Map<String, dynamic> params,
  ) async* {
    try {
      final minLevel = params['minLevel'] != null
          ? LogLevel.values.byName(params['minLevel'] as String)
          : null;
      final tag = params['tag'] as String?;

      final stream = AppLogger.streamLogs(minLevel: minLevel, tag: tag);

      await for (final entry in stream) {
        yield entry.toJson();
      }
    } catch (e, st) {
      yield {
        'success': false,
        'error': e.toString(),
        'stackTrace': st.toString(),
      };
    }
  }

  /// Clear all stored logs
  ///
  /// Returns:
  /// ```json
  /// {
  ///   "success": true,
  ///   "message": "Logs cleared"
  /// }
  /// ```
  static Future<Map<String, dynamic>> clearLogs(
    Map<String, dynamic> params,
  ) async {
    try {
      AppLogger.clearLogs();
      return {'success': true, 'message': 'Logs cleared'};
    } catch (e, st) {
      return {
        'success': false,
        'error': e.toString(),
        'stackTrace': st.toString(),
      };
    }
  }

  /// Get log statistics
  ///
  /// Returns:
  /// ```json
  /// {
  ///   "success": true,
  ///   "stats": {
  ///     "total": 1250,
  ///     "byLevel": {
  ///       "verbose": 500,
  ///       "debug": 400,
  ///       "info": 250,
  ///       "warning": 75,
  ///       "error": 20,
  ///       "fatal": 5
  ///     },
  ///     "last5Minutes": 45,
  ///     "last1Hour": 320
  ///   }
  /// }
  /// ```
  static Future<Map<String, dynamic>> getStats(
    Map<String, dynamic> params,
  ) async {
    try {
      final now = DateTime.now();
      final last5Min = now.subtract(const Duration(minutes: 5));
      final last1Hour = now.subtract(const Duration(hours: 1));

      final allLogs = await AppLogger.getLogs();

      final byLevel = <String, int>{};
      for (final level in LogLevel.values) {
        byLevel[level.name] = 0;
      }

      var last5MinCount = 0;
      var last1HourCount = 0;

      for (final log in allLogs) {
        byLevel[log.level.name] = (byLevel[log.level.name] ?? 0) + 1;

        if (log.timestamp.isAfter(last5Min)) {
          last5MinCount++;
        }
        if (log.timestamp.isAfter(last1Hour)) {
          last1HourCount++;
        }
      }

      return {
        'success': true,
        'stats': {
          'total': allLogs.length,
          'byLevel': byLevel,
          'last5Minutes': last5MinCount,
          'last1Hour': last1HourCount,
        },
      };
    } catch (e, st) {
      return {
        'success': false,
        'error': e.toString(),
        'stackTrace': st.toString(),
      };
    }
  }
}
