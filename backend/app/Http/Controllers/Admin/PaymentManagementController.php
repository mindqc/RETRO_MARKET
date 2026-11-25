<?php

namespace App\Http\Controllers\Admin;

use App\Enums\PaymentStatus;
use App\Http\Controllers\Controller;
use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\View\View;

class PaymentManagementController extends Controller
{
    /**
     * Display list of QR payment sessions and transactions (Screen A-PM-01).
     */
    public function index(Request $request): View
    {
        $query = Payment::query()
            ->with(['order', 'payer']);

        // Search: payment_reference, order_code, or payer details
        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('payment_reference', 'ilike', "%{$search}%")
                    ->orWhereHas('order', fn ($oq) => $oq->where('order_code', 'ilike', "%{$search}%"))
                    ->orWhereHas('payer', fn ($pq) => $pq->where('display_name', 'ilike', "%{$search}%")->orWhere('email', 'ilike', "%{$search}%"));
            });
        }

        // Status filter
        if ($status = $request->input('status')) {
            $query->where('status', $status);
        }

        // Summary Statistics
        $stats = [
            'total' => Payment::count(),
            'paid_amount' => Payment::where('status', PaymentStatus::PAID)->sum('amount'),
            'paid_count' => Payment::where('status', PaymentStatus::PAID)->count(),
            'pending_count' => Payment::where('status', PaymentStatus::PENDING)->count(),
            'expired_count' => Payment::where('status', PaymentStatus::EXPIRED)->count(),
        ];

        $payments = $query->orderByDesc('id')->paginate(15)->withQueryString();

        return view('admin.payments.index', compact('payments', 'stats'));
    }
}
