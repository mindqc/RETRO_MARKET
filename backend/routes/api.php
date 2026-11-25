<?php

use App\Http\Controllers\Api\V1\AddressController;
use App\Http\Controllers\Api\V1\AuctionController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\BootstrapController;
use App\Http\Controllers\Api\V1\BuyerOrderController;
use App\Http\Controllers\Api\V1\CartController;
use App\Http\Controllers\Api\V1\CatalogController;
use App\Http\Controllers\Api\V1\CheckoutController;
use App\Http\Controllers\Api\V1\ConversationController;
use App\Http\Controllers\Api\V1\DisputeController;
use App\Http\Controllers\Api\V1\EngagementController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\PaymentController;
use App\Http\Controllers\Api\V1\ProductController;
use App\Http\Controllers\Api\V1\ProfileController;
use App\Http\Controllers\Api\V1\ReportController;
use App\Http\Controllers\Api\V1\ReviewController;
use App\Http\Controllers\Api\V1\SellerOrderController;
use App\Http\Controllers\Api\V1\SellerProductController;
use App\Http\Controllers\Api\V1\SellerStorefrontController;
use App\Http\Controllers\Api\V1\SellerWalletController;
use App\Http\Controllers\Api\V1\SystemDevToolsController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| RETRO MARKET (izithrift) - REST API Routes (/api/v1)
|--------------------------------------------------------------------------
*/

