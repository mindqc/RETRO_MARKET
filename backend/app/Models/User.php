<?php

namespace App\Models;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $table = 'users';

    protected $fillable = [
        'display_name',
        'email',
        'phone',
        'password_hash',
        'role',
        'status',
        'status_reason',
        'suspended_until',
        'last_login_at',
    ];

    protected $hidden = [
        'password_hash',
    ];

    /**
     * Get the name of the password attribute for authentication (TECH-02).
     */
    public function getAuthPasswordName(): string
    {
        return 'password_hash';
    }

    protected function casts(): array
    {
        return [
            'role' => UserRole::class,
            'status' => UserStatus::class,
            'suspended_until' => 'datetime',
            'last_login_at' => 'datetime',
        ];
    }

    public function getFullNameAttribute(): string
    {
        return $this->display_name ?? '';
    }

    // Role & Status Convenience Helpers
    public function isAdmin(): bool
    {
        return $this->role === UserRole::ADMIN;
    }

    public function isModerator(): bool
    {
        return $this->role === UserRole::MODERATOR;
    }

    public function isSupport(): bool
    {
        return $this->role === UserRole::SUPPORT;
    }

    public function isInternalStaff(): bool
    {
        return in_array($this->role, [UserRole::ADMIN, UserRole::MODERATOR, UserRole::SUPPORT], true);
    }

    public function isActive(): bool
    {
        return $this->status === UserStatus::ACTIVE;
    }

    // Relationships
    public function profile(): HasOne
    {
        return $this->hasOne(UserProfile::class, 'user_id');
    }

    public function sellerProfile(): HasOne
    {
        return $this->hasOne(SellerProfile::class, 'user_id');
    }

    public function addresses(): HasMany
    {
        return $this->hasMany(UserAddress::class, 'user_id');
    }

    public function defaultAddress(): HasOne
    {
        return $this->hasOne(UserAddress::class, 'user_id')->where('is_default', true);
    }

    public function cart(): HasOne
    {
        return $this->hasOne(Cart::class, 'user_id');
    }

    public function products(): HasMany
    {
        return $this->hasMany(Product::class, 'seller_id');
    }

    public function auctionsAsSeller(): HasMany
    {
        return $this->hasMany(Auction::class, 'seller_id');
    }

    public function auctionBids(): HasMany
    {
        return $this->hasMany(AuctionBid::class, 'bidder_id');
    }

    public function auctionWatches(): HasMany
    {
        return $this->hasMany(AuctionWatch::class, 'user_id');
    }

    public function buyerOrders(): HasMany
    {
        return $this->hasMany(Order::class, 'buyer_id');
    }

    public function sellerOrders(): HasMany
    {
        return $this->hasMany(Order::class, 'seller_id');
    }

    public function walletTransactions(): HasMany
    {
        return $this->hasMany(WalletTransaction::class, 'seller_id');
    }

    public function favorites(): HasMany
    {
        return $this->hasMany(Favorite::class, 'user_id');
    }

    public function followingSellers(): HasMany
    {
        return $this->hasMany(SellerFollow::class, 'follower_id');
    }

    public function followers(): HasMany
    {
        return $this->hasMany(SellerFollow::class, 'seller_id');
    }

    public function notifications(): HasMany
    {
        return $this->hasMany(Notification::class, 'user_id');
    }

    public function reviewsWritten(): HasMany
    {
        return $this->hasMany(Review::class, 'reviewer_id');
    }

    public function reviewsReceived(): HasMany
    {
        return $this->hasMany(Review::class, 'seller_id');
    }
}
