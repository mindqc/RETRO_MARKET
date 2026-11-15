<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Demo Mode Settings
    |--------------------------------------------------------------------------
    |
    | When DEMO_MODE is true, expiration timers are significantly shortened,
    | and Developer Tools (manual job triggers) are enabled in Admin Web.
    |
    */
    'demo_mode' => (bool) env('DEMO_MODE', false),

    /*
    |--------------------------------------------------------------------------
    | Upload Constraints
    |--------------------------------------------------------------------------
    |
    | Maximum allowed upload file size in Kilobytes (Default: 5120 KB = 5 MB).
    | Enforced by NFR-SEC-05.
    |
    */
    'max_upload_kb' => (int) env('RETRO_MAX_UPLOAD_KB', 5120),

    /*
    |--------------------------------------------------------------------------
    | Default Financial Settings (DEC-04)
    |--------------------------------------------------------------------------
    */
    'default_protection_fee_rate' => 0.06, // 6%
    'default_protection_fixed_fee' => 7000.00, // 7.000 VND
    'default_shipping_fee' => 0.00, // 0 VND on platform
    'default_seller_commission_rate' => 0.00, // 0%
];
