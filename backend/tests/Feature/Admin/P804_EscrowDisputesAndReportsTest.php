<?php

namespace Tests\Feature\Admin;

use App\Enums\DisputeStatus;
use App\Enums\EscrowStatus;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Enums\ProductCondition;
use App\Enums\ProductStatus;
use App\Enums\UserRole;
use App\Models\AuditLog;
use App\Models\Category;
use App\Models\Dispute;
use App\Models\DisputeEvidence;
use App\Models\EscrowTransaction;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\Product;
use App\Models\Report;
use App\Models\SellerProfile;
use App\Models\User;
use App\Models\WalletTransaction;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use LogicException;
use Tests\TestCase;

class P804_EscrowDisputesAndReportsTest extends TestCase
{
    use DatabaseTransactions;

    protected User $admin;
    protected User $moderator;
    protected User $support;
    protected User $buyer;
    protected User $seller;

    protected function setUp(): void
    {
        parent::setUp();
        $this->admin = User::where('email', 'admin@izithrift.local')->firstOrFail();
        $this->moderator = User::where('email', 'moderator@izithrift.local')->firstOrFail();
        $this->support = User::where('email', 'support@izithrift.local')->firstOrFail();

        $this->seller = User::whereHas('sellerProfile')->where('role', UserRole::REGISTERED_USER)->firstOrFail();
        $this->buyer = User::where('role', UserRole::REGISTERED_USER)->where('id', '!=', $this->seller->id)->firstOrFail();
    }

    /**
     * Helper to create an order with an active dispute.
     */
    protected function createOrderWithDispute(array $orderOverrides = [], array $disputeOverrides = []): array
    {
        $category = Category::whereNotNull('parent_id')->first() ?? Category::firstOrFail();

        $product = Product::create([
            'product_code' => 'PRD-DISP-' . uniqid(),
            'seller_id' => $this->seller->id,
            'category_id' => $category->id,
            'title' => 'Vintage Retro Jacket ' . uniqid(),
            'slug' => 'vintage-retro-jacket-' . uniqid(),
            'description' => 'Fine wool retro jacket',
            'condition' => ProductCondition::GOOD,
            'defect_info' => 'Vết sờn nhẹ ở gấu áo.',
            'listing_type' => 'FIXED_PRICE',
            'price' => 200000.00,
            'total_quantity' => 1,
            'available_quantity' => 0,
            'status' => ProductStatus::SOLD,
        ]);

        $order = Order::create(array_merge([
            'order_code' => 'ORD-DSP-' . uniqid(),
            'buyer_id' => $this->buyer->id,
            'seller_id' => $this->seller->id,
            'order_source' => 'FIXED_PRICE',
            'item_subtotal' => 200000.00,
            'shipping_fee' => 0.00,
            'protection_fee_rate_applied' => 0.0600,
            'protection_fixed_fee_applied' => 7000.00,
            'buyer_protection_fee' => 19000.00,
            'total_amount' => 219000.00,
            'seller_net_amount' => 200000.00,
            'shipping_address_snapshot' => ['recipient_name' => 'Linh', 'phone' => '0901234567'],
            'order_status' => OrderStatus::DELIVERED,
            'payment_status' => PaymentStatus::PAID,
            'escrow_status' => EscrowStatus::HELD,
            'dispute_status' => DisputeStatus::OPEN,
            'payment_expires_at' => now()->addMinutes(30),
            'paid_at' => now()->subDay(),
            'delivered_at' => now()->subHours(6),
            'escrow_frozen_at' => now()->subHours(2),
        ], $orderOverrides));

        OrderItem::create([
            'order_id' => $order->id,
            'product_id' => $product->id,
            'product_code_snapshot' => $product->product_code,
            'product_title_snapshot' => $product->title,
            'condition_snapshot' => ProductCondition::GOOD->value,
            'defect_info_snapshot' => 'Vết sờn nhẹ.',
            'primary_image_snapshot' => 'https://example.com/jacket.jpg',
            'unit_price_snapshot' => 200000.00,
            'quantity' => 1,
            'line_total' => 200000.00,
        ]);

        Payment::create([
            'payment_reference' => 'REF-DSP-' . uniqid(),
            'order_id' => $order->id,
            'payer_id' => $this->buyer->id,
            'amount' => 219000.00,
            'qr_payload' => 'vietqr://mock-qr-payload-test',
            'status' => PaymentStatus::PAID,
            'expires_at' => now()->addMinutes(30),
            'paid_at' => now()->subDay(),
        ]);

        // Adjust seller escrow held balance
        $sellerProfile = $this->seller->sellerProfile;
        if ($sellerProfile) {
            $sellerProfile->increment('escrow_held_balance', 200000.00);
        }

        $dispute = Dispute::create(array_merge([
            'dispute_code' => 'DSP-' . date('Y') . '-' . strtoupper(uniqid()),
            'order_id' => $order->id,
            'buyer_id' => $this->buyer->id,
            'seller_id' => $this->seller->id,
            'opened_at_order_status' => 'DELIVERED',
            'reason_category' => 'ITEM_NOT_AS_DESCRIBED',
            'buyer_description' => 'Sản phẩm có vết rách lớn ở lưng áo không giống mô tả.',
            'status' => DisputeStatus::OPEN,
        ], $disputeOverrides));

        DisputeEvidence::create([
            'dispute_id' => $dispute->id,
            'uploader_id' => $this->buyer->id,
            'uploader_role' => 'BUYER',
            'evidence_type' => 'BUYER_PROOF',
            'file_url' => 'https://example.com/evidence1.jpg',
            'message_note' => 'Ảnh chụp chi tiết vết rách khi mở kiện hàng.',
        ]);

        return [$order, $dispute, $product];
    }

