<?php

namespace Database\Factories;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    protected $model = User::class;

    protected static ?string $password;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'display_name' => fake()->name(),
            'email' => fake()->unique()->safeEmail(),
            'phone' => '09' . fake()->numerify('########'),
            'password_hash' => static::$password ??= Hash::make('Retro@2026'),
            'role' => UserRole::REGISTERED_USER,
            'status' => UserStatus::ACTIVE,
            'status_reason' => null,
            'suspended_until' => null,
            'last_login_at' => now(),
        ];
    }

    public function admin(): static
    {
        return $this->state(fn () => [
            'role' => UserRole::ADMIN,
        ]);
    }

    public function moderator(): static
    {
        return $this->state(fn () => [
            'role' => UserRole::MODERATOR,
        ]);
    }

    public function support(): static
    {
        return $this->state(fn () => [
            'role' => UserRole::SUPPORT,
        ]);
    }

    public function suspended(): static
    {
        return $this->state(fn () => [
            'status' => UserStatus::SUSPENDED,
            'status_reason' => 'Vi phạm quy tắc kiểm duyệt nội dung cộng đồng',
            'suspended_until' => now()->addDays(7),
        ]);
    }
}
