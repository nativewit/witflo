// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// App Router - Navigator 2.0 with go_router
// ═══════════════════════════════════════════════════════════════════════════
//
// ROUTE STRUCTURE:
// /                  - Welcome (unlock/create vault)
// /home              - Home page (vault overview)
// /vault/:id         - Vault settings
// /notebook/:id      - Notebook notes list
// /note/:id          - Note editor
// /notes             - All notes
// /notes/pinned      - Pinned notes
// /notes/archived    - Archived notes
// /trash             - Trash
// /settings          - Settings
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/features/notes/models/note.dart';
import 'package:fyndo_app/providers/note_providers.dart';
import 'package:fyndo_app/providers/vault_providers.dart';
import 'package:fyndo_app/ui/consumers/note_consumer.dart';
import 'package:fyndo_app/ui/pages/pages.dart';
import 'package:fyndo_app/ui/pages/onboarding/onboarding_wizard.dart';
import 'package:fyndo_app/ui/pages/settings/settings_page.dart';
import 'package:fyndo_app/providers/workspace_provider.dart';
import 'package:fyndo_app/ui/theme/fyndo_theme.dart';
import 'package:fyndo_app/ui/widgets/common/fyndo_app_bar.dart';
import 'package:fyndo_app/ui/widgets/common/fyndo_empty_state.dart';
import 'package:fyndo_app/ui/widgets/note/note_share_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// App router provider.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: _RouterRefreshNotifier(ref),
    redirect: (context, state) {
      final vaultState = ref.read(vaultProvider);
      final workspaceAsync = ref.read(workspaceProvider);

      final isOnWelcome = state.matchedLocation == '/';
      final isOnOnboarding = state.matchedLocation == '/onboarding';

      // Check if workspace is configured
      final hasWorkspace = workspaceAsync.when(
        data: (workspaceState) => workspaceState.hasWorkspace,
        loading: () => false,
        error: (error, stackTrace) => false,
      );

      // If no workspace configured and not on onboarding, redirect to onboarding
      if (!hasWorkspace && !isOnOnboarding) {
        return '/onboarding';
      }

      // If workspace configured but vault not unlocked and not on welcome/onboarding
      if (hasWorkspace &&
          !vaultState.isUnlocked &&
          !isOnWelcome &&
          !isOnOnboarding) {
        return '/';
      }

      // If vault is unlocked and on welcome, redirect to home
      if (vaultState.isUnlocked && isOnWelcome) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Onboarding - First-time workspace setup
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingWizard(),
      ),

      // Welcome / Unlock
      GoRoute(
        path: '/',
        name: 'welcome',
        builder: (context, state) => const WelcomePage(),
      ),

      // Home
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),

      // Vault settings
      GoRoute(
        path: '/vault/:id',
        name: 'vault',
        builder: (context, state) =>
            VaultPage(vaultId: state.pathParameters['id']),
      ),

      // Vault settings (default vault)
      GoRoute(
        path: '/vault',
        name: 'vault-settings',
        builder: (context, state) => const VaultPage(),
      ),

      // Notebook
      GoRoute(
        path: '/notebook/:id',
        name: 'notebook',
        builder: (context, state) =>
            NotebookPage(notebookId: state.pathParameters['id']!),
      ),

      // Note
      GoRoute(
        path: '/note/:id',
        name: 'note',
        builder: (context, state) =>
            NotePage(noteId: state.pathParameters['id']!),
      ),

      // All notes
      GoRoute(
        path: '/notes',
        name: 'notes',
        builder: (context, state) => const _AllNotesPage(),
        routes: [
          GoRoute(
            path: 'pinned',
            name: 'pinned-notes',
            builder: (context, state) => const _PinnedNotesPage(),
          ),
          GoRoute(
            path: 'archived',
            name: 'archived-notes',
            builder: (context, state) => const _ArchivedNotesPage(),
          ),
        ],
      ),

      // Trash
      GoRoute(
        path: '/trash',
        name: 'trash',
        builder: (context, state) => const _TrashPage(),
      ),

      // Settings
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(state.uri.toString()),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Router refresh notifier that listens to vault and workspace state changes.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this._ref) {
    _ref.listen(vaultProvider.select((s) => s.status), (previous, next) {
      notifyListeners();
    });
    _ref.listen(workspaceProvider, (previous, next) {
      notifyListeners();
    });
  }

  final Ref _ref;
}

