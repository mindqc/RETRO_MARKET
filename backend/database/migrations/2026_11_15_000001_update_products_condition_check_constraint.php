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
        DB::statement("ALTER TABLE products DROP CONSTRAINT IF EXISTS chk_products_condition;");
        DB::statement("ALTER TABLE products ADD CONSTRAINT chk_products_condition CHECK (condition IN ('NEW_WITH_TAGS', 'LIKE_NEW', 'GOOD', 'FAIR', 'VINTAGE_WORN'));");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::statement("ALTER TABLE products DROP CONSTRAINT IF EXISTS chk_products_condition;");
        DB::statement("ALTER TABLE products ADD CONSTRAINT chk_products_condition CHECK (condition IN ('LIKE_NEW', 'GOOD', 'FAIR', 'VINTAGE_WORN'));");
    }
};