    /**
     * AC-P804-01: Admin can view Escrow Explorer and verify Zero Ledger Drift (Screen A-ES-01).
     */
    public function test_admin_can_view_escrow_explorer_and_verify_zero_ledger_drift(): void
    {
        $response = $this->actingAs($this->admin)->get('/admin/escrow');

        $response->assertStatus(200);
        $response->assertSee('Sổ cái Ký quỹ (Escrow)');
        $response->assertSee('ZERO LEDGER DRIFT');
        $response->assertSee('Escrow Transactions');
        $response->assertSee('Wallet Transactions');
    }

    /**
     * AC-P804-01: Moderator and Support are forbidden from Escrow Explorer (admin.can:escrow.view).
     */
    public function test_moderator_and_support_are_forbidden_from_escrow_explorer(): void
    {
        $modResponse = $this->actingAs($this->moderator)->get('/admin/escrow');
        $modResponse->assertStatus(403);

        $suppResponse = $this->actingAs($this->support)->get('/admin/escrow');
        $suppResponse->assertStatus(403);
    }

    /**
     * AC-P804-02: Support and Admin can view Disputes Queue (Screen A-DP-01); Moderator is denied.
     */
    public function test_support_and_admin_can_view_disputes_queue_and_moderator_is_denied(): void
    {
        $adminRes = $this->actingAs($this->admin)->get('/admin/disputes');
        $adminRes->assertStatus(200);
        $adminRes->assertSee('Hàng đợi Quản lý Khiếu nại');

        $suppRes = $this->actingAs($this->support)->get('/admin/disputes');
        $suppRes->assertStatus(200);
        $suppRes->assertSee('Hàng đợi Quản lý Khiếu nại');

        $modRes = $this->actingAs($this->moderator)->get('/admin/disputes');
        $modRes->assertStatus(403);
    }

    /**
     * AC-P804-03: Support and Admin can view Dispute Case Room (Screen A-DP-02); Moderator is denied.
     */
    public function test_support_and_admin_can_view_dispute_case_room_and_moderator_is_denied(): void
    {
        [$order, $dispute] = $this->createOrderWithDispute();

        $adminRes = $this->actingAs($this->admin)->get("/admin/disputes/{$dispute->id}");
        $adminRes->assertStatus(200);
        $adminRes->assertSee($dispute->dispute_code);
        $adminRes->assertSee('Hồ sơ Xử lý Khiếu nại');
        $adminRes->assertSee('FROZEN ESCROW FUNDS');

        $suppRes = $this->actingAs($this->support)->get("/admin/disputes/{$dispute->id}");
        $suppRes->assertStatus(200);
        $suppRes->assertSee($dispute->dispute_code);

        $modRes = $this->actingAs($this->moderator)->get("/admin/disputes/{$dispute->id}");
        $modRes->assertStatus(403);
    }

    /**
     * AC-P804-03: Support and Admin can request additional evidence transitioning dispute to NEED_MORE_INFO.
     */
    public function test_support_and_admin_can_request_additional_evidence_transitioning_to_need_more_info(): void
    {
        [$order, $dispute] = $this->createOrderWithDispute();

        $response = $this->actingAs($this->support)->post("/admin/disputes/{$dispute->id}/request-info", [
            'message_note' => 'Vui lòng cung cấp thêm video quá trình mở kiện hàng để đối chứng.',
        ]);

        $response->assertRedirect("/admin/disputes/{$dispute->id}");
        $response->assertSessionHas('success');

        $freshDispute = $dispute->fresh();
        $this->assertEquals(DisputeStatus::NEED_MORE_INFO, $freshDispute->status);

        $this->assertDatabaseHas('dispute_evidences', [
            'dispute_id' => $dispute->id,
            'uploader_id' => $this->support->id,
            'uploader_role' => 'SUPPORT',
            'evidence_type' => 'STAFF_REQUEST_NOTE',
            'message_note' => 'Vui lòng cung cấp thêm video quá trình mở kiện hàng để đối chứng.',
        ]);
    }

    /**
     * AC-P804-04: Separation of Duties (DEC-08-03 / P6-02) - Support and Moderator are FORBIDDEN from financial verdicts.
     */
    public function test_separation_of_duties_support_and_moderator_are_forbidden_from_financial_verdict(): void
    {
        [$order, $dispute] = $this->createOrderWithDispute();

        // Support role attempting verdict -> 403 Forbidden
        $suppRes = $this->actingAs($this->support)->post("/admin/disputes/{$dispute->id}/verdict", [
            'verdict' => 'APPROVE_BUYER_REFUND',
            'resolution_note' => 'Support cố gắng ra phán quyết trái thẩm quyền.',
        ]);
        $suppRes->assertStatus(403);

        // Moderator role attempting verdict -> 403 Forbidden
        $modRes = $this->actingAs($this->moderator)->post("/admin/disputes/{$dispute->id}/verdict", [
            'verdict' => 'APPROVE_BUYER_REFUND',
            'resolution_note' => 'Moderator cố gắng ra phán quyết trái thẩm quyền.',
        ]);
        $modRes->assertStatus(403);

        // Verify dispute remains OPEN
        $this->assertEquals(DisputeStatus::OPEN, $dispute->fresh()->status);
    }

    /**
     * AC-P804-04: Supreme Admin executes Buyer Refund verdict (DEC-07 / BR-FN-06).
     */
    public function test_admin_can_execute_buyer_refund_verdict_dec07(): void
    {
        [$order, $dispute] = $this->createOrderWithDispute();

        $sellerProfileBefore = $this->seller->sellerProfile->fresh();
        $heldBefore = (float) $sellerProfileBefore->escrow_held_balance;

        $response = $this->actingAs($this->admin)->post("/admin/disputes/{$dispute->id}/verdict", [
            'verdict' => 'APPROVE_BUYER_REFUND',
            'resolution_note' => 'Bằng chứng rách lưng áo rõ ràng. Chấp thuận hoàn tiền 100% cho người mua (DEC-07).',
        ]);

        $response->assertRedirect("/admin/disputes/{$dispute->id}");
        $response->assertSessionHas('success');

        // Verify dispute is RESOLVED
        $freshDispute = $dispute->fresh();
        $this->assertEquals(DisputeStatus::RESOLVED, $freshDispute->status);
        $this->assertEquals('APPROVE_BUYER_REFUND', $freshDispute->admin_verdict);
        $this->assertEquals($this->admin->id, $freshDispute->resolved_by_admin_id);
        $this->assertNotNull($freshDispute->resolved_at);

        // Verify Order is CANCELLED and Escrow REFUNDED
        $freshOrder = $order->fresh();
        $this->assertEquals(OrderStatus::CANCELLED, $freshOrder->order_status);
        $this->assertEquals(EscrowStatus::REFUNDED, $freshOrder->escrow_status);
        $this->assertEquals(PaymentStatus::REFUNDED, $freshOrder->payment_status);

        // Verify EscrowTransaction FULL_REFUND is recorded
        $this->assertDatabaseHas('escrow_transactions', [
            'order_id' => $order->id,
            'transaction_type' => 'FULL_REFUND',
            'buyer_refunded_amount' => '219000.00',
            'seller_released_amount' => '0.00',
            'triggered_by_user_id' => $this->admin->id,
        ]);

        // Verify Seller held balance decreased
        $sellerProfileAfter = $this->seller->sellerProfile->fresh();
        $this->assertEquals(round($heldBefore - 200000.00, 2), (float) $sellerProfileAfter->escrow_held_balance);
        $this->assertEquals(1, (int) $sellerProfileAfter->dispute_lost_count);

        // Verify Audit Log is recorded
        $this->assertDatabaseHas('audit_logs', [
            'actor_id' => $this->admin->id,
            'action' => 'DISPUTE_RESOLVED',
            'target_type' => 'disputes',
            'target_id' => $dispute->id,
        ]);
    }

