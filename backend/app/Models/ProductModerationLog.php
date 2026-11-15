<?php

namespace App\Models;

use App\Models\Concerns\ImmutableLedgerRecord;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProductModerationLog extends Model
{
    use HasFactory, ImmutableLedgerRecord;

    public const UPDATED_AT = null;

    protected $table = 'product_moderation_logs';

    protected $fillable = [
        'product_id',
        'moderator_id',
        'action',
        'previous_status',
        'new_status',
        'verification_level_assigned',
        'reason',
    ];

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class, 'product_id');
    }

    public function moderator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'moderator_id');
    }
}
