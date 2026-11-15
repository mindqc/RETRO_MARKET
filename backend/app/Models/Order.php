<?php

namespace App\Models;

use App\Enums\DisputeStatus;
use App\Enums\EscrowStatus;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Order extends Model
{
    use HasFactory;

    protected $table = 'orders';

    protected $fillable = [
        'order_code',
        'buyer_id',
        'seller_id',
        'order_source',
        'auction_id',
        'item_subtotal',
        'shipping_fee',
        'protection_fee_rate_applied',
        'protection_fixed_fee_applied',
        'buyer_protection_fee',
        'total_amount',
        'seller_net_amount',
        'shipping_address_snapshot',
        'order_status',
        'payment_status',
        'escrow_status',
        'dispute_status',
        'cancellation_requested',
        'cancellation_request_reason',
        'cancelled_by_role',
        'cancel_reason',
        'payment_expires_at',
        'paid_at',
        'preparing_at',
        'shipped_at',
        'delivered_at',
        'auto_complete_at',
        'escrow_frozen_at',
        'completed_at',
        'cancelled_at',
    ];

    protected function casts(): array
    {
        return [
            'order_status' => OrderStatus::class,
            'payment_status' => PaymentStatus::class,
            'escrow_status' => EscrowStatus::class,
            'dispute_status' => DisputeStatus::class,
            'item_subtotal' => 'decimal:2',
            'shipping_fee' => 'decimal:2',
            'protection_fee_rate_applied' => 'decimal:4',
            'protection_fixed_fee_applied' => 'decimal:2',
            'buyer_protection_fee' => 'decimal:2',
            'total_amount' => 'decimal:2',
            'seller_net_amount' => 'decimal:2',
            'shipping_address_snapshot' => 'array',
            'cancellation_requested' => 'boolean',
            'payment_expires_at' => 'datetime',
            'paid_at' => 'datetime',
            'preparing_at' => 'datetime',
            'shipped_at' => 'datetime',
            'delivered_at' => 'datetime',
            'auto_complete_at' => 'datetime',
            'escrow_frozen_at' => 'datetime',
            'completed_at' => 'datetime',
            'cancelled_at' => 'datetime',
        ];
    }

    // Relationships
    public function buyer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'buyer_id');
    }

    public function seller(): BelongsTo
    {
        return $this->belongsTo(User::class, 'seller_id');
    }

    public function auction(): BelongsTo
    {
        return $this->belongsTo(Auction::class, 'auction_id');
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class, 'order_id');
    }

    public function shipment(): HasOne
    {
        return $this->hasOne(Shipment::class, 'order_id');
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class, 'order_id');
    }

    public function paidPayment(): HasOne
    {
        return $this->hasOne(Payment::class, 'order_id')->where('status', 'PAID');
    }

    public function escrowTransactions(): HasMany
    {
        return $this->hasMany(EscrowTransaction::class, 'order_id');
    }

    public function walletTransaction(): HasOne
    {
        return $this->hasOne(WalletTransaction::class, 'order_id');
    }

    public function dispute(): HasOne
    {
        return $this->hasOne(Dispute::class, 'order_id');
    }

    public function review(): HasOne
    {
        return $this->hasOne(Review::class, 'order_id');
    }
}
