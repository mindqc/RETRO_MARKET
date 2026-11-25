<?php

namespace App\Http\Controllers\Admin;

use App\Enums\OrderStatus;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Dispute;
use App\Models\Order;
use App\Models\Product;
use App\Models\SellerProfile;
use App\Models\User;
use App\Services\Governance\UserGovernanceService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class UserManagementController extends Controller
{
    public function __construct(
        protected UserGovernanceService $userGovernanceService
    ) {}

    /**
     * Display User Management List (Screen A-US-01).
     */
    public function index(Request $request): View
    {
        $query = User::query()->with(['sellerProfile']);

        // Search: display_name, email, phone
        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('display_name', 'ilike', "%{$search}%")
                    ->orWhere('email', 'ilike', "%{$search}%")
                    ->orWhere('phone', 'ilike', "%{$search}%");
            });
        }

        // Role filter
        if ($role = $request->input('role')) {
            $query->where('role', $role);
        }

        // Status filter
        if ($status = $request->input('status')) {
            $query->where('status', $status);
        }

        // Summary Stats
        $stats = [
            'total' => User::count(),
            'active' => User::where('status', UserStatus::ACTIVE)->count(),
            'suspended' => User::where('status', UserStatus::SUSPENDED)->count(),
            'sellers' => SellerProfile::count(),
            'staff' => User::whereIn('role', [UserRole::ADMIN, UserRole::MODERATOR, UserRole::SUPPORT])->count(),
        ];

        $users = $query->orderByDesc('id')->paginate(15)->withQueryString();

        return view('admin.users.index', compact('users', 'stats'));
    }

    /**
     * Display User Detail, Role & Fraud Inspector (Screen A-US-02).
     */
    public function show(int $id): View
    {
        $targetUser = User::with(['sellerProfile', 'profile'])->findOrFail($id);

        // Buyer metrics
        $buyerStats = [
            'orders_count' => Order::where('buyer_id', $id)->count(),
            'completed_orders_count' => Order::where('buyer_id', $id)->where('order_status', OrderStatus::COMPLETED)->count(),
            'total_spent' => (float) Order::where('buyer_id', $id)->where('order_status', OrderStatus::COMPLETED)->sum('total_amount'),
            'disputes_opened' => Dispute::where('buyer_id', $id)->count(),
        ];

        // Seller metrics (if seller profile exists)
        $sellerStats = null;
        if ($targetUser->sellerProfile) {
            $sp = $targetUser->sellerProfile;
            $sellerStats = [
                'shop_slug' => $sp->shop_slug,
                'trust_score' => (float) $sp->trust_score,
                'wallet_balance' => (float) $sp->wallet_balance,
                'escrow_held_balance' => (float) $sp->escrow_held_balance,
                'completed_orders_count' => (int) $sp->completed_orders_count,
                'dispute_lost_count' => (int) $sp->dispute_lost_count,
                'auction_default_count' => (int) $sp->auction_default_count,
                'total_products' => Product::where('seller_id', $id)->count(),
                'active_products' => Product::where('seller_id', $id)->where('status', 'APPROVED')->count(),
            ];
        }

        // Recent Orders
        $recentOrders = Order::where(function ($q) use ($id) {
            $q->where('buyer_id', $id)->orWhere('seller_id', $id);
        })->with(['buyer', 'seller'])->orderByDesc('id')->limit(5)->get();

        // Recent Audit Logs targeting this user
        $auditLogs = AuditLog::where('target_type', 'users')
            ->where('target_id', $id)
            ->with(['actor'])
            ->orderByDesc('id')
            ->limit(10)
            ->get();

        return view('admin.users.show', compact('targetUser', 'buyerStats', 'sellerStats', 'recentOrders', 'auditLogs'));
    }

    /**
     * Suspend or unsuspend account (Admin only, DEC-08-02).
     */
    public function updateStatus(Request $request, int $id): RedirectResponse
    {
        if (!$request->user()?->isAdmin()) {
            abort(403, 'Chỉ Quản trị viên (Admin) mới có quyền khóa/mở khóa tài khoản.');
        }

        $validated = $request->validate([
            'status' => 'required|string|in:ACTIVE,SUSPENDED',
            'reason' => 'required|string|min:5|max:1000',
        ], [
            'status.required' => 'Vui lòng chọn trạng thái tài khoản.',
            'status.in' => 'Trạng thái tài khoản không hợp lệ.',
            'reason.required' => 'Vui lòng nhập lý do (bắt buộc).',
            'reason.min' => 'Lý do phải có ít nhất 5 ký tự.',
        ]);

        $targetUser = User::findOrFail($id);

        try {
            $this->userGovernanceService->updateAccountStatus(
                $request->user(),
                $targetUser,
                $validated['status'],
                $validated['reason']
            );

            $actionText = ($validated['status'] === 'ACTIVE') ? 'kích hoạt lại' : 'khóa (tạm dừng)';

            return redirect()->route('admin.users.show', $id)
                ->with('success', "Tài khoản của {$targetUser->display_name} đã được {$actionText} thành công.");
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', $e->getMessage())
                ->withInput();
        }
    }

    /**
     * Update user role (Admin only, DEC-08-02).
     */
    public function updateRole(Request $request, int $id): RedirectResponse
    {
        if (!$request->user()?->isAdmin()) {
            abort(403, 'Chỉ Quản trị viên (Admin) mới có quyền thay đổi vai trò tài khoản.');
        }

        $validated = $request->validate([
            'role' => 'required|string|in:registered_user,moderator,support,admin',
            'reason' => 'required|string|min:5|max:1000',
        ], [
            'role.required' => 'Vui lòng chọn vai trò mới.',
            'role.in' => 'Vai trò không hợp lệ.',
            'reason.required' => 'Vui lòng nhập lý do thay đổi vai trò (bắt buộc).',
            'reason.min' => 'Lý do phải có ít nhất 5 ký tự.',
        ]);

        $targetUser = User::findOrFail($id);

        try {
            $this->userGovernanceService->updateUserRole(
                $request->user(),
                $targetUser,
                $validated['role'],
                $validated['reason']
            );

            return redirect()->route('admin.users.show', $id)
                ->with('success', "Vai trò của {$targetUser->display_name} đã được cập nhật thành {$validated['role']}.");
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', $e->getMessage())
                ->withInput();
        }
    }
}
