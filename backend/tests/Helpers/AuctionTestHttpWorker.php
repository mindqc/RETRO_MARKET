<?php

/**
 * P9-02 Test Helper: Independent HTTP Auction Bid Worker
 *
 * Runs as an independent OS process, queries its own PostgreSQL backend PID,
 * waits for a synchronization barrier, and sends an authenticated HTTP request
 * to the real local Laravel API endpoint.
 */

if ($argc < 7) {
    fwrite(STDERR, "Usage: php AuctionTestHttpWorker.php <worker_id> <target_url> <auction_id> <token> <bid_amount> <barrier_path>\n");
    exit(1);
}

$workerId = $argv[1];
$targetUrl = rtrim($argv[2], '/');
$auctionId = (int) $argv[3];
$token = $argv[4];
$bidAmount = (float) $argv[5];
$barrierPath = $argv[6];

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

// Signal readiness to parent test process
$readyFile = "{$barrierPath}.ready.{$workerId}";
file_put_contents($readyFile, (string) time());

// Wait for parent barrier release (.go file)
$goFile = "{$barrierPath}.go";
$waitStart = microtime(true);
$timedOut = false;

while (!file_exists($goFile)) {
    if ((microtime(true) - $waitStart) > 10.0) {
        $timedOut = true;
        break;
    }
    usleep(500); // 0.5ms tight polling
}

if ($timedOut) {
    echo json_encode([
        'worker_id' => $workerId,
        'backend_pid' => $pid,
        't_start' => null,
        't_end' => null,
        'duration_ms' => null,
        'http_status' => 0,
        'response_json' => null,
        'raw_response' => null,
        'error' => 'Timed out waiting for start barrier release (.go file).',
    ]);
    exit(1);
}

// Execute authenticated HTTP request via native cURL
$endpoint = "{$targetUrl}/api/v1/auctions/{$auctionId}/bids";
$payload = json_encode(['bid_amount' => $bidAmount]);

$ch = curl_init($endpoint);
curl_setopt_array($ch, [
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => $payload,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        "Authorization: Bearer {$token}",
        'Accept: application/json',
        'Content-Type: application/json',
    ],
    CURLOPT_TIMEOUT => 15,
    CURLOPT_CONNECTTIMEOUT => 5,
]);

$tStart = microtime(true);
$rawResponse = curl_exec($ch);
$tEnd = microtime(true);

$httpStatus = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);
curl_close($ch);

$parsedJson = json_decode($rawResponse, true);

echo json_encode([
    'worker_id' => $workerId,
    'backend_pid' => $pid,
    't_start' => $tStart,
    't_end' => $tEnd,
    'duration_ms' => round(($tEnd - $tStart) * 1000, 2),
    'http_status' => $httpStatus,
    'response_json' => $parsedJson,
    'raw_response' => $rawResponse,
    'error' => !empty($curlError) ? $curlError : null,
]);
exit(0);
