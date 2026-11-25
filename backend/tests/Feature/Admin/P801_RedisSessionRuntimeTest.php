<?php

namespace Tests\Feature\Admin;

use Illuminate\Support\Facades\Redis;
use Illuminate\Support\Facades\Session;
use Illuminate\Support\Str;
use Tests\TestCase;

class P801_RedisSessionRuntimeTest extends TestCase
{
    /**
     * Test AC-P801-03: Redis 7.4 runtime connectivity and session isolation.
     * Note: FLUSHDB and FLUSHALL are strictly forbidden. Only isolated test keys are used.
     */
    public function test_redis_runtime_connectivity_and_ping(): void
    {
        $redis = Redis::connection();
        $this->assertNotNull($redis, 'Redis connection instance should be available.');

        $pong = $redis->ping();
        // PhpRedis returns true or '+PONG', Predis returns Status object
        $this->assertTrue(
            $pong === true || $pong === '+PONG' || (is_object($pong) && method_exists($pong, 'getPayload') && $pong->getPayload() === 'PONG') || (string)$pong === 'PONG',
            'Redis 7.4 must respond to PING with PONG.'
        );
    }

    /**
     * Test isolated session write, read, and delete on Redis 7.4 without FLUSHDB/FLUSHALL.
     */
    public function test_isolated_session_lifecycle_on_redis(): void
    {
        $testKey = 'admin_session_runtime_test:' . Str::random(16);
        $payload = json_encode([
            'session_id' => Str::random(40),
            'admin_user_id' => 1,
            'role' => 'admin',
            'created_at' => now()->timestamp,
        ]);

        $redis = Redis::connection();

        try {
            // Write with 60s TTL
            $redis->setex($testKey, 60, $payload);

            // Read back
            $stored = $redis->get($testKey);
            $this->assertNotNull($stored);
            $this->assertEquals($payload, $stored);

            $decoded = json_decode($stored, true);
            $this->assertEquals('admin', $decoded['role']);
            $this->assertEquals(1, $decoded['admin_user_id']);

            // Verify TTL is active
            $ttl = $redis->ttl($testKey);
            $this->assertGreaterThan(0, $ttl);
            $this->assertLessThanOrEqual(60, $ttl);
        } finally {
            // Strictly delete only the test key (never FLUSHDB/FLUSHALL)
            $redis->del($testKey);
        }

        // Verify key deletion
        $this->assertNull($redis->get($testKey));
    }

    /**
     * Test Laravel session store runtime with Redis driver.
     */
    public function test_laravel_session_with_redis_driver(): void
    {
        $originalDriver = config('session.driver');
        config(['session.driver' => 'redis']);

        $sessionManager = app('session');
        $session = $sessionManager->driver('redis');

        $testSessionId = 'p801_test_' . Str::random(24);
        $session->setId($testSessionId);
        $session->start();

        try {
            $session->put('admin_auth_test', [
                'user_id' => 99,
                'role' => 'admin',
                'login_time' => now()->toIso8601String(),
            ]);
            $session->save();

            // Re-read from driver
            $freshSession = $sessionManager->driver('redis');
            $freshSession->setId($testSessionId);
            $freshSession->start();

            $data = $freshSession->get('admin_auth_test');
            $this->assertIsArray($data);
            $this->assertEquals('admin', $data['role']);
            $this->assertEquals(99, $data['user_id']);
        } finally {
            $session->invalidate();
            $session->save();
            config(['session.driver' => $originalDriver]);
        }
    }
}
