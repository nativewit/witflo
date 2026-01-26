// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// HTTP Sync Backend - Generic REST API Sync
// ═══════════════════════════════════════════════════════════════════════════
//
// This backend syncs encrypted operations via a generic HTTP/REST API.
// It can be used with any server that implements the Fyndo sync protocol.
//
// PROTOCOL:
// All endpoints receive/return encrypted data. The server NEVER sees plaintext.
//
// ENDPOINTS:
// POST   /vaults/{vaultId}/operations      - Push operations
// GET    /vaults/{vaultId}/operations      - Pull operations (with cursor)
// POST   /vaults/{vaultId}/blobs/{blobId}  - Upload blob
// GET    /vaults/{vaultId}/blobs/{blobId}  - Download blob
// HEAD   /vaults/{vaultId}/blobs/{blobId}  - Check blob exists
// DELETE /vaults/{vaultId}/blobs/{blobId}  - Delete blob
//
// AUTHENTICATION:
// Uses bearer token authentication. Token is provided by user/app.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:fyndo_app/core/sync/sync_backend.dart';
import 'package:fyndo_app/core/sync/sync_operation.dart';

/// Configuration for HTTP sync backend.
class HttpSyncConfig implements SyncBackendConfig {
  /// Base URL of the sync server.
  final String baseUrl;

  /// Bearer token for authentication.
  final String? authToken;

  /// Custom headers to include in all requests.
  final Map<String, String> customHeaders;

  /// Request timeout in seconds.
  final int timeoutSeconds;

  HttpSyncConfig({
    required this.baseUrl,
    this.authToken,
    this.customHeaders = const {},
    this.timeoutSeconds = 30,
  });

  @override
  String get backendType => 'http';

  @override
  String get displayName => 'HTTP Server';

  @override
  bool get isAvailable => baseUrl.isNotEmpty;

  @override
  Map<String, dynamic> toJson() => {
        'type': backendType,
        'base_url': baseUrl,
        'auth_token': authToken,
        'custom_headers': customHeaders,
        'timeout_seconds': timeoutSeconds,
      };

  factory HttpSyncConfig.fromJson(Map<String, dynamic> json) {
    return HttpSyncConfig(
      baseUrl: json['base_url'] as String,
      authToken: json['auth_token'] as String?,
      customHeaders:
          (json['custom_headers'] as Map<String, dynamic>?)?.cast<String, String>() ??
              {},
      timeoutSeconds: json['timeout_seconds'] as int? ?? 30,
    );
  }

  /// Creates a copy with updated values.
  HttpSyncConfig copyWith({
    String? baseUrl,
    String? authToken,
    Map<String, String>? customHeaders,
    int? timeoutSeconds,
  }) {
    return HttpSyncConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      authToken: authToken ?? this.authToken,
      customHeaders: customHeaders ?? this.customHeaders,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
    );
  }
}

/// HTTP sync backend for generic REST API servers.
///
/// This is a stub implementation that can be extended for any
/// HTTP-based sync server that implements the Fyndo protocol.
class HttpSyncBackend implements SyncBackend {
  final HttpSyncConfig _config;
  final http.Client _client;
  bool _isConnected = false;

  HttpSyncBackend(this._config, {http.Client? client})
      : _client = client ?? http.Client();

  @override
  SyncBackendConfig get config => _config;

  @override
  bool get isConnected => _isConnected;

