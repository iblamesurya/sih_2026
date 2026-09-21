import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'scaffold_with_nav_bar.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/ponds/presentation/pages/pond_list_page.dart';
import '../../features/ponds/presentation/pages/pond_detail_page.dart';
import '../../features/ponds/presentation/pages/telemetry_logging_page.dart';
import '../../features/ponds/presentation/pages/add_pond_modal.dart';
import '../../features/feed/presentation/pages/feed_ai_page.dart';
import '../../features/prawndoc/presentation/pages/prawndoc_page.dart';
import '../../features/more/presentation/pages/more_page.dart';
import '../../features/more/presentation/pages/profile_settings_page.dart';
import '../../features/finance/presentation/pages/finance_page.dart';
import '../../features/weather/presentation/pages/weather_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/subscription/presentation/pages/upgrade_page.dart';
import '../../features/community/presentation/pages/community_page.dart';
import '../../features/admin/presentation/pages/admin_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Central GoRouter configuration provider for PrawnGuard.ai.
final appRouterProvider = Provider<GoRouter>((ref) {
  return createPrawnGuardRouter();
});

/// Creates and configures the 5-tab shell + modal router for PrawnGuard.ai.
GoRouter createPrawnGuardRouter({String initialLocation = '/home'}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      // 5-Tab StatefulShellRoute Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),

          // Tab 1: Ponds
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ponds',
                builder: (context, state) => const PondListPage(),
              ),
            ],
          ),

          // Tab 2: Feed AI
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                builder: (context, state) => const FeedAiPage(),
              ),
            ],
          ),

          // Tab 3: PrawnDoc Vision
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/prawndoc',
                builder: (context, state) => const PrawnDocPage(),
              ),
            ],
          ),

          // Tab 4: More & Hub
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MorePage(),
              ),
            ],
          ),
        ],
      ),

      // Standalone Fullscreen & Modal Routes
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/profile-setup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileSettingsPage(),
      ),
      GoRoute(
        path: '/quick-log',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TelemetryLoggingPage(),
      ),
      GoRoute(
        path: '/finance',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FinancePage(),
      ),
      GoRoute(
        path: '/weather',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WeatherPage(),
      ),
      GoRoute(
        path: '/reports',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReportsPage(),
      ),
      GoRoute(
        path: '/upgrade',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const UpgradePage(),
      ),
      GoRoute(
        path: '/admin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminPage(),
      ),
      GoRoute(
        path: '/community',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CommunityPage(),
      ),
      GoRoute(
        path: '/add-pond',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddPondModal(),
      ),
      GoRoute(
        path: '/pond/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final pondId = state.pathParameters['id'] ?? '1';
          return PondDetailPage(pondId: pondId);
        },
      ),
    ],
  );
}
