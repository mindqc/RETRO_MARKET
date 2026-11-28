import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/product_image_resolver.dart';

/// Illustrated friendly avatar styles for izithrift shops.
enum ShopAvatarVariant {
  cat,
  dog,
  storefront,
  monogram,
}

/// Brand color theme options (Pine, Terracotta, Vintage Gold) for shop avatars.
enum ShopAvatarPalette {
  pine,
  terracotta,
  gold,
}

/// Unified friendly shop avatar used consistently across product cards,
/// product detail pages, storefronts, nearby shops, and followed shops.
///
/// Automatically replaces default/seeded human-portrait URLs (e.g. Unsplash
/// stock faces or placeholder hosts) with a deterministic friendly illustration
/// (cute cat, friendly dog, cozy thrift shop emblem, or vintage monogram) on
/// Pine / Terracotta / Gold backgrounds.
class RetroShopAvatar extends StatelessWidget {
  final int? sellerId;
  final String shopName;
  final String? avatarUrl;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final bool allowCustomNetworkImage;

  const RetroShopAvatar({
    super.key,
    this.sellerId,
    required this.shopName,
    this.avatarUrl,
    this.size = 40,
    this.borderColor,
    this.borderWidth = 1.5,
    this.allowCustomNetworkImage = true,
  });

  /// Returns true when [rawUrl] is missing, invalid, or points to a stock/sample
  /// human portrait host (such as Unsplash seeded faces or placeholder hosts).
  static bool isSampleOrPortraitUrl(String? rawUrl) {
    final normalized = ProductImageResolver.normalizeImageUrl(rawUrl);
    if (normalized == null || normalized.isEmpty) return true;
    final lower = normalized.toLowerCase();

    if (lower.contains('images.unsplash.com') ||
        lower.contains('unsplash.com') ||
        lower.contains('pravatar.cc') ||
        lower.contains('randomuser.me') ||
        lower.contains('images.pexels.com') ||
        lower.contains('ui-avatars.com') ||
        lower.contains('dicebear.com') ||
        lower.contains('placeholder') ||
        lower.contains('izithrift.local') ||
        lower.contains('example.com')) {
      return true;
    }

    return !(lower.startsWith('http://') || lower.startsWith('https://'));
  }

  /// Deterministic hash seed derived from [sellerId] and [shopName] so every
  /// shop renders the exact same friendly avatar across all screens.
  static int seedFor({int? sellerId, required String shopName}) {
    final normalizedName = shopName.trim().toLowerCase();
    var nameHash = 0;
    for (final unit in normalizedName.codeUnits) {
      nameHash = (nameHash * 31 + unit) & 0x7fffffff;
    }
    if (sellerId != null && sellerId > 0) {
      return (sellerId * 17 + (nameHash % 13)).abs();
    }
    return nameHash.abs();
  }

  /// Deterministic friendly style (cat, dog, storefront, monogram) per shop.
  static ShopAvatarVariant variantFor({int? sellerId, required String shopName}) {
    final seed = seedFor(sellerId: sellerId, shopName: shopName);
    return ShopAvatarVariant.values[seed % ShopAvatarVariant.values.length];
  }

  /// Deterministic Pine / Terracotta / Gold color palette per shop.
  static ShopAvatarPalette paletteFor({int? sellerId, required String shopName}) {
    final seed = seedFor(sellerId: sellerId, shopName: shopName);
    return ShopAvatarPalette.values[(seed ~/ 2) % ShopAvatarPalette.values.length];
  }

  /// Extracts clean 1–2 letter monogram initials from a Vietnamese/English shop name.
  static String extractInitials(String shopName) {
    final trimmed = shopName.trim();
    if (trimmed.isEmpty) return 'IZ';

    const skipPrefixes = {
      'tiệm',
      'tiem',
      'shop',
      'cửa',
      'hàng',
      'đồ',
      'do',
      'si',
      'the',
    };

    final rawWords = trimmed
        .split(RegExp(r'[\s\-_•]+'))
        .where((w) => w.isNotEmpty)
        .toList();

    final meaningful = rawWords
        .where((w) => !skipPrefixes.contains(w.toLowerCase()))
        .toList();

    final source = meaningful.isNotEmpty ? meaningful : rawWords;
    if (source.isEmpty) return 'IZ';
    if (source.length == 1) {
      final w = source.first;
      return w.length >= 2
          ? w.substring(0, 2).toUpperCase()
          : w.substring(0, 1).toUpperCase();
    }
    return '${source[0].substring(0, 1)}${source[1].substring(0, 1)}'
        .toUpperCase();
  }

