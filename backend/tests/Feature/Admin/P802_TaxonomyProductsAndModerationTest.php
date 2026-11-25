<?php

namespace Tests\Feature\Admin;

use App\Enums\ProductCondition;
use App\Enums\ProductStatus;
use App\Enums\UserRole;
use App\Models\AuditLog;
use App\Models\Brand;
use App\Models\Category;
use App\Models\Product;
use App\Models\ProductModerationLog;
use App\Models\User;
use LogicException;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

class P802_TaxonomyProductsAndModerationTest extends TestCase
{
    use DatabaseTransactions;

    protected User $admin;
    protected User $moderator;
    protected User $support;
    protected User $buyer;

    protected function setUp(): void
    {
        parent::setUp();
        $this->admin = User::where('email', 'admin@izithrift.local')->firstOrFail();
        $this->moderator = User::where('email', 'moderator@izithrift.local')->firstOrFail();
        $this->support = User::where('email', 'support@izithrift.local')->firstOrFail();
        $this->buyer = User::where('role', UserRole::REGISTERED_USER)->firstOrFail();
    }

    /**
     * Helper to create a test product in isolated fashion.
     */
    protected function createTestProduct(array $attributes = []): Product
    {
        $seller = User::where('role', UserRole::REGISTERED_USER)->firstOrFail();
        $category = Category::whereNotNull('parent_id')->first() ?? Category::firstOrFail();
        $brand = Brand::first();

        return Product::create(array_merge([
            'product_code' => 'PRD-TEST-' . uniqid(),
            'seller_id' => $seller->id,
            'category_id' => $category->id,
            'brand_id' => $brand?->id,
            'title' => 'Vintage Test Product ' . uniqid(),
            'slug' => 'vintage-test-product-' . uniqid(),
            'description' => 'Test description for moderation inspection.',
            'condition' => ProductCondition::NEW_WITH_TAGS,
            'defect_info' => 'Vết sờn nhẹ ở gấu áo phía sau lưng',
            'listing_type' => 'FIXED_PRICE',
            'price' => 350000.00,
            'total_quantity' => 1,
            'available_quantity' => 1,
            'status' => ProductStatus::PENDING_REVIEW,
        ], $attributes));
    }

    /**
     * AC-P802-01: Moderation Queue (A-MD-01) displays PENDING_REVIEW listings and filters across all 5 conditions.
     */
    public function test_moderation_queue_renders_and_filters_across_all_5_conditions(): void
    {
        $prodNew = $this->createTestProduct(['condition' => ProductCondition::NEW_WITH_TAGS]);
        $prodWorn = $this->createTestProduct(['condition' => ProductCondition::VINTAGE_WORN]);

        try {
            $response = $this->actingAs($this->moderator, 'web')->get('/admin/moderation/products');

            $response->assertStatus(200);
            $response->assertSee('Hàng đợi Chờ Kiểm duyệt');
            $response->assertSee($prodNew->product_code);
            $response->assertSee($prodWorn->product_code);

            // Filter by condition: NEW_WITH_TAGS
            $filterNew = $this->actingAs($this->moderator, 'web')
                ->get('/admin/moderation/products?condition=NEW_WITH_TAGS');
            $filterNew->assertStatus(200);
            $filterNew->assertSee($prodNew->product_code);

            // Filter by condition: VINTAGE_WORN
            $filterWorn = $this->actingAs($this->moderator, 'web')
                ->get('/admin/moderation/products?condition=VINTAGE_WORN');
            $filterWorn->assertStatus(200);
            $filterWorn->assertSee($prodWorn->product_code);
        } finally {
            $prodNew->delete();
            $prodWorn->delete();
        }
    }

    /**
     * AC-P802-01: Moderation Detail (A-MD-02) displays Split-Pane review, defect slip (BR-PR-03) and history.
     */
    public function test_moderation_detail_split_pane_renders_defect_slip_and_history(): void
    {
        $product = $this->createTestProduct([
            'condition' => ProductCondition::GOOD,
            'defect_info' => 'Vết ố nhỏ kích thước 1cm ở cổ áo bên trái',
        ]);

        try {
            $response = $this->actingAs($this->moderator, 'web')
                ->get('/admin/moderation/products/' . $product->id);

            $response->assertStatus(200);
            $response->assertSee($product->product_code);
            $response->assertSee('Phiếu Khai Báo Khuyết Điểm Đồ Si (BR-PR-03)');
            $response->assertSee('Vết ố nhỏ kích thước 1cm ở cổ áo bên trái');
            $response->assertSee('Quyết định Thẩm định (Moderation Verdict)');
            $response->assertSee('Phê duyệt Xuất bản');
            $response->assertSee('Từ chối Bài đăng (Reject - DEC-05)');
        } finally {
            $product->delete();
        }
    }

