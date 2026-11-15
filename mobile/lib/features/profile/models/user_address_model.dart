import '../../../core/utils/safe_json_parser.dart';

/// User Shipping Address model for address book and order checkout (M-PF-03, M-PF-04)
class UserAddressModel {
  final int id;
  final String recipientName;
  final String recipientPhone;
  final String provinceCity;
  final String districtWard;
  final String streetAddress;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserAddressModel({
    required this.id,
    required this.recipientName,
    required this.recipientPhone,
    required this.provinceCity,
    required this.districtWard,
    required this.streetAddress,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Formatted full delivery address
  String get fullAddress => '$streetAddress, $districtWard, $provinceCity';

  factory UserAddressModel.fromJson(Map<String, dynamic> json) {
    return UserAddressModel(
      id: SafeJsonParser.toInt(json['id']),
      recipientName: json['recipient_name']?.toString() ?? '',
      recipientPhone: json['recipient_phone']?.toString() ?? '',
      provinceCity: json['province_city']?.toString() ?? '',
      districtWard: json['district_ward']?.toString() ?? '',
      streetAddress: json['street_address']?.toString() ?? '',
      isDefault: SafeJsonParser.toBool(json['is_default'], defaultValue: false),
      createdAt: SafeJsonParser.toDateTime(json['created_at']),
      updatedAt: SafeJsonParser.toDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'province_city': provinceCity,
      'district_ward': districtWard,
      'street_address': streetAddress,
      'is_default': isDefault,
    };
  }

  UserAddressModel copyWith({
    int? id,
    String? recipientName,
    String? recipientPhone,
    String? provinceCity,
    String? districtWard,
    String? streetAddress,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserAddressModel(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      provinceCity: provinceCity ?? this.provinceCity,
      districtWard: districtWard ?? this.districtWard,
      streetAddress: streetAddress ?? this.streetAddress,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
