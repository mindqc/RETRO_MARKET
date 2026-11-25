@php
    use App\Support\AdminPermission;
    $user = auth('web')->user();
@endphp

<aside class="w-64 bg-[#1C1E1B] text-[#E8E2D9] flex flex-col shrink-0 border-r border-[#2C2E2A]">
    <!-- Brand Header -->
    <div class="h-16 flex items-center px-6 border-b border-[#2C2E2A]">
        <div class="flex items-center space-x-3">
            <span class="w-8 h-8 rounded-md bg-[#C85A32] flex items-center justify-center text-white font-serif font-black text-lg shadow-sm">
                i
            </span>
            <div>
                <h1 class="font-serif text-lg font-bold tracking-tight text-white">izithrift</h1>
                <p class="text-[10px] tracking-wider uppercase text-[#C5A66B] font-medium">Administration</p>
            </div>
        </div>
    </div>

    <!-- Navigation Menu -->
    <nav class="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
        <!-- Dashboard -->
        @if (AdminPermission::can($user, 'dashboard.view'))
            <a href="{{ route('admin.dashboard') }}"
               class="flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors {{ request()->routeIs('admin.dashboard') ? 'bg-[#2D5A3C] text-white font-semibold' : 'text-[#BFB6A8] hover:bg-[#282B26] hover:text-white' }}">
                <svg class="w-5 h-5 mr-3 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
                </svg>
                Tổng quan (Dashboard)
            </a>
        @endif

        <div class="pt-4 pb-1">
            <p class="px-3 text-[10px] uppercase tracking-wider font-semibold text-[#8C8477]">Kiểm duyệt & Danh mục</p>
        </div>

        <!-- Moderation Queue (A-MD-01) -->
        @if (AdminPermission::can($user, 'products.view'))
            <a href="{{ route('admin.moderation.products.index') }}"
               class="flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors {{ request()->routeIs('admin.moderation.*') ? 'bg-[#2D5A3C] text-white font-semibold' : 'text-[#BFB6A8] hover:bg-[#282B26] hover:text-white' }}">
                <svg class="w-5 h-5 mr-3 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                </svg>
                Hàng đợi Kiểm duyệt
            </a>
        @endif

        <!-- Master Products Inventory (A-PR-01) -->
        @if (AdminPermission::can($user, 'products.view'))
            <a href="{{ route('admin.products.index') }}"
               class="flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors {{ request()->routeIs('admin.products.*') ? 'bg-[#2D5A3C] text-white font-semibold' : 'text-[#BFB6A8] hover:bg-[#282B26] hover:text-white' }}">
                <svg class="w-5 h-5 mr-3 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/>
                </svg>
                Quản lý Sản phẩm
            </a>
        @endif

        <!-- Catalog Taxonomy (A-CT-01) -->
        @if (AdminPermission::can($user, 'categories.view'))
            <a href="{{ route('admin.catalog.index') }}"
               class="flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors {{ request()->routeIs('admin.catalog.*') ? 'bg-[#2D5A3C] text-white font-semibold' : 'text-[#BFB6A8] hover:bg-[#282B26] hover:text-white' }}">
                <svg class="w-5 h-5 mr-3 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"/>
                </svg>
                Phân loại & Danh mục
            </a>
        @endif

        <!-- Violation Reports (A-CM-01) -->
        @if (AdminPermission::can($user, 'reports.view'))
            <a href="{{ route('admin.moderation.reports.index') }}"
               class="flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors {{ request()->routeIs('admin.moderation.reports.*') ? 'bg-[#2D5A3C] text-white font-semibold' : 'text-[#BFB6A8] hover:bg-[#282B26] hover:text-white' }}">
                <svg class="w-5 h-5 mr-3 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
                </svg>
                Báo cáo Vi phạm
            </a>
        @endif

        <div class="pt-4 pb-1">
            <p class="px-3 text-[10px] uppercase tracking-wider font-semibold text-[#8C8477]">Vận hành & Giao dịch</p>
        </div>

        <!-- Auctions (A-AC-01..03) -->
        @if (AdminPermission::can($user, 'auctions.view'))
            <a href="{{ route('admin.auctions.index') }}"
               class="flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors {{ request()->routeIs('admin.auctions.*') ? 'bg-[#2D5A3C] text-white font-semibold' : 'text-[#BFB6A8] hover:bg-[#282B26] hover:text-white' }}">
                <svg class="w-5 h-5 mr-3 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
                </svg>
                Quản lý Đấu giá
            </a>
        @endif

        <!-- Orders (A-OR-01..02) -->
        @if (AdminPermission::can($user, 'orders.view'))
            <a href="{{ route('admin.orders.index') }}"
               class="flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors {{ request()->routeIs('admin.orders.*') ? 'bg-[#2D5A3C] text-white font-semibold' : 'text-[#BFB6A8] hover:bg-[#282B26] hover:text-white' }}">
                <svg class="w-5 h-5 mr-3 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"/>
                </svg>
                Đơn hàng & Escrow
            </a>
        @endif

        <!-- Payments (A-PM-01) -->
        @if (AdminPermission::can($user, 'payments.view'))
            <a href="{{ route('admin.payments.index') }}"
               class="flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors {{ request()->routeIs('admin.payments.*') ? 'bg-[#2D5A3C] text-white font-semibold' : 'text-[#BFB6A8] hover:bg-[#282B26] hover:text-white' }}">
                <svg class="w-5 h-5 mr-3 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z"/>
                </svg>
                Giao dịch Thanh toán
            </a>
        @endif

        <!-- Escrow Immutable Ledger (A-ES-01) -->
        @if (AdminPermission::can($user, 'escrow.view'))
            <a href="{{ route('admin.escrow.index') }}"
               class="flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors {{ request()->routeIs('admin.escrow.*') ? 'bg-[#2D5A3C] text-white font-semibold' : 'text-[#BFB6A8] hover:bg-[#282B26] hover:text-white' }}">
                <svg class="w-5 h-5 mr-3 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                </svg>
                Sổ cái Ký quỹ (Escrow)
            </a>
        @endif

        <!-- Disputes (A-DP-01..02) -->
        @if (AdminPermission::can($user, 'disputes.view'))
            <a href="{{ route('admin.disputes.index') }}"
               class="flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors {{ request()->routeIs('admin.disputes.*') ? 'bg-[#2D5A3C] text-white font-semibold' : 'text-[#BFB6A8] hover:bg-[#282B26] hover:text-white' }}">
                <svg class="w-5 h-5 mr-3 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 6l3 1m0 0l-3 9a5.002 5.002 0 006.001 0M6 7l3 9M6 7l6-2m6 2l3-1m-3 1l-3 9a5.002 5.002 0 006.001 0M18 7l3 9m-3-9l-6-2m0-2v2m0 16V5m0 16H9m3 0h3"/>
                </svg>
                Tranh chấp & Khiếu nại
            </a>
        @endif

        <!-- Users -->
        @if (AdminPermission::can($user, 'users.view'))
            <a href="{{ route('admin.users.index') }}"
               class="flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors {{ request()->routeIs('admin.users.*') ? 'bg-[#2D5A3C] text-white' : 'text-[#BFB6A8] hover:bg-[#282B26] hover:text-white' }}">
                <svg class="w-5 h-5 mr-3 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/>
                </svg>
                Quản lý Người dùng
            </a>
        @endif

        <div class="pt-4 pb-1">
            <p class="px-3 text-[10px] uppercase tracking-wider font-semibold text-[#8C8477]">Hệ thống & Kiểm toán</p>
        </div>

        <!-- Settings -->
        @if (AdminPermission::can($user, 'settings.manage'))
            <a href="{{ route('admin.settings.index') }}"
               class="flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors {{ request()->routeIs('admin.settings.*') ? 'bg-[#2D5A3C] text-white' : 'text-[#BFB6A8] hover:bg-[#282B26] hover:text-white' }}">
                <svg class="w-5 h-5 mr-3 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/>
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                </svg>
                Cấu hình Nền tảng
            </a>
        @endif

        <!-- Audit Logs -->
        @if (AdminPermission::can($user, 'audit_logs.view'))
            <a href="{{ route('admin.audit_logs.index') }}"
               class="flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors {{ request()->routeIs('admin.audit_logs.*') ? 'bg-[#2D5A3C] text-white' : 'text-[#BFB6A8] hover:bg-[#282B26] hover:text-white' }}">
                <svg class="w-5 h-5 mr-3 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                </svg>
                Nhật ký Kiểm toán
            </a>
        @endif

        <!-- Developer Tools (A-DT-01) - Demo Mode Only -->
        @if ($user?->isAdmin() && config('retromarket.demo_mode', false))
            <a href="{{ route('admin.dev_tools.index') }}"
               class="flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors {{ request()->routeIs('admin.dev_tools.*') ? 'bg-[#84664C] text-white' : 'text-[#C5A66B] hover:bg-[#282B26] hover:text-white' }}">
                <svg class="w-5 h-5 mr-3 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"/>
                </svg>
                Developer Tools (Demo)
            </a>
        @endif
    </nav>

    <!-- Footer Status -->
    <div class="p-4 border-t border-[#2C2E2A] text-[11px] text-[#8C8477] text-center">
        Retro Market Admin v1.0 &bull; P8-05
    </div>
</aside>
