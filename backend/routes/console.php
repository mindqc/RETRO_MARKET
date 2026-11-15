<?php

use App\Jobs\AutoCompleteDeliveredOrdersJob;
use App\Jobs\CloseExpiredAuctionsJob;
use App\Jobs\ExpireUnpaidAuctionOrdersJob;
use App\Jobs\OpenScheduledAuctionsJob;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

/*
|--------------------------------------------------------------------------
| RETRO MARKET (izithrift) - Scheduled Background Jobs (P6-09)
|--------------------------------------------------------------------------
*/

Schedule::job(new OpenScheduledAuctionsJob)
    ->everyMinute()
    ->withoutOverlapping();

Schedule::job(new CloseExpiredAuctionsJob)
    ->everyMinute()
    ->withoutOverlapping();

Schedule::job(new ExpireUnpaidAuctionOrdersJob)
    ->everyMinute()
    ->withoutOverlapping();

Schedule::job(new AutoCompleteDeliveredOrdersJob)
    ->everyMinute()
    ->withoutOverlapping();