    /**
     * AC-P804-04: Supreme Admin executes Release to Seller verdict (DEC-04 / BR-FN-07).
     */
    public function test_admin_can_execute_release_to_seller_verdict_dec04(): void
    {
        [$order, $dispute] = $this->createOrderWithDispute();

        $sellerProfileBefore = $this->seller->sellerProfile->fresh();
        $walletBefore = (float) $sellerProfileBefore->wallet_balance;

        $response = $this->actingAs($this->admin)->post("/admin/disputes/{$dispute->id}/verdict", [
            'verdict' => 'RELEASE_TO_SELLER',
            'resolution_note' => 'Người mua không xuất trình được bằng chứng lỗi sản phẩm. Bác bỏ khiếu nại, giải ngân người bán.',
        ]);

        $response->assertRedirect("/admin/disputes/{$dispute->id}");
        $response->assertSessionHas('success');

        // Verify dispute is RESOLVED
        $freshDispute = $dispute->fresh();
        $this->assertEquals(DisputeStatus::RESOLVED, $freshDispute->status);
        $this->assertEquals('RELEASE_TO_SELLER', $freshDispute->admin_verdict);

        // Verify Order is COMPLETED and Escrow RELEASED
        $freshOrder = $order->fresh();
        $this->assertEquals(OrderStatus::COMPLETED, $freshOrder->order_status);
        $this->assertEquals(EscrowStatus::RELEASED, $freshOrder->escrow_status);

        // Verify EscrowTransaction RELEASE is recorded
        $this->assertDatabaseHas('escrow_transactions', [
            'order_id' => $order->id,
            'transaction_type' => 'RELEASE',
            'seller_released_amount' => '200000.00',
            'buyer_refunded_amount' => '0.00',
            'platform_fee_retained' => '19000.00',
        ]);

        // Verify WalletTransaction CREDIT is recorded
        $this->assertDatabaseHas('wallet_transactions', [
            'seller_id' => $this->seller->id,
            'order_id' => $order->id,
            'entry_type' => 'CREDIT',
            'amount' => '200000.00',
        ]);

        // Verify Seller wallet balance increased
        $sellerProfileAfter = $this->seller->sellerProfile->fresh();
        $this->assertEquals(round($walletBefore + 200000.00, 2), (float) $sellerProfileAfter->wallet_balance);
    }

