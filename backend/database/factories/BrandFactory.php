<?php

namespace Database\Factories;

use App\Models\Brand;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Brand>
 */
class BrandFactory extends Factory
{
    protected $model = Brand::class;

    public function definition(): array
    {
        $name = fake()->unique()->company();

        return [
            'name' => $name,
            'slug' => Str::slug($name) . '-' . fake()->unique()->randomNumber(4),
            'logo_url' => 'https://images.unsplash.com/photo-1544816155-12df9643f363?w=200',
            'origin_country' => fake()->country(),
            'description' => fake()->sentence(),
            'is_active' => true,
        ];
    }
}
