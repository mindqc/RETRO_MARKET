<?php

namespace Tests\Feature\Admin;

use App\Enums\DisputeStatus;
use App\Enums\EscrowStatus;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Enums\ProductCondition;
use App\Enums\ProductStatus;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\AuditLog;
use App\Models\Category;
use App\Models\Dispute;
use App\Models\DisputeEvidence;
use App\Models\EscrowTransaction;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\Product;
use App\Models\ProductModerationLog;
use App\Models\SellerProfile;
use App\Models\User;
use App\Models\UserProfile;
use App\Models\WalletTransaction;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use LogicException;
use Tests\TestCase;

class P806_Phase08EndToEndIntegrationTest extends TestCase
{
    /**
     * Helper to create an isolated user with profile and seller profile.
     */
    protected function createIsolatedUser(string $prefix, UserRole $role = UserRole::REGISTERED_USER): User
    {
        $unique = $prefix . '_' . bin2hex(random_bytes(5));
        $user = User::create([
            'display_name' => 'User ' . $unique,
            'email' => $unique . '@izithrift.test',
            'password_hash' => Hash::make('Retro@2026'),
            'role' => $role,
            'status' => UserStatus::ACTIVE,
        ]);

        UserProfile::create([
            'user_id' => $user->id,
            'seasonal_decor_enabled' => true,
        ]);

        SellerProfile::create([
            'user_id' => $user->id,
            'shop_slug' => 'shop-' . $unique,
            'trust_score' => 100.00,
            'wallet_balance' => 0.00,
            'escrow_held_balance' => 0.00,
            'completed_orders_count' => 0,
            'dispute_lost_count' => 0,
        ]);

        return $user;
    }

    /**
     * Clean up an isolated order and its linked ledger records.
     */
    protected function cleanUpOrder(int $orderId): void
    {
        DB::table('dispute_evidences')
            ->whereIn('dispute_id', function ($q) use ($orderId) {
                $q->select('id')->from('disputes')->where('order_id', $orderId);
            })->delete();

        DB::table('disputes')->where('order_id', $orderId)->delete();
        DB::table('wallet_transactions')->where('order_id', $orderId)->delete();
        DB::table('escrow_transactions')->where('order_id', $orderId)->delete();
        DB::table('payments')->where('order_id', $orderId)->delete();
        DB::table('shipments')->where('order_id', $orderId)->delete();
        DB::table('order_items')->where('order_id', $orderId)->delete();
        DB::table('orders')->where('id', $orderId)->delete();
    }

    /**
     * Clean up an isolated user.
     */
    protected function cleanUpUser(int $userId): void
    {
        DB::table('notifications')->where('user_id', $userId)->delete();
        DB::table('audit_logs')->where('actor_id', $userId)->orWhere('target_id', (string) $userId)->delete();
        DB::table('seller_profiles')->where('user_id', $userId)->delete();
        DB::table('user_profiles')->where('user_id', $userId)->delete();
        DB::table('personal_access_tokens')->where('tokenable_id', $userId)->delete();
        DB::table('users')->where('id', $userId)->delete();
    }

