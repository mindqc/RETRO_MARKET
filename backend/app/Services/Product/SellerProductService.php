<?php

namespace App\Services\Product;

use App\Enums\OrderStatus;
use App\Enums\ProductStatus;
use App\Exceptions\InvalidStateTransitionException;
use App\Exceptions\RolePermissionDeniedException;
use App\Models\Auction;
use App\Models\AuctionSession;
use App\Models\Order;
use App\Models\Product;
use App\Models\ProductImage;
use App\Models\ProductModerationLog;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class SellerProductService
{
    /**
     * Get seller dashboard metrics and action item counters (M-SL-01).
     */
    public function getSellerDashboardMetrics(User $seller): array
    {
        $sellerProfile = $seller->sellerProfile;

        // Action Counters
        $ordersPendingShipment = Order::query()
            ->where('seller_id', $seller->id)
            ->where('order_status', OrderStatus::PAID)
            ->count();

        $cancellationRequests = Order::query()
            ->where('seller_id', $seller->id)
            ->where('order_status', OrderStatus::PREPARING)
            ->where('cancellation_requested', true)
            ->count();

        $openDisputes = Order::query()
            ->where('seller_id', $seller->id)
            ->where('dispute_status', 'OPEN')
            ->count();

        $productsPendingReview = Product::query()
            ->where('seller_id', $seller->id)
            ->where('status', ProductStatus::PENDING_REVIEW)
            ->count();

        $productsRejected = Product::query()
            ->where('seller_id', $seller->id)
            ->where('status', ProductStatus::REJECTED)
            ->count();

        $productsApproved = Product::query()
            ->where('seller_id', $seller->id)
            ->where('status', ProductStatus::APPROVED)
            ->count();

        $productsSold = Product::query()
            ->where('seller_id', $seller->id)
            ->where('status', ProductStatus::SOLD)
            ->count();

        return [
            'wallet_balance' => (float) ($sellerProfile?->wallet_balance ?? 0.0),
            'escrow_held_balance' => (float) ($sellerProfile?->escrow_held_balance ?? 0.0),
            'trust_score' => (float) ($sellerProfile?->trust_score ?? 100.0),
            'average_rating' => (float) ($sellerProfile?->average_rating ?? 0.0),
            'review_count' => (int) ($sellerProfile?->review_count ?? 0),
            'completed_orders_count' => (int) ($sellerProfile?->completed_orders_count ?? 0),
            'action_counters' => [
                'orders_pending_shipment' => $ordersPendingShipment,
                'cancellation_requests' => $cancellationRequests,
                'open_disputes' => $openDisputes,
                'products_pending_review' => $productsPendingReview,
                'products_rejected' => $productsRejected,
                'products_approved' => $productsApproved,
                'products_sold' => $productsSold,
            ],
        ];
    }

    /**
     * List all products belonging to seller with status filter (M-SL-02).
     */
    public function listSellerProducts(User $seller, array $filters = [], int $perPage = 12): LengthAwarePaginator
    {
        $query = Product::query()
            ->where('seller_id', $seller->id)
            ->with(['primaryImage', 'category', 'brand']);

        if (! empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        if (! empty($filters['listing_type'])) {
            $query->where('listing_type', strtoupper($filters['listing_type']));
        }

        return $query->latest('id')->paginate($perPage);
    }

    /**
     * Create a new product listing (M-SL-03 / BR-PR-01 / BR-PR-03).
     */
    public function createListing(User $seller, array $data, array $uploadedImages = []): Product
    {
        return DB::transaction(function () use ($seller, $data, $uploadedImages) {
            $isAuction = ($data['listing_type'] ?? 'FIXED_PRICE') === 'AUCTION';

            // Enforce BR-PR-01: Auction listings are strictly single quantity (1)
            $totalQuantity = $isAuction ? 1 : (int) ($data['total_quantity'] ?? 1);
            $availableQuantity = $totalQuantity;

            // Determine initial status: PENDING_REVIEW or DRAFT
            $isSubmit = ! empty($data['submit_for_review']);
            $status = $isSubmit ? ProductStatus::PENDING_REVIEW : ProductStatus::DRAFT;

            $productCode = 'PRD-' . date('Y') . '-' . strtoupper(Str::random(6));
            $slug = Str::slug($data['title']) . '-' . strtolower(Str::random(5));

            $product = Product::create([
                'product_code' => $productCode,
                'seller_id' => $seller->id,
                'category_id' => $data['category_id'],
                'brand_id' => $data['brand_id'] ?? null,
                'title' => trim($data['title']),
                'slug' => $slug,
                'description' => trim($data['description'] ?? '') ?: 'Mô tả chi tiết sản phẩm vintage.',
                'condition' => $data['condition'],
                'defect_info' => trim($data['defect_info']),
                'listing_type' => $data['listing_type'],
                'price' => (float) $data['price'],
                'total_quantity' => $totalQuantity,
                'available_quantity' => $availableQuantity,
                'verification_level' => 'UNVERIFIED',
                'status' => $status,
            ]);

            // Save Images (UploadedFile[] or image_urls array)
            $this->storeProductImages($product, $uploadedImages, $data['image_urls'] ?? []);

            // If submitted for review immediately, create log
            if ($status === ProductStatus::PENDING_REVIEW) {
                ProductModerationLog::create([
                    'product_id' => $product->id,
                    'moderator_id' => $seller->id,
                    'action' => 'SUBMITTED',
                    'previous_status' => 'DRAFT',
                    'new_status' => 'PENDING_REVIEW',
                    'reason' => 'Người bán gửi bài đăng kiểm duyệt lần đầu.',
                ]);
            }

            // If AUCTION and session details provided, create Auction record
            if ($isAuction && ! empty($data['session_id'])) {
                $session = AuctionSession::findOrFail($data['session_id']);
                Auction::create([
                    'session_id' => $session->id,
                    'seller_id' => $seller->id,
                    'product_id' => $product->id,
                    'starting_price' => (float) ($data['starting_price'] ?? $data['price']),
                    'reserve_price' => isset($data['reserve_price']) ? (float) $data['reserve_price'] : null,
                    'min_bid_increment' => (float) ($data['min_bid_increment'] ?? 10000.0),
                    'buy_now_price' => isset($data['buy_now_price']) ? (float) $data['buy_now_price'] : null,
                    'auction_starts_at' => $session->starts_at,
                    'auction_ends_at' => $session->ends_at,
                    'original_ends_at' => $session->ends_at,
                    'status' => 'SCHEDULED',
                ]);
            }

            return $product->load(['images', 'primaryImage', 'category', 'brand']);
        });
    }

    /**
     * Update listing or resubmit a rejected listing (M-SL-04 / BR-PR-05 / DEC-05).
     *
     * @throws RolePermissionDeniedException
     * @throws InvalidStateTransitionException
     */
    public function updateOrResubmitListing(User $seller, Product $product, array $data, array $uploadedImages = []): Product
    {
        if ($product->seller_id !== $seller->id) {
            throw new RolePermissionDeniedException('Bạn không có quyền chỉnh sửa bài đăng này.');
        }

        // BR-PR-05: Lock editing if sold, in active order, or live auction with bids
        $productStatus = $product->status instanceof ProductStatus ? $product->status->value : (string) $product->status;
        if ($productStatus === 'SOLD') {
            throw new InvalidStateTransitionException('Không thể chỉnh sửa sản phẩm đã bán thành công (BR-PR-05).');
        }

        $hasActiveOrders = $product->orderItems()->whereHas('order', function ($query) {
            $query->whereIn('order_status', ['PENDING_PAYMENT', 'PAID', 'PREPARING', 'SHIPPED', 'DELIVERED']);
        })->exists();

        if ($hasActiveOrders) {
            throw new InvalidStateTransitionException('Không thể chỉnh sửa sản phẩm đang có đơn hàng đang xử lý hoặc giao hàng (BR-PR-05).');
        }

        $hasLiveAuctionWithBids = $product->auctions()
            ->where('status', 'LIVE')
            ->where('bid_count', '>', 0)
            ->exists();

        if ($hasLiveAuctionWithBids) {
            throw new InvalidStateTransitionException('Không thể chỉnh sửa sản phẩm trong phiên đấu giá trực tiếp đã có người đặt giá (BR-PR-05).');
        }

        return DB::transaction(function () use ($seller, $product, $data, $uploadedImages, $productStatus) {
            // Update Core Fields
            if (isset($data['title'])) {
                $product->title = trim($data['title']);
            }
            if (isset($data['category_id'])) {
                $product->category_id = $data['category_id'];
            }
            if (array_key_exists('brand_id', $data)) {
                $product->brand_id = $data['brand_id'];
            }
            if (isset($data['description'])) {
                $product->description = $data['description'];
            }
            if (isset($data['condition'])) {
                $product->condition = $data['condition'];
            }
            if (isset($data['defect_info'])) {
                $product->defect_info = trim($data['defect_info']);
            }
            if (isset($data['price'])) {
                $product->price = (float) $data['price'];
            }

            if ($product->listing_type === 'AUCTION') {
                $product->total_quantity = 1;
                $product->available_quantity = 1;
            } elseif (isset($data['total_quantity'])) {
                $product->total_quantity = (int) $data['total_quantity'];
                $product->available_quantity = (int) $data['total_quantity'];
            }

            // Save new images if provided
            if (! empty($uploadedImages) || ! empty($data['image_urls'])) {
                $this->storeProductImages($product, $uploadedImages, $data['image_urls'] ?? []);
            }

            // DEC-05: Resubmit flow if requested
            if (! empty($data['submit_for_review'])) {
                $product->status = ProductStatus::PENDING_REVIEW;
                $product->rejection_reason = null; // Clear rejection reason upon resubmit

                ProductModerationLog::create([
                    'product_id' => $product->id,
                    'moderator_id' => $seller->id,
                    'action' => 'SUBMITTED',
                    'previous_status' => $productStatus,
                    'new_status' => 'PENDING_REVIEW',
                    'reason' => 'Người bán chỉnh sửa và gửi duyệt lại bài đăng.',
                ]);
            }

            $product->save();

            return $product->fresh(['images', 'primaryImage', 'category', 'brand']);
        });
    }

    /**
     * Change product status by seller (HIDDEN, ARCHIVED).
     */
    public function changeSellerListingStatus(User $seller, Product $product, string $targetStatus): Product
    {
        if ($product->seller_id !== $seller->id) {
            throw new RolePermissionDeniedException('Bạn không có quyền thay đổi trạng thái sản phẩm này.');
        }

        $targetEnum = ProductStatus::from($targetStatus);

        $product->update([
            'status' => $targetEnum,
        ]);

        return $product->fresh();
    }

    /**
     * Helper to store product images into database and local storage disk.
     */
    protected function storeProductImages(Product $product, array $uploadedImages, array $imageUrls = []): void
    {
        $order = (int) $product->images()->max('sort_order');
        $hasPrimary = $product->images()->where('is_primary', true)->exists();

        // 1. Process Uploaded Files
        foreach ($uploadedImages as $index => $file) {
            if ($file instanceof UploadedFile) {
                $path = $file->store("products/{$product->id}", 'public');
                $url = Storage::disk('public')->url($path);

                ProductImage::create([
                    'product_id' => $product->id,
                    'image_url' => $url,
                    'image_type' => 'GALLERY',
                    'is_primary' => (! $hasPrimary && $index === 0),
                    'sort_order' => ++$order,
                    'file_size_bytes' => $file->getSize(),
                ]);

                if (! $hasPrimary && $index === 0) {
                    $hasPrimary = true;
                }
            }
        }

        // 2. Process Direct Image URLs
        foreach ($imageUrls as $index => $url) {
            ProductImage::create([
                'product_id' => $product->id,
                'image_url' => $url,
                'image_type' => 'GALLERY',
                'is_primary' => (! $hasPrimary && $index === 0),
                'sort_order' => ++$order,
                'file_size_bytes' => 1024,
            ]);

            if (! $hasPrimary && $index === 0) {
                $hasPrimary = true;
            }
        }
    }
}
