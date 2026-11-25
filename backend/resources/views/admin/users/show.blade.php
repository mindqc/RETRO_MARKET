@extends('layouts.admin')

@section('title', 'Hồ sơ Người dùng #' . $targetUser->id . ' - Retro Market Admin')

@section('content')
<div class="space-y-6">
    <!-- Breadcrumb & Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <nav class="flex items-center space-x-2 text-xs text-[#8C8477] mb-1">
                <a href="{{ route('admin.dashboard') }}" class="hover:underline">Quản trị</a>
                <span>&rsaquo;</span>
                <a href="{{ route('admin.users.index') }}" class="hover:underline">Người dùng</a>
                <span>&rsaquo;</span>
                <span class="text-[#2C2E2A] font-medium">#{{ $targetUser->id }} ({{ $targetUser->display_name }})</span>
            </nav>
            <h1 class="text-2xl font-serif font-bold text-[#2C2E2A]">Hồ sơ 360° & Phân quyền Quản trị (A-US-02)</h1>
            <p class="text-xs text-[#6E675F]">Soi chiếu toàn diện hành vi mua/bán, điểm uy tín, số lần vi phạm và quản trị vai trò người dùng (DEC-08-02).</p>
        </div>
        <div>
            <a href="{{ route('admin.users.index') }}" class="px-4 py-2 bg-[#F2ECE1] text-[#2C2E2A] rounded-md text-xs font-semibold hover:bg-[#E5DDCF] transition-colors">
                &larr; Quay lại danh sách
            </a>
        </div>
    </div>

    <!-- Alert Messages -->
    @if(session('success'))
        <div class="p-4 bg-[#EAF2ED] border-l-4 border-[#2D5A3C] text-[#2D5A3C] rounded-r-md text-sm font-medium shadow-sm">
            {{ session('success') }}
        </div>
    @endif
    @if(session('error'))
        <div class="p-4 bg-[#FBEAEB] border-l-4 border-[#8B3A3A] text-[#8B3A3A] rounded-r-md text-sm font-medium shadow-sm">
            {{ session('error') }}
        </div>
    @endif
    @if($errors->any())
        <div class="p-4 bg-[#FBEAEB] border-l-4 border-[#8B3A3A] text-[#8B3A3A] rounded-r-md text-sm font-medium shadow-sm">
            <ul class="list-disc pl-5 space-y-1">
                @foreach($errors->all() as $err)
                    <li>{{ $err }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    @php
        $roleValue = $targetUser->role instanceof \App\Enums\UserRole ? $targetUser->role->value : (string) $targetUser->role;
        $statusValue = $targetUser->status instanceof \App\Enums\UserStatus ? $targetUser->status->value : (string) $targetUser->status;
    @endphp

    <!-- Suspension Notice Banner (if suspended) -->
    @if($statusValue === 'SUSPENDED')
        <div class="p-4 bg-[#FBEAEB] border border-[#E0B4B4] rounded-lg text-[#8B3A3A] shadow-sm flex items-start gap-3">
            <svg class="w-5 h-5 shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
            <div>
                <h4 class="font-bold text-sm">TÀI KHOẢN ĐANG BỊ TẠM KHÓA (SUSPENDED)</h4>
                <p class="text-xs mt-1">Lý do: <em>"{{ $targetUser->status_reason ?? 'Vi phạm quy chế sàn' }}"</em></p>
                @if($targetUser->suspended_until)
                    <p class="text-[11px] mt-0.5">Thời hạn khóa đến: <strong>{{ $targetUser->suspended_until->format('d/m/Y H:i') }}</strong></p>
                @endif
                <p class="text-[10px] text-[#8C8477] mt-1">Mọi phiên đăng nhập và token truy cập của người dùng này đã bị thu hồi lập tức (BR-AC-04).</p>
            </div>
        </div>
    @endif

    <!-- Profile Summary Card -->
    <div class="bg-white rounded-lg border border-[#E0D7C7] p-5 shadow-sm">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-[#E0D7C7] pb-4">
            <div class="flex items-center gap-4">
                <div class="w-14 h-14 rounded-full bg-[#84664C] text-white flex items-center justify-center font-serif font-bold text-xl shadow-inner">
                    {{ strtoupper(substr($targetUser->display_name, 0, 1)) }}
                </div>
                <div>
                    <div class="flex items-center gap-2">
                        <h2 class="text-xl font-bold font-serif text-[#2C2E2A]">{{ $targetUser->display_name }}</h2>
                        <span class="inline-flex items-center px-2.5 py-0.5 rounded text-xs font-semibold
                            {{ $roleValue === 'admin' ? 'bg-red-100 text-red-800' : ($roleValue === 'moderator' ? 'bg-blue-100 text-blue-800' : ($roleValue === 'support' ? 'bg-amber-100 text-amber-800' : 'bg-gray-100 text-gray-800')) }}">
                            {{ strtoupper($roleValue) }}
                        </span>
                        <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold
                            {{ $statusValue === 'ACTIVE' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800' }}">
                            {{ $statusValue }}
                        </span>
                    </div>
                    <div class="flex flex-wrap gap-x-4 gap-y-1 text-xs text-[#8C8477] mt-1">
                        <span>Email: <strong class="text-[#2C2E2A]">{{ $targetUser->email }}</strong></span>
                        <span>SĐT: <strong class="text-[#2C2E2A]">{{ $targetUser->phone ?? 'Chưa cập nhật' }}</strong></span>
                        <span>Mã ID: <strong class="font-mono text-[#2C2E2A]">#{{ $targetUser->id }}</strong></span>
                    </div>
                </div>
            </div>
            <div class="text-xs text-[#8C8477] text-right">
                <div>Ngày tham gia: <strong class="text-[#2C2E2A]">{{ $targetUser->created_at->format('d/m/Y H:i') }}</strong></div>
                <div>Đăng nhập gần nhất: <strong class="text-[#2C2E2A]">{{ $targetUser->last_login_at ? $targetUser->last_login_at->format('d/m/Y H:i') : 'Chưa có' }}</strong></div>
            </div>
        </div>

        <!-- 360° Metrics Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-5">
            <!-- Buyer Dimension -->
            <div class="p-4 bg-[#FAF8F5] rounded-md border border-[#E0D7C7]">
                <h3 class="text-xs font-bold uppercase tracking-wider text-[#84664C] mb-3 flex items-center gap-1.5">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"/></svg>
                    <span>Kênh Mua hàng (Buyer Metrics)</span>
                </h3>
                <div class="grid grid-cols-2 gap-3 text-xs">
                    <div>
                        <span class="text-[#8C8477] block">Đơn hàng đã đặt:</span>
                        <strong class="font-mono text-base text-[#2C2E2A]">{{ number_format($buyerStats['orders_count']) }}</strong>
                    </div>
                    <div>
                        <span class="text-[#8C8477] block">Đơn hoàn tất thành công:</span>
                        <strong class="font-mono text-base text-[#2D5A3C]">{{ number_format($buyerStats['completed_orders_count']) }}</strong>
                    </div>
                    <div>
                        <span class="text-[#8C8477] block">Tổng chi tiêu hoàn tất:</span>
                        <strong class="font-mono text-base text-[#2C2E2A]">{{ number_format($buyerStats['total_spent']) }} đ</strong>
                    </div>
                    <div>
                        <span class="text-[#8C8477] block">Số khiếu nại đã mở:</span>
                        <strong class="font-mono text-base {{ $buyerStats['disputes_opened'] > 0 ? 'text-[#8B3A3A]' : 'text-[#2C2E2A]' }}">{{ number_format($buyerStats['disputes_opened']) }}</strong>
                    </div>
                </div>
            </div>

            <!-- Seller Dimension -->
            <div class="p-4 bg-[#FAF8F5] rounded-md border border-[#E0D7C7]">
                <h3 class="text-xs font-bold uppercase tracking-wider text-[#84664C] mb-3 flex items-center gap-1.5">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/></svg>
                    <span>Kênh Bán hàng (Seller Shop Dimension)</span>
                </h3>
                @if($sellerStats)
                    <div class="grid grid-cols-3 gap-3 text-xs">
                        <div>
                            <span class="text-[#8C8477] block">Shop Slug:</span>
                            <strong class="text-[#84664C] font-semibold truncate block">{{ $sellerStats['shop_slug'] }}</strong>
                        </div>
                        <div>
                            <span class="text-[#8C8477] block">Điểm Uy tín:</span>
                            <strong class="font-mono text-base text-[#2D5A3C]">{{ number_format($sellerStats['trust_score'], 1) }} / 100</strong>
                        </div>
                        <div>
                            <span class="text-[#8C8477] block">Bùng cọc đấu giá:</span>
                            <strong class="font-mono text-base {{ $sellerStats['auction_default_count'] > 0 ? 'text-[#8B3A3A]' : 'text-[#2C2E2A]' }}">{{ number_format($sellerStats['auction_default_count']) }} lần</strong>
                        </div>
                        <div>
                            <span class="text-[#8C8477] block">Số dư Ví:</span>
                            <strong class="font-mono text-sm text-[#2C2E2A]">{{ number_format($sellerStats['wallet_balance']) }} đ</strong>
                        </div>
                        <div>
                            <span class="text-[#8C8477] block">Escrow Đang giữ:</span>
                            <strong class="font-mono text-sm text-[#84664C]">{{ number_format($sellerStats['escrow_held_balance']) }} đ</strong>
                        </div>
                        <div>
                            <span class="text-[#8C8477] block">Khiếu nại thua:</span>
                            <strong class="font-mono text-sm {{ $sellerStats['dispute_lost_count'] > 0 ? 'text-[#8B3A3A]' : 'text-[#2C2E2A]' }}">{{ number_format($sellerStats['dispute_lost_count']) }}</strong>
                        </div>
                    </div>
                @else
                    <p class="text-xs text-[#8C8477] italic py-3">Tài khoản này chưa đăng ký mở Shop bán hàng.</p>
                @endif
            </div>
        </div>
    </div>

    <!-- Governance Actions (Supreme Admin ONLY) -->
    @if(auth()->user()?->isAdmin())
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <!-- Account Status Governance -->
            <div class="bg-white rounded-lg border border-[#E0D7C7] p-5 shadow-sm">
                <h3 class="text-sm font-bold font-serif text-[#2C2E2A] mb-1">Quản trị Trạng thái Tài khoản (Status Governance)</h3>
                <p class="text-xs text-[#6E675F] mb-4">Khóa hoặc kích hoạt lại tài khoản. Khi bị khóa, toàn bộ phiên đăng nhập của người dùng sẽ bị chấm dứt (BR-AC-04).</p>

                <form method="POST" action="{{ route('admin.users.update_status', $targetUser->id) }}" class="space-y-4">
                    @csrf
                    <div>
                        <label class="block text-xs font-bold uppercase text-[#2C2E2A] mb-1">Trạng thái mới <span class="text-red-500">*</span></label>
                        <select name="status" class="w-full py-2 px-3 border border-[#E0D7C7] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#84664C]">
                            <option value="ACTIVE" {{ $statusValue === 'ACTIVE' ? 'selected' : '' }}>ACTIVE (Hoạt động bình thường)</option>
                            <option value="SUSPENDED" {{ $statusValue === 'SUSPENDED' ? 'selected' : '' }}>SUSPENDED (Khóa tài khoản / Tạm dừng)</option>
                        </select>
                    </div>

                    <div>
                        <label class="block text-xs font-bold uppercase text-[#2C2E2A] mb-1">Lý do điều chỉnh trạng thái <span class="text-red-500">*</span></label>
                        <textarea name="reason" rows="3" required minlength="5" maxlength="1000"
                                  placeholder="Nhập lý do khóa hoặc mở khóa tài khoản (bắt buộc tối thiểu 5 ký tự)..."
                                  class="w-full p-2.5 border border-[#E0D7C7] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#84664C]"></textarea>
                    </div>

                    <div class="pt-2">
                        <button type="submit"
                                onclick="return confirm('Bạn có chắc chắn muốn thay đổi trạng thái tài khoản này?')"
                                class="w-full py-2 bg-[#84664C] text-white rounded-md text-xs font-bold hover:bg-[#6E543E] transition-colors shadow-sm">
                            Xác nhận Thay đổi Trạng thái
                        </button>
                    </div>
                </form>
            </div>

            <!-- Role Governance -->
            <div class="bg-white rounded-lg border border-[#E0D7C7] p-5 shadow-sm">
                <h3 class="text-sm font-bold font-serif text-[#2C2E2A] mb-1">Phân quyền & Vai trò Nhân sự (Role Governance)</h3>
                <p class="text-xs text-[#6E675F] mb-4">Ủy quyền hoặc thu hồi vai trò Quản trị viên, Kiểm duyệt viên hoặc Chăm sóc khách hàng (DEC-08-02).</p>

                <form method="POST" action="{{ route('admin.users.update_role', $targetUser->id) }}" class="space-y-4">
                    @csrf
                    <div>
                        <label class="block text-xs font-bold uppercase text-[#2C2E2A] mb-1">Vai trò mới <span class="text-red-500">*</span></label>
                        <select name="role" class="w-full py-2 px-3 border border-[#E0D7C7] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#84664C]">
                            <option value="registered_user" {{ $roleValue === 'registered_user' ? 'selected' : '' }}>registered_user (Người dùng thường)</option>
                            <option value="moderator" {{ $roleValue === 'moderator' ? 'selected' : '' }}>moderator (Kiểm duyệt viên danh mục & sản phẩm)</option>
                            <option value="support" {{ $roleValue === 'support' ? 'selected' : '' }}>support (Chăm sóc khách hàng & Tranh chấp)</option>
                            <option value="admin" {{ $roleValue === 'admin' ? 'selected' : '' }}>admin (Quản trị viên tối cao hệ thống)</option>
                        </select>
                    </div>

                    <div>
                        <label class="block text-xs font-bold uppercase text-[#2C2E2A] mb-1">Lý do thay đổi vai trò <span class="text-red-500">*</span></label>
                        <textarea name="reason" rows="3" required minlength="5" maxlength="1000"
                                  placeholder="Nhập lý do phân quyền hoặc hạ quyền nhân sự (bắt buộc tối thiểu 5 ký tự)..."
                                  class="w-full p-2.5 border border-[#E0D7C7] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#84664C]"></textarea>
                    </div>

                    <div class="pt-2">
                        <button type="submit"
                                onclick="return confirm('Bạn có chắc chắn muốn thay đổi vai trò của người dùng này?')"
                                class="w-full py-2 bg-[#2D5A3C] text-white rounded-md text-xs font-bold hover:bg-[#234730] transition-colors shadow-sm">
                            Xác nhận Cập nhật Vai trò
                        </button>
                    </div>
                </form>
            </div>
        </div>
    @else
        <div class="p-4 bg-gray-50 border border-gray-200 rounded-lg text-xs text-[#6E675F] italic">
            * Tính năng thay đổi vai trò và khóa/mở khóa tài khoản chỉ dành riêng cho Quản trị viên tối cao (Admin).
        </div>
    @endif

    <!-- Recent Orders Table -->
    <div class="bg-white rounded-lg border border-[#E0D7C7] shadow-sm overflow-hidden">
        <div class="p-4 bg-[#F8F5F0] border-b border-[#E0D7C7] flex items-center justify-between">
            <h3 class="text-sm font-bold font-serif text-[#2C2E2A]">Đơn hàng Gần đây (Recent Orders)</h3>
            <span class="text-xs text-[#8C8477]">Hiển thị tối đa 5 đơn hàng mới nhất</span>
        </div>
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse text-xs">
                <thead>
                    <tr class="bg-[#FAF8F5] border-b border-[#E0D7C7] text-[#8C8477] uppercase text-[10px]">
                        <th class="py-2.5 px-4">Mã đơn</th>
                        <th class="py-2.5 px-4">Vai trò</th>
                        <th class="py-2.5 px-4">Tổng tiền</th>
                        <th class="py-2.5 px-4">Trạng thái</th>
                        <th class="py-2.5 px-4">Ngày tạo</th>
                        <th class="py-2.5 px-4 text-right">Chi tiết</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#E0D7C7]">
                    @forelse($recentOrders as $order)
                        <tr class="hover:bg-[#FAF8F5]">
                            <td class="py-2.5 px-4 font-mono font-bold text-[#2D5A3C]">#{{ $order->order_code }}</td>
                            <td class="py-2.5 px-4">
                                @if($order->buyer_id === $targetUser->id)
                                    <span class="text-blue-700 font-semibold">Khách mua</span>
                                @else
                                    <span class="text-[#84664C] font-semibold">Người bán</span>
                                @endif
                            </td>
                            <td class="py-2.5 px-4 font-mono font-bold text-[#2C2E2A]">{{ number_format((float) $order->total_amount) }} đ</td>
                            <td class="py-2.5 px-4">
                                <span class="px-2 py-0.5 rounded text-[10px] font-semibold bg-gray-100 text-[#2C2E2A]">
                                    {{ $order->order_status->value ?? $order->order_status }}
                                </span>
                            </td>
                            <td class="py-2.5 px-4 text-[#8C8477]">{{ $order->created_at->format('d/m/Y H:i') }}</td>
                            <td class="py-2.5 px-4 text-right">
                                <a href="{{ route('admin.orders.show', $order->id) }}" class="text-[#84664C] hover:underline font-semibold">
                                    Xem &rarr;
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="py-4 text-center text-[#8C8477] italic">Chưa có giao dịch đơn hàng nào.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <!-- Audit Logs for this User -->
    <div class="bg-white rounded-lg border border-[#E0D7C7] shadow-sm overflow-hidden">
        <div class="p-4 bg-[#F8F5F0] border-b border-[#E0D7C7] flex items-center justify-between">
            <h3 class="text-sm font-bold font-serif text-[#2C2E2A]">Lịch sử Nhật ký Kiểm toán Tài khoản (Account Audit Trail)</h3>
            <span class="text-xs text-[#8C8477]">Bản ghi bất biến ghi nhận các thay đổi quản trị</span>
        </div>
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse text-xs">
                <thead>
                    <tr class="bg-[#FAF8F5] border-b border-[#E0D7C7] text-[#8C8477] uppercase text-[10px]">
                        <th class="py-2.5 px-4">Thời gian</th>
                        <th class="py-2.5 px-4">Người thực hiện</th>
                        <th class="py-2.5 px-4">Hành động</th>
                        <th class="py-2.5 px-4">Lý do</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#E0D7C7]">
                    @forelse($auditLogs as $log)
                        <tr class="hover:bg-[#FAF8F5]">
                            <td class="py-2.5 px-4 font-mono text-[#8C8477]">{{ $log->created_at->format('d/m/Y H:i:s') }}</td>
                            <td class="py-2.5 px-4">
                                <span class="font-medium text-[#2C2E2A]">{{ $log->actor?->display_name ?? 'System' }}</span>
                                <span class="text-[10px] text-[#8C8477]">({{ $log->actor_role }})</span>
                            </td>
                            <td class="py-2.5 px-4">
                                <span class="font-mono text-xs font-semibold px-2 py-0.5 rounded bg-[#F0ECE1] text-[#84664C]">
                                    {{ $log->action }}
                                </span>
                            </td>
                            <td class="py-2.5 px-4 text-[#6E675F] max-w-md truncate" title="{{ $log->reason }}">
                                "{{ $log->reason }}"
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="4" class="py-4 text-center text-[#8C8477] italic">Chưa có bản ghi kiểm toán nào cho tài khoản này.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