  _PaletteColors _colorsFor(ShopAvatarPalette palette) {
    switch (palette) {
      case ShopAvatarPalette.pine:
        return const _PaletteColors(
          bgStart: AppColors.pineBannerLight,
          bgEnd: AppColors.pineDeep,
          primaryInk: AppColors.creamBadgeBg,
          accentInk: AppColors.starGold,
          detailInk: AppColors.pineDeep,
        );
      case ShopAvatarPalette.terracotta:
        return const _PaletteColors(
          bgStart: Color(0xFFD66A42),
          bgEnd: AppColors.ctaTerracotta,
          primaryInk: AppColors.creamBadgeBg,
          accentInk: Color(0xFFF6DFB0),
          detailInk: Color(0xFF5D2614),
        );
      case ShopAvatarPalette.gold:
        return const _PaletteColors(
          bgStart: Color(0xFFD8B876),
          bgEnd: AppColors.brandGold,
          primaryInk: AppColors.pineDeep,
          accentInk: AppColors.creamBadgeBg,
          detailInk: AppColors.creamBadgeBg,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = ProductImageResolver.normalizeImageUrl(avatarUrl);
    final useCustomNetwork = allowCustomNetworkImage &&
        normalizedUrl != null &&
        !isSampleOrPortraitUrl(normalizedUrl);

    final palette = paletteFor(sellerId: sellerId, shopName: shopName);
    final colors = _colorsFor(palette);
    final variant = variantFor(sellerId: sellerId, shopName: shopName);

    final illustrated = _buildIllustratedAvatar(variant, colors);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderWidth > 0
            ? Border.all(
                color: borderColor ?? AppColors.creamBadgeBorder,
                width: borderWidth,
              )
            : null,
      ),
      child: ClipOval(
        child: useCustomNetwork
            ? CachedNetworkImage(
                imageUrl: normalizedUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_, _) => illustrated,
                errorWidget: (_, _, _) => illustrated,
              )
            : illustrated,
      ),
    );
  }

  Widget _buildIllustratedAvatar(
    ShopAvatarVariant variant,
    _PaletteColors colors,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [colors.bgStart, colors.bgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: variant == ShopAvatarVariant.monogram
          ? Text(
              extractInitials(shopName),
              maxLines: 1,
              style: TextStyle(
                fontFamily: AppTypography.fontHeading,
                fontSize: (size * 0.38).clamp(7.0, 24.0),
                fontWeight: FontWeight.w800,
                color: colors.primaryInk,
                letterSpacing: -0.3,
                height: 1.0,
              ),
            )
          : CustomPaint(
              size: Size.square(size),
              painter: _ShopMascotPainter(
                variant: variant,
                colors: colors,
              ),
            ),
    );
  }
}

class _PaletteColors {
  final Color bgStart;
  final Color bgEnd;
  final Color primaryInk;
  final Color accentInk;
  final Color detailInk;

  const _PaletteColors({
    required this.bgStart,
    required this.bgEnd,
    required this.primaryInk,
    required this.accentInk,
    required this.detailInk,
  });
}

class _ShopMascotPainter extends CustomPainter {
  final ShopAvatarVariant variant;
  final _PaletteColors colors;

