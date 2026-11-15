<?php

namespace Database\Seeders;

use App\Models\AuditLog;
use App\Models\Conversation;
use App\Models\Favorite;
use App\Models\Message;
use App\Models\Notification;
use App\Models\Order;
use App\Models\Product;
use App\Models\SellerFollow;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;

class EngagementChatAndAuditSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $admin = User::where('email', 'admin@izithrift.local')->firstOrFail();
        $moderator = User::where('email', 'moderator@izithrift.local')->firstOrFail();
        $sellerA = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();
        $sellerB = User::where('email', 'retrolab.sg@izithrift.local')->firstOrFail();
        $buyer1 = User::where('email', 'buyer.linh@izithrift.local')->firstOrFail();
        $buyer2 = User::where('email', 'buyer.kiet@izithrift.local')->firstOrFail();

        $prd1 = Product::where('product_code', 'PRD-2026-0001')->firstOrFail();
        $prd2 = Product::where('product_code', 'PRD-2026-0002')->firstOrFail();
        $prd3 = Product::where('product_code', 'PRD-2026-0003')->firstOrFail();
        $prd7 = Product::where('product_code', 'PRD-2026-0007')->firstOrFail();
        $prd14 = Product::where('product_code', 'PRD-2026-0014')->firstOrFail();

        $ord1 = Order::where('order_code', 'ORD-2026-0001')->firstOrFail();
        $ord6 = Order::where('order_code', 'ORD-2026-0006')->firstOrFail();

        $now = Carbon::now();

        // -------------------------------------------------------------------------
        // 1. FAVORITES
        // -------------------------------------------------------------------------
        Favorite::firstOrCreate(['user_id' => $buyer1->id, 'product_id' => $prd1->id]);
        Favorite::firstOrCreate(['user_id' => $buyer1->id, 'product_id' => $prd7->id]);
        Favorite::firstOrCreate(['user_id' => $buyer2->id, 'product_id' => $prd2->id]);
        Favorite::firstOrCreate(['user_id' => $buyer2->id, 'product_id' => $prd3->id]);

        // Update favorite_count for products
        $prd1->update(['favorite_count' => Favorite::where('product_id', $prd1->id)->count()]);
        $prd2->update(['favorite_count' => Favorite::where('product_id', $prd2->id)->count()]);
        $prd3->update(['favorite_count' => Favorite::where('product_id', $prd3->id)->count()]);
        $prd7->update(['favorite_count' => Favorite::where('product_id', $prd7->id)->count()]);

        // -------------------------------------------------------------------------
        // 2. SELLER FOLLOWS
        // -------------------------------------------------------------------------
        SellerFollow::firstOrCreate(['follower_id' => $buyer1->id, 'seller_id' => $sellerA->id]);
        SellerFollow::firstOrCreate(['follower_id' => $buyer1->id, 'seller_id' => $sellerB->id]);
        SellerFollow::firstOrCreate(['follower_id' => $buyer2->id, 'seller_id' => $sellerA->id]);

        // -------------------------------------------------------------------------
        // 3. CONVERSATIONS & 1-ON-1 MESSAGES (With product context)
        // -------------------------------------------------------------------------
        [$u1, $u2] = Conversation::normalizeParticipants($buyer1->id, $sellerA->id);

        $conversation = Conversation::updateOrCreate(
            ['user_one_id' => $u1, 'user_two_id' => $u2],
            [
                'context_product_id' => $prd1->id,
                'context_order_id' => $ord6->id,
                'last_message_preview' => 'Dạ em cảm ơn chị nhiều ạ! Chúc chị mặc đẹp nha.',
                'last_message_at' => (clone $now)->subDays(2),
            ]
        );

        Message::firstOrCreate(
            [
                'conversation_id' => $conversation->id,
                'sender_id' => $buyer1->id,
                'message_text' => 'Chào shop, áo măng tô dạ này bạn cao 1m62 mặc dài tới đâu ạ?',
            ],
            [
                'attached_product_id' => $prd1->id,
                'is_read' => true,
                'read_at' => (clone $now)->subDays(3)->addMinutes(10),
                'created_at' => (clone $now)->subDays(3),
            ]
        );

        Message::firstOrCreate(
            [
                'conversation_id' => $conversation->id,
                'sender_id' => $sellerA->id,
                'message_text' => 'Dạ chào bạn, bạn cao 1m62 mặc qua gối khoảng 5cm, form thụng vintage rất xinh ạ!',
            ],
            [
                'attached_product_id' => null,
                'is_read' => true,
                'read_at' => (clone $now)->subDays(3)->addMinutes(25),
                'created_at' => (clone $now)->subDays(3)->addMinutes(15),
            ]
        );

        Message::firstOrCreate(
            [
                'conversation_id' => $conversation->id,
                'sender_id' => $buyer1->id,
                'message_text' => 'Dạ mình nhận được áo rồi, vải dạ dày dặn và thơm lắm, cảm ơn shop!',
            ],
            [
                'attached_product_id' => null,
                'is_read' => true,
                'read_at' => (clone $now)->subDays(2)->addMinutes(5),
                'created_at' => (clone $now)->subDays(2),
            ]
        );

        Message::firstOrCreate(
            [
                'conversation_id' => $conversation->id,
                'sender_id' => $sellerA->id,
                'message_text' => 'Dạ em cảm ơn chị nhiều ạ! Chúc chị mặc đẹp nha.',
            ],
            [
                'attached_product_id' => null,
                'is_read' => true,
                'read_at' => (clone $now)->subDays(2)->addMinutes(20),
                'created_at' => (clone $now)->subDays(2)->addMinutes(10),
            ]
        );

        // -------------------------------------------------------------------------
        // 4. NOTIFICATIONS
        // -------------------------------------------------------------------------
        Notification::firstOrCreate(
            [
                'user_id' => $buyer1->id,
                'type' => 'ORDER_STATUS_UPDATE',
                'title' => 'Đơn hàng ORD-2026-0006 đã hoàn tất',
            ],
            [
                'body' => 'Đơn hàng của bạn đã được xác nhận hoàn tất thành công. Hãy để lại đánh giá cho người bán nhé!',
                'target_type' => 'ORDER',
                'target_id' => $ord6->id,
                'deep_link_route' => '/orders/ORD-2026-0006',
                'is_read' => true,
                'read_at' => (clone $now)->subDays(2),
                'created_at' => (clone $now)->subDays(2),
            ]
        );

        Notification::firstOrCreate(
            [
                'user_id' => $sellerA->id,
                'type' => 'ESCROW_RELEASED',
                'title' => 'Tiền hàng đã vào ví!',
            ],
            [
                'body' => 'Hệ thống đã giải ngân 500.000đ từ đơn hàng ORD-2026-0006 vào số dư ví của bạn.',
                'target_type' => 'ORDER',
                'target_id' => $ord6->id,
                'deep_link_route' => '/seller/wallet',
                'is_read' => false,
                'read_at' => null,
                'created_at' => (clone $now)->subDays(2),
            ]
        );

        Notification::firstOrCreate(
            [
                'user_id' => $buyer1->id,
                'type' => 'AUCTION_OUTBID',
                'title' => 'Bạn đã bị trả giá cao hơn!',
            ],
            [
                'body' => 'Phiên đấu giá AUC-2026-0001 vừa có người đặt giá cao hơn. Nhấn để nâng giá thầu ngay!',
                'target_type' => 'AUCTION',
                'target_id' => $prd7->id,
                'deep_link_route' => '/auctions/AUC-2026-0001',
                'is_read' => false,
                'read_at' => null,
                'created_at' => (clone $now)->subMinutes(5),
            ]
        );

        // -------------------------------------------------------------------------
        // 5. AUDIT LOGS (Immutable logs by Moderator & Admin)
        // -------------------------------------------------------------------------
        AuditLog::firstOrCreate(
            [
                'actor_id' => $moderator->id,
                'action' => 'PRODUCT_REJECTED',
                'target_type' => 'PRODUCT',
                'target_id' => $prd14->id,
            ],
            [
                'actor_role' => 'moderator',
                'reason' => 'Từ chối sản phẩm do tem mác có dấu hiệu may lại, nghi vấn hàng giả (DEC-05).',
                'old_values' => ['status' => 'PENDING_REVIEW'],
                'new_values' => ['status' => 'REJECTED'],
                'ip_address' => '127.0.0.1',
                'created_at' => (clone $now)->subDays(2),
            ]
        );

        AuditLog::firstOrCreate(
            [
                'actor_id' => $admin->id,
                'action' => 'DISPUTE_PARTIAL_REFUND_VERDICT',
                'target_type' => 'DISPUTE',
                'target_id' => $ord1->id, // target reference
            ],
            [
                'actor_role' => 'admin',
                'reason' => 'Phán quyết phân xử khiếu nại DSP-2026-0002 theo phương án PARTIAL_REFUND.',
                'old_values' => ['status' => 'OPEN', 'escrow_status' => 'HELD'],
                'new_values' => ['status' => 'RESOLVED', 'escrow_status' => 'PARTIALLY_REFUNDED'],
                'ip_address' => '127.0.0.1',
                'created_at' => (clone $now)->subDays(1),
            ]
        );
    }
}
