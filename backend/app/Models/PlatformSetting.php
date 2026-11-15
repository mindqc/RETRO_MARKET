<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PlatformSetting extends Model
{
    use HasFactory;

    public const CREATED_AT = null;

    protected $table = 'platform_settings';

    protected $primaryKey = 'key';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'key',
        'value',
        'value_type',
        'description',
        'updated_by',
    ];

    public function updater(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    /**
     * Retrieve and cast setting value by key.
     */
    public static function getValue(string $key, mixed $default = null): mixed
    {
        $setting = static::query()->find($key);

        if (! $setting) {
            return $default;
        }

        return match ($setting->value_type) {
            'INTEGER' => (int) $setting->value,
            'DECIMAL' => (float) $setting->value,
            'BOOLEAN' => filter_var($setting->value, FILTER_VALIDATE_BOOLEAN),
            default => $setting->value,
        };
    }
}