    /**
     * AC-P804-05: Staff can view and filter Violation Reports (Screen A-CM-01).
     */
    public function test_staff_can_view_and_filter_violation_reports(): void
    {
        // Create sample reports
        Report::create([
            'reporter_id' => $this->buyer->id,
            'target_type' => 'PRODUCT',
            'target_id' => 1,
            'reason_category' => 'COUNTERFEIT',
            'description' => 'Sản phẩm có dấu hiệu làm giả thương hiệu nổi tiếng.',
            'status' => 'PENDING',
        ]);

        Report::create([
            'reporter_id' => $this->seller->id,
            'target_type' => 'USER',
            'target_id' => $this->buyer->id,
            'reason_category' => 'HARASSMENT',
            'description' => 'Người mua nhắn tin đe dọa tục tĩu.',
            'status' => 'RESOLVED_ACTION_TAKEN',
            'resolution_note' => 'Đã gửi cảnh cáo chính thức.',
            'handled_by' => $this->moderator->id,
            'handled_at' => now(),
        ]);

        $adminRes = $this->actingAs($this->admin)->get('/admin/moderation/reports');
        $adminRes->assertStatus(200);
        $adminRes->assertSee('Quản lý Báo cáo Vi phạm');

        $modRes = $this->actingAs($this->moderator)->get('/admin/moderation/reports?status=PENDING');
        $modRes->assertStatus(200);
        $modRes->assertSee('COUNTERFEIT');

        $suppRes = $this->actingAs($this->support)->get('/admin/moderation/reports?status=RESOLVED_ACTION_TAKEN');
        $suppRes->assertStatus(200);
        $suppRes->assertSee('HARASSMENT');

        // Unauthenticated or regular user is blocked
        $userRes = $this->actingAs($this->buyer)->get('/admin/moderation/reports');
        $userRes->assertStatus(403);
    }

    /**
     * AC-P804-05: Moderator can resolve Violation Report with mandatory note.
     */
    public function test_moderator_can_resolve_violation_report_with_mandatory_note(): void
    {
        $report = Report::create([
            'reporter_id' => $this->buyer->id,
            'target_type' => 'PRODUCT',
            'target_id' => 999,
            'reason_category' => 'PROHIBITED_ITEM',
            'description' => 'Sản phẩm thuộc danh mục cấm giao dịch.',
            'status' => 'PENDING',
        ]);

        $response = $this->actingAs($this->moderator)->post("/admin/moderation/reports/{$report->id}/resolve", [
            'status' => 'RESOLVED_ACTION_TAKEN',
            'resolution_note' => 'Xác nhận sản phẩm vi phạm danh mục cấm, đã ẩn sản phẩm khỏi sàn.',
        ]);

        $response->assertRedirect('/admin/moderation/reports');
        $response->assertSessionHas('success');

        $freshReport = $report->fresh();
        $this->assertEquals('RESOLVED_ACTION_TAKEN', $freshReport->status);
        $this->assertEquals($this->moderator->id, $freshReport->handled_by);
        $this->assertNotNull($freshReport->handled_at);
        $this->assertEquals('Xác nhận sản phẩm vi phạm danh mục cấm, đã ẩn sản phẩm khỏi sàn.', $freshReport->resolution_note);

        // Verify immutable AuditLog
        $this->assertDatabaseHas('audit_logs', [
            'actor_id' => $this->moderator->id,
            'action' => 'REPORT_RESOLVED',
            'target_type' => 'REPORT',
            'target_id' => $report->id,
        ]);
    }

    /**
     * AC-P804-05: Support can dismiss Violation Report with mandatory note.
     */
    public function test_support_can_dismiss_violation_report_with_mandatory_note(): void
    {
        $report = Report::create([
            'reporter_id' => $this->buyer->id,
            'target_type' => 'USER',
            'target_id' => $this->seller->id,
            'reason_category' => 'OTHER',
            'description' => 'Không hài lòng với thái độ phục vụ.',
            'status' => 'PENDING',
        ]);

        $response = $this->actingAs($this->support)->post("/admin/moderation/reports/{$report->id}/resolve", [
            'status' => 'DISMISSED',
            'resolution_note' => 'Không đủ căn cứ vi phạm quy chế sàn, bác bỏ báo cáo.',
        ]);

        $response->assertRedirect('/admin/moderation/reports');
        $response->assertSessionHas('success');

        $freshReport = $report->fresh();
        $this->assertEquals('DISMISSED', $freshReport->status);
        $this->assertEquals($this->support->id, $freshReport->handled_by);
    }

