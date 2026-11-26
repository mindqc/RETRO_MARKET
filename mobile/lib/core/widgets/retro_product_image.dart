import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/product_image_resolver.dart';
import 'state_feedback_views.dart';

/// Unified product photography widget for Retro Market (izithrift).
///
/// Supports:
/// - Bundled local studio product photos (`assets/images/products/...`)
/// - Remote HTTP/HTTPS URLs via `CachedNetworkImage` with shimmer loading
/// - Automatic category-matched local photography fallback if any URL is missing or fails
/// - Optional static placeholder for widget-test-friendly screens
class RetroProductImage extends StatelessWidget {
  final String? imageUrl;
  final String? title;
  final String? categoryName;
  final int productId;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  /// When true, remote images use a static placeholder instead of shimmer.
  ///
  /// This is useful for screens whose widget tests use pumpAndSettle(),
  /// because shimmer contains an infinite animation.
  /// Defaults to false to preserve the existing behavior.
  final bool useStaticPlaceholder;

  const RetroProductImage({
    super.key,
    this.imageUrl,
    this.title,
    this.categoryName,
    this.productId = 0,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.useStaticPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = ProductImageResolver.resolveImage(
      rawUrl: imageUrl,
      title: title,
      categoryName: categoryName,
      id: productId,
    );

    final fallbackAsset = ProductImageResolver.fallbackAssetFor(
      title: title,
      categoryName: categoryName,
      id: productId,
    );

    Widget imageWidget;

    if (ProductImageResolver.isLocalAsset(resolved)) {
      imageWidget = Image.asset(
        resolved,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _styledIconFallback(),
      );
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: resolved,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => useStaticPlaceholder
            ? _styledIconFallback()
            : RetroShimmerBox(
                width: width ?? double.infinity,
                height: height ?? double.infinity,
              ),
        errorWidget: (context, url, error) => Image.asset(
          fallbackAsset,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, err, stackTrace) => _styledIconFallback(),
        ),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _styledIconFallback() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceWarm,
      child: const Center(
        child: Icon(
          Icons.checkroom_outlined,
          color: AppColors.primaryVintageBrown,
          size: 32,
        ),
      ),
    );
  }
}