import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Shared brand mark and wordmark for `izithrift`.
///
/// Combines a distinctive thrift/vintage emblem (Deep Pine badge + Vintage Gold
/// stitched inner frame + warm-cream garment hanger & price tag silhouette +
/// Terracotta eyelet & circular reuse arc) with crisp `izithrift` wordmark
/// typography.
///
/// Supports horizontal ([IzithriftLogo]), emblem-only ([IzithriftLogo.iconOnly]),
/// and centered vertical hero ([IzithriftLogo.stacked]) lockups.
class IzithriftLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final bool showWordmark;
  final bool onDarkSurface;
  final String wordmarkText;
  final bool showTagline;
  final String tagline;
  final bool stacked;

  const IzithriftLogo({
    super.key,
    this.iconSize = 32,
    this.fontSize = 20,
    this.showWordmark = true,
    this.onDarkSurface = false,
    this.wordmarkText = 'izithrift',
    this.showTagline = false,
    this.tagline = 'Đồ si tuyển chọn',
  }) : stacked = false;

  const IzithriftLogo.iconOnly({
    super.key,
    this.iconSize = 32,
    this.onDarkSurface = false,
  })  : fontSize = 0,
        showWordmark = false,
        wordmarkText = 'izithrift',
        showTagline = false,
        tagline = 'Đồ si tuyển chọn',
        stacked = false;

  const IzithriftLogo.stacked({
    super.key,
    this.iconSize = 84,
    this.fontSize = 34,
    this.onDarkSurface = false,
    this.wordmarkText = 'izithrift',
    this.showTagline = true,
    this.tagline = 'Kho đồ secondhand & vintage tuyển chọn',
  })  : showWordmark = true,
        stacked = true;

  @override
  Widget build(BuildContext context) {
    final badge = SizedBox(
      width: iconSize,
      height: iconSize,
      child: CustomPaint(
        painter: _IzithriftMarkPainter(onDarkSurface: onDarkSurface),
      ),
    );

    if (!showWordmark) {
      return badge;
    }

    final textColor = onDarkSurface ? Colors.white : AppColors.pineDeep;
    final subColor = onDarkSurface
        ? Colors.white.withValues(alpha: 0.80)
        : AppColors.textMuted;

    final wordmarkRow = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          wordmarkText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.brandWordmark.copyWith(
            fontSize: fontSize,
            color: textColor,
            letterSpacing: fontSize >= 28 ? -0.9 : -0.5,
            height: 1.05,
          ),
        ),
        Container(
          width: (fontSize * 0.23).clamp(4.0, 7.0),
          height: (fontSize * 0.23).clamp(4.0, 7.0),
          margin: const EdgeInsets.only(left: 2.5),
          decoration: const BoxDecoration(
            color: AppColors.ctaTerracotta,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );

    if (stacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          badge,
          SizedBox(height: (iconSize * 0.18).clamp(10.0, 18.0)),
          wordmarkRow,
          if (showTagline) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: onDarkSurface
                    ? Colors.white.withValues(alpha: 0.12)
                    : AppColors.creamBadgeSoft,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: onDarkSurface
                      ? AppColors.starGold.withValues(alpha: 0.45)
                      : AppColors.creamBadgeBorder,
                ),
              ),
              child: Text(
                tagline,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  fontSize: 11.5,
                  color: onDarkSurface
                      ? AppColors.creamBadgeBg
                      : AppColors.creamBadgeText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        badge,
        SizedBox(width: (iconSize * 0.26).clamp(7.0, 12.0)),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              wordmarkRow,
              if (showTagline)
                Text(
                  tagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    fontSize: (fontSize * 0.50).clamp(10.0, 12.5),
                    color: subColor,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IzithriftMarkPainter extends CustomPainter {
  final bool onDarkSurface;

  const _IzithriftMarkPainter({required this.onDarkSurface});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final rect = Rect.fromLTWH(0, 0, s, s);
    final radius = Radius.circular(s * 0.28);

    // 1. Deep Pine Green emblem backdrop
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: onDarkSurface
            ? const [Color(0xFF236B50), Color(0xFF174D38)]
            : const [Color(0xFF1B5740), Color(0xFF103828)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), bgPaint);

    // 2. Vintage Gold inner heritage border
    final borderPaint = Paint()
      ..color = AppColors.starGold.withValues(alpha: 0.52)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.032).clamp(1.0, 2.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(s * 0.055),
        Radius.circular(s * 0.23),
      ),
      borderPaint,
    );

    // 3. Vintage Clothing Hanger Hook & Thrift Tag String at top
    final hangerPaint = Paint()
      ..color = AppColors.starGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.048).clamp(1.3, 3.6)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final hookPath = Path()
      ..moveTo(s * 0.44, s * 0.21)
      ..cubicTo(s * 0.44, s * 0.12, s * 0.58, s * 0.12, s * 0.58, s * 0.20)
      ..quadraticBezierTo(s * 0.58, s * 0.26, s * 0.50, s * 0.28)
      ..lineTo(s * 0.50, s * 0.34);
    canvas.drawPath(hookPath, hangerPaint);

    // Subtle hanger shoulders extending from hook
    final shouldersPath = Path()
      ..moveTo(s * 0.25, s * 0.44)
      ..lineTo(s * 0.50, s * 0.33)
      ..lineTo(s * 0.75, s * 0.44);
    canvas.drawPath(shouldersPath, hangerPaint);

    // 4. Warm Cream Vintage Thrift Price Tag suspended from the hanger
    canvas.save();
    canvas.translate(s * 0.50, s * 0.60);
    canvas.rotate(-math.pi / 18);

    final tagPath = Path()
      ..moveTo(-s * 0.20, -s * 0.14)
      ..lineTo(-s * 0.07, -s * 0.24)
      ..lineTo(s * 0.07, -s * 0.24)
      ..lineTo(s * 0.20, -s * 0.14)
      ..lineTo(s * 0.20, s * 0.18)
      ..quadraticBezierTo(s * 0.20, s * 0.24, s * 0.14, s * 0.24)
      ..lineTo(-s * 0.14, s * 0.24)
      ..quadraticBezierTo(-s * 0.20, s * 0.24, -s * 0.20, s * 0.18)
      ..close();

    final tagFill = Paint()..color = const Color(0xFFFFFDF9);
    canvas.drawPath(tagPath, tagFill);

    // Terracotta tag eyelet punch
    final eyeletPaint = Paint()..color = AppColors.ctaTerracotta;
    canvas.drawCircle(Offset(0, -s * 0.13), s * 0.048, eyeletPaint);

    // Circular thrift reuse arc + arrowhead inside tag (Pine Green)
    final arcPaint = Paint()
      ..color = AppColors.pineDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.056).clamp(1.4, 4.2)
      ..strokeCap = StrokeCap.round;

    final arcRect = Rect.fromCenter(
      center: Offset(0, s * 0.06),
      width: s * 0.20,
      height: s * 0.20,
    );
    canvas.drawArc(arcRect, -math.pi * 0.72, math.pi * 1.44, false, arcPaint);

    // Small Terracotta stitch dot at arc tip
    canvas.drawCircle(
      Offset(s * 0.072, -s * 0.005),
      s * 0.026,
      Paint()..color = AppColors.ctaTerracotta,
    );

    canvas.restore();

    // 5. Crisp Vintage Gold 4-point star sparkle at top-right
    final cx = s * 0.79;
    final cy = s * 0.22;
    final rOuter = s * 0.095;
    final rInner = s * 0.032;
    final starPath = Path()
      ..moveTo(cx, cy - rOuter)
      ..quadraticBezierTo(cx, cy, cx + rOuter, cy)
      ..quadraticBezierTo(cx, cy, cx, cy + rOuter)
      ..quadraticBezierTo(cx, cy, cx - rOuter, cy)
      ..quadraticBezierTo(cx, cy, cx, cy - rOuter)
      ..close();
    canvas.drawPath(starPath, Paint()..color = AppColors.starGold);
    canvas.drawCircle(
      Offset(cx, cy),
      rInner * 0.55,
      Paint()..color = const Color(0xFFFFFDF9),
    );
  }

  @override
  bool shouldRepaint(covariant _IzithriftMarkPainter oldDelegate) {
    return oldDelegate.onDarkSurface != onDarkSurface;
  }
}
