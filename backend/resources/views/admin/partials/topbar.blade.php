<header class="h-16 bg-white border-b border-[#E5E7EB] px-6 flex items-center justify-between sticky top-0 z-20">
    <div class="flex items-center space-x-3">
        <h2 class="text-lg font-bold tracking-tight text-[#231F20]">@yield('header_title', 'Bảng điều khiển Quản trị')</h2>
        <span class="text-xs px-2.5 py-0.5 rounded-full bg-[#E7F2EC] text-[#174D38] font-semibold tabular-nums">
            {{ $serverTime ?? now()->timezone('Asia/Ho_Chi_Minh')->format('d/m/Y H:i:s T') }}
        </span>
    </div>

    <div class="flex items-center space-x-4">
        @php
            $authUser = auth('web')->user();
            $roleLabel = $authUser?->role?->label() ?? 'Nhân viên';
            $roleClass = match($authUser?->role?->value) {
                'admin' => 'bg-[#FBEDE9] text-[#C65335] border-[#F0C6BA]',
                'moderator' => 'bg-[#E7F2EC] text-[#174D38] border-[#BBDAC8]',
                'support' => 'bg-[#F8EED6] text-[#8C6518] border-[#E7D29D]',
                default => 'bg-gray-100 text-gray-800 border-gray-300',
            };
        @endphp

        <div class="flex items-center space-x-3 pr-2">
            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold border {{ $roleClass }}">
                {{ $roleLabel }}
            </span>
            <div class="text-right">
                <div class="text-sm font-semibold text-[#231F20]">{{ $authUser?->display_name ?? 'Admin Staff' }}</div>
                <div class="text-xs text-[#6B7280]">{{ $authUser?->email }}</div>
            </div>
        </div>

        <form method="POST" action="{{ route('admin.logout') }}" class="inline">
            @csrf
            <button type="submit" class="inline-flex items-center px-3 py-1.5 border border-[#E5E7EB] text-xs font-semibold rounded-lg text-[#231F20] hover:bg-[#F4F5F7] hover:border-[#174D38] transition-colors focus:outline-hidden focus:ring-2 focus:ring-offset-2 focus:ring-[#174D38]">
                <svg class="w-4 h-4 mr-1.5 text-[#174D38]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
                </svg>
                Đăng xuất
            </button>
        </form>
    </div>
</header>
