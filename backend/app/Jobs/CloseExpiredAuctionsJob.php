<?php

namespace App\Jobs;

use App\Services\Auction\AuctionLifecycleService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldBeUnique;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class CloseExpiredAuctionsJob implements ShouldQueue, ShouldBeUnique
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public array $backoff = [5, 15, 30];
    public int $uniqueFor = 55;

    public function handle(AuctionLifecycleService $auctionLifecycleService): void
    {
        $result = $auctionLifecycleService->closeExpiredLiveAuctions();

        $totalProcessed = $result['completed_count'] + $result['unsold_count'];

        if ($totalProcessed > 0) {
            Log::info("CloseExpiredAuctionsJob: Processed {$totalProcessed} expired live auctions.", [
                'completed_count' => $result['completed_count'],
                'unsold_count' => $result['unsold_count'],
                'completed_ids' => $result['completed_auction_ids'],
                'unsold_ids' => $result['unsold_auction_ids'],
            ]);
        }
    }
}
