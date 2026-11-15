<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AuctionSession extends Model
{
    use HasFactory;

    protected $table = 'auction_sessions';

    protected $fillable = [
        'session_code',
        'title',
        'starts_at',
        'ends_at',
        'default_min_increment',
        'status',
        'created_by',
    ];

    protected function casts(): array
    {
        return [
            'starts_at' => 'datetime',
            'ends_at' => 'datetime',
            'default_min_increment' => 'decimal:2',
        ];
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function auctions(): HasMany
    {
        return $this->hasMany(Auction::class, 'session_id');
    }
}
