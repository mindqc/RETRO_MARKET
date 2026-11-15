<?php

namespace App\Jobs;

use App\Services\Escrow\EscrowReleaseService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldBeUnique;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class AutoCompleteDeliveredOrdersJob implements ShouldQueue, ShouldBeUnique
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public array $backoff = [5, 15, 30];
    public int $uniqueFor = 55;

    public function handle(EscrowReleaseService $escrowReleaseService): void
    {
        $result = $escrowReleaseService->autoCompleteDueDeliveredOrders();

        if ($result['auto_completed_count'] > 0) {
            Log::info("AutoCompleteDeliveredOrdersJob: Auto-completed and released escrow for {$result['auto_completed_count']} delivered orders.", [
                'order_ids' => $result['auto_completed_order_ids'],
            ]);
        }
    }
}
