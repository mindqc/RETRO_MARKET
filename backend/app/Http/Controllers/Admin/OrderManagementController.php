<?php

namespace App\Http\Controllers\Admin;

use App\Enums\DisputeStatus;
use App\Enums\EscrowStatus;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Http\Controllers\Controller;
use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\View\View;

class OrderManagementController extends Controller
{
    /**
     * Display list of orders with 4 independent state machines (Screen A-OR-01).
     */
    public function index(Request $request): View
    {
        $query = Order::query()
            ->with(['buyer', 'seller', 'items', 'payments', 'shipment']);

        // Search: order_code, buyer name/email, seller name/email
        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('order_code', 'ilike', "%{$search}%")
                    ->orWhereHas('buyer', fn ($bq) => $bq->where('display_name', 'ilike', "%{$search}%")->orWhere('email', 'ilike', "%{$search}%"))
                    ->orWhereHas('seller', fn ($sq) => $sq->where('display_name', 'ilike', "%{$search}%")->orWhere('email', 'ilike', "%{$search}%"));
            });
        }

        // 4 Independent State Machine Filters
        if ($orderStatus = $request->input('order_status')) {
            $query->where('order_status', $orderStatus);
        }

        if ($paymentStatus = $request->input('payment_status')) {
            $query->where('payment_status', $paymentStatus);
        }

        if ($escrowStatus = $request->input('escrow_status')) {
            $query->where('escrow_status', $escrowStatus);
        }

        if ($disputeStatus = $request->input('dispute_status')) {
            $query->where('dispute_status', $disputeStatus);
        }

        // Order Source Filter
        if ($orderSource = $request->input('order_source')) {
            $query->where('order_source', $orderSource);
        }

        // Summary Statistics
        $stats = [
            'total' => Order::count(),
            'escrow_held' => Order::where('escrow_status', EscrowStatus::HELD)->count(),
            'dispute_open' => Order::where('dispute_status', DisputeStatus::OPEN)->count(),
            'completed' => Order::where('order_status', OrderStatus::COMPLETED)->count(),
            'gross_volume' => Order::whereIn('order_status', [
                OrderStatus::PAID,
                OrderStatus::PREPARING,
                OrderStatus::SHIPPED,
                OrderStatus::DELIVERED,
                OrderStatus::COMPLETED,
            ])->sum('total_amount'),
        ];

        $orders = $query->orderByDesc('id')->paginate(15)->withQueryString();

        return view('admin.orders.index', compact('orders', 'stats'));
    }

    /**
     * Display 360° Order Inspector with DEC-04 financial breakdown (Screen A-OR-02).
     */
    public function show(int $id): View
    {
        $order = Order::with([
            'buyer.profile',
            'seller.sellerProfile',
            'items.product.primaryImage',
            'payments',
            'shipment.updater',
            'escrowTransactions',
            'walletTransaction',
            'dispute',
            'review',
            'auction',
        ])->findOrFail($id);

        return view('admin.orders.show', compact('order'));
    }
}
