import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prawn_guard/core/router/app_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoRouter 5-Tab Shell & Modal Routing Tests', () {
    test('createPrawnGuardRouter instantiates GoRouter with expected initial route', () {
      final router = createPrawnGuardRouter(initialLocation: '/home');
      expect(router, isA<GoRouter>());
      expect(router.routeInformationProvider.value.uri.toString(), equals('/home'));
    });

    testWidgets('Renders Home page at /home initial route', (tester) async {
      final router = createPrawnGuardRouter(initialLocation: '/home');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PrawnGuard.ai'), findsWidgets);
      expect(find.text('Quick Actions'), findsOneWidget);
    });

    testWidgets('Renders Ponds page at /ponds route', (tester) async {
      final router = createPrawnGuardRouter(initialLocation: '/ponds');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pond Management'), findsOneWidget);
    });

    testWidgets('Renders Feed AI page at /feed route', (tester) async {
      final router = createPrawnGuardRouter(initialLocation: '/feed');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Feed AI Bio-Energetics'), findsOneWidget);
    });

    testWidgets('Renders PrawnDoc page at /prawndoc route', (tester) async {
      final router = createPrawnGuardRouter(initialLocation: '/prawndoc');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PrawnDoc Vision AI'), findsOneWidget);
    });

    testWidgets('Renders More & Settings page at /more route', (tester) async {
      final router = createPrawnGuardRouter(initialLocation: '/more');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('More & Settings'), findsOneWidget);
      expect(find.text('Surya Tummala'), findsOneWidget);
    });

    testWidgets('Renders Login page modal at /login route', (tester) async {
      final router = createPrawnGuardRouter(initialLocation: '/login');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Enter Indian Mobile Number'), findsOneWidget);
      expect(find.text('Get OTP Code'), findsOneWidget);
    });

    testWidgets('Renders Quick Log page at /quick-log route', (tester) async {
      final router = createPrawnGuardRouter(initialLocation: '/quick-log');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quick Water Telemetry Log'), findsOneWidget);
      expect(find.text('Telugu Voice NLU Assistant'), findsOneWidget);
    });

    testWidgets('Renders Finance page modal at /finance route', (tester) async {
      final router = createPrawnGuardRouter(initialLocation: '/finance');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PrawnCredit & Finance'), findsOneWidget);
    });

    testWidgets('Renders Weather page modal at /weather route', (tester) async {
      final router = createPrawnGuardRouter(initialLocation: '/weather');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Weather Intelligence'), findsOneWidget);
    });

    testWidgets('Renders Upgrade page modal at /upgrade route', (tester) async {
      final router = createPrawnGuardRouter(initialLocation: '/upgrade');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PrawnGuard Pro Plan'), findsOneWidget);
    });
  });
}
