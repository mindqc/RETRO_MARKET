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
        // 9. platform_settings
        Schema::create('platform_settings', function (Blueprint $table) {
            $table->string('key', 80)->primary();
            $table->string('value', 255);
            $table->string('value_type', 20);
            $table->text('description');
            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestampTz('updated_at')->useCurrent();
        });

        // Seed 12 default configuration keys (DEC-04 & ADR-05)
        DB::table('platform_settings')->insert([
            [
                'key' => 'protection_fee_rate',
                'value' => '0.06',
                'value_type' => 'DECIMAL',
                'description' => 'Tỷ lệ % Phí bảo vệ người mua (Mặc định 6%, cho phép 5%-8% theo DEC-04)',
                'updated_at' => now(),
            ],
            [
                'key' => 'protection_fixed_fee',
                'value' => '7000',
                'value_type' => 'DECIMAL',
                'description' => 'Phí bảo vệ cố định VND trên mỗi đơn hàng (Mặc định 7.000đ, cho phép 5k-10k theo DEC-04)',
                'updated_at' => now(),
            ],
            [
                'key' => 'shipping_fee_default',
                'value' => '0',
                'value_type' => 'DECIMAL',
                'description' => 'Phí vận chuyển thu trên ứng dụng (Cố định 0 VND theo DEC-04)',
                'updated_at' => now(),
            ],
            [
                'key' => 'seller_commission_rate',
                'value' => '0',
                'value_type' => 'DECIMAL',
                'description' => 'Hoa hồng thu từ người bán (Cố định 0% - Seller nhận đủ 100% tiền hàng theo DEC-04)',
                'updated_at' => now(),
            ],
            [
                'key' => 'auction_payment_window_production_sec',
                'value' => '1800',
                'value_type' => 'INTEGER',
                'description' => 'Thời hạn thanh toán đơn thắng đấu giá Production (30 phút = 1800 giây)',
                'updated_at' => now(),
            ],
            [
                'key' => 'auction_payment_window_demo_sec',
                'value' => '120',
                'value_type' => 'INTEGER',
                'description' => 'Thời hạn thanh toán đơn thắng đấu giá Demo Mode (2 phút = 120 giây theo ADR-05)',
                'updated_at' => now(),
            ],
            [
                'key' => 'auto_complete_window_production_sec',
                'value' => '86400',
                'value_type' => 'INTEGER',
                'description' => 'Thời gian tự hoàn tất đơn & giải ngân sau khi giao hàng Production (24 giờ = 86400 giây)',
                'updated_at' => now(),
            ],
            [
                'key' => 'auto_complete_window_demo_sec',
                'value' => '120',
                'value_type' => 'INTEGER',
                'description' => 'Thời gian tự hoàn tất đơn & giải ngân Demo Mode (2 phút = 120 giây theo ADR-05)',
                'updated_at' => now(),
            ],
            [
                'key' => 'anti_sniping_trigger_window_production_sec',
                'value' => '120',
                'value_type' => 'INTEGER',
                'description' => 'Khung giờ kích hoạt Anti-sniping trước khi hết phiên Production (2 phút cuối)',
                'updated_at' => now(),
            ],
            [
                'key' => 'anti_sniping_extend_duration_production_sec',
                'value' => '120',
                'value_type' => 'INTEGER',
                'description' => 'Thời gian gia hạn phiên đấu giá khi có bid phút chót Production (+2 phút)',
                'updated_at' => now(),
            ],
            [
                'key' => 'anti_sniping_trigger_window_demo_sec',
                'value' => '30',
                'value_type' => 'INTEGER',
                'description' => 'Khung giờ kích hoạt Anti-sniping Demo Mode (30 giây cuối theo ADR-05)',
                'updated_at' => now(),
            ],
            [
                'key' => 'anti_sniping_extend_duration_demo_sec',
                'value' => '30',
                'value_type' => 'INTEGER',
                'description' => 'Thời gian gia hạn phiên đấu giá Demo Mode (+30 giây theo ADR-05)',
                'updated_at' => now(),
            ],
        ]);

        // 10. audit_logs
        Schema::create('audit_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('actor_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('actor_role', 30);
            $table->string('action', 80);
            $table->string('target_type', 50);
            $table->unsignedBigInteger('target_id')->nullable();
            $table->text('reason')->nullable();
            $table->jsonb('old_values')->nullable();
            $table->jsonb('new_values')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->timestampTz('created_at')->useCurrent();
        });

        // 11. products
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->string('product_code', 30)->unique();
            $table->foreignId('seller_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('category_id')->constrained('categories')->restrictOnDelete();
            $table->foreignId('brand_id')->nullable()->constrained('brands')->nullOnDelete();
            $table->string('title', 150);
            $table->string('slug', 180)->unique();
            $table->text('description');
            $table->string('condition', 25);
            $table->text('defect_info');
            $table->string('listing_type', 20)->default('FIXED_PRICE');
            $table->decimal('price', 15, 2);
            $table->integer('total_quantity')->default(1);
            $table->integer('available_quantity')->default(1);
            $table->string('verification_level', 30)->default('UNVERIFIED');
            $table->string('status', 25)->default('DRAFT');
            $table->text('rejection_reason')->nullable();
            $table->integer('favorite_count')->default(0);
            $table->timestampTz('approved_at')->nullable();
            $table->foreignId('approved_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestampsTz();
        });

        // 12. product_images
        Schema::create('product_images', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained('products')->cascadeOnDelete();
            $table->string('image_url', 500);
            $table->string('image_type', 30)->default('GALLERY');
            $table->boolean('is_primary')->default(false);
            $table->smallInteger('sort_order')->default(0);
            $table->integer('file_size_bytes')->nullable();
            $table->timestampTz('created_at')->useCurrent();
        });

        // 13. product_moderation_logs
        Schema::create('product_moderation_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained('products')->cascadeOnDelete();
            $table->foreignId('moderator_id')->constrained('users')->restrictOnDelete();
            $table->string('action', 25);
            $table->string('previous_status', 25);
            $table->string('new_status', 25);
            $table->string('verification_level_assigned', 30)->nullable();
            $table->text('reason')->nullable();
            $table->timestampTz('created_at')->useCurrent();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('product_moderation_logs');
        Schema::dropIfExists('product_images');
        Schema::dropIfExists('products');
        Schema::dropIfExists('audit_logs');
        Schema::dropIfExists('platform_settings');
    }
};