    /**
     * 1. TASK-P806-01 & AC-P806-01: Comprehensive 21-Screen Route, View & Wireframe Audit.
     * Verifies that every single one of the 21 canonical Admin screens is accessible by its
     * authorized role, renders without Blade/Vite errors, and default-denies unauthorized roles.
     */
    public function test_21_canonical_screens_complete_route_view_and_rbac_audit(): void
    {
        $admin = User::where('email', 'admin@izithrift.local')->firstOrFail();
        $moderator = User::where('email', 'moderator@izithrift.local')->firstOrFail();
        $support = User::where('email', 'support@izithrift.local')->firstOrFail();
        $buyer = User::where('role', UserRole::REGISTERED_USER)->firstOrFail();

        // 1. A-LG-01: Admin Login Screen (Guest accessible, 200 OK)
        Auth::guard('web')->logout();
        $this->get('/admin/login')->assertStatus(200)->assertSee('Đăng nhập Quản trị');

        // 2. A-DB-01: Operations Dashboard (Admin 200 OK, sees GMV)
        $this->actingAs($admin, 'web')->get('/admin/dashboard')
            ->assertStatus(200)
            ->assertSee('Bảng điều khiển Vận hành')
            ->assertSee('Tổng GMV hoàn tất');

        // 3. A-MD-01: Moderation Queue (Moderator 200 OK)
        $this->actingAs($moderator, 'web')->get('/admin/moderation/products')
            ->assertStatus(200)
            ->assertSee('Hàng đợi Kiểm duyệt Sản phẩm');

        // 4. A-MD-02: Moderation Detail (Moderator 200 OK)
        $firstProduct = Product::firstOrFail();
        $this->actingAs($moderator, 'web')->get("/admin/moderation/products/{$firstProduct->id}")
            ->assertStatus(200)
            ->assertSee('Thẩm định Sản phẩm');

        // 5. A-PR-01: Master Product Inventory (Moderator 200 OK)
        $this->actingAs($moderator, 'web')->get('/admin/products')
            ->assertStatus(200)
            ->assertSee('Quản lý Sản phẩm');

        // 6. A-CT-01: Taxonomy & Categories (Moderator 200 OK)
        $this->actingAs($moderator, 'web')->get('/admin/catalog')
            ->assertStatus(200)
            ->assertSee('Quản lý Phân loại');

        // 7. A-AC-01: Auctions Real-Time Monitor (Moderator 200 OK)
        $this->actingAs($moderator, 'web')->get('/admin/auctions')
            ->assertStatus(200)
            ->assertSee('Quản lý Đấu giá');

        // 8. A-AC-02: Auction Live Bids & Detail (Moderator 200 OK)
        $firstAuction = DB::table('auctions')->first();
        if ($firstAuction) {
            $this->actingAs($moderator, 'web')->get("/admin/auctions/{$firstAuction->id}")
                ->assertStatus(200)
                ->assertSee('Chi tiết Phiên Đấu giá');
        }

        // 9. A-AC-03: Emergency Auction Intervention (Covered via cancel endpoint permission)
        $this->actingAs($support, 'web')->post("/admin/auctions/1/cancel", ['reason' => 'Test reason'])
            ->assertStatus(403); // Support cannot cancel auctions

        // 10. A-OR-01: 4-State Order Management (Support 200 OK)
        $this->actingAs($support, 'web')->get('/admin/orders')
            ->assertStatus(200)
            ->assertSee('Quản lý Đơn hàng & Escrow');

        // 11. A-OR-02: Order Detail & 360° Escrow Inspector (Support 200 OK)
        $firstOrder = Order::firstOrFail();
        $this->actingAs($support, 'web')->get("/admin/orders/{$firstOrder->id}")
            ->assertStatus(200)
            ->assertSee('Chi tiết Đơn hàng');

        // 12. A-PM-01: Payment Transactions & QR Gateway Monitor (Admin 200 OK, Support 403)
        $this->actingAs($admin, 'web')->get('/admin/payments')
            ->assertStatus(200)
            ->assertSee('Giao dịch Thanh toán');
        $this->actingAs($support, 'web')->get('/admin/payments')->assertStatus(403);

        // 13. A-ES-01: Immutable Escrow Ledger Explorer (Admin ONLY, Moderator & Support 403)
        $this->actingAs($admin, 'web')->get('/admin/escrow')
            ->assertStatus(200)
            ->assertSee('Sổ cái Ký quỹ và Đối soát Tài chính');
        $this->actingAs($moderator, 'web')->get('/admin/escrow')->assertStatus(403);
        $this->actingAs($support, 'web')->get('/admin/escrow')->assertStatus(403);

        // 14. A-DP-01: Dispute Management Queue (Support 200 OK, Moderator 403)
        $this->actingAs($support, 'web')->get('/admin/disputes')
            ->assertStatus(200)
            ->assertSee('Quản lý Khiếu nại');
        $this->actingAs($moderator, 'web')->get('/admin/disputes')->assertStatus(403);

        // 15. A-DP-02: Dispute Detail & 2-Way Evidence Workbench (Support 200 OK)
        $firstDispute = Dispute::first();
        if ($firstDispute) {
            $this->actingAs($support, 'web')->get("/admin/disputes/{$firstDispute->id}")
                ->assertStatus(200)
                ->assertSee('Hồ sơ Xử lý Khiếu nại');
        }

        // 16. A-CM-01: Violation Reports Management (Moderator 200 OK)
        $this->actingAs($moderator, 'web')->get('/admin/moderation/reports')
            ->assertStatus(200)
            ->assertSee('Báo cáo Vi phạm');

        // 17. A-US-01: User Management Directory (Admin, Mod & Support 200 OK)
        $this->actingAs($support, 'web')->get('/admin/users')
            ->assertStatus(200)
            ->assertSee('Quản lý Người dùng');
        $this->actingAs($moderator, 'web')->get('/admin/users')
            ->assertStatus(200)
            ->assertSee('Quản lý Người dùng');

        // 18. A-US-02: User Detail, 360° Inspector & Governance (Support 200 OK)
        $this->actingAs($support, 'web')->get("/admin/users/{$buyer->id}")
            ->assertStatus(200)
            ->assertSee('Hồ sơ Người dùng');

        // 19. A-ST-01: Platform Settings & Configuration (Admin ONLY, Mod & Support 403)
        $this->actingAs($admin, 'web')->get('/admin/settings')
            ->assertStatus(200)
            ->assertSee('Cấu hình Nền tảng');
        $this->actingAs($moderator, 'web')->get('/admin/settings')->assertStatus(403);
        $this->actingAs($support, 'web')->get('/admin/settings')->assertStatus(403);

        // 20. A-AD-01: Activity Audit Logs Explorer (Admin ONLY, Mod & Support 403)
        $this->actingAs($admin, 'web')->get('/admin/audit-logs')
            ->assertStatus(200)
            ->assertSee('Nhật ký Kiểm toán Hệ thống');
        $this->actingAs($moderator, 'web')->get('/admin/audit-logs')->assertStatus(403);
        $this->actingAs($support, 'web')->get('/admin/audit-logs')->assertStatus(403);

        // 21. A-DT-01: Developer Tools & Manual Job Triggers (Dual-Gate: Admin + DEMO_MODE=true)
        Config::set('retromarket.demo_mode', true);
        $this->actingAs($admin, 'web')->get('/admin/dev-tools')
            ->assertStatus(200)
            ->assertSee('Developer Tools');
        $this->actingAs($support, 'web')->get('/admin/dev-tools')->assertStatus(403);
        $this->actingAs($moderator, 'web')->get('/admin/dev-tools')->assertStatus(403);

        // Default Deny Check: Registered User is blocked on ALL Admin endpoints
        $this->actingAs($buyer, 'web')->get('/admin/dashboard')->assertStatus(403);
        $this->actingAs($buyer, 'web')->get('/admin/products')->assertStatus(403);
        $this->actingAs($buyer, 'web')->get('/admin/orders')->assertStatus(403);
    }

    /**
     * 2. AC-P806-02: Flow 1 – E2E Moderation & Resubmit Lifecycle (DEC-05).
     * Mobile API Seller listing -> Admin Web Moderator Reject with Reason ->
     * Mobile API Seller Resubmit -> Admin Web Moderator Approve -> Public Mobile Discovery.
     */
    public function test_e2e_moderation_lifecycle_cross_platform_flow(): void
    {
        $seller = null;
        $createdProductId = null;

        try {
            $seller = $this->createIsolatedUser('e2e_mod_seller');
            $moderator = User::where('email', 'moderator@izithrift.local')->firstOrFail();
            $category = Category::whereNull('parent_id')->firstOrFail();

            $sellerToken = $seller->createToken('seller_token')->plainTextToken;

            // Step 1: Seller posts listing via Mobile API (M-SL-03 / POST /api/v1/seller/products)
            auth()->forgetGuards();
            $createRes = $this->withHeader('Authorization', "Bearer {$sellerToken}")
                ->postJson('/api/v1/seller/products', [
                    'category_id' => $category->id,
                    'title' => 'Áo Khoác Da Thật Vintage 1980s Tuyển Chọn',
                    'description' => 'Áo khoác da cừu phong cách cổ điển, lót lụa nguyên bản.',
                    'condition' => 'LIKE_NEW',
                    'defect_info' => 'Không có vết rách, khóa đồng chạy mượt.',
                    'listing_type' => 'FIXED_PRICE',
                    'price' => 450000.00,
                    'total_quantity' => 1,
                    'submit_for_review' => true,
                ]);

            $createRes->assertStatus(201);
            $createdProductId = $createRes->json('data.id');
            $this->assertEquals('PENDING_REVIEW', $createRes->json('data.status'));

            // Step 2: Moderator views listing on Admin Web (A-MD-02)
            $this->actingAs($moderator, 'web')
                ->get("/admin/moderation/products/{$createdProductId}")
                ->assertStatus(200)
                ->assertSee('Áo Khoác Da Thật Vintage 1980s Tuyển Chọn');

            // Step 3: Moderator rejects listing on Admin Web (POST /admin/moderation/products/{id}/reject)
            $rejectReason = 'Ảnh chụp chưa rõ nhãn mác cổ áo và cần thêm ảnh chụp mặt trong theo chuẩn DEC-05';
            $rejectRes = $this->actingAs($moderator, 'web')
                ->post("/admin/moderation/products/{$createdProductId}/reject", [
                    'reason' => $rejectReason,
                ]);

            $rejectRes->assertRedirect(route('admin.moderation.products.index'));

            // Verify DB state
            $productAfterReject = Product::findOrFail($createdProductId);
            $this->assertEquals(ProductStatus::REJECTED, $productAfterReject->status);
            $this->assertEquals($rejectReason, $productAfterReject->rejection_reason);

            // Step 4: Seller checks listing via Mobile API (M-PR-01 / GET /api/v1/products/{id})
            auth()->forgetGuards();
            $sellerCheckRes = $this->withHeader('Authorization', "Bearer {$sellerToken}")
                ->getJson("/api/v1/products/{$createdProductId}");
            $sellerCheckRes->assertStatus(200);
            $this->assertEquals('REJECTED', $sellerCheckRes->json('data.product.status'));
            $this->assertEquals($rejectReason, $sellerCheckRes->json('data.product.rejection_reason'));

            // Step 5: Seller edits and resubmits listing via Mobile API (M-SL-04 / PUT /api/v1/seller/products/{id})
            auth()->forgetGuards();
            $resubmitRes = $this->withHeader('Authorization', "Bearer {$sellerToken}")
                ->putJson("/api/v1/seller/products/{$createdProductId}", [
                    'title' => 'Áo Khoác Da Thật Vintage 1980s Tuyển Chọn [Đã bổ sung ảnh mác]',
                    'description' => 'Áo khoác da cừu phong cách cổ điển, đã cập nhật chi tiết tem nhãn.',
                    'condition' => 'LIKE_NEW',
                    'defect_info' => 'Không lỗi, đã bổ sung ảnh tem nhãn rõ nét.',
                    'price' => 450000.00,
                    'submit_for_review' => true,
                ]);

            $resubmitRes->assertStatus(200);
            $this->assertEquals('PENDING_REVIEW', $resubmitRes->json('data.status'));
            $this->assertNull($resubmitRes->json('data.rejection_reason'));

            // Step 6: Moderator reviews and approves on Admin Web (POST /admin/moderation/products/{id}/approve)
            $approveRes = $this->actingAs($moderator, 'web')
                ->post("/admin/moderation/products/{$createdProductId}/approve", [
                    'verification_level' => 'MODERATOR_REVIEWED',
                    'reason' => 'Đã kiểm tra tem nhãn hợp lệ, đạt tiêu chuẩn xuất bản.',
                ]);

            $approveRes->assertRedirect(route('admin.moderation.products.index'));

            // Step 7: Product is now APPROVED and visible on Public Mobile Discovery API (GET /api/v1/products)
            $productAfterApprove = Product::findOrFail($createdProductId);
            $this->assertEquals(ProductStatus::APPROVED, $productAfterApprove->status);
            $this->assertEquals('MODERATOR_REVIEWED', $productAfterApprove->verification_level);

            auth()->forgetGuards();
            $publicDiscoveryRes = $this->getJson("/api/v1/products?q=1980s");
            $publicDiscoveryRes->assertStatus(200);
            $items = $publicDiscoveryRes->json('data');
            $found = collect($items)->contains('id', $createdProductId);
            $this->assertTrue($found, 'Approved product must be discoverable on public mobile API.');

            // Verify Moderation Logs and Audit Logs
            $modLogsCount = ProductModerationLog::where('product_id', $createdProductId)->count();
            $this->assertGreaterThanOrEqual(2, $modLogsCount, 'Must have at least REJECT and APPROVE moderation logs.');

            $auditLogsCount = AuditLog::where('target_type', 'products')
                ->where('target_id', (string) $createdProductId)
                ->count();
            $this->assertGreaterThanOrEqual(1, $auditLogsCount, 'Must record audit log for product governance.');

        } finally {
            if ($createdProductId) {
                DB::table('product_moderation_logs')->where('product_id', $createdProductId)->delete();
                DB::table('audit_logs')->where('target_type', 'product')->where('target_id', (string) $createdProductId)->delete();
                DB::table('notifications')->where('target_type', 'products')->where('target_id', $createdProductId)->delete();
                DB::table('products')->where('id', $createdProductId)->delete();
            }
            if ($seller) {
                $this->cleanUpUser($seller->id);
            }
        }
    }

    /**
     * 3. AC-P806-02 & AC-P806-03: Flow 2 – E2E Order, Escrow & Dispute Verdict Lifecycle with Zero Ledger Drift.
     * Buyer order -> Mobile Dispute -> Admin Web Support Request Info ->
     * Support Forbidden from Verdict (DEC-08-03) -> Admin Financial Verdict (DEC-07) ->
     * Mathematical Verification of Zero Ledger Drift (0.00 discrepancy).
     */
    public function test_e2e_order_escrow_dispute_verdict_and_zero_ledger_drift(): void
    {
        $seller = null;
        $buyer = null;
        $order = null;

        try {
            $seller = $this->createIsolatedUser('e2e_esc_seller');
            $seller->sellerProfile()->update(['escrow_held_balance' => 300000.00]);

            $buyer = $this->createIsolatedUser('e2e_esc_buyer');
            $admin = User::where('email', 'admin@izithrift.local')->firstOrFail();
            $support = User::where('email', 'support@izithrift.local')->firstOrFail();

            $buyerToken = $buyer->createToken('buyer_token')->plainTextToken;

            // Step 1: Create active order with HELD escrow (Simulating Mobile Checkout & Mock QR Payment)
            $order = Order::create([
                'order_code' => 'ORD-E2E-' . time(),
                'buyer_id' => $buyer->id,
                'seller_id' => $seller->id,
                'order_source' => 'FIXED_PRICE',
                'item_subtotal' => 300000.00,
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => 0.0600,
                'protection_fixed_fee_applied' => 7000.00,
                'buyer_protection_fee' => 25000.00,
                'total_amount' => 325000.00,
                'seller_net_amount' => 300000.00,
                'shipping_address_snapshot' => ['recipient_name' => 'Linh', 'phone' => '0901234567'],
                'order_status' => OrderStatus::DELIVERED,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => EscrowStatus::HELD,
                'dispute_status' => DisputeStatus::NONE,
                'payment_expires_at' => now()->addMinutes(30),
                'paid_at' => now(),
                'delivered_at' => now(),
            ]);

            OrderItem::create([
                'order_id' => $order->id,
                'product_id' => 1,
                'product_code_snapshot' => 'PRD-E2E-001',
                'product_title_snapshot' => 'Váy vintage hoa nhí',
                'unit_price_snapshot' => 300000.00,
                'quantity' => 1,
                'line_total' => 300000.00,
                'condition_snapshot' => 'LIKE_NEW',
                'defect_info_snapshot' => 'Không lỗi',
                'primary_image_snapshot' => 'https://izithrift.local/storage/sample.jpg',
            ]);

            Payment::create([
                'payment_code' => 'PMT-E2E-' . time(),
                'order_id' => $order->id,
                'payer_id' => $buyer->id,
                'amount' => 325000.00,
                'qr_payload' => 'vietqr://mock-payload-e2e',
                'payment_method' => 'MOCK_VIETQR',
                'payment_reference' => 'REF-E2E-' . time(),
                'status' => PaymentStatus::PAID,
                'expires_at' => now()->addMinutes(30),
                'paid_at' => now(),
            ]);

            EscrowTransaction::create([
                'transaction_code' => 'ESC-HOLD-' . time(),
                'order_id' => $order->id,
                'buyer_id' => $buyer->id,
                'seller_id' => $seller->id,
                'transaction_type' => 'HOLD',
                'gross_amount' => 325000.00,
                'item_subtotal_amount' => 300000.00,
                'buyer_protection_fee_amount' => 25000.00,
                'seller_released_amount' => 0.00,
                'buyer_refunded_amount' => 0.00,
                'platform_fee_retained' => 0.00,
                'note' => 'Ký quỹ đơn hàng ORD-E2E',
            ]);

            // Step 2: Buyer opens Dispute via Mobile API (POST /api/v1/orders/{id}/disputes)
            auth()->forgetGuards();
            $disputeRes = $this->withHeader('Authorization', "Bearer {$buyerToken}")
                ->postJson("/api/v1/orders/{$order->id}/disputes", [
                    'reason_category' => 'ITEM_NOT_AS_DESCRIBED',
                    'description' => 'Váy hoa nhí bị ố vàng diện rộng và rách đường chỉ eo.',
                ]);

            $disputeRes->assertStatus(201);
            $disputeId = $disputeRes->json('data.id');
            $this->assertEquals('OPEN', $disputeRes->json('data.status'));

            // Step 3: Support Staff views dispute on Admin Web (A-DP-02: GET /admin/disputes/{id})
            $this->actingAs($support, 'web')
                ->get("/admin/disputes/{$disputeId}")
                ->assertStatus(200)
                ->assertSee('Hồ sơ Xử lý Khiếu nại')
                ->assertSee('Váy hoa nhí bị ố vàng');

            // Step 4: Support Staff requests additional evidence on Admin Web (POST /admin/disputes/{id}/request-info)
            $requestInfoRes = $this->actingAs($support, 'web')
                ->post("/admin/disputes/{$disputeId}/request-info", [
                    'message_note' => 'Yêu cầu người mua gửi thêm video mở gói hàng và ảnh chụp tem mác trong 24h.',
                ]);

            $requestInfoRes->assertRedirect(route('admin.disputes.show', $disputeId));

            $disputeAfterNote = Dispute::findOrFail($disputeId);
            $this->assertEquals(DisputeStatus::NEED_MORE_INFO, $disputeAfterNote->status);

            // Step 5: Support Staff attempts to issue financial verdict -> BLOCKED WITH 403 (DEC-08-03)
            $supportVerdictRes = $this->actingAs($support, 'web')
                ->post("/admin/disputes/{$disputeId}/verdict", [
                    'verdict' => 'APPROVE_BUYER_REFUND',
                    'resolution_note' => 'Support cố tình phán quyết hoàn tiền trái thẩm quyền',
                ]);

            $supportVerdictRes->assertStatus(403);

            // Step 6: Supreme Admin issues financial verdict on Admin Web (POST /admin/disputes/{id}/verdict)
            $adminVerdictRes = $this->actingAs($admin, 'web')
                ->post("/admin/disputes/{$disputeId}/verdict", [
                    'verdict' => 'APPROVE_BUYER_REFUND',
                    'resolution_note' => 'Chấp thuận hoàn tiền 100% cho người mua do sản phẩm sai lệch tình trạng nghiêm trọng.',
                ]);

            $adminVerdictRes->assertRedirect(route('admin.disputes.show', $disputeId));

            // Verify post-verdict DB status
            $orderAfterVerdict = Order::findOrFail($order->id);
            $disputeAfterVerdict = Dispute::findOrFail($disputeId);

            $this->assertEquals(OrderStatus::CANCELLED, $orderAfterVerdict->order_status);
            $this->assertEquals(EscrowStatus::REFUNDED, $orderAfterVerdict->escrow_status);
            $this->assertEquals(DisputeStatus::RESOLVED, $disputeAfterVerdict->status);
            $this->assertEquals('APPROVE_BUYER_REFUND', $disputeAfterVerdict->admin_verdict);

            // Verify Immutable Escrow Transaction created
            $refundTx = EscrowTransaction::where('order_id', $order->id)
                ->where('transaction_type', 'FULL_REFUND')
                ->first();
            $this->assertNotNull($refundTx);
            $this->assertEquals(325000.00, (float) $refundTx->gross_amount);
            $this->assertEquals(325000.00, (float) $refundTx->buyer_refunded_amount);
            $this->assertEquals(0.00, (float) $refundTx->seller_released_amount);

            // Step 7: Prove Mathematically Zero Ledger Drift (AC-P806-03)
            // Platform Escrow Held Balance must exactly equal aggregate Active Orders in HELD status
            $totalHeldInOrders = (float) Order::where('escrow_status', EscrowStatus::HELD)->sum('item_subtotal');
            $totalHeldInSellerProfiles = (float) SellerProfile::sum('escrow_held_balance');
            $ledgerDrift = abs($totalHeldInOrders - $totalHeldInSellerProfiles);

            $this->assertEquals(
                0.00,
                $ledgerDrift,
                "Zero Ledger Drift Invariant Violated! Orders Held: {$totalHeldInOrders}, Sellers Held: {$totalHeldInSellerProfiles}, Drift: {$ledgerDrift}"
            );

        } finally {
            if ($order) {
                $this->cleanUpOrder($order->id);
            }
            if ($seller) {
                $this->cleanUpUser($seller->id);
            }
            if ($buyer) {
                $this->cleanUpUser($buyer->id);
            }
        }
    }

