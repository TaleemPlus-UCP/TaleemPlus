import 'package:flutter/material.dart';

import '../../core/web/web_theme.dart';

/// Custom shimmer sweep (no extra package) used by every `WebSkeleton*`
/// widget — an [AnimatedBuilder] driving a diagonal gradient sweep clipped
/// to the child's shape via [ShaderMask].
class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.webColors.skeletonBase;
    final highlight = context.webColors.skeletonHighlight;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _controller.value;
            return LinearGradient(
              begin: Alignment(-1.5 + 3 * t, -0.3),
              end: Alignment(-0.5 + 3 * t, 0.3),
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single shimmering rounded box — the atom every other skeleton is built
/// from.
class WebSkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const WebSkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.webColors.skeletonBase,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Placeholder for a vertical list of card rows while data is loading.
class WebSkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const WebSkeletonList({super.key, this.itemCount = 6, this.itemHeight = 64});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: WebSkeletonBox(
            height: itemHeight,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

/// Placeholder for a [WebDataTable] while its rows are loading — a header
/// bar plus several shimmering row bars.
class WebSkeletonTable extends StatelessWidget {
  final int rows;
  final int columns;

  const WebSkeletonTable({super.key, this.rows = 8, this.columns = 4});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const WebSkeletonBox(height: 40, width: 220),
        const SizedBox(height: 18),
        for (int r = 0; r < rows; r++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                for (int c = 0; c < columns; c++) ...[
                  const Expanded(
                    child: WebSkeletonBox(height: 18, width: double.infinity),
                  ),
                  if (c != columns - 1) const SizedBox(width: 24),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// A small circular/pill skeleton for avatars or badges.
class WebSkeletonCircle extends StatelessWidget {
  final double size;
  const WebSkeletonCircle({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: context.webColors.skeletonBase,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
