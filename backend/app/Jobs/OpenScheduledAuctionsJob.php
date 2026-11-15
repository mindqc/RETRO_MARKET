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

class OpenScheduledAuctionsJob implements ShouldQueue, ShouldBeUnique
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public array $backoff = [5, 15, 30];
    public int $uniqueFor = 55;

    public function handle(AuctionLifecycleService $auctionLifecycleService): void
    {
        $result = $auctionLifecycleService->openDueScheduledAuctions();

        if ($result['opened_count'] > 0) {
            Log::info("OpenScheduledAuctionsJob: Successfully opened {$result['opened_count']} scheduled auctions to LIVE.", [
                'auction_ids' => $result['opened_auction_ids'],
            ]);
        }
    }
}
