import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Fashion & secondhand product category glyphs drawn as clean vector outlines.
///
/// Every glyph directly represents its apparel/product category so the Home
/// category strip and Category Taxonomy screen never rely on unrelated icons
/// (such as umbrellas, snowflakes, rulers, or shields).
enum FashionCategoryGlyph {
  americanTee,
  boxyTee,
  flareJeans,
  denimJacket,
  vintageShirt,
  trousers,
  sneakers,
  leatherBag,
  watch,
  accessories,
  sweater,
  outerwear;

  /// Maps an arbitrary Vietnamese/English taxonomy category name to the closest
  /// fashion/product glyph.
  static FashionCategoryGlyph fromCategoryName(String name) {
    final v = name.toLowerCase();
    if (v.contains('boxy')) return FashionCategoryGlyph.boxyTee;
    if (v.contains('tee') || v.contains('áo thun') || v.contains('áo phông')) {
      return FashionCategoryGlyph.americanTee;
    }
    if (v.contains('denim') && (v.contains('jacket') || v.contains('áo'))) {
      return FashionCategoryGlyph.denimJacket;
    }
    if (v.contains('jeans') || v.contains('quần bò') || v.contains('flare')) {
      return FashionCategoryGlyph.flareJeans;
    }
    if (v.contains('áo khoác') ||
        v.contains('outerwear') ||
        v.contains('coat') ||
        v.contains('măng tô') ||
        v.contains('áo dạ') ||
        v.contains('jacket')) {
      return FashionCategoryGlyph.outerwear;
    }
    if (v.contains('len') ||
        v.contains('sweater') ||
        v.contains('hoodie') ||
        v.contains('cardigan') ||
        v.contains('nỉ')) {
      return FashionCategoryGlyph.sweater;
    }
    if (v.contains('sơ mi') || v.contains('shirt') || v.contains('flannel')) {
      return FashionCategoryGlyph.vintageShirt;
    }
    if (v.contains('quần') || v.contains('trouser') || v.contains('pants')) {
      return FashionCategoryGlyph.trousers;
    }
    if (v.contains('giày') ||
        v.contains('dép') ||
        v.contains('sneaker') ||
        v.contains('boot') ||
        v.contains('shoe')) {
      return FashionCategoryGlyph.sneakers;
    }
    if (v.contains('túi') ||
        v.contains('ví') ||
        v.contains('bag') ||
        v.contains('balo')) {
      return FashionCategoryGlyph.leatherBag;
    }
    if (v.contains('đồng hồ') || v.contains('watch')) {
      return FashionCategoryGlyph.watch;
    }
    if (v.contains('kính') ||
        v.contains('phụ kiện') ||
        v.contains('trang sức') ||
        v.contains('mũ') ||
        v.contains('nón') ||
        v.contains('accessor')) {
      return FashionCategoryGlyph.accessories;
    }
    if (v.contains('áo') || v.contains('váy') || v.contains('đồ')) {
      return FashionCategoryGlyph.vintageShirt;
    }
    return FashionCategoryGlyph.americanTee;
  }
}

/// Crisp vector icon widget for secondhand fashion & product categories.
class FashionCategoryIcon extends StatelessWidget {
  final FashionCategoryGlyph glyph;
  final Color color;
  final double size;

  const FashionCategoryIcon({
    super.key,
    required this.glyph,
    required this.color,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _FashionCategoryPainter(glyph: glyph, color: color),
        ),
      ),
    );
  }
}

class _FashionCategoryPainter extends CustomPainter {
  final FashionCategoryGlyph glyph;
  final Color color;