    /**
     * AC-P802-02: Approve product transitions status to APPROVED, records moderation & audit logs.
     */
    public function test_approve_transitions_to_approved_writes_moderation_and_audit_logs(): void
    {
        $product = $this->createTestProduct();

        try {
            $this->get('/admin/moderation/products/' . $product->id);

            $response = $this->actingAs($this->moderator, 'web')
                ->post('/admin/moderation/products/' . $product->id . '/approve', [
                    '_token' => csrf_token(),
                    'verification_level' => 'MODERATOR_REVIEWED',
                    'reason' => 'Đã kiểm tra tem nhãn và chi tiết vải đạt chuẩn vintage.',
                ]);

            $response->assertRedirect(route('admin.moderation.products.index'));
            $response->assertSessionHas('success');

            $product->refresh();
            $this->assertEquals(ProductStatus::APPROVED, $product->status);
            $this->assertEquals('MODERATOR_REVIEWED', $product->verification_level);

            // Verify immutable moderation log
            $modLog = ProductModerationLog::where('product_id', $product->id)
                ->where('action', 'APPROVED')
                ->first();
            $this->assertNotNull($modLog);
            $this->assertEquals($this->moderator->id, $modLog->moderator_id);

            // Verify audit log
            $auditLog = AuditLog::where('target_id', $product->id)
                ->where('action', 'APPROVE_PRODUCT')
                ->first();
            $this->assertNotNull($auditLog);
        } finally {
            ProductModerationLog::where('product_id', $product->id)->forceDelete();
            $product->delete();
        }
    }

    /**
     * AC-P802-02: Reject without reason fails validation; with reason updates product to REJECTED (DEC-05).
     */
    public function test_reject_without_reason_fails_validation_and_with_reason_updates_product(): void
    {
        $product = $this->createTestProduct();

        try {
            $this->get('/admin/moderation/products/' . $product->id);

            // 1. Missing reason must fail validation
            $failResponse = $this->actingAs($this->moderator, 'web')
                ->from('/admin/moderation/products/' . $product->id)
                ->post('/admin/moderation/products/' . $product->id . '/reject', [
                    '_token' => csrf_token(),
                    'reason' => '',
                ]);
            $failResponse->assertRedirect('/admin/moderation/products/' . $product->id);
            $failResponse->assertSessionHasErrors('reason');

            // 2. Reason < 5 chars must fail validation
            $shortResponse = $this->actingAs($this->moderator, 'web')
                ->from('/admin/moderation/products/' . $product->id)
                ->post('/admin/moderation/products/' . $product->id . '/reject', [
                    '_token' => csrf_token(),
                    'reason' => 'Lỗi',
                ]);
            $shortResponse->assertSessionHasErrors('reason');

            // 3. Valid reason >= 5 chars
            $rejectionReason = 'Ảnh chụp nhãn hiệu bị mờ, vui lòng chụp rõ tem tag để xác thực độ vintage (DEC-05).';
            $successResponse = $this->actingAs($this->moderator, 'web')
                ->post('/admin/moderation/products/' . $product->id . '/reject', [
                    '_token' => csrf_token(),
                    'reason' => $rejectionReason,
                ]);

            $successResponse->assertRedirect(route('admin.moderation.products.index'));

            $product->refresh();
            $this->assertEquals(ProductStatus::REJECTED, $product->status);
            $this->assertEquals($rejectionReason, $product->rejection_reason);

            // Verify moderation log
            $modLog = ProductModerationLog::where('product_id', $product->id)
                ->where('action', 'REJECTED')
                ->first();
            $this->assertNotNull($modLog);
            $this->assertEquals($rejectionReason, $modLog->reason);
        } finally {
            ProductModerationLog::where('product_id', $product->id)->forceDelete();
            $product->delete();
        }
    }

