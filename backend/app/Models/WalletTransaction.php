<?php

namespace App\Models;

use App\Models\Concerns\ImmutableLedgerRecord;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WalletTransaction extends Model
{
    use HasFactory, ImmutableLedgerRecord;

    public const UPDATED_AT = null;

    protected $table = 'wallet_transactions';

    protected $fillable = [
        'wallet_tx_code',
        'seller_id',
        'order_id',
        'escrow_transaction_id',
        'entry_type',
        'amount',
        'balance_before',
        'balance_after',
        'description',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'balance_before' => 'decimal:2',
            'balance_after' => 'decimal:2',
        ];
    }

    public function seller(): BelongsTo
    {
        return $this->belongsTo(User::class, 'seller_id');
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class, 'order_id');
    }

    public function escrowTransaction(): BelongsTo
    {
        return $this->belongsTo(EscrowTransaction::class, 'escrow_transaction_id');
    }
}
