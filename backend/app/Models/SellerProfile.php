<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SellerProfile extends Model
{
    use HasFactory;

    protected $table = 'seller_profiles';

    protected $fillable = [
        'user_id',
        'shop_slug',
        'trust_score',
        'average_rating',
        'review_count',
        'completed_orders_count',
        'wallet_balance',
        'escrow_held_balance',
        'auction_default_count',
        'dispute_lost_count',
    ];

    protected function casts(): array
    {
        return [
            'trust_score' => 'decimal:2',
            'average_rating' => 'decimal:2',
            'wallet_balance' => 'decimal:2',
            'escrow_held_balance' => 'decimal:2',
            'review_count' => 'integer',
            'completed_orders_count' => 'integer',
            'auction_default_count' => 'integer',
            'dispute_lost_count' => 'integer',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
