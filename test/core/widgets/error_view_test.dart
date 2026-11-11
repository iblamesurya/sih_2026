import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_guard/core/widgets/error_view.dart';

void main() {
  group('AppErrorView & OfflineStatusBar Test Suite', () {
    testWidgets('AppErrorView renders offline error in English with retry and cached data buttons',
        (WidgetTester tester) async {
      bool retried = false;
      bool usedOffline = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorView(
              errorType: AppErrorType.offline,
              isTelugu: false,
              hasOfflineData: true,
              onRetry: () => retried = true,
              onUseOfflineData: () => usedOffline = true,
            ),
          ),
        ),
      );

      expect(find.text('No Network Connection'), findsOneWidget);
      expect(
        find.textContaining('Pond dyke 2G connectivity might be unavailable'),
        findsOneWidget,
      );
      expect(find.text('Retry Connection'), findsOneWidget);
      expect(find.text('Use Offline Cached Data'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

      await tester.tap(find.text('Retry Connection'));
      expect(retried, isTrue);

      await tester.tap(find.text('Use Offline Cached Data'));
      expect(usedOffline, isTrue);
    });

    testWidgets('AppErrorView renders bilingual Telugu messaging accurately',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppErrorView(
              errorType: AppErrorType.offline,
              isTelugu: true,
            ),
          ),
        ),
      );

      expect(find.text('ఇంటర్నెట్ కనెక్షన్ లేదు'), findsOneWidget);
      expect(
        find.textContaining('చెరువు గట్ల వద్ద 2G సిగ్నల్ బలహీనంగా ఉండవచ్చు'),
        findsOneWidget,
      );
    });

    testWidgets('AppErrorView handles server, timeout, and unknown error types',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppErrorView(
              errorType: AppErrorType.server,
              isTelugu: false,
            ),
          ),
        ),
      );

      expect(find.text('AquaCloud Server Unavailable'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppErrorView(
              errorType: AppErrorType.timeout,
              isTelugu: false,
            ),
          ),
        ),
      );

      expect(find.text('Connection Timed Out'), findsOneWidget);
      expect(find.byIcon(Icons.timer_off_outlined), findsOneWidget);
    });

    testWidgets('AppErrorView renders compact inline alert when isCompact is true',
        (WidgetTester tester) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorView(
              isCompact: true,
              errorType: AppErrorType.offline,
              title: 'Compact Offline Alert',
              message: 'Local changes cached',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Compact Offline Alert'), findsOneWidget);
      expect(find.text('Local changes cached'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh));
      expect(retried, isTrue);
    });

    testWidgets('OfflineStatusBar shows banner when isOffline is true and hides when false',
        (WidgetTester tester) async {
      bool synced = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineStatusBar(
              isOffline: true,
              isTelugu: false,
              onSyncNow: () => synced = true,
            ),
          ),
        ),
      );

      expect(find.textContaining('Offline Mode — Showing local cached farm data'), findsOneWidget);
      expect(find.text('Sync'), findsOneWidget);

      await tester.tap(find.text('Sync'));
      expect(synced, isTrue);

      // Verify hidden when isOffline is false
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineStatusBar(
              isOffline: false,
            ),
          ),
        ),
      );

      expect(find.textContaining('Offline Mode'), findsNothing);
    });
  });
}
