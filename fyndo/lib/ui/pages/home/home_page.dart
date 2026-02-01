// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Home Page - Vault List and Management
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:fyndo_app/core/agentic/fyndo_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/providers/note_providers.dart';
import 'package:fyndo_app/providers/notebook_providers.dart';
import 'package:fyndo_app/providers/vault_providers.dart';
import 'package:fyndo_app/providers/vault_selection_providers.dart';
import 'package:fyndo_app/providers/unlocked_workspace_provider.dart';
import 'package:fyndo_app/ui/consumers/notebook_consumer.dart';
import 'package:fyndo_app/ui/theme/fyndo_theme.dart';
import 'package:fyndo_app/ui/widgets/common/fyndo_app_bar.dart';
import 'package:fyndo_app/ui/widgets/common/fyndo_empty_state.dart';
import 'package:fyndo_app/ui/widgets/common/fyndo_list_tile.dart';
import 'package:fyndo_app/ui/widgets/notebook/notebook_create_dialog.dart';
import 'package:fyndo_app/ui/widgets/vault/vault_card.dart';
import 'package:fyndo_app/ui/widgets/vault/vault_switcher_dialog.dart';
import 'package:go_router/go_router.dart';

/// Home page showing vault overview and notebooks.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // Load notebooks when page loads
    Future.microtask(() {
      ref.read(notebooksProvider.notifier).loadNotebooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if workspace is unlocked using the new spec-002 architecture
    final unlockedWorkspace = ref.watch(unlockedWorkspaceProvider);

    // If workspace is not unlocked, redirect to welcome
    if (unlockedWorkspace == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return const _HomePageContent();
  }
}

class _HomePageContent extends ConsumerWidget {
  const _HomePageContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    return Scaffold(
      appBar: FyndoAppBar(
        title: const FyndoAppBarTitle('Fyndo'),
        leading: const SizedBox(width: 16),
        actions: [
          IconButton(
            key: FyndoKeys.btnSearch,
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
            tooltip: 'Search',
          ),
          IconButton(
            key: FyndoKeys.navSettings,
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),
          PopupMenuButton<String>(
            key: FyndoKeys.menuMoreActions,
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'lock',
                child: ListTile(
                  leading: Icon(Icons.lock),
                  title: Text('Lock Vault'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'trash',
                child: ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Trash'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: isWide
          ? _buildWideLayout(context, ref)
          : _buildNarrowLayout(context, ref),
      floatingActionButton: FloatingActionButton(
        key: FyndoKeys.btnNotebookCreate,
        onPressed: () => _createNotebook(context, ref),
        tooltip: 'Create Notebook',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Sidebar
        SizedBox(width: 280, child: _buildSidebar(context, ref)),
        const VerticalDivider(width: 1),
        // Main content
        Expanded(child: _buildMainContent(context, ref)),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context, WidgetRef ref) {
    return _buildMainContent(context, ref);
  }

  Widget _buildSidebar(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Quick links
        Padding(
          padding: const EdgeInsets.all(FyndoTheme.padding),
          child: Text(
            'Quick Access',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        FyndoListTile(
          key: FyndoKeys.navAllNotes,
          leading: const Icon(Icons.note, size: 20),
          title: const Text('All Notes'),
          onTap: () => context.push('/notes'),
        ),
        FyndoListTile(
          key: FyndoKeys.navPinned,
          leading: const Icon(Icons.push_pin, size: 20),
          title: const Text('Pinned'),
          onTap: () => context.push('/notes/pinned'),
        ),
        FyndoListTile(
          key: FyndoKeys.navArchived,
          leading: const Icon(Icons.archive, size: 20),
          title: const Text('Archived'),
          onTap: () => context.push('/notes/archived'),
        ),
        const Divider(),

        // Notebooks
        Padding(
          padding: const EdgeInsets.all(FyndoTheme.padding),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Notebooks',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                key: FyndoKeys.btnNotebookCreateSidebar,
                icon: const Icon(Icons.add, size: 18),
                onPressed: () => _createNotebook(context, ref),
                tooltip: 'Create Notebook',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ActiveNotebooksConsumer(
            builder: (context, notebooks, _) {
              if (notebooks.isEmpty) {
                return Center(
                  child: Text(
                    'No notebooks yet',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }

              return ListView.builder(
                key: FyndoKeys.listNotebooksSidebar,
                itemCount: notebooks.length,
                itemBuilder: (context, index) {
                  final notebook = notebooks[index];
                  return _NotebookListTile(
                    notebook: notebook,
                    onTap: () => context.push('/notebook/${notebook.id}'),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        // Vault info card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(FyndoTheme.padding),
            child: _VaultCardWithData(
              onTap: () => _showVaultSwitcher(context, ref),
            ),
          ),
        ),

        // Recent notes header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FyndoTheme.padding,
              vertical: FyndoTheme.paddingSmall,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('Notebooks', style: theme.textTheme.titleMedium),
                ),
                TextButton.icon(
                  key: FyndoKeys.btnNotebookCreateHeader,
                  onPressed: () => _createNotebook(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New'),
                ),
              ],
            ),
          ),
        ),

        // Notebooks grid
        NotebookConsumer(
          builder: (context, state, _) {
            if (state.isLoading) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final notebooks = state.notebooks
                .where((n) => !n.isArchived)
                .toList();

            if (notebooks.isEmpty) {
              return SliverFillRemaining(
                child: FyndoEmptyState(
                  icon: Icons.book,
                  title: 'No Notebooks Yet',
                  description:
                      'Create your first notebook to start organizing your notes.',
                  actionText: 'Create Notebook',
                  onAction: () => _createNotebook(context, ref),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.all(FyndoTheme.padding),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  mainAxisSpacing: FyndoTheme.padding,
                  crossAxisSpacing: FyndoTheme.padding,
                  childAspectRatio: 1.5,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final notebook = notebooks[index];
                  return _NotebookGridCard(
                    notebook: notebook,
                    onTap: () => context.push('/notebook/${notebook.id}'),
                    onMoreOptions: () =>
                        _showNotebookOptions(context, ref, notebook),
                  );
                }, childCount: notebooks.length),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showSearch(BuildContext context) {
    // TODO: Implement search
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Search coming soon')));
  }

  void _showVaultSwitcher(BuildContext context, WidgetRef ref) {
    VaultSwitcherDialog.show(
      context,
      onVaultSelected: (vaultId) {
        // Vault selection is handled by the dialog
        // Invalidate dependent providers to reload data
        ref.invalidate(notebooksProvider);
        ref.invalidate(activeNotesProvider);
      },
      onCreateVault:
          ({
            required String name,
            String? description,
            String? icon,
            String? color,
          }) async {
            // Create vault using the vault creation provider
            final result = await ref
                .read(vaultCreationProvider.notifier)
                .createVault(
                  name: name,
                  description: description,
                  icon: icon,
                  color: color,
                );

            if (context.mounted) {
              if (result.isSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Vault "$name" created successfully!'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to create vault: ${result.error}'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            }
          },
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'lock':
        ref.read(vaultProvider.notifier).lock();
        context.go('/');
        break;
      case 'trash':
        context.push('/trash');
        break;
    }
  }

  void _createNotebook(BuildContext context, WidgetRef ref) {
    NotebookCreateDialog.show(
      context,
      onCreate: (name, description, color, icon) {
        ref
            .read(notebooksProvider.notifier)
            .createNotebook(
              name: name,
              description: description,
              color: color,
              icon: icon,
            );
      },
    );
  }

  void _showNotebookOptions(
    BuildContext context,
    WidgetRef ref,
    Notebook notebook,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show share dialog
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show rename dialog
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archive'),
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(notebooksProvider.notifier)
                    .archiveNotebook(notebook.id);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteNotebook(context, ref, notebook);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteNotebook(
    BuildContext context,
    WidgetRef ref,
    Notebook notebook,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notebook?'),
        content: Text(
          'Are you sure you want to delete "${notebook.name}"? '
          'All notes in this notebook will also be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(notebooksProvider.notifier).deleteNotebook(notebook.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// List tile for notebook in sidebar with dynamic note count.
class _NotebookListTile extends ConsumerWidget {
  final Notebook notebook;
  final VoidCallback? onTap;

  const _NotebookListTile({required this.notebook, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteCountAsync = ref.watch(notebookNoteCountProvider(notebook.id));
    final noteCount = noteCountAsync.valueOrNull ?? 0;

    return FyndoListTile(
      key: FyndoKeys.notebookItem(notebook.id),
      leading: Icon(
        Icons.book,
        size: 20,
        color: notebook.color != null
            ? Color(int.parse('0xFF${notebook.color}'))
            : null,
      ),
      title: Text(notebook.name),
      subtitle: Text('$noteCount notes'),
      onTap: onTap,
    );
  }
}

class _NotebookGridCard extends ConsumerWidget {
  final Notebook notebook;
  final VoidCallback? onTap;
  final VoidCallback? onMoreOptions;

  const _NotebookGridCard({
    required this.notebook,
    this.onTap,
    this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final noteCountAsync = ref.watch(notebookNoteCountProvider(notebook.id));
    final noteCount = noteCountAsync.valueOrNull ?? 0;
    final color = notebook.color != null
        ? Color(int.parse('0xFF${notebook.color}'))
        : theme.colorScheme.primary;

    return InkWell(
      key: FyndoKeys.notebookCard(notebook.id),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with color
            Container(height: 8, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(FyndoTheme.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.book, color: color, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notebook.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (onMoreOptions != null)
                          IconButton(
                            icon: const Icon(Icons.more_vert, size: 18),
                            onPressed: onMoreOptions,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (notebook.description != null &&
                        notebook.description!.isNotEmpty)
                      Expanded(
                        child: Text(
                          notebook.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      const Spacer(),
                    Text(
                      '$noteCount notes',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vault card that displays real vault data from providers.
class _VaultCardWithData extends ConsumerWidget {
  final VoidCallback? onTap;

  const _VaultCardWithData({this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metadataAsync = ref.watch(activeVaultMetadataProvider);
    final statsAsync = ref.watch(activeVaultStatsProvider);
    final vaultCount = ref.watch(vaultCountProvider);

    return metadataAsync.when(
      data: (metadata) {
        final stats = statsAsync.valueOrNull ?? VaultStats.empty;

        return VaultCard(
          key: FyndoKeys.vaultCardHome,
          name: metadata?.name ?? 'My Vault',
          description: metadata?.description ?? 'Your personal encrypted vault',
          isLocked: false,
          noteCount: stats.noteCount,
          notebookCount: stats.notebookCount,
          lastModified: stats.lastModified ?? DateTime.now(),
          vaultCount: vaultCount > 1 ? vaultCount : null,
          onTap: onTap,
        );
      },
      loading: () => VaultCard(
        key: FyndoKeys.vaultCardHome,
        name: 'Loading...',
        description: '',
        isLocked: false,
        noteCount: 0,
        notebookCount: 0,
        lastModified: DateTime.now(),
        onTap: null,
      ),
      error: (_, __) => VaultCard(
        key: FyndoKeys.vaultCardHome,
        name: 'Error',
        description: 'Failed to load vault data',
        isLocked: false,
        noteCount: 0,
        notebookCount: 0,
        lastModified: DateTime.now(),
        onTap: onTap,
      ),
    );
  }
}
