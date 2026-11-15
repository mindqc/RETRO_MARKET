<?php

namespace App\Services\Governance;

use App\Models\PlatformSetting;
use Illuminate\Support\Facades\Cache;

class PlatformConfigService
{
    /**
     * Get a setting value with caching.
     */
    public function get(string $key, mixed $default = null): mixed
    {
        return Cache::remember("platform_setting_{$key}", 3600, function () use ($key, $default) {
            return PlatformSetting::getValue($key, $default);
        });
    }

    /**
     * Clear cached setting(s).
     */
    public function clearCache(?string $key = null): void
    {
        if ($key !== null) {
            Cache::forget("platform_setting_{$key}");
            return;
        }

        $commonKeys = [
            'protection_fee_rate',
            'protection_fixed_fee',
            'shipping_fee_default',
            'seller_commission_rate',
            'auction_payment_window_production_sec',
            'auction_payment_window_demo_sec',
            'auto_complete_window_production_sec',
            'auto_complete_window_demo_sec',
            'anti_sniping_trigger_window_production_sec',
            'anti_sniping_trigger_window_demo_sec',
            'anti_sniping_extend_duration_production_sec',
            'anti_sniping_extend_duration_demo_sec',
        ];

        foreach ($commonKeys as $k) {
            Cache::forget("platform_setting_{$k}");
        }
    }

    /**
     * Check if DEMO_MODE is active.
     */
    public function isDemoMode(): bool
    {
        return (bool) config('retromarket.demo_mode', false);
    }

    /**
     * Buyer Protection Fee Rate (Default 0.06 = 6%).
     */
    public function protectionFeeRate(): float
    {
        return (float) $this->get('protection_fee_rate', config('retromarket.default_protection_fee_rate', 0.06));
    }

    /**
     * Buyer Protection Fixed Fee (Default 7000.00 VND).
     */
    public function protectionFixedFee(): float
    {
        return (float) $this->get('protection_fixed_fee', config('retromarket.default_protection_fixed_fee', 7000.0));
    }

    /**
     * Calculate Buyer Protection Fee, shipping, total amount, and seller net amount.
     * Enforces DEC-04:
     * - Protection Fee = ROUND(item_subtotal * rate) + fixed_fee
     * - Shipping Fee = 0.00 (handled off-platform or direct)
     * - Total Amount = item_subtotal + shipping_fee + buyer_protection_fee
     * - Seller Net Amount = item_subtotal (0% commission)
     *
     * @return array{
     *     item_subtotal: string,
     *     shipping_fee: string,
     *     protection_fee_rate: string,
     *     protection_fixed_fee: string,
     *     buyer_protection_fee: string,
     *     total_amount: string,
     *     seller_net_amount: string
     * }
     */
    public function calculateBuyerProtectionFee(float|string $itemSubtotal): array
    {
        $subtotal = round((float) $itemSubtotal, 2);
        $rate = $this->protectionFeeRate();
        $fixed = $this->protectionFixedFee();

        $fee = round($subtotal * $rate) + $fixed;
        $shipping = 0.00;
        $total = $subtotal + $shipping + $fee;
        $sellerNetAmount = $subtotal;

        return [
            'item_subtotal' => number_format($subtotal, 2, '.', ''),
            'shipping_fee' => number_format($shipping, 2, '.', ''),
            'protection_fee_rate' => number_format($rate, 4, '.', ''),
            'protection_fixed_fee' => number_format($fixed, 2, '.', ''),
            'buyer_protection_fee' => number_format($fee, 2, '.', ''),
            'total_amount' => number_format($total, 2, '.', ''),
            'seller_net_amount' => number_format($sellerNetAmount, 2, '.', ''),
        ];
    }

    /**
     * Auction winner payment window in seconds (Production: 1800s, Demo: 120s).
     */
    public function auctionWinnerPaymentWindowSeconds(): int
    {
        return $this->isDemoMode()
            ? (int) $this->get('auction_payment_window_demo_sec', 120)
            : (int) $this->get('auction_payment_window_production_sec', 1800);
    }

    /**
     * Auction winner payment deadline in minutes (e.g. 30 min in prod, 2 min in demo).
     */
    public function auctionWinnerPaymentDeadlineMinutes(): int
    {
        return (int) ceil($this->auctionWinnerPaymentWindowSeconds() / 60);
    }

    /**
     * Order auto-complete window in seconds (Production: 86400s = 24h, Demo: 120s = 2m).
     */
    public function autoCompleteWindowSeconds(): int
    {
        return $this->isDemoMode()
            ? (int) $this->get('auto_complete_window_demo_sec', 120)
            : (int) $this->get('auto_complete_window_production_sec', 86400);
    }

    /**
     * Order auto-complete window duration in seconds (alias for autoCompleteWindowSeconds).
     */
    public function orderAutoCompleteDurationSeconds(): int
    {
        return $this->autoCompleteWindowSeconds();
    }

    /**
     * Anti-sniping trigger window in seconds (Production: 120s, Demo: 30s).
     */
    public function antiSnipingWindowSeconds(): int
    {
        return $this->isDemoMode()
            ? (int) $this->get('anti_sniping_trigger_window_demo_sec', 30)
            : (int) $this->get('anti_sniping_trigger_window_production_sec', 120);
    }

    /**
     * Anti-sniping extension duration in seconds (Production: 120s, Demo: 30s).
     */
    public function antiSnipingExtensionSeconds(): int
    {
        return $this->isDemoMode()
            ? (int) $this->get('anti_sniping_extend_duration_demo_sec', 30)
            : (int) $this->get('anti_sniping_extend_duration_production_sec', 120);
    }

    /**
     * Get public configuration array for client bootstrap (M-AU-01).
     */
    public function getPublicBootstrapConfig(): array
    {
        return [
            'server_time' => now()->toIso8601String(),
            'demo_mode' => $this->isDemoMode(),
            'protection_fee_rate' => $this->protectionFeeRate(),
            'protection_fixed_fee' => $this->protectionFixedFee(),
            'shipping_fee_default' => (float) $this->get('shipping_fee_default', 0.0),
            'seller_commission_rate' => (float) $this->get('seller_commission_rate', 0.0),
            'auction_payment_deadline_minutes' => $this->auctionWinnerPaymentDeadlineMinutes(),
            'auction_payment_window_seconds' => $this->auctionWinnerPaymentWindowSeconds(),
            'auto_complete_window_seconds' => $this->autoCompleteWindowSeconds(),
        ];
    }
}
