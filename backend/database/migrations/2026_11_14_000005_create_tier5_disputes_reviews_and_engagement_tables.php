<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 26. disputes
        Schema::create('disputes', function (Blueprint $table) {
            $table->id();
            $table->string('dispute_code', 30)->unique();
            $table->foreignId('order_id')->unique()->constrained('orders')->restrictOnDelete();
            $table->foreignId('buyer_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('seller_id')->constrained('users')->restrictOnDelete();
            $table->string('opened_at_order_status', 25);
            $table->string('reason_category', 50);
            $table->text('buyer_description');
            $table->text('seller_response')->nullable();
            $table->foreignId('assigned_support_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('status', 25)->default('OPEN');
            $table->string('admin_verdict', 30)->nullable();
            $table->decimal('partial_refund_to_buyer', 15, 2)->nullable();
            $table->text('resolution_note')->nullable();
            $table->foreignId('resolved_by_admin_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestampTz('resolved_at')->nullable();
            $table->timestampsTz();

            $table->index(['status', 'assigned_support_id', 'created_at']);
        });

        // 27. dispute_evidences
        Schema::create('dispute_evidences', function (Blueprint $table) {
            $table->id();
            $table->foreignId('dispute_id')->constrained('disputes')->cascadeOnDelete();
            $table->foreignId('uploader_id')->constrained('users')->restrictOnDelete();
            $table->string('uploader_role', 25);
            $table->string('evidence_type', 30);
            $table->string('file_url', 500)->nullable();
            $table->text('message_note')->nullable();
            $table->timestampTz('created_at')->useCurrent();
        });

        // 28. reviews
        Schema::create('reviews', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->unique()->constrained('orders')->restrictOnDelete();
            $table->foreignId('product_id')->constrained('products')->restrictOnDelete();
            $table->foreignId('reviewer_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('seller_id')->constrained('users')->restrictOnDelete();
            $table->smallInteger('rating');
            $table->text('comment');
            $table->string('status', 20)->default('VISIBLE');
            $table->text('hidden_reason')->nullable();
            $table->foreignId('hidden_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestampsTz();

            $table->index(['seller_id', 'status', 'created_at']);
        });

        // 29. reports
        Schema::create('reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('reporter_id')->constrained('users')->cascadeOnDelete();
            $table->string('target_type', 25);
            $table->bigInteger('target_id');
            $table->string('reason_category', 60);
            $table->text('description');
            $table->string('status', 25)->default('PENDING');
            $table->text('resolution_note')->nullable();
            $table->foreignId('handled_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestampTz('handled_at')->nullable();
            $table->timestampsTz();

            $table->index(['status', 'target_type', 'created_at']);
        });

        // 30. favorites
        Schema::create('favorites', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('product_id')->constrained('products')->cascadeOnDelete();
            $table->timestampTz('created_at')->useCurrent();

            $table->unique(['user_id', 'product_id']);
        });

        // 31. seller_follows
        Schema::create('seller_follows', function (Blueprint $table) {
            $table->id();
            $table->foreignId('follower_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('seller_id')->constrained('users')->cascadeOnDelete();
            $table->timestampTz('created_at')->useCurrent();

            $table->unique(['follower_id', 'seller_id']);
        });

        // 32. conversations
        Schema::create('conversations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_one_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('user_two_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('context_product_id')->nullable()->constrained('products')->nullOnDelete();
            $table->foreignId('context_order_id')->nullable()->constrained('orders')->nullOnDelete();
            $table->string('last_message_preview', 255)->nullable();
            $table->timestampTz('last_message_at')->nullable();
            $table->foreignId('blocked_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestampsTz();

            $table->unique(['user_one_id', 'user_two_id']);
            $table->index(['user_one_id', 'last_message_at']);
            $table->index(['user_two_id', 'last_message_at']);
        });

        // 33. messages
        Schema::create('messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('conversation_id')->constrained('conversations')->cascadeOnDelete();
            $table->foreignId('sender_id')->constrained('users')->cascadeOnDelete();
            $table->text('message_text');
            $table->foreignId('attached_product_id')->nullable()->constrained('products')->nullOnDelete();
            $table->boolean('is_read')->default(false);
            $table->timestampTz('read_at')->nullable();
            $table->timestampTz('created_at')->useCurrent();

            $table->index(['conversation_id', 'id']);
        });

        // 34. notifications
        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('type', 40);
            $table->string('title', 180);
            $table->text('body');
            $table->string('target_type', 40)->nullable();
            $table->bigInteger('target_id')->nullable();
            $table->string('deep_link_route', 255)->nullable();
            $table->boolean('is_read')->default(false);
            $table->timestampTz('read_at')->nullable();
            $table->timestampTz('created_at')->useCurrent();

            $table->index(['user_id', 'is_read', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('notifications');
        Schema::dropIfExists('messages');
        Schema::dropIfExists('conversations');
        Schema::dropIfExists('seller_follows');
        Schema::dropIfExists('favorites');
        Schema::dropIfExists('reports');
        Schema::dropIfExists('reviews');
        Schema::dropIfExists('dispute_evidences');
        Schema::dropIfExists('disputes');
    }
};
