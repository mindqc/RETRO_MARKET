@extends('layouts.admin')

@section('title', 'Quản lý Đấu giá - Retro Market Admin')

@section('content')
<div class="space-y-6">
    <!-- Breadcrumb & Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <nav class="flex items-center space-x-2 text-xs text-[#8C8477] mb-1">
                <a href="{{ route('admin.dashboard') }}" class="hover:underline">Quản trị</a>
                <span>&rsaquo;</span>
                <span class="text-[#2C2E2A] font-medium">Quản lý Đấu giá</span>
            </nav>
            <h1 class="text-2xl font-serif font-bold text-[#2C2E2A]">Quản lý và Giám sát Đấu giá</h1>
            <p class="text-xs text-[#6E675F]">Theo dõi các phiên đấu giá trực tiếp, lịch sử, chống bắn tỉa (Anti-Sniping) và xử lý người thắng bỏ cọc.</p>
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
    <div class="grid grid-cols-2 md:grid-cols-6 gap-3">
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#8C8477] uppercase tracking-wider">Tổng số phiên</span>
            <p class="text-2xl font-bold font-serif text-[#2C2E2A] mt-1">{{ number_format($stats['total']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#2D5A3C] uppercase tracking-wider">Đang diễn ra (Live)</span>
            <p class="text-2xl font-bold font-serif text-[#2D5A3C] mt-1">{{ number_format($stats['live']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#3B6E8C] uppercase tracking-wider">Sắp mở</span>
            <p class="text-2xl font-bold font-serif text-[#3B6E8C] mt-1">{{ number_format($stats['scheduled']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#84664C] uppercase tracking-wider">Đã hoàn tất</span>
            <p class="text-2xl font-bold font-serif text-[#84664C] mt-1">{{ number_format($stats['completed']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#C85A32] uppercase tracking-wider">Bỏ cọc / Quá hạn</span>
            <p class="text-2xl font-bold font-serif text-[#C85A32] mt-1">{{ number_format($stats['defaulted']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#8B3A3A] uppercase tracking-wider">Đã hủy</span>
            <p class="text-2xl font-bold font-serif text-[#8B3A3A] mt-1">{{ number_format($stats['cancelled']) }}</p>
        </div>
    </div>

    <!-- Filter & Search Toolbar -->
    <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm space-y-3">
        <!-- Tabs -->
        <div class="flex flex-wrap gap-2 border-b border-[#E0D7C7] pb-3">
            <a href="{{ route('admin.auctions.index', ['tab' => 'all']) }}"
               class="px-3 py-1.5 text-xs font-semibold rounded-md transition-colors {{ $tab === 'all' ? 'bg-[#2C2E2A] text-white' : 'bg-[#F2ECE1] text-[#6E675F] hover:bg-[#E5DDCF]' }}">
                Tất cả phiên
            </a>
            <a href="{{ route('admin.auctions.index', ['tab' => 'live']) }}"
               class="px-3 py-1.5 text-xs font-semibold rounded-md transition-colors {{ $tab === 'live' ? 'bg-[#2D5A3C] text-white' : 'bg-[#F2ECE1] text-[#6E675F] hover:bg-[#E5DDCF]' }}">
                Đang trực tiếp & Sắp mở (Live)
            </a>
            <a href="{{ route('admin.auctions.index', ['tab' => 'history']) }}"
               class="px-3 py-1.5 text-xs font-semibold rounded-md transition-colors {{ $tab === 'history' ? 'bg-[#84664C] text-white' : 'bg-[#F2ECE1] text-[#6E675F] hover:bg-[#E5DDCF]' }}">
                Lịch sử hoàn tất & Đã đóng
            </a>
            <a href="{{ route('admin.auctions.index', ['tab' => 'defaulted']) }}"
               class="px-3 py-1.5 text-xs font-semibold rounded-md transition-colors {{ $tab === 'defaulted' ? 'bg-[#C85A32] text-white' : 'bg-[#F2ECE1] text-[#6E675F] hover:bg-[#E5DDCF]' }}">
                Người thắng bỏ cọc (Winner Defaulted)
            </a>
        </div>

        <!-- Search Form -->
        <form method="GET" action="{{ route('admin.auctions.index') }}" class="flex flex-col md:flex-row gap-3">
            <input type="hidden" name="tab" value="{{ $tab }}">
            <div class="flex-1 relative">
                <input type="text" name="search" value="{{ request('search') }}"
                       placeholder="Tìm theo mã đấu giá (VD: AUC-...), tên sản phẩm, tên người bán..."
                       class="w-full pl-9 pr-3 py-2 text-xs border border-[#C5BCAB] rounded-md bg-[#FAF7F2] text-[#2C2E2A] placeholder-[#8C8477] focus:outline-none focus:ring-1 focus:ring-[#2D5A3C]">
                <svg class="w-4 h-4 absolute left-3 top-2.5 text-[#8C8477]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                </svg>
            </div>
            <div class="flex items-center gap-2">
                <select name="status" class="py-2 px-3 text-xs border border-[#C5BCAB] rounded-md bg-[#FAF7F2] text-[#2C2E2A] focus:outline-none focus:ring-1 focus:ring-[#2D5A3C]">
                    <option value="">-- Tất cả trạng thái --</option>
                    @foreach(\App\Enums\AuctionStatus::cases() as $st)
                        <option value="{{ $st->value }}" {{ request('status') === $st->value ? 'selected' : '' }}>
                            {{ $st->value }} - {{ $st->label() }}
                        </option>
                    @endforeach
                </select>
                <button type="submit" class="px-4 py-2 text-xs font-semibold bg-[#2D5A3C] text-white rounded-md hover:bg-[#23462F] transition-colors">
                    Lọc
                </button>
                @if(request()->hasAny(['search', 'status']))
                    <a href="{{ route('admin.auctions.index', ['tab' => $tab]) }}" class="px-3 py-2 text-xs font-medium text-[#6E675F] hover:underline">
                        Xóa lọc
                    </a>
                @endif
            </div>
        </form>
    </div>

    <!-- Auctions Table -->
    <div class="bg-white rounded-lg border border-[#E0D7C7] shadow-sm overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse text-xs">
                <thead>
                    <tr class="bg-[#F8F5EE] border-b border-[#E0D7C7] text-[#6E675F] uppercase tracking-wider text-[11px]">
                        <th class="py-3 px-4 font-semibold">Mã phiên</th>
                        <th class="py-3 px-4 font-semibold">Sản phẩm</th>
                        <th class="py-3 px-4 font-semibold">Người bán</th>
                        <th class="py-3 px-4 font-semibold text-right">Khởi điểm / Cao nhất</th>
                        <th class="py-3 px-4 font-semibold text-center">Bids / Watch</th>
                        <th class="py-3 px-4 font-semibold">Thời gian & Chống tỉa</th>
                        <th class="py-3 px-4 font-semibold text-center">Trạng thái</th>
                        <th class="py-3 px-4 font-semibold text-center">Hành động</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#E0D7C7]">
                    @forelse($auctions as $auction)
                        <tr class="hover:bg-[#FAF7F2] transition-colors">
                            <!-- Code -->
                            <td class="py-3 px-4 font-mono font-semibold text-[#2C2E2A]">
                                <a href="{{ route('admin.auctions.show', $auction->id) }}" class="text-[#2D5A3C] hover:underline">
                                    #{{ $auction->auction_code }}
                                </a>
                                @if($auction->session)
                                    <div class="text-[10px] text-[#8C8477]">
                                        Session: {{ $auction->session->title }}
                                    </div>
                                @endif
                            </td>

                            <!-- Product -->
                            <td class="py-3 px-4">
                                <div class="flex items-center space-x-3">
                                    @php
                                        $primaryImg = $auction->product?->primaryImage?->image_url;
                                    @endphp
                                    <div class="w-10 h-10 rounded border border-[#E0D7C7] overflow-hidden bg-[#F2ECE1] shrink-0">
                                        @if($primaryImg)
                                            <img src="{{ $primaryImg }}" alt="{{ $auction->product->title ?? '' }}" class="w-full h-full object-cover">
                                        @else
                                            <div class="w-full h-full flex items-center justify-center text-[#8C8477] font-serif text-xs">No img</div>
                                        @endif
                                    </div>
                                    <div class="min-w-0">
                                        <p class="font-medium text-[#2C2E2A] truncate max-w-[200px]" title="{{ $auction->product->title ?? 'N/A' }}">
                                            {{ $auction->product->title ?? 'Sản phẩm không xác định' }}
                                        </p>
                                        <p class="text-[10px] text-[#8C8477] font-mono">
                                            Code: {{ $auction->product->product_code ?? 'N/A' }}
                                        </p>
                                    </div>
                                </div>
                            </td>

                            <!-- Seller -->
                            <td class="py-3 px-4">
                                <p class="font-medium text-[#2C2E2A]">{{ $auction->seller->full_name ?? 'N/A' }}</p>
                                <p class="text-[10px] text-[#8C8477]">{{ $auction->seller->email ?? '' }}</p>
                            </td>

                            <!-- Pricing -->
                            <td class="py-3 px-4 text-right">
                                <div class="font-mono text-[#8C8477] text-[11px]">
                                    KĐ: {{ number_format((float) $auction->starting_price) }} đ
                                </div>
                                <div class="font-mono font-bold text-[#2C2E2A] text-xs">
                                    {{ (float) $auction->current_highest_bid > 0 ? number_format((float) $auction->current_highest_bid) . ' đ' : 'Chưa có bid' }}
                                </div>
                                @if((float) $auction->reserve_price > 0)
                                    <div class="text-[10px] text-[#84664C]">
                                        Sàn: {{ number_format((float) $auction->reserve_price) }} đ
                                    </div>
                                @endif
                            </td>

                            <!-- Bid count / Watch count -->
                            <td class="py-3 px-4 text-center">
                                <span class="inline-flex items-center px-2 py-0.5 rounded text-[11px] font-semibold bg-[#EAF2ED] text-[#2D5A3C]">
                                    {{ $auction->bid_count }} bids
                                </span>
                                <div class="text-[10px] text-[#8C8477] mt-0.5">
                                    {{ $auction->watch_count }} quan tâm
                                </div>
                            </td>

                            <!-- Dates & Anti-sniping -->
                            <td class="py-3 px-4 text-[11px]">
                                <div>
                                    <span class="text-[#8C8477]">Bắt đầu:</span> {{ $auction->auction_starts_at ? $auction->auction_starts_at->format('d/m/Y H:i') : 'N/A' }}
                                </div>
                                <div>
                                    <span class="text-[#8C8477]">Kết thúc:</span> {{ $auction->auction_ends_at ? $auction->auction_ends_at->format('d/m/Y H:i') : 'N/A' }}
                                </div>
                                @if($auction->extended_count > 0)
                                    <span class="inline-block mt-0.5 px-1.5 py-0.5 rounded text-[9px] font-bold bg-[#F8E8E8] text-[#8B3A3A] uppercase tracking-wider">
                                        Gia hạn +{{ $auction->extended_count * 2 }}p (Anti-Sniping x{{ $auction->extended_count }})
                                    </span>
                                @endif
                            </td>

                            <!-- Status Badge -->
                            <td class="py-3 px-4 text-center">
                                @php
                                    $st = $auction->status instanceof \App\Enums\AuctionStatus ? $auction->status : \App\Enums\AuctionStatus::tryFrom($auction->status);
                                    $badgeClass = match($st) {
                                        \App\Enums\AuctionStatus::LIVE => 'bg-[#2D5A3C] text-white',
                                        \App\Enums\AuctionStatus::SCHEDULED => 'bg-[#3B6E8C] text-white',
                                        \App\Enums\AuctionStatus::COMPLETED => 'bg-[#84664C] text-white',
                                        \App\Enums\AuctionStatus::ENDED_UNSOLD => 'bg-[#6E675F] text-white',
                                        \App\Enums\AuctionStatus::WINNER_DEFAULTED => 'bg-[#C85A32] text-white',
                                        \App\Enums\AuctionStatus::CANCELLED => 'bg-[#8B3A3A] text-white',
                                        default => 'bg-gray-500 text-white',
                                    };
                                @endphp
                                <span class="inline-block px-2 py-1 rounded text-[10px] font-semibold uppercase tracking-wider {{ $badgeClass }}">
                                    {{ $st?->value ?? $auction->status }}
                                </span>
                            </td>

                            <!-- Action -->
                            <td class="py-3 px-4 text-center">
                                <a href="{{ route('admin.auctions.show', $auction->id) }}"
                                   class="inline-block px-3 py-1 text-xs font-semibold rounded bg-[#F2ECE1] text-[#2C2E2A] hover:bg-[#E5DDCF] border border-[#C5BCAB] transition-colors">
                                    Chi tiết &rsaquo;
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="8" class="py-8 text-center text-[#8C8477]">
                                <p class="text-sm">Không tìm thấy phiên đấu giá nào phù hợp với bộ lọc hiện tại.</p>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($auctions->hasPages())
            <div class="p-4 border-t border-[#E0D7C7] bg-[#FAF7F2]">
                {{ $auctions->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
