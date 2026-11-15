<?php

namespace Tests\Feature\Api\V1;

use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Enums\ProductStatus;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\Category;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\Notification;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\Review;
use App\Models\SellerProfile;
use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class ChatNotificationAndEngagementTest extends TestCase
{
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
            'review_count' => 0,
            'average_rating' => 5.00,
            'completed_orders_count' => 0,
            'dispute_lost_count' => 0,
        ]);

        return $user;
    }

    protected function createIsolatedProduct(User $seller, float $price = 150000.00): Product
    {
        $unique = 'prd_eng_' . bin2hex(random_bytes(5));
        $category = Category::first() ?? Category::create([
            'name' => 'Thời trang Vintage',
            'slug' => 'vintage-' . bin2hex(random_bytes(3)),
        ]);

        return Product::create([
            'product_code' => 'PRD-' . strtoupper($unique),
            'seller_id' => $seller->id,
            'category_id' => $category->id,
            'title' => 'Sản phẩm ' . $unique,
            'slug' => 'slug-' . $unique,
            'description' => 'Mô tả chi tiết sản phẩm vintage test',
            'condition' => 'LIKE_NEW',
            'defect_info' => 'Không lỗi',
            'listing_type' => 'FIXED_PRICE',
            'price' => $price,
            'original_price' => $price * 1.2,
            'available_quantity' => 5,
            'total_quantity' => 5,
            'favorite_count' => 0,
            'status' => ProductStatus::APPROVED,
        ]);
    }

    protected function cleanUpUser(int $userId): void
    {
        DB::table('notifications')->where('user_id', $userId)->delete();
        DB::table('reports')->where('reporter_id', $userId)->delete();
        DB::table('favorites')->where('user_id', $userId)->delete();
        DB::table('seller_follows')->where('follower_id', $userId)->orWhere('seller_id', $userId)->delete();
        DB::table('reviews')->where('reviewer_id', $userId)->orWhere('seller_id', $userId)->delete();

        // Conversations and messages
        $convIds = DB::table('conversations')
            ->where('user_one_id', $userId)
            ->orWhere('user_two_id', $userId)
            ->pluck('id')
            ->toArray();

        if (! empty($convIds)) {
            DB::table('messages')->whereIn('conversation_id', $convIds)->delete();
            DB::table('conversations')->whereIn('id', $convIds)->delete();
        }

        DB::table('seller_profiles')->where('user_id', $userId)->delete();
        DB::table('user_profiles')->where('user_id', $userId)->delete();
        DB::table('users')->where('id', $userId)->delete();
    }

    protected function cleanUpOrder(int $orderId): void
    {
        DB::table('reviews')->where('order_id', $orderId)->delete();
        DB::table('order_items')->where('order_id', $orderId)->delete();
        DB::table('orders')->where('id', $orderId)->delete();
    }

    /**
     * 1. Test toggle favorite product and list favorites syncs favorite_count.
     */
    public function test_toggle_favorite_product_and_list_favorites_syncs_favorite_count(): void
    {
        $seller = null;
        $user = null;
        $product = null;

        try {
            $seller = $this->createIsolatedUser('fav_seller');
            $user = $this->createIsolatedUser('fav_user');
            $product = $this->createIsolatedProduct($seller, 200000.00);

            $this->assertEquals(0, $product->favorite_count);

            // Add to favorites
            $res1 = $this->actingAs($user)->postJson("/api/v1/products/{$product->id}/favorite");
            $res1->assertStatus(200);
            $res1->assertJsonPath('data.is_favorited', true);
            $res1->assertJsonPath('data.favorite_count', 1);

            $product->refresh();
            $this->assertEquals(1, $product->favorite_count);

            // List favorites
            $listRes = $this->actingAs($user)->getJson('/api/v1/profile/favorites');
            $listRes->assertStatus(200);
            $listRes->assertJsonFragment(['id' => $product->id]);

            // Remove from favorites
            $res2 = $this->actingAs($user)->postJson("/api/v1/products/{$product->id}/favorite");
            $res2->assertStatus(200);
            $res2->assertJsonPath('data.is_favorited', false);
            $res2->assertJsonPath('data.favorite_count', 0);

            $product->refresh();
            $this->assertEquals(0, $product->favorite_count);
        } finally {
            if ($product) {
                DB::table('favorites')->where('product_id', $product->id)->delete();
                $product->delete();
            }
            if ($user) {
                $this->cleanUpUser($user->id);
            }
            if ($seller) {
                $this->cleanUpUser($seller->id);
            }
        }
    }

    /**
     * 2. Test toggle follow seller succeeds and blocks self-follow with 403 (BR-AC-02).
     */
    public function test_toggle_follow_seller_succeeds_and_blocks_self_follow_with_403_br_ac_02(): void
    {
        $follower = null;
        $seller = null;

        try {
            $follower = $this->createIsolatedUser('flw_buyer');
            $seller = $this->createIsolatedUser('flw_seller');

            // Attempt self-follow -> 403
            $selfRes = $this->actingAs($follower)->postJson("/api/v1/sellers/{$follower->id}/follow");
            $selfRes->assertStatus(403);
            $selfRes->assertJsonPath('error_code', 'SELF_TRANSACTION_FORBIDDEN');

            // Follow seller -> 200
            $followRes = $this->actingAs($follower)->postJson("/api/v1/sellers/{$seller->id}/follow");
            $followRes->assertStatus(200);
            $followRes->assertJsonPath('data.is_following', true);
            $followRes->assertJsonPath('data.followers_count', 1);

            // Unfollow seller -> 200
            $unfollowRes = $this->actingAs($follower)->postJson("/api/v1/sellers/{$seller->id}/follow");
            $unfollowRes->assertStatus(200);
            $unfollowRes->assertJsonPath('data.is_following', false);
            $unfollowRes->assertJsonPath('data.followers_count', 0);
        } finally {
            if ($follower) {
                $this->cleanUpUser($follower->id);
            }
            if ($seller) {
                $this->cleanUpUser($seller->id);
            }
        }
    }

    /**
     * 3. Test verified review succeeds for completed order and recalculates seller average rating (BR-RV-01).
     */
    public function test_verified_review_succeeds_for_completed_order_and_recalculates_seller_average_rating_br_rv_01(): void
    {
        $seller = null;
        $buyer = null;
        $product = null;
        $order = null;

        try {
            $seller = $this->createIsolatedUser('rev_seller');
            $buyer = $this->createIsolatedUser('rev_buyer');
            $product = $this->createIsolatedProduct($seller, 300000.00);

            $order = Order::create([
                'order_code' => 'ORD-REV-' . time() . '-' . rand(100, 999),
                'buyer_id' => $buyer->id,
                'seller_id' => $seller->id,
                'order_source' => 'FIXED_PRICE',
                'order_status' => OrderStatus::COMPLETED,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => 'RELEASED',
                'dispute_status' => 'NONE',
                'item_subtotal' => 300000.00,
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => 0.0600,
                'protection_fixed_fee_applied' => 7000.00,
                'buyer_protection_fee' => 25000.00,
                'total_amount' => 325000.00,
                'seller_net_amount' => 300000.00,
                'payment_expires_at' => now()->addMinutes(30),
                'paid_at' => now()->subHours(2),
                'shipping_address_snapshot' => [
                    'recipient_name' => 'Người mua test',
                    'phone' => '0901234567',
                    'province' => 'TP. Hồ Chí Minh',
                    'district' => 'Quận 1',
                    'ward' => 'Bến Nghé',
                    'detailed_address' => '123 Đồng Khởi',
                ],
                'completed_at' => now(),
            ]);

            OrderItem::create([
                'order_id' => $order->id,
                'product_id' => $product->id,
                'product_code_snapshot' => $product->product_code,
                'product_title_snapshot' => $product->title,
                'unit_price_snapshot' => 300000.00,
                'quantity' => 1,
                'line_total' => 300000.00,
                'condition_snapshot' => 'LIKE_NEW',
                'defect_info_snapshot' => 'Không lỗi',
                'primary_image_snapshot' => 'https://izithrift.local/storage/sample.jpg',
            ]);

            // Submit verified review (5 stars)
            $res = $this->actingAs($buyer)->postJson("/api/v1/orders/{$order->id}/reviews", [
                'rating' => 5,
                'comment' => 'Sản phẩm vintage tuyệt vời, vải đẹp và thơm!',
            ]);

            $res->assertStatus(201);
            $res->assertJsonPath('data.rating', 5);
            $res->assertJsonPath('data.comment', 'Sản phẩm vintage tuyệt vời, vải đẹp và thơm!');

            // Verify seller rating recalculation
            $sellerProfile = SellerProfile::where('user_id', $seller->id)->first();
            $this->assertEquals(1, $sellerProfile->review_count);
            $this->assertEquals(5.00, (float) $sellerProfile->average_rating);

            // Verify notification sent to seller
            $notif = Notification::where('user_id', $seller->id)
                ->where('type', 'NEW_REVIEW_RECEIVED')
                ->first();
            $this->assertNotNull($notif);
            $this->assertEquals('REVIEW', $notif->target_type);
        } finally {
            if ($order) {
                $this->cleanUpOrder($order->id);
            }
            if ($product) {
                $product->delete();
            }
            if ($buyer) {
                $this->cleanUpUser($buyer->id);
            }
            if ($seller) {
                $this->cleanUpUser($seller->id);
            }
        }
    }

    /**
     * 4. Test buyer cannot review uncompleted order or submit duplicate review returns 409.
     */
    public function test_buyer_cannot_review_uncompleted_order_or_submit_duplicate_review_returns_409(): void
    {
        $seller = null;
        $buyer = null;
        $product = null;
        $order = null;

        try {
            $seller = $this->createIsolatedUser('unrev_seller');
            $buyer = $this->createIsolatedUser('unrev_buyer');
            $product = $this->createIsolatedProduct($seller, 250000.00);

            // Create order at SHIPPED status (not yet completed)
            $order = Order::create([
                'order_code' => 'ORD-UNREV-' . time() . '-' . rand(100, 999),
                'buyer_id' => $buyer->id,
                'seller_id' => $seller->id,
                'order_source' => 'FIXED_PRICE',
                'order_status' => OrderStatus::SHIPPED,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => 'HELD',
                'dispute_status' => 'NONE',
                'item_subtotal' => 250000.00,
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => 0.0600,
                'protection_fixed_fee_applied' => 7000.00,
                'buyer_protection_fee' => 22000.00,
                'total_amount' => 272000.00,
                'seller_net_amount' => 250000.00,
                'payment_expires_at' => now()->addMinutes(30),
                'paid_at' => now()->subHours(1),
                'shipping_address_snapshot' => [
                    'recipient_name' => 'Test Reviewer',
                    'phone' => '0901234567',
                    'province' => 'Hà Nội',
                    'district' => 'Hoàn Kiếm',
                    'ward' => 'Hàng Bạc',
                    'detailed_address' => '45 Hàng Bạc',
                ],
            ]);

            OrderItem::create([
                'order_id' => $order->id,
                'product_id' => $product->id,
                'product_code_snapshot' => $product->product_code,
                'product_title_snapshot' => $product->title,
                'unit_price_snapshot' => 250000.00,
                'quantity' => 1,
                'line_total' => 250000.00,
                'condition_snapshot' => 'LIKE_NEW',
                'defect_info_snapshot' => 'Không lỗi',
                'primary_image_snapshot' => 'https://izithrift.local/storage/sample.jpg',
            ]);

            // Attempt review on uncompleted order -> 409
            $resUncompleted = $this->actingAs($buyer)->postJson("/api/v1/orders/{$order->id}/reviews", [
                'rating' => 4,
                'comment' => 'Chưa nhận hàng nhưng thử đánh giá',
            ]);
            $resUncompleted->assertStatus(409);
            $this->assertStringContainsString('BR-RV-01', $resUncompleted->json('message'));

            // Complete order
            $order->update(['order_status' => OrderStatus::COMPLETED, 'completed_at' => now()]);

            // First review -> 201
            $resFirst = $this->actingAs($buyer)->postJson("/api/v1/orders/{$order->id}/reviews", [
                'rating' => 4,
                'comment' => 'Hàng đẹp đúng như mô tả!',
            ]);
            $resFirst->assertStatus(201);

            // Duplicate review attempt -> 409
            $resDup = $this->actingAs($buyer)->postJson("/api/v1/orders/{$order->id}/reviews", [
                'rating' => 5,
                'comment' => 'Đánh giá lần hai không được phép',
            ]);
            $resDup->assertStatus(409);
            $this->assertStringContainsString('đã được đánh giá', $resDup->json('message'));
        } finally {
            if ($order) {
                $this->cleanUpOrder($order->id);
            }
            if ($product) {
                $product->delete();
            }
            if ($buyer) {
                $this->cleanUpUser($buyer->id);
            }
            if ($seller) {
                $this->cleanUpUser($seller->id);
            }
        }
    }

    /**
     * 5. Test chat conversation normalizes participant order and blocks self chat (OQ-P6-03).
     */
    public function test_chat_conversation_normalizes_participant_order_and_blocks_self_chat_oq_p6_03(): void
    {
        $userA = null;
        $userB = null;

        try {
            $userA = $this->createIsolatedUser('chat_a');
            $userB = $this->createIsolatedUser('chat_b');

            // Self-chat attempt -> 403
            $selfRes = $this->actingAs($userA)->postJson('/api/v1/conversations', [
                'recipient_id' => $userA->id,
            ]);
            $selfRes->assertStatus(403);
            $selfRes->assertJsonPath('error_code', 'SELF_TRANSACTION_FORBIDDEN');

            // User A starts conversation with User B
            $res1 = $this->actingAs($userA)->postJson('/api/v1/conversations', [
                'recipient_id' => $userB->id,
                'initial_message' => 'Xin chào shop, món này còn không?',
            ]);
            $res1->assertStatus(201);
            $convId1 = $res1->json('data.id');

            $conv = Conversation::findOrFail($convId1);
            $this->assertLessThan($conv->user_two_id, $conv->user_one_id);

            // User B calls start conversation with User A -> returns existing conversation
            $res2 = $this->actingAs($userB)->postJson('/api/v1/conversations', [
                'recipient_id' => $userA->id,
            ]);
            $res2->assertStatus(201);
            $this->assertEquals($convId1, $res2->json('data.id'));
        } finally {
            if ($userA) {
                $this->cleanUpUser($userA->id);
            }
            if ($userB) {
                $this->cleanUpUser($userB->id);
            }
        }
    }

    /**
     * 6. Test chat incremental HTTP polling with after_id returns only new messages and marks as read (ADR-08).
     */
    public function test_chat_incremental_http_polling_with_after_id_returns_only_new_messages_and_marks_as_read_adr_08(): void
    {
        $userA = null;
        $userB = null;

        try {
            $userA = $this->createIsolatedUser('poll_a');
            $userB = $this->createIsolatedUser('poll_b');

            [$u1, $u2] = Conversation::normalizeParticipants($userA->id, $userB->id);
            $conv = Conversation::create([
                'user_one_id' => $u1,
                'user_two_id' => $u2,
            ]);

            // User A sends 3 messages
            $m1 = Message::create([
                'conversation_id' => $conv->id,
                'sender_id' => $userA->id,
                'message_text' => 'Tin nhắn số 1',
                'is_read' => false,
            ]);
            $m2 = Message::create([
                'conversation_id' => $conv->id,
                'sender_id' => $userA->id,
                'message_text' => 'Tin nhắn số 2',
                'is_read' => false,
            ]);
            $m3 = Message::create([
                'conversation_id' => $conv->id,
                'sender_id' => $userA->id,
                'message_text' => 'Tin nhắn số 3',
                'is_read' => false,
            ]);

            // User B polls without after_id -> gets all 3 messages
            $pollAll = $this->actingAs($userB)->getJson("/api/v1/conversations/{$conv->id}/messages");
            $pollAll->assertStatus(200);
            $this->assertCount(3, $pollAll->json('data.messages'));

            // Verify all 3 messages are now read
            $m1->refresh();
            $m2->refresh();
            $m3->refresh();
            $this->assertTrue($m1->is_read);
            $this->assertTrue($m2->is_read);
            $this->assertTrue($m3->is_read);

            // User A sends message 4
            $m4 = Message::create([
                'conversation_id' => $conv->id,
                'sender_id' => $userA->id,
                'message_text' => 'Tin nhắn mới số 4',
                'is_read' => false,
            ]);

            // User B polls incrementally with after_id = m3->id -> receives only message 4
            $pollIncr = $this->actingAs($userB)->getJson("/api/v1/conversations/{$conv->id}/messages?after_id={$m3->id}");
            $pollIncr->assertStatus(200);
            $this->assertCount(1, $pollIncr->json('data.messages'));
            $this->assertEquals($m4->id, $pollIncr->json('data.messages.0.id'));
            $this->assertEquals('Tin nhắn mới số 4', $pollIncr->json('data.messages.0.message_text'));
        } finally {
            if ($userA) {
                $this->cleanUpUser($userA->id);
            }
            if ($userB) {
                $this->cleanUpUser($userB->id);
            }
        }
    }

    /**
     * 7. Test non-participant cannot read or send chat messages returns 403.
     */
    public function test_non_participant_cannot_read_or_send_chat_messages_returns_403(): void
    {
        $userA = null;
        $userB = null;
        $userC = null;

        try {
            $userA = $this->createIsolatedUser('priv_a');
            $userB = $this->createIsolatedUser('priv_b');
            $userC = $this->createIsolatedUser('priv_c');

            [$u1, $u2] = Conversation::normalizeParticipants($userA->id, $userB->id);
            $conv = Conversation::create([
                'user_one_id' => $u1,
                'user_two_id' => $u2,
            ]);

            // User C tries to read messages -> 403
            $readRes = $this->actingAs($userC)->getJson("/api/v1/conversations/{$conv->id}/messages");
            $readRes->assertStatus(403);
            $readRes->assertJsonPath('error_code', 'ROLE_PERMISSION_DENIED');

            // User C tries to send message -> 403
            $sendRes = $this->actingAs($userC)->postJson("/api/v1/conversations/{$conv->id}/messages", [
                'message_text' => 'Tôi muốn xen vào cuộc nói chuyện này!',
            ]);
            $sendRes->assertStatus(403);
            $sendRes->assertJsonPath('error_code', 'ROLE_PERMISSION_DENIED');
        } finally {
            if ($userA) {
                $this->cleanUpUser($userA->id);
            }
            if ($userB) {
                $this->cleanUpUser($userB->id);
            }
            if ($userC) {
                $this->cleanUpUser($userC->id);
            }
        }
    }

    /**
     * 8. Test submit violation report with block conversation flag prevents further messages with 409 and notifications read flow.
     */
    public function test_submit_violation_report_with_block_conversation_flag_prevents_further_messages_with_409_and_notifications_read_flow(): void
    {
        $userA = null;
        $userB = null;

        try {
            $userA = $this->createIsolatedUser('rep_a');
            $userB = $this->createIsolatedUser('rep_b');

            [$u1, $u2] = Conversation::normalizeParticipants($userA->id, $userB->id);
            $conv = Conversation::create([
                'user_one_id' => $u1,
                'user_two_id' => $u2,
            ]);

            // User A reports conversation and blocks User B
            $repRes = $this->actingAs($userA)->postJson('/api/v1/reports', [
                'target_type' => 'CONVERSATION',
                'target_id' => $conv->id,
                'reason_category' => 'HARASSMENT',
                'description' => 'Người dùng này có lời lẽ xúc phạm và quấy rối liên tục.',
                'block_conversation' => true,
            ]);
            $repRes->assertStatus(201);
            $repRes->assertJsonPath('data.target_type', 'CONVERSATION');

            $conv->refresh();
            $this->assertEquals($userA->id, $conv->blocked_by_user_id);

            // User B tries to send message -> 409 blocked
            $sendRes = $this->actingAs($userB)->postJson("/api/v1/conversations/{$conv->id}/messages", [
                'message_text' => 'Alo shop ơi sao không trả lời?',
            ]);
            $sendRes->assertStatus(409);
            $this->assertStringContainsString('bị chặn', $sendRes->json('message'));

            // Test Notifications list and read flow
            $notif1 = Notification::create([
                'user_id' => $userA->id,
                'type' => 'SYSTEM_ALERT',
                'title' => 'Cập nhật hệ thống',
                'body' => 'Bản cập nhật mùa lễ hội đã sẵn sàng.',
                'target_type' => 'SYSTEM',
                'target_id' => 1,
                'deep_link_route' => '/settings',
                'is_read' => false,
            ]);

            $notif2 = Notification::create([
                'user_id' => $userA->id,
                'type' => 'ORDER_SHIPPED',
                'title' => 'Đơn hàng đang giao',
                'body' => 'Đơn hàng của bạn đã được giao cho đơn vị vận chuyển.',
                'target_type' => 'ORDER',
                'target_id' => 10,
                'deep_link_route' => '/orders/10',
                'is_read' => false,
            ]);

            // List notifications
            $listRes = $this->actingAs($userA)->getJson('/api/v1/notifications');
            $listRes->assertStatus(200);
            $listRes->assertJsonPath('unread_count', 2);

            // Mark single notification as read
            $read1Res = $this->actingAs($userA)->postJson("/api/v1/notifications/{$notif1->id}/read");
            $read1Res->assertStatus(200);
            $read1Res->assertJsonPath('data.is_read', true);

            // Mark all as read
            $readAllRes = $this->actingAs($userA)->postJson('/api/v1/notifications/read-all');
            $readAllRes->assertStatus(200);

            // Verify unread count is now 0
            $afterListRes = $this->actingAs($userA)->getJson('/api/v1/notifications');
            $afterListRes->assertStatus(200);
            $afterListRes->assertJsonPath('unread_count', 0);
        } finally {
            if ($userA) {
                $this->cleanUpUser($userA->id);
            }
            if ($userB) {
                $this->cleanUpUser($userB->id);
            }
        }
    }
}
