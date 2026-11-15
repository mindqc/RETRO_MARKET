import 'category_model.dart';
import 'brand_model.dart';

/// Aggregated Taxonomy containing categories and brands (M-DS-01)
class TaxonomyModel {
  final List<CategoryModel> categories;
  final List<BrandModel> brands;

  const TaxonomyModel({
    this.categories = const [],
    this.brands = const [],
  });

  factory TaxonomyModel.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'];
    final List<CategoryModel> parsedCategories = [];
    if (rawCategories is List) {
      for (final item in rawCategories) {
        if (item is Map) {
          parsedCategories.add(
            CategoryModel.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final rawBrands = json['brands'];
    final List<BrandModel> parsedBrands = [];
    if (rawBrands is List) {
      for (final item in rawBrands) {
        if (item is Map) {
          parsedBrands.add(BrandModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return TaxonomyModel(
      categories: parsedCategories,
      brands: parsedBrands,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': categories.map((c) => c.toJson()).toList(),
      'brands': brands.map((b) => b.toJson()).toList(),
    };
  }
}