Route::prefix('v1')->group(function () {
    Route::get('/health', [BootstrapController::class, 'health']);
    Route::get('/bootstrap', [BootstrapController::class, 'bootstrap'])
        ->middleware(['optional.sanctum', 'active.user']);

    // 1. Authentication Routes (P6-02)
    Route::prefix('auth')->group(function () {
        Route::post('/register', [AuthController::class, 'register'])
            ->middleware('throttle:auth');
        Route::post('/login', [AuthController::class, 'login'])
            ->middleware('throttle:auth');
        Route::post('/logout', [AuthController::class, 'logout'])
            ->middleware(['auth:sanctum', 'active.user']);
        Route::post('/forgot-password', [AuthController::class, 'forgotPassword'])
            ->middleware('throttle:auth');
        Route::post('/reset-password', [AuthController::class, 'resetPassword'])
            ->middleware('throttle:auth');
    });

    // 2. Public Catalog & Storefront Routes (P6-03)
    Route::middleware(['optional.sanctum', 'active.user'])->group(function () {
        Route::get('/home', [CatalogController::class, 'home']);
        Route::get('/catalog/taxonomy', [CatalogController::class, 'taxonomy']);
        Route::get('/sellers/{id}', [SellerStorefrontController::class, 'show']);
        Route::get('/sellers/{id}/reviews', [SellerStorefrontController::class, 'reviews']);
    });

    // 3. User Profile & Address Book Routes (P6-03)
    Route::middleware(['auth:sanctum', 'active.user'])->prefix('profile')->group(function () {
        Route::get('/', [ProfileController::class, 'show']);
        Route::post('/', [ProfileController::class, 'update']);
        Route::put('/', [ProfileController::class, 'update']);
        Route::put('/settings', [ProfileController::class, 'updateSettings']);
        Route::put('/password', [ProfileController::class, 'changePassword']);

        // Address Book
        Route::get('/addresses', [AddressController::class, 'index']);
        Route::post('/addresses', [AddressController::class, 'store']);
        Route::put('/addresses/{id}', [AddressController::class, 'update']);
        Route::delete('/addresses/{id}', [AddressController::class, 'destroy']);
    });

    // 4. Public Product Discovery Routes (P6-04)
    Route::middleware(['optional.sanctum', 'active.user'])->group(function () {
        Route::get('/products', [ProductController::class, 'index']);
        Route::get('/products/{id}', [ProductController::class, 'show']);
    });

    // 5. Seller Product Management Routes (P6-04)
    Route::middleware(['auth:sanctum', 'active.user'])->prefix('seller')->group(function () {
        Route::get('/dashboard', [SellerProductController::class, 'dashboard']);
        Route::get('/products', [SellerProductController::class, 'index']);
        Route::post('/products', [SellerProductController::class, 'store'])
            ->middleware('throttle:transactional');
        Route::put('/products/{id}', [SellerProductController::class, 'update'])
            ->middleware('throttle:transactional');
        Route::post('/products/{id}', [SellerProductController::class, 'update'])
            ->middleware('throttle:transactional');
        Route::patch('/products/{id}/status', [SellerProductController::class, 'updateStatus']);
    });

    // 6. Cart, Checkout, QR Payment & Order Cancellation Routes (P6-05)
    Route::middleware(['auth:sanctum', 'active.user'])->group(function () {
        // Shopping Cart
        Route::get('/cart', [CartController::class, 'index']);
        Route::post('/cart/items', [CartController::class, 'storeItem']);
        Route::put('/cart/items/{id}', [CartController::class, 'updateItem']);
        Route::delete('/cart/items/{id}', [CartController::class, 'destroyItem']);

        // Checkout Preview & Order Placement
        Route::post('/checkout/preview', [CheckoutController::class, 'preview']);
        Route::post('/orders', [CheckoutController::class, 'placeOrder'])
            ->middleware('throttle:transactional');

        // Mock QR Payment
        Route::get('/payments/{id}', [PaymentController::class, 'show']);
        Route::post('/payments/{id}/simulate-success', [PaymentController::class, 'simulateSuccess'])
            ->middleware('throttle:transactional');
        Route::post('/payments/{id}/simulate-failure', [PaymentController::class, 'simulateFailure'])
            ->middleware('throttle:transactional');

        // Buyer Purchases & Order Lifecycle
        Route::get('/orders/purchases', [BuyerOrderController::class, 'index']);
        Route::get('/orders/{id}', [BuyerOrderController::class, 'show']);
        Route::post('/orders/{id}/cancel', [BuyerOrderController::class, 'cancel'])
            ->middleware('throttle:transactional');
        Route::post('/orders/{id}/withdraw-cancel-request', [BuyerOrderController::class, 'withdrawCancelRequest']);

        // Seller Cancellation Response
        Route::post('/seller/orders/{id}/respond-cancel', [BuyerOrderController::class, 'sellerRespondCancel'])
            ->middleware('throttle:transactional');
    });

    // 7. Order Fulfillment, Escrow Release, Seller Wallet & Dispute Resolution (P6-06)
    Route::middleware(['auth:sanctum', 'active.user'])->group(function () {
        // Seller Orders Fulfillment
        Route::get('/seller/orders', [SellerOrderController::class, 'index']);
        Route::post('/seller/orders/{id}/prepare', [SellerOrderController::class, 'prepare'])
            ->middleware('throttle:transactional');
        Route::post('/seller/orders/{id}/cancel', [SellerOrderController::class, 'cancel'])
            ->middleware('throttle:transactional');
        Route::post('/seller/orders/{id}/ship', [SellerOrderController::class, 'ship'])
            ->middleware('throttle:transactional');
        Route::post('/seller/orders/{id}/deliver', [SellerOrderController::class, 'deliver'])
            ->middleware('throttle:transactional');

        // Buyer Delivery Confirmation & Escrow Release
        Route::post('/orders/{id}/confirm-delivery', [BuyerOrderController::class, 'confirmDelivery'])
            ->middleware('throttle:transactional');

        // Seller Wallet Ledger
        Route::get('/seller/wallet', [SellerWalletController::class, 'index']);

        // Dispute Resolution System
        Route::post('/orders/{id}/disputes', [DisputeController::class, 'store'])
            ->middleware('throttle:transactional');
        Route::get('/disputes', [DisputeController::class, 'index']);
        Route::get('/disputes/{id}', [DisputeController::class, 'show']);
        Route::post('/disputes/{id}/evidences', [DisputeController::class, 'storeEvidence'])
            ->middleware('throttle:transactional');
        Route::post('/admin/disputes/{id}/resolve', [DisputeController::class, 'resolve'])
            ->middleware('throttle:transactional');
    });

    // 8. Auction Engine Routes (P6-07)
    // Authenticated Auction Routes
    Route::middleware(['auth:sanctum', 'active.user'])->group(function () {
        Route::get('/auctions/mine', [AuctionController::class, 'mine']);
        Route::post('/auctions/{id}/bids', [AuctionController::class, 'placeBid'])
            ->middleware('throttle:transactional');
        Route::post('/auctions/{id}/watch', [AuctionController::class, 'toggleWatch']);
        Route::post('/auctions/{id}/close-early', [AuctionController::class, 'closeEarly'])
            ->middleware('throttle:transactional');
        Route::post('/seller/products/{id}/relist', [AuctionController::class, 'relistProduct'])
            ->middleware('throttle:transactional');
    });

    // Public / Optional-Auth Auction Exploration Routes (placed after /auctions/mine)
    Route::middleware(['optional.sanctum', 'active.user'])->group(function () {
        Route::get('/auctions', [AuctionController::class, 'index']);
        Route::get('/auctions/{id}', [AuctionController::class, 'show']);
        Route::get('/auctions/{id}/bids', [AuctionController::class, 'bids']);
    });

    // 9. Chat, Notification, Review & Engagement Routes (P6-08)
    Route::middleware(['auth:sanctum', 'active.user'])->group(function () {
        // Engagement: Favorites & Seller Follow
        Route::post('/products/{id}/favorite', [EngagementController::class, 'toggleFavorite']);
        Route::get('/profile/favorites', [EngagementController::class, 'favorites']);
        Route::post('/sellers/{id}/follow', [EngagementController::class, 'toggleFollow']);

        // Verified Order Reviews (BR-RV-01)
        Route::post('/orders/{id}/reviews', [ReviewController::class, 'store'])
            ->middleware('throttle:transactional');

        // 1-on-1 Chat with Incremental Polling (ADR-08)
        Route::get('/conversations', [ConversationController::class, 'index']);
        Route::post('/conversations', [ConversationController::class, 'store']);
        Route::get('/conversations/{id}/messages', [ConversationController::class, 'messages'])
            ->middleware('throttle:polling');
        Route::post('/conversations/{id}/messages', [ConversationController::class, 'sendMessage'])
            ->middleware('throttle:transactional');

        // In-App Notifications
        Route::get('/notifications', [NotificationController::class, 'index']);
        Route::post('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);
        Route::post('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);

        // Violation Reporting
        Route::post('/reports', [ReportController::class, 'store'])
            ->middleware('throttle:transactional');
    });

    // 10. System DevTools (Demo Mode ADR-05 / P6-09)
    Route::middleware(['auth:sanctum', 'active.user', 'role:admin', 'demo.only'])->group(function () {
        Route::post('/system/dev-tools/trigger-jobs', [SystemDevToolsController::class, 'triggerJobs']);
    });
});
