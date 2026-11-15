<?php

namespace Tests\Feature\Api\V1;

use App\Enums\ProductStatus;
use App\Exceptions\RolePermissionDeniedException;
use App\Models\Auction;
use App\Models\AuctionSession;
use App\Models\Category;
use App\Models\Notification;
use App\Models\Product;
use App\Models\ProductModerationLog;
use App\Models\User;
use App\Services\Governance\ProductModerationService;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class ProductAndModerationTest extends TestCase
{
    /**
     * 1. Test public product search filters by keyword, category, condition, price, and sorts accurately (M-DS-02 / BR-PR-02).
     */
    public function test_public_product_search_filters_by_keyword_category_condition_price_and_sorts_accurately(): void
    {
        // Public search without authentication
        $response = $this->getJson('/api/v1/products');
        $response->assertStatus(200);
        $response->assertJsonStructure([
            'success',
            'message',
            'server_time',
            'data',
            'meta' => ['current_page', 'per_page', 'total', 'last_page', 'has_more_pages'],
        ]);

        // All returned products must have status APPROVED (BR-PR-02)
        $items = $response->json('data');
        $this->assertNotEmpty($items);
        foreach ($items as $item) {
            $this->assertEquals('APPROVED', $item['status']);
        }

        // Test keyword search
        $searchResponse = $this->getJson('/api/v1/products?q=Denim');
        $searchResponse->assertStatus(200);
        $searchItems = $searchResponse->json('data');
        $this->assertNotEmpty($searchItems);
        foreach ($searchItems as $item) {
            $this->assertStringContainsStringIgnoringCase('denim', $item['title']);
        }

        // Test category filter
        $category = Category::where('slug', 'ao-khoac-vintage')->firstOrFail();
        $catResponse = $this->getJson('/api/v1/products?category_id=' . $category->id);
        $catResponse->assertStatus(200);
        $catItems = $catResponse->json('data');
        $this->assertNotEmpty($catItems);
        foreach ($catItems as $item) {
            $this->assertEquals($category->id, $item['category']['id']);
        }

        // Test condition filter
        $condResponse = $this->getJson('/api/v1/products?condition=LIKE_NEW');
        $condResponse->assertStatus(200);
        $condItems = $condResponse->json('data');
        $this->assertNotEmpty($condItems);
        foreach ($condItems as $item) {
            $this->assertEquals('LIKE_NEW', $item['condition']);
        }

        // Test sort by price asc
        $sortAscResponse = $this->getJson('/api/v1/products?sort=price_asc');
        $sortAscResponse->assertStatus(200);
        $pricesAsc = array_column($sortAscResponse->json('data'), 'price');
        $sortedPricesAsc = $pricesAsc;
        sort($sortedPricesAsc);
        $this->assertEquals($sortedPricesAsc, $pricesAsc);

        // Test sort by price desc
        $sortDescResponse = $this->getJson('/api/v1/products?sort=price_desc');
        $sortDescResponse->assertStatus(200);
        $pricesDesc = array_column($sortDescResponse->json('data'), 'price');
        $sortedPricesDesc = $pricesDesc;
        rsort($sortedPricesDesc);
        $this->assertEquals($sortedPricesDesc, $pricesDesc);
    }

    /**
     * 2. Test product search rejects invalid price range when min exceeds max with 422.
     */
    public function test_product_search_rejects_invalid_price_range_when_min_exceeds_max_with_422(): void
    {
        $response = $this->getJson('/api/v1/products?min_price=500000&max_price=200000');
        $response->assertStatus(422);
        $response->assertJsonStructure([
            'success',
            'error_code',
            'message',
            'errors',
            'server_time',
        ]);
        $this->assertFalse($response->json('success'));
        $this->assertEquals('VALIDATION_ERROR', $response->json('error_code'));
        $this->assertArrayHasKey('max_price', $response->json('errors'));
    }

    /**
     * 3. Test product detail hides unapproved products from public but allows seller owner with rejection reason (M-PR-01 / BR-PR-02).
     */
    public function test_product_detail_hides_unapproved_products_from_public_but_allows_seller_owner_with_rejection_reason(): void
    {
        $seller = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();
        $moderator = User::where('email', 'moderator@izithrift.local')->firstOrFail();
        $buyer = User::where('email', 'buyer.linh@izithrift.local')->firstOrFail();
        $category = Category::firstOrFail();

        $testProduct = Product::create([
            'product_code' => 'PRD-TEST-REJECTED-' . time(),
            'seller_id' => $seller->id,
            'category_id' => $category->id,
            'title' => 'Áo khoác thử nghiệm bị từ chối duyệt',
            'slug' => 'ao-khoac-thu-nghiem-bi-tu-choi-' . time(),
            'description' => 'Mô tả thử nghiệm sản phẩm chi tiết',
            'condition' => 'FAIR',
            'defect_info' => 'Có vết xước ở cúc áo',
            'listing_type' => 'FIXED_PRICE',
            'price' => 320000,
            'total_quantity' => 1,
            'available_quantity' => 1,
            'status' => 'REJECTED',
            'rejection_reason' => 'Ảnh chụp mờ nhãn hiệu và sai danh mục chi tiết',
        ]);

        ProductModerationLog::create([
            'product_id' => $testProduct->id,
            'moderator_id' => $moderator->id,
            'action' => 'REJECTED',
            'previous_status' => 'PENDING_REVIEW',
            'new_status' => 'REJECTED',
            'reason' => 'Ảnh chụp mờ nhãn hiệu và sai danh mục chi tiết',
        ]);

        $sellerToken = $seller->createToken('seller_test')->plainTextToken;
        $buyerToken = $buyer->createToken('buyer_test')->plainTextToken;

        try {
            // Guest viewing unapproved product -> 404
            $guestResponse = $this->getJson("/api/v1/products/{$testProduct->id}");
            $guestResponse->assertStatus(404);
            $this->assertEquals('RESOURCE_NOT_AVAILABLE', $guestResponse->json('error_code'));

            // Other buyer viewing unapproved product -> 404
            $buyerResponse = $this->withHeader('Authorization', "Bearer {$buyerToken}")
                ->getJson("/api/v1/products/{$testProduct->id}");
            $buyerResponse->assertStatus(404);
            $this->assertEquals('RESOURCE_NOT_AVAILABLE', $buyerResponse->json('error_code'));

            // Seller owner viewing unapproved product -> 200
            $ownerResponse = $this->withHeader('Authorization', "Bearer {$sellerToken}")
                ->getJson("/api/v1/products/{$testProduct->id}");
            $ownerResponse->assertStatus(200);
            $this->assertTrue($ownerResponse->json('data.is_owner'));
            $this->assertEquals('Ảnh chụp mờ nhãn hiệu và sai danh mục chi tiết', $ownerResponse->json('data.product.rejection_reason'));
            $this->assertNotEmpty($ownerResponse->json('data.product.moderation_logs'));
            $this->assertEquals('REJECTED', $ownerResponse->json('data.product.moderation_logs.0.action'));
        } finally {
            $seller->tokens()->delete();
            $buyer->tokens()->delete();
            DB::table('product_moderation_logs')->where('product_id', $testProduct->id)->delete();
            $testProduct->delete();
        }
    }

    /**
     * 4. Test seller creates fixed price and auction listings enforcing defect info and single auction qty (M-SL-03 / BR-PR-01 / BR-PR-03).
     */
    public function test_seller_creates_fixed_price_and_auction_listings_enforcing_defect_info_and_single_auction_qty(): void
    {
        Storage::fake('public');
        $seller = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();
        $token = $seller->createToken('create_product_test')->plainTextToken;
        $category = Category::firstOrFail();

        $createdProductIds = [];

        try {
            // 1. Try to create listing with whitespace-only defect_info -> 422
            $failResponse = $this->withHeader('Authorization', "Bearer {$token}")
                ->postJson('/api/v1/seller/products', [
                    'category_id' => $category->id,
                    'title' => 'Áo Len Vintage Họa Tiết Bắc Âu Giáng Sinh',
                    'condition' => 'LIKE_NEW',
                    'defect_info' => '   ',
                    'listing_type' => 'FIXED_PRICE',
                    'price' => 250000,
                ]);
            $failResponse->assertStatus(422);
            $this->assertEquals('VALIDATION_ERROR', $failResponse->json('error_code'));
            $this->assertArrayHasKey('defect_info', $failResponse->json('errors'));

            // 2. Create valid FIXED_PRICE listing with images and quantity 3
            $imageFile = UploadedFile::fake()->image('vintage_sweater.jpg', 600, 600);
            $successResponse = $this->withHeader('Authorization', "Bearer {$token}")
                ->postJson('/api/v1/seller/products', [
                    'category_id' => $category->id,
                    'title' => 'Áo Len Vintage Họa Tiết Bắc Âu Giáng Sinh Tuyển Chọn',
                    'description' => 'Áo len đan tay cổ điển thập niên 90',
                    'condition' => 'LIKE_NEW',
                    'defect_info' => 'Không có khuyết điểm đáng kể, len còn rất đanh',
                    'listing_type' => 'FIXED_PRICE',
                    'price' => 280000,
                    'total_quantity' => 3,
                    'submit_for_review' => true,
                    'images' => [$imageFile],
                ]);
            $successResponse->assertStatus(201);
            $fixedProductId = $successResponse->json('data.id');
            $createdProductIds[] = $fixedProductId;

            $this->assertEquals(3, $successResponse->json('data.total_quantity'));
            $this->assertEquals(3, $successResponse->json('data.available_quantity'));
            $this->assertEquals('PENDING_REVIEW', $successResponse->json('data.status'));

            // 3. Create AUCTION listing requesting quantity 5 -> must enforce single quantity (1) (BR-PR-01)
            $auctionResponse = $this->withHeader('Authorization', "Bearer {$token}")
                ->postJson('/api/v1/seller/products', [
                    'category_id' => $category->id,
                    'title' => 'Đồng Hồ Quả Quýt Cổ Điển Mạ Bạc Sưu Tầm',
                    'description' => 'Cơ chế lên dây cót tay nguyên bản',
                    'condition' => 'VINTAGE_WORN',
                    'defect_info' => 'Mặt kính có xước nhẹ do tuổi đời trên 50 năm',
                    'listing_type' => 'AUCTION',
                    'price' => 800000,
                    'total_quantity' => 5, // Requesting 5
                    'submit_for_review' => false,
                ]);
            $auctionResponse->assertStatus(201);
            $auctionProductId = $auctionResponse->json('data.id');
            $createdProductIds[] = $auctionProductId;

            $this->assertEquals(1, $auctionResponse->json('data.total_quantity'));
            $this->assertEquals(1, $auctionResponse->json('data.available_quantity'));
            $this->assertEquals('DRAFT', $auctionResponse->json('data.status'));
        } finally {
            $seller->tokens()->delete();
            foreach ($createdProductIds as $id) {
                DB::table('product_images')->where('product_id', $id)->delete();
                DB::table('product_moderation_logs')->where('product_id', $id)->delete();
                DB::table('products')->where('id', $id)->delete();
            }
        }
    }

    /**
     * 5. Test moderator approves and rejects product enforcing mandatory reason DEC-05 and notifies seller.
     */
    public function test_moderator_approves_and_rejects_product_enforcing_mandatory_reason_dec05_and_notifies_seller(): void
    {
        $moderator = User::where('email', 'moderator@izithrift.local')->firstOrFail();
        $seller = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();
        $category = Category::firstOrFail();

        $product = Product::create([
            'product_code' => 'PRD-MOD-TEST-' . time(),
            'seller_id' => $seller->id,
            'category_id' => $category->id,
            'title' => 'Sản phẩm thử nghiệm kiểm duyệt',
            'slug' => 'san-pham-thu-nghiem-kiem-duyet-' . time(),
            'description' => 'Mô tả chi tiết sản phẩm thử nghiệm kiểm duyệt',
            'condition' => 'GOOD',
            'defect_info' => 'Sờn nhẹ vải lót trong',
            'listing_type' => 'FIXED_PRICE',
            'price' => 200000,
            'total_quantity' => 1,
            'available_quantity' => 1,
            'status' => 'PENDING_REVIEW',
        ]);

        /** @var ProductModerationService $service */
        $service = app(ProductModerationService::class);

        try {
            // 1. Moderator rejects with empty reason -> throws ValidationException (DEC-05)
            try {
                $service->rejectOrHideProduct($moderator, $product, 'REJECTED', '   ');
                $this->fail('Expected ValidationException was not thrown for empty rejection reason.');
            } catch (ValidationException $e) {
                $this->assertArrayHasKey('reason', $e->errors());
            }

            // 2. Moderator rejects with valid non-empty reason
            $rejectReason = 'Ảnh chụp góc tem mác bị lóa đèn, vui lòng bổ sung ảnh chụp tự nhiên.';
            $rejectedProduct = $service->rejectOrHideProduct($moderator, $product, 'REJECTED', $rejectReason);
            $this->assertEquals(ProductStatus::REJECTED, $rejectedProduct->status);
            $this->assertEquals($rejectReason, $rejectedProduct->rejection_reason);

            // Verify notification sent to seller
            $rejectNotification = Notification::where('user_id', $seller->id)
                ->where('type', 'PRODUCT_REJECTED')
                ->where('target_id', $product->id)
                ->latest('id')
                ->first();
            $this->assertNotNull($rejectNotification);
            $this->assertStringContainsString($rejectReason, $rejectNotification->body);

            // 3. Moderator approves product
            $approvedProduct = $service->approveProduct(
                $moderator,
                $rejectedProduct,
                'MODERATOR_REVIEWED',
                'Sản phẩm đã được kiểm tra đạt chuẩn vintage'
            );
            $this->assertEquals(ProductStatus::APPROVED, $approvedProduct->status);
            $this->assertEquals('MODERATOR_REVIEWED', $approvedProduct->verification_level);
            $this->assertNotNull($approvedProduct->approved_at);
            $this->assertEquals($moderator->id, $approvedProduct->approved_by);
            $this->assertNull($approvedProduct->rejection_reason);

            // Verify notification sent to seller
            $approveNotification = Notification::where('user_id', $seller->id)
                ->where('type', 'PRODUCT_APPROVED')
                ->where('target_id', $product->id)
                ->latest('id')
                ->first();
            $this->assertNotNull($approveNotification);
        } finally {
            Notification::where('target_type', 'products')->where('target_id', $product->id)->delete();
            DB::table('audit_logs')->where('target_type', 'products')->where('target_id', (string) $product->id)->delete();
            DB::table('product_moderation_logs')->where('product_id', $product->id)->delete();
            $product->delete();
        }
    }

    /**
     * 6. Test regular user or support cannot moderate products returns 403.
     */
    public function test_regular_user_or_support_cannot_moderate_products_returns_403(): void
    {
        $buyer = User::where('email', 'buyer.linh@izithrift.local')->firstOrFail();
        $support = User::where('email', 'support@izithrift.local')->firstOrFail();
        $seller = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();
        $category = Category::firstOrFail();

        $product = Product::create([
            'product_code' => 'PRD-PERM-TEST-' . time(),
            'seller_id' => $seller->id,
            'category_id' => $category->id,
            'title' => 'Sản phẩm thử nghiệm phân quyền kiểm duyệt',
            'slug' => 'san-pham-thu-nghiem-phan-quyen-' . time(),
            'description' => 'Mô tả chi tiết thử nghiệm phân quyền',
            'condition' => 'GOOD',
            'defect_info' => 'Không lỗi',
            'listing_type' => 'FIXED_PRICE',
            'price' => 100000,
            'total_quantity' => 1,
            'available_quantity' => 1,
            'status' => 'PENDING_REVIEW',
        ]);

        /** @var ProductModerationService $service */
        $service = app(ProductModerationService::class);

        try {
            // Buyer attempts approval -> RolePermissionDeniedException (403)
            try {
                $service->approveProduct($buyer, $product);
                $this->fail('Regular buyer should not be permitted to approve products.');
            } catch (RolePermissionDeniedException $e) {
                $this->assertEquals(403, $e->getHttpStatus());
            }

            // Support staff attempts rejection -> RolePermissionDeniedException (403)
            try {
                $service->rejectOrHideProduct($support, $product, 'REJECTED', 'Lý do từ chối');
                $this->fail('Support staff should not be permitted to reject products.');
            } catch (RolePermissionDeniedException $e) {
                $this->assertEquals(403, $e->getHttpStatus());
            }
        } finally {
            $product->delete();
        }
    }

    /**
     * 7. Test seller resubmits rejected product clears rejection reason and transitions to pending review (DEC-05 / M-SL-04).
     */
    public function test_seller_resubmits_rejected_product_clears_rejection_reason_and_transitions_to_pending_review(): void
    {
        $seller = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();
        $category = Category::firstOrFail();
        $token = $seller->createToken('resubmit_test')->plainTextToken;

        $product = Product::create([
            'product_code' => 'PRD-RESUBMIT-' . time(),
            'seller_id' => $seller->id,
            'category_id' => $category->id,
            'title' => 'Sản phẩm ban đầu bị từ chối duyệt',
            'slug' => 'san-pham-ban-dau-bi-tu-choi-' . time(),
            'description' => 'Mô tả ban đầu trước khi duyệt lại',
            'condition' => 'GOOD',
            'defect_info' => 'Chưa mô tả khuyết điểm',
            'listing_type' => 'FIXED_PRICE',
            'price' => 300000,
            'total_quantity' => 1,
            'available_quantity' => 1,
            'status' => 'REJECTED',
            'rejection_reason' => 'Cần bổ sung mô tả khuyết điểm chi tiết (DEC-05)',
        ]);

        try {
            $response = $this->withHeader('Authorization', "Bearer {$token}")
                ->putJson("/api/v1/seller/products/{$product->id}", [
                    'title' => 'Sản phẩm đã cập nhật bổ sung khuyết điểm',
                    'defect_info' => 'Đã bổ sung chi tiết: sờn vải 1cm ở gấu áo',
                    'submit_for_review' => true,
                ]);

            $response->assertStatus(200);

            $product->refresh();
            $this->assertEquals(ProductStatus::PENDING_REVIEW, $product->status);
            $this->assertNull($product->rejection_reason);

            // Verify moderation log recorded SUBMITTED action
            $log = ProductModerationLog::where('product_id', $product->id)
                ->where('action', 'SUBMITTED')
                ->first();
            $this->assertNotNull($log);
            $this->assertEquals('PENDING_REVIEW', $log->new_status);
        } finally {
            $seller->tokens()->delete();
            DB::table('product_moderation_logs')->where('product_id', $product->id)->delete();
            $product->delete();
        }
    }

    /**
     * 8. Test seller cannot update product locked by sold status or live auction with bids returns 409 (BR-PR-05).
     */
    public function test_seller_cannot_update_product_locked_by_active_order_or_live_auction_with_bids_returns_409(): void
    {
        $seller = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();
        $category = Category::firstOrFail();
        $token = $seller->createToken('locked_product_test')->plainTextToken;

        // 1. Product with SOLD status
        $soldProduct = Product::create([
            'product_code' => 'PRD-SOLD-' . time(),
            'seller_id' => $seller->id,
            'category_id' => $category->id,
            'title' => 'Sản phẩm đã bán thành công',
            'slug' => 'san-pham-da-ban-' . time(),
            'description' => 'Mô tả sản phẩm đã bán thành công',
            'condition' => 'LIKE_NEW',
            'defect_info' => 'Không lỗi',
            'listing_type' => 'FIXED_PRICE',
            'price' => 500000,
            'total_quantity' => 1,
            'available_quantity' => 0,
            'status' => 'SOLD',
        ]);

        // 2. Product in live auction with bids
        $auctionProduct = Product::create([
            'product_code' => 'PRD-LIVE-AUC-' . time(),
            'seller_id' => $seller->id,
            'category_id' => $category->id,
            'title' => 'Sản phẩm đấu giá trực tiếp có lượt đặt giá',
            'slug' => 'san-pham-dau-gia-truc-tiep-' . time(),
            'description' => 'Mô tả sản phẩm đấu giá trực tiếp',
            'condition' => 'LIKE_NEW',
            'defect_info' => 'Không lỗi',
            'listing_type' => 'AUCTION',
            'price' => 1000000,
            'total_quantity' => 1,
            'available_quantity' => 1,
            'status' => 'APPROVED',
        ]);

        $session = AuctionSession::firstOrFail();
        $auction = Auction::create([
            'auction_code' => 'AUC-TEST-' . time(),
            'session_id' => $session->id,
            'seller_id' => $seller->id,
            'product_id' => $auctionProduct->id,
            'starting_price' => 1000000,
            'current_highest_bid' => 1200000,
            'bid_count' => 3,
            'min_bid_increment' => 50000,
            'auction_starts_at' => now()->subHour(),
            'auction_ends_at' => now()->addHours(2),
            'original_ends_at' => now()->addHours(2),
            'status' => 'LIVE',
        ]);

        try {
            // Attempt to update SOLD product -> 409
            $soldResponse = $this->withHeader('Authorization', "Bearer {$token}")
                ->putJson("/api/v1/seller/products/{$soldProduct->id}", [
                    'title' => 'Cố gắng sửa sản phẩm đã bán',
                ]);
            $soldResponse->assertStatus(409);
            $this->assertEquals('INVALID_STATE_TRANSITION', $soldResponse->json('error_code'));

            // Attempt to update product with live auction bids -> 409
            $auctionResponse = $this->withHeader('Authorization', "Bearer {$token}")
                ->putJson("/api/v1/seller/products/{$auctionProduct->id}", [
                    'title' => 'Cố gắng sửa sản phẩm đấu giá đang diễn ra',
                ]);
            $auctionResponse->assertStatus(409);
            $this->assertEquals('INVALID_STATE_TRANSITION', $auctionResponse->json('error_code'));
        } finally {
            $seller->tokens()->delete();
            $auction->delete();
            $auctionProduct->delete();
            $soldProduct->delete();
        }
    }
}
