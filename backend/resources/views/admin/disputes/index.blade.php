@extends('layouts.admin')

@section('title', 'Hàng đợi Quản lý Khiếu nại - Retro Market Admin')

@section('content')
<div class="space-y-6">
    <!-- Breadcrumb & Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <nav class="flex items-center space-x-2 text-xs text-[#8C8477] mb-1">
                <a href="{{ route('admin.dashboard') }}" class="hover:underline">Quản trị</a>
                <span>&rsaquo;</span>
                <span class="text-[#2C2E2A] font-medium">Tranh chấp & Khiếu nại</span>
            </nav>
            <h1 class="text-2xl font-serif font-bold text-[#2C2E2A]">Hàng đợi Quản lý Khiếu nại và Tranh chấp</h1>
            <p class="text-xs text-[#6E675F]">Giải quyết khiếu nại trả hàng/hoàn tiền, đóng băng Escrow tự động và thực thi phán quyết tài chính.</p>
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
            <span class="text-[11px] font-semibold text-[#8C8477] uppercase tracking-wider">Tổng số khiếu nại</span>
            <p class="text-2xl font-bold font-serif text-[#2C2E2A] mt-1">{{ number_format($stats['total']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#8B3A3A] uppercase tracking-wider">Đang mở (Open)</span>
            <p class="text-2xl font-bold font-serif text-[#8B3A3A] mt-1">{{ number_format($stats['open']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#C85A32] uppercase tracking-wider">Chờ bổ sung bằng chứng</span>
            <p class="text-2xl font-bold font-serif text-[#C85A32] mt-1">{{ number_format($stats['need_more_info']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#2D5A3C] uppercase tracking-wider">Đã phân xử xong</span>
            <p class="text-2xl font-bold font-serif text-[#2D5A3C] mt-1">{{ number_format($stats['resolved']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm col-span-2 md:col-span-1">
            <span class="text-[11px] font-semibold text-[#84664C] uppercase tracking-wider">Tiền Escrow đóng băng</span>
            <p class="text-xl font-bold font-mono text-[#84664C] mt-1 tabular-nums">{{ number_format($stats['frozen_amount']) }} đ</p>
        </div>
    </div>

    <!-- Filter & Search Toolbar -->
    <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
        <form method="GET" action="{{ route('admin.disputes.index') }}" class="flex flex-col md:flex-row gap-3">
            <div class="flex-1 relative">
                <input type="text" name="search" value="{{ request('search') }}"
                       placeholder="Tìm theo mã khiếu nại (DSP-...), mã đơn hàng (ORD-...), người mua, người bán..."
                       class="w-full pl-9 pr-3 py-2 text-xs border border-[#C5BCAB] rounded-md bg-[#FAF7F2] text-[#2C2E2A] placeholder-[#8C8477] focus:outline-none focus:ring-1 focus:ring-[#2D5A3C]">
                <svg class="w-4 h-4 absolute left-3 top-2.5 text-[#8C8477]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                </svg>
            </div>
            <div class="flex items-center gap-2">
                <select name="status" class="py-2 px-3 text-xs border border-[#C5BCAB] rounded-md bg-[#FAF7F2] text-[#2C2E2A] focus:outline-none focus:ring-1 focus:ring-[#2D5A3C]">
                    <option value="">-- Tất cả trạng thái --</option>
                    @foreach(\App\Enums\DisputeStatus::cases() as $st)
                        @if($st->value !== 'NONE')
                            <option value="{{ $st->value }}" {{ request('status') === $st->value ? 'selected' : '' }}>
                                {{ $st->value }} - {{ $st->label() }}
                            </option>
                        @endif
                    @endforeach
                </select>

                <select name="reason_category" class="py-2 px-3 text-xs border border-[#C5BCAB] rounded-md bg-[#FAF7F2] text-[#2C2E2A] focus:outline-none focus:ring-1 focus:ring-[#2D5A3C]">
                    <option value="">-- Tất cả lý do --</option>
                    <option value="ITEM_NOT_AS_DESCRIBED" {{ request('reason_category') === 'ITEM_NOT_AS_DESCRIBED' ? 'selected' : '' }}>Hàng không đúng mô tả</option>
                    <option value="DEFECT_NOT_DISCLOSED" {{ request('reason_category') === 'DEFECT_NOT_DISCLOSED' ? 'selected' : '' }}>Có lỗi chưa khai báo</option>
                    <option value="COUNTERFEIT_SUSPECTED" {{ request('reason_category') === 'COUNTERFEIT_SUSPECTED' ? 'selected' : '' }}>Nghi vấn hàng giả/nhái</option>
                    <option value="PARCEL_EMPTY_OR_WRONG" {{ request('reason_category') === 'PARCEL_EMPTY_OR_WRONG' ? 'selected' : '' }}>Giao sai/thiếu hàng</option>
                    <option value="OTHER" {{ request('reason_category') === 'OTHER' ? 'selected' : '' }}>Lý do khác</option>
                </select>

                <button type="submit" class="px-4 py-2 text-xs font-semibold bg-[#2D5A3C] text-white rounded-md hover:bg-[#23462F] transition-colors">
                    Lọc
                </button>
                @if(request()->hasAny(['search', 'status', 'reason_category']))
                    <a href="{{ route('admin.disputes.index') }}" class="px-3 py-2 text-xs font-medium text-[#6E675F] hover:underline">
                        Xóa
                    </a>
                @endif
            </div>
        </form>
    </div>

    <!-- Disputes Table -->
    <div class="bg-white rounded-lg border border-[#E0D7C7] shadow-sm overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse text-xs">
                <thead>
                    <tr class="bg-[#F8F5EE] border-b border-[#E0D7C7] text-[#6E675F] uppercase tracking-wider text-[11px]">
                        <th class="py-3 px-4 font-semibold">Mã khiếu nại</th>
                        <th class="py-3 px-4 font-semibold">Đơn hàng</th>
                        <th class="py-3 px-4 font-semibold">Người khiếu nại (Buyer)</th>
                        <th class="py-3 px-4 font-semibold">Người bị khiếu nại (Seller)</th>
                        <th class="py-3 px-4 font-semibold">Lý do</th>
                        <th class="py-3 px-4 font-semibold text-right">Escrow đóng băng</th>
                        <th class="py-3 px-4 font-semibold text-center">Trạng thái</th>
                        <th class="py-3 px-4 font-semibold text-center">Thao tác</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#E0D7C7]">
                    @forelse($disputes as $dispute)
                        <tr class="hover:bg-[#FAF7F2] transition-colors">
                            <td class="py-3 px-4 font-mono font-bold text-[#2C2E2A]">
                                <a href="{{ route('admin.disputes.show', $dispute->id) }}" class="text-[#2D5A3C] hover:underline">
                                    {{ $dispute->dispute_code }}
                                </a>
                                <div class="text-[10px] text-[#8C8477] font-normal">
                                    {{ $dispute->created_at->format('d/m/Y H:i') }}
                                </div>
                            </td>
                            <td class="py-3 px-4 font-mono">
                                @if($dispute->order)
                                    <a href="{{ route('admin.orders.show', $dispute->order_id) }}" class="font-bold text-[#2D5A3C] hover:underline">
                                        #{{ $dispute->order->order_code }}
                                    </a>
                                @else
                                    #{{ $dispute->order_id }}
                                @endif
                            </td>
                            <td class="py-3 px-4">
                                <p class="font-medium text-[#2C2E2A]">{{ $dispute->buyer->full_name ?? 'N/A' }}</p>
                                <p class="text-[10px] text-[#8C8477]">{{ $dispute->buyer->email ?? '' }}</p>
                            </td>
                            <td class="py-3 px-4">
                                <p class="font-medium text-[#2C2E2A]">{{ $dispute->seller->full_name ?? 'N/A' }}</p>
                                <p class="text-[10px] text-[#8C8477]">{{ $dispute->seller->email ?? '' }}</p>
                            </td>
                            <td class="py-3 px-4">
                                <span class="font-semibold text-[#84664C]">{{ $dispute->reason_category }}</span>
                                <p class="text-[10px] text-[#6E675F] truncate max-w-[180px]" title="{{ $dispute->buyer_description }}">
                                    {{ $dispute->buyer_description }}
                                </p>
                            </td>
                            <td class="py-3 px-4 text-right font-mono font-bold text-[#8B3A3A] tabular-nums text-sm">
                                {{ number_format((float) ($dispute->order?->item_subtotal ?? 0)) }} đ
                            </td>
                            <td class="py-3 px-4 text-center">
                                @php
                                    $st = $dispute->status instanceof \App\Enums\DisputeStatus ? $dispute->status : \App\Enums\DisputeStatus::tryFrom($dispute->status);
                                    $badge = match($st) {
                                        \App\Enums\DisputeStatus::OPEN => 'bg-[#8B3A3A] text-white animate-pulse',
                                        \App\Enums\DisputeStatus::NEED_MORE_INFO => 'bg-[#C85A32] text-white',
                                        \App\Enums\DisputeStatus::RESOLVED => 'bg-[#2D5A3C] text-white',
                                        default => 'bg-gray-500 text-white',
                                    };
                                @endphp
                                <span class="inline-block px-2 py-0.5 rounded text-[10px] font-semibold uppercase tracking-wider {{ $badge }}">
                                    {{ $st?->value ?? $dispute->status }}
                                </span>
                            </td>
                            <td class="py-3 px-4 text-center">
                                <a href="{{ route('admin.disputes.show', $dispute->id) }}"
                                   class="inline-block px-3 py-1 text-xs font-semibold rounded bg-[#F2ECE1] text-[#2C2E2A] hover:bg-[#E5DDCF] border border-[#C5BCAB] transition-colors">
                                    Case Room &rsaquo;
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="8" class="py-8 text-center text-[#8C8477]">
                                <p class="text-sm">Không tìm thấy hồ sơ khiếu nại nào.</p>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($disputes->hasPages())
            <div class="p-4 border-t border-[#E0D7C7] bg-[#FAF7F2]">
                {{ $disputes->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
