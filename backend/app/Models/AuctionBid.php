<?php

namespace App\Models;

use App\Models\Concerns\ImmutableLedgerRecord;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AuctionBid extends Model
{
    use HasFactory, ImmutableLedgerRecord;

    public const UPDATED_AT = null;

    protected $table = 'auction_bids';

    protected $fillable = [
        'auction_id',
        'bidder_id',
        'bid_amount',
        'previous_highest_bid',
        'triggered_anti_sniping',
    ];

    protected function casts(): array
    {
        return [
            'bid_amount' => 'decimal:2',
            'previous_highest_bid' => 'decimal:2',
            'triggered_anti_sniping' => 'boolean',
        ];
    }

    public function auction(): BelongsTo
    {
        return $this->belongsTo(Auction::class, 'auction_id');
    }

    public function bidder(): BelongsTo
    {
        return $this->belongsTo(User::class, 'bidder_id');
    }
}
