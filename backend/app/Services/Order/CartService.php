<?php

namespace App\Services\Order;

use App\Enums\ProductStatus;
use App\Exceptions\InvalidStateTransitionException;
use App\Exceptions\ProductOutOfStockException;
use App\Exceptions\SelfTransactionForbiddenException;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Product;
use App\Models\User;
use Illuminate\Validation\ValidationException;

class CartService
{
    /**
     * Get grouped cart contents separated by store (M-CR-01 / BR-OR-01).
     */
    public function getGroupedCart(User $buyer): array
    {
        $cart = Cart::firstOrCreate(['user_id' => $buyer->id]);

        $cart->load([
            'items.product.primaryImage',
            'items.product.category',
            'items.seller.sellerProfile',
        ]);

        $grouped = [];
        $selectedCount = 0;
        $selectedSubtotal = 0.0;
        $totalItemsCount = 0;

        foreach ($cart->items as $item) {
            $sellerId = $item->seller_id;
            if (! isset($grouped[$sellerId])) {
                $seller = $item->seller;
                $grouped[$sellerId] = [
                    'seller' => [
                        'id' => $seller->id,
                        'display_name' => $seller->display_name,
                        'shop_slug' => $seller->sellerProfile?->shop_slug,
                        'avatar_url' => $seller->profile?->avatar_url,
                        'trust_score' => (float) ($seller->sellerProfile?->trust_score ?? 100.0),
                    ],
                    'items' => [],
                    'seller_subtotal' => 0.0,
                ];
            }

            $product = $item->product;
            $linePrice = round((float) $product->price * $item->quantity, 2);
            $productStatus = $product->status instanceof ProductStatus ? $product->status->value : (string) $product->status;
            $isAvailable = ($productStatus === 'APPROVED') && ($product->available_quantity >= $item->quantity);

            $itemData = [
                'id' => $item->id,
                'product_id' => $product->id,
                'product_code' => $product->product_code,
                'title' => $product->title,
                'slug' => $product->slug,
                'condition' => $product->condition?->value ?? (string) $product->condition,
                'price' => (float) $product->price,
                'quantity' => (int) $item->quantity,
                'available_quantity' => (int) $product->available_quantity,
                'is_selected' => (bool) $item->is_selected,
                'is_available' => $isAvailable,
                'primary_image_url' => $product->primaryImage?->image_url,
                'line_total' => $linePrice,
            ];

            $grouped[$sellerId]['items'][] = $itemData;
            $grouped[$sellerId]['seller_subtotal'] = round($grouped[$sellerId]['seller_subtotal'] + $linePrice, 2);
            $totalItemsCount += $item->quantity;

            if ($item->is_selected && $isAvailable) {
                $selectedCount += $item->quantity;
                $selectedSubtotal = round($selectedSubtotal + $linePrice, 2);
            }
        }

        return [
            'cart_id' => $cart->id,
            'total_items_count' => $totalItemsCount,
            'selected_items_count' => $selectedCount,
            'selected_subtotal' => (float) $selectedSubtotal,
            'seller_groups' => array_values($grouped),
        ];
    }

    /**
     * Add item to cart with self-purchase guard and stock verification (BR-AC-02 / OF-01).
     *
     * @throws SelfTransactionForbiddenException
     * @throws InvalidStateTransitionException
     * @throws ProductOutOfStockException
     */
    public function addItem(User $buyer, int $productId, int $quantity = 1): CartItem
    {
        $product = Product::findOrFail($productId);

        // BR-AC-02: Self transaction forbidden
        if ($product->seller_id === $buyer->id) {
            throw new SelfTransactionForbiddenException('Bạn không thể tự thêm sản phẩm của chính mình vào giỏ hàng (BR-AC-02).');
        }

        $productStatus = $product->status instanceof ProductStatus ? $product->status->value : (string) $product->status;
        if ($product->listing_type !== 'FIXED_PRICE' || $productStatus !== 'APPROVED') {
            throw new InvalidStateTransitionException('Chỉ có thể thêm sản phẩm Giá cố định đã được duyệt vào giỏ hàng.');
        }

        $cart = Cart::firstOrCreate(['user_id' => $buyer->id]);
        $existingItem = CartItem::where('cart_id', $cart->id)
            ->where('product_id', $product->id)
            ->first();

        $currentQty = $existingItem ? $existingItem->quantity : 0;
        $targetQty = $currentQty + $quantity;

        if ($product->available_quantity <= 0 || $targetQty > $product->available_quantity) {
            throw new ProductOutOfStockException("Sản phẩm '{$product->title}' không đủ tồn kho (Còn lại: {$product->available_quantity}).");
        }

        if ($existingItem) {
            $existingItem->update([
                'quantity' => $targetQty,
                'is_selected' => true,
            ]);

            return $existingItem->fresh(['product.primaryImage', 'seller.sellerProfile']);
        }

        return CartItem::create([
            'cart_id' => $cart->id,
            'product_id' => $product->id,
            'seller_id' => $product->seller_id,
            'quantity' => $quantity,
            'is_selected' => true,
        ])->load(['product.primaryImage', 'seller.sellerProfile']);
    }

    /**
     * Update item quantity or selected state in cart.
     *
     * @throws ValidationException
     * @throws ProductOutOfStockException
     */
    public function updateItem(User $buyer, int $cartItemId, array $data): CartItem
    {
        $cart = Cart::firstOrCreate(['user_id' => $buyer->id]);
        $item = CartItem::where('cart_id', $cart->id)->where('id', $cartItemId)->firstOrFail();

        if (isset($data['quantity'])) {
            $qty = (int) $data['quantity'];
            if ($qty < 1) {
                throw ValidationException::withMessages(['quantity' => ['Số lượng sản phẩm tối thiểu là 1.']]);
            }

            $product = $item->product;
            if ($qty > $product->available_quantity) {
                throw new ProductOutOfStockException("Sản phẩm '{$product->title}' không đủ tồn kho (Còn lại: {$product->available_quantity}).");
            }

            $item->quantity = $qty;
        }

        if (array_key_exists('is_selected', $data)) {
            $item->is_selected = (bool) $data['is_selected'];
        }

        $item->save();

        return $item->fresh(['product.primaryImage', 'seller.sellerProfile']);
    }

    /**
     * Remove item from cart.
     */
    public function removeItem(User $buyer, int $cartItemId): void
    {
        $cart = Cart::firstOrCreate(['user_id' => $buyer->id]);
        $item = CartItem::where('cart_id', $cart->id)->where('id', $cartItemId)->firstOrFail();
        $item->delete();
    }
}