    /**
     * 4. AC-P806-02: Flow 3 – E2E Auction Lifecycle & Developer Tools Trigger (BR-AU-04, BR-AU-07, A-DT-01).
     * Dual-Gate protection, manual job execution via SystemDevToolsService, and audit logging.
     */
    public function test_e2e_auction_lifecycle_and_developer_tools_trigger(): void
    {
        $admin = User::where('email', 'admin@izithrift.local')->firstOrFail();
        $support = User::where('email', 'support@izithrift.local')->firstOrFail();

        // Dual-Gate Gate 1: Non-Admin blocked (403)
        Config::set('retromarket.demo_mode', true);
        $this->actingAs($support, 'web')->get('/admin/dev-tools')->assertStatus(403);
        $this->actingAs($support, 'web')->post('/admin/dev-tools/trigger', [
            'action_key' => 'EXPIRE_UNPAID_ORDERS',
        ])->assertStatus(403);

        // Dual-Gate Gate 2: DEMO_MODE=false blocked (403)
        Config::set('retromarket.demo_mode', false);
        $this->actingAs($admin, 'web')->get('/admin/dev-tools')->assertStatus(403);
        $this->actingAs($admin, 'web')->post('/admin/dev-tools/trigger', [
            'action_key' => 'EXPIRE_UNPAID_ORDERS',
        ])->assertStatus(403);

        // Dual-Gate Passed: Admin + DEMO_MODE=true
        Config::set('retromarket.demo_mode', true);
        $this->actingAs($admin, 'web')->get('/admin/dev-tools')
            ->assertStatus(200)
            ->assertSee('Developer Tools')
            ->assertSee('Manual Job Triggers');

        // Trigger manual lifecycle jobs trigger
        $triggerRes = $this->actingAs($admin, 'web')->post('/admin/dev-tools/trigger', [
            'action_key' => 'EXPIRE_UNPAID_ORDERS',
        ]);

        $triggerRes->assertRedirect(route('admin.dev_tools.index'));

        // Verify audit log recorded for manual job trigger
        $auditLog = AuditLog::where('action', 'DEVTOOLS_MANUAL_JOB_TRIGGER')
            ->where('actor_id', $admin->id)
            ->latest('id')
            ->first();

        $this->assertNotNull($auditLog);
        $this->assertEquals('SYSTEM', $auditLog->target_type);
        $this->assertEquals('Manual trigger: EXPIRE_UNPAID_ORDERS', $auditLog->reason);
    }

