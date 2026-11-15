<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Conversation extends Model
{
    use HasFactory;

    protected $table = 'conversations';

    protected $fillable = [
        'user_one_id',
        'user_two_id',
        'context_product_id',
        'context_order_id',
        'last_message_preview',
        'last_message_at',
        'blocked_by_user_id',
    ];

    protected function casts(): array
    {
        return [
            'last_message_at' => 'datetime',
        ];
    }

    /**
     * Normalize user participant IDs so user_one_id < user_two_id (satisfies chk_conversation_user_order).
     */
    public static function normalizeParticipants(int $u1, int $u2): array
    {
        return [min($u1, $u2), max($u1, $u2)];
    }

    public function userOne(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_one_id');
    }

    public function userTwo(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_two_id');
    }

    public function contextProduct(): BelongsTo
    {
        return $this->belongsTo(Product::class, 'context_product_id');
    }

    public function contextOrder(): BelongsTo
    {
        return $this->belongsTo(Order::class, 'context_order_id');
    }

    public function blockedByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'blocked_by_user_id');
    }

    public function messages(): HasMany
    {
        return $this->hasMany(Message::class, 'conversation_id');
    }
}