  const _ShopMascotPainter({
    required this.variant,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (variant) {
      case ShopAvatarVariant.cat:
        _paintCat(canvas, size);
      case ShopAvatarVariant.dog:
        _paintDog(canvas, size);
      case ShopAvatarVariant.storefront:
        _paintStorefront(canvas, size);
      case ShopAvatarVariant.monogram:
        break;
    }
  }

  void _paintCat(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()
      ..color = colors.primaryInk
      ..style = PaintingStyle.fill;
    final accent = Paint()
      ..color = colors.accentInk
      ..style = PaintingStyle.fill;
    final detail = Paint()
      ..color = colors.detailInk
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = colors.detailInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.045).clamp(0.7, 2.2)
      ..strokeCap = StrokeCap.round;

    // Left & right pointed ears
    final leftEar = Path()
      ..moveTo(w * 0.27, h * 0.48)
      ..lineTo(w * 0.25, h * 0.22)
      ..lineTo(w * 0.44, h * 0.34)
      ..close();
    final rightEar = Path()
      ..moveTo(w * 0.73, h * 0.48)
      ..lineTo(w * 0.75, h * 0.22)
      ..lineTo(w * 0.56, h * 0.34)
      ..close();
    canvas.drawPath(leftEar, fill);
    canvas.drawPath(rightEar, fill);

    // Inner ears
    final leftInner = Path()
      ..moveTo(w * 0.30, h * 0.42)
      ..lineTo(w * 0.29, h * 0.28)
      ..lineTo(w * 0.40, h * 0.35)
      ..close();
    final rightInner = Path()
      ..moveTo(w * 0.70, h * 0.42)
      ..lineTo(w * 0.71, h * 0.28)
      ..lineTo(w * 0.60, h * 0.35)
      ..close();
    canvas.drawPath(leftInner, accent);
    canvas.drawPath(rightInner, accent);

    // Rounded cat head
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.56),
        width: w * 0.54,
        height: h * 0.46,
      ),
      fill,
    );

    // Eyes
    final eyeR = (w * 0.042).clamp(0.7, 2.8);
    canvas.drawCircle(Offset(w * 0.40, h * 0.53), eyeR, detail);
    canvas.drawCircle(Offset(w * 0.60, h * 0.53), eyeR, detail);

    // Cute triangle nose
    final nose = Path()
      ..moveTo(w * 0.46, h * 0.59)
      ..lineTo(w * 0.54, h * 0.59)
      ..lineTo(w * 0.50, h * 0.64)
      ..close();
    canvas.drawPath(nose, accent);

    // Tiny whiskers (only visible clearly above mini sizes)
    if (w >= 24) {
      final whiskerStroke = Paint()
        ..color = colors.detailInk.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (w * 0.03).clamp(0.7, 1.5)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(w * 0.27, h * 0.59),
        Offset(w * 0.37, h * 0.61),
        whiskerStroke,
      );
      canvas.drawLine(
        Offset(w * 0.27, h * 0.65),
        Offset(w * 0.37, h * 0.64),
        whiskerStroke,
      );
      canvas.drawLine(
        Offset(w * 0.73, h * 0.59),
        Offset(w * 0.63, h * 0.61),
        whiskerStroke,
      );
      canvas.drawLine(
        Offset(w * 0.73, h * 0.65),
        Offset(w * 0.63, h * 0.64),
        whiskerStroke,
      );

      // Gentle smile arc
      final smileRect = Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.65),
        width: w * 0.14,
        height: h * 0.08,
      );
      canvas.drawArc(smileRect, 0.15, math.pi - 0.3, false, stroke);
    }
  }

  void _paintDog(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()
      ..color = colors.primaryInk
      ..style = PaintingStyle.fill;
    final earPaint = Paint()
      ..color = colors.accentInk
      ..style = PaintingStyle.fill;
    final detail = Paint()
      ..color = colors.detailInk
      ..style = PaintingStyle.fill;

    // Floppy puppy ears
    canvas.save();
    canvas.translate(w * 0.27, h * 0.48);
    canvas.rotate(0.24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w * 0.18, height: h * 0.34),
        Radius.circular(w * 0.10),
      ),
      earPaint,
    );
    canvas.restore();

    canvas.save();
    canvas.translate(w * 0.73, h * 0.48);
    canvas.rotate(-0.24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w * 0.18, height: h * 0.34),
        Radius.circular(w * 0.10),
      ),
      earPaint,
    );
    canvas.restore();

    // Puppy head
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.52),
        width: w * 0.50,
        height: h * 0.48,
      ),
      fill,
    );

    // Eyes
    final eyeR = (w * 0.042).clamp(0.7, 2.8);
    canvas.drawCircle(Offset(w * 0.40, h * 0.48), eyeR, detail);
    canvas.drawCircle(Offset(w * 0.60, h * 0.48), eyeR, detail);

    // Snout oval
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.62),
        width: w * 0.24,
        height: h * 0.16,
      ),
      earPaint,
    );

    // Rounded puppy nose
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.58),
        width: w * 0.11,
        height: h * 0.08,
      ),
      detail,
    );

    if (w >= 24) {
      final stroke = Paint()
        ..color = colors.detailInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = (w * 0.04).clamp(0.7, 2.0)
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.64),
          width: w * 0.12,
          height: h * 0.08,
        ),
        0.15,
        math.pi - 0.3,
        false,
        stroke,
      );
    }
  }

  void _paintStorefront(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()
      ..color = colors.primaryInk
      ..style = PaintingStyle.fill;
    final accent = Paint()
      ..color = colors.accentInk
      ..style = PaintingStyle.fill;
    final detail = Paint()
      ..color = colors.detailInk
      ..style = PaintingStyle.fill;

    // Vintage awning roof
    final awning = Path()
      ..moveTo(w * 0.24, h * 0.42)
      ..lineTo(w * 0.30, h * 0.26)
      ..lineTo(w * 0.70, h * 0.26)
      ..lineTo(w * 0.76, h * 0.42)
      ..close();
    canvas.drawPath(awning, accent);

    // Scallops under awning
    for (var i = 0; i < 4; i++) {
      final cx = w * (0.305 + i * 0.13);
      canvas.drawCircle(Offset(cx, h * 0.42), w * 0.066, i.isEven ? fill : accent);
    }

    // Shop body
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.28, h * 0.44, w * 0.44, h * 0.30),
        bottomLeft: Radius.circular(w * 0.06),
        bottomRight: Radius.circular(w * 0.06),
      ),
      fill,
    );

    // Cozy shop door + display window
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.33, h * 0.52, w * 0.15, h * 0.22),
        Radius.circular(w * 0.03),
      ),
      detail,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.53, h * 0.52, w * 0.14, h * 0.13),
        Radius.circular(w * 0.03),
      ),
      accent,
    );
  }

  @override
  bool shouldRepaint(covariant _ShopMascotPainter oldDelegate) {
    return oldDelegate.variant != variant || oldDelegate.colors != colors;
  }
}
