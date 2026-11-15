/// Payload for submitting violation report and blocking conversation (M-CM-03)
class ViolationReportPayload {
  final String targetType; // 'CONVERSATION', 'USER', 'PRODUCT'
  final int targetId;
  final String reasonCategory; // 'SCAM', 'COUNTERFEIT', 'ABUSIVE_LANGUAGE', 'SPAM'
  final String description;
  final bool blockConversation;

  const ViolationReportPayload({
    required this.targetType,
    required this.targetId,
    required this.reasonCategory,
    required this.description,
    this.blockConversation = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'target_type': targetType,
      'target_id': targetId,
      'reason_category': reasonCategory,
      'description': description,
      'block_conversation': blockConversation,
    };
  }
}
