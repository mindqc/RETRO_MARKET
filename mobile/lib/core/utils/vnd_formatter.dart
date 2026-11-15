import 'package:intl/intl.dart';

/// Vietnamese Dong (VNĐ) Currency Formatter.
class VndFormatter {
  VndFormatter._();

  static final NumberFormat _currencyFormat = NumberFormat('#,##0', 'vi_VN');

  /// Formats amount into standard Vietnamese Dong: "400.000đ" or "1.067.000đ".
  static String format(num? amount) {
    if (amount == null) return '0đ';
    final formatted = _currencyFormat.format(amount.round()).replaceAll(',', '.');
    return '$formattedđ';
  }

  /// Compact format for cards and tags: "850k", "1,2tr", "45tr".
  static String formatCompact(num? amount) {
    if (amount == null) return '0đ';
    final value = amount.toDouble();
    if (value >= 1000000000) {
      final b = (value / 1000000000).toStringAsFixed(1).replaceAll('.', ',');
      return '${b.endsWith(',0') ? b.substring(0, b.length - 2) : b}tỷ';
    }
    if (value >= 1000000) {
      final m = (value / 1000000).toStringAsFixed(1).replaceAll('.', ',');
      return '${m.endsWith(',0') ? m.substring(0, m.length - 2) : m}tr';
    }
    if (value >= 1000) {
      final k = (value / 1000).toStringAsFixed(0);
      return '${k}k';
    }
    return format(amount);
  }
}
