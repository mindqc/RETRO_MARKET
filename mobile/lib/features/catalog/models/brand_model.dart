import '../../../core/utils/safe_json_parser.dart';

/// Brand model for vintage & retro brands directory (M-DS-01)
class BrandModel {
  final int id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String? originCountry;
  final String? description;
  final int approvedProductsCount;

  const BrandModel({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.originCountry,
    this.description,
    this.approvedProductsCount = 0,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: SafeJsonParser.toInt(json['id']),
      name: SafeJsonParser.toStringValue(json['name']),
      slug: SafeJsonParser.toStringValue(json['slug']),
      logoUrl: SafeJsonParser.toNullableString(json['logo_url']),
      originCountry: SafeJsonParser.toNullableString(json['origin_country']),
      description: SafeJsonParser.toNullableString(json['description']),
      approvedProductsCount: SafeJsonParser.toInt(
        json['approved_products_count'],
        defaultValue: 0,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'logo_url': logoUrl,
      'origin_country': originCountry,
      'description': description,
      'approved_products_count': approvedProductsCount,
    };
  }
}
