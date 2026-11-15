<?php

namespace App\Models;

use App\Models\Concerns\ImmutableLedgerRecord;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class EscrowTransaction extends Model
{
    use HasFactory, ImmutableLedgerRecord;

    public const UPDATED_AT = null;

    protected $table = 'escrow_transactions';

    protected $fillable = [
        'transaction_code',
        'order_id',
        'payment_id',
        'buyer_id',
        'seller_id',
        'transaction_type',
        'gross_amount',
        'item_subtotal_amount',
        'buyer_protection_fee_amount',
        'seller_released_amount',
        'buyer_refunded_amount',
        'platform_fee_retained',
        'triggered_by_user_id',
        'note',
    ];

    protected function casts(): array
    {
        return [
            'gross_amount' => 'decimal:2',
            'item_subtotal_amount' => 'decimal:2',
            'buyer_protection_fee_amount' => 'decimal:2',
            'seller_released_amount' => 'decimal:2',
            'buyer_refunded_amount' => 'decimal:2',
            'platform_fee_retained' => 'decimal:2',
        ];
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class, 'order_id');
    }

    public function payment(): BelongsTo
    {
        return $this->belongsTo(Payment::class, 'payment_id');
    }

    public function buyer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'buyer_id');
    }

    public function seller(): BelongsTo
    {
        return $this->belongsTo(User::class, 'seller_id');
    }

    public function triggeredBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'triggered_by_user_id');
    }

    public function walletTransaction(): HasOne
    {
        return $this->hasOne(WalletTransaction::class, 'escrow_transaction_id');
    }
}
