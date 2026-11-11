import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_guard/core/theme/app_theme.dart';
import 'package:prawn_guard/core/widgets/shimmer_skeleton.dart';

void main() {
  group('Shimmer & Skeleton Loaders Test Suite', () {
    testWidgets('ShimmerBox renders with specified width, height and border radius',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerBox(width: 120, height: 24, borderRadius: 6),
          ),
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      final container = tester.widget<Container>(containerFinder.first);
      final boxDec = container.decoration as BoxDecoration;
      expect(boxDec.borderRadius, BorderRadius.circular(6));
    });

    testWidgets('ShimmerCircle renders circular container with specified diameter',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerCircle(size: 40),
          ),
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      final container = tester.widget<Container>(containerFinder.first);
      final boxDec = container.decoration as BoxDecoration;
      expect(boxDec.shape, BoxShape.circle);
      expect(container.constraints?.maxWidth, 40);
      expect(container.constraints?.maxHeight, 40);
    });

    testWidgets('PondCardSkeleton renders full pond card skeleton silhouette',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PondCardSkeleton(),
          ),
        ),
      );

      expect(find.byType(ShimmerLoading), findsOneWidget);
      expect(find.byType(ShimmerCircle), findsOneWidget);
      expect(find.byType(ShimmerBox), findsWidgets);
    });

    testWidgets('TelemetryGraphSkeleton renders chart silhouette with parameter chips',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TelemetryGraphSkeleton(),
          ),
        ),
      );

      expect(find.byType(ShimmerLoading), findsOneWidget);
      expect(find.byType(ShimmerBox), findsWidgets);
    });

    testWidgets('MandiPriceSkeleton renders market card silhouette',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MandiPriceSkeleton(),
          ),
        ),
      );

      expect(find.byType(ShimmerLoading), findsOneWidget);
      expect(find.byType(ShimmerBox), findsWidgets);
    });

    testWidgets('SkeletonList repeats skeleton items count times',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonList(
              skeletonItem: PondCardSkeleton(),
              count: 4,
            ),
          ),
        ),
      );

      expect(find.byType(PondCardSkeleton), findsNWidgets(4));
    });
  });
}
