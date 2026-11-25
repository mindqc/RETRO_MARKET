<?php

namespace Tests\Helpers;

/**
 * P9-02 Test Helper: Local Dual-Port HTTP Server Manager
 *
 * Spawns two independent PHP built-in web servers on distinct ports
 * to allow genuine concurrent HTTP requests without web-server-level serialization on Windows.
 */
class LocalHttpServerManager
{
    protected static ?array $servers = null;
    protected static int $port1 = 8911;
    protected static int $port2 = 8912;

    public static function getPort1(): int
    {
        return self::$port1;
    }

    public static function getPort2(): int
    {
        return self::$port2;
    }

    public static function getUrl1(): string
    {
        return "http://127.0.0.1:" . self::$port1;
    }

    public static function getUrl2(): string
    {
        return "http://127.0.0.1:" . self::$port2;
    }

    /**
     * Start the dual web servers if not already running.
     */
    public static function start(): void
    {
        if (self::$servers !== null) {
            return;
        }

        $backendDir = realpath(__DIR__ . '/../..');
        $publicDir = $backendDir . DIRECTORY_SEPARATOR . 'public';

        $descriptors = [
            0 => ['pipe', 'r'],
            1 => ['file', 'NUL', 'w'],
            2 => ['file', 'NUL', 'w'],
        ];

        $cmd1 = sprintf('php -S 127.0.0.1:%d -t "%s"', self::$port1, $publicDir);
        $cmd2 = sprintf('php -S 127.0.0.1:%d -t "%s"', self::$port2, $publicDir);

        $process1 = proc_open($cmd1, $descriptors, $pipes1, $backendDir);
        $process2 = proc_open($cmd2, $descriptors, $pipes2, $backendDir);

        self::$servers = [
            'process1' => $process1,
            'process2' => $process2,
        ];

        register_shutdown_function([self::class, 'stop']);

        // Poll both ports until ready (timeout 5s)
        self::waitForPort(self::$port1, 5000);
        self::waitForPort(self::$port2, 5000);
    }

    /**
     * Stop both web servers.
     */
    public static function stop(): void
    {
        if (self::$servers === null) {
            return;
        }

        foreach (['process1', 'process2'] as $pKey) {
            if (isset(self::$servers[$pKey]) && is_resource(self::$servers[$pKey])) {
                @proc_terminate(self::$servers[$pKey]);
                @proc_close(self::$servers[$pKey]);
            }
        }

        self::$servers = null;
        usleep(100000); // 100ms cooldown for socket release
    }

    /**
     * Wait for a port to accept connections.
     */
    protected static function waitForPort(int $port, int $timeoutMs): void
    {
        $start = microtime(true);
        while ((microtime(true) - $start) * 1000 < $timeoutMs) {
            $ch = curl_init("http://127.0.0.1:{$port}/api/v1/auctions");
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_TIMEOUT_MS => 250,
                CURLOPT_CONNECTTIMEOUT_MS => 250,
            ]);
            curl_exec($ch);
            $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            if ($code > 0) {
                return;
            }
            usleep(40000); // 40ms
        }
        throw new \RuntimeException("Local test HTTP server on port {$port} failed to start within {$timeoutMs}ms.");
    }
}
