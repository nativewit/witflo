// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Notebook Consumer - Wrapper for Notebook State
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/providers/notebook_providers.dart';

/// Consumer widget for notebooks state.
class NotebookConsumer extends ConsumerWidget {
  /// Builder function called with notebooks state.
  final Widget Function(
    BuildContext context,
    AsyncValue<NotebooksState> state,
    Widget? child,
  )
  builder;

  /// Optional child widget.
  final Widget? child;

  const NotebookConsumer({super.key, required this.builder, this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notebooksProvider);
    return builder(context, state, child);
  }
}

/// Consumer for active notebooks list.
class ActiveNotebooksConsumer extends ConsumerWidget {
  /// Builder function called with notebooks list.
  final Widget Function(
    BuildContext context,
    List<Notebook> notebooks,
    Widget? child,
  )
  builder;

  /// Optional child widget.
  final Widget? child;

  const ActiveNotebooksConsumer({super.key, required this.builder, this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notebooks = ref.watch(activeNotebooksProvider);
    return builder(context, notebooks, child);
  }
}

/// Consumer for a single notebook.
class SingleNotebookConsumer extends ConsumerWidget {
  /// Notebook ID to watch.
  final String notebookId;

  /// Builder function called with notebook.
  final Widget Function(BuildContext context, Notebook? notebook, Widget? child)
  builder;

  /// Optional child widget.
  final Widget? child;

  const SingleNotebookConsumer({
    super.key,
    required this.notebookId,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notebook = ref.watch(notebookProvider(notebookId));
    return builder(context, notebook, child);
  }
}
