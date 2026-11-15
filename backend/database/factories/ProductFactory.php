<?php

namespace Database\Factories;

use App\Enums\ProductCondition;
use App\Enums\ProductStatus;
use App\Models\Category;
use App\Models\Product;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Product>
 */
class ProductFactory extends Factory
{
    protected $model = Product::class;

    public function definition(): array
    {
        $title = fake()->words(3, true);

        return [
            'product_code' => 'PRD-' . strtoupper(Str::random(8)),
            'seller_id' => User::factory(),
            'category_id' => Category::factory(),
            'brand_id' => null,
            'title' => ucfirst($title),
            'slug' => Str::slug($title) . '-' . fake()->unique()->randomNumber(4),
            'description' => fake()->paragraph(),
            'condition' => fake()->randomElement(ProductCondition::cases()),
            'defect_info' => 'Có vết sờn nhẹ theo thời gian ở phần viền',
            'listing_type' => 'FIXED_PRICE',
            'price' => fake()->randomElement([150000, 250000, 350000, 500000, 750000, 1000000]),
            'total_quantity' => 1,
            'available_quantity' => 1,
            'verification_level' => 'UNVERIFIED',
            'status' => ProductStatus::APPROVED,
            'rejection_reason' => null,
            'favorite_count' => 0,
            'approved_at' => now(),
            'approved_by' => null,
        ];
    }
}
