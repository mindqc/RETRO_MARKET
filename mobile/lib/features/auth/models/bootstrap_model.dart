import '../../../core/utils/safe_json_parser.dart';
import 'user_model.dart';

/// Bootstrap configuration payload returned from GET /api/v1/bootstrap
class BootstrapModel {
  final DateTime? serverTime;
  final bool demoMode;
  final double protectionFeeRate;
  final double protectionFixedFee;
  final double shippingFeeDefault;
  final UserModel? currentUser;

  const BootstrapModel({
    this.serverTime,
    this.demoMode = true,
    this.protectionFeeRate = 0.06,
    this.protectionFixedFee = 7000.0,
    this.shippingFeeDefault = 0.0,
    this.currentUser,
  });

  factory BootstrapModel.fromJson(Map<String, dynamic> json) {
    UserModel? parsedUser;
    if (json['current_user'] is Map<String, dynamic>) {
      parsedUser = UserModel.fromJson(json['current_user'] as Map<String, dynamic>);
    } else if (json['current_user'] is Map) {
      parsedUser = UserModel.fromJson(Map<String, dynamic>.from(json['current_user'] as Map));
    }

    return BootstrapModel(
      serverTime: SafeJsonParser.toDateTime(json['server_time']),
      demoMode: SafeJsonParser.toBool(json['demo_mode'], defaultValue: true),
      protectionFeeRate: SafeJsonParser.toDouble(json['protection_fee_rate'], defaultValue: 0.06),
      protectionFixedFee: SafeJsonParser.toDouble(json['protection_fixed_fee'], defaultValue: 7000.0),
      shippingFeeDefault: SafeJsonParser.toDouble(json['shipping_fee_default'], defaultValue: 0.0),
      currentUser: parsedUser,
    );
  }
}
