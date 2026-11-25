<header class="h-16 bg-white border-b border-[#E8E2D9] px-6 flex items-center justify-between sticky top-0 z-20 shadow-xs">
    <div class="flex items-center space-x-4">
        <h2 class="text-lg font-serif font-bold text-[#1F2937]">@yield('header_title', 'Bảng điều khiển Quản trị')</h2>
        <span class="text-xs px-2.5 py-0.5 rounded-full bg-[#F4EBDD] text-[#84664C] font-mono">
            {{ $serverTime ?? now()->timezone('Asia/Ho_Chi_Minh')->format('d/m/Y H:i:s T') }}
        </span>
    </div>

    <div class="flex items-center space-x-4">
        @php
            $authUser = auth('web')->user();
            $roleLabel = $authUser?->role?->label() ?? 'Nhân viên';
            $roleClass = match($authUser?->role?->value) {
                'admin' => 'bg-rose-100 text-rose-800 border-rose-300',
                'moderator' => 'bg-emerald-100 text-emerald-800 border-emerald-300',
                'support' => 'bg-amber-100 text-amber-800 border-amber-300',
                default => 'bg-gray-100 text-gray-800 border-gray-300',
            };
        @endphp

        <div class="flex items-center space-x-3 pr-2">
            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold border {{ $roleClass }}">
                {{ $roleLabel }}
            </span>
            <div class="text-right">
                <div class="text-sm font-medium text-[#1F2937]">{{ $authUser?->display_name ?? 'Admin Staff' }}</div>
                <div class="text-xs text-gray-500">{{ $authUser?->email }}</div>
            </div>
        </div>

        <form method="POST" action="{{ route('admin.logout') }}" class="inline">
            @csrf
            <button type="submit" class="inline-flex items-center px-3 py-1.5 border border-[#D5CBC1] text-xs font-medium rounded-md text-[#5E5852] hover:bg-[#F4EBDD] hover:text-[#1F2937] transition-colors focus:outline-hidden focus:ring-2 focus:ring-offset-2 focus:ring-[#C85A32]">
                <svg class="w-4 h-4 mr-1 text-[#84664C]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
                </svg>
                Đăng xuất
            </button>
        </form>
    </div>
</header>
