<?php

namespace App\Services\Order;

use App\Enums\DisputeStatus;
use App\Enums\EscrowStatus;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Enums\ProductStatus;
use App\Exceptions\InvalidStateTransitionException;
use App\Exceptions\ProductOutOfStockException;
use App\Exceptions\RolePermissionDeniedException;
use App\Exceptions\SelfTransactionForbiddenException;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\Product;
use App\Models\User;
use App\Models\UserAddress;
use App\Services\Governance\PlatformConfigService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class CheckoutService
{
    public function __construct(
        protected PlatformConfigService $platformConfig
    ) {}

    /**
     * Preview checkout breakdown enforcing DEC-04 Buyer Protection Fee calculation (M-OR-01).
     * Never trusts client-provided prices or fee totals (NFR-SEC-03).
     *
     * @throws ValidationException
     * @throws SelfTransactionForbiddenException
     * @throws InvalidStateTransitionException
     * @throws ProductOutOfStockException
     */
    public function previewCheckout(User $buyer, array $payload): array
    {
        $source = strtoupper($payload['source'] ?? 'CART');

        // 1. Resolve Address
        $address = null;
        if (! empty($payload['address_id'])) {
            $address = UserAddress::where('id', $payload['address_id'])
                ->where('user_id', $buyer->id)
                ->first();
        }
        if (! $address) {
            $address = $buyer->addresses()->where('is_default', true)->first()
                ?? $buyer->addresses()->first();
        }

        // 2. Resolve Items
        $itemsToCheckout = [];
        if ($source === 'BUY_NOW') {
            $productId = (int) ($payload['product_id'] ?? 0);
            $qty = max(1, (int) ($payload['quantity'] ?? 1));

            $product = Product::with(['primaryImage', 'seller.sellerProfile'])->findOrFail($productId);

            if ($product->seller_id === $buyer->id) {
                throw new SelfTransactionForbiddenException('Bạn không thể tự mua sản phẩm của chính mình (BR-AC-02).');
            }

            $productStatus = $product->status instanceof ProductStatus ? $product->status->value : (string) $product->status;
            if ($product->listing_type !== 'FIXED_PRICE' || $productStatus !== 'APPROVED') {
                throw new InvalidStateTransitionException("Sản phẩm '{$product->title}' không khả dụng để mua ngay.");
            }

            if ($product->available_quantity < $qty) {
                throw new ProductOutOfStockException("Sản phẩm '{$product->title}' không đủ tồn kho (Còn lại: {$product->available_quantity}).");
            }

            $itemsToCheckout[] = [
                'product' => $product,
                'quantity' => $qty,
                'seller_id' => $product->seller_id,
            ];
        } else {
            // Source is CART
            $cart = Cart::firstOrCreate(['user_id' => $buyer->id]);
            $cartQuery = CartItem::where('cart_id', $cart->id)
                ->where('is_selected', true)
                ->with(['product.primaryImage', 'seller.sellerProfile']);

            if (! empty($payload['seller_id'])) {
                $cartQuery->where('seller_id', $payload['seller_id']);
            }

            $cartItems = $cartQuery->get();
            if ($cartItems->isEmpty()) {
                throw ValidationException::withMessages([
                    'items' => ['Giỏ hàng không có sản phẩm nào được chọn để thanh toán.'],
                ]);
            }

            foreach ($cartItems as $ci) {
                $p = $ci->product;
                if ($p->seller_id === $buyer->id) {
                    throw new SelfTransactionForbiddenException("Bạn không thể tự mua sản phẩm '{$p->title}' của chính mình (BR-AC-02).");
                }
                $itemsToCheckout[] = [
                    'product' => $p,
                    'quantity' => $ci->quantity,
                    'seller_id' => $p->seller_id,
                ];
            }
        }

        // 3. Group by Seller (BR-OR-01) & Calculate DEC-04 Fees
        $sellerGroups = [];
        $grandSubtotal = 0.0;
        $grandProtectionFee = 0.0;
        $grandTotal = 0.0;
        $totalItemsCount = 0;

        $bySeller = [];
        foreach ($itemsToCheckout as $item) {
            $bySeller[$item['seller_id']][] = $item;
        }

        foreach ($bySeller as $sellerId => $sellerItems) {
            $seller = $sellerItems[0]['product']->seller;
            $itemSubtotal = 0.0;
            $formattedItems = [];

            foreach ($sellerItems as $si) {
                $p = $si['product'];
                $qty = $si['quantity'];
                $lineTotal = round((float) $p->price * $qty, 2);
                $itemSubtotal = round($itemSubtotal + $lineTotal, 2);
                $totalItemsCount += $qty;

                $formattedItems[] = [
                    'product_id' => $p->id,
                    'product_code' => $p->product_code,
                    'title' => $p->title,
                    'condition' => $p->condition?->value ?? (string) $p->condition,
                    'unit_price' => (float) $p->price,
                    'quantity' => $qty,
                    'line_total' => $lineTotal,
                    'primary_image_url' => $p->primaryImage?->image_url,
                ];
            }

            $feeBreakdown = $this->platformConfig->calculateBuyerProtectionFee($itemSubtotal);
            $groupTotal = (float) $feeBreakdown['total_amount'];
            $groupFee = (float) $feeBreakdown['buyer_protection_fee'];

            $sellerGroups[] = [
                'seller' => [
                    'id' => $seller->id,
                    'display_name' => $seller->display_name,
                    'shop_slug' => $seller->sellerProfile?->shop_slug,
                    'avatar_url' => $seller->profile?->avatar_url,
                    'trust_score' => (float) ($seller->sellerProfile?->trust_score ?? 100.0),
                ],
                'items' => $formattedItems,
                'item_subtotal' => (float) $feeBreakdown['item_subtotal'],
                'shipping_fee' => (float) $feeBreakdown['shipping_fee'],
                'protection_fee_rate' => (float) $feeBreakdown['protection_fee_rate'],
                'protection_fixed_fee' => (float) $feeBreakdown['protection_fixed_fee'],
                'buyer_protection_fee' => $groupFee,
                'total_amount' => $groupTotal,
                'seller_net_amount' => (float) $feeBreakdown['seller_net_amount'],
            ];

            $grandSubtotal = round($grandSubtotal + $itemSubtotal, 2);
            $grandProtectionFee = round($grandProtectionFee + $groupFee, 2);
            $grandTotal = round($grandTotal + $groupTotal, 2);
        }

        return [
            'source' => $source,
            'shipping_address' => $address ? [
                'id' => $address->id,
                'recipient_name' => $address->recipient_name,
                'recipient_phone' => $address->recipient_phone,
                'province_city' => $address->province_city,
                'district_ward' => $address->district_ward,
                'street_address' => $address->street_address,
                'full_address' => trim("{$address->street_address}, {$address->district_ward}, {$address->province_city}"),
            ] : null,
            'seller_groups' => $sellerGroups,
            'summary' => [
                'sellers_count' => count($sellerGroups),
                'items_count' => $totalItemsCount,
                'item_subtotal' => $grandSubtotal,
                'shipping_fee' => 0.0,
                'buyer_protection_fee' => $grandProtectionFee,
                'grand_total' => $grandTotal,
            ],
        ];
    }

    /**
     * Place order with pessimistic row-locking on products (OF-02 / BR-OR-01 / BR-OR-02).
     *
     * @throws ValidationException
     * @throws RolePermissionDeniedException
     * @throws SelfTransactionForbiddenException
     * @throws InvalidStateTransitionException
     * @throws ProductOutOfStockException
     */
    public function placeOrder(User $buyer, array $payload): array
    {
        return DB::transaction(function () use ($buyer, $payload) {
            $source = strtoupper($payload['source'] ?? 'CART');

            // 1. Validate & Snapshot Shipping Address (BR-OR-02)
            $address = null;
            if (! empty($payload['address_id'])) {
                $address = UserAddress::find($payload['address_id']);
                if (! $address) {
                    throw ValidationException::withMessages([
                        'address_id' => ['Địa chỉ nhận hàng đã chọn không tồn tại.'],
                    ]);
                }
                if ($address->user_id !== $buyer->id) {
                    throw new RolePermissionDeniedException('Bạn không có quyền sử dụng địa chỉ nhận hàng của tài khoản khác.');
                }
            } else {
                $address = $buyer->addresses()->where('is_default', true)->first()
                    ?? $buyer->addresses()->first();
                if (! $address) {
                    throw ValidationException::withMessages([
                        'address_id' => ['Vui lòng thêm ít nhất một địa chỉ nhận hàng trước khi tiến hành đặt đơn.'],
                    ]);
                }
            }

            $shippingSnapshot = [
                'recipient_name' => $address->recipient_name,
                'recipient_phone' => $address->recipient_phone,
                'province_city' => $address->province_city,
                'district_ward' => $address->district_ward,
                'street_address' => $address->street_address,
                'full_address' => trim("{$address->street_address}, {$address->district_ward}, {$address->province_city}"),
            ];

            // 2. Gather Requested Items
            $requestedQuantities = [];
            $cart = null;

            if ($source === 'BUY_NOW') {
                $pid = (int) ($payload['product_id'] ?? 0);
                $qty = max(1, (int) ($payload['quantity'] ?? 1));
                $requestedQuantities[$pid] = $qty;
            } else {
                $cart = Cart::firstOrCreate(['user_id' => $buyer->id]);
                $cartQuery = CartItem::where('cart_id', $cart->id)->where('is_selected', true);
                if (! empty($payload['seller_id'])) {
                    $cartQuery->where('seller_id', $payload['seller_id']);
                }
                $cartItems = $cartQuery->get();

                if ($cartItems->isEmpty()) {
                    throw ValidationException::withMessages([
                        'items' => ['Giỏ hàng không có sản phẩm nào được chọn để thanh toán.'],
                    ]);
                }

                foreach ($cartItems as $ci) {
                    $requestedQuantities[$ci->product_id] = $ci->quantity;
                }
            }

            // 3. Pessimistic Row Lock Ordered by Product ID ASC to prevent Deadlocks (OF-02)
            $productIds = array_keys($requestedQuantities);
            sort($productIds);

            /** @var \Illuminate\Database\Eloquent\Collection<int, Product> $products */
            $products = Product::whereIn('id', $productIds)
                ->orderBy('id', 'asc')
                ->lockForUpdate()
                ->get()
                ->keyBy('id');

            // 4. Verify Stock & Business Invariants
            foreach ($requestedQuantities as $pid => $qty) {
                /** @var Product|null $product */
                $product = $products->get($pid);
                if (! $product) {
                    throw new ProductOutOfStockException("Sản phẩm ID #{$pid} không tồn tại.");
                }

                // BR-AC-02: Self transaction forbidden
                if ($product->seller_id === $buyer->id) {
                    throw new SelfTransactionForbiddenException("Bạn không thể tự mua sản phẩm '{$product->title}' của chính mình (BR-AC-02).");
                }

                $status = $product->status instanceof ProductStatus ? $product->status->value : (string) $product->status;
                if ($product->listing_type !== 'FIXED_PRICE' || $status !== 'APPROVED') {
                    throw new InvalidStateTransitionException("Sản phẩm '{$product->title}' không còn khả dụng để đặt mua.");
                }

                if ($product->available_quantity < $qty) {
                    throw new ProductOutOfStockException("Sản phẩm '{$product->title}' không đủ tồn kho (Còn lại: {$product->available_quantity}, Yêu cầu: {$qty}).");
                }
            }

            // 5. Decrement Stock & Update Status if Sold Out
            foreach ($requestedQuantities as $pid => $qty) {
                $product = $products->get($pid);
                $newAvailable = $product->available_quantity - $qty;
                $product->available_quantity = $newAvailable;
                if ($newAvailable === 0) {
                    $product->status = ProductStatus::SOLD;
                }
                $product->save();
            }

            // 6. Group by Seller & Create Orders + OrderItems + QR Payments
            $paymentExpiresAt = now()->addMinutes($this->platformConfig->auctionWinnerPaymentDeadlineMinutes());

            $bySeller = [];
            foreach ($requestedQuantities as $pid => $qty) {
                $p = $products->get($pid);
                $bySeller[$p->seller_id][] = ['product' => $p, 'quantity' => $qty];
            }

            $createdOrders = [];
            $createdPayments = [];

            foreach ($bySeller as $sellerId => $sellerItems) {
                $itemSubtotal = 0.0;
                foreach ($sellerItems as $si) {
                    $itemSubtotal = round($itemSubtotal + ((float) $si['product']->price * $si['quantity']), 2);
                }

                $fees = $this->platformConfig->calculateBuyerProtectionFee($itemSubtotal);
                $orderCode = 'ORD-2026-' . strtoupper(Str::random(8));

                $order = Order::create([
                    'order_code' => $orderCode,
                    'buyer_id' => $buyer->id,
                    'seller_id' => $sellerId,
                    'order_source' => 'FIXED_PRICE',
                    'item_subtotal' => (float) $fees['item_subtotal'],
                    'shipping_fee' => 0.00,
                    'protection_fee_rate_applied' => (float) $fees['protection_fee_rate'],
                    'protection_fixed_fee_applied' => (float) $fees['protection_fixed_fee'],
                    'buyer_protection_fee' => (float) $fees['buyer_protection_fee'],
                    'total_amount' => (float) $fees['total_amount'],
                    'seller_net_amount' => (float) $fees['seller_net_amount'],
                    'shipping_address_snapshot' => $shippingSnapshot,
                    'order_status' => OrderStatus::PENDING_PAYMENT,
                    'payment_status' => PaymentStatus::UNPAID,
                    'escrow_status' => EscrowStatus::NONE,
                    'dispute_status' => DisputeStatus::NONE,
                    'payment_expires_at' => $paymentExpiresAt,
                ]);

                foreach ($sellerItems as $si) {
                    $p = $si['product'];
                    $qty = $si['quantity'];
                    $lineTotal = round((float) $p->price * $qty, 2);

                    OrderItem::create([
                        'order_id' => $order->id,
                        'product_id' => $p->id,
                        'product_code_snapshot' => $p->product_code,
                        'product_title_snapshot' => $p->title,
                        'condition_snapshot' => $p->condition?->value ?? (string) $p->condition,
                        'defect_info_snapshot' => $p->defect_info,
                        'primary_image_snapshot' => $p->primaryImage?->image_url ?? '',
                        'unit_price_snapshot' => (float) $p->price,
                        'quantity' => $qty,
                        'line_total' => $lineTotal,
                    ]);
                }

                $paymentRef = 'PAY-2026-' . strtoupper(Str::random(8));
                $qrPayload = "IZITHRIFT_QR|{$order->order_code}|{$order->total_amount}";

                $payment = Payment::create([
                    'payment_reference' => $paymentRef,
                    'order_id' => $order->id,
                    'payer_id' => $buyer->id,
                    'amount' => (float) $order->total_amount,
                    'qr_payload' => $qrPayload,
                    'status' => PaymentStatus::PENDING,
                    'expires_at' => $paymentExpiresAt,
                ]);

                $createdOrders[] = $order->load(['items', 'seller.sellerProfile', 'payments']);
                $createdPayments[] = $payment;
            }

            // 7. Remove purchased items from cart if source was CART
            if ($source === 'CART' && $cart) {
                CartItem::where('cart_id', $cart->id)
                    ->whereIn('product_id', array_keys($requestedQuantities))
                    ->delete();
            }

            return [
                'order' => $createdOrders[0],
                'payment' => $createdPayments[0],
                'orders' => $createdOrders,
            ];
        });
    }
}
