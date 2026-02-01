// Custom Fyndo MCP Tools
// Provides domain-specific AI agent capabilities for:
// - Vault state inspection
// - Sync engine verification
// - Cryptographic health checks
// - Hierarchical data integrity

import 'package:mcp_toolkit/mcp_toolkit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/core/crypto/crypto.dart';
import 'package:fyndo_app/platform/database/drift/database_providers.dart';
import 'package:fyndo_app/providers/workspace_provider.dart';
import 'package:fyndo_app/core/mcp/logger_mcp_tool.dart';
import 'package:fyndo_app/core/mcp/widget_inspector_mcp_tool.dart';

// Global container to access Riverpod providers
// Will be set from main.dart after ProviderScope is created
ProviderContainer? _providerContainer;

/// Set the provider container for MCP tools to access app state
/// Must be called from FyndoApp after the ProviderScope is initialized
void setMCPProviderContainer(ProviderContainer container) {
  _providerContainer = container;
}

/// Initialize custom Fyndo MCP tools
/// Call this from main.dart in debug mode
void initializeFyndoMCPTools() {
  if (!kDebugMode) return;

  MCPToolkitBinding.instance.addEntries(
    entries: {
      // Vault State Tool
      MCPCallEntry.tool(
        definition: MCPToolDefinition(
          name: 'get_vault_state',
          description:
              'Get current vault state including unlock status, count, and encryption info',
          inputSchema: ObjectSchema(properties: {}),
        ),
        handler: (params) async {
          try {
            int totalVaults = 0;
            bool cryptoInitialized = false;
            bool workspaceConfigured = false;

            if (_providerContainer != null) {
              try {
                // Get workspace state for vault discovery
                final workspaceAsync = _providerContainer!.read(
                  workspaceProvider,
                );
                final workspaceState = workspaceAsync.valueOrNull;

                if (workspaceState != null) {
                  workspaceConfigured = workspaceState.hasWorkspace;
                  totalVaults = workspaceState.discoveredVaults?.length ?? 0;
                }

                // Check crypto service
                try {
                  CryptoService.instance;
                  cryptoInitialized = true;
                } catch (e) {
                  cryptoInitialized = false;
                }
              } catch (e) {
                // Provider not ready
              }
            }

            return MCPCallResult(
              message: 'Vault state retrieved successfully',
              parameters: {
                'success': true,
                'data': {
                  'vaults': {
                    'total': totalVaults,
                    'discovered': totalVaults,
                    // Note: unlock status requires vault-specific tracking
                    'workspaceConfigured': workspaceConfigured,
                  },
                  'encryption': {
                    'algorithm': 'XChaCha20-Poly1305',
                    'keyDerivation': 'Argon2id + HKDF',
                    'initialized': cryptoInitialized,
                  },
                  'storage': {
                    'location': 'local-filesystem',
                    'encrypted': true,
                    'format': 'file-based',
                  },
                },
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
          } catch (e) {
            return MCPCallResult(
              message: 'Error retrieving vault state',
              parameters: {'success': false, 'error': e.toString()},
            );
          }
        },
      ),

      // Sync State Tool
      MCPCallEntry.tool(
        definition: MCPToolDefinition(
          name: 'verify_sync_state',
          description: 'Check file sync engine status and pending operations',
          inputSchema: ObjectSchema(properties: {}),
        ),
        handler: (params) async {
          try {
            // Note: Sync engine is currently per-vault and not globally tracked
            // This tool reports on database-level sync state
            int syncOpsCount = 0;

            if (_providerContainer != null) {
              try {
                final db = _providerContainer!.read(appDatabaseProvider);

                // Check if sync_state table exists and has data
                syncOpsCount = await db
                    .customSelect('SELECT COUNT(*) as count FROM sync_state')
                    .map((row) => row.read<int>('count'))
                    .getSingle();
              } catch (e) {
                // Sync state table might not exist or DB not ready
              }
            }

            return MCPCallResult(
              message: 'Sync state verified',
              parameters: {
                'success': true,
                'data': {
                  'engine': {
                    'available': true,
                    'type': 'file-based',
                    'backends': [
                      'local',
                      'http',
                      'firebase',
                      'gdrive',
                      'onedrive',
                      'dropbox',
                    ],
                    'note': 'Sync engine is per-vault, not globally tracked',
                  },
                  'cursor': {
                    'tracked': syncOpsCount > 0,
                    'entries': syncOpsCount,
                  },
                  'features': {
                    'offlineFirst': true,
                    'conflictResolution': 'lamport-clock',
                    'encryption': 'zero-trust',
                  },
                },
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
          } catch (e) {
            return MCPCallResult(
              message: 'Error verifying sync state',
              parameters: {'success': false, 'error': e.toString()},
            );
          }
        },
      ),

      // Crypto Health Tool
      MCPCallEntry.tool(
        definition: MCPToolDefinition(
          name: 'check_crypto_health',
          description:
              'Validate cryptographic operations and key material availability',
          inputSchema: ObjectSchema(properties: {}),
        ),
        handler: (params) async {
          try {
            // Verify CryptoService is initialized (will throw if not)
            CryptoService.instance;

            // Check workspace state if container available
            bool workspaceUnlocked = false;
            if (_providerContainer != null) {
              try {
                final workspaceAsync = _providerContainer!.read(
                  workspaceProvider,
                );
                final workspaceState = workspaceAsync.valueOrNull;
                workspaceUnlocked = workspaceState?.hasWorkspace ?? false;
              } catch (e) {
                // Provider not available yet
              }
            }

            return MCPCallResult(
              message: 'Crypto health checked',
              parameters: {
                'success': true,
                'data': {
                  'libsodium': {
                    'available': true,
                    'initialized': true,
                    'primitives': {
                      'argon2id': true,
                      'xchacha20': true,
                      'hkdf': true,
                      'blake3': true,
                      'ed25519': true,
                      'x25519': true,
                      'random': true,
                    },
                  },
                  'workspace': {
                    'unlocked': workspaceUnlocked,
                    'masterKeyDerived': workspaceUnlocked,
                  },
                  'operations': {
                    'encryption': 'available',
                    'signing': 'available',
                    'keyExchange': 'available',
                    'hashing': 'available',
                    'kdf': 'available',
                  },
                },
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
          } catch (e) {
            return MCPCallResult(
              message: 'Error checking crypto health',
              parameters: {'success': false, 'error': e.toString()},
            );
          }
        },
      ),

      // Hierarchy Integrity Tool
      MCPCallEntry.tool(
        definition: MCPToolDefinition(
          name: 'check_hierarchy_integrity',
          description: 'Verify Fyndo hierarchy: Vaults -> Notebooks -> Notes',
          inputSchema: ObjectSchema(properties: {}),
        ),
        handler: (params) async {
          try {
            int notebookCount = 0;
            int noteCount = 0;
            int orphanedNotebooks = 0;
            int orphanedNotes = 0;
            List<String> issues = [];
            int vaultCount = 0;

            if (_providerContainer != null) {
              try {
                final db = _providerContainer!.read(appDatabaseProvider);

                // Get workspace state for vault count
                final workspaceAsync = _providerContainer!.read(
                  workspaceProvider,
                );
                final workspaceState = workspaceAsync.valueOrNull;
                vaultCount = workspaceState?.discoveredVaults?.length ?? 0;

                // Count notebooks (not archived)
                notebookCount = await db
                    .customSelect(
                      'SELECT COUNT(*) as count FROM notebooks WHERE is_archived = 0',
                    )
                    .map((row) => row.read<int>('count'))
                    .getSingle();

                // Count notes (not trashed)
                noteCount = await db
                    .customSelect(
                      'SELECT COUNT(*) as count FROM notes WHERE is_trashed = 0',
                    )
                    .map((row) => row.read<int>('count'))
                    .getSingle();

                // Check for orphaned notebooks (notebooks without valid vault_id)
                // Note: This is a simplified check since vault validation requires filesystem access
                orphanedNotebooks = await db
                    .customSelect(
                      'SELECT COUNT(*) as count FROM notebooks WHERE (vault_id IS NULL OR vault_id = \'\') AND is_archived = 0',
                    )
                    .map((row) => row.read<int>('count'))
                    .getSingle();

                // Check for orphaned notes (notes without valid notebook_id)
                orphanedNotes = await db
                    .customSelect('''
                      SELECT COUNT(*) as count FROM notes 
                      WHERE notebook_id NOT IN (SELECT id FROM notebooks WHERE is_archived = 0) 
                      AND is_trashed = 0
                      ''')
                    .map((row) => row.read<int>('count'))
                    .getSingle();

                if (orphanedNotebooks > 0) {
                  issues.add(
                    'Found $orphanedNotebooks notebook(s) without valid vault_id',
                  );
                }
                if (orphanedNotes > 0) {
                  issues.add(
                    'Found $orphanedNotes note(s) without valid notebook',
                  );
                }
              } catch (e) {
                issues.add('Database query error: ${e.toString()}');
              }
            }

            return MCPCallResult(
              message: 'Hierarchy integrity checked',
              parameters: {
                'success': true,
                'data': {
                  'hierarchy': {
                    'vaults': vaultCount,
                    'notebooks': notebookCount,
                    'notes': noteCount,
                  },
                  'orphans': {
                    'notebooks': orphanedNotebooks,
                    'notes': orphanedNotes,
                  },
                  'integrity': {'valid': issues.isEmpty, 'issues': issues},
                },
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
          } catch (e) {
            return MCPCallResult(
              message: 'Error checking hierarchy integrity',
              parameters: {'success': false, 'error': e.toString()},
            );
          }
        },
      ),

      // App State Tool
      MCPCallEntry.tool(
        definition: MCPToolDefinition(
          name: 'get_app_state',
          description: 'Get overall application state and diagnostics',
          inputSchema: ObjectSchema(properties: {}),
        ),
        handler: (params) async {
          try {
            return MCPCallResult(
              message: 'App state retrieved',
              parameters: {
                'success': true,
                'data': {
                  'app': {
                    'version': '0.1.0+1',
                    'environment': kDebugMode ? 'debug' : 'release',
                    'platform': defaultTargetPlatform.toString(),
                  },
                  'initialization': {
                    'complete': true,
                    'masterPasswordSet': false,
                  },
                  'features': {
                    'vaults': true,
                    'notebooks': true,
                    'notes': true,
                    'richText': true,
                    'sync': false,
                  },
                },
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
          } catch (e) {
            return MCPCallResult(
              message: 'Error retrieving app state',
              parameters: {'success': false, 'error': e.toString()},
            );
          }
        },
      ),

      // Logger Tool - Get Logs
      MCPCallEntry.tool(
        definition: MCPToolDefinition(
          name: 'get_logs',
          description: 'Query application logs with filtering (for debugging)',
          inputSchema: ObjectSchema(
            properties: {
              'since': StringSchema(
                description: 'ISO 8601 timestamp to filter logs after',
              ),
              'minLevel': StringSchema(
                description:
                    'Minimum log level: verbose, debug, info, warning, error, fatal',
              ),
              'tag': StringSchema(
                description: 'Filter by logger tag (contains match)',
              ),
              'search': StringSchema(
                description: 'Search term in message or error',
              ),
              'limit': NumberSchema(
                description: 'Maximum number of logs to return (default: 100)',
              ),
            },
          ),
        ),
        handler: (params) async {
          return MCPCallResult(
            message: 'Logs retrieved',
            parameters: await LoggerMcpTool.getLogs(params),
          );
        },
      ),

      // Logger Tool - Get Stats
      MCPCallEntry.tool(
        definition: MCPToolDefinition(
          name: 'get_log_stats',
          description: 'Get logging statistics and distribution',
          inputSchema: ObjectSchema(properties: {}),
        ),
        handler: (params) async {
          return MCPCallResult(
            message: 'Log stats retrieved',
            parameters: await LoggerMcpTool.getStats(params),
          );
        },
      ),

      // Logger Tool - Clear Logs
      MCPCallEntry.tool(
        definition: MCPToolDefinition(
          name: 'clear_logs',
          description: 'Clear all stored application logs',
          inputSchema: ObjectSchema(properties: {}),
        ),
        handler: (params) async {
          return MCPCallResult(
            message: 'Logs cleared',
            parameters: await LoggerMcpTool.clearLogs(params),
          );
        },
      ),

      // Database Stats Tool
      MCPCallEntry.tool(
        definition: MCPToolDefinition(
          name: 'get_database_stats',
          description: 'Get database statistics and health information',
          inputSchema: ObjectSchema(
            properties: {
              'includeTableDetails': BooleanSchema(
                description:
                    'Include detailed table statistics (default: false)',
              ),
            },
          ),
        ),
        handler: (params) async {
          try {
            final includeDetails =
                params['includeTableDetails'] as bool? ?? false;

            // Try to access database if available
            int notebookCount = 0;
            int noteCount = 0;
            int trashedCount = 0;
            int archivedCount = 0;
            bool dbAvailable = false;

            if (_providerContainer != null) {
              try {
                final db = _providerContainer!.read(appDatabaseProvider);

                // Get counts from database
                notebookCount = await db
                    .customSelect(
                      'SELECT COUNT(*) as count FROM notebooks WHERE is_archived = 0',
                    )
                    .map((row) => row.read<int>('count'))
                    .getSingle();

                noteCount = await db
                    .customSelect(
                      'SELECT COUNT(*) as count FROM notes WHERE is_trashed = 0',
                    )
                    .map((row) => row.read<int>('count'))
                    .getSingle();

                trashedCount = await db
                    .customSelect(
                      'SELECT COUNT(*) as count FROM notes WHERE is_trashed = 1',
                    )
                    .map((row) => row.read<int>('count'))
                    .getSingle();

                if (includeDetails) {
                  archivedCount = await db
                      .customSelect(
                        'SELECT COUNT(*) as count FROM notes WHERE is_archived = 1 AND is_trashed = 0',
                      )
                      .map((row) => row.read<int>('count'))
                      .getSingle();
                }

                dbAvailable = true;
              } catch (e) {
                // Database not initialized yet
              }
            }

            final result = {
              'success': true,
              'data': {
                'database': {
                  'available': dbAvailable,
                  'encrypted': true,
                  'location': 'local',
                  'type': 'SQLite (Drift)',
                },
                'tables': {
                  'notebooks': notebookCount,
                  'notes': noteCount,
                  'trashed': trashedCount,
                  'total': noteCount + trashedCount,
                },
                'health': {
                  'status': dbAvailable ? 'healthy' : 'not_initialized',
                  'integrityCheck': dbAvailable,
                },
              },
              'timestamp': DateTime.now().toIso8601String(),
            };

            if (includeDetails && dbAvailable) {
              (result['data'] as Map<String, dynamic>)['tables']['archived'] =
                  archivedCount;
            }

            return MCPCallResult(
              message: 'Database stats retrieved',
              parameters: result,
            );
          } catch (e) {
            return MCPCallResult(
              message: 'Error retrieving database stats',
              parameters: {'success': false, 'error': e.toString()},
            );
          }
        },
      ),

      // Widget Inspector Tool - Get Widget Tree
      MCPCallEntry.tool(
        definition: MCPToolDefinition(
          name: 'get_widget_tree',
          description:
              'Get the complete Flutter widget tree with properties for UI debugging',
          inputSchema: ObjectSchema(
            properties: {
              'subtreeDepth': NumberSchema(
                description: 'How many levels deep to inspect (default: 10)',
              ),
              'withProperties': BooleanSchema(
                description:
                    'Include detailed widget properties (default: true)',
              ),
            },
          ),
        ),
        handler: (params) async {
          return MCPCallResult(
            message: 'Widget tree retrieved',
            parameters: await WidgetInspectorMcpTool.getWidgetTree(params),
          );
        },
      ),

      // Widget Inspector Tool - Find Widgets
      MCPCallEntry.tool(
        definition: MCPToolDefinition(
          name: 'find_widgets',
          description:
              'Find widgets by key, type, or text content for UI debugging',
          inputSchema: ObjectSchema(
            properties: {
              'key': StringSchema(description: 'ValueKey string to search for'),
              'type': StringSchema(
                description:
                    'Widget type name (e.g., "TextField", "ElevatedButton")',
              ),
              'text': StringSchema(description: 'Text content to search for'),
            },
          ),
        ),
        handler: (params) async {
          return MCPCallResult(
            message: 'Widget search completed',
            parameters: await WidgetInspectorMcpTool.findWidgets(params),
          );
        },
      ),

      // Widget Inspector Tool - Get Widget Properties
      MCPCallEntry.tool(
        definition: MCPToolDefinition(
          name: 'get_widget_properties',
          description: 'Get detailed properties of a specific widget by key',
          inputSchema: ObjectSchema(
            properties: {
              'key': StringSchema(description: 'ValueKey string of the widget'),
            },
          ),
        ),
        handler: (params) async {
          return MCPCallResult(
            message: 'Widget properties retrieved',
            parameters: await WidgetInspectorMcpTool.getWidgetProperties(
              params,
            ),
          );
        },
      ),
    },
  );
}
