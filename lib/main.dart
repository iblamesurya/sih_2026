import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class PrawnGuardApp extends ConsumerWidget {
  const PrawnGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'PrawnGuard.ai',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
