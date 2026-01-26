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
import 'package:fyndo_app/providers/vault_providers.dart';
import 'package:fyndo_app/ui/pages/pages.dart';
import 'package:go_router/go_router.dart';

/// App router provider.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: _RouterRefreshNotifier(ref),
    redirect: (context, state) {
      final vaultState = ref.read(vaultProvider);
      final isOnWelcome = state.matchedLocation == '/';

      // If vault is not unlocked and not on welcome, redirect to welcome
      if (!vaultState.isUnlocked && !isOnWelcome) {
        return '/';
      }

      // If vault is unlocked and on welcome, redirect to home
      if (vaultState.isUnlocked && isOnWelcome) {
        return '/home';
      }

      return null;
    },
    routes: [
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
        builder: (context, state) => const _SettingsPage(),
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

/// Router refresh notifier that listens to vault state changes.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this._ref) {
    _ref.listen(vaultProvider.select((s) => s.status), (previous, next) {
      notifyListeners();
    });
  }

  final Ref _ref;
}

// ═══════════════════════════════════════════════════════════════════════════
// PLACEHOLDER PAGES (to be expanded)
// ═══════════════════════════════════════════════════════════════════════════

class _AllNotesPage extends ConsumerWidget {
  const _AllNotesPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Notes')),
      body: const Center(child: Text('All notes coming soon')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Create a new note
          // final note = await ref.read(noteOperationsProvider.notifier).createNote(
          //       title: '',
          //       content: '',
          //     );
          // if (context.mounted) {
          //   context.push('/note/${note.id}');
          // }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PinnedNotesPage extends StatelessWidget {
  const _PinnedNotesPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pinned Notes')),
      body: const Center(child: Text('Pinned notes coming soon')),
    );
  }
}

class _ArchivedNotesPage extends StatelessWidget {
  const _ArchivedNotesPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archived Notes')),
      body: const Center(child: Text('Archived notes coming soon')),
    );
  }
}

class _TrashPage extends StatelessWidget {
  const _TrashPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trash')),
      body: const Center(child: Text('Trash coming soon')),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Appearance'),
            subtitle: const Text('Theme, font size'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync'),
            subtitle: const Text('Configure sync settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Security'),
            subtitle: const Text('Password, biometrics'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('Version, licenses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
