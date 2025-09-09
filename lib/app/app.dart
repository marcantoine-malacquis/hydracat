import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/app/router.dart';
import 'package:hydracat/core/config/flavor_config.dart';
import 'package:hydracat/core/theme/app_theme.dart';
import 'package:hydracat/providers/theme_provider.dart';
import 'package:hydracat/shared/services/firebase_service.dart';

/// Main application widget for HydraCat.
class HydraCatApp extends ConsumerStatefulWidget {
  /// Creates a HydraCatApp.
  const HydraCatApp({super.key});

  @override
  ConsumerState<HydraCatApp> createState() => _HydraCatAppState();
}

class _HydraCatAppState extends ConsumerState<HydraCatApp> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      _devLog('Starting Firebase initialization...');
      await FirebaseService().initialize();
      _devLog('Firebase initialization completed successfully');
      setState(() {
        _initialized = true;
      });
    } on Exception catch (e, stackTrace) {
      _devLog('Firebase initialization failed: $e');
      _devLog('Stack trace: $stackTrace');
      setState(() {
        _error = 'Firebase Error: $e';
      });
    }
  }

  /// Log messages only in development flavor
  void _devLog(String message) {
    if (FlavorConfig.isDevelopment) {
      debugPrint('[App Dev] $message');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always show error screen first if there's an error
    if (_error != null) {
      return MaterialApp(
        title: 'HydraCat',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'App Initialization Failed',
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _error = null;
                          _initialized = false;
                        });
                        _initializeFirebase();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32, 
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Retry Initialization'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Show loading screen while initializing
    if (!_initialized) {
      return const MaterialApp(
        title: 'HydraCat',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.blue,
                ),
                SizedBox(height: 24),
                Text(
                  'Initializing HydraCat...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If we reach here, Firebase is initialized successfully
    try {
      final router = ref.watch(appRouterProvider);
      final themeMode = ref.watch(themeProvider);
      
      return MaterialApp.router(
        title: 'HydraCat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: router,
      );
    } on Exception catch (e) {
      // If there's an error with routing, show a fallback
      return MaterialApp(
        title: 'HydraCat',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Text(
              'Router Error: $e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }
  }
}
