import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Custom brand mark and wordmark for `izithrift`.
///
/// Combines a stylized vintage clothing tag + circular reuse arc + subtle
/// winter-star sparkle in Deep Pine Green (#174D38), Vintage Gold (#D6AE55),
/// and Terracotta (#C65335). Cleanly scalable from 24px app bars to splash screens.
class IzithriftLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final bool showWordmark;
  final bool onDarkSurface;
  final String wordmarkText;
  final bool showTagline;

  const IzithriftLogo({
    super.key,
    this.iconSize = 32,
    this.fontSize = 20,
    this.showWordmark = true,
    this.onDarkSurface = false,
    this.wordmarkText = 'izithrift',
    this.showTagline = false,
  });

  const IzithriftLogo.iconOnly({
    super.key,
    this.iconSize = 32,
    this.onDarkSurface = false,
  })  : fontSize = 0,
        showWordmark = false,
        wordmarkText = 'izithrift',
        showTagline = false;

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
        ? Colors.white.withValues(alpha: 0.78)
        : AppColors.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        badge,
        SizedBox(width: iconSize * 0.28),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      letterSpacing: -0.5,
                      height: 1.05,
                    ),
                  ),
                  Container(
                    width: (fontSize * 0.24).clamp(4.0, 6.5),
                    height: (fontSize * 0.24).clamp(4.0, 6.5),
                    margin: const EdgeInsets.only(left: 2),
                    decoration: const BoxDecoration(
                      color: AppColors.ctaTerracotta,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              if (showTagline)
                Text(
                  'Đồ si tuyển chọn',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    fontSize: (fontSize * 0.52).clamp(10.0, 13.0),
                    color: subColor,
                    fontWeight: FontWeight.w500,
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

    // 1. Deep Pine Green rounded square emblem backdrop
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: onDarkSurface
            ? const [Color(0xFF21664B), Color(0xFF174D38)]
            : const [Color(0xFF174D38), Color(0xFF113C2B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), bgPaint);

    // Subtle vintage gold inner border
    final borderPaint = Paint()
      ..color = AppColors.starGold.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.032;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(s * 0.035), Radius.circular(s * 0.25)),
      borderPaint,
    );

    // 2. Stylized Vintage Thrift Price Tag (rotated cleanly inside)
    canvas.save();
    canvas.translate(s * 0.50, s * 0.51);
    canvas.rotate(-math.pi / 12);

    final tagPath = Path()
      ..moveTo(-s * 0.24, -s * 0.08)
      ..lineTo(-s * 0.06, -s * 0.25)
      ..lineTo(s * 0.20, -s * 0.25)
      ..quadraticBezierTo(s * 0.26, -s * 0.25, s * 0.26, -s * 0.19)
      ..lineTo(s * 0.26, s * 0.19)
      ..quadraticBezierTo(s * 0.26, s * 0.25, s * 0.20, s * 0.25)
      ..lineTo(-s * 0.18, s * 0.25)
      ..quadraticBezierTo(-s * 0.24, s * 0.25, -s * 0.24, s * 0.19)
      ..close();

    final tagFill = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawPath(tagPath, tagFill);

    // Punch hole in tag corner (Terracotta accent)
    final holePaint = Paint()..color = AppColors.ctaTerracotta;
    canvas.drawCircle(Offset(-s * 0.07, -s * 0.12), s * 0.055, holePaint);

    // Minimalist thrift circular reuse arc inside the tag
    final arcPaint = Paint()
      ..color = AppColors.pineDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.062
      ..strokeCap = StrokeCap.round;

    final arcRect = Rect.fromCenter(
      center: Offset(s * 0.04, s * 0.06),
      width: s * 0.22,
      height: s * 0.22,
    );
    canvas.drawArc(arcRect, -math.pi * 0.78, math.pi * 1.48, false, arcPaint);

    canvas.restore();

    // 3. Subtle Vintage Gold 4-point star sparkle at top-right (seasonal touch)
    final cx = s * 0.79;
    final cy = s * 0.22;
    final rOuter = s * 0.105;
    final rInner = s * 0.036;
    final starPath = Path()
      ..moveTo(cx, cy - rOuter)
      ..quadraticBezierTo(cx, cy, cx + rOuter, cy)
      ..quadraticBezierTo(cx, cy, cx, cy + rOuter)
      ..quadraticBezierTo(cx, cy, cx - rOuter, cy)
      ..quadraticBezierTo(cx, cy, cx, cy - rOuter)
      ..close();
    final starPaint = Paint()..color = AppColors.starGold;
    canvas.drawPath(starPath, starPaint);

    // Tiny center highlight on star
    canvas.drawCircle(
      Offset(cx, cy),
      rInner * 0.55,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _IzithriftMarkPainter oldDelegate) {
    return oldDelegate.onDarkSurface != onDarkSurface;
  }
}
