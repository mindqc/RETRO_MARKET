<?php

namespace App\Models;

use App\Models\Concerns\ImmutableLedgerRecord;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderItem extends Model
{
    use HasFactory, ImmutableLedgerRecord;

    public const UPDATED_AT = null;

    protected $table = 'order_items';

    protected $fillable = [
        'order_id',
        'product_id',
        'product_code_snapshot',
        'product_title_snapshot',
        'condition_snapshot',
        'defect_info_snapshot',
        'primary_image_snapshot',
        'unit_price_snapshot',
        'quantity',
        'line_total',
    ];

    protected function casts(): array
    {
        return [
            'unit_price_snapshot' => 'decimal:2',
            'quantity' => 'integer',
            'line_total' => 'decimal:2',
        ];
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class, 'order_id');
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class, 'product_id');
    }
}
