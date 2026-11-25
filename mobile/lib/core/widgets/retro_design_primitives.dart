import 'dart:async';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';

/// Shared visual primitives implementing the approved Retro Market (izithrift)
/// Cozy Vintage Editorial design language across all screens.

/// Subtle parchment header/brand wordmark matching the reference Home top bar.
/// Keeps exact [titleText] strings so navigation & screen tests stay intact.
class RetroBrandWordmark extends StatelessWidget {
  final String titleText;
  final bool showSeasonalAccent;

  const RetroBrandWordmark({
    super.key,
    required this.titleText,
    this.showSeasonalAccent = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSeasonalAccent) ...[
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.priceCrimson,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.ac_unit_rounded,
              color: AppColors.creamBadgeBg,
              size: 13,
            ),
          ),
          const SizedBox(width: 7),
        ],
        Flexible(
          child: Text(
            titleText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.brandWordmark.copyWith(fontSize: 19),
          ),
        ),
        if (showSeasonalAccent) ...[
          const SizedBox(width: 4),
          const Icon(
            Icons.auto_awesome,
            size: 14,
            color: AppColors.starGold,
          ),
        ],
      ],
    );
  }
}

/// Outlined top-bar icon button with optional crimson notification counter pill.
class RetroHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final int badgeCount;

  const RetroHeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(icon, color: AppColors.textCharcoal, size: 23),
          tooltip: tooltip,
          onPressed: onPressed,
        ),
        if (badgeCount > 0)
          Positioned(
            top: 6,
            right: 6,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                decoration: const BoxDecoration(
                  color: AppColors.priceCrimson,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontBody,
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Elevated full-pill search trigger matching the reference Home search bar.
class RetroSearchPill extends StatelessWidget {
  final String placeholder;
  final VoidCallback onTap;
  final VoidCallback? onFilterTap;

  const RetroSearchPill({
    super.key,
    required this.placeholder,
    required this.onTap,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: DesignTokens.borderRadiusFull,
      child: InkWell(
        onTap: onTap,
        borderRadius: DesignTokens.borderRadiusFull,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: DesignTokens.borderRadiusFull,
            border: Border.all(color: AppColors.borderWarm, width: 1),
            boxShadow: DesignTokens.cardElevation,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: AppColors.textCharcoal,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onFilterTap ?? onTap,
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.textCharcoal,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Elevated soft-cream rounded container matching the "Deal Hot Hôm Nay" section card.
class RetroSectionContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;

  const RetroSectionContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DesignTokens.spaceLg),
    this.backgroundColor = AppColors.surfaceSection,
    this.borderColor = AppColors.borderWarm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: DesignTokens.borderRadiusBanner,
        border: Border.all(color: borderColor, width: 1),
        boxShadow: DesignTokens.sectionContainerShadow,
      ),
      child: child,
    );
  }
}

/// Deep Pine Green spotlight container matching the reference "Đấu giá sắp diễn ra" module.
class RetroPineSpotlightContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const RetroPineSpotlightContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.pineDeep, AppColors.pineBanner],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: DesignTokens.borderRadiusBanner,
        border: Border.all(
          color: AppColors.accentVintageGold.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: DesignTokens.bannerElevation,
      ),
      child: child,
    );
  }
}

/// Editorial section header with crisp icon, Fraunces title, optional subtitle, and "Xem tất cả >".
class RetroSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool darkSurface;

  const RetroSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor = AppColors.starGold,
    this.actionLabel,
    this.onAction,
    this.darkSurface = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor =
        darkSurface ? AppColors.textLight : AppColors.textCharcoal;
    final subColor =
        darkSurface ? const Color(0xFFCCD9CE) : AppColors.textMuted;
    final actionColor =
        darkSurface ? AppColors.creamBadgeBg : AppColors.pineDeep;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 19, color: iconColor),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headingMedium.copyWith(
                        fontSize: 18,
                        color: titleColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: subColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onAction != null)
          InkWell(
            onTap: onAction,
            borderRadius: DesignTokens.borderRadiusFull,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel ?? 'Xem tất cả',
                    style: AppTypography.caption.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: actionColor,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: actionColor,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Compact verified shop label ("Shop uy tín") matching the reference product & shop cards.
class RetroVerifiedShopChip extends StatelessWidget {
  final String label;
  final double fontSize;

  const RetroVerifiedShopChip({
    super.key,
    this.label = 'Shop uy tín',
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.verified_rounded,
          size: fontSize + 2,
          color: AppColors.verifiedLeaf,
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.verifiedLeaf,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Warm cream-gold segmented flip-clock countdown (`01 : 24 : 32`)
/// matching the reference dark pine-green auction spotlight header.
class RetroSegmentedCountdown extends StatefulWidget {
  final DateTime endsAt;
  final DateTime Function()? customClock;

  const RetroSegmentedCountdown({
    super.key,
    required this.endsAt,
    this.customClock,
  });

  @override
  State<RetroSegmentedCountdown> createState() =>
      _RetroSegmentedCountdownState();
}

class _RetroSegmentedCountdownState extends State<RetroSegmentedCountdown> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _sync();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(_sync);
    });
  }

  @override
  void didUpdateWidget(covariant RetroSegmentedCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endsAt != widget.endsAt) {
      _sync();
    }
  }

  void _sync() {
    final now = widget.customClock?.call() ?? DateTime.now();
    final diff = widget.endsAt.difference(now);
    _remaining = diff.isNegative ? Duration.zero : diff;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _remaining.inHours.clamp(0, 99).toString().padLeft(2, '0');
    final minutes =
        _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _digitBox(hours),
        _colon(),
        _digitBox(minutes),
        _colon(),
        _digitBox(seconds),
      ],
    );
  }

  Widget _digitBox(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.creamBadgeBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value,
        style: AppTypography.countdownTimer.copyWith(
          color: AppColors.textCharcoal,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _colon() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 3),
      child: Text(
        ':',
        style: TextStyle(
          color: AppColors.creamBadgeBg,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// Subtle warm-parchment atmospheric snowflake backdrop (respects seasonal toggle).
class RetroAmbientSnowflakes extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const RetroAmbientSnowflakes({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return Stack(
      children: [
        const Positioned(
          top: -8,
          right: 72,
          child: IgnorePointer(
            child: Icon(
              Icons.ac_unit_rounded,
              size: 46,
              color: Color(0x1684664C),
            ),
          ),
        ),
        const Positioned(
          top: 26,
          left: 140,
          child: IgnorePointer(
            child: Icon(
              Icons.ac_unit_rounded,
              size: 26,
              color: Color(0x1284664C),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
