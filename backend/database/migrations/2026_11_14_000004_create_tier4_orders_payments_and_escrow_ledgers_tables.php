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
        // 18. carts
        Schema::create('carts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained('users')->cascadeOnDelete();
            $table->timestampsTz();
        });

        // 19. cart_items
        Schema::create('cart_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('cart_id')->constrained('carts')->cascadeOnDelete();
            $table->foreignId('product_id')->constrained('products')->cascadeOnDelete();
            $table->foreignId('seller_id')->constrained('users')->cascadeOnDelete();
            $table->integer('quantity')->default(1);
            $table->boolean('is_selected')->default(true);
            $table->timestampsTz();

            $table->unique(['cart_id', 'product_id']);
            $table->index(['cart_id', 'seller_id']);
        });

        // 20. orders
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->string('order_code', 30)->unique();
            $table->foreignId('buyer_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('seller_id')->constrained('users')->restrictOnDelete();
            $table->string('order_source', 20)->default('FIXED_PRICE');
            $table->foreignId('auction_id')->nullable()->unique()->constrained('auctions')->restrictOnDelete();
            $table->decimal('item_subtotal', 15, 2);
            $table->decimal('shipping_fee', 15, 2)->default(0.00);
            $table->decimal('protection_fee_rate_applied', 5, 4)->default(0.0600);
            $table->decimal('protection_fixed_fee_applied', 15, 2)->default(7000.00);
            $table->decimal('buyer_protection_fee', 15, 2);
            $table->decimal('total_amount', 15, 2);
            $table->decimal('seller_net_amount', 15, 2);
            $table->jsonb('shipping_address_snapshot');
            $table->string('order_status', 25)->default('PENDING_PAYMENT');
            $table->string('payment_status', 25)->default('UNPAID');
            $table->string('escrow_status', 25)->default('NONE');
            $table->string('dispute_status', 25)->default('NONE');
            $table->boolean('cancellation_requested')->default(false);
            $table->text('cancellation_request_reason')->nullable();
            $table->string('cancelled_by_role', 20)->nullable();
            $table->text('cancel_reason')->nullable();
            $table->timestampTz('payment_expires_at');
            $table->timestampTz('paid_at')->nullable();
            $table->timestampTz('preparing_at')->nullable();
            $table->timestampTz('shipped_at')->nullable();
            $table->timestampTz('delivered_at')->nullable();
            $table->timestampTz('auto_complete_at')->nullable();
            $table->timestampTz('escrow_frozen_at')->nullable();
            $table->timestampTz('completed_at')->nullable();
            $table->timestampTz('cancelled_at')->nullable();
            $table->timestampsTz();

            $table->index(['buyer_id', 'order_status', 'created_at']);
            $table->index(['seller_id', 'order_status', 'created_at']);
        });

        // 21. order_items
        Schema::create('order_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained('orders')->cascadeOnDelete();
            $table->foreignId('product_id')->constrained('products')->restrictOnDelete();
            $table->string('product_code_snapshot', 30);
            $table->string('product_title_snapshot', 150);
            $table->string('condition_snapshot', 25);
            $table->text('defect_info_snapshot');
            $table->string('primary_image_snapshot', 500);
            $table->decimal('unit_price_snapshot', 15, 2);
            $table->integer('quantity')->default(1);
            $table->decimal('line_total', 15, 2);
            $table->timestampTz('created_at')->useCurrent();

            $table->index('order_id');
        });

        // 22. shipments
        Schema::create('shipments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->unique()->constrained('orders')->cascadeOnDelete();
            $table->string('carrier_name', 80);
            $table->string('tracking_code', 80);
            $table->text('shipping_note')->nullable();
            $table->string('status', 25)->default('SHIPPED');
            $table->timestampTz('shipped_at')->useCurrent();
            $table->timestampTz('delivered_at')->nullable();
            $table->foreignId('updated_by')->constrained('users')->restrictOnDelete();
            $table->timestampsTz();
        });

        // 23. payments
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->string('payment_reference', 50)->unique();
            $table->foreignId('order_id')->constrained('orders')->restrictOnDelete();
            $table->foreignId('payer_id')->constrained('users')->restrictOnDelete();
            $table->decimal('amount', 15, 2);
            $table->text('qr_payload');
            $table->string('status', 25)->default('PENDING');
            $table->string('failure_reason', 255)->nullable();
            $table->timestampTz('expires_at');
            $table->timestampTz('paid_at')->nullable();
            $table->timestampsTz();
        });

        // 24. escrow_transactions
        Schema::create('escrow_transactions', function (Blueprint $table) {
            $table->id();
            $table->string('transaction_code', 40)->unique();
            $table->foreignId('order_id')->constrained('orders')->restrictOnDelete();
            $table->foreignId('payment_id')->nullable()->constrained('payments')->restrictOnDelete();
            $table->foreignId('buyer_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('seller_id')->constrained('users')->restrictOnDelete();
            $table->string('transaction_type', 30);
            $table->decimal('gross_amount', 15, 2);
            $table->decimal('item_subtotal_amount', 15, 2);
            $table->decimal('buyer_protection_fee_amount', 15, 2);
            $table->decimal('seller_released_amount', 15, 2)->default(0.00);
            $table->decimal('buyer_refunded_amount', 15, 2)->default(0.00);
            $table->decimal('platform_fee_retained', 15, 2)->default(0.00);
            $table->foreignId('triggered_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->text('note');
            $table->timestampTz('created_at')->useCurrent();

            $table->index(['order_id', 'created_at']);
        });

        // 25. wallet_transactions
        Schema::create('wallet_transactions', function (Blueprint $table) {
            $table->id();
            $table->string('wallet_tx_code', 40)->unique();
            $table->foreignId('seller_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('order_id')->unique()->constrained('orders')->restrictOnDelete();
            $table->foreignId('escrow_transaction_id')->unique()->constrained('escrow_transactions')->restrictOnDelete();
            $table->string('entry_type', 20)->default('CREDIT');
            $table->decimal('amount', 15, 2);
            $table->decimal('balance_before', 15, 2);
            $table->decimal('balance_after', 15, 2);
            $table->string('description', 255);
            $table->timestampTz('created_at')->useCurrent();

            $table->index(['seller_id', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('wallet_transactions');
        Schema::dropIfExists('escrow_transactions');
        Schema::dropIfExists('payments');
        Schema::dropIfExists('shipments');
        Schema::dropIfExists('order_items');
        Schema::dropIfExists('orders');
        Schema::dropIfExists('cart_items');
        Schema::dropIfExists('carts');
    }
};
