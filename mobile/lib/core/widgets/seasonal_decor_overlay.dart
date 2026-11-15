import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/seasonal_decor_provider.dart';

/// SeasonalDecorOverlay wraps the app or screen with cozy Christmas/holiday accents (NFR-UX-02)
/// When seasonal decor is enabled in user settings, displays a subtle garland at the top corners.
/// Uses [IgnorePointer] so all touch events pass through to underlying views without any friction.
class SeasonalDecorOverlay extends ConsumerWidget {
  final Widget child;

  const SeasonalDecorOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDecorEnabled = ref.watch(seasonalDecorProvider);

    if (!isDecorEnabled) {
      return child;
    }

    return Stack(
      key: const Key('seasonal_decor_overlay_active'),
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: CustomPaint(
              painter: _HolidayGarlandPainter(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter rendering subtle festive pine branch accents at screen top corners
class _HolidayGarlandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Only paint if size is positive
    if (size.width <= 0 || size.height <= 0) return;

    final pinePaint = Paint()
      ..color = AppColors.secondaryPineGreen.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final berryPaint = Paint()
      ..color = AppColors.christmasBerryRed
      ..style = PaintingStyle.fill;

    final goldPaint = Paint()
      ..color = AppColors.accentVintageGold
      ..style = PaintingStyle.fill;

    // Top-left subtle garland corner
    _drawGarlandCluster(canvas, pinePaint, berryPaint, goldPaint, const Offset(16, 8), isLeft: true);

    // Top-right subtle garland corner
    _drawGarlandCluster(canvas, pinePaint, berryPaint, goldPaint, Offset(size.width - 16, 8), isLeft: false);
  }

  void _drawGarlandCluster(
    Canvas canvas,
    Paint pine,
    Paint berry,
    Paint gold,
    Offset origin, {
    required bool isLeft,
  }) {
    final factor = isLeft ? 1.0 : -1.0;

    // Small pine needle arcs
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(origin.dx + ( factor * 6), origin.dy + 4),
        width: 14,
        height: 6,
      ),
      pine,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(origin.dx + (factor * 12), origin.dy + 8),
        width: 16,
        height: 7,
      ),
      pine,
    );

    // Festive berry cluster
    canvas.drawCircle(Offset(origin.dx + (factor * 2), origin.dy + 5), 3.0, berry);
    canvas.drawCircle(Offset(origin.dx + (factor * 7), origin.dy + 9), 2.5, berry);
    canvas.drawCircle(Offset(origin.dx + (factor * 11), origin.dy + 4), 2.2, gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
