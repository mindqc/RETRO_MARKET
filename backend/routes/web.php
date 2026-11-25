<?php

use App\Http\Controllers\Admin\AuctionManagementController;
use App\Http\Controllers\Admin\AuditLogController;
use App\Http\Controllers\Admin\Auth\AdminAuthController;
use App\Http\Controllers\Admin\CatalogController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\DeveloperToolsController;
use App\Http\Controllers\Admin\DisputeManagementController;
use App\Http\Controllers\Admin\EscrowLedgerController;
use App\Http\Controllers\Admin\ModerationController;
use App\Http\Controllers\Admin\OrderManagementController;
use App\Http\Controllers\Admin\PaymentManagementController;
use App\Http\Controllers\Admin\PlatformSettingsController;
use App\Http\Controllers\Admin\ProductManagementController;
use App\Http\Controllers\Admin\ReportManagementController;
use App\Http\Controllers\Admin\UserManagementController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::prefix('admin')->name('admin.')->group(function () {
    // Guest Admin Auth Routes
    Route::get('/', function () {
        return redirect()->route('admin.dashboard');
    });

    Route::get('/login', [AdminAuthController::class, 'showLoginForm'])->name('login');
    Route::post('/login', [AdminAuthController::class, 'login'])->name('login.submit');

    // Authenticated Admin Routes (Session Auth + Status Gate + Default Deny)
    Route::middleware(['admin.auth'])->group(function () {
        Route::post('/logout', [AdminAuthController::class, 'logout'])->name('logout');

        // P8-01 Core Dashboard (A-DB-01)
        Route::get('/dashboard', [DashboardController::class, 'index'])
            ->middleware('admin.can:dashboard.view')
            ->name('dashboard');

        // P8-02: Product Moderation Queue (A-MD-01) & Detail Split-Pane (A-MD-02)
        Route::prefix('moderation')->name('moderation.')->group(function () {
            Route::get('/products', [ModerationController::class, 'productQueue'])
                ->middleware('admin.can:products.view')
                ->name('products.index');

            Route::get('/products/{id}', [ModerationController::class, 'productDetail'])
                ->middleware('admin.can:products.view')
                ->name('products.show');

            Route::post('/products/{id}/approve', [ModerationController::class, 'approve'])
                ->middleware('admin.can:products.approve')
                ->name('products.approve');

            Route::post('/products/{id}/reject', [ModerationController::class, 'reject'])
                ->middleware('admin.can:products.reject')
                ->name('products.reject');
        });

        // P8-02: Product Management – Master Inventory (A-PR-01)
        Route::get('/products', [ProductManagementController::class, 'index'])
            ->middleware('admin.can:products.view')
            ->name('products.index');

        Route::get('/products/{id}', [ProductManagementController::class, 'show'])
            ->middleware('admin.can:products.view')
            ->name('products.show');

        Route::post('/products/{id}/hide', [ProductManagementController::class, 'hide'])
            ->middleware('admin.can:products.hide')
            ->name('products.hide');

        Route::post('/products/{id}/unhide', [ProductManagementController::class, 'unhide'])
            ->middleware('admin.can:products.approve')
            ->name('products.unhide');

        // P8-02: Catalog & Taxonomy Management (A-CT-01)
        Route::get('/catalog', [CatalogController::class, 'index'])
            ->middleware('admin.can:categories.view')
            ->name('catalog.index');

        Route::prefix('catalog')->name('catalog.')->group(function () {
            // Category Mutations
            Route::post('/categories', [CatalogController::class, 'storeCategory'])
                ->middleware('admin.can:categories.manage')
                ->name('categories.store');

            Route::put('/categories/{id}', [CatalogController::class, 'updateCategory'])
                ->middleware('admin.can:categories.manage')
                ->name('categories.update');

            Route::post('/categories/{id}/toggle', [CatalogController::class, 'toggleCategory'])
                ->middleware('admin.can:categories.manage')
                ->name('categories.toggle');

            Route::delete('/categories/{id}', [CatalogController::class, 'destroyCategory'])
                ->middleware('admin.can:categories.manage')
                ->name('categories.destroy');

            // Brand Mutations
            Route::post('/brands', [CatalogController::class, 'storeBrand'])
                ->middleware('admin.can:categories.manage')
                ->name('brands.store');

            Route::put('/brands/{id}', [CatalogController::class, 'updateBrand'])
                ->middleware('admin.can:categories.manage')
                ->name('brands.update');

            Route::post('/brands/{id}/toggle', [CatalogController::class, 'toggleBrand'])
                ->middleware('admin.can:categories.manage')
                ->name('brands.toggle');

            Route::delete('/brands/{id}', [CatalogController::class, 'destroyBrand'])
                ->middleware('admin.can:categories.manage')
                ->name('brands.destroy');
        });

        // P8-03: Auction Management (A-AC-01, A-AC-02, A-AC-03)
        Route::prefix('auctions')->name('auctions.')->group(function () {
            Route::get('/', [AuctionManagementController::class, 'index'])
                ->middleware('admin.can:auctions.view')
                ->name('index');

            Route::get('/{id}', [AuctionManagementController::class, 'show'])
                ->middleware('admin.can:auctions.view')
                ->name('show');

            Route::post('/{id}/cancel', [AuctionManagementController::class, 'cancel'])
                ->middleware('admin.can:auctions.cancel')
                ->name('cancel');
        });

        // P8-03: Order Management & 360° Inspector (A-OR-01, A-OR-02)
        Route::prefix('orders')->name('orders.')->group(function () {
            Route::get('/', [OrderManagementController::class, 'index'])
                ->middleware('admin.can:orders.view')
                ->name('index');

            Route::get('/{id}', [OrderManagementController::class, 'show'])
                ->middleware('admin.can:orders.view')
                ->name('show');
        });

        // P8-03: Payment Transactions Management (A-PM-01)
        Route::get('/payments', [PaymentManagementController::class, 'index'])
            ->middleware('admin.can:payments.view')
            ->name('payments.index');

        // P8-04: Immutable Escrow & Wallet Ledger Explorer (A-ES-01) - Strictly Read-Only
        Route::get('/escrow', [EscrowLedgerController::class, 'index'])
            ->middleware('admin.can:escrow.view')
            ->name('escrow.index');

        // P8-04: Dispute Management Queue & 2-Way Evidence Case Room (A-DP-01, A-DP-02)
        Route::prefix('disputes')->name('disputes.')->group(function () {
            Route::get('/', [DisputeManagementController::class, 'index'])
                ->middleware('admin.can:disputes.view')
                ->name('index');

            Route::get('/{id}', [DisputeManagementController::class, 'show'])
                ->middleware('admin.can:disputes.view')
                ->name('show');

            Route::post('/{id}/request-info', [DisputeManagementController::class, 'requestInfo'])
                ->middleware('admin.can:disputes.view')
                ->name('request_info');

            Route::post('/{id}/verdict', [DisputeManagementController::class, 'verdict'])
                ->middleware('admin.can:disputes.verdict')
                ->name('verdict');
        });

        // P8-04: Violation / Moderation Reports Management (A-CM-01)
        Route::prefix('moderation/reports')->name('moderation.reports.')->group(function () {
            Route::get('/', [ReportManagementController::class, 'index'])
                ->middleware('admin.can:reports.view')
                ->name('index');

            Route::post('/{id}/resolve', [ReportManagementController::class, 'resolve'])
                ->middleware('admin.can:reports.resolve')
                ->name('resolve');
        });

        Route::get('/reports', fn () => redirect()->route('admin.moderation.reports.index'))->name('reports.index');

        // P8-05: User Management List & 360° Role/Fraud Inspector (A-US-01, A-US-02)
        Route::prefix('users')->name('users.')->group(function () {
            Route::get('/', [UserManagementController::class, 'index'])
                ->middleware('admin.can:users.view')
                ->name('index');

            Route::get('/{id}', [UserManagementController::class, 'show'])
                ->middleware('admin.can:users.view')
                ->name('show');

            Route::post('/{id}/status', [UserManagementController::class, 'updateStatus'])
                ->middleware('admin.can:users.ban')
                ->name('update_status');

            Route::post('/{id}/role', [UserManagementController::class, 'updateRole'])
                ->name('update_role');
        });

        // P8-05: Platform Settings (Buyer Protection Fee & Timers) (A-ST-01)
        Route::prefix('settings')->name('settings.')->group(function () {
            Route::get('/', [PlatformSettingsController::class, 'index'])
                ->middleware('admin.can:settings.manage')
                ->name('index');

            Route::post('/', [PlatformSettingsController::class, 'update'])
                ->middleware('admin.can:settings.manage')
                ->name('update');
        });

        // P8-05: Admin Activity Audit Logs (A-AD-01) - Strictly Read-Only
        Route::prefix('audit-logs')->name('audit_logs.')->group(function () {
            Route::get('/', [AuditLogController::class, 'index'])
                ->middleware('admin.can:audit_logs.view')
                ->name('index');
        });

        // P8-05: Developer Tools & Manual Job Triggers (A-DT-01) - Dual-Gate Security (Admin + DEMO_MODE=true)
        Route::prefix('dev-tools')->name('dev_tools.')->group(function () {
            Route::get('/', [DeveloperToolsController::class, 'index'])
                ->name('index');

            Route::post('/trigger', [DeveloperToolsController::class, 'trigger'])
                ->name('trigger');
        });

        Route::get('/devtools', fn () => redirect()->route('admin.dev_tools.index'))->name('devtools.redirect');
    });
});
