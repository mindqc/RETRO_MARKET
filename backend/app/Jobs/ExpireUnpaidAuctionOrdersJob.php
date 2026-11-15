<?php

namespace App\Jobs;

use App\Services\Order\OrderExpirationService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldBeUnique;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class ExpireUnpaidAuctionOrdersJob implements ShouldQueue, ShouldBeUnique
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public array $backoff = [5, 15, 30];
    public int $uniqueFor = 55;

    public function handle(OrderExpirationService $orderExpirationService): void
    {
        $result = $orderExpirationService->expireOverdueUnpaidOrders();

        if ($result['expired_orders_count'] > 0) {
            Log::info("ExpireUnpaidAuctionOrdersJob: Expired {$result['expired_orders_count']} overdue unpaid orders.", [
                'defaulted_auctions' => $result['defaulted_auctions_count'],
                'order_ids' => $result['expired_order_ids'],
            ]);
        }
    }
}