  const _FashionCategoryPainter({
    required this.glyph,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.082).clamp(1.4, 2.2)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final detailStroke = Paint()
      ..color = color.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.06).clamp(1.1, 1.6)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final softFill = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    switch (glyph) {
      case FashionCategoryGlyph.americanTee:
        _paintAmericanTee(canvas, s, stroke, detailStroke, softFill);
      case FashionCategoryGlyph.boxyTee:
        _paintBoxyTee(canvas, s, stroke, detailStroke, softFill);
      case FashionCategoryGlyph.flareJeans:
        _paintFlareJeans(canvas, s, stroke, detailStroke, softFill);
      case FashionCategoryGlyph.denimJacket:
        _paintDenimJacket(canvas, s, stroke, detailStroke, softFill);
      case FashionCategoryGlyph.vintageShirt:
        _paintVintageShirt(canvas, s, stroke, detailStroke, softFill);
      case FashionCategoryGlyph.trousers:
        _paintTrousers(canvas, s, stroke, detailStroke, softFill);
      case FashionCategoryGlyph.sneakers:
        _paintSneakers(canvas, s, stroke, detailStroke, softFill);
      case FashionCategoryGlyph.leatherBag:
        _paintLeatherBag(canvas, s, stroke, detailStroke, softFill);
      case FashionCategoryGlyph.watch:
        _paintWatch(canvas, s, stroke, detailStroke, softFill);
      case FashionCategoryGlyph.accessories:
        _paintAccessories(canvas, s, stroke, detailStroke, softFill);
      case FashionCategoryGlyph.sweater:
        _paintSweater(canvas, s, stroke, detailStroke, softFill);
      case FashionCategoryGlyph.outerwear:
        _paintOuterwear(canvas, s, stroke, detailStroke, softFill);
    }
  }

  /// Classic vintage crew-neck tee with retro chest bar accent.
  void _paintAmericanTee(
    Canvas canvas,
    double s,
    Paint stroke,
    Paint detail,
    Paint fill,
  ) {
    final p = Path()
      ..moveTo(s * 0.34, s * 0.16)
      ..quadraticBezierTo(s * 0.50, s * 0.27, s * 0.66, s * 0.16)
      ..lineTo(s * 0.89, s * 0.30)
      ..lineTo(s * 0.78, s * 0.48)
      ..lineTo(s * 0.70, s * 0.43)
      ..lineTo(s * 0.70, s * 0.85)
      ..lineTo(s * 0.30, s * 0.85)
      ..lineTo(s * 0.30, s * 0.43)
      ..lineTo(s * 0.22, s * 0.48)
      ..lineTo(s * 0.11, s * 0.30)
      ..close();
    canvas.drawPath(p, fill);
    canvas.drawPath(p, stroke);
    // Vintage graphic stripe across chest
    canvas.drawLine(Offset(s * 0.38, s * 0.47), Offset(s * 0.62, s * 0.47), detail);
    canvas.drawLine(Offset(s * 0.42, s * 0.56), Offset(s * 0.58, s * 0.56), detail);
  }

  /// Wide-shoulder cropped boxy T-shirt silhouette.
  void _paintBoxyTee(
    Canvas canvas,
    double s,
    Paint stroke,
    Paint detail,
    Paint fill,
  ) {
    final p = Path()
      ..moveTo(s * 0.36, s * 0.20)
      ..quadraticBezierTo(s * 0.50, s * 0.29, s * 0.64, s * 0.20)
      ..lineTo(s * 0.91, s * 0.32)
      ..lineTo(s * 0.85, s * 0.54)
      ..lineTo(s * 0.74, s * 0.51)
      ..lineTo(s * 0.74, s * 0.80)
      ..lineTo(s * 0.26, s * 0.80)
      ..lineTo(s * 0.26, s * 0.51)
      ..lineTo(s * 0.15, s * 0.54)
      ..lineTo(s * 0.09, s * 0.32)
      ..close();
    canvas.drawPath(p, fill);
    canvas.drawPath(p, stroke);
    // Drop-shoulder stitch lines
    canvas.drawLine(Offset(s * 0.26, s * 0.33), Offset(s * 0.26, s * 0.51), detail);
    canvas.drawLine(Offset(s * 0.74, s * 0.33), Offset(s * 0.74, s * 0.51), detail);
  }

  /// Flared vintage denim jeans with pockets and wide hems.
  void _paintFlareJeans(
    Canvas canvas,
    double s,
    Paint stroke,
    Paint detail,
    Paint fill,
  ) {
    final p = Path()
      ..moveTo(s * 0.28, s * 0.14)
      ..lineTo(s * 0.72, s * 0.14)
      ..lineTo(s * 0.74, s * 0.44)
      ..lineTo(s * 0.86, s * 0.87)
      ..lineTo(s * 0.58, s * 0.87)
      ..lineTo(s * 0.50, s * 0.47)
      ..lineTo(s * 0.42, s * 0.87)
      ..lineTo(s * 0.14, s * 0.87)
      ..lineTo(s * 0.26, s * 0.44)
      ..close();
    canvas.drawPath(p, fill);
    canvas.drawPath(p, stroke);
    // Waistband & fly
    canvas.drawLine(Offset(s * 0.28, s * 0.24), Offset(s * 0.72, s * 0.24), detail);
    canvas.drawLine(Offset(s * 0.50, s * 0.24), Offset(s * 0.50, s * 0.39), detail);
  }

  /// Trucker denim jacket with collar, placket and chest flap pockets.
  void _paintDenimJacket(
    Canvas canvas,
    double s,
    Paint stroke,
    Paint detail,
    Paint fill,
  ) {
    final p = Path()
      ..moveTo(s * 0.33, s * 0.15)
      ..lineTo(s * 0.67, s * 0.15)
      ..lineTo(s * 0.88, s * 0.30)
      ..lineTo(s * 0.82, s * 0.76)
      ..lineTo(s * 0.71, s * 0.76)
      ..lineTo(s * 0.71, s * 0.42)
      ..lineTo(s * 0.71, s * 0.84)
      ..lineTo(s * 0.29, s * 0.84)
      ..lineTo(s * 0.29, s * 0.42)
      ..lineTo(s * 0.29, s * 0.76)
      ..lineTo(s * 0.18, s * 0.76)
      ..lineTo(s * 0.12, s * 0.30)
      ..close();
    canvas.drawPath(p, fill);
    canvas.drawPath(p, stroke);
    // Collar + center placket
    canvas.drawLine(Offset(s * 0.36, s * 0.16), Offset(s * 0.50, s * 0.29), detail);
    canvas.drawLine(Offset(s * 0.64, s * 0.16), Offset(s * 0.50, s * 0.29), detail);
    canvas.drawLine(Offset(s * 0.50, s * 0.29), Offset(s * 0.50, s * 0.84), detail);
    // Chest pockets
    canvas.drawRect(Rect.fromLTWH(s * 0.34, s * 0.39, s * 0.11, s * 0.11), detail);
    canvas.drawRect(Rect.fromLTWH(s * 0.55, s * 0.39, s * 0.11, s * 0.11), detail);
  }

  /// Collared vintage button-up shirt.
  void _paintVintageShirt(
    Canvas canvas,
    double s,
    Paint stroke,
    Paint detail,
    Paint fill,
  ) {
    final p = Path()
      ..moveTo(s * 0.34, s * 0.15)
      ..lineTo(s * 0.66, s * 0.15)
      ..lineTo(s * 0.87, s * 0.31)
      ..lineTo(s * 0.78, s * 0.50)
      ..lineTo(s * 0.70, s * 0.46)
      ..lineTo(s * 0.70, s * 0.85)
      ..lineTo(s * 0.30, s * 0.85)
      ..lineTo(s * 0.30, s * 0.46)
      ..lineTo(s * 0.22, s * 0.50)
      ..lineTo(s * 0.13, s * 0.31)
      ..close();
    canvas.drawPath(p, fill);
    canvas.drawPath(p, stroke);
    // Pointed collar & button placket
    canvas.drawLine(Offset(s * 0.35, s * 0.16), Offset(s * 0.43, s * 0.31), detail);
    canvas.drawLine(Offset(s * 0.43, s * 0.31), Offset(s * 0.50, s * 0.24), detail);
    canvas.drawLine(Offset(s * 0.65, s * 0.16), Offset(s * 0.57, s * 0.31), detail);
    canvas.drawLine(Offset(s * 0.57, s * 0.31), Offset(s * 0.50, s * 0.24), detail);
    canvas.drawLine(Offset(s * 0.50, s * 0.24), Offset(s * 0.50, s * 0.85), detail);
    // Left chest pocket
    canvas.drawRect(Rect.fromLTWH(s * 0.55, s * 0.41, s * 0.10, s * 0.11), detail);
  }

  /// Tailored straight-leg vintage trousers with front crease lines.
  void _paintTrousers(
    Canvas canvas,
    double s,
    Paint stroke,
    Paint detail,
    Paint fill,
  ) {
    final p = Path()
      ..moveTo(s * 0.27, s * 0.14)
      ..lineTo(s * 0.73, s * 0.14)
      ..lineTo(s * 0.76, s * 0.87)
      ..lineTo(s * 0.55, s * 0.87)
      ..lineTo(s * 0.50, s * 0.44)
      ..lineTo(s * 0.45, s * 0.87)
      ..lineTo(s * 0.24, s * 0.87)
      ..close();
    canvas.drawPath(p, fill);
    canvas.drawPath(p, stroke);
    // Waistband & pressed pleats
    canvas.drawLine(Offset(s * 0.27, s * 0.24), Offset(s * 0.73, s * 0.24), detail);
    canvas.drawLine(Offset(s * 0.38, s * 0.24), Offset(s * 0.36, s * 0.48), detail);
    canvas.drawLine(Offset(s * 0.62, s * 0.24), Offset(s * 0.64, s * 0.48), detail);
  }

  /// Retro low-top sneaker side profile with sole and laces.
  void _paintSneakers(
    Canvas canvas,
    double s,
    Paint stroke,
    Paint detail,
    Paint fill,
  ) {
    final p = Path()
      ..moveTo(s * 0.15, s * 0.38)
      ..lineTo(s * 0.32, s * 0.38)
      ..quadraticBezierTo(s * 0.40, s * 0.47, s * 0.50, s * 0.44)
      ..lineTo(s * 0.68, s * 0.55)
      ..quadraticBezierTo(s * 0.88, s * 0.57, s * 0.89, s * 0.70)
      ..lineTo(s * 0.89, s * 0.77)
      ..lineTo(s * 0.13, s * 0.77)
      ..lineTo(s * 0.13, s * 0.44)
      ..quadraticBezierTo(s * 0.13, s * 0.38, s * 0.15, s * 0.38)
      ..close();
    canvas.drawPath(p, fill);
    canvas.drawPath(p, stroke);
    // Midsole line & shoelaces
    canvas.drawLine(Offset(s * 0.14, s * 0.69), Offset(s * 0.88, s * 0.69), detail);
    canvas.drawLine(Offset(s * 0.52, s * 0.47), Offset(s * 0.56, s * 0.42), detail);
    canvas.drawLine(Offset(s * 0.60, s * 0.52), Offset(s * 0.64, s * 0.47), detail);
  }

  /// Structured vintage leather bag with handle & front flap clasp.
  void _paintLeatherBag(
    Canvas canvas,
    double s,
    Paint stroke,
    Paint detail,
    Paint fill,
  ) {
    // Handle arc
    final handle = Rect.fromLTWH(s * 0.34, s * 0.16, s * 0.32, s * 0.26);
    canvas.drawArc(handle, math.pi, math.pi, false, stroke);

    // Body
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.16, s * 0.32, s * 0.68, s * 0.52),
      Radius.circular(s * 0.10),
    );
    canvas.drawRRect(body, fill);
    canvas.drawRRect(body, stroke);

    // Flap line & brass clasp
    final flap = Path()
      ..moveTo(s * 0.16, s * 0.50)
      ..quadraticBezierTo(s * 0.50, s * 0.58, s * 0.84, s * 0.50);
    canvas.drawPath(flap, detail);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(s * 0.50, s * 0.55),
          width: s * 0.11,
          height: s * 0.11,
        ),
        Radius.circular(s * 0.025),
      ),
      detail,
    );
  }

  /// Classic round mechanical wristwatch with lugs and hands.
  void _paintWatch(
    Canvas canvas,
    double s,
    Paint stroke,
    Paint detail,
    Paint fill,
  ) {
    // Top & bottom straps
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.36, s * 0.12, s * 0.28, s * 0.18),
        Radius.circular(s * 0.04),
      ),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.36, s * 0.70, s * 0.28, s * 0.18),
        Radius.circular(s * 0.04),
      ),
      stroke,
    );

    // Dial case
    final center = Offset(s * 0.50, s * 0.50);
    canvas.drawCircle(center, s * 0.25, fill);
    canvas.drawCircle(center, s * 0.25, stroke);

    // Crown
    canvas.drawLine(Offset(s * 0.76, s * 0.46), Offset(s * 0.81, s * 0.46), stroke);
    canvas.drawLine(Offset(s * 0.76, s * 0.54), Offset(s * 0.81, s * 0.54), stroke);

    // Hands
    canvas.drawLine(center, Offset(s * 0.50, s * 0.36), detail);
    canvas.drawLine(center, Offset(s * 0.61, s * 0.50), detail);
  }

  /// Vintage retro round sunglasses (iconic fashion accessory).
  void _paintAccessories(
    Canvas canvas,
    double s,
    Paint stroke,
    Paint detail,
    Paint fill,
  ) {
    // Temples (arms)
    final leftArm = Path()
      ..moveTo(s * 0.12, s * 0.50)
      ..lineTo(s * 0.24, s * 0.30)
      ..lineTo(s * 0.31, s * 0.30);
    final rightArm = Path()
      ..moveTo(s * 0.88, s * 0.50)
      ..lineTo(s * 0.76, s * 0.30)
      ..lineTo(s * 0.69, s * 0.30);
    canvas.drawPath(leftArm, detail);
    canvas.drawPath(rightArm, detail);

    // Lenses
    final leftLens = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.12, s * 0.45, s * 0.31, s * 0.26),
      Radius.circular(s * 0.11),
    );
    final rightLens = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.57, s * 0.45, s * 0.31, s * 0.26),
      Radius.circular(s * 0.11),
    );
    canvas.drawRRect(leftLens, fill);
    canvas.drawRRect(rightLens, fill);
    canvas.drawRRect(leftLens, stroke);
    canvas.drawRRect(rightLens, stroke);

    // Bridge
    final bridge = Path()
      ..moveTo(s * 0.43, s * 0.54)
      ..quadraticBezierTo(s * 0.50, s * 0.47, s * 0.57, s * 0.54);
    canvas.drawPath(bridge, stroke);
  }

  /// Cozy long-sleeve vintage knit crewneck sweater with ribbed hem & cuffs.
  void _paintSweater(
    Canvas canvas,
    double s,
    Paint stroke,
    Paint detail,
    Paint fill,
  ) {
    final p = Path()
      ..moveTo(s * 0.35, s * 0.16)
      ..quadraticBezierTo(s * 0.50, s * 0.27, s * 0.65, s * 0.16)
      ..lineTo(s * 0.86, s * 0.29)
      ..lineTo(s * 0.89, s * 0.78)
      ..lineTo(s * 0.76, s * 0.78)
      ..lineTo(s * 0.72, s * 0.44)
      ..lineTo(s * 0.72, s * 0.84)
      ..lineTo(s * 0.28, s * 0.84)
      ..lineTo(s * 0.28, s * 0.44)
      ..lineTo(s * 0.24, s * 0.78)
      ..lineTo(s * 0.11, s * 0.78)
      ..lineTo(s * 0.14, s * 0.29)
      ..close();
    canvas.drawPath(p, fill);
    canvas.drawPath(p, stroke);
    // Ribbed hem & Nordic knit chevron
    canvas.drawLine(Offset(s * 0.28, s * 0.75), Offset(s * 0.72, s * 0.75), detail);
    final chevron = Path()
      ..moveTo(s * 0.34, s * 0.46)
      ..lineTo(s * 0.42, s * 0.39)
      ..lineTo(s * 0.50, s * 0.46)
      ..lineTo(s * 0.58, s * 0.39)
      ..lineTo(s * 0.66, s * 0.46);
    canvas.drawPath(chevron, detail);
  }

  /// Long vintage trench coat / wool outerwear with lapels and buttons.
  void _paintOuterwear(
    Canvas canvas,
    double s,
    Paint stroke,
    Paint detail,
    Paint fill,
  ) {
    final p = Path()
      ..moveTo(s * 0.35, s * 0.13)
      ..lineTo(s * 0.65, s * 0.13)
      ..lineTo(s * 0.86, s * 0.27)
      ..lineTo(s * 0.84, s * 0.72)
      ..lineTo(s * 0.73, s * 0.72)
      ..lineTo(s * 0.72, s * 0.40)
      ..lineTo(s * 0.76, s * 0.88)
      ..lineTo(s * 0.24, s * 0.88)
      ..lineTo(s * 0.28, s * 0.40)
      ..lineTo(s * 0.27, s * 0.72)
      ..lineTo(s * 0.16, s * 0.72)
      ..lineTo(s * 0.14, s * 0.27)
      ..close();
    canvas.drawPath(p, fill);
    canvas.drawPath(p, stroke);
    // Lapels & waist belt
    canvas.drawLine(Offset(s * 0.36, s * 0.15), Offset(s * 0.50, s * 0.37), detail);
    canvas.drawLine(Offset(s * 0.64, s * 0.15), Offset(s * 0.50, s * 0.37), detail);
    canvas.drawLine(Offset(s * 0.50, s * 0.37), Offset(s * 0.50, s * 0.88), detail);
    canvas.drawLine(Offset(s * 0.27, s * 0.56), Offset(s * 0.73, s * 0.56), detail);
  }

  @override
  bool shouldRepaint(covariant _FashionCategoryPainter oldDelegate) {
    return oldDelegate.glyph != glyph || oldDelegate.color != color;
  }
}
