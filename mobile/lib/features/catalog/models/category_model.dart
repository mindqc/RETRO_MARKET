import '../../../core/utils/safe_json_parser.dart';

/// Category model representing hierarchical product categories (M-DS-01)
class CategoryModel {
  final int id;
  final int? parentId;
  final String name;
  final String slug;
  final String? iconName;
  final String? description;
  final int sortOrder;
  final int approvedProductsCount;
  final List<CategoryModel> children;

  const CategoryModel({
    required this.id,
    this.parentId,
    required this.name,
    required this.slug,
    this.iconName,
    this.description,
    this.sortOrder = 0,
    this.approvedProductsCount = 0,
    this.children = const [],
  });

  bool get isRoot => parentId == null;
  bool get hasChildren => children.isNotEmpty;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'];
    final List<CategoryModel> parsedChildren = [];
    if (rawChildren is List) {
      for (final item in rawChildren) {
        if (item is Map) {
          parsedChildren.add(
            CategoryModel.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return CategoryModel(
      id: SafeJsonParser.toInt(json['id']),
      parentId: SafeJsonParser.toNullableInt(json['parent_id']),
      name: SafeJsonParser.toStringValue(json['name']),
      slug: SafeJsonParser.toStringValue(json['slug']),
      iconName: SafeJsonParser.toNullableString(json['icon_name']),
      description: SafeJsonParser.toNullableString(json['description']),
      sortOrder: SafeJsonParser.toInt(json['sort_order'], defaultValue: 0),
      approvedProductsCount: SafeJsonParser.toInt(
        json['approved_products_count'],
        defaultValue: 0,
      ),
      children: parsedChildren,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'name': name,
      'slug': slug,
      'icon_name': iconName,
      'description': description,
      'sort_order': sortOrder,
      'approved_products_count': approvedProductsCount,
      'children': children.map((c) => c.toJson()).toList(),
    };
  }
}