    /**
     * AC-P804-05: Validation rejects empty note or re-resolving an already handled report.
     */
    public function test_cannot_resolve_report_without_valid_note_or_if_already_handled(): void
    {
        $report = Report::create([
            'reporter_id' => $this->buyer->id,
            'target_type' => 'PRODUCT',
            'target_id' => 1,
            'reason_category' => 'COUNTERFEIT',
            'description' => 'Mô tả ngắn.',
            'status' => 'PENDING',
        ]);

        // Note too short (< 5 chars) -> validation failure
        $shortNoteRes = $this->actingAs($this->moderator)->post("/admin/moderation/reports/{$report->id}/resolve", [
            'status' => 'RESOLVED_ACTION_TAKEN',
            'resolution_note' => 'abc',
        ]);
        $shortNoteRes->assertSessionHasErrors(['resolution_note']);

        // Mark report as resolved
        $report->update([
            'status' => 'RESOLVED_ACTION_TAKEN',
            'handled_by' => $this->moderator->id,
            'handled_at' => now(),
            'resolution_note' => 'Đã xử lý xong trước đó.',
        ]);

        // Attempting to resolve an already resolved report -> error redirect
        $reResolveRes = $this->actingAs($this->moderator)->post("/admin/moderation/reports/{$report->id}/resolve", [
            'status' => 'DISMISSED',
            'resolution_note' => 'Cố gắng sửa quyết định.',
        ]);
        $reResolveRes->assertSessionHas('error');
    }

    /**
     * AC-P804-06: Immutable Append-Only Ledger Integrity (EscrowTransaction, WalletTransaction, AuditLog).
     */
    public function test_immutable_ledger_protection_on_escrow_wallet_and_audit_logs(): void
    {
        [$order] = $this->createOrderWithDispute();

        // 1. EscrowTransaction immutable protection
        $escrowTx = EscrowTransaction::create([
            'transaction_code' => 'ESC-TEST-' . uniqid(),
            'order_id' => $order->id,
            'buyer_id' => $this->buyer->id,
            'seller_id' => $this->seller->id,
            'transaction_type' => 'HOLD',
            'gross_amount' => 219000.00,
            'item_subtotal_amount' => 200000.00,
            'buyer_protection_fee_amount' => 19000.00,
            'seller_released_amount' => 0.00,
            'buyer_refunded_amount' => 0.00,
            'platform_fee_retained' => 0.00,
            'note' => 'Test escrow transaction',
        ]);

        $this->expectException(LogicException::class);
        $escrowTx->update(['note' => 'Illegal edit attempt']);
    }

    /**
     * AC-P804-06: WalletTransaction immutable protection against deletion.
     */
    public function test_wallet_transaction_cannot_be_deleted(): void
    {
        [$order] = $this->createOrderWithDispute();

        $escrowTx = EscrowTransaction::create([
            'transaction_code' => 'ESC-WTX-' . uniqid(),
            'order_id' => $order->id,
            'buyer_id' => $this->buyer->id,
            'seller_id' => $this->seller->id,
            'transaction_type' => 'HOLD',
            'gross_amount' => 219000.00,
            'item_subtotal_amount' => 200000.00,
            'buyer_protection_fee_amount' => 19000.00,
            'seller_released_amount' => 0.00,
            'buyer_refunded_amount' => 0.00,
            'platform_fee_retained' => 0.00,
            'note' => 'Test escrow transaction for wallet',
        ]);

        $walletTx = WalletTransaction::create([
            'wallet_tx_code' => 'WTX-TEST-' . uniqid(),
            'seller_id' => $this->seller->id,
            'order_id' => $order->id,
            'escrow_transaction_id' => $escrowTx->id,
            'entry_type' => 'CREDIT',
            'amount' => 200000.00,
            'balance_before' => 0.00,
            'balance_after' => 200000.00,
            'description' => 'Test wallet transaction',
        ]);

        $this->expectException(LogicException::class);
        $walletTx->delete();
    }

    /**
     * AC-P804-06: AuditLog immutable protection against update.
     */
    public function test_audit_log_cannot_be_updated(): void
    {
        $auditLog = AuditLog::create([
            'actor_id' => $this->admin->id,
            'actor_role' => 'ADMIN',
            'action' => 'TEST_ACTION',
            'target_type' => 'SYSTEM',
            'target_id' => 1,
            'reason' => 'Audit record test',
        ]);

        $this->expectException(LogicException::class);
        $auditLog->update(['reason' => 'Tampered audit record']);
    }
}
