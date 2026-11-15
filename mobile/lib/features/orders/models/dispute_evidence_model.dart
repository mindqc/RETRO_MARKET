import '../../../core/utils/safe_json_parser.dart';

/// Represents a single piece of evidence or counter-statement uploaded during dispute resolution (M-DP-02..03).
class DisputeEvidenceModel {
  final int id;
  final int disputeId;
  final int uploaderId;
  final String uploaderRole; // BUYER, SELLER, STAFF, ADMIN
  final String uploaderName;
  final String evidenceType; // BUYER_PROOF, SELLER_COUNTER_PROOF, STAFF_REQUEST_NOTE
  final String? fileUrl;
  final List<String> attachmentUrls;
  final String messageNote;
  final DateTime? createdAt;

  const DisputeEvidenceModel({
    required this.id,
    required this.disputeId,
    required this.uploaderId,
    required this.uploaderRole,
    required this.uploaderName,
    required this.evidenceType,
    this.fileUrl,
    this.attachmentUrls = const [],
    required this.messageNote,
    this.createdAt,
  });

  bool get isBuyerProof => evidenceType == 'BUYER_PROOF' || uploaderRole == 'BUYER';
  bool get isSellerCounterProof => evidenceType == 'SELLER_COUNTER_PROOF' || uploaderRole == 'SELLER';
  bool get isStaffNote => evidenceType == 'STAFF_REQUEST_NOTE' || uploaderRole == 'STAFF' || uploaderRole == 'ADMIN';

  factory DisputeEvidenceModel.fromJson(Map<String, dynamic> json) {
    String uName = 'Người dùng';
    String uRole = SafeJsonParser.toStringValue(json['uploader_role'], defaultValue: 'BUYER').toUpperCase();

    if (json['uploader'] is Map<String, dynamic>) {
      final u = json['uploader'] as Map<String, dynamic>;
      uName = SafeJsonParser.toStringValue(
        u['display_name'] ?? u['name'],
        defaultValue: 'Người dùng',
      );
      if (u['role'] != null) {
        uRole = SafeJsonParser.toStringValue(u['role']).toUpperCase();
      }
    }

    final rawAttachments = json['attachment_urls'] ?? json['attachments'];
    final List<String> urls = [];
    if (rawAttachments is List) {
      for (final a in rawAttachments) {
        if (a != null && a.toString().isNotEmpty) {
          urls.add(a.toString());
        }
      }
    }
    final singleFile = SafeJsonParser.toNullableString(json['file_url']);
    if (singleFile != null && !urls.contains(singleFile)) {
      urls.insert(0, singleFile);
    }

    return DisputeEvidenceModel(
      id: SafeJsonParser.toInt(json['id']),
      disputeId: SafeJsonParser.toInt(json['dispute_id']),
      uploaderId: SafeJsonParser.toInt(json['uploader_id'] ?? json['submitter_id']),
      uploaderRole: uRole,
      uploaderName: uName,
      evidenceType: SafeJsonParser.toStringValue(json['evidence_type'], defaultValue: 'BUYER_PROOF').toUpperCase(),
      fileUrl: singleFile,
      attachmentUrls: urls,
      messageNote: SafeJsonParser.toStringValue(
        json['message_note'] ?? json['note'] ?? json['message'],
        defaultValue: 'Không có ghi chú thêm.',
      ),
      createdAt: SafeJsonParser.toNullableDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dispute_id': disputeId,
      'uploader_id': uploaderId,
      'uploader_role': uploaderRole,
      'uploader_name': uploaderName,
      'evidence_type': evidenceType,
      'file_url': fileUrl,
      'attachment_urls': attachmentUrls,
      'message_note': messageNote,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