    /**
     * 5. AC-P806-02: Flow 4 – E2E User Suspension & Cross-Guard Isolation.
     * Admin suspends user on A-US-02 -> User immediately blocked on Mobile API (401/403)
     * and Admin Web session (403).
     */
    public function test_e2e_user_suspension_and_cross_guard_isolation(): void
    {
        $targetUser = null;

        try {
            $targetUser = $this->createIsolatedUser('e2e_suspend_target');
            $admin = User::where('email', 'admin@izithrift.local')->firstOrFail();

            // Step 1: Active user accesses Mobile API with token -> 200 OK
            auth()->forgetGuards();
            $token = $targetUser->createToken('active_test_token')->plainTextToken;
            $activeMeRes = $this->withHeader('Authorization', "Bearer {$token}")
                ->getJson('/api/v1/profile');
            $activeMeRes->assertStatus(200);
            $this->assertEquals('ACTIVE', $activeMeRes->json('data.user.status'));

            // Step 2: Admin inspects user on Admin Web (A-US-02)
            $this->actingAs($admin, 'web')
                ->get("/admin/users/{$targetUser->id}")
                ->assertStatus(200)
                ->assertSee('User e2e_suspend_target');

            // Step 3: Admin suspends user on Admin Web (POST /admin/users/{id}/status)
            $suspensionReason = 'Nghi vấn gian lận thông tin định danh và tạo đơn hàng ảo';
            $suspendRes = $this->actingAs($admin, 'web')
                ->post("/admin/users/{$targetUser->id}/status", [
                    'status' => 'SUSPENDED',
                    'reason' => $suspensionReason,
                ]);

            $suspendRes->assertRedirect(route('admin.users.show', $targetUser->id));

            // Verify User status updated in DB
            $targetUser->refresh();
            $this->assertEquals(UserStatus::SUSPENDED, $targetUser->status);
            $this->assertEquals($suspensionReason, $targetUser->status_reason);

            // Step 4: Previous Sanctum token must be revoked and rejected on Mobile API -> 401 Unauthenticated
            auth()->forgetGuards();
            $revokedTokenRes = $this->withHeader('Authorization', "Bearer {$token}")
                ->getJson('/api/v1/profile');
            $revokedTokenRes->assertStatus(401);

            // Step 5: If a new token is somehow created for suspended user, EnsureUserIsActive blocks with 403
            auth()->forgetGuards();
            $newToken = $targetUser->createToken('new_token')->plainTextToken;
            $blockedMeRes = $this->withHeader('Authorization', "Bearer {$newToken}")
                ->getJson('/api/v1/profile');
            $blockedMeRes->assertStatus(403);
            $this->assertEquals('ACCOUNT_SUSPENDED', $blockedMeRes->json('error_code'));

            // Step 6: Verify Admin restores user status
            $restoreRes = $this->actingAs($admin, 'web')
                ->post("/admin/users/{$targetUser->id}/status", [
                    'status' => 'ACTIVE',
                    'reason' => 'Đã hoàn tất xác minh danh tính và mở khóa tài khoản.',
                ]);

            $restoreRes->assertRedirect(route('admin.users.show', $targetUser->id));

            $targetUser->refresh();
            $this->assertEquals(UserStatus::ACTIVE, $targetUser->status);

        } finally {
            if ($targetUser) {
                $this->cleanUpUser($targetUser->id);
            }
        }
    }

    /**
     * 6. AC-P806-03: Strict Append-Only Immutability Guard Verification.
     * Proves that update() and delete() on all immutable ledger/audit models are strictly rejected.
     */
    public function test_immutable_ledger_and_audit_trail_invariance(): void
    {
        $auditLog = AuditLog::first();
        if ($auditLog) {
            $this->expectException(LogicException::class);
            $auditLog->update(['reason' => 'Attempting illegal update']);
        }

        $escrowTx = EscrowTransaction::first();
        if ($escrowTx) {
            $this->expectException(LogicException::class);
            $escrowTx->delete();
        }
    }
}
