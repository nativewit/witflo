// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Widget Inspector MCP Tool - Expose widget tree for AI agent debugging
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:isolate';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// MCP tool for exposing Flutter widget tree inspection to AI agents.
///
/// Provides capabilities to inspect widget properties, find widgets by key/type,
/// and debug UI state issues.
class WidgetInspectorMcpTool {
  /// Get the complete widget tree with detailed properties
  ///
  /// Parameters:
  /// - subtreeDepth: How many levels deep to inspect (default: 10)
  /// - withProperties: Include detailed widget properties (default: true)
  ///
  /// Returns:
  /// ```json
  /// {
  ///   "success": true,
  ///   "tree": {
  ///     "id": "widget-123",
  ///     "type": "MaterialApp",
  ///     "properties": {...},
  ///     "children": [...]
  ///   }
  /// }
  /// ```
  static Future<Map<String, dynamic>> getWidgetTree(
    Map<String, dynamic> params,
  ) async {
    if (!kDebugMode) {
      return {
        'success': false,
        'error': 'Widget inspector only available in debug mode',
      };
    }

    try {
      final subtreeDepth = params['subtreeDepth'] as int? ?? 10;
      final withProperties = params['withProperties'] as bool? ?? true;

      // Get the widget tree via WidgetInspectorService
      final service = developer.Service.getIsolateID(Isolate.current);
      if (service == null) {
        return {'success': false, 'error': 'Developer service not available'};
      }

      // Use the WidgetsBinding to get root widget
      final binding = WidgetsBinding.instance;
      final rootElement = binding.renderViewElement;

      if (rootElement == null) {
        return {
          'success': false,
          'error': 'No root element found - app not fully initialized',
        };
      }

      final tree = _inspectElement(
        rootElement,
        depth: subtreeDepth,
        includeProperties: withProperties,
      );

      return {
        'success': true,
        'tree': tree,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e, st) {
      return {
        'success': false,
        'error': e.toString(),
        'stackTrace': st.toString(),
      };
    }
  }

  /// Find widgets by key, type, or text content
  ///
  /// Parameters:
  /// - key: ValueKey string to search for
  /// - type: Widget type name (e.g., "TextField", "ElevatedButton")
  /// - text: Text content to search for
  ///
  /// Returns:
  /// ```json
  /// {
  ///   "success": true,
  ///   "matches": 3,
  ///   "widgets": [
  ///     {
  ///       "id": "widget-456",
  ///       "type": "TextField",
  ///       "key": "input_password",
  ///       "properties": {...}
  ///     }
  ///   ]
  /// }
  /// ```
  static Future<Map<String, dynamic>> findWidgets(
    Map<String, dynamic> params,
  ) async {
    if (!kDebugMode) {
      return {
        'success': false,
        'error': 'Widget inspector only available in debug mode',
      };
    }

    try {
      final key = params['key'] as String?;
      final type = params['type'] as String?;
      final text = params['text'] as String?;

      if (key == null && type == null && text == null) {
        return {
          'success': false,
          'error':
              'Must provide at least one search criterion: key, type, or text',
        };
      }

      final binding = WidgetsBinding.instance;
      final rootElement = binding.renderViewElement;

      if (rootElement == null) {
        return {'success': false, 'error': 'No root element found'};
      }

      final matches = <Map<String, dynamic>>[];
      _findMatchingWidgets(
        rootElement,
        key: key,
        type: type,
        text: text,
        matches: matches,
      );

      return {
        'success': true,
        'matches': matches.length,
        'widgets': matches,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e, st) {
      return {
        'success': false,
        'error': e.toString(),
        'stackTrace': st.toString(),
      };
    }
  }

  /// Get detailed properties of a specific widget
  ///
  /// Parameters:
  /// - key: ValueKey string of the widget
  ///
  /// Returns:
  /// ```json
  /// {
  ///   "success": true,
  ///   "widget": {
  ///     "type": "TextField",
  ///     "key": "input_password",
  ///     "properties": {
  ///       "enabled": true,
  ///       "obscureText": true,
  ///       "errorText": "Password incorrect",
  ///       "controller": {...}
  ///     }
  ///   }
  /// }
  /// ```
  static Future<Map<String, dynamic>> getWidgetProperties(
    Map<String, dynamic> params,
  ) async {
    if (!kDebugMode) {
      return {
        'success': false,
        'error': 'Widget inspector only available in debug mode',
      };
    }

    try {
      final key = params['key'] as String?;
      if (key == null) {
        return {'success': false, 'error': 'Widget key is required'};
      }

      final binding = WidgetsBinding.instance;
      final rootElement = binding.renderViewElement;

      if (rootElement == null) {
        return {'success': false, 'error': 'No root element found'};
      }

      final matches = <Map<String, dynamic>>[];
      _findMatchingWidgets(rootElement, key: key, matches: matches);

      if (matches.isEmpty) {
        return {'success': false, 'error': 'Widget with key "$key" not found'};
      }

      return {
        'success': true,
        'widget': matches.first,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e, st) {
      return {
        'success': false,
        'error': e.toString(),
        'stackTrace': st.toString(),
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  static Map<String, dynamic> _inspectElement(
    Element element, {
    required int depth,
    required bool includeProperties,
    int currentDepth = 0,
  }) {
    final widget = element.widget;
    final result = <String, dynamic>{
      'id': element.hashCode.toString(),
      'type': widget.runtimeType.toString(),
    };

    // Add key if present
    if (widget.key != null) {
      result['key'] = _extractKeyValue(widget.key!);
    }

    // Add properties if requested
    if (includeProperties) {
      result['properties'] = _extractWidgetProperties(widget);
    }

    // Recursively inspect children
    if (currentDepth < depth) {
      final children = <Map<String, dynamic>>[];
      element.visitChildren((child) {
        children.add(
          _inspectElement(
            child,
            depth: depth,
            includeProperties: includeProperties,
            currentDepth: currentDepth + 1,
          ),
        );
      });

      if (children.isNotEmpty) {
        result['children'] = children;
      }
    }

    return result;
  }

  static void _findMatchingWidgets(
    Element element, {
    String? key,
    String? type,
    String? text,
    required List<Map<String, dynamic>> matches,
  }) {
    final widget = element.widget;
    bool isMatch = true;

    // Check key match
    if (key != null) {
      final widgetKey = _extractKeyValue(widget.key);
      isMatch = isMatch && widgetKey == key;
    }

    // Check type match
    if (type != null) {
      isMatch = isMatch && widget.runtimeType.toString() == type;
    }

    // Check text match
    if (text != null) {
      final widgetText = _extractTextContent(widget);
      isMatch = isMatch && (widgetText?.contains(text) ?? false);
    }

    if (isMatch) {
      matches.add({
        'id': element.hashCode.toString(),
        'type': widget.runtimeType.toString(),
        'key': _extractKeyValue(widget.key),
        'properties': _extractWidgetProperties(widget),
      });
    }

    // Recursively search children
    element.visitChildren((child) {
      _findMatchingWidgets(
        child,
        key: key,
        type: type,
        text: text,
        matches: matches,
      );
    });
  }

  static String? _extractKeyValue(Key? key) {
    if (key == null) return null;
    if (key is ValueKey<String>) return key.value;
    if (key is ValueKey<int>) return key.value.toString();
    return key.toString();
  }

  static String? _extractTextContent(Widget widget) {
    if (widget is Text) {
      return widget.data ?? widget.textSpan?.toPlainText();
    }
    if (widget is TextField) {
      return widget.controller?.text;
    }
    if (widget is EditableText) {
      return widget.controller.text;
    }
    return null;
  }

  static Map<String, dynamic> _extractWidgetProperties(Widget widget) {
    final props = <String, dynamic>{};

    // Common properties
    if (widget is StatefulWidget) {
      props['stateful'] = true;
    } else if (widget is StatelessWidget) {
      props['stateless'] = true;
    }

    // Text widgets
    if (widget is Text) {
      props['text'] = widget.data ?? widget.textSpan?.toPlainText();
      props['textAlign'] = widget.textAlign?.toString();
      props['overflow'] = widget.overflow?.toString();
      props['maxLines'] = widget.maxLines;
    }

    // TextField
    if (widget is TextField) {
      props['enabled'] = widget.enabled;
      props['obscureText'] = widget.obscureText;
      props['maxLines'] = widget.maxLines;
      props['readOnly'] = widget.readOnly;
      props['controller_text'] = widget.controller?.text;

      // Check decoration for error text
      if (widget.decoration != null) {
        props['labelText'] = widget.decoration!.labelText;
        props['hintText'] = widget.decoration!.hintText;
        props['errorText'] = widget.decoration!.errorText;
        props['helperText'] = widget.decoration!.helperText;
        props['prefixText'] = widget.decoration!.prefixText;
        props['suffixText'] = widget.decoration!.suffixText;
      }
    }

    // Buttons
    if (widget is ElevatedButton ||
        widget is TextButton ||
        widget is OutlinedButton) {
      final button = widget as ButtonStyleButton;
      props['enabled'] = button.onPressed != null;
    }

    // Checkbox
    if (widget is Checkbox) {
      props['value'] = widget.value;
      props['enabled'] = widget.onChanged != null;
    }

    // Switch
    if (widget is Switch) {
      props['value'] = widget.value;
      props['enabled'] = widget.onChanged != null;
    }

    // Container
    if (widget is Container) {
      props['width'] = widget.constraints?.maxWidth;
      props['height'] = widget.constraints?.maxHeight;
      props['color'] = widget.color?.toString();
      props['padding'] = widget.padding?.toString();
      props['margin'] = widget.margin?.toString();
    }

    return props;
  }
}
