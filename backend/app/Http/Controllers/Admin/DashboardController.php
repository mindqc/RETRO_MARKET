<?php

namespace App\Http\Controllers\Admin;

use App\Enums\AuctionStatus;
use App\Enums\DisputeStatus;
use App\Enums\EscrowStatus;
use App\Enums\OrderStatus;
use App\Enums\ProductStatus;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Http\Controllers\Controller;
use App\Models\Auction;
use App\Models\AuditLog;
use App\Models\Dispute;
use App\Models\EscrowTransaction;
use App\Models\Order;
use App\Models\Product;
use App\Models\Report;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

class DashboardController extends Controller
{
    /**
     * Display the Admin Dashboard (Screen A-DB-01).
     */
    public function index(Request $request): View
    {
        /** @var User $user */
        $user = Auth::guard('web')->user();

        $metrics = [];
        $recentActivities = collect();

        if ($user->role === UserRole::ADMIN) {
            $metrics = [
                'total_gmv' => (float) Order::where('order_status', OrderStatus::COMPLETED)->sum('total_amount'),
                'active_escrow_amount' => (float) Order::where('escrow_status', EscrowStatus::HELD)->sum('total_amount'),
                'total_users' => User::count(),
                'active_users' => User::where('status', UserStatus::ACTIVE)->count(),
                'pending_moderation_count' => Product::where('status', ProductStatus::PENDING_REVIEW)->count(),
                'pending_disputes_count' => Dispute::where('status', DisputeStatus::OPEN)->count(),
                'open_reports_count' => Report::where('status', 'PENDING')->count(),
                'active_auctions_count' => Auction::where('status', AuctionStatus::LIVE)->count(),
            ];
            $recentActivities = AuditLog::with('actor')->latest('id')->limit(8)->get();
        } elseif ($user->role === UserRole::MODERATOR) {
            $metrics = [
                'pending_moderation_count' => Product::where('status', ProductStatus::PENDING_REVIEW)->count(),
                'open_reports_count' => Report::where('status', 'PENDING')->count(),
                'active_auctions_count' => Auction::where('status', AuctionStatus::LIVE)->count(),
                'total_products' => Product::count(),
            ];
            $recentActivities = AuditLog::with('actor')
                ->whereIn('action', [
                    'PRODUCT_APPROVED',
                    'PRODUCT_REJECTED',
                    'PRODUCT_HIDDEN',
                    'AUCTION_CANCELLED',
                    'REPORT_RESOLVED',
                    'ADMIN_LOGIN',
                    'ADMIN_LOGOUT',
                ])
                ->latest('id')
                ->limit(8)
                ->get();
        } elseif ($user->role === UserRole::SUPPORT) {
            $metrics = [
                'pending_disputes_count' => Dispute::where('status', DisputeStatus::OPEN)->count(),
                'open_reports_count' => Report::where('status', 'PENDING')->count(),
                'processing_orders_count' => Order::whereIn('order_status', [
                    OrderStatus::PAID,
                    OrderStatus::PREPARING,
                    OrderStatus::SHIPPED,
                ])->count(),
            ];
            $recentActivities = AuditLog::with('actor')
                ->whereIn('action', [
                    'DISPUTE_RESOLVED',
                    'ORDER_STATUS_UPDATED',
                    'REPORT_RESOLVED',
                    'ADMIN_LOGIN',
                    'ADMIN_LOGOUT',
                ])
                ->latest('id')
                ->limit(8)
                ->get();
        }

        return view('admin.dashboard', [
            'user' => $user,
            'metrics' => $metrics,
            'recentActivities' => $recentActivities,
            'serverTime' => now()->timezone('Asia/Ho_Chi_Minh')->format('d/m/Y H:i:s T'),
        ]);
    }
}
