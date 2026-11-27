import '../../../core/utils/safe_json_parser.dart';

/// Model representing a product photo, defect closeup, or authenticity proof.
class ProductImageModel {
  final int id;
  final String imageUrl;
  final String imageType;
  final bool isPrimary;
  final int sortOrder;
  final String? defectNote;
  final int fileSizeBytes;

  const ProductImageModel({
    required this.id,
    required this.imageUrl,
    this.imageType = 'GALLERY',
    this.isPrimary = false,
    this.sortOrder = 0,
    this.defectNote,
    this.fileSizeBytes = 0,
  });

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: SafeJsonParser.toInt(json['id']),
      imageUrl: SafeJsonParser.toStringValue(
        json['image_url'] ?? json['url'],
        defaultValue: '',
      ),
      imageType: SafeJsonParser.toStringValue(json['image_type'], defaultValue: 'GALLERY'),
      isPrimary: SafeJsonParser.toBool(json['is_primary']),
      sortOrder: SafeJsonParser.toInt(json['sort_order']),
      defectNote: SafeJsonParser.toNullableString(json['defect_note'] ?? json['description']),
      fileSizeBytes: SafeJsonParser.toInt(json['file_size_bytes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'image_type': imageType,
      'is_primary': isPrimary,
      'sort_order': sortOrder,
      'defect_note': defectNote,
      'file_size_bytes': fileSizeBytes,
    };
  }
}
