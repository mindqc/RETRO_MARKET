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
        // 1. users
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('display_name', 100);
            $table->string('email', 150)->unique();
            $table->string('phone', 20)->nullable();
            $table->string('password_hash', 255);
            $table->string('role', 30)->default('REGISTERED_USER');
            $table->string('status', 20)->default('ACTIVE');
            $table->text('status_reason')->nullable();
            $table->timestampTz('suspended_until')->nullable();
            $table->timestampTz('last_login_at')->nullable();
            $table->timestampsTz();
        });

        // 2. personal_access_tokens
        Schema::create('personal_access_tokens', function (Blueprint $table) {
            $table->id();
            $table->string('tokenable_type', 100);
            $table->unsignedBigInteger('tokenable_id');
            $table->string('name', 100);
            $table->string('token', 64)->unique();
            $table->text('abilities')->nullable();
            $table->timestampTz('last_used_at')->nullable();
            $table->timestampTz('expires_at')->nullable();
            $table->timestampsTz();

            $table->index(['tokenable_type', 'tokenable_id']);
        });

        // 3. password_reset_tokens
        Schema::create('password_reset_tokens', function (Blueprint $table) {
            $table->string('email', 150)->primary();
            $table->string('token', 255);
            $table->timestampTz('created_at')->useCurrent();
        });

        // 4. user_profiles
        Schema::create('user_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained('users')->cascadeOnDelete();
            $table->string('avatar_url', 500)->nullable();
            $table->text('bio')->nullable();
            $table->boolean('seasonal_decor_enabled')->default(true);
            $table->timestampsTz();
        });

        // 5. seller_profiles
        Schema::create('seller_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained('users')->cascadeOnDelete();
            $table->string('shop_slug', 120)->unique();
            $table->decimal('trust_score', 5, 2)->default(100.00);
            $table->decimal('average_rating', 3, 2)->default(0.00);
            $table->integer('review_count')->default(0);
            $table->integer('completed_orders_count')->default(0);
            $table->decimal('wallet_balance', 15, 2)->default(0.00);
            $table->decimal('escrow_held_balance', 15, 2)->default(0.00);
            $table->integer('auction_default_count')->default(0);
            $table->integer('dispute_lost_count')->default(0);
            $table->timestampsTz();
        });

        // 6. user_addresses
        Schema::create('user_addresses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('recipient_name', 100);
            $table->string('recipient_phone', 20);
            $table->string('province_city', 100);
            $table->string('district_ward', 150);
            $table->string('street_address', 255);
            $table->boolean('is_default')->default(false);
            $table->timestampsTz();
        });

        // 7. categories
        Schema::create('categories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('parent_id')->nullable()->constrained('categories')->nullOnDelete();
            $table->string('name', 100);
            $table->string('slug', 120)->unique();
            $table->string('icon_name', 60)->nullable();
            $table->text('description')->nullable();
            $table->integer('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestampsTz();
        });

        // 8. brands
        Schema::create('brands', function (Blueprint $table) {
            $table->id();
            $table->string('name', 100)->unique();
            $table->string('slug', 120)->unique();
            $table->string('logo_url', 500)->nullable();
            $table->string('origin_country', 80)->nullable();
            $table->text('description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestampsTz();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('brands');
        Schema::dropIfExists('categories');
        Schema::dropIfExists('user_addresses');
        Schema::dropIfExists('seller_profiles');
        Schema::dropIfExists('user_profiles');
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('personal_access_tokens');
        Schema::dropIfExists('users');
    }
};
