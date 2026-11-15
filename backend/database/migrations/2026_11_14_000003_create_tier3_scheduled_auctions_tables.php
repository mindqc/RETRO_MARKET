<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 14. auction_sessions
        Schema::create('auction_sessions', function (Blueprint $table) {
            $table->id();
            $table->string('session_code', 40)->unique();
            $table->string('title', 120);
            $table->timestampTz('starts_at');
            $table->timestampTz('ends_at');
            $table->decimal('default_min_increment', 15, 2)->default(20000.00);
            $table->string('status', 20)->default('ACTIVE');
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestampsTz();
        });

        // 15. auctions
        Schema::create('auctions', function (Blueprint $table) {
            $table->id();
            $table->string('auction_code', 30)->unique();
            $table->foreignId('product_id')->constrained('products')->restrictOnDelete();
            $table->foreignId('seller_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('session_id')->constrained('auction_sessions')->restrictOnDelete();
            $table->decimal('starting_price', 15, 2);
            $table->decimal('min_bid_increment', 15, 2);
            $table->decimal('reserve_price', 15, 2)->nullable();
            $table->decimal('current_highest_bid', 15, 2)->default(0.00);
            $table->foreignId('leading_bidder_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('winner_id')->nullable()->constrained('users')->nullOnDelete();
            $table->integer('bid_count')->default(0);
            $table->integer('watch_count')->default(0);
            $table->timestampTz('auction_starts_at');
            $table->timestampTz('auction_ends_at');
            $table->integer('extended_count')->default(0);
            $table->timestampTz('last_extended_at')->nullable();
            $table->boolean('closed_early_by_seller')->default(false);
            $table->string('status', 25)->default('SCHEDULED');
            $table->text('cancel_reason')->nullable();
            $table->timestampTz('closed_at')->nullable();
            $table->timestampsTz();
        });

        // 16. auction_bids
        Schema::create('auction_bids', function (Blueprint $table) {
            $table->id();
            $table->foreignId('auction_id')->constrained('auctions')->cascadeOnDelete();
            $table->foreignId('bidder_id')->constrained('users')->restrictOnDelete();
            $table->decimal('bid_amount', 15, 2);
            $table->decimal('previous_highest_bid', 15, 2)->default(0.00);
            $table->boolean('triggered_anti_sniping')->default(false);
            $table->timestampTz('created_at')->useCurrent();
        });

        // 17. auction_watches
        Schema::create('auction_watches', function (Blueprint $table) {
            $table->id();
            $table->foreignId('auction_id')->constrained('auctions')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->timestampTz('created_at')->useCurrent();

            $table->unique(['auction_id', 'user_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('auction_watches');
        Schema::dropIfExists('auction_bids');
        Schema::dropIfExists('auctions');
        Schema::dropIfExists('auction_sessions');
    }
};
