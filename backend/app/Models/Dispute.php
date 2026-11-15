<?php

namespace App\Models;

use App\Enums\DisputeStatus;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Dispute extends Model
{
    use HasFactory;

    protected $table = 'disputes';

    protected $fillable = [
        'dispute_code',
        'order_id',
        'buyer_id',
        'seller_id',
        'opened_at_order_status',
        'reason_category',
        'buyer_description',
        'seller_response',
        'assigned_support_id',
        'status',
        'admin_verdict',
        'partial_refund_to_buyer',
        'resolution_note',
        'resolved_by_admin_id',
        'resolved_at',
    ];

    protected function casts(): array
    {
        return [
            'status' => DisputeStatus::class,
            'partial_refund_to_buyer' => 'decimal:2',
            'resolved_at' => 'datetime',
        ];
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class, 'order_id');
    }

    public function buyer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'buyer_id');
    }

    public function seller(): BelongsTo
    {
        return $this->belongsTo(User::class, 'seller_id');
    }

    public function assignedSupport(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assigned_support_id');
    }

    public function resolvedByAdmin(): BelongsTo
    {
        return $this->belongsTo(User::class, 'resolved_by_admin_id');
    }

    public function evidences(): HasMany
    {
        return $this->hasMany(DisputeEvidence::class, 'dispute_id');
    }
}
