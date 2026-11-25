@extends('layouts.admin')

@section('title', 'Phiên đấu giá #' . $auction->auction_code . ' - Retro Market Admin')

@section('content')
@php
    use App\Support\AdminPermission;
    $user = auth('web')->user();
    $st = $auction->status instanceof \App\Enums\AuctionStatus ? $auction->status : \App\Enums\AuctionStatus::tryFrom($auction->status);
    $canCancel = AdminPermission::can($user, 'auctions.cancel') && in_array($st, [\App\Enums\AuctionStatus::SCHEDULED, \App\Enums\AuctionStatus::LIVE], true);
@endphp

<div class="space-y-6">
    <!-- Breadcrumb & Nav -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <nav class="flex items-center space-x-2 text-xs text-[#8C8477] mb-1">
                <a href="{{ route('admin.dashboard') }}" class="hover:underline">Quản trị</a>
                <span>&rsaquo;</span>
                <a href="{{ route('admin.auctions.index') }}" class="hover:underline">Quản lý Đấu giá</a>
                <span>&rsaquo;</span>
                <span class="text-[#2C2E2A] font-medium font-mono">#{{ $auction->auction_code }}</span>
            </nav>
            <div class="flex items-center space-x-3">
                <h1 class="text-2xl font-serif font-bold text-[#2C2E2A]">Chi tiết Phiên Đấu giá</h1>
                @php
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
                <span class="px-2.5 py-1 rounded text-xs font-semibold uppercase tracking-wider {{ $badgeClass }}">
                    {{ $st?->value ?? $auction->status }} - {{ $st?->label() }}
                </span>
            </div>
        </div>
        <div class="flex items-center space-x-2">
            <a href="{{ route('admin.auctions.index') }}"
               class="px-3 py-1.5 text-xs font-medium rounded border border-[#C5BCAB] bg-white text-[#2C2E2A] hover:bg-[#FAF7F2] transition-colors">
                &larr; Quay lại danh sách
            </a>
            @if($canCancel)
                <button type="button" onclick="document.getElementById('cancel-modal').classList.remove('hidden')"
                        class="px-3 py-1.5 text-xs font-semibold rounded bg-[#8B3A3A] text-white hover:bg-[#6D2E2E] transition-colors">
                    Hủy phiên đấu giá
                </button>
            @endif
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

    <!-- TICKET-STUB MOTIF CARD (Warm Editorial Archive) -->
    <div class="bg-[#FBF8F3] border-2 border-[#C5BCAB] rounded-xl shadow-md overflow-hidden relative">
        <!-- Ticket Header Perforated Bar -->
        <div class="bg-[#2C2E2A] text-[#E8E2D9] px-6 py-4 flex flex-col sm:flex-row sm:items-center sm:justify-between border-b-2 border-dashed border-[#C5A66B]">
            <div class="flex items-center space-x-3">
                <span class="w-8 h-8 rounded bg-[#C5A66B] text-[#2C2E2A] font-serif font-black flex items-center justify-center text-sm">
                    TKT
                </span>
                <div>
                    <span class="text-[10px] uppercase tracking-widest text-[#C5A66B] font-bold">IZITHRIFT OFFICIAL AUCTION VOUCHER</span>
                    <h2 class="text-lg font-serif font-bold text-white font-mono">LOT #{{ $auction->auction_code }}</h2>
                </div>
            </div>
            <div class="mt-2 sm:mt-0 text-right">
                <p class="text-xs text-[#BFB6A8]">Phiên: <strong class="text-white">{{ $auction->session->title ?? 'Phiên tự do' }}</strong></p>
                <p class="text-[11px] text-[#C5A66B]">Khởi tạo: {{ $auction->created_at->format('d/m/Y H:i:s') }}</p>
            </div>
        </div>

        <!-- Ticket Body (2-column layout) -->
        <div class="p-6 grid grid-cols-1 lg:grid-cols-3 gap-6">
            <!-- Left: Product Snapshot & Rules -->
            <div class="lg:col-span-2 space-y-6">
                <!-- Product Card -->
                <div class="bg-white p-5 rounded-lg border border-[#E0D7C7] shadow-sm flex flex-col sm:flex-row gap-5">
                    @php
                        $primaryImg = $auction->product?->primaryImage?->image_url;
                    @endphp
                    <div class="w-28 h-28 rounded-lg border border-[#C5BCAB] overflow-hidden bg-[#F2ECE1] shrink-0">
                        @if($primaryImg)
                            <img src="{{ $primaryImg }}" alt="{{ $auction->product->title ?? '' }}" class="w-full h-full object-cover">
                        @else
                            <div class="w-full h-full flex items-center justify-center text-[#8C8477] font-serif text-sm">No Image</div>
                        @endif
                    </div>
                    <div class="flex-1 space-y-2">
                        <div class="flex items-center justify-between">
                            <span class="text-[10px] font-bold px-2 py-0.5 rounded bg-[#F2ECE1] text-[#84664C] uppercase tracking-wider">
                                {{ $auction->product->category->name ?? 'Không phân loại' }}
                            </span>
                            <span class="text-xs font-mono text-[#8C8477]">
                                ID: #{{ $auction->product_id }}
                            </span>
                        </div>
                        <h3 class="text-base font-serif font-bold text-[#2C2E2A]">
                            {{ $auction->product->title ?? 'Sản phẩm không xác định' }}
                        </h3>
                        <p class="text-xs text-[#6E675F] line-clamp-2">
                            {{ $auction->product->description ?? 'Không có mô tả sản phẩm.' }}
                        </p>
                        <div class="pt-1 flex items-center space-x-4 text-xs text-[#8C8477]">
                            <span>Tình trạng: <strong class="text-[#2C2E2A]">{{ $auction->product->condition ?? 'N/A' }}</strong></span>
                            <span>Người bán: <strong class="text-[#2C2E2A]">{{ $auction->seller->full_name ?? 'N/A' }}</strong></span>
                        </div>
                    </div>
                </div>

                <!-- Financial & Rules Matrix -->
                <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 bg-white p-4 rounded-lg border border-[#E0D7C7]">
                    <div>
                        <span class="text-[10px] uppercase text-[#8C8477] font-semibold">Giá khởi điểm</span>
                        <p class="text-sm font-mono font-bold text-[#2C2E2A] mt-0.5">
                            {{ number_format((float) $auction->starting_price) }} đ
                        </p>
                    </div>
                    <div>
                        <span class="text-[10px] uppercase text-[#8C8477] font-semibold">Bước giá tối thiểu</span>
                        <p class="text-sm font-mono font-bold text-[#2C2E2A] mt-0.5">
                            +{{ number_format((float) $auction->min_bid_increment) }} đ
                        </p>
                    </div>
                    <div>
                        <span class="text-[10px] uppercase text-[#8C8477] font-semibold">Giá sàn (Reserve)</span>
                        <p class="text-sm font-mono font-bold text-[#84664C] mt-0.5">
                            @if((float) $auction->reserve_price > 0)
                                {{ number_format((float) $auction->reserve_price) }} đ
                                @if((float) $auction->current_highest_bid >= (float) $auction->reserve_price)
                                    <span class="text-[9px] text-[#2D5A3C] block font-sans font-semibold">&#10003; Đã đạt sàn</span>
                                @else
                                    <span class="text-[9px] text-[#8B3A3A] block font-sans font-semibold">&#10007; Chưa đạt sàn</span>
                                @endif
                            @else
                                Không đặt
                            @endif
                        </p>
                    </div>
                    <div>
                        <span class="text-[10px] uppercase text-[#2D5A3C] font-semibold">Giá hiện tại</span>
                        <p class="text-base font-mono font-black text-[#2D5A3C] mt-0.5">
                            {{ (float) $auction->current_highest_bid > 0 ? number_format((float) $auction->current_highest_bid) . ' đ' : 'Chưa có' }}
                        </p>
                    </div>
                </div>

                <!-- Anti-Sniping & Winner Deadline Boxes -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <!-- Anti-Sniping (BR-AU-04) -->
                    <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] space-y-2">
                        <div class="flex items-center justify-between">
                            <span class="text-xs font-serif font-bold text-[#2C2E2A]">Cơ chế Chống Bắn Tỉa (BR-AU-04)</span>
                            @if($auction->extended_count > 0)
                                <span class="px-2 py-0.5 rounded text-[10px] font-bold bg-[#F8E8E8] text-[#8B3A3A]">
                                    Đã kích hoạt x{{ $auction->extended_count }}
                                </span>
                            @else
                                <span class="px-2 py-0.5 rounded text-[10px] font-semibold bg-[#EAF2ED] text-[#2D5A3C]">
                                    Chưa kích hoạt
                                </span>
                            @endif
                        </div>
                        <p class="text-xs text-[#6E675F]">
                            Mỗi lượt đặt giá trong <strong>2 phút cuối</strong> sẽ tự động kéo dài phiên thêm <strong>2 phút</strong> để đảm bảo công bằng.
                        </p>
                        <div class="text-[11px] text-[#8C8477] pt-1">
                            <p>Số lần gia hạn: <strong class="text-[#2C2E2A]">{{ $auction->extended_count }} lần (+{{ $auction->extended_count * 2 }} phút)</strong></p>
                            @if($auction->last_extended_at)
                                <p>Lần gia hạn gần nhất: <span class="font-mono">{{ $auction->last_extended_at->format('d/m/Y H:i:s') }}</span></p>
                            @endif
                        </div>
                    </div>

                    <!-- 30-Minute Winner Payment Deadline (BR-AU-07 / DEC-02) -->
                    <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] space-y-2">
                        <span class="text-xs font-serif font-bold text-[#2C2E2A]">Hạn Thanh toán Người thắng (BR-AU-07 / DEC-02)</span>
                        <p class="text-xs text-[#6E675F]">
                            Người thắng đấu giá có đúng <strong>30 phút</strong> để hoàn tất thanh toán. Quá hạn hệ thống sẽ hủy đơn và chuyển trạng thái <code>WINNER_DEFAULTED</code>.
                        </p>
                        @if($auction->winner)
                            <div class="text-[11px] pt-1 space-y-1">
                                <p>Người thắng: <strong class="text-[#2C2E2A]">{{ $auction->winner->full_name }}</strong> ({{ $auction->winner->email }})</p>
                                @if($auction->order)
                                    <p>Đơn hàng liên kết:
                                        <a href="{{ route('admin.orders.show', $auction->order->id) }}" class="text-[#2D5A3C] font-mono font-semibold hover:underline">
                                            #{{ $auction->order->order_code }}
                                        </a>
                                        <span class="text-[10px] text-[#8C8477]">({{ $auction->order->order_status->value }})</span>
                                    </p>
                                @endif
                                @if($st === \App\Enums\AuctionStatus::WINNER_DEFAULTED)
                                    <p class="text-[#C85A32] font-semibold text-xs">
                                        &bull; Người thắng đã quá hạn thanh toán 30 phút. Phiên được đánh dấu WINNER_DEFAULTED.
                                    </p>
                                @endif
                            </div>
                        @else
                            <p class="text-[11px] text-[#8C8477] italic pt-1">Chưa có người thắng được xác định.</p>
                        @endif
                    </div>
                </div>

                <!-- Cancellation Info (If Cancelled) -->
                @if($st === \App\Enums\AuctionStatus::CANCELLED)
                    <div class="bg-[#FBEAEB] p-4 rounded-lg border border-[#8B3A3A] text-xs text-[#8B3A3A] space-y-1">
                        <div class="flex items-center space-x-2 font-bold uppercase tracking-wider">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
                            </svg>
                            <span>Thông tin Hủy phiên đấu giá</span>
                        </div>
                        <p>Thời điểm hủy: <span class="font-mono">{{ $auction->closed_at ? $auction->closed_at->format('d/m/Y H:i:s') : 'N/A' }}</span></p>
                        <p>Lý do: <strong>{{ $auction->cancel_reason ?? 'Không có lý do ghi nhận.' }}</strong></p>
                    </div>
                @endif
            </div>

            <!-- Right Column: Ticket Stamp & Status Summary -->
            <div class="space-y-6">
                <!-- Ticket Right Stamp Bar -->
                <div class="bg-white p-5 rounded-lg border border-[#E0D7C7] shadow-sm space-y-4">
                    <div class="border-b border-[#E0D7C7] pb-3">
                        <span class="text-[10px] uppercase font-bold text-[#8C8477] tracking-wider">Trạng thái Bidding</span>
                        <div class="mt-1 flex items-center justify-between">
                            <span class="text-sm font-semibold text-[#2C2E2A]">Lượt đặt giá</span>
                            <span class="text-lg font-bold font-mono text-[#2D5A3C]">{{ $auction->bid_count }}</span>
                        </div>
                        <div class="mt-1 flex items-center justify-between">
                            <span class="text-sm font-semibold text-[#2C2E2A]">Người dẫn đầu</span>
                            <span class="text-xs font-semibold text-[#2C2E2A]">
                                {{ $auction->leadingBidder->full_name ?? 'Chưa có' }}
                            </span>
                        </div>
                    </div>

                    <!-- Time window -->
                    <div class="space-y-2 text-xs">
                        <div>
                            <span class="text-[#8C8477] block text-[10px] uppercase">Thời gian bắt đầu:</span>
                            <span class="font-mono font-medium text-[#2C2E2A]">{{ $auction->auction_starts_at ? $auction->auction_starts_at->format('d/m/Y H:i:s') : 'N/A' }}</span>
                        </div>
                        <div>
                            <span class="text-[#8C8477] block text-[10px] uppercase">Thời gian kết thúc (Dự kiến):</span>
                            <span class="font-mono font-medium text-[#2C2E2A]">{{ $auction->auction_ends_at ? $auction->auction_ends_at->format('d/m/Y H:i:s') : 'N/A' }}</span>
                        </div>
                        @if($auction->closed_at)
                            <div>
                                <span class="text-[#8C8477] block text-[10px] uppercase">Thời điểm đóng phiên:</span>
                                <span class="font-mono font-medium text-[#2C2E2A]">{{ $auction->closed_at->format('d/m/Y H:i:s') }}</span>
                            </div>
                        @endif
                    </div>

                    <!-- Seller Card -->
                    <div class="border-t border-[#E0D7C7] pt-3 text-xs space-y-1">
                        <span class="text-[10px] uppercase font-bold text-[#8C8477] tracking-wider">Chủ sở hữu (Người bán)</span>
                        <p class="font-bold text-[#2C2E2A]">{{ $auction->seller->full_name ?? 'N/A' }}</p>
                        <p class="text-[#6E675F]">{{ $auction->seller->email ?? '' }}</p>
                        <p class="text-[#8C8477]">SĐT: {{ $auction->seller->phone_number ?? 'Chưa cập nhật' }}</p>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- IMMUTABLE BID HISTORY TRAIL (AC-P803-01 / ImmutableLedgerRecord) -->
    <div class="bg-white rounded-lg border border-[#E0D7C7] shadow-sm overflow-hidden">
        <div class="px-5 py-4 border-b border-[#E0D7C7] flex items-center justify-between bg-[#F8F5EE]">
            <div class="flex items-center space-x-2">
                <svg class="w-4 h-4 text-[#2D5A3C]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
                </svg>
                <h3 class="text-sm font-serif font-bold text-[#2C2E2A]">Nhật ký Đặt giá Bất biến (Immutable Bid Trail)</h3>
            </div>
            <span class="text-[11px] text-[#8C8477]">
                Ghi nhận {{ $bids->count() }} lượt bid (Bảo vệ tính toàn vẹn tài chính)
            </span>
        </div>

        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse text-xs">
                <thead>
                    <tr class="bg-[#FAF7F2] border-b border-[#E0D7C7] text-[#6E675F] uppercase tracking-wider text-[11px]">
                        <th class="py-2.5 px-4 font-semibold">STT / ID</th>
                        <th class="py-2.5 px-4 font-semibold">Thời điểm đặt giá</th>
                        <th class="py-2.5 px-4 font-semibold">Người đặt giá (Bidder)</th>
                        <th class="py-2.5 px-4 font-semibold text-right">Giá đặt (Bid Amount)</th>
                        <th class="py-2.5 px-4 font-semibold text-right">Giá trước đó</th>
                        <th class="py-2.5 px-4 font-semibold text-center">Kích hoạt Anti-Sniping</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#E0D7C7]">
                    @forelse($bids as $index => $bid)
                        <tr class="hover:bg-[#FAF7F2] transition-colors {{ $loop->first ? 'bg-[#EAF2ED]/30 font-medium' : '' }}">
                            <td class="py-2.5 px-4 font-mono text-[#8C8477]">
                                #{{ $bid->id }}
                                @if($loop->first)
                                    <span class="ml-1 text-[9px] bg-[#2D5A3C] text-white px-1.5 py-0.2 rounded font-sans font-bold">Cao nhất</span>
                                @endif
                            </td>
                            <td class="py-2.5 px-4 font-mono text-[#2C2E2A]">
                                {{ $bid->created_at->format('d/m/Y H:i:s') }}
                            </td>
                            <td class="py-2.5 px-4">
                                <span class="font-medium text-[#2C2E2A]">{{ $bid->bidder->full_name ?? 'N/A' }}</span>
                                <span class="text-[10px] text-[#8C8477] block">{{ $bid->bidder->email ?? '' }}</span>
                            </td>
                            <td class="py-2.5 px-4 text-right font-mono font-bold text-[#2C2E2A] text-xs">
                                {{ number_format((float) $bid->bid_amount) }} đ
                            </td>
                            <td class="py-2.5 px-4 text-right font-mono text-[#8C8477]">
                                {{ (float) $bid->previous_highest_bid > 0 ? number_format((float) $bid->previous_highest_bid) . ' đ' : 'Khởi điểm' }}
                            </td>
                            <td class="py-2.5 px-4 text-center">
                                @if($bid->triggered_anti_sniping)
                                    <span class="inline-block px-2 py-0.5 rounded text-[10px] font-bold bg-[#F8E8E8] text-[#8B3A3A]">
                                        Có (+2 phút)
                                    </span>
                                @else
                                    <span class="inline-block px-2 py-0.5 rounded text-[10px] font-medium bg-[#F2ECE1] text-[#8C8477]">
                                        Không
                                    </span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="py-6 text-center text-[#8C8477] italic">
                                Phiên đấu giá này chưa có lượt đặt giá nào.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- CANCEL AUCTION MODAL -->