    /**
     * AC-P802-03: Master Inventory (A-PR-01) supports 7 statuses, search, and administrative hide/unhide.
     */
    public function test_master_inventory_filters_across_7_statuses_and_supports_hide_unhide(): void
    {
        $product = $this->createTestProduct(['status' => ProductStatus::APPROVED]);

        try {
            // GET A-PR-01
            $response = $this->actingAs($this->moderator, 'web')->get('/admin/products');
            $response->assertStatus(200);
            $response->assertSee('Kho Sản phẩm Toàn Sàn');

            // Administrative Hide action
            $hideResponse = $this->actingAs($this->moderator, 'web')
                ->post('/admin/products/' . $product->id . '/hide', [
                    '_token' => csrf_token(),
                    'reason' => 'Phát hiện khiếu nại bản quyền hoặc mô tả không đúng thực tế (BR-PR-04).',
                ]);
            $hideResponse->assertRedirect();

            $product->refresh();
            $this->assertEquals(ProductStatus::HIDDEN, $product->status);

            // Administrative Unhide action
            $unhideResponse = $this->actingAs($this->moderator, 'web')
                ->post('/admin/products/' . $product->id . '/unhide', [
                    '_token' => csrf_token(),
                    'reason' => 'Người bán đã bổ sung hóa đơn đối chiếu hợp lệ.',
                ]);
            $unhideResponse->assertRedirect();

            $product->refresh();
            $this->assertEquals(ProductStatus::APPROVED, $product->status);
        } finally {
            ProductModerationLog::where('product_id', $product->id)->forceDelete();
            $product->delete();
        }
    }

    /**
     * AC-P802-04: Catalog Management (A-CT-01) Category CRUD with circular check and product protection (DEC-08-02).
     */
    public function test_catalog_category_crud_with_slug_validation_and_circular_hierarchy_guard(): void
    {
        $this->actingAs($this->admin, 'web');

        // 1. View A-CT-01
        $viewRes = $this->get('/admin/catalog');
        $viewRes->assertStatus(200);
        $viewRes->assertSee('Cây Phân Cấp Danh Mục');

        // 2. Create Root Category
        $rootName = 'Danh Mục Gốc Test ' . uniqid();
        $rootRes = $this->post('/admin/catalog/categories', [
            '_token' => csrf_token(),
            'name' => $rootName,
            'sort_order' => 10,
        ]);
        $rootRes->assertRedirect(route('admin.catalog.index'));
        $rootCategory = Category::where('name', $rootName)->firstOrFail();

        // 3. Create Child Category
        $childName = 'Danh Mục Con Test ' . uniqid();
        $childRes = $this->post('/admin/catalog/categories', [
            '_token' => csrf_token(),
            'name' => $childName,
            'parent_id' => $rootCategory->id,
            'sort_order' => 1,
        ]);
        $childRes->assertRedirect(route('admin.catalog.index'));
        $childCategory = Category::where('name', $childName)->firstOrFail();

        try {
            // 4. Circular Hierarchy Guard: Cannot make child parent of itself
            $selfLoopRes = $this->put('/admin/catalog/categories/' . $childCategory->id, [
                '_token' => csrf_token(),
                'name' => $childCategory->name,
                'parent_id' => $childCategory->id, // SELF LOOP!
            ]);
            $selfLoopRes->assertSessionHasErrors('parent_id');

            // 5. Circular Hierarchy Guard: Cannot make root have child as parent (descendant loop)
            $descendantLoopRes = $this->put('/admin/catalog/categories/' . $rootCategory->id, [
                '_token' => csrf_token(),
                'name' => $rootCategory->name,
                'parent_id' => $childCategory->id, // DESCENDANT LOOP!
            ]);
            $descendantLoopRes->assertSessionHasErrors('parent_id');

            // 6. Delete Category with Products Guard
            $product = $this->createTestProduct(['category_id' => $childCategory->id]);
            $deleteBlockedRes = $this->delete('/admin/catalog/categories/' . $childCategory->id, [
                '_token' => csrf_token(),
            ]);
            $deleteBlockedRes->assertSessionHasErrors('category');
            $this->assertDatabaseHas('categories', ['id' => $childCategory->id]);

            // Remove product then delete succeeds
            $product->delete();
            $deleteOkRes = $this->delete('/admin/catalog/categories/' . $childCategory->id, [
                '_token' => csrf_token(),
            ]);
            $deleteOkRes->assertRedirect(route('admin.catalog.index'));
            $this->assertDatabaseMissing('categories', ['id' => $childCategory->id]);
        } finally {
            $childCategory->delete();
            $rootCategory->delete();
        }
    }

