<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // ========================================================================
        // 1. CHECK CONSTRAINTS - GROUP 1: IDENTITY, TAXONOMY & RBAC GUARDS
        // ========================================================================
        DB::statement("ALTER TABLE users ADD CONSTRAINT chk_users_role CHECK (role IN ('registered_user', 'moderator', 'support', 'admin'));");
        DB::statement("ALTER TABLE users ADD CONSTRAINT chk_users_status CHECK (status IN ('ACTIVE', 'SUSPENDED', 'BANNED'));");
        DB::statement("ALTER TABLE seller_profiles ADD CONSTRAINT chk_seller_wallet_non_negative CHECK (wallet_balance >= 0.00);");
        DB::statement("ALTER TABLE seller_profiles ADD CONSTRAINT chk_seller_escrow_non_negative CHECK (escrow_held_balance >= 0.00);");
        DB::statement("ALTER TABLE categories ADD CONSTRAINT chk_categories_sort_order CHECK (sort_order >= 0);");
        DB::statement("ALTER TABLE platform_settings ADD CONSTRAINT chk_settings_type CHECK (value_type IN ('DECIMAL', 'INTEGER', 'BOOLEAN', 'STRING'));");

        // ========================================================================
        // 2. CHECK CONSTRAINTS - GROUP 2: SECONDHAND PRODUCTS & MODERATION
        // ========================================================================
        DB::statement("ALTER TABLE products ADD CONSTRAINT chk_products_condition CHECK (condition IN ('NEW_WITH_TAGS', 'LIKE_NEW', 'GOOD', 'FAIR', 'VINTAGE_WORN'));");
        DB::statement("ALTER TABLE products ADD CONSTRAINT chk_products_defect_not_empty CHECK (LENGTH(TRIM(defect_info)) > 0);");
        DB::statement("ALTER TABLE products ADD CONSTRAINT chk_products_listing_type CHECK (listing_type IN ('FIXED_PRICE', 'AUCTION'));");
        DB::statement("ALTER TABLE products ADD CONSTRAINT chk_products_price_positive CHECK (price > 0.00);");
        DB::statement("ALTER TABLE products ADD CONSTRAINT chk_products_total_qty CHECK ((listing_type = 'FIXED_PRICE' AND total_quantity >= 1) OR (listing_type = 'AUCTION' AND total_quantity = 1));");
        DB::statement("ALTER TABLE products ADD CONSTRAINT chk_products_avail_qty CHECK (available_quantity >= 0 AND available_quantity <= total_quantity);");
        DB::statement("ALTER TABLE products ADD CONSTRAINT chk_products_verification CHECK (verification_level IN ('UNVERIFIED', 'EVIDENCE_PROVIDED', 'MODERATOR_REVIEWED'));");
        DB::statement("ALTER TABLE products ADD CONSTRAINT chk_products_status CHECK (status IN ('DRAFT', 'PENDING_REVIEW', 'APPROVED', 'REJECTED', 'SOLD', 'HIDDEN', 'ARCHIVED'));");

        DB::statement("ALTER TABLE product_images ADD CONSTRAINT chk_product_images_size CHECK (file_size_bytes IS NULL OR file_size_bytes <= 5242880);");
        DB::statement("ALTER TABLE product_images ADD CONSTRAINT chk_product_images_type CHECK (image_type IN ('GALLERY', 'DEFECT_CLOSEUP', 'AUTHENTICITY_EVIDENCE'));");

        DB::statement("ALTER TABLE product_moderation_logs ADD CONSTRAINT chk_mod_logs_action CHECK (action IN ('SUBMITTED', 'APPROVED', 'REJECTED', 'HIDDEN', 'UNHIDDEN'));");
        DB::statement("ALTER TABLE product_moderation_logs ADD CONSTRAINT chk_mod_logs_mandatory_reason CHECK (action NOT IN ('REJECTED', 'HIDDEN') OR LENGTH(TRIM(COALESCE(reason, ''))) > 0);");

        // ========================================================================
        // 3. CHECK CONSTRAINTS - GROUP 3: SCHEDULED AUCTIONS
        // ========================================================================
        DB::statement("ALTER TABLE auction_sessions ADD CONSTRAINT chk_auction_sessions_time_order CHECK (ends_at > starts_at);");
        DB::statement("ALTER TABLE auction_sessions ADD CONSTRAINT chk_auction_sessions_status CHECK (status IN ('ACTIVE', 'COMPLETED', 'CANCELLED'));");

        DB::statement("ALTER TABLE auctions ADD CONSTRAINT chk_auctions_starting_price CHECK (starting_price > 0.00);");
        DB::statement("ALTER TABLE auctions ADD CONSTRAINT chk_auctions_min_increment CHECK (min_bid_increment > 0.00);");
        DB::statement("ALTER TABLE auctions ADD CONSTRAINT chk_auctions_reserve_price CHECK (reserve_price IS NULL OR reserve_price >= starting_price);");
        DB::statement("ALTER TABLE auctions ADD CONSTRAINT chk_auctions_current_bid CHECK (current_highest_bid = 0.00 OR current_highest_bid >= starting_price);");
        DB::statement("ALTER TABLE auctions ADD CONSTRAINT chk_auctions_time_window CHECK (auction_ends_at > auction_starts_at);");
        DB::statement("ALTER TABLE auctions ADD CONSTRAINT chk_auctions_status CHECK (status IN ('SCHEDULED', 'LIVE', 'COMPLETED', 'ENDED_UNSOLD', 'WINNER_DEFAULTED', 'CANCELLED'));");
        DB::statement("ALTER TABLE auctions ADD CONSTRAINT chk_auctions_no_seller_self_lead CHECK (leading_bidder_id IS NULL OR leading_bidder_id <> seller_id);");
        DB::statement("ALTER TABLE auctions ADD CONSTRAINT chk_auctions_no_seller_self_win CHECK (winner_id IS NULL OR winner_id <> seller_id);");
        DB::statement("ALTER TABLE auctions ADD CONSTRAINT chk_auctions_bid_count CHECK (bid_count >= 0);");
        DB::statement("ALTER TABLE auctions ADD CONSTRAINT chk_auctions_watch_count CHECK (watch_count >= 0);");
        DB::statement("ALTER TABLE auctions ADD CONSTRAINT chk_auctions_extended_count CHECK (extended_count >= 0);");

        DB::statement("ALTER TABLE auction_bids ADD CONSTRAINT chk_auction_bids_amount_positive CHECK (bid_amount > 0.00);");

        // ========================================================================
        // 4. CHECK CONSTRAINTS - GROUP 4: ORDERS, ESCROW & WALLET INVARIANTS
        // ========================================================================
        DB::statement("ALTER TABLE cart_items ADD CONSTRAINT chk_cart_items_qty CHECK (quantity >= 1);");

        DB::statement("ALTER TABLE orders ADD CONSTRAINT chk_orders_source CHECK (order_source IN ('FIXED_PRICE', 'AUCTION'));");
        DB::statement("ALTER TABLE orders ADD CONSTRAINT chk_orders_subtotal_pos CHECK (item_subtotal > 0.00);");
        DB::statement("ALTER TABLE orders ADD CONSTRAINT chk_orders_shipping_zero CHECK (shipping_fee = 0.00);");
        DB::statement("ALTER TABLE orders ADD CONSTRAINT chk_orders_fee_rate CHECK (protection_fee_rate_applied >= 0.0000 AND protection_fee_rate_applied <= 0.2000);");
        DB::statement("ALTER TABLE orders ADD CONSTRAINT chk_orders_fixed_fee CHECK (protection_fixed_fee_applied >= 0.00);");
        DB::statement("ALTER TABLE orders ADD CONSTRAINT chk_orders_protection_fee_non_neg CHECK (buyer_protection_fee >= 0.00);");
        DB::statement("ALTER TABLE orders ADD CONSTRAINT chk_orders_total_equation CHECK (total_amount = item_subtotal + shipping_fee + buyer_protection_fee);");
        DB::statement("ALTER TABLE orders ADD CONSTRAINT chk_orders_seller_net_100_percent CHECK (seller_net_amount = item_subtotal);");
        DB::statement("ALTER TABLE orders ADD CONSTRAINT chk_orders_no_self_purchase CHECK (buyer_id <> seller_id);");
        DB::statement("ALTER TABLE orders ADD CONSTRAINT chk_orders_order_status CHECK (order_status IN ('PENDING_PAYMENT', 'PAID', 'PREPARING', 'SHIPPED', 'DELIVERED', 'COMPLETED', 'CANCELLED', 'REFUNDED'));");
        DB::statement("ALTER TABLE orders ADD CONSTRAINT chk_orders_payment_status CHECK (payment_status IN ('UNPAID', 'PAID', 'FAILED', 'EXPIRED', 'REFUNDED'));");
        DB::statement("ALTER TABLE orders ADD CONSTRAINT chk_orders_escrow_status CHECK (escrow_status IN ('NONE', 'HELD', 'RELEASED', 'REFUNDED', 'PARTIALLY_REFUNDED'));");
        DB::statement("ALTER TABLE orders ADD CONSTRAINT chk_orders_dispute_status CHECK (dispute_status IN ('NONE', 'OPEN', 'NEED_MORE_INFO', 'RESOLVED'));");

        DB::statement("ALTER TABLE order_items ADD CONSTRAINT chk_order_items_price_pos CHECK (unit_price_snapshot > 0.00);");
        DB::statement("ALTER TABLE order_items ADD CONSTRAINT chk_order_items_qty_pos CHECK (quantity >= 1);");
        DB::statement("ALTER TABLE order_items ADD CONSTRAINT chk_order_items_line_total CHECK (line_total = unit_price_snapshot * quantity);");

        DB::statement("ALTER TABLE shipments ADD CONSTRAINT chk_shipments_status CHECK (status IN ('SHIPPED', 'DELIVERED'));");

        DB::statement("ALTER TABLE payments ADD CONSTRAINT chk_payments_amount_pos CHECK (amount > 0.00);");
        DB::statement("ALTER TABLE payments ADD CONSTRAINT chk_payments_status CHECK (status IN ('PENDING', 'PAID', 'FAILED', 'EXPIRED'));");

        DB::statement("ALTER TABLE escrow_transactions ADD CONSTRAINT chk_escrow_tx_type CHECK (transaction_type IN ('HOLD', 'RELEASE', 'FULL_REFUND', 'PARTIAL_REFUND'));");
        DB::statement("ALTER TABLE escrow_transactions ADD CONSTRAINT chk_escrow_gross_pos CHECK (gross_amount > 0.00);");
        DB::statement("ALTER TABLE escrow_transactions ADD CONSTRAINT chk_escrow_subtotal_pos CHECK (item_subtotal_amount > 0.00);");
        DB::statement("ALTER TABLE escrow_transactions ADD CONSTRAINT chk_escrow_fee_non_neg CHECK (buyer_protection_fee_amount >= 0.00);");
        DB::statement("ALTER TABLE escrow_transactions ADD CONSTRAINT chk_escrow_seller_rel_non_neg CHECK (seller_released_amount >= 0.00);");
        DB::statement("ALTER TABLE escrow_transactions ADD CONSTRAINT chk_escrow_buyer_ref_non_neg CHECK (buyer_refunded_amount >= 0.00);");
        DB::statement("ALTER TABLE escrow_transactions ADD CONSTRAINT chk_escrow_plat_fee_non_neg CHECK (platform_fee_retained >= 0.00);");
        DB::statement("ALTER TABLE escrow_transactions ADD CONSTRAINT chk_escrow_accounting_balance CHECK (
            (transaction_type = 'HOLD' AND seller_released_amount = 0.00 AND buyer_refunded_amount = 0.00 AND platform_fee_retained = 0.00) OR
            (transaction_type = 'RELEASE' AND seller_released_amount = item_subtotal_amount AND buyer_refunded_amount = 0.00 AND platform_fee_retained = buyer_protection_fee_amount) OR
            (transaction_type = 'FULL_REFUND' AND buyer_refunded_amount = gross_amount AND seller_released_amount = 0.00 AND platform_fee_retained = 0.00) OR
            (transaction_type = 'PARTIAL_REFUND' AND buyer_refunded_amount > 0.00 AND seller_released_amount > 0.00 AND (buyer_refunded_amount + seller_released_amount = item_subtotal_amount) AND platform_fee_retained = buyer_protection_fee_amount)
        );");

        DB::statement("ALTER TABLE wallet_transactions ADD CONSTRAINT chk_wallet_tx_entry_type CHECK (entry_type IN ('CREDIT'));");
        DB::statement("ALTER TABLE wallet_transactions ADD CONSTRAINT chk_wallet_tx_amount_pos CHECK (amount > 0.00);");
        DB::statement("ALTER TABLE wallet_transactions ADD CONSTRAINT chk_wallet_tx_bal_before CHECK (balance_before >= 0.00);");
        DB::statement("ALTER TABLE wallet_transactions ADD CONSTRAINT chk_wallet_tx_balance_math CHECK (balance_after = balance_before + amount);");

        // ========================================================================
        // 5. CHECK CONSTRAINTS - GROUP 5: DISPUTES, REVIEWS & ENGAGEMENT
        // ========================================================================
        DB::statement("ALTER TABLE disputes ADD CONSTRAINT chk_disputes_opened_status CHECK (opened_at_order_status IN ('SHIPPED', 'DELIVERED'));");
        DB::statement("ALTER TABLE disputes ADD CONSTRAINT chk_disputes_status CHECK (status IN ('OPEN', 'NEED_MORE_INFO', 'RESOLVED'));");
        DB::statement("ALTER TABLE disputes ADD CONSTRAINT chk_disputes_verdict CHECK (admin_verdict IS NULL OR admin_verdict IN ('APPROVE_BUYER_REFUND', 'RELEASE_TO_SELLER', 'PARTIAL_REFUND'));");
        DB::statement("ALTER TABLE disputes ADD CONSTRAINT chk_disputes_partial_amount CHECK (partial_refund_to_buyer IS NULL OR partial_refund_to_buyer > 0.00);");

        DB::statement("ALTER TABLE dispute_evidences ADD CONSTRAINT chk_dispute_ev_role CHECK (uploader_role IN ('BUYER', 'SELLER', 'SUPPORT', 'ADMIN'));");
        DB::statement("ALTER TABLE dispute_evidences ADD CONSTRAINT chk_dispute_ev_type CHECK (evidence_type IN ('BUYER_PROOF', 'SELLER_COUNTER_PROOF', 'STAFF_REQUEST_NOTE'));");

        DB::statement("ALTER TABLE reviews ADD CONSTRAINT chk_reviews_rating_range CHECK (rating >= 1 AND rating <= 5);");
        DB::statement("ALTER TABLE reviews ADD CONSTRAINT chk_reviews_comment_not_empty CHECK (LENGTH(TRIM(comment)) > 0);");
        DB::statement("ALTER TABLE reviews ADD CONSTRAINT chk_reviews_status CHECK (status IN ('VISIBLE', 'HIDDEN'));");
        DB::statement("ALTER TABLE reviews ADD CONSTRAINT chk_reviews_no_self_review CHECK (reviewer_id <> seller_id);");

        DB::statement("ALTER TABLE reports ADD CONSTRAINT chk_reports_target_type CHECK (target_type IN ('PRODUCT', 'USER', 'CONVERSATION'));");
        DB::statement("ALTER TABLE reports ADD CONSTRAINT chk_reports_status CHECK (status IN ('PENDING', 'RESOLVED_ACTION_TAKEN', 'DISMISSED'));");

        DB::statement("ALTER TABLE seller_follows ADD CONSTRAINT chk_no_self_follow CHECK (follower_id <> seller_id);");
        DB::statement("ALTER TABLE conversations ADD CONSTRAINT chk_conversation_user_order CHECK (user_one_id < user_two_id);");
        DB::statement("ALTER TABLE messages ADD CONSTRAINT chk_messages_not_empty CHECK (LENGTH(TRIM(message_text)) > 0);");

        // ========================================================================
        // 6. PARTIAL UNIQUE INDEXES & PERFORMANCE INDEXES
        // ========================================================================
        // Partial Unique Indexes
        DB::statement("CREATE UNIQUE INDEX uq_auctions_active_product ON auctions(product_id) WHERE status IN ('SCHEDULED', 'LIVE');");
        DB::statement("CREATE UNIQUE INDEX uq_payments_one_paid_per_order ON payments(order_id) WHERE status = 'PAID';");

        // Partial Performance Indexes
        DB::statement("CREATE INDEX idx_orders_unpaid_expiry ON orders(order_status, payment_status, payment_expires_at ASC) WHERE order_status = 'PENDING_PAYMENT';");
        DB::statement("CREATE INDEX idx_orders_auto_complete ON orders(order_status, dispute_status, auto_complete_at ASC) WHERE order_status = 'DELIVERED' AND dispute_status = 'NONE';");

        // Catalog & Auction Performance Indexes
        DB::statement("CREATE INDEX idx_products_public_discovery ON products(status, listing_type, category_id, condition, price, created_at DESC);");
        DB::statement("CREATE INDEX idx_products_seller_status ON products(seller_id, status, updated_at DESC);");
        DB::statement("CREATE INDEX idx_product_images_product_sort ON product_images(product_id, is_primary DESC, sort_order ASC);");
        DB::statement("CREATE INDEX idx_mod_logs_product_time ON product_moderation_logs(product_id, created_at DESC);");
        DB::statement("CREATE INDEX idx_audit_logs_target ON audit_logs(target_type, target_id, created_at DESC);");
        DB::statement("CREATE INDEX idx_audit_logs_actor ON audit_logs(actor_id, created_at DESC);");
        DB::statement("CREATE INDEX idx_auctions_status_ends_at ON auctions(status, auction_ends_at ASC);");
        DB::statement("CREATE INDEX idx_auctions_status_starts_at ON auctions(status, auction_starts_at ASC);");
        DB::statement("CREATE INDEX idx_auctions_leading_bidder ON auctions(leading_bidder_id, status);");
        DB::statement("CREATE INDEX idx_auctions_winner ON auctions(winner_id, status);");
        DB::statement("CREATE INDEX idx_auction_bids_auction_amount ON auction_bids(auction_id, bid_amount DESC, created_at ASC);");
        DB::statement("CREATE INDEX idx_auction_bids_bidder_history ON auction_bids(bidder_id, created_at DESC);");
        DB::statement("CREATE INDEX idx_auction_watches_user ON auction_watches(user_id, created_at DESC);");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Drop Indexes
        DB::statement("DROP INDEX IF EXISTS idx_auction_watches_user;");
        DB::statement("DROP INDEX IF EXISTS idx_auction_bids_bidder_history;");
        DB::statement("DROP INDEX IF EXISTS idx_auction_bids_auction_amount;");
        DB::statement("DROP INDEX IF EXISTS idx_auctions_winner;");
        DB::statement("DROP INDEX IF EXISTS idx_auctions_leading_bidder;");
        DB::statement("DROP INDEX IF EXISTS idx_auctions_status_starts_at;");
        DB::statement("DROP INDEX IF EXISTS idx_auctions_status_ends_at;");
        DB::statement("DROP INDEX IF EXISTS idx_audit_logs_actor;");
        DB::statement("DROP INDEX IF EXISTS idx_audit_logs_target;");
        DB::statement("DROP INDEX IF EXISTS idx_mod_logs_product_time;");
        DB::statement("DROP INDEX IF EXISTS idx_product_images_product_sort;");
        DB::statement("DROP INDEX IF EXISTS idx_products_seller_status;");
        DB::statement("DROP INDEX IF EXISTS idx_products_public_discovery;");
        DB::statement("DROP INDEX IF EXISTS idx_orders_auto_complete;");
        DB::statement("DROP INDEX IF EXISTS idx_orders_unpaid_expiry;");
        DB::statement("DROP INDEX IF EXISTS uq_payments_one_paid_per_order;");
        DB::statement("DROP INDEX IF EXISTS uq_auctions_active_product;");

        // Drop Constraints
        $constraints = [
            'users' => ['chk_users_role', 'chk_users_status'],
            'seller_profiles' => ['chk_seller_wallet_non_negative', 'chk_seller_escrow_non_negative'],
            'categories' => ['chk_categories_sort_order'],
            'platform_settings' => ['chk_settings_type'],
            'products' => [
                'chk_products_condition', 'chk_products_defect_not_empty', 'chk_products_listing_type',
                'chk_products_price_positive', 'chk_products_total_qty', 'chk_products_avail_qty',
                'chk_products_verification', 'chk_products_status',
            ],
            'product_images' => ['chk_product_images_size', 'chk_product_images_type'],
            'product_moderation_logs' => ['chk_mod_logs_action', 'chk_mod_logs_mandatory_reason'],
            'auction_sessions' => ['chk_auction_sessions_time_order', 'chk_auction_sessions_status'],
            'auctions' => [
                'chk_auctions_starting_price', 'chk_auctions_min_increment', 'chk_auctions_reserve_price',
                'chk_auctions_current_bid', 'chk_auctions_time_window', 'chk_auctions_status',
                'chk_auctions_no_seller_self_lead', 'chk_auctions_no_seller_self_win',
                'chk_auctions_bid_count', 'chk_auctions_watch_count', 'chk_auctions_extended_count',
            ],
            'auction_bids' => ['chk_auction_bids_amount_positive'],
            'cart_items' => ['chk_cart_items_qty'],
            'orders' => [
                'chk_orders_source', 'chk_orders_subtotal_pos', 'chk_orders_shipping_zero',
                'chk_orders_fee_rate', 'chk_orders_fixed_fee', 'chk_orders_protection_fee_non_neg',
                'chk_orders_total_equation', 'chk_orders_seller_net_100_percent', 'chk_orders_no_self_purchase',
                'chk_orders_order_status', 'chk_orders_payment_status', 'chk_orders_escrow_status',
                'chk_orders_dispute_status',
            ],
            'order_items' => ['chk_order_items_price_pos', 'chk_order_items_qty_pos', 'chk_order_items_line_total'],
            'shipments' => ['chk_shipments_status'],
            'payments' => ['chk_payments_amount_pos', 'chk_payments_status'],
            'escrow_transactions' => [
                'chk_escrow_tx_type', 'chk_escrow_gross_pos', 'chk_escrow_subtotal_pos',
                'chk_escrow_fee_non_neg', 'chk_escrow_seller_rel_non_neg', 'chk_escrow_buyer_ref_non_neg',
                'chk_escrow_plat_fee_non_neg', 'chk_escrow_accounting_balance',
            ],
            'wallet_transactions' => [
                'chk_wallet_tx_entry_type', 'chk_wallet_tx_amount_pos', 'chk_wallet_tx_bal_before',
                'chk_wallet_tx_balance_math',
            ],
            'disputes' => [
                'chk_disputes_opened_status', 'chk_disputes_status', 'chk_disputes_verdict',
                'chk_disputes_partial_amount',
            ],
            'dispute_evidences' => ['chk_dispute_ev_role', 'chk_dispute_ev_type'],
            'reviews' => ['chk_reviews_rating_range', 'chk_reviews_comment_not_empty', 'chk_reviews_status', 'chk_reviews_no_self_review'],
            'reports' => ['chk_reports_target_type', 'chk_reports_status'],
            'seller_follows' => ['chk_no_self_follow'],
            'conversations' => ['chk_conversation_user_order'],
            'messages' => ['chk_messages_not_empty'],
        ];

        foreach ($constraints as $table => $constraintList) {
            foreach ($constraintList as $constraint) {
                DB::statement("ALTER TABLE {$table} DROP CONSTRAINT IF EXISTS {$constraint};");
            }
        }
    }
};
