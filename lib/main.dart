import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/app_providers.dart';
import 'core/router/app_router.dart';
import 'core/services/logger_service.dart';
import 'core/services/supabase_client.dart';
import 'core/theme/app_theme.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Global Flutter framework error capture
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        LoggerService.error(
          'Flutter Framework Exception: ${details.exceptionAsString()}',
          tag: 'CRASH',
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      await SupabaseClientService.initialize();
      runApp(const ProviderScope(child: PrawnGuardApp()));
    },
    (Object error, StackTrace stack) {
      LoggerService.error(
        'Uncaught Root Exception: $error',
        tag: 'CRASH',
        error: error,
        stackTrace: stack,
      );
    },
  );
}

class PrawnGuardApp extends ConsumerStatefulWidget {
  const PrawnGuardApp({super.key});

  @override
  ConsumerState<PrawnGuardApp> createState() => _PrawnGuardAppState();
}

class _PrawnGuardAppState extends ConsumerState<PrawnGuardApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hydration = ref.read(dataHydrationServiceProvider);
      hydration.hydrateAll(ref);
      hydration.bindRealtimeStreams(ref);
    });
  }

  @override
  void dispose() {
    try {
      ref.read(dataHydrationServiceProvider).disposeRealtimeStreams();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(currentLocaleProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'PrawnGuard.ai',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('te'),
      ],
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
