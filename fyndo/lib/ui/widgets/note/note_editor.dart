// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Note Editor - Quill-based Rich Text Editor
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:fyndo_app/ui/theme/fyndo_colors.dart';
import 'package:fyndo_app/ui/theme/fyndo_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// A rich text editor using Quill.
class NoteEditor extends StatefulWidget {
  /// Initial content in Quill Delta JSON format.
  final String? initialContent;

  /// Callback when content changes.
  final ValueChanged<String>? onContentChanged;

  /// Whether editor is read-only.
  final bool readOnly;

  /// Whether to show toolbar.
  final bool showToolbar;

  /// Focus node.
  final FocusNode? focusNode;

  /// Whether to autofocus.
  final bool autofocus;

  /// Placeholder text.
  final String? placeholder;

  const NoteEditor({
    super.key,
    this.initialContent,
    this.onContentChanged,
    this.readOnly = false,
    this.showToolbar = true,
    this.focusNode,
    this.autofocus = false,
    this.placeholder,
  });

  @override
  State<NoteEditor> createState() => NoteEditorState();
}

class NoteEditorState extends State<NoteEditor> {
  late QuillController _controller;
  late FocusNode _focusNode;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _scrollController = ScrollController();
    _initController();
  }

  void _initController() {
    Document document;

    if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
      try {
        final json = jsonDecode(widget.initialContent!);
        document = Document.fromJson(json);
      } catch (_) {
        // If parsing fails, create document from plain text
        document = Document()..insert(0, widget.initialContent!);
      }
    } else {
      document = Document();
    }

    _controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: widget.readOnly,
    );

    _controller.document.changes.listen((_) {
      _notifyContentChanged();
    });
  }

  void _notifyContentChanged() {
    if (widget.onContentChanged != null) {
      final json = jsonEncode(_controller.document.toDelta().toJson());
      widget.onContentChanged!(json);
    }
  }

  /// Gets the current content as Quill Delta JSON.
  String getContent() {
    return jsonEncode(_controller.document.toDelta().toJson());
  }

  /// Gets the current content as plain text.
  String getPlainText() {
    return _controller.document.toPlainText();
  }

  /// Gets the current content as markdown.
  String getMarkdown() {
    // Simple conversion - for full markdown, use a proper converter
    final plainText = _controller.document.toPlainText();
    return plainText;
  }

  /// Sets the content from Quill Delta JSON.
  void setContent(String json) {
    try {
      final delta = jsonDecode(json);
      _controller.document = Document.fromJson(delta);
    } catch (_) {
      // Ignore parse errors
    }
  }

  /// Clears the editor content.
  void clear() {
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        if (widget.showToolbar && !widget.readOnly)
          _buildToolbar(theme, isDark),
        Expanded(
          child: Container(
            color: theme.scaffoldBackgroundColor,
            child: QuillEditor(
              controller: _controller,
              focusNode: _focusNode,
              scrollController: _scrollController,
              config: QuillEditorConfig(
                autoFocus: widget.autofocus,
                placeholder: widget.placeholder ?? 'Start writing...',
                padding: const EdgeInsets.all(FyndoTheme.padding),
                expands: true,
                customStyles: _buildStyles(theme, isDark),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: QuillSimpleToolbar(
        controller: _controller,
        config: QuillSimpleToolbarConfig(
          showDividers: true,
          showFontFamily: false,
          showFontSize: false,
          showBoldButton: true,
          showItalicButton: true,
          showUnderLineButton: true,
          showStrikeThrough: true,
          showInlineCode: true,
          showColorButton: true,
          showBackgroundColorButton: true,
          showClearFormat: true,
          showAlignmentButtons: false,
          showHeaderStyle: true,
          showListNumbers: true,
          showListBullets: true,
          showListCheck: true,
          showCodeBlock: true,
          showQuote: true,
          showIndent: false,
          showLink: true,
          showUndo: true,
          showRedo: true,
          showSearchButton: false,
          showSubscript: false,
          showSuperscript: false,
          buttonOptions: QuillSimpleToolbarButtonOptions(
            base: QuillToolbarBaseButtonOptions(
              iconTheme: QuillIconTheme(
                iconButtonSelectedData: IconButtonData(
                  color: theme.colorScheme.primary,
                ),
                iconButtonUnselectedData: IconButtonData(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  DefaultStyles _buildStyles(ThemeData theme, bool isDark) {
    final baseStyle = GoogleFonts.nunito(
      fontSize: 16,
      height: 1.6,
      color: theme.colorScheme.onSurface,
    );

    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        baseStyle,
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 8),
        const VerticalSpacing(0, 0),
        null,
      ),
      h1: DefaultTextBlockStyle(
        baseStyle.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(16, 8),
        const VerticalSpacing(0, 0),
        null,
      ),
      h2: DefaultTextBlockStyle(
        baseStyle.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(12, 8),
        const VerticalSpacing(0, 0),
        null,
      ),
      h3: DefaultTextBlockStyle(
        baseStyle.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(8, 8),
        const VerticalSpacing(0, 0),
        null,
      ),
      bold: const TextStyle(fontWeight: FontWeight.w700),
      italic: const TextStyle(fontStyle: FontStyle.italic),
      underline: const TextStyle(decoration: TextDecoration.underline),
      strikeThrough: const TextStyle(decoration: TextDecoration.lineThrough),
      inlineCode: InlineCodeStyle(
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: theme.colorScheme.onSurface,
          backgroundColor: isDark
              ? FyndoColors.darkSurfaceElevated
              : FyndoColors.paleGray,
        ),
      ),
      code: DefaultTextBlockStyle(
        TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          height: 1.5,
          color: theme.colorScheme.onSurface,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(8, 8),
        const VerticalSpacing(0, 0),
        BoxDecoration(
          color: isDark
              ? FyndoColors.darkSurfaceElevated
              : FyndoColors.paleGray,
          border: Border.all(color: theme.dividerColor),
        ),
      ),
      quote: DefaultTextBlockStyle(
        baseStyle.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(8, 8),
        const VerticalSpacing(0, 0),
        BoxDecoration(
          border: Border(
            left: BorderSide(color: theme.colorScheme.primary, width: 3),
          ),
        ),
      ),
      lists: DefaultListBlockStyle(
        baseStyle,
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 8),
        const VerticalSpacing(0, 0),
        null,
        null,
      ),
      link: TextStyle(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      placeHolder: DefaultTextBlockStyle(
        baseStyle.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
    );
  }
}
