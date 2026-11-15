<?php

namespace App\Providers;

use App\Models\Auction;
use App\Models\Conversation;
use App\Models\Dispute;
use App\Models\Order;
use App\Models\Product;
use App\Models\Review;
use App\Policies\AuctionPolicy;
use App\Policies\ConversationPolicy;
use App\Policies\DisputePolicy;
use App\Policies\OrderPolicy;
use App\Policies\ProductPolicy;
use App\Policies\ReviewPolicy;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // 1. Rate Limiters
        RateLimiter::for('auth', function (Request $request) {
            return Limit::perMinute(5)->by($request->ip());
        });

        RateLimiter::for('transactional', function (Request $request) {
            return Limit::perMinute(30)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('polling', function (Request $request) {
            return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip());
        });

        // 2. Eloquent RBAC Policies Registration (P6-02)
        Gate::policy(Product::class, ProductPolicy::class);
        Gate::policy(Auction::class, AuctionPolicy::class);
        Gate::policy(Order::class, OrderPolicy::class);
        Gate::policy(Dispute::class, DisputePolicy::class);
        Gate::policy(Conversation::class, ConversationPolicy::class);
        Gate::policy(Review::class, ReviewPolicy::class);
    }
}
