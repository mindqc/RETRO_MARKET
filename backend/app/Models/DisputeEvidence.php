<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DisputeEvidence extends Model
{
    use HasFactory;

    public const UPDATED_AT = null;

    protected $table = 'dispute_evidences';

    protected $fillable = [
        'dispute_id',
        'uploader_id',
        'uploader_role',
        'evidence_type',
        'file_url',
        'message_note',
    ];

    public function dispute(): BelongsTo
    {
        return $this->belongsTo(Dispute::class, 'dispute_id');
    }

    public function uploader(): BelongsTo
    {
        return $this->belongsTo(User::class, 'uploader_id');
    }
}
