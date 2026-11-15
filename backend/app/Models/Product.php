<?php

namespace App\Models;

use App\Enums\ProductCondition;
use App\Enums\ProductStatus;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Product extends Model
{
    use HasFactory;

    protected $table = 'products';

    protected $fillable = [
        'product_code',
        'seller_id',
        'category_id',
        'brand_id',
        'title',
        'slug',
        'description',
        'condition',
        'defect_info',
        'listing_type',
        'price',
        'total_quantity',
        'available_quantity',
        'verification_level',
        'status',
        'rejection_reason',
        'favorite_count',
        'approved_at',
        'approved_by',
    ];

    protected function casts(): array
    {
        return [
            'condition' => ProductCondition::class,
            'status' => ProductStatus::class,
            'price' => 'decimal:2',
            'total_quantity' => 'integer',
            'available_quantity' => 'integer',
            'favorite_count' => 'integer',
            'approved_at' => 'datetime',
        ];
    }

    // Query Scopes
    public function scopeApproved(Builder $query): Builder
    {
        return $query->where('status', ProductStatus::APPROVED);
    }

    public function scopeFixedPrice(Builder $query): Builder
    {
        return $query->where('listing_type', 'FIXED_PRICE');
    }

    public function scopeAuction(Builder $query): Builder
    {
        return $query->where('listing_type', 'AUCTION');
    }

    // Relationships
    public function seller(): BelongsTo
    {
        return $this->belongsTo(User::class, 'seller_id');
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class, 'category_id');
    }

    public function brand(): BelongsTo
    {
        return $this->belongsTo(Brand::class, 'brand_id');
    }

    public function approver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function images(): HasMany
    {
        return $this->hasMany(ProductImage::class, 'product_id');
    }

    public function primaryImage(): HasOne
    {
        return $this->hasOne(ProductImage::class, 'product_id')->where('is_primary', true);
    }

    public function moderationLogs(): HasMany
    {
        return $this->hasMany(ProductModerationLog::class, 'product_id');
    }

    public function auctions(): HasMany
    {
        return $this->hasMany(Auction::class, 'product_id');
    }

    public function activeAuction(): HasOne
    {
        return $this->hasOne(Auction::class, 'product_id')->whereIn('status', ['SCHEDULED', 'LIVE']);
    }

    public function favorites(): HasMany
    {
        return $this->hasMany(Favorite::class, 'product_id');
    }

    public function orderItems(): HasMany
    {
        return $this->hasMany(OrderItem::class, 'product_id');
    }

    public function reviews(): HasMany
    {
        return $this->hasMany(Review::class, 'product_id');
    }
}
