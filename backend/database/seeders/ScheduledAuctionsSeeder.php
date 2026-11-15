<?php

namespace Database\Seeders;

use App\Enums\AuctionStatus;
use App\Models\Auction;
use App\Models\AuctionBid;
use App\Models\AuctionSession;
use App\Models\AuctionWatch;
use App\Models\Product;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;

class ScheduledAuctionsSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $admin = User::where('email', 'admin@izithrift.local')->firstOrFail();
        $sellerA = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();
        $sellerB = User::where('email', 'retrolab.sg@izithrift.local')->firstOrFail();
        $sellerC = User::where('email', 'tiemnhamay@izithrift.local')->firstOrFail();
        $buyer1 = User::where('email', 'buyer.linh@izithrift.local')->firstOrFail();
        $buyer2 = User::where('email', 'buyer.kiet@izithrift.local')->firstOrFail();
        $buyer3 = User::where('email', 'buyer.ha@izithrift.local')->firstOrFail();

        $now = Carbon::now();

        // -------------------------------------------------------------------------
        // 1. AUCTION SESSIONS (3 Sessions)
        // -------------------------------------------------------------------------
        $session1 = AuctionSession::updateOrCreate(
            ['session_code' => 'SESS-2026-0001'],
            [
                'title' => 'Phiên Đấu Giá Retro Cuối Tuần - Sáng Thứ Bảy',
                'starts_at' => (clone $now)->subHours(2),
                'ends_at' => (clone $now)->addHours(4),
                'default_min_increment' => 50000.00,
                'status' => 'ACTIVE',
                'created_by' => $admin->id,
            ]
        );

        $session2 = AuctionSession::updateOrCreate(
            ['session_code' => 'SESS-2026-0002'],
            [
                'title' => 'Phiên Đêm Đồng Hồ & Máy Ảnh Cổ Điển',
                'starts_at' => (clone $now)->addHours(2),
                'ends_at' => (clone $now)->addHours(6),
                'default_min_increment' => 50000.00,
                'status' => 'ACTIVE',
                'created_by' => $admin->id,
            ]
        );

        $session3 = AuctionSession::updateOrCreate(
            ['session_code' => 'SESS-2026-0003'],
            [
                'title' => 'Phiên Đặc Biệt Giáng Sinh Ấm Áp',
                'starts_at' => (clone $now)->subDays(1),
                'ends_at' => (clone $now)->subHours(2),
                'default_min_increment' => 30000.00,
                'status' => 'ACTIVE',
                'created_by' => $admin->id,
            ]
        );

        // Fetch products
        $prd7 = Product::where('product_code', 'PRD-2026-0007')->firstOrFail();
        $prd8 = Product::where('product_code', 'PRD-2026-0008')->firstOrFail();
        $prd9 = Product::where('product_code', 'PRD-2026-0009')->firstOrFail();
        $prd10 = Product::where('product_code', 'PRD-2026-0010')->firstOrFail();
        $prd11 = Product::where('product_code', 'PRD-2026-0011')->firstOrFail();

        // -------------------------------------------------------------------------
        // 2. AUCTIONS (6 Auctions with full state coverage)
        // -------------------------------------------------------------------------

        // AUC-2026-0001: LIVE - Active with 3 bids
        $auc1 = Auction::updateOrCreate(
            ['auction_code' => 'AUC-2026-0001'],
            [
                'product_id' => $prd7->id,
                'seller_id' => $sellerB->id,
                'session_id' => $session1->id,
                'starting_price' => 800000.00,
                'min_bid_increment' => 50000.00,
                'reserve_price' => 900000.00,
                'current_highest_bid' => 950000.00,
                'leading_bidder_id' => $buyer1->id,
                'winner_id' => null,
                'bid_count' => 3,
                'watch_count' => 2,
                'auction_starts_at' => (clone $now)->subMinutes(30),
                'auction_ends_at' => (clone $now)->addMinutes(45),
                'extended_count' => 0,
                'status' => AuctionStatus::LIVE,
            ]
        );

        AuctionBid::firstOrCreate(
            ['auction_id' => $auc1->id, 'bidder_id' => $buyer2->id, 'bid_amount' => 800000.00],
            ['previous_highest_bid' => 0.00, 'triggered_anti_sniping' => false, 'created_at' => (clone $now)->subMinutes(25)]
        );
        AuctionBid::firstOrCreate(
            ['auction_id' => $auc1->id, 'bidder_id' => $buyer3->id, 'bid_amount' => 850000.00],
            ['previous_highest_bid' => 800000.00, 'triggered_anti_sniping' => false, 'created_at' => (clone $now)->subMinutes(15)]
        );
        AuctionBid::firstOrCreate(
            ['auction_id' => $auc1->id, 'bidder_id' => $buyer1->id, 'bid_amount' => 950000.00],
            ['previous_highest_bid' => 850000.00, 'triggered_anti_sniping' => false, 'created_at' => (clone $now)->subMinutes(5)]
        );

        AuctionWatch::firstOrCreate(['auction_id' => $auc1->id, 'user_id' => $buyer1->id]);
        AuctionWatch::firstOrCreate(['auction_id' => $auc1->id, 'user_id' => $buyer2->id]);

        // AUC-2026-0002: LIVE - Ending soon (+90s) for Anti-Sniping testing
        $auc2 = Auction::updateOrCreate(
            ['auction_code' => 'AUC-2026-0002'],
            [
                'product_id' => $prd8->id,
                'seller_id' => $sellerB->id,
                'session_id' => $session1->id,
                'starting_price' => 600000.00,
                'min_bid_increment' => 50000.00,
                'reserve_price' => 700000.00,
                'current_highest_bid' => 750000.00,
                'leading_bidder_id' => $buyer2->id,
                'winner_id' => null,
                'bid_count' => 2,
                'watch_count' => 1,
                'auction_starts_at' => (clone $now)->subMinutes(50),
                'auction_ends_at' => (clone $now)->addSeconds(90),
                'extended_count' => 0,
                'status' => AuctionStatus::LIVE,
            ]
        );

        AuctionBid::firstOrCreate(
            ['auction_id' => $auc2->id, 'bidder_id' => $buyer1->id, 'bid_amount' => 600000.00],
            ['previous_highest_bid' => 0.00, 'triggered_anti_sniping' => false, 'created_at' => (clone $now)->subMinutes(30)]
        );
        AuctionBid::firstOrCreate(
            ['auction_id' => $auc2->id, 'bidder_id' => $buyer2->id, 'bid_amount' => 750000.00],
            ['previous_highest_bid' => 600000.00, 'triggered_anti_sniping' => false, 'created_at' => (clone $now)->subMinutes(10)]
        );

        AuctionWatch::firstOrCreate(['auction_id' => $auc2->id, 'user_id' => $buyer2->id]);

        // AUC-2026-0003: SCHEDULED - Upcoming session
        $auc3 = Auction::updateOrCreate(
            ['auction_code' => 'AUC-2026-0003'],
            [
                'product_id' => $prd9->id,
                'seller_id' => $sellerA->id,
                'session_id' => $session2->id,
                'starting_price' => 500000.00,
                'min_bid_increment' => 50000.00,
                'reserve_price' => 600000.00,
                'current_highest_bid' => 0.00,
                'leading_bidder_id' => null,
                'winner_id' => null,
                'bid_count' => 0,
                'watch_count' => 1,
                'auction_starts_at' => (clone $now)->addHours(2),
                'auction_ends_at' => (clone $now)->addHours(5),
                'extended_count' => 0,
                'status' => AuctionStatus::SCHEDULED,
            ]
        );

        AuctionWatch::firstOrCreate(['auction_id' => $auc3->id, 'user_id' => $buyer1->id]);

        // AUC-2026-0004: COMPLETED - Won by Buyer 1 at 1,000,000đ (maps to ORD-2026-0002)
        $auc4 = Auction::updateOrCreate(
            ['auction_code' => 'AUC-2026-0004'],
            [
                'product_id' => $prd10->id,
                'seller_id' => $sellerA->id,
                'session_id' => $session3->id,
                'starting_price' => 700000.00,
                'min_bid_increment' => 50000.00,
                'reserve_price' => 850000.00,
                'current_highest_bid' => 1000000.00,
                'leading_bidder_id' => $buyer1->id,
                'winner_id' => $buyer1->id,
                'bid_count' => 3,
                'watch_count' => 2,
                'auction_starts_at' => (clone $now)->subDays(1),
                'auction_ends_at' => (clone $now)->subHours(5),
                'closed_at' => (clone $now)->subHours(5),
                'extended_count' => 0,
                'status' => AuctionStatus::COMPLETED,
            ]
        );

        AuctionBid::firstOrCreate(
            ['auction_id' => $auc4->id, 'bidder_id' => $buyer2->id, 'bid_amount' => 700000.00],
            ['previous_highest_bid' => 0.00, 'triggered_anti_sniping' => false, 'created_at' => (clone $now)->subHours(10)]
        );
        AuctionBid::firstOrCreate(
            ['auction_id' => $auc4->id, 'bidder_id' => $buyer3->id, 'bid_amount' => 850000.00],
            ['previous_highest_bid' => 700000.00, 'triggered_anti_sniping' => false, 'created_at' => (clone $now)->subHours(8)]
        );
        AuctionBid::firstOrCreate(
            ['auction_id' => $auc4->id, 'bidder_id' => $buyer1->id, 'bid_amount' => 1000000.00],
            ['previous_highest_bid' => 850000.00, 'triggered_anti_sniping' => false, 'created_at' => (clone $now)->subHours(6)]
        );

        AuctionWatch::firstOrCreate(['auction_id' => $auc4->id, 'user_id' => $buyer1->id]);
        AuctionWatch::firstOrCreate(['auction_id' => $auc4->id, 'user_id' => $buyer3->id]);

        // AUC-2026-0005: ENDED_UNSOLD - Ended with no bids (ready for relist demo)
        $auc5 = Auction::updateOrCreate(
            ['auction_code' => 'AUC-2026-0005'],
            [
                'product_id' => $prd11->id,
                'seller_id' => $sellerC->id,
                'session_id' => $session3->id,
                'starting_price' => 300000.00,
                'min_bid_increment' => 30000.00,
                'reserve_price' => 400000.00,
                'current_highest_bid' => 0.00,
                'leading_bidder_id' => null,
                'winner_id' => null,
                'bid_count' => 0,
                'watch_count' => 0,
                'auction_starts_at' => (clone $now)->subDays(1),
                'auction_ends_at' => (clone $now)->subHours(3),
                'closed_at' => (clone $now)->subHours(3),
                'extended_count' => 0,
                'status' => AuctionStatus::ENDED_UNSOLD,
            ]
        );

        // AUC-2026-0006: WINNER_DEFAULTED - Winner Buyer 3 defaulted after 30 mins (maps to ORD-2026-0008)
        $auc6 = Auction::updateOrCreate(
            ['auction_code' => 'AUC-2026-0006'],
            [
                'product_id' => $prd8->id,
                'seller_id' => $sellerB->id,
                'session_id' => $session3->id,
                'starting_price' => 400000.00,
                'min_bid_increment' => 50000.00,
                'reserve_price' => 500000.00,
                'current_highest_bid' => 500000.00,
                'leading_bidder_id' => $buyer3->id,
                'winner_id' => $buyer3->id,
                'bid_count' => 1,
                'watch_count' => 1,
                'auction_starts_at' => (clone $now)->subDays(2),
                'auction_ends_at' => (clone $now)->subHours(2),
                'closed_at' => (clone $now)->subHours(2),
                'extended_count' => 0,
                'status' => AuctionStatus::WINNER_DEFAULTED,
            ]
        );

        AuctionBid::firstOrCreate(
            ['auction_id' => $auc6->id, 'bidder_id' => $buyer3->id, 'bid_amount' => 500000.00],
            ['previous_highest_bid' => 0.00, 'triggered_anti_sniping' => false, 'created_at' => (clone $now)->subDays(1)]
        );

        AuctionWatch::firstOrCreate(['auction_id' => $auc6->id, 'user_id' => $buyer3->id]);
    }
}
