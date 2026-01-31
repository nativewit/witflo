// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Main Entry Point
// ═══════════════════════════════════════════════════════════════════════════
//
// INITIALIZATION ORDER:
// 1. WidgetsFlutterBinding.ensureInitialized()
// 2. CryptoService.initialize() - Load libsodium
// 3. Platform-specific setup (desktop SQLite, etc.)
// 4. Run app with Riverpod
//
// SECURITY NOTE:
// The crypto service MUST be initialized before any other operations.
// All cryptographic operations depend on libsodium being loaded.
//
// WEB SUPPORT:
// The app works on web with the following considerations:
// - Crypto uses sodium.js (included in sodium_libs)
// - Storage uses IndexedDB/localStorage instead of file system
// - SQLite uses sql.js for web
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/core/crypto/crypto.dart';
import 'package:fyndo_app/providers/vault_providers.dart';
import 'package:fyndo_app/ui/router/app_router.dart';
import 'package:fyndo_app/ui/theme/fyndo_theme.dart';

// Conditional imports for platform-specific code
import 'platform/platform_init.dart'
    if (dart.library.html) 'platform/platform_init_web.dart'
    if (dart.library.io) 'platform/platform_init_native.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize platform-specific dependencies
  await initializePlatform();

  // Initialize cryptography (REQUIRED before any crypto operations)
  await CryptoService.initialize();

  // Run the app with Riverpod for state management
  runApp(const ProviderScope(child: FyndoApp()));
}

/// The main Fyndo application.
class FyndoApp extends ConsumerStatefulWidget {
  const FyndoApp({super.key});

  @override
  ConsumerState<FyndoApp> createState() => _FyndoAppState();
}

class _FyndoAppState extends ConsumerState<FyndoApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Get default vault path using platform helper
    final defaultVaultPath = await getAppDocumentsPath();

    // Set vault path
    await ref.read(vaultProvider.notifier).setVaultPath(defaultVaultPath);

    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        title: 'Fyndo',
        debugShowCheckedModeBanner: false,
        theme: FyndoTheme.light(),
        darkTheme: FyndoTheme.dark(),
        themeMode: ThemeMode.system,
        localizationsDelegates: [FlutterQuillLocalizations.delegate],
        home: const _SplashScreen(),
      );
    }

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Fyndo',
      debugShowCheckedModeBanner: false,
      theme: FyndoTheme.light(),
      darkTheme: FyndoTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      localizationsDelegates: [FlutterQuillLocalizations.delegate],
    );
  }
}

/// Splash screen shown during initialization.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              ),
              child: Icon(
                Icons.lock,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'FYNDO',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Initializing...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
