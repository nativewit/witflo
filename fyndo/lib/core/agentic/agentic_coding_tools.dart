// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Agentic Coding Tools - Centralized AI Development Support
// ═══════════════════════════════════════════════════════════════════════════
//
// OVERVIEW:
// This file centralizes all AI-powered development tooling for Fyndo:
// - Marionette MCP: UI testing, screenshots, element detection
// - MCP Toolkit: Flutter-specific testing capabilities
// - Custom Fyndo MCP Tools: Domain-specific inspection (vaults, crypto, db)
//
// USAGE:
// Wrap your app with AgenticCodingTools in main.dart (debug mode only):
//
// ```dart
// runApp(
//   AgenticCodingTools(
//     child: ProviderScope(child: FyndoApp()),
//   ),
// );
// ```
//
// MARIONETTE ELEMENT DETECTION:
// All interactive elements should have unique keys for reliable detection.
// Use the pattern: Key('feature_action') - e.g., Key('vault_create')
//
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:mcp_toolkit/mcp_toolkit.dart';
import 'package:fyndo_app/core/mcp/fyndo_mcp_tools.dart';

/// Wrapper widget that initializes all agentic coding tools.
/// Only active in debug mode - has zero impact on production builds.
class AgenticCodingTools extends StatefulWidget {
  final Widget child;

  const AgenticCodingTools({required this.child, super.key});

  @override
  State<AgenticCodingTools> createState() => _AgenticCodingToolsState();

  /// Initialize all agentic coding tools.
  /// Call this from main() before runApp().
  static Future<void> initialize() async {
    if (!kDebugMode) {
      // In release mode, just initialize the standard Flutter binding
      WidgetsFlutterBinding.ensureInitialized();
      return;
    }

    // Initialize Marionette binding for UI testing
    MarionetteBinding.ensureInitialized(
      MarionetteConfiguration(
        // Custom widget detection for Fyndo components
        // TODO: Uncomment when Fyndo design system is created
        // isInteractiveWidget: (type) =>
        //     type == FyndoButton ||
        //     type == FyndoTextField ||
        //     type == FyndoCard ||
        //     type == FyndoIconButton,
        //
        // extractText: (widget) {
        //   if (widget is FyndoText) return widget.data;
        //   if (widget is FyndoTextField) return widget.controller?.text;
        //   if (widget is FyndoButton) return widget.label;
        //   return null;
        // },

        // Screenshot configuration
        maxScreenshotSize: const Size(2000, 2000),
      ),
    );

    // Initialize MCP Toolkit for Flutter-specific testing
    MCPToolkitBinding.instance
      ..initialize()
      ..initializeFlutterToolkit();

    // Register custom Fyndo MCP tools
    initializeFyndoMCPTools();

    debugPrint('✅ Agentic Coding Tools initialized');
    debugPrint('   - Marionette MCP: UI testing & screenshots');
    debugPrint('   - MCP Toolkit: Flutter testing tools (3 tools)');
    debugPrint('   - Fyndo MCP Tools: Domain-specific inspection (6 tools)');
    debugPrint('   - Total: 9+ MCP tools available');
  }
}

class _AgenticCodingToolsState extends State<AgenticCodingTools> {
  @override
  void initState() {
    super.initState();

    if (kDebugMode) {
      // Set provider container for MCP tools after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          // Get the ProviderScope container if the child is wrapped in one
          final container = ProviderScope.containerOf(context);
          setMCPProviderContainer(container);
          debugPrint('✅ MCP Provider Container connected');
        } catch (e) {
          debugPrint('⚠️ No ProviderScope found - MCP tools will use defaults');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // In release mode, just return the child
    if (!kDebugMode) {
      return widget.child;
    }

    // In debug mode, return child as-is (MCP tools are already initialized)
    return widget.child;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// KEY NAMING CONVENTIONS FOR MARIONETTE
// ═══════════════════════════════════════════════════════════════════════════
//
// Use consistent, descriptive keys for all interactive elements:
//
// PATTERN: Key('<feature>_<action>')
//
// EXAMPLES:
// - Navigation:     Key('nav_vaults'), Key('nav_settings')
// - Creation:       Key('vault_create'), Key('note_create')
// - Actions:        Key('note_save'), Key('vault_unlock')
// - Input fields:   Key('input_vault_name'), Key('input_password')
// - Buttons:        Key('btn_submit'), Key('btn_cancel')
// - Lists:          Key('list_vaults'), Key('list_notes')
// - List items:     Key('vault_item_<id>'), Key('note_item_<id>')
//
// BENEFITS:
// - AI agents can reliably find and interact with elements
// - Easy to search for keys in codebase
// - Consistent naming aids debugging
// - No collisions between different features
//
// ═══════════════════════════════════════════════════════════════════════════
