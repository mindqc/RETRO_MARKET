<?php

namespace Database\Seeders;

use App\Enums\DisputeStatus;
use App\Enums\EscrowStatus;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Models\Auction;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\EscrowTransaction;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\Product;
use App\Models\Shipment;
use App\Models\User;
use App\Models\WalletTransaction;
use Carbon\Carbon;
use Illuminate\Database\Seeder;

class OrdersPaymentsAndEscrowSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $sellerA = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();
        $sellerB = User::where('email', 'retrolab.sg@izithrift.local')->firstOrFail();
        $sellerC = User::where('email', 'tiemnhamay@izithrift.local')->firstOrFail();
        $buyer1 = User::where('email', 'buyer.linh@izithrift.local')->firstOrFail();
        $buyer2 = User::where('email', 'buyer.kiet@izithrift.local')->firstOrFail();
        $buyer3 = User::where('email', 'buyer.ha@izithrift.local')->firstOrFail();

        $now = Carbon::now();

        // -------------------------------------------------------------------------
        // 1. CART ITEMS (Buyer 1 & Buyer 2 active cart items)
        // -------------------------------------------------------------------------
        $cartBuyer1 = Cart::firstOrCreate(['user_id' => $buyer1->id]);
        $prd1 = Product::where('product_code', 'PRD-2026-0001')->firstOrFail();
        CartItem::updateOrCreate(
            ['cart_id' => $cartBuyer1->id, 'product_id' => $prd1->id],
            [
                'seller_id' => $sellerA->id,
                'quantity' => 1,
                'is_selected' => true,
            ]
        );

        $cartBuyer2 = Cart::firstOrCreate(['user_id' => $buyer2->id]);
        $prd2 = Product::where('product_code', 'PRD-2026-0002')->firstOrFail();
        CartItem::updateOrCreate(
            ['cart_id' => $cartBuyer2->id, 'product_id' => $prd2->id],
            [
                'seller_id' => $sellerA->id,
                'quantity' => 1,
                'is_selected' => true,
            ]
        );

        // Fetch products for order items snapshot
        $prd3 = Product::where('product_code', 'PRD-2026-0003')->firstOrFail();
        $prd4 = Product::where('product_code', 'PRD-2026-0004')->firstOrFail();
        $prd5 = Product::where('product_code', 'PRD-2026-0005')->firstOrFail();
        $prd6 = Product::where('product_code', 'PRD-2026-0006')->firstOrFail();
        $prd8 = Product::where('product_code', 'PRD-2026-0008')->firstOrFail();
        $prd10 = Product::where('product_code', 'PRD-2026-0010')->firstOrFail();

        $auc4 = Auction::where('auction_code', 'AUC-2026-0004')->firstOrFail();
        $auc6 = Auction::where('auction_code', 'AUC-2026-0006')->firstOrFail();

        $shippingAddressLinh = [
            'recipient_name' => 'Nguyễn Ngọc Linh',
            'phone_number' => '0901234567',
            'street_address' => '123 Đường Lê Lợi, Phường Bến Nghé',
            'ward' => 'Phường Bến Nghé',
            'district' => 'Quận 1',
            'province' => 'TP. Hồ Chí Minh',
        ];

        $shippingAddressKiet = [
            'recipient_name' => 'Trần Tuấn Kiệt',
            'phone_number' => '0912345678',
            'street_address' => '456 Đường Trần Phú, Phường 4',
            'ward' => 'Phường 4',
            'district' => 'Quận 5',
            'province' => 'TP. Hồ Chí Minh',
        ];

        $shippingAddressHa = [
            'recipient_name' => 'Lê Thanh Hà',
            'phone_number' => '0923456789',
            'street_address' => '789 Đường Hai Bà Trưng, Phường 6',
            'ward' => 'Phường 6',
            'district' => 'Quận 3',
            'province' => 'TP. Hồ Chí Minh',
        ];

        // -------------------------------------------------------------------------
        // 2. 10 STANDARDIZED ORDERS (Table 3.4 in P5_05_SEEDERS_SPEC.md)
        // -------------------------------------------------------------------------

        // ORD-2026-0001: PENDING_PAYMENT / UNPAID / NONE / NONE (Fixed-price checkout pending QR payment)
        $ord1 = Order::updateOrCreate(
            ['order_code' => 'ORD-2026-0001'],
            [
                'buyer_id' => $buyer1->id,
                'seller_id' => $sellerA->id,
                'order_source' => 'FIXED_PRICE',
                'item_subtotal' => 400000.00,
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => 0.0600,
                'protection_fixed_fee_applied' => 7000.00,
                'buyer_protection_fee' => 31000.00,
                'total_amount' => 431000.00,
                'seller_net_amount' => 400000.00,
                'shipping_address_snapshot' => $shippingAddressLinh,
                'order_status' => OrderStatus::PENDING_PAYMENT,
                'payment_status' => PaymentStatus::UNPAID,
                'escrow_status' => EscrowStatus::NONE,
                'dispute_status' => DisputeStatus::NONE,
                'payment_expires_at' => (clone $now)->addMinutes(30),
            ]
        );
        $this->seedOrderItem($ord1, $prd3, 400000.00);
        Payment::updateOrCreate(
            ['payment_reference' => 'PAY-2026-0001'],
            [
                'order_id' => $ord1->id,
                'payer_id' => $buyer1->id,
                'amount' => 431000.00,
                'qr_payload' => '00020101021238540010A00000072701240006970422011012345678900208QRIBFTTA530370454064310005802VN62170813ORD-2026-00016304ABCD',
                'status' => 'PENDING',
                'expires_at' => (clone $now)->addMinutes(30),
            ]
        );

        // ORD-2026-0002: PAID / PAID / HELD / NONE (Auction win from AUC-2026-0004)
        $ord2 = Order::updateOrCreate(
            ['order_code' => 'ORD-2026-0002'],
            [
                'buyer_id' => $buyer1->id,
                'seller_id' => $sellerA->id,
                'order_source' => 'AUCTION',
                'auction_id' => $auc4->id,
                'item_subtotal' => 1000000.00,
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => 0.0600,
                'protection_fixed_fee_applied' => 7000.00,
                'buyer_protection_fee' => 67000.00,
                'total_amount' => 1067000.00,
                'seller_net_amount' => 1000000.00,
                'shipping_address_snapshot' => $shippingAddressLinh,
                'order_status' => OrderStatus::PAID,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => EscrowStatus::HELD,
                'dispute_status' => DisputeStatus::NONE,
                'paid_at' => (clone $now)->subHours(2),
                'payment_expires_at' => (clone $now)->subHours(1),
            ]
        );
        $this->seedOrderItem($ord2, $prd10, 1000000.00);
        $pay2 = Payment::updateOrCreate(
            ['payment_reference' => 'PAY-2026-0002'],
            [
                'order_id' => $ord2->id,
                'payer_id' => $buyer1->id,
                'amount' => 1067000.00,
                'qr_payload' => 'PAYLOAD-ORD-2026-0002-PAID',
                'status' => 'PAID',
                'paid_at' => (clone $now)->subHours(2),
                'expires_at' => (clone $now)->subHours(1),
            ]
        );
        EscrowTransaction::firstOrCreate(
            ['transaction_code' => 'ETX-2026-0001'],
            [
                'order_id' => $ord2->id,
                'payment_id' => $pay2->id,
                'buyer_id' => $buyer1->id,
                'seller_id' => $sellerA->id,
                'transaction_type' => 'HOLD',
                'gross_amount' => 1067000.00,
                'item_subtotal_amount' => 1000000.00,
                'buyer_protection_fee_amount' => 67000.00,
                'seller_released_amount' => 0.00,
                'buyer_refunded_amount' => 0.00,
                'platform_fee_retained' => 0.00,
                'triggered_by_user_id' => $buyer1->id,
                'note' => 'Giu tien ky quy don hang dau gia ORD-2026-0002',
                'created_at' => (clone $now)->subHours(2),
            ]
        );

        // ORD-2026-0003: PREPARING / PAID / HELD / NONE (with cancellation_requested = true)
        $ord3 = Order::updateOrCreate(
            ['order_code' => 'ORD-2026-0003'],
            [
                'buyer_id' => $buyer2->id,
                'seller_id' => $sellerA->id,
                'order_source' => 'FIXED_PRICE',
                'item_subtotal' => 350000.00,
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => 0.0600,
                'protection_fixed_fee_applied' => 7000.00,
                'buyer_protection_fee' => 28000.00,
                'total_amount' => 378000.00,
                'seller_net_amount' => 350000.00,
                'shipping_address_snapshot' => $shippingAddressKiet,
                'order_status' => OrderStatus::PREPARING,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => EscrowStatus::HELD,
                'dispute_status' => DisputeStatus::NONE,
                'cancellation_requested' => true,
                'cancellation_request_reason' => 'Tôi muốn đổi địa chỉ giao hàng, mong shop hủy giúp để đặt lại',
                'paid_at' => (clone $now)->subHours(4),
                'preparing_at' => (clone $now)->subHours(3),
                'payment_expires_at' => (clone $now)->subHours(3),
            ]
        );
        $this->seedOrderItem($ord3, $prd2, 350000.00);
        $pay3 = Payment::updateOrCreate(
            ['payment_reference' => 'PAY-2026-0003'],
            [
                'order_id' => $ord3->id,
                'payer_id' => $buyer2->id,
                'amount' => 378000.00,
                'qr_payload' => 'PAYLOAD-ORD-2026-0003-PAID',
                'status' => 'PAID',
                'paid_at' => (clone $now)->subHours(4),
                'expires_at' => (clone $now)->subHours(3),
            ]
        );
        EscrowTransaction::firstOrCreate(
            ['transaction_code' => 'ETX-2026-0002'],
            [
                'order_id' => $ord3->id,
                'payment_id' => $pay3->id,
                'buyer_id' => $buyer2->id,
                'seller_id' => $sellerA->id,
                'transaction_type' => 'HOLD',
                'gross_amount' => 378000.00,
                'item_subtotal_amount' => 350000.00,
                'buyer_protection_fee_amount' => 28000.00,
                'seller_released_amount' => 0.00,
                'buyer_refunded_amount' => 0.00,
                'platform_fee_retained' => 0.00,
                'triggered_by_user_id' => $buyer2->id,
                'note' => 'Giu tien ky quy don hang ORD-2026-0003',
                'created_at' => (clone $now)->subHours(4),
            ]
        );

        // ORD-2026-0004: SHIPPED / PAID / HELD / NONE (In transit via GHN)
        $ord4 = Order::updateOrCreate(
            ['order_code' => 'ORD-2026-0004'],
            [
                'buyer_id' => $buyer1->id,
                'seller_id' => $sellerB->id,
                'order_source' => 'FIXED_PRICE',
                'item_subtotal' => 500000.00,
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => 0.0600,
                'protection_fixed_fee_applied' => 7000.00,
                'buyer_protection_fee' => 37000.00,
                'total_amount' => 537000.00,
                'seller_net_amount' => 500000.00,
                'shipping_address_snapshot' => $shippingAddressLinh,
                'order_status' => OrderStatus::SHIPPED,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => EscrowStatus::HELD,
                'dispute_status' => DisputeStatus::NONE,
                'paid_at' => (clone $now)->subDays(1),
                'preparing_at' => (clone $now)->subHours(20),
                'shipped_at' => (clone $now)->subHours(12),
                'payment_expires_at' => (clone $now)->subDays(1),
            ]
        );
        $this->seedOrderItem($ord4, $prd4, 500000.00);
        $pay4 = Payment::updateOrCreate(
            ['payment_reference' => 'PAY-2026-0004'],
            [
                'order_id' => $ord4->id,
                'payer_id' => $buyer1->id,
                'amount' => 537000.00,
                'qr_payload' => 'PAYLOAD-ORD-2026-0004-PAID',
                'status' => 'PAID',
                'paid_at' => (clone $now)->subDays(1),
                'expires_at' => (clone $now)->subDays(1),
            ]
        );
        Shipment::updateOrCreate(
            ['order_id' => $ord4->id],
            [
                'carrier_name' => 'Giao Hàng Nhanh (GHN)',
                'tracking_code' => 'GHN2026RETRO004',
                'shipping_note' => 'Kien hang dong goi chong soc ky luong gom hop giay kraft va xop no',
                'status' => 'SHIPPED',
                'shipped_at' => (clone $now)->subHours(12),
                'updated_by' => $sellerB->id,
            ]
        );
        EscrowTransaction::firstOrCreate(
            ['transaction_code' => 'ETX-2026-0003'],
            [
                'order_id' => $ord4->id,
                'payment_id' => $pay4->id,
                'buyer_id' => $buyer1->id,
                'seller_id' => $sellerB->id,
                'transaction_type' => 'HOLD',
                'gross_amount' => 537000.00,
                'item_subtotal_amount' => 500000.00,
                'buyer_protection_fee_amount' => 37000.00,
                'seller_released_amount' => 0.00,
                'buyer_refunded_amount' => 0.00,
                'platform_fee_retained' => 0.00,
                'triggered_by_user_id' => $buyer1->id,
                'note' => 'Giu tien ky quy don hang ORD-2026-0004',
                'created_at' => (clone $now)->subDays(1),
            ]
        );

        // ORD-2026-0005: DELIVERED / PAID / HELD / NONE (auto_complete_at expired 5 mins ago)
        $ord5 = Order::updateOrCreate(
            ['order_code' => 'ORD-2026-0005'],
            [
                'buyer_id' => $buyer2->id,
                'seller_id' => $sellerB->id,
                'order_source' => 'FIXED_PRICE',
                'item_subtotal' => 600000.00,
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => 0.0600,
                'protection_fixed_fee_applied' => 7000.00,
                'buyer_protection_fee' => 43000.00,
                'total_amount' => 643000.00,
                'seller_net_amount' => 600000.00,
                'shipping_address_snapshot' => $shippingAddressKiet,
                'order_status' => OrderStatus::DELIVERED,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => EscrowStatus::HELD,
                'dispute_status' => DisputeStatus::NONE,
                'paid_at' => (clone $now)->subDays(3),
                'preparing_at' => (clone $now)->subDays(2)->subHours(20),
                'shipped_at' => (clone $now)->subDays(2),
                'delivered_at' => (clone $now)->subHours(72)->subMinutes(5),
                'auto_complete_at' => (clone $now)->subMinutes(5),
                'payment_expires_at' => (clone $now)->subDays(3),
            ]
        );
        $this->seedOrderItem($ord5, $prd5, 600000.00);
        $pay5 = Payment::updateOrCreate(
            ['payment_reference' => 'PAY-2026-0005'],
            [
                'order_id' => $ord5->id,
                'payer_id' => $buyer2->id,
                'amount' => 643000.00,
                'qr_payload' => 'PAYLOAD-ORD-2026-0005-PAID',
                'status' => 'PAID',
                'paid_at' => (clone $now)->subDays(3),
                'expires_at' => (clone $now)->subDays(3),
            ]
        );
        Shipment::updateOrCreate(
            ['order_id' => $ord5->id],
            [
                'carrier_name' => 'Viettel Post',
                'tracking_code' => 'VTP2026RETRO005',
                'shipping_note' => 'Giao tan tay nguoi nhan, kiem tra ngoai quan kien hang',
                'status' => 'DELIVERED',
                'shipped_at' => (clone $now)->subDays(2),
                'delivered_at' => (clone $now)->subHours(72)->subMinutes(5),
                'updated_by' => $sellerB->id,
            ]
        );
        EscrowTransaction::firstOrCreate(
            ['transaction_code' => 'ETX-2026-0004'],
            [
                'order_id' => $ord5->id,
                'payment_id' => $pay5->id,
                'buyer_id' => $buyer2->id,
                'seller_id' => $sellerB->id,
                'transaction_type' => 'HOLD',
                'gross_amount' => 643000.00,
                'item_subtotal_amount' => 600000.00,
                'buyer_protection_fee_amount' => 43000.00,
                'seller_released_amount' => 0.00,
                'buyer_refunded_amount' => 0.00,
                'platform_fee_retained' => 0.00,
                'triggered_by_user_id' => $buyer2->id,
                'note' => 'Giu tien ky quy don hang ORD-2026-0005',
                'created_at' => (clone $now)->subDays(3),
            ]
        );

        // ORD-2026-0006: COMPLETED / PAID / RELEASED / NONE (Order finished, seller released 500k)
        $ord6 = Order::updateOrCreate(
            ['order_code' => 'ORD-2026-0006'],
            [
                'buyer_id' => $buyer1->id,
                'seller_id' => $sellerA->id,
                'order_source' => 'FIXED_PRICE',
                'item_subtotal' => 500000.00,
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => 0.0600,
                'protection_fixed_fee_applied' => 7000.00,
                'buyer_protection_fee' => 37000.00,
                'total_amount' => 537000.00,
                'seller_net_amount' => 500000.00,
                'shipping_address_snapshot' => $shippingAddressLinh,
                'order_status' => OrderStatus::COMPLETED,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => EscrowStatus::RELEASED,
                'dispute_status' => DisputeStatus::NONE,
                'paid_at' => (clone $now)->subDays(5),
                'shipped_at' => (clone $now)->subDays(4),
                'delivered_at' => (clone $now)->subDays(3),
                'completed_at' => (clone $now)->subDays(2),
                'payment_expires_at' => (clone $now)->subDays(5),
            ]
        );
        $this->seedOrderItem($ord6, $prd1, 500000.00);
        $pay6 = Payment::updateOrCreate(
            ['payment_reference' => 'PAY-2026-0006'],
            [
                'order_id' => $ord6->id,
                'payer_id' => $buyer1->id,
                'amount' => 537000.00,
                'qr_payload' => 'PAYLOAD-ORD-2026-0006-PAID',
                'status' => 'PAID',
                'paid_at' => (clone $now)->subDays(5),
                'expires_at' => (clone $now)->subDays(5),
            ]
        );
        Shipment::updateOrCreate(
            ['order_id' => $ord6->id],
            [
                'carrier_name' => 'Giao Hàng Tiết Kiệm (GHTK)',
                'tracking_code' => 'GHTK2026RETRO006',
                'shipping_note' => 'Giao hang thanh cong',
                'status' => 'DELIVERED',
                'shipped_at' => (clone $now)->subDays(4),
                'delivered_at' => (clone $now)->subDays(3),
                'updated_by' => $sellerA->id,
            ]
        );
        $etxHold6 = EscrowTransaction::firstOrCreate(
            ['transaction_code' => 'ETX-2026-0005'],
            [
                'order_id' => $ord6->id,
                'payment_id' => $pay6->id,
                'buyer_id' => $buyer1->id,
                'seller_id' => $sellerA->id,
                'transaction_type' => 'HOLD',
                'gross_amount' => 537000.00,
                'item_subtotal_amount' => 500000.00,
                'buyer_protection_fee_amount' => 37000.00,
                'seller_released_amount' => 0.00,
                'buyer_refunded_amount' => 0.00,
                'platform_fee_retained' => 0.00,
                'triggered_by_user_id' => $buyer1->id,
                'note' => 'Giu tien ky quy don hang ORD-2026-0006',
                'created_at' => (clone $now)->subDays(5),
            ]
        );
        $etxRelease6 = EscrowTransaction::firstOrCreate(
            ['transaction_code' => 'ETX-2026-0006'],
            [
                'order_id' => $ord6->id,
                'payment_id' => $pay6->id,
                'buyer_id' => $buyer1->id,
                'seller_id' => $sellerA->id,
                'transaction_type' => 'RELEASE',
                'gross_amount' => 537000.00,
                'item_subtotal_amount' => 500000.00,
                'buyer_protection_fee_amount' => 37000.00,
                'seller_released_amount' => 500000.00,
                'buyer_refunded_amount' => 0.00,
                'platform_fee_retained' => 37000.00,
                'triggered_by_user_id' => $buyer1->id,
                'note' => 'Giai ngan don hang hoan tat ORD-2026-0006',
                'created_at' => (clone $now)->subDays(2),
            ]
        );
        WalletTransaction::firstOrCreate(
            ['wallet_tx_code' => 'WTX-2026-0001'],
            [
                'seller_id' => $sellerA->id,
                'order_id' => $ord6->id,
                'escrow_transaction_id' => $etxRelease6->id,
                'entry_type' => 'CREDIT',
                'amount' => 500000.00,
                'balance_before' => 0.00,
                'balance_after' => 500000.00,
                'description' => 'Thanh toán tiền hàng đơn ORD-2026-0006 thành công',
                'created_at' => (clone $now)->subDays(2),
            ]
        );

        // ORD-2026-0007: CANCELLED / REFUNDED / REFUNDED / NONE (Buyer cancelled immediately at PAID -> 100% refund)
        $ord7 = Order::updateOrCreate(
            ['order_code' => 'ORD-2026-0007'],
            [
                'buyer_id' => $buyer2->id,
                'seller_id' => $sellerC->id,
                'order_source' => 'FIXED_PRICE',
                'item_subtotal' => 300000.00,
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => 0.0600,
                'protection_fixed_fee_applied' => 7000.00,
                'buyer_protection_fee' => 25000.00,
                'total_amount' => 325000.00,
                'seller_net_amount' => 300000.00,
                'shipping_address_snapshot' => $shippingAddressKiet,
                'order_status' => OrderStatus::CANCELLED,
                'payment_status' => PaymentStatus::REFUNDED,
                'escrow_status' => EscrowStatus::REFUNDED,
                'dispute_status' => DisputeStatus::NONE,
                'cancelled_by_role' => 'BUYER',
                'cancel_reason' => 'Người mua chủ động hủy đơn trong giai đoạn PAID theo DEC-07',
                'paid_at' => (clone $now)->subDays(2),
                'cancelled_at' => (clone $now)->subDays(2)->addMinutes(10),
                'payment_expires_at' => (clone $now)->subDays(2),
            ]
        );
        $this->seedOrderItem($ord7, $prd6, 300000.00);
        $pay7 = Payment::updateOrCreate(
            ['payment_reference' => 'PAY-2026-0007'],
            [
                'order_id' => $ord7->id,
                'payer_id' => $buyer2->id,
                'amount' => 325000.00,
                'qr_payload' => 'PAYLOAD-ORD-2026-0007-REFUNDED',
                'status' => 'PAID',
                'paid_at' => (clone $now)->subDays(2),
                'expires_at' => (clone $now)->subDays(2),
            ]
        );
        EscrowTransaction::firstOrCreate(
            ['transaction_code' => 'ETX-2026-0007'],
            [
                'order_id' => $ord7->id,
                'payment_id' => $pay7->id,
                'buyer_id' => $buyer2->id,
                'seller_id' => $sellerC->id,
                'transaction_type' => 'HOLD',
                'gross_amount' => 325000.00,
                'item_subtotal_amount' => 300000.00,
                'buyer_protection_fee_amount' => 25000.00,
                'seller_released_amount' => 0.00,
                'buyer_refunded_amount' => 0.00,
                'platform_fee_retained' => 0.00,
                'triggered_by_user_id' => $buyer2->id,
                'note' => 'Giu tien ky quy don hang ORD-2026-0007',
                'created_at' => (clone $now)->subDays(2),
            ]
        );
        EscrowTransaction::firstOrCreate(
            ['transaction_code' => 'ETX-2026-0008'],
            [
                'order_id' => $ord7->id,
                'payment_id' => $pay7->id,
                'buyer_id' => $buyer2->id,
                'seller_id' => $sellerC->id,
                'transaction_type' => 'FULL_REFUND',
                'gross_amount' => 325000.00,
                'item_subtotal_amount' => 300000.00,
                'buyer_protection_fee_amount' => 25000.00,
                'seller_released_amount' => 0.00,
                'buyer_refunded_amount' => 325000.00,
                'platform_fee_retained' => 0.00,
                'triggered_by_user_id' => $buyer2->id,
                'note' => 'Hoàn trả 100% tổng tiền đơn hàng do Buyer hủy ở trạng thái PAID (DEC-07)',
                'created_at' => (clone $now)->subDays(2)->addMinutes(10),
            ]
        );

        // ORD-2026-0008: CANCELLED / EXPIRED / NONE / NONE (Auction win unpaid after 30 mins)
        $ord8 = Order::updateOrCreate(
            ['order_code' => 'ORD-2026-0008'],
            [
                'buyer_id' => $buyer3->id,
                'seller_id' => $sellerB->id,
                'order_source' => 'AUCTION',
                'auction_id' => $auc6->id,
                'item_subtotal' => 500000.00,
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => 0.0600,
                'protection_fixed_fee_applied' => 7000.00,
                'buyer_protection_fee' => 37000.00,
                'total_amount' => 537000.00,
                'seller_net_amount' => 500000.00,
                'shipping_address_snapshot' => $shippingAddressHa,
                'order_status' => OrderStatus::CANCELLED,
                'payment_status' => PaymentStatus::EXPIRED,
                'escrow_status' => EscrowStatus::NONE,
                'dispute_status' => DisputeStatus::NONE,
                'cancelled_by_role' => 'SYSTEM',
                'cancel_reason' => 'Người thắng đấu giá quá hạn 30 phút thanh toán (DEC-02)',
                'payment_expires_at' => (clone $now)->subHours(2),
                'cancelled_at' => (clone $now)->subHours(2),
            ]
        );
        $this->seedOrderItem($ord8, $prd8, 500000.00);
        Payment::updateOrCreate(
            ['payment_reference' => 'PAY-2026-0008'],
            [
                'order_id' => $ord8->id,
                'payer_id' => $buyer3->id,
                'amount' => 537000.00,
                'qr_payload' => 'PAYLOAD-ORD-2026-0008-EXPIRED',
                'status' => 'EXPIRED',
                'failure_reason' => 'Hết hạn thanh toán sau 30 phút (DEC-02)',
                'expires_at' => (clone $now)->subHours(2),
            ]
        );

        // ORD-2026-0009: DELIVERED / PAID / HELD / OPEN (Dispute DSP-2026-0001 active, escrow frozen)
        $ord9 = Order::updateOrCreate(
            ['order_code' => 'ORD-2026-0009'],
            [
                'buyer_id' => $buyer1->id,
                'seller_id' => $sellerA->id,
                'order_source' => 'FIXED_PRICE',
                'item_subtotal' => 700000.00,
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => 0.0600,
                'protection_fixed_fee_applied' => 7000.00,
                'buyer_protection_fee' => 49000.00,
                'total_amount' => 749000.00,
                'seller_net_amount' => 700000.00,
                'shipping_address_snapshot' => $shippingAddressLinh,
                'order_status' => OrderStatus::DELIVERED,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => EscrowStatus::HELD,
                'dispute_status' => DisputeStatus::OPEN,
                'paid_at' => (clone $now)->subDays(2),
                'shipped_at' => (clone $now)->subHours(20),
                'delivered_at' => (clone $now)->subHours(14),
                'escrow_frozen_at' => (clone $now)->subHours(12),
                'payment_expires_at' => (clone $now)->subDays(2),
            ]
        );
        $this->seedOrderItem($ord9, $prd3, 700000.00);
        $pay9 = Payment::updateOrCreate(
            ['payment_reference' => 'PAY-2026-0009'],
            [
                'order_id' => $ord9->id,
                'payer_id' => $buyer1->id,
                'amount' => 749000.00,
                'qr_payload' => 'PAYLOAD-ORD-2026-0009-PAID',
                'status' => 'PAID',
                'paid_at' => (clone $now)->subDays(2),
                'expires_at' => (clone $now)->subDays(2),
            ]
        );
        Shipment::updateOrCreate(
            ['order_id' => $ord9->id],
            [
                'carrier_name' => 'SPX Express',
                'tracking_code' => 'SPX2026RETRO009',
                'shipping_note' => 'Giao hang thanh cong',
                'status' => 'DELIVERED',
                'shipped_at' => (clone $now)->subHours(20),
                'delivered_at' => (clone $now)->subHours(14),
                'updated_by' => $sellerA->id,
            ]
        );
        EscrowTransaction::firstOrCreate(
            ['transaction_code' => 'ETX-2026-0009'],
            [
                'order_id' => $ord9->id,
                'payment_id' => $pay9->id,
                'buyer_id' => $buyer1->id,
                'seller_id' => $sellerA->id,
                'transaction_type' => 'HOLD',
                'gross_amount' => 749000.00,
                'item_subtotal_amount' => 700000.00,
                'buyer_protection_fee_amount' => 49000.00,
                'seller_released_amount' => 0.00,
                'buyer_refunded_amount' => 0.00,
                'platform_fee_retained' => 0.00,
                'triggered_by_user_id' => $buyer1->id,
                'note' => 'Giu tien ky quy don hang ORD-2026-0009 (Tien dang bi dong bang boi khieu nai DSP-2026-0001)',
                'created_at' => (clone $now)->subDays(2),
            ]
        );

        // ORD-2026-0010: COMPLETED / PAID / PARTIALLY_REFUNDED / RESOLVED (Admin ruled partial refund: 200k Buyer, 600k Seller)
        $ord10 = Order::updateOrCreate(
            ['order_code' => 'ORD-2026-0010'],
            [
                'buyer_id' => $buyer2->id,
                'seller_id' => $sellerA->id,
                'order_source' => 'FIXED_PRICE',
                'item_subtotal' => 800000.00,
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => 0.0600,
                'protection_fixed_fee_applied' => 7000.00,
                'buyer_protection_fee' => 55000.00,
                'total_amount' => 855000.00,
                'seller_net_amount' => 800000.00,
                'shipping_address_snapshot' => $shippingAddressKiet,
                'order_status' => OrderStatus::COMPLETED,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => EscrowStatus::PARTIALLY_REFUNDED,
                'dispute_status' => DisputeStatus::RESOLVED,
                'paid_at' => (clone $now)->subDays(4),
                'shipped_at' => (clone $now)->subDays(3)->subHours(10),
                'delivered_at' => (clone $now)->subDays(3),
                'escrow_frozen_at' => (clone $now)->subDays(3),
                'completed_at' => (clone $now)->subDays(1),
                'payment_expires_at' => (clone $now)->subDays(4),
            ]
        );
        $this->seedOrderItem($ord10, $prd4, 800000.00);
        $pay10 = Payment::updateOrCreate(
            ['payment_reference' => 'PAY-2026-0010'],
            [
                'order_id' => $ord10->id,
                'payer_id' => $buyer2->id,
                'amount' => 855000.00,
                'qr_payload' => 'PAYLOAD-ORD-2026-0010-PAID',
                'status' => 'PAID',
                'paid_at' => (clone $now)->subDays(4),
                'expires_at' => (clone $now)->subDays(4),
            ]
        );
        Shipment::updateOrCreate(
            ['order_id' => $ord10->id],
            [
                'carrier_name' => 'Viettel Post',
                'tracking_code' => 'VTP2026RETRO010',
                'shipping_note' => 'Giao hang thanh cong',
                'status' => 'DELIVERED',
                'shipped_at' => (clone $now)->subDays(3)->subHours(10),
                'delivered_at' => (clone $now)->subDays(3),
                'updated_by' => $sellerA->id,
            ]
        );
        $etxHold10 = EscrowTransaction::firstOrCreate(
            ['transaction_code' => 'ETX-2026-0010'],
            [
                'order_id' => $ord10->id,
                'payment_id' => $pay10->id,
                'buyer_id' => $buyer2->id,
                'seller_id' => $sellerA->id,
                'transaction_type' => 'HOLD',
                'gross_amount' => 855000.00,
                'item_subtotal_amount' => 800000.00,
                'buyer_protection_fee_amount' => 55000.00,
                'seller_released_amount' => 0.00,
                'buyer_refunded_amount' => 0.00,
                'platform_fee_retained' => 0.00,
                'triggered_by_user_id' => $buyer2->id,
                'note' => 'Giu tien ky quy don hang ORD-2026-0010',
                'created_at' => (clone $now)->subDays(4),
            ]
        );
        $etxPartial10 = EscrowTransaction::firstOrCreate(
            ['transaction_code' => 'ETX-2026-0011'],
            [
                'order_id' => $ord10->id,
                'payment_id' => $pay10->id,
                'buyer_id' => $buyer2->id,
                'seller_id' => $sellerA->id,
                'transaction_type' => 'PARTIAL_REFUND',
                'gross_amount' => 855000.00,
                'item_subtotal_amount' => 800000.00,
                'buyer_protection_fee_amount' => 55000.00,
                'seller_released_amount' => 600000.00,
                'buyer_refunded_amount' => 200000.00,
                'platform_fee_retained' => 55000.00,
                'triggered_by_user_id' => User::where('role', 'admin')->first()->id,
                'note' => 'Phán quyết Admin: Hoàn trả 200.000đ cho Buyer, giải ngân 600.000đ cho Seller A',
                'created_at' => (clone $now)->subDays(1),
            ]
        );
        WalletTransaction::firstOrCreate(
            ['wallet_tx_code' => 'WTX-2026-0002'],
            [
                'seller_id' => $sellerA->id,
                'order_id' => $ord10->id,
                'escrow_transaction_id' => $etxPartial10->id,
                'entry_type' => 'CREDIT',
                'amount' => 600000.00,
                'balance_before' => 500000.00,
                'balance_after' => 1100000.00,
                'description' => 'Giải ngân sau phán quyết khiếu nại đơn ORD-2026-0010',
                'created_at' => (clone $now)->subDays(1),
            ]
        );

        // -------------------------------------------------------------------------
        // 3. ZERO-DRIFT LEDGER RECONCILIATION FOR SELLER PROFILES
        // -------------------------------------------------------------------------
        foreach ([$sellerA, $sellerB, $sellerC] as $seller) {
            $walletBal = (float) WalletTransaction::where('seller_id', $seller->id)->sum('amount');
            $escrowHeld = (float) Order::where('seller_id', $seller->id)
                ->where('escrow_status', EscrowStatus::HELD->value)
                ->sum('item_subtotal');
            $completedCount = Order::where('seller_id', $seller->id)
                ->where('order_status', OrderStatus::COMPLETED->value)
                ->count();

            $seller->sellerProfile()->update([
                'wallet_balance' => $walletBal,
                'escrow_held_balance' => $escrowHeld,
                'completed_orders_count' => $completedCount,
            ]);
        }
    }

    /**
     * Helper to safely seed OrderItem with immutability support.
     */
    private function seedOrderItem(Order $order, Product $product, float $price): OrderItem
    {
        return OrderItem::firstOrCreate(
            [
                'order_id' => $order->id,
                'product_id' => $product->id,
            ],
            [
                'product_code_snapshot' => $product->product_code,
                'product_title_snapshot' => $product->title,
                'condition_snapshot' => $product->condition,
                'defect_info_snapshot' => $product->defect_info ?? 'Không có lỗi',
                'primary_image_snapshot' => $product->primaryImage?->image_url ?? $product->images()->first()?->image_url ?? '/assets/images/placeholder.jpg',
                'unit_price_snapshot' => $price,
                'quantity' => 1,
                'line_total' => $price,
            ]
        );
    }
}
