<?php

/**
 * P9-02 Test Helper: Direct Row-Lock Contention Worker
 *
 * Runs as an independent OS process, connects independently to PostgreSQL,
 * and executes a transaction with SELECT ... FOR UPDATE on an auction record
 * to demonstrate temporal overlap and row-level lock blocking.
 */

if ($argc < 6) {
    fwrite(STDERR, "Usage: php AuctionLockContentionWorker.php <worker_id> <auction_id> <hold_us> <delay_us> <barrier_path>\n");
    exit(1);
}

$workerId = $argv[1];
$auctionId = (int) $argv[2];
$holdUs = (int) $argv[3];
$delayUs = (int) $argv[4];
$barrierPath = $argv[5];

$backendDir = realpath(__DIR__ . '/../..');
require $backendDir . '/vendor/autoload.php';
$app = require $backendDir . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

// Query independent PostgreSQL backend PID
$pid = null;
try {
    $pidRow = DB::selectOne("SELECT pg_backend_pid() AS pid");
    $pid = $pidRow ? (int) $pidRow->pid : null;
} catch (\Throwable $e) {
    $pid = null;
}

// Signal readiness
$readyFile = "{$barrierPath}.ready.{$workerId}";
file_put_contents($readyFile, (string) time());

// Wait for start barrier
$goFile = "{$barrierPath}.go";
$waitStart = microtime(true);
$timedOut = false;

while (!file_exists($goFile)) {
    if ((microtime(true) - $waitStart) > 10.0) {
        $timedOut = true;
        break;
    }
    usleep(500);
}

if ($timedOut) {
    echo json_encode([
        'worker_id' => $workerId,
        'backend_pid' => $pid,
        'error' => 'Timed out waiting for start barrier.',
    ]);
    exit(1);
}

if ($delayUs > 0) {
    usleep($delayUs);
}

$tBefore = microtime(true);
$tAcquired = 0;
$tReleased = 0;

try {
    DB::transaction(function () use ($auctionId, $holdUs, &$tAcquired, &$tReleased) {
        DB::select("SELECT id, current_highest_bid FROM auctions WHERE id = ? FOR UPDATE", [$auctionId]);
        $tAcquired = microtime(true);
        if ($holdUs > 0) {
            usleep($holdUs);
        }
        $tReleased = microtime(true);
    });

    echo json_encode([
        'worker_id' => $workerId,
        'backend_pid' => $pid,
        't_before' => $tBefore,
        't_acquired' => $tAcquired,
        't_released' => $tReleased,
        'wait_duration_ms' => round(($tAcquired - $tBefore) * 1000, 2),
        'held_duration_ms' => round(($tReleased - $tAcquired) * 1000, 2),
        'error' => null,
    ]);
    exit(0);
} catch (\Throwable $e) {
    echo json_encode([
        'worker_id' => $workerId,
        'backend_pid' => $pid,
        't_before' => $tBefore,
        't_acquired' => null,
        't_released' => null,
        'wait_duration_ms' => null,
        'held_duration_ms' => null,
        'error' => $e->getMessage(),
    ]);
    exit(1);
}
