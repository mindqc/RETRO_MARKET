@extends('layouts.admin')

@section('title', 'Bảng điều khiển Vận hành')
@section('header_title', 'Bảng điều khiển Vận hành (Executive Dashboard)')

@section('content')
<div class="space-y-8">
    <!-- Welcome Banner -->
    <div class="bg-white rounded-xl p-6 border border-[#E8E2D9] shadow-xs flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
            <div class="flex items-center space-x-3">
                <h3 class="font-serif text-2xl font-bold text-[#1F2937]">
                    Xin chào, {{ $user->display_name }}!
                </h3>
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-[#F4EBDD] text-[#84664C]">
                    {{ $user->role->label() }}
                </span>
            </div>
            <p class="text-sm text-gray-500 mt-1">
                Chào mừng bạn đến với trung tâm điều hành sàn Retro Market (izithrift). Trạng thái phiên làm việc bảo mật cao (Active).
            </p>
        </div>
        <div class="text-right">
            <span class="inline-flex items-center px-3 py-1 rounded-md text-xs font-mono font-medium bg-emerald-50 text-emerald-700 border border-emerald-200">
                <span class="w-2 h-2 rounded-full bg-emerald-500 mr-2 animate-pulse"></span>
                Hệ thống thời gian thực: Hoạt động bình thường
            </span>
        </div>
    </div>

    <!-- Role-Scoped Operational Metrics Grid -->
    <div>
        <h4 class="font-serif text-lg font-bold text-[#1F2937] mb-4">Chỉ số vận hành trọng yếu</h4>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
            @if ($user->role->value === 'admin')
                <!-- GMV Card -->
                <div class="bg-white rounded-xl p-5 border border-[#E8E2D9] shadow-xs">
                    <div class="flex items-center justify-between">
                        <span class="text-xs font-semibold uppercase tracking-wider text-gray-500">Tổng GMV hoàn tất</span>
                        <span class="p-2 bg-emerald-50 text-emerald-600 rounded-lg">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                            </svg>
                        </span>
                    </div>
                    <div class="mt-3">
                        <span class="text-2xl font-bold font-sans tabular-nums text-[#1F2937]">
                            {{ number_format($metrics['total_gmv'] ?? 0, 0, ',', '.') }}
                        </span>
                        <span class="text-xs text-gray-500 ml-1">VNĐ</span>
                    </div>
                    <p class="text-[11px] text-gray-400 mt-2">Tổng giá trị giao dịch các đơn hàng COMPLETED</p>
                </div>

                <!-- Escrow Held Card -->
                <div class="bg-white rounded-xl p-5 border border-[#E8E2D9] shadow-xs">
                    <div class="flex items-center justify-between">
                        <span class="text-xs font-semibold uppercase tracking-wider text-gray-500">Escrow Đang giữ bảo vệ</span>
                        <span class="p-2 bg-amber-50 text-amber-600 rounded-lg">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/>
                            </svg>
                        </span>
                    </div>
                    <div class="mt-3">
                        <span class="text-2xl font-bold font-sans tabular-nums text-[#C85A32]">
                            {{ number_format($metrics['active_escrow_amount'] ?? 0, 0, ',', '.') }}
                        </span>
                        <span class="text-xs text-gray-500 ml-1">VNĐ</span>
                    </div>
                    <p class="text-[11px] text-gray-400 mt-2">Tiền người mua ký quỹ chờ giao hàng</p>
                </div>

                <!-- Active Users Card -->
                <div class="bg-white rounded-xl p-5 border border-[#E8E2D9] shadow-xs">
                    <div class="flex items-center justify-between">
                        <span class="text-xs font-semibold uppercase tracking-wider text-gray-500">Tài khoản hoạt động</span>
                        <span class="p-2 bg-blue-50 text-blue-600 rounded-lg">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/>
                            </svg>
                        </span>
                    </div>
                    <div class="mt-3">
                        <span class="text-2xl font-bold font-sans tabular-nums text-[#1F2937]">
                            {{ number_format($metrics['active_users'] ?? 0, 0, ',', '.') }}
                        </span>
                        <span class="text-xs text-gray-500 ml-1">/ {{ number_format($metrics['total_users'] ?? 0, 0, ',', '.') }} tổng</span>
                    </div>
                    <p class="text-[11px] text-gray-400 mt-2">Thành viên có trạng thái ACTIVE</p>
                </div>

                <!-- Pending Moderation Card -->
                <div class="bg-white rounded-xl p-5 border border-[#E8E2D9] shadow-xs">
                    <div class="flex items-center justify-between">
                        <span class="text-xs font-semibold uppercase tracking-wider text-gray-500">Sản phẩm chờ duyệt</span>
                        <span class="p-2 bg-rose-50 text-rose-600 rounded-lg">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
                            </svg>
                        </span>
                    </div>
                    <div class="mt-3">
                        <span class="text-2xl font-bold font-sans tabular-nums text-rose-600">
                            {{ number_format($metrics['pending_moderation_count'] ?? 0, 0, ',', '.') }}
                        </span>
                    </div>
                    <p class="text-[11px] text-gray-400 mt-2">Tin đăng vintage cần kiểm duyệt</p>
                </div>
            @elseif ($user->role->value === 'moderator')
                <!-- Moderator View -->
                <div class="bg-white rounded-xl p-5 border border-[#E8E2D9] shadow-xs">
                    <div class="flex items-center justify-between">
                        <span class="text-xs font-semibold uppercase tracking-wider text-gray-500">Sản phẩm chờ duyệt</span>
                        <span class="p-2 bg-rose-50 text-rose-600 rounded-lg">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
                            </svg>
                        </span>
                    </div>
                    <div class="mt-3">
                        <span class="text-2xl font-bold font-sans tabular-nums text-rose-600">
                            {{ number_format($metrics['pending_moderation_count'] ?? 0, 0, ',', '.') }}
                        </span>
                    </div>
                    <p class="text-[11px] text-gray-400 mt-2">Hàng đợi kiểm duyệt ưu tiên PENDING_REVIEW</p>
                </div>

                <div class="bg-white rounded-xl p-5 border border-[#E8E2D9] shadow-xs">
                    <div class="flex items-center justify-between">
                        <span class="text-xs font-semibold uppercase tracking-wider text-gray-500">Báo cáo vi phạm mở</span>
                        <span class="p-2 bg-amber-50 text-amber-600 rounded-lg">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
                            </svg>
                        </span>
                    </div>
                    <div class="mt-3">
                        <span class="text-2xl font-bold font-sans tabular-nums text-amber-600">
                            {{ number_format($metrics['open_reports_count'] ?? 0, 0, ',', '.') }}
                        </span>
                    </div>
                    <p class="text-[11px] text-gray-400 mt-2">Khiếu nại sản phẩm/người dùng từ cộng đồng</p>
                </div>

                <div class="bg-white rounded-xl p-5 border border-[#E8E2D9] shadow-xs">
                    <div class="flex items-center justify-between">
                        <span class="text-xs font-semibold uppercase tracking-wider text-gray-500">Đấu giá đang diễn ra</span>
                        <span class="p-2 bg-blue-50 text-blue-600 rounded-lg">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"/>
                            </svg>
                        </span>
                    </div>
                    <div class="mt-3">
                        <span class="text-2xl font-bold font-sans tabular-nums text-blue-600">
                            {{ number_format($metrics['active_auctions_count'] ?? 0, 0, ',', '.') }}
                        </span>
                    </div>
                    <p class="text-[11px] text-gray-400 mt-2">Phiên đấu giá LIVE cần giám sát</p>
                </div>

                <div class="bg-white rounded-xl p-5 border border-[#E8E2D9] shadow-xs">
                    <div class="flex items-center justify-between">
                        <span class="text-xs font-semibold uppercase tracking-wider text-gray-500">Tổng sản phẩm sàn</span>
                        <span class="p-2 bg-gray-50 text-gray-600 rounded-lg">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/>
                            </svg>
                        </span>
                    </div>
                    <div class="mt-3">
                        <span class="text-2xl font-bold font-sans tabular-nums text-gray-800">
                            {{ number_format($metrics['total_products'] ?? 0, 0, ',', '.') }}
                        </span>
                    </div>
                    <p class="text-[11px] text-gray-400 mt-2">Tổng danh mục catalog sản phẩm</p>
                </div>
            @elseif ($user->role->value === 'support')
                <!-- Support Staff View -->
                <div class="bg-white rounded-xl p-5 border border-[#E8E2D9] shadow-xs">
                    <div class="flex items-center justify-between">
                        <span class="text-xs font-semibold uppercase tracking-wider text-gray-500">Khiếu nại mở cần xử lý</span>
                        <span class="p-2 bg-rose-50 text-rose-600 rounded-lg">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 6l3 1m0 0l-3 9a5.002 5.002 0 006.001 0M6 7l3 9M6 7l6-2m6 2l3-1m-3 1l-3 9a5.002 5.002 0 006.001 0M18 7l3 9m-3-9l-6-2m0-2v2m0 16V5m0 16H9m3 0h3"/>
                            </svg>
                        </span>
                    </div>
                    <div class="mt-3">
                        <span class="text-2xl font-bold font-sans tabular-nums text-rose-600">
                            {{ number_format($metrics['pending_disputes_count'] ?? 0, 0, ',', '.') }}
                        </span>
                    </div>
                    <p class="text-[11px] text-gray-400 mt-2">Tranh chấp OPEN đang khóa tiền Escrow</p>
                </div>

                <div class="bg-white rounded-xl p-5 border border-[#E8E2D9] shadow-xs">
                    <div class="flex items-center justify-between">
                        <span class="text-xs font-semibold uppercase tracking-wider text-gray-500">Báo cáo vi phạm mở</span>
                        <span class="p-2 bg-amber-50 text-amber-600 rounded-lg">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
                            </svg>
                        </span>
                    </div>
                    <div class="mt-3">
                        <span class="text-2xl font-bold font-sans tabular-nums text-amber-600">
                            {{ number_format($metrics['open_reports_count'] ?? 0, 0, ',', '.') }}
                        </span>
                    </div>
                    <p class="text-[11px] text-gray-400 mt-2">Yêu cầu hỗ trợ & phản ánh từ người dùng</p>
                </div>

                <div class="bg-white rounded-xl p-5 border border-[#E8E2D9] shadow-xs">
                    <div class="flex items-center justify-between">
                        <span class="text-xs font-semibold uppercase tracking-wider text-gray-500">Đơn hàng đang luân chuyển</span>
                        <span class="p-2 bg-blue-50 text-blue-600 rounded-lg">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"/>
                            </svg>
                        </span>
                    </div>
                    <div class="mt-3">
                        <span class="text-2xl font-bold font-sans tabular-nums text-blue-600">
                            {{ number_format($metrics['processing_orders_count'] ?? 0, 0, ',', '.') }}
                        </span>
                    </div>
                    <p class="text-[11px] text-gray-400 mt-2">Đơn hàng ở trạng thái PAID, PREPARING hoặc SHIPPED</p>
                </div>
            @endif
        </div>
    </div>

    <!-- Immutable Audit Activity Stream -->
    <div class="bg-white rounded-xl border border-[#E8E2D9] shadow-xs overflow-hidden">
        <div class="px-6 py-4 border-b border-[#E8E2D9] flex items-center justify-between">
            <div>
                <h4 class="font-serif text-lg font-bold text-[#1F2937]">Nhật ký vận hành mới nhất</h4>
                <p class="text-xs text-gray-500">Ghi nhận các sự kiện bảo mật và thao tác quản trị trên sổ cái bất biến (Audit Log)</p>
            </div>
            <span class="text-xs font-mono text-[#84664C]">Bất biến (Append-only)</span>
        </div>

        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse text-xs">
                <thead>
                    <tr class="bg-[#FBF8F3] border-b border-[#E8E2D9] text-[#5E5852] uppercase font-semibold">
                        <th class="py-3 px-6">Thời gian (VN)</th>
                        <th class="py-3 px-6">Nhân sự thực hiện</th>
                        <th class="py-3 px-6">Vai trò</th>
                        <th class="py-3 px-6">Hành động</th>
                        <th class="py-3 px-6">Đối tượng</th>
                        <th class="py-3 px-6">IP Ghi nhận</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#E8E2D9]">
                    @forelse ($recentActivities as $log)
                        <tr class="hover:bg-[#FCFAF7] transition-colors">
                            <td class="py-3.5 px-6 font-mono text-gray-500 tabular-nums">
                                {{ $log->created_at?->timezone('Asia/Ho_Chi_Minh')->format('d/m/Y H:i:s') ?? '---' }}
                            </td>
                            <td class="py-3.5 px-6 font-medium text-[#1F2937]">
                                {{ $log->actor?->display_name ?? 'Hệ thống' }}
                            </td>
                            <td class="py-3.5 px-6">
                                <span class="inline-flex items-center px-2 py-0.5 rounded text-[11px] font-semibold bg-gray-100 text-gray-700">
                                    {{ $log->actor_role }}
                                </span>
                            </td>
                            <td class="py-3.5 px-6 font-mono font-medium text-[#C85A32]">
                                {{ $log->action }}
                            </td>
                            <td class="py-3.5 px-6 text-gray-600">
                                {{ $log->target_type }} #{{ $log->target_id }}
                            </td>
                            <td class="py-3.5 px-6 font-mono text-gray-400">
                                {{ $log->ip_address ?? '127.0.0.1' }}
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="py-8 px-6 text-center text-gray-400 italic">
                                Chưa có sự kiện quản trị nào được ghi nhận trong phiên hiện tại.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
