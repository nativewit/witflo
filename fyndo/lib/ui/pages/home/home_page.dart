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
import 'package:fyndo_app/ui/widgets/vault/vault_create_dialog.dart';
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

        // Vaults
        Padding(
          padding: const EdgeInsets.all(FyndoTheme.padding),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Vaults',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                key: FyndoKeys.btnVaultCreate,
                icon: const Icon(Icons.add, size: 18),
                onPressed: () => _createVault(context, ref),
                tooltip: 'Create Vault',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        Expanded(
          child: Consumer(
            builder: (context, ref, _) {
              final vaultsAsync = ref.watch(availableVaultsProvider);
              final activeVaultId = ref.watch(activeVaultIdProvider);

              return vaultsAsync.when(
                data: (vaults) {
                  if (vaults.isEmpty) {
                    return Center(
                      child: Text(
                        'No vaults',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    key: FyndoKeys.listVaultsSidebar,
                    itemCount: vaults.length,
                    itemBuilder: (context, index) {
                      final vaultInfo = vaults[index];
                      return _VaultListTile(
                        vaultInfo: vaultInfo,
                        isActive: vaultInfo.vaultId == activeVaultId,
                        onTap: () {
                          ref
                              .read(selectedVaultIdProvider.notifier)
                              .selectVault(vaultInfo.vaultId);
                          // Invalidate dependent providers to reload data
                          ref.invalidate(notebooksProvider);
                          ref.invalidate(activeNotesProvider);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(
                    'Error loading vaults',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
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
            child: _VaultCardWithData(onTap: () => context.push('/vault')),
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
            return state.when(
              data: (notebooksState) {
                final notebooks = notebooksState.notebooks
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
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
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
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: Center(child: Text('Error loading notebooks: $error')),
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

  void _createVault(BuildContext context, WidgetRef ref) {
    VaultCreateDialog.show(
      context,
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

/// List tile for vault in sidebar.
class _VaultListTile extends StatelessWidget {
  final VaultInfo vaultInfo;
  final bool isActive;
  final VoidCallback? onTap;

  const _VaultListTile({
    required this.vaultInfo,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = vaultInfo.metadata;

    return FyndoListTile(
      key: Key('vault_tile_${vaultInfo.vaultId}'),
      leading: Icon(
        isActive ? Icons.lock_open : Icons.lock,
        size: 20,
        color: isActive ? theme.colorScheme.primary : null,
      ),
      title: Text(
        metadata.name,
        style: isActive
            ? TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              )
            : null,
      ),
      subtitle: metadata.description != null && metadata.description!.isNotEmpty
          ? Text(
              metadata.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: isActive
          ? Icon(Icons.check_circle, size: 16, color: theme.colorScheme.primary)
          : null,
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
                        Icon(
                          _getIconData(notebook.icon),
                          color: color,
                          size: 24,
                        ),
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

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work;
      case 'personal':
        return Icons.person;
      case 'ideas':
        return Icons.lightbulb;
      case 'journal':
        return Icons.auto_stories;
      case 'finance':
        return Icons.attach_money;
      case 'health':
        return Icons.favorite;
      case 'travel':
        return Icons.flight;
      case 'education':
        return Icons.school;
      case 'project':
        return Icons.folder_special;
      default:
        return Icons.book;
    }
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
      error: (_, stack) => VaultCard(
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
