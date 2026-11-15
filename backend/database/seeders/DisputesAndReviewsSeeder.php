<?php

namespace Database\Seeders;

use App\Models\Dispute;
use App\Models\DisputeEvidence;
use App\Models\Order;
use App\Models\Product;
use App\Models\Report;
use App\Models\Review;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;

class DisputesAndReviewsSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $admin = User::where('email', 'admin@izithrift.local')->firstOrFail();
        $moderator = User::where('email', 'moderator@izithrift.local')->firstOrFail();
        $support = User::where('email', 'support@izithrift.local')->firstOrFail();
        $sellerA = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();
        $buyer1 = User::where('email', 'buyer.linh@izithrift.local')->firstOrFail();
        $buyer2 = User::where('email', 'buyer.kiet@izithrift.local')->firstOrFail();

        $ord6 = Order::where('order_code', 'ORD-2026-0006')->firstOrFail();
        $ord9 = Order::where('order_code', 'ORD-2026-0009')->firstOrFail();
        $ord10 = Order::where('order_code', 'ORD-2026-0010')->firstOrFail();

        $prd1 = Product::where('product_code', 'PRD-2026-0001')->firstOrFail();
        $prd14 = Product::where('product_code', 'PRD-2026-0014')->firstOrFail();

        $now = Carbon::now();

        // -------------------------------------------------------------------------
        // 1. DISPUTES (2 Scenarios: OPEN for Split-Pane review, RESOLVED with verdict)
        // -------------------------------------------------------------------------

        // DSP-2026-0001: OPEN (Order ORD-2026-0009)
        $dsp1 = Dispute::updateOrCreate(
            ['dispute_code' => 'DSP-2026-0001'],
            [
                'order_id' => $ord9->id,
                'buyer_id' => $buyer1->id,
                'seller_id' => $sellerA->id,
                'opened_at_order_status' => 'DELIVERED',
                'reason_category' => 'ITEM_NOT_AS_DESCRIBED',
                'buyer_description' => 'Áo có vết rách nhỏ ở đường may nách áo không hề được mô tả trong thông tin lỗi sản phẩm.',
                'seller_response' => 'Shop cam kết trước khi đóng gói áo còn nguyên vẹn, nghi vấn lỗi phát sinh do quá trình thử đồ của người mua.',
                'assigned_support_id' => $support->id,
                'status' => 'OPEN',
                'admin_verdict' => null,
                'partial_refund_to_buyer' => null,
                'resolution_note' => null,
                'resolved_by_admin_id' => null,
                'resolved_at' => null,
            ]
        );

        DisputeEvidence::firstOrCreate(
            [
                'dispute_id' => $dsp1->id,
                'uploader_id' => $buyer1->id,
                'evidence_type' => 'BUYER_PROOF',
            ],
            [
                'uploader_role' => 'BUYER',
                'file_url' => '/assets/disputes/dsp1_buyer_proof.jpg',
                'message_note' => 'Ảnh chụp cận cảnh vết sờn chỉ và rách nhỏ ở nách áo bên trái.',
                'created_at' => (clone $now)->subHours(12),
            ]
        );

        DisputeEvidence::firstOrCreate(
            [
                'dispute_id' => $dsp1->id,
                'uploader_id' => $sellerA->id,
                'evidence_type' => 'SELLER_COUNTER_PROOF',
            ],
            [
                'uploader_role' => 'SELLER',
                'file_url' => '/assets/disputes/dsp1_seller_proof.jpg',
                'message_note' => 'Hình ảnh sản phẩm trên móc treo trước khi bọc giấy nến gửi khách.',
                'created_at' => (clone $now)->subHours(10),
            ]
        );

        // DSP-2026-0002: RESOLVED (Order ORD-2026-0010)
        $dsp2 = Dispute::updateOrCreate(
            ['dispute_code' => 'DSP-2026-0002'],
            [
                'order_id' => $ord10->id,
                'buyer_id' => $buyer2->id,
                'seller_id' => $sellerA->id,
                'opened_at_order_status' => 'DELIVERED',
                'reason_category' => 'DEFECT_UNDISCLOSED',
                'buyer_description' => 'Khóa kéo kim loại túi xách bị kẹt rít khó mở, không trơn tru như hình ảnh.',
                'seller_response' => 'Đồng ý hỗ trợ người mua một phần chi phí tra dầu và bảo dưỡng lại khóa túi.',
                'assigned_support_id' => $support->id,
                'status' => 'RESOLVED',
                'admin_verdict' => 'PARTIAL_REFUND',
                'partial_refund_to_buyer' => 200000.00,
                'resolution_note' => 'Admin phê duyệt phương án Partial Refund: Hoàn trả 200.000đ cho Buyer, giải ngân 600.000đ cho Seller A.',
                'resolved_by_admin_id' => $admin->id,
                'resolved_at' => (clone $now)->subDays(1),
            ]
        );

        DisputeEvidence::firstOrCreate(
            [
                'dispute_id' => $dsp2->id,
                'uploader_id' => $buyer2->id,
                'evidence_type' => 'BUYER_PROOF',
            ],
            [
                'uploader_role' => 'BUYER',
                'file_url' => '/assets/disputes/dsp2_buyer_zipper.jpg',
                'message_note' => 'Video quay lại cảnh kéo khóa túi xách bị kẹt cứng ở đoạn giữa.',
                'created_at' => (clone $now)->subDays(2),
            ]
        );

        // -------------------------------------------------------------------------
        // 2. REVIEWS (Authentic Review for ORD-2026-0006)
        // -------------------------------------------------------------------------
        Review::updateOrCreate(
            ['order_id' => $ord6->id],
            [
                'product_id' => $prd1->id,
                'reviewer_id' => $buyer1->id,
                'seller_id' => $sellerA->id,
                'rating' => 5,
                'comment' => 'Sản phẩm áo măng tô dạ tweed rất đẹp, đúng form vintage thập niên 90s. Chủ tiệm gói hàng chu đáo, kèm thiệp cảm ơn dễ thương!',
                'status' => 'VISIBLE',
            ]
        );

        // Update seller rating stats
        $sellerA->sellerProfile()->update([
            'average_rating' => 5.00,
            'review_count' => 1,
        ]);

        // -------------------------------------------------------------------------
        // 3. REPORTS (Counterfeit Report handled by Moderator)
        // -------------------------------------------------------------------------
        Report::updateOrCreate(
            [
                'reporter_id' => $buyer2->id,
                'target_type' => 'PRODUCT',
                'target_id' => $prd14->id,
            ],
            [
                'reason_category' => 'SUSPECTED_COUNTERFEIT',
                'description' => 'Sản phẩm có dấu hiệu tem nhãn may lại, nghi vấn không phải hàng chính hãng Burberrys vintage.',
                'status' => 'RESOLVED_ACTION_TAKEN',
                'resolution_note' => 'Kiểm duyệt viên đã kiểm tra chi tiết tem nhãn và gắn trạng thái REJECTED cho sản phẩm.',
                'handled_by' => $moderator->id,
                'handled_at' => (clone $now)->subDays(2),
            ]
        );
    }
}
