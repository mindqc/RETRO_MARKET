import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/base_view_model.dart';
import '../models/dispute_evidence_model.dart';
import '../models/dispute_model.dart';
import '../repositories/order_fulfillment_repository.dart';

/// ViewModel managing Dispute Case creation, 2-way evidence submission, and case details (DEC-03 / BR-DP-02 / M-DP-01..03).
class DisputeViewModel extends BaseViewModel<DisputeModel> {
  final OrderFulfillmentRepository repository;

  bool isSubmitting = false;
  String? submitErrorMessage;

  DisputeViewModel({required this.repository});

  /// Loads full details of a specific dispute case
  Future<void> loadDisputeDetail(int disputeId) async {
    await runCatching(
      () => repository.fetchDisputeDetail(disputeId),
      emptyMessage: 'Không tìm thấy hồ sơ khiếu nại.',
    );
  }

  /// Opens a new dispute against an order (DEC-03 / BR-DP-02 / M-DP-01)
  Future<DisputeModel?> openDispute({
    required int orderId,
    required String reasonCategory,
    required String description,
    List<String> attachmentUrls = const [],
  }) async {
    final trimmedDesc = description.trim();
    if (trimmedDesc.length < 10) {
      submitErrorMessage = 'Vui lòng mô tả chi tiết lý do khiếu nại (tối thiểu 10 ký tự).';
      notifyListeners();
      return null;
    }

    if (attachmentUrls.length > 5) {
      submitErrorMessage = 'Chỉ được đính kèm tối đa 5 hình ảnh hoặc video bằng chứng (BR-DP-02).';
      notifyListeners();
      return null;
    }

    isSubmitting = true;
    submitErrorMessage = null;
    notifyListeners();

    try {
      final dispute = await repository.openDispute(
        orderId,
        reasonCategory: reasonCategory,
        description: trimmedDesc,
        attachmentUrls: attachmentUrls,
      );
      isSubmitting = false;
      setSuccess(dispute);
      return dispute;
    } catch (e) {
      isSubmitting = false;
      submitErrorMessage = 'Không thể mở khiếu nại: $e';
      notifyListeners();
      return null;
    }
  }

  /// Submits additional evidence or counter-statement to active dispute (M-DP-03)
  Future<DisputeEvidenceModel?> submitEvidence({
    required int disputeId,
    required String messageNote,
    String? evidenceType,
    List<String> attachmentUrls = const [],
  }) async {
    final trimmedNote = messageNote.trim();
    if (trimmedNote.isEmpty) {
      submitErrorMessage = 'Vui lòng nhập nội dung giải trình hoặc ghi chú bằng chứng.';
      notifyListeners();
      return null;
    }

    isSubmitting = true;
    submitErrorMessage = null;
    notifyListeners();

    try {
      final evidence = await repository.submitDisputeEvidence(
        disputeId,
        messageNote: trimmedNote,
        evidenceType: evidenceType,
        attachmentUrls: attachmentUrls,
      );

      // Refresh dispute detail
      await loadDisputeDetail(disputeId);

      isSubmitting = false;
      notifyListeners();
      return evidence;
    } catch (e) {
      isSubmitting = false;
      submitErrorMessage = 'Không thể gửi bằng chứng: $e';
      notifyListeners();
      return null;
    }
  }
}

/// Riverpod provider for DisputeViewModel
final disputeViewModelProvider = ChangeNotifierProvider.autoDispose<DisputeViewModel>((ref) {
  final repo = ref.watch(orderFulfillmentRepositoryProvider);
  return DisputeViewModel(repository: repo);
});
