import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';

/// ServerCountdownTimer displays a live tick-down timer synchronized with auction or order expiration
/// Features Anti-Sniping warning alert styling when <= 120 seconds remain (BR-AU-04).
/// Uses tabular numerals to eliminate visual jitter during tick transitions.
class ServerCountdownTimer extends StatefulWidget {
  final DateTime endsAt;
  final VoidCallback? onExpired;
  final int extendedCount;
  final bool isCompact;
  final DateTime Function()? customClock;

  const ServerCountdownTimer({
    super.key,
    required this.endsAt,
    this.onExpired,
    this.extendedCount = 0,
    this.isCompact = false,
    this.customClock,
  });

  @override
  State<ServerCountdownTimer> createState() => _ServerCountdownTimerState();
}

class _ServerCountdownTimerState extends State<ServerCountdownTimer> {
  Timer? _timer;
  late Duration _remaining;
  bool _hasExpiredTriggered = false;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant ServerCountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endsAt != widget.endsAt) {
      _updateRemaining();
    }
  }

  void _updateRemaining() {
    final now = widget.customClock != null ? widget.customClock!() : DateTime.now();
    final difference = widget.endsAt.difference(now);
    _remaining = difference.isNegative ? Duration.zero : difference;
    if (_remaining == Duration.zero && !_hasExpiredTriggered) {
      _hasExpiredTriggered = true;
      widget.onExpired?.call();
    }
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _updateRemaining();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEndingSoon = _remaining.inSeconds > 0 && _remaining.inSeconds <= 120;
    final isExpired = _remaining == Duration.zero;

    final timerColor = isExpired
        ? AppColors.textMuted
        : (isEndingSoon ? AppColors.christmasBerryRed : AppColors.primaryTerracotta);

    final backgroundColor = isEndingSoon
        ? const Color(0xFFFDE8E8)
        : (isExpired ? const Color(0xFFF0EAE1) : AppColors.surfaceWarm);

    final formattedText = _formatDuration(_remaining);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isCompact ? 6 : 10,
        vertical: widget.isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
        border: Border.all(
          color: isEndingSoon ? const Color(0xFFF8B4B4) : AppColors.borderWarm,
          width: isEndingSoon ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEndingSoon ? Icons.timer_outlined : Icons.schedule_outlined,
            size: widget.isCompact ? 12 : 15,
            color: timerColor,
          ),
          const SizedBox(width: 4),
          Text(
            formattedText,
            style: AppTypography.countdownTimer.copyWith(
              color: timerColor,
              fontSize: widget.isCompact ? 11 : 13,
              fontWeight: isEndingSoon ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
          if (widget.extendedCount > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.accentVintageGold,
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              ),
              child: Text(
                '+${widget.extendedCount}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return '00:00:00';

    final days = duration.inDays;
    final hours = duration.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (days > 0) {
      return '${days}d $hours:$minutes:$seconds';
    }
    return '$hours:$minutes:$seconds';
  }
}
