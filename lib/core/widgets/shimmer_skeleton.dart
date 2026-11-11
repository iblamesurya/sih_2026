import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable Deep Ocean Matte Shimmer Animation Wrapper.
///
/// Uses an internal single-ticker animation to smoothly cycle an ambient
/// cyan-tinted matte gradient across placeholder silhouettes without external dependencies.
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final sweep = _controller.value;
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFF1E1E1E),
                Color(0xFF2C2C2C),
                Color(0xFF1E1E1E),
              ],
              stops: [
                (sweep - 0.3).clamp(0.0, 1.0),
                sweep.clamp(0.0, 1.0),
                (sweep + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Primitive rectangular skeleton placeholder.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final Color? color;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Primitive circular skeleton placeholder (e.g. for badges, avatar icons).
class ShimmerCircle extends StatelessWidget {
  final double size;
  final Color? color;

  const ShimmerCircle({
    super.key,
    required this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? AppColors.surfaceElevated,
      ),
    );
  }
}

/// Skeleton mimic for a Pond Card in PondListPage & HomePage.
class PondCardSkeleton extends StatelessWidget {
  const PondCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ShimmerCircle(size: 20),
                    SizedBox(width: 10),
                    ShimmerBox(width: 140, height: 18, borderRadius: 4),
                  ],
                ),
                ShimmerBox(width: 60, height: 22, borderRadius: 12),
              ],
            ),
            SizedBox(height: 14),
            Row(
              children: [
                ShimmerBox(width: 70, height: 14, borderRadius: 4),
                SizedBox(width: 12),
                ShimmerBox(width: 90, height: 14, borderRadius: 4),
                SizedBox(width: 12),
                ShimmerBox(width: 60, height: 14, borderRadius: 4),
              ],
            ),
            SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(width: 40, height: 10, borderRadius: 2),
                          SizedBox(height: 6),
                          ShimmerBox(width: 60, height: 16, borderRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(width: 40, height: 10, borderRadius: 2),
                          SizedBox(height: 6),
                          ShimmerBox(width: 60, height: 16, borderRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(width: 40, height: 10, borderRadius: 2),
                          SizedBox(height: 6),
                          ShimmerBox(width: 60, height: 16, borderRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton placeholder for Telemetry Charts & Detail Views.
class TelemetryGraphSkeleton extends StatelessWidget {
  const TelemetryGraphSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 130, height: 18, borderRadius: 4),
                ShimmerBox(width: 70, height: 14, borderRadius: 4),
              ],
            ),
            SizedBox(height: 18),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShimmerBox(width: 30, height: 10, borderRadius: 2),
                          ShimmerBox(width: 200, height: 2, borderRadius: 1),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShimmerBox(width: 30, height: 10, borderRadius: 2),
                          ShimmerBox(width: 200, height: 2, borderRadius: 1),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShimmerBox(width: 30, height: 10, borderRadius: 2),
                          ShimmerBox(width: 200, height: 2, borderRadius: 1),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ShimmerBox(width: 60, height: 12, borderRadius: 4),
                ShimmerBox(width: 60, height: 12, borderRadius: 4),
                ShimmerBox(width: 60, height: 12, borderRadius: 4),
                ShimmerBox(width: 60, height: 12, borderRadius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton mimic for Mandi Price items on MandiPricesPage.
class MandiPriceSkeleton extends StatelessWidget {
  const MandiPriceSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 120, height: 16, borderRadius: 4),
                SizedBox(height: 6),
                ShimmerBox(width: 180, height: 12, borderRadius: 4),
                SizedBox(height: 6),
                ShimmerBox(width: 90, height: 10, borderRadius: 2),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ShimmerBox(width: 70, height: 20, borderRadius: 4),
                SizedBox(height: 6),
                ShimmerBox(width: 45, height: 14, borderRadius: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton list generator helper widget.
class SkeletonList extends StatelessWidget {
  final Widget skeletonItem;
  final int count;
  final EdgeInsetsGeometry padding;

  const SkeletonList({
    super.key,
    required this.skeletonItem,
    this.count = 4,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (context, index) => skeletonItem,
    );
  }
}
