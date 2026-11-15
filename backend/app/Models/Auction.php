<?php

namespace App\Models;

use App\Enums\AuctionStatus;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Auction extends Model
{
    use HasFactory;

    protected $table = 'auctions';

    protected $fillable = [
        'auction_code',
        'product_id',
        'seller_id',
        'session_id',
        'starting_price',
        'min_bid_increment',
        'reserve_price',
        'current_highest_bid',
        'leading_bidder_id',
        'winner_id',
        'bid_count',
        'watch_count',
        'auction_starts_at',
        'auction_ends_at',
        'extended_count',
        'last_extended_at',
        'closed_early_by_seller',
        'status',
        'cancel_reason',
        'closed_at',
    ];

    protected function casts(): array
    {
        return [
            'status' => AuctionStatus::class,
            'starting_price' => 'decimal:2',
            'min_bid_increment' => 'decimal:2',
            'reserve_price' => 'decimal:2',
            'current_highest_bid' => 'decimal:2',
            'bid_count' => 'integer',
            'watch_count' => 'integer',
            'extended_count' => 'integer',
            'closed_early_by_seller' => 'boolean',
            'auction_starts_at' => 'datetime',
            'auction_ends_at' => 'datetime',
            'last_extended_at' => 'datetime',
            'closed_at' => 'datetime',
        ];
    }

    /**
     * Calculate minimum valid next bid amount.
     */
    public function minimumNextBidAmount(): float
    {
        if ((float) $this->current_highest_bid > 0) {
            return (float) ($this->current_highest_bid + $this->min_bid_increment);
        }

        return (float) $this->starting_price;
    }

    // Relationships
    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class, 'product_id');
    }

    public function seller(): BelongsTo
    {
        return $this->belongsTo(User::class, 'seller_id');
    }

    public function session(): BelongsTo
    {
        return $this->belongsTo(AuctionSession::class, 'session_id');
    }

    public function leadingBidder(): BelongsTo
    {
        return $this->belongsTo(User::class, 'leading_bidder_id');
    }

    public function winner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'winner_id');
    }

    public function bids(): HasMany
    {
        return $this->hasMany(AuctionBid::class, 'auction_id');
    }

    public function watches(): HasMany
    {
        return $this->hasMany(AuctionWatch::class, 'auction_id');
    }

    public function order(): HasOne
    {
        return $this->hasOne(Order::class, 'auction_id');
    }
}