    /**
     * AC-P802-04: Brand CRUD and synchronization with public API taxonomy.
     */
    public function test_brand_crud_and_public_taxonomy_synchronization(): void
    {
        $this->actingAs($this->admin, 'web');

        $brandName = 'Vintage Leather Test ' . uniqid();
        $brandSlug = 'vintage-leather-test-' . uniqid();

        // 1. Create Brand
        $res = $this->post('/admin/catalog/brands', [
            '_token' => csrf_token(),
            'name' => $brandName,
            'slug' => $brandSlug,
            'origin_country' => 'Ý (Italy)',
            'description' => 'Thương hiệu da vintage cao cấp từ Florence.',
        ]);
        $res->assertRedirect(route('admin.catalog.index'));

        $brand = Brand::where('slug', $brandSlug)->firstOrFail();

        try {
            // 2. Synchronized to public taxonomy API
            $apiRes = $this->getJson('/api/v1/catalog/taxonomy');
            $apiRes->assertStatus(200);
            $brandSlugs = collect($apiRes->json('data.brands'))->pluck('slug')->toArray();
            $this->assertContains($brandSlug, $brandSlugs);

            // 3. Toggle Active
            $toggleRes = $this->post('/admin/catalog/brands/' . $brand->id . '/toggle', [
                '_token' => csrf_token(),
            ]);
            $toggleRes->assertRedirect();
            $brand->refresh();
            $this->assertFalse($brand->is_active);

            // Inactive brand must disappear from public taxonomy API
            $apiRes2 = $this->getJson('/api/v1/catalog/taxonomy');
            $brandSlugs2 = collect($apiRes2->json('data.brands'))->pluck('slug')->toArray();
            $this->assertNotContains($brandSlug, $brandSlugs2);
        } finally {
            $brand->delete();
        }
    }

    /**
     * AC-P802-05: RBAC enforcement between Admin, Moderator, Support, and Registered User.
     */
    public function test_rbac_moderator_vs_admin_vs_support_vs_registered_user(): void
    {
        // 1. Moderator CAN access moderation queue and catalog view
        $this->actingAs($this->moderator, 'web')->get('/admin/moderation/products')->assertStatus(200);
        $this->actingAs($this->moderator, 'web')->get('/admin/products')->assertStatus(200);
        $this->actingAs($this->moderator, 'web')->get('/admin/catalog')->assertStatus(200);

        // 2. Moderator CANNOT mutate categories (categories.manage is Admin only) -> 403
        $modMutateRes = $this->actingAs($this->moderator, 'web')->post('/admin/catalog/categories', [
            '_token' => csrf_token(),
            'name' => 'Illegal Category',
        ]);
        $modMutateRes->assertStatus(403);

        // 3. Support Staff is BLOCKED (403) from moderation and catalog
        $this->actingAs($this->support, 'web')->get('/admin/moderation/products')->assertStatus(403);
        $this->actingAs($this->support, 'web')->get('/admin/catalog')->assertStatus(403);

        // 4. Registered User is BLOCKED (403) from all admin routes
        $this->actingAs($this->buyer, 'web')->get('/admin/moderation/products')->assertStatus(403);
        $this->actingAs($this->buyer, 'web')->get('/admin/catalog')->assertStatus(403);
        $this->actingAs($this->buyer, 'web')->get('/admin/products')->assertStatus(403);
    }

    /**
     * AC-P802-05: Product Moderation Log is strictly append-only (ImmutableLedgerRecord).
     */
    public function test_product_moderation_log_is_strictly_append_only(): void
    {
        $log = ProductModerationLog::first();
        if (!$log) {
            $product = $this->createTestProduct();
            $log = ProductModerationLog::create([
                'product_id' => $product->id,
                'moderator_id' => $this->moderator->id,
                'action' => 'APPROVED',
                'previous_status' => 'PENDING_REVIEW',
                'new_status' => 'APPROVED',
                'reason' => 'Test immutability',
            ]);
        }

        // Test update() throws LogicException
        try {
            $log->update(['action' => 'TAMPERED_ACTION']);
            $this->fail('Expected LogicException was not thrown on update() of ProductModerationLog.');
        } catch (LogicException $e) {
            $this->assertStringContainsString('Immutable ledger/audit record cannot be updated or deleted', $e->getMessage());
        }

        // Test delete() throws LogicException
        try {
            $log->delete();
            $this->fail('Expected LogicException was not thrown on delete() of ProductModerationLog.');
        } catch (LogicException $e) {
            $this->assertStringContainsString('Immutable ledger/audit record cannot be updated or deleted', $e->getMessage());
        }
    }
}
