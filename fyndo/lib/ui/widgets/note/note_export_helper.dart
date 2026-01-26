// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Note Export Helper - Export Notes as Markdown
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

/// Helper class for exporting notes.
class NoteExportHelper {
  /// Exports note as markdown file.
  static Future<void> exportAsMarkdown({
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    final markdown = _convertToMarkdown(
      title: title,
      content: content,
      tags: tags,
    );

    final filename = _sanitizeFilename(title);

    if (kIsWeb) {
      // For web, use share or download
      await Share.share(markdown, subject: '$filename.md');
    } else {
      // For mobile/desktop, share as file
      await Share.share(markdown, subject: filename);
    }
  }

  /// Converts note content to markdown format.
  static String _convertToMarkdown({
    required String title,
    required String content,
    List<String> tags = const [],
  }) {
    final buffer = StringBuffer();

    // Title
    buffer.writeln('# $title');
    buffer.writeln();

    // Tags as badges
    if (tags.isNotEmpty) {
      buffer.write('Tags: ');
      buffer.writeln(tags.map((t) => '`$t`').join(' '));
      buffer.writeln();
    }

    // Separator
    buffer.writeln('---');
    buffer.writeln();

    // Content - try to parse as Quill Delta and convert
    String plainContent;
    try {
      final delta = jsonDecode(content);
      if (delta is List) {
        plainContent = _deltaToMarkdown(delta);
      } else {
        plainContent = content;
      }
    } catch (_) {
      plainContent = content;
    }

    buffer.writeln(plainContent);

    return buffer.toString();
  }

  /// Converts Quill Delta to markdown.
  static String _deltaToMarkdown(List<dynamic> ops) {
    final buffer = StringBuffer();

    for (final op in ops) {
      if (op is Map<String, dynamic>) {
        final insert = op['insert'];
        final attributes = op['attributes'] as Map<String, dynamic>?;

        if (insert is String) {
          var text = insert;

          // Apply formatting
          if (attributes != null) {
            if (attributes['bold'] == true) {
              text = '**$text**';
            }
            if (attributes['italic'] == true) {
              text = '*$text*';
            }
            if (attributes['code'] == true) {
              text = '`$text`';
            }
            if (attributes['strike'] == true) {
              text = '~~$text~~';
            }
            if (attributes['link'] != null) {
              text = '[$text](${attributes['link']})';
            }
            if (attributes['header'] != null) {
              final level = attributes['header'] as int;
              text = '${'#' * level} $text';
            }
            if (attributes['list'] == 'bullet') {
              text = '- $text';
            }
            if (attributes['list'] == 'ordered') {
              text = '1. $text';
            }
            if (attributes['blockquote'] == true) {
              text = '> $text';
            }
            if (attributes['code-block'] == true) {
              text = '```\n$text\n```';
            }
          }

          buffer.write(text);
        }
      }
    }

    return buffer.toString();
  }

  /// Sanitizes filename for export.
  static String _sanitizeFilename(String title) {
    if (title.isEmpty) {
      return 'untitled';
    }

    return title
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase()
        .substring(0, title.length > 50 ? 50 : title.length);
  }
}