// ═══════════════════════════════════════════════════════════════════════════
// NOTES LIST PAGES
// ═══════════════════════════════════════════════════════════════════════════

class _AllNotesPage extends ConsumerWidget {
  const _AllNotesPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const FyndoAppBar(title: FyndoAppBarTitle('All Notes')),
      body: ActiveNotesConsumer(
        builder: (context, notesAsync, _) {
          return notesAsync.when(
            data: (notes) => _NotesGridView(
              notes: notes,
              onNoteOptions: (note) => _showNoteOptions(context, ref, note),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNote(context, ref),
        tooltip: 'Create Note',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _createNote(BuildContext context, WidgetRef ref) async {
    try {
      final note = await ref
          .read(noteOperationsProvider.notifier)
          .createNote(title: '', content: '');
      if (context.mounted) {
        context.push('/note/${note.id}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create note: $e')));
      }
    }
  }

  void _showNoteOptions(
    BuildContext context,
    WidgetRef ref,
    NoteMetadata note,
  ) {
    _NoteOptionsSheet.show(context, ref, note);
  }
}

class _PinnedNotesPage extends ConsumerWidget {
  const _PinnedNotesPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const FyndoAppBar(title: FyndoAppBarTitle('Pinned Notes')),
      body: ActiveNotesConsumer(
        builder: (context, notesAsync, _) {
          return notesAsync.when(
            data: (notes) {
              final pinnedNotes = notes.where((n) => n.isPinned).toList();
              if (pinnedNotes.isEmpty) {
                return const FyndoEmptyState(
                  icon: Icons.push_pin_outlined,
                  title: 'No Pinned Notes',
                  description: 'Pin important notes to find them quickly.',
                );
              }
              return _NotesGridView(
                notes: pinnedNotes,
                onNoteOptions: (note) =>
                    _NoteOptionsSheet.show(context, ref, note),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          );
        },
      ),
    );
  }
}

class _ArchivedNotesPage extends ConsumerWidget {
  const _ArchivedNotesPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const FyndoAppBar(title: FyndoAppBarTitle('Archived Notes')),
      body: ArchivedNotesConsumer(
        builder: (context, notesAsync, _) {
          return notesAsync.when(
            data: (notes) {
              if (notes.isEmpty) {
                return const FyndoEmptyState(
                  icon: Icons.archive_outlined,
                  title: 'No Archived Notes',
                  description: 'Archived notes will appear here.',
                );
              }
              return _NotesGridView(
                notes: notes,
                onNoteOptions: (note) =>
                    _NoteOptionsSheet.show(context, ref, note),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          );
        },
      ),
    );
  }
}

class _TrashPage extends ConsumerWidget {
  const _TrashPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: FyndoAppBar(
        title: const FyndoAppBarTitle('Trash'),
        actions: [
          TextButton(
            onPressed: () => _emptyTrash(context, ref),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
      body: TrashedNotesConsumer(
        builder: (context, notesAsync, _) {
          return notesAsync.when(
            data: (notes) {
              if (notes.isEmpty) {
                return const FyndoEmptyState(
                  icon: Icons.delete_outline,
                  title: 'Trash is Empty',
                  description: 'Deleted notes will appear here.',
                );
              }
              return _NotesGridView(
                notes: notes,
                onNoteOptions: (note) => _showTrashOptions(context, ref, note),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          );
        },
      ),
    );
  }

  void _emptyTrash(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text(
          'All notes in trash will be permanently deleted. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement empty trash
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Trash emptied')));
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );
  }

  void _showTrashOptions(
    BuildContext context,
    WidgetRef ref,
    NoteMetadata note,
  ) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Restore'),
              onTap: () {
                Navigator.pop(context);
                ref.read(noteOperationsProvider.notifier).restoreNote(note.id);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_forever,
                color: theme.colorScheme.error,
              ),
              title: Text(
                'Delete Permanently',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                ref.read(noteOperationsProvider.notifier).deleteNote(note.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// Grid view for notes - gives a paper/card feel
class _NotesGridView extends StatelessWidget {
  final List<NoteMetadata> notes;
  final void Function(NoteMetadata note) onNoteOptions;

  const _NotesGridView({required this.notes, required this.onNoteOptions});

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const FyndoEmptyState(
        icon: Icons.note_outlined,
        title: 'No Notes Yet',
        description: 'Create your first note to get started.',
      );
    }

    // Separate pinned and regular notes
    final pinnedNotes = notes.where((n) => n.isPinned).toList();
    final regularNotes = notes.where((n) => !n.isPinned).toList();

    return CustomScrollView(
      slivers: [
        if (pinnedNotes.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                FyndoTheme.padding,
                FyndoTheme.padding,
                FyndoTheme.padding,
                8,
              ),
              child: Text(
                'PINNED',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          _buildGrid(context, pinnedNotes),
        ],
        if (regularNotes.isNotEmpty) ...[
          if (pinnedNotes.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  FyndoTheme.padding,
                  FyndoTheme.padding,
                  FyndoTheme.padding,
                  8,
                ),
                child: Text(
                  'NOTES',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          _buildGrid(context, regularNotes),
        ],
        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, List<NoteMetadata> notes) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: FyndoTheme.padding),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280,
          mainAxisSpacing: FyndoTheme.padding,
          crossAxisSpacing: FyndoTheme.padding,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final note = notes[index];
          return _NoteGridCard(
            note: note,
            onTap: () => context.push('/note/${note.id}'),
            onLongPress: () => onNoteOptions(note),
          );
        }, childCount: notes.length),
      ),
    );
  }
}

/// A grid card for a note - resembles a paper page
class _NoteGridCard extends StatelessWidget {
  final NoteMetadata note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NoteGridCard({
    required this.note,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            // Paper shadow effect
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with pin icon
              if (note.isPinned)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Icon(
                    Icons.push_pin,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              // Title
              Padding(
                padding: EdgeInsets.fromLTRB(12, note.isPinned ? 0 : 12, 12, 8),
                child: Text(
                  note.title.isEmpty ? 'Untitled' : note.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontStyle: note.title.isEmpty ? FontStyle.italic : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Preview lines (simulating lined paper)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: List.generate(
                      4,
                      (index) => Container(
                        height: 20,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: theme.dividerColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: index == 0 && note.preview != null
                            ? Text(
                                note.preview!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              // Footer with date and tags
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Text(
                      _formatDate(note.modifiedAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    if (note.tags.isNotEmpty)
                      Icon(
                        Icons.label_outline,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return DateFormat.jm().format(date);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat.E().format(date);
    } else {
      return DateFormat.MMMd().format(date);
    }
  }
}

/// Bottom sheet for note options
class _NoteOptionsSheet {
  static void show(BuildContext context, WidgetRef ref, NoteMetadata note) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              ),
              title: Text(note.isPinned ? 'Unpin' : 'Pin'),
              onTap: () {
                Navigator.pop(context);
                ref.read(noteOperationsProvider.notifier).togglePin(note.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                ShareDialog.show(
                  context,
                  itemName: note.title.isEmpty ? 'Untitled' : note.title,
                  itemType: ShareItemType.note,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archive'),
              onTap: () {
                Navigator.pop(context);
                ref.read(noteOperationsProvider.notifier).archiveNote(note.id);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: theme.colorScheme.error),
              title: Text(
                'Move to Trash',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                ref.read(noteOperationsProvider.notifier).trashNote(note.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
