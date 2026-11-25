@extends('layouts.admin')

@section('title', 'Quản lý Người dùng & Nhân sự - Retro Market Admin')

@section('content')
<div class="space-y-6">
    <!-- Breadcrumb & Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <nav class="flex items-center space-x-2 text-xs text-[#8C8477] mb-1">
                <a href="{{ route('admin.dashboard') }}" class="hover:underline">Quản trị</a>
                <span>&rsaquo;</span>
                <span class="text-[#2C2E2A] font-medium">Người dùng & Tài khoản</span>
            </nav>
            <h1 class="text-2xl font-serif font-bold text-[#2C2E2A]">Quản lý Người dùng & Nhân sự Hệ thống</h1>
            <p class="text-xs text-[#6E675F]">Mô hình tài khoản hợp nhất (BR-AC-01) phục vụ cả người mua, người bán và phân quyền nhân sự nội bộ (A-US-01).</p>
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

    <!-- Metrics Cards -->
    <div class="grid grid-cols-2 md:grid-cols-5 gap-3">
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#8C8477] uppercase tracking-wider">Tổng tài khoản</span>
            <p class="text-2xl font-bold font-serif text-[#2C2E2A] mt-1">{{ number_format($stats['total']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#2D5A3C] uppercase tracking-wider">Đang hoạt động</span>
            <p class="text-2xl font-bold font-serif text-[#2D5A3C] mt-1">{{ number_format($stats['active']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#8B3A3A] uppercase tracking-wider">Bị tạm khóa</span>
            <p class="text-2xl font-bold font-serif text-[#8B3A3A] mt-1">{{ number_format($stats['suspended']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#84664C] uppercase tracking-wider">Người bán (Shop)</span>
            <p class="text-2xl font-bold font-serif text-[#84664C] mt-1">{{ number_format($stats['sellers']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#C5A66B] uppercase tracking-wider">Nhân sự nội bộ</span>
            <p class="text-2xl font-bold font-serif text-[#C5A66B] mt-1">{{ number_format($stats['staff']) }}</p>
        </div>
    </div>

    <!-- Filter & Search Toolbar -->
    <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
        <form method="GET" action="{{ route('admin.users.index') }}" class="flex flex-col md:flex-row gap-3">
            <div class="flex-1 relative">
                <input type="text" name="search" value="{{ request('search') }}"
                       placeholder="Tìm kiếm theo tên, email, số điện thoại..."
                       class="w-full pl-9 pr-4 py-2 border border-[#E0D7C7] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#84664C]">
                <svg class="w-4 h-4 text-[#8C8477] absolute left-3 top-2.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                </svg>
            </div>

            <div class="w-full md:w-48">
                <select name="role" class="w-full py-2 px-3 border border-[#E0D7C7] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#84664C]">
                    <option value="">Tất cả vai trò (Role)</option>
                    <option value="registered_user" {{ request('role') === 'registered_user' ? 'selected' : '' }}>Người dùng thường (User)</option>
                    <option value="moderator" {{ request('role') === 'moderator' ? 'selected' : '' }}>Kiểm duyệt viên (Moderator)</option>
                    <option value="support" {{ request('role') === 'support' ? 'selected' : '' }}>CSKH & Tranh chấp (Support)</option>
                    <option value="admin" {{ request('role') === 'admin' ? 'selected' : '' }}>Quản trị viên (Admin)</option>
                </select>
            </div>

            <div class="w-full md:w-44">
                <select name="status" class="w-full py-2 px-3 border border-[#E0D7C7] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#84664C]">
                    <option value="">Tất cả trạng thái</option>
                    <option value="ACTIVE" {{ request('status') === 'ACTIVE' ? 'selected' : '' }}>Đang hoạt động (ACTIVE)</option>
                    <option value="SUSPENDED" {{ request('status') === 'SUSPENDED' ? 'selected' : '' }}>Bị khóa (SUSPENDED)</option>
                </select>
            </div>

            <div class="flex gap-2">
                <button type="submit" class="px-4 py-2 bg-[#84664C] text-white rounded-md text-sm font-medium hover:bg-[#6E543E] transition-colors">
                    Lọc
                </button>
                @if(request()->anyFilled(['search', 'role', 'status']))
                    <a href="{{ route('admin.users.index') }}" class="px-3 py-2 bg-gray-100 text-[#6E675F] rounded-md text-sm font-medium hover:bg-gray-200 transition-colors flex items-center justify-center">
                        Xóa lọc
                    </a>
                @endif
            </div>
        </form>
    </div>

    <!-- Users Table -->
    <div class="bg-white rounded-lg border border-[#E0D7C7] shadow-sm overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse text-sm">
                <thead>
                    <tr class="bg-[#F8F5F0] border-b border-[#E0D7C7] text-[11px] font-semibold text-[#8C8477] uppercase tracking-wider">
                        <th class="py-3 px-4">ID</th>
                        <th class="py-3 px-4">Họ và tên & Email</th>
                        <th class="py-3 px-4">Vai trò (Role)</th>
                        <th class="py-3 px-4">Kênh Bán hàng (Shop)</th>
                        <th class="py-3 px-4">Trạng thái</th>
                        <th class="py-3 px-4">Ngày đăng ký</th>
                        <th class="py-3 px-4 text-right">Thao tác</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#E0D7C7]">
                    @forelse($users as $user)
                        <tr class="hover:bg-[#FAF8F5] transition-colors">
                            <td class="py-3 px-4 font-mono font-medium text-[#2C2E2A]">#{{ $user->id }}</td>
                            <td class="py-3 px-4">
                                <div class="font-medium text-[#2C2E2A]">{{ $user->display_name }}</div>
                                <div class="text-xs text-[#8C8477]">{{ $user->email }}</div>
                                @if($user->phone)
                                    <div class="text-[10px] text-[#8C8477] font-mono mt-0.5">{{ $user->phone }}</div>
                                @endif
                            </td>
                            <td class="py-3 px-4">
                                @php
                                    $roleValue = $user->role instanceof \App\Enums\UserRole ? $user->role->value : (string) $user->role;
                                    $roleBadge = match($roleValue) {
                                        'admin' => 'bg-red-50 text-red-700 border-red-200 font-bold',
                                        'moderator' => 'bg-blue-50 text-blue-700 border-blue-200 font-semibold',
                                        'support' => 'bg-amber-50 text-amber-700 border-amber-200 font-semibold',
                                        default => 'bg-gray-50 text-gray-700 border-gray-200',
                                    };
                                @endphp
                                <span class="inline-flex items-center px-2 py-0.5 rounded text-xs border {{ $roleBadge }}">
                                    {{ strtoupper($roleValue) }}
                                </span>
                            </td>
                            <td class="py-3 px-4">
                                @if($user->sellerProfile)
                                    <div class="text-xs font-semibold text-[#84664C] flex items-center gap-1">
                                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"/></svg>
                                        <span>{{ $user->sellerProfile->shop_slug }}</span>
                                    </div>
                                    <div class="text-[10px] text-[#6E675F] mt-0.5">
                                        Điểm uy tín: <strong class="font-mono text-[#2D5A3C]">{{ number_format((float) $user->sellerProfile->trust_score, 1) }}</strong>
                                    </div>
                                @else
                                    <span class="text-xs text-[#8C8477] italic">Người mua</span>
                                @endif
                            </td>
                            <td class="py-3 px-4">
                                @php
                                    $statusValue = $user->status instanceof \App\Enums\UserStatus ? $user->status->value : (string) $user->status;
                                @endphp
                                @if($statusValue === 'ACTIVE')
                                    <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-green-100 text-[#2D5A3C]">
                                        Hoạt động
                                    </span>
                                @else
                                    <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-red-100 text-[#8B3A3A]">
                                        Bị khóa
                                    </span>
                                @endif
                            </td>
                            <td class="py-3 px-4 text-xs font-mono text-[#8C8477]">
                                {{ $user->created_at->format('d/m/Y H:i') }}
                            </td>
                            <td class="py-3 px-4 text-right">
                                <a href="{{ route('admin.users.show', $user->id) }}"
                                   class="inline-flex items-center px-3 py-1.5 bg-[#84664C] text-white rounded text-xs font-medium hover:bg-[#6E543E] transition-colors shadow-sm">
                                    Hồ sơ 360°
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="py-8 text-center text-sm text-[#8C8477]">
                                Không tìm thấy người dùng nào phù hợp.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($users->hasPages())
            <div class="p-4 border-t border-[#E0D7C7]">
                {{ $users->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
