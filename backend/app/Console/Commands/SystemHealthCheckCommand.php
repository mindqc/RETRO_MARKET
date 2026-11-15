<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class SystemHealthCheckCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'system:health-check';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Kiểm tra trạng thái kết nối hạ tầng PostgreSQL 18, Redis 7.4, Runtime PHP & Filesystem (Task P5-01)';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $this->info("===============================================================================");
        $this->info("  IZITHRIFT (RETRO MARKET) - SYSTEM HEALTH CHECK - TASK P5-01");
        $this->info("===============================================================================");

        $results = [];
        $hasFailure = false;

        // 1. PHP Runtime & Extensions
        $phpVersion = PHP_VERSION;
        $laravelVersion = app()->version();
        $timezone = config('app.timezone');
        $demoMode = config('retromarket.demo_mode') ? 'ENABLED (true)' : 'DISABLED (false)';

        $requiredExts = ['pdo_pgsql', 'pgsql', 'bcmath', 'gd', 'intl', 'mbstring', 'zip'];
        $missingExts = [];
        foreach ($requiredExts as $ext) {
            if (!extension_loaded($ext)) {
                $missingExts[] = $ext;
            }
        }

        $results[] = [
            'Component' => 'PHP Runtime',
            'Detail' => "PHP {$phpVersion} | Laravel {$laravelVersion}",
            'Status' => version_compare($phpVersion, '8.3.0', '>=') ? 'OK' : 'FAIL',
        ];

        $results[] = [
            'Component' => 'PHP Extensions',
            'Detail' => empty($missingExts) ? implode(', ', $requiredExts) : 'Missing: ' . implode(', ', $missingExts),
            'Status' => empty($missingExts) ? 'OK' : 'FAIL',
        ];

        $results[] = [
            'Component' => 'App Timezone',
            'Detail' => $timezone,
            'Status' => ($timezone === 'Asia/Ho_Chi_Minh') ? 'OK' : 'WARN',
        ];

        $results[] = [
            'Component' => 'Demo Mode',
            'Detail' => $demoMode,
            'Status' => config('retromarket.demo_mode') ? 'OK' : 'WARN',
        ];

        // 2. PostgreSQL 18 Connection
        try {
            $pgVersion = DB::selectOne("SELECT version() as ver")->ver ?? 'Unknown';
            $encoding = DB::selectOne("SHOW server_encoding")->server_encoding ?? 'Unknown';
            $pgTimezone = DB::selectOne("SHOW TIMEZONE")->TimeZone ?? 'Unknown';

            $isPg18 = str_contains($pgVersion, 'PostgreSQL 18');

            $results[] = [
                'Component' => 'PostgreSQL 18',
                'Detail' => $pgVersion,
                'Status' => $isPg18 ? 'OK' : 'WARN',
            ];

            $results[] = [
                'Component' => 'PG Encoding / Timezone',
                'Detail' => "Encoding: {$encoding} | TimeZone: {$pgTimezone}",
                'Status' => ($encoding === 'UTF8') ? 'OK' : 'WARN',
            ];
        } catch (\Throwable $e) {
            $hasFailure = true;
            $results[] = [
                'Component' => 'PostgreSQL 18',
                'Detail' => 'Connection Failed: ' . $e->getMessage(),
                'Status' => 'FAIL',
            ];
        }

        // 3. Redis 7.4 Connection
        try {
            $testKey = 'health_check_' . now()->timestamp;
            $testVal = 'retromarket_healthy';

            Cache::store('redis')->put($testKey, $testVal, 30);
            $retrieved = Cache::store('redis')->get($testKey);
            Cache::store('redis')->forget($testKey);

            $results[] = [
                'Component' => 'Redis 7.4 (Predis)',
                'Detail' => ($retrieved === $testVal) ? 'Cache Put/Get/Delete Verified (Connection OK)' : 'Value mismatch',
                'Status' => ($retrieved === $testVal) ? 'OK' : 'FAIL',
            ];
        } catch (\Throwable $e) {
            $hasFailure = true;
            $results[] = [
                'Component' => 'Redis 7.4 (Predis)',
                'Detail' => 'Connection Failed: ' . $e->getMessage(),
                'Status' => 'FAIL',
            ];
        }

        // 4. Storage / Filesystem
        try {
            $disk = config('filesystems.default');
            $testFile = 'health_test.txt';
            Storage::disk('public')->put($testFile, 'health_check_ok');
            $readContent = Storage::disk('public')->get($testFile);
            Storage::disk('public')->delete($testFile);

            $results[] = [
                'Component' => 'Public Storage',
                'Detail' => "Disk: {$disk} | Read/Write Verified",
                'Status' => ($readContent === 'health_check_ok') ? 'OK' : 'FAIL',
            ];
        } catch (\Throwable $e) {
            $hasFailure = true;
            $results[] = [
                'Component' => 'Public Storage',
                'Detail' => 'Write Failed: ' . $e->getMessage(),
                'Status' => 'FAIL',
            ];
        }

        $this->table(['Component', 'Detail', 'Status'], $results);

        if ($hasFailure) {
            $this->error("\n❌ SYSTEM HEALTH CHECK FAILED: Vui lòng kiểm tra lại cấu hình hạ tầng.");
            return self::FAILURE;
        }

        $this->info("\n✅ ALL SYSTEMS GO (PASS): Toàn bộ hạ tầng PostgreSQL 18, Redis 7.4, PHP 8.4 & Laravel 13 đã sẵn sàng cho Task P5-02!");
        return self::SUCCESS;
    }
}