@if($canCancel)
<div id="cancel-modal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 hidden">
    <div class="bg-white rounded-xl shadow-xl max-w-md w-full border border-[#C5BCAB] overflow-hidden">
        <form method="POST" action="{{ route('admin.auctions.cancel', $auction->id) }}">
            @csrf
            <div class="bg-[#8B3A3A] px-6 py-4 text-white flex items-center justify-between">
                <h3 class="font-serif font-bold text-base">Hủy Phiên Đấu Giá #{{ $auction->auction_code }}</h3>
                <button type="button" onclick="document.getElementById('cancel-modal').classList.add('hidden')" class="text-white/80 hover:text-white">&times;</button>
            </div>
            <div class="p-6 space-y-4 text-xs">
                <p class="text-[#6E675F]">
                    Hành động này sẽ hủy phiên đấu giá hiện tại, hoàn trả trạng thái sản phẩm về <strong>APPROVED</strong> để người bán có thể thao tác lại, và ghi nhận nhật ký kiểm toán không thể xóa.
                </p>
                <div>
                    <label class="block font-semibold text-[#2C2E2A] mb-1">Lý do hủy phiên <span class="text-[#8B3A3A]">*</span></label>
                    <textarea name="reason" rows="3" required placeholder="Nhập lý do can thiệp hành chính hủy phiên đấu giá (ít nhất 5 ký tự)..."
                              class="w-full p-2 border border-[#C5BCAB] rounded-md text-xs focus:ring-1 focus:ring-[#8B3A3A] focus:outline-none"></textarea>
                </div>
            </div>
            <div class="px-6 py-3 bg-[#FAF7F2] border-t border-[#E0D7C7] flex justify-end space-x-2">
                <button type="button" onclick="document.getElementById('cancel-modal').classList.add('hidden')"
                        class="px-4 py-2 text-xs font-semibold rounded border border-[#C5BCAB] bg-white text-[#2C2E2A] hover:bg-[#F2ECE1]">
                    Hủy bỏ
                </button>
                <button type="submit"
                        class="px-4 py-2 text-xs font-semibold rounded bg-[#8B3A3A] text-white hover:bg-[#6D2E2E]">
                    Xác nhận hủy phiên
                </button>
            </div>
        </form>
    </div>
</div>
@endif
@endsection