  /// Build headers for requests.
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ..._config.customHeaders,
    };

    if (_config.authToken != null) {
      headers['Authorization'] = 'Bearer ${_config.authToken}';
    }

    return headers;
  }

  /// Build URL for an endpoint.
  Uri _buildUrl(String path, [Map<String, String>? queryParams]) {
    final baseUri = Uri.parse(_config.baseUrl);
    return baseUri.replace(
      path: '${baseUri.path}$path',
      queryParameters: queryParams,
    );
  }

  @override
  Future<void> initialize() async {
    // Test connection by checking server health
    try {
      final response = await _client
          .get(
            _buildUrl('/health'),
            headers: _headers,
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));

      _isConnected = response.statusCode == 200;
    } catch (e) {
      _isConnected = false;
      // Don't throw - we might be offline, that's OK
    }
  }

  @override
  Future<void> dispose() async {
    _client.close();
    _isConnected = false;
  }

  @override
  Future<SyncPushResult> pushOperations({
    required String vaultId,
    required List<EncryptedSyncOp> operations,
  }) async {
    if (operations.isEmpty) {
      return SyncPushResult.success(0);
    }

    try {
      final body = jsonEncode({
        'operations': operations.map((op) => op.toFirestoreDoc()).toList(),
      });

      final response = await _client
          .post(
            _buildUrl('/vaults/$vaultId/operations'),
            headers: _headers,
            body: body,
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isConnected = true;
        return SyncPushResult.success(operations.length);
      } else {
        return SyncPushResult.failure(
          'Server returned ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      _isConnected = false;
      return SyncPushResult.failure('Network error: $e');
    }
  }

  @override
  Future<SyncPullResult> pullOperations({
    required String vaultId,
    String? cursor,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      if (cursor != null) {
        queryParams['cursor'] = cursor;
      }

      final response = await _client
          .get(
            _buildUrl('/vaults/$vaultId/operations', queryParams),
            headers: _headers,
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));

      if (response.statusCode == 200) {
        _isConnected = true;
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final opsJson = json['operations'] as List<dynamic>;
        final operations = opsJson
            .map((op) => EncryptedSyncOp.fromFirestoreDoc(
                op as Map<String, dynamic>))
            .toList();
        final newCursor = json['cursor'] as String?;

        return SyncPullResult.success(operations, cursor: newCursor);
      } else {
        return SyncPullResult.failure(
          'Server returned ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      _isConnected = false;
      return SyncPullResult.failure('Network error: $e');
    }
  }

  @override
  Future<String?> uploadBlob({
    required String vaultId,
    required String blobId,
    required Uint8List data,
  }) async {
    try {
      final response = await _client
          .post(
            _buildUrl('/vaults/$vaultId/blobs/$blobId'),
            headers: {
              ..._headers,
              'Content-Type': 'application/octet-stream',
            },
            body: data,
          )
          .timeout(Duration(seconds: _config.timeoutSeconds * 2));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isConnected = true;
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['url'] as String?;
      }
      return null;
    } catch (e) {
      _isConnected = false;
      return null;
    }
  }

  @override
  Future<Uint8List?> downloadBlob({
    required String vaultId,
    required String blobId,
  }) async {
    try {
      final response = await _client
          .get(
            _buildUrl('/vaults/$vaultId/blobs/$blobId'),
            headers: _headers,
          )
          .timeout(Duration(seconds: _config.timeoutSeconds * 2));

      if (response.statusCode == 200) {
        _isConnected = true;
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      _isConnected = false;
      return null;
    }
  }

  @override
  Future<bool> blobExists({
    required String vaultId,
    required String blobId,
  }) async {
    try {
      final response = await _client
          .head(
            _buildUrl('/vaults/$vaultId/blobs/$blobId'),
            headers: _headers,
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));

      _isConnected = true;
      return response.statusCode == 200;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  @override
  Future<bool> deleteBlob({
    required String vaultId,
    required String blobId,
  }) async {
    try {
      final response = await _client
          .delete(
            _buildUrl('/vaults/$vaultId/blobs/$blobId'),
            headers: _headers,
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));

      _isConnected = true;
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  @override
  Future<SyncBackendStatus> getStatus() async {
    try {
      final response = await _client
          .get(
            _buildUrl('/health'),
            headers: _headers,
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));

      if (response.statusCode == 200) {
        _isConnected = true;
        return SyncBackendStatus.connected();
      }
      return SyncBackendStatus.disconnected();
    } catch (e) {
      _isConnected = false;
      return SyncBackendStatus(
        isConnected: false,
        isAuthenticated: false,
        error: e.toString(),
      );
    }
  }
}

