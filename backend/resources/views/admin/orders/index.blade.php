@extends('layouts.admin')

@section('title', 'Quản lý Đơn hàng & Escrow - Retro Market Admin')

@section('content')
<div class="space-y-6">
    <!-- Breadcrumb & Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <nav class="flex items-center space-x-2 text-xs text-[#8C8477] mb-1">
                <a href="{{ route('admin.dashboard') }}" class="hover:underline">Quản trị</a>
                <span>&rsaquo;</span>
                <span class="text-[#2C2E2A] font-medium">Đơn hàng & Escrow</span>
            </nav>
            <h1 class="text-2xl font-serif font-bold text-[#2C2E2A]">Quản lý Đơn hàng và Escrow</h1>
            <p class="text-xs text-[#6E675F]">Giám sát 4 máy trạng thái độc lập (Đơn hàng, Thanh toán, Ký quỹ Escrow, Khiếu nại) và bảo vệ giao dịch.</p>
        </div>
    </div>

    <!-- Metrics Cards -->
    <div class="grid grid-cols-2 md:grid-cols-5 gap-3">
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#8C8477] uppercase tracking-wider">Tổng đơn hàng</span>
            <p class="text-2xl font-bold font-serif text-[#2C2E2A] mt-1">{{ number_format($stats['total']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#84664C] uppercase tracking-wider">Escrow đang giữ</span>
            <p class="text-2xl font-bold font-serif text-[#84664C] mt-1">{{ number_format($stats['escrow_held']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#8B3A3A] uppercase tracking-wider">Tranh chấp mở</span>
            <p class="text-2xl font-bold font-serif text-[#8B3A3A] mt-1">{{ number_format($stats['dispute_open']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#2D5A3C] uppercase tracking-wider">Đã hoàn tất</span>
            <p class="text-2xl font-bold font-serif text-[#2D5A3C] mt-1">{{ number_format($stats['completed']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm col-span-2 md:col-span-1">
            <span class="text-[11px] font-semibold text-[#C5A66B] uppercase tracking-wider">Tổng GMV hoàn tất/paid</span>
            <p class="text-xl font-bold font-mono text-[#2C2E2A] mt-1">{{ number_format((float) $stats['gross_volume']) }} đ</p>
        </div>
    </div>

    <!-- Filter & Search Toolbar (4 Independent State Machines) -->
    <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm space-y-3">
        <form method="GET" action="{{ route('admin.orders.index') }}" class="space-y-3">
            <!-- Search input -->
            <div class="flex-1 relative">
                <input type="text" name="search" value="{{ request('search') }}"
                       placeholder="Tìm theo mã đơn hàng (VD: ORD-...), email/tên người mua, email/tên người bán..."
                       class="w-full pl-9 pr-3 py-2 text-xs border border-[#C5BCAB] rounded-md bg-[#FAF7F2] text-[#2C2E2A] placeholder-[#8C8477] focus:outline-none focus:ring-1 focus:ring-[#2D5A3C]">
                <svg class="w-4 h-4 absolute left-3 top-2.5 text-[#8C8477]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                </svg>
            </div>

            <!-- 4 State Machine Selects -->
            <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-5 gap-2">
                <!-- Order Status -->
                <div>
                    <label class="block text-[10px] uppercase font-bold text-[#8C8477] mb-1">1. Trạng thái Đơn</label>
                    <select name="order_status" class="w-full py-1.5 px-2 text-xs border border-[#C5BCAB] rounded-md bg-[#FAF7F2] text-[#2C2E2A] focus:outline-none focus:ring-1 focus:ring-[#2D5A3C]">
                        <option value="">-- Tất cả Order --</option>
                        @foreach(\App\Enums\OrderStatus::cases() as $st)
                            <option value="{{ $st->value }}" {{ request('order_status') === $st->value ? 'selected' : '' }}>
                                {{ $st->value }} ({{ $st->label() }})
                            </option>
                        @endforeach
                    </select>
                </div>

                <!-- Payment Status -->
                <div>
                    <label class="block text-[10px] uppercase font-bold text-[#8C8477] mb-1">2. Trạng thái Thanh toán</label>
                    <select name="payment_status" class="w-full py-1.5 px-2 text-xs border border-[#C5BCAB] rounded-md bg-[#FAF7F2] text-[#2C2E2A] focus:outline-none focus:ring-1 focus:ring-[#2D5A3C]">
                        <option value="">-- Tất cả Payment --</option>
                        @foreach(\App\Enums\PaymentStatus::cases() as $st)
                            <option value="{{ $st->value }}" {{ request('payment_status') === $st->value ? 'selected' : '' }}>
                                {{ $st->value }} ({{ $st->label() }})
                            </option>
                        @endforeach
                    </select>
                </div>

                <!-- Escrow Status -->
                <div>
                    <label class="block text-[10px] uppercase font-bold text-[#8C8477] mb-1">3. Trạng thái Escrow</label>
                    <select name="escrow_status" class="w-full py-1.5 px-2 text-xs border border-[#C5BCAB] rounded-md bg-[#FAF7F2] text-[#2C2E2A] focus:outline-none focus:ring-1 focus:ring-[#2D5A3C]">
                        <option value="">-- Tất cả Escrow --</option>
                        @foreach(\App\Enums\EscrowStatus::cases() as $st)
                            <option value="{{ $st->value }}" {{ request('escrow_status') === $st->value ? 'selected' : '' }}>
                                {{ $st->value }} ({{ $st->label() }})
                            </option>
                        @endforeach
                    </select>
                </div>

                <!-- Dispute Status -->
                <div>
                    <label class="block text-[10px] uppercase font-bold text-[#8C8477] mb-1">4. Trạng thái Khiếu nại</label>
                    <select name="dispute_status" class="w-full py-1.5 px-2 text-xs border border-[#C5BCAB] rounded-md bg-[#FAF7F2] text-[#2C2E2A] focus:outline-none focus:ring-1 focus:ring-[#2D5A3C]">
                        <option value="">-- Tất cả Dispute --</option>
                        @foreach(\App\Enums\DisputeStatus::cases() as $st)
                            <option value="{{ $st->value }}" {{ request('dispute_status') === $st->value ? 'selected' : '' }}>
                                {{ $st->value }} ({{ $st->label() }})
                            </option>
                        @endforeach
                    </select>
                </div>

                <!-- Buttons -->
                <div class="flex items-end space-x-2">
                    <button type="submit" class="flex-1 py-1.5 px-3 text-xs font-semibold bg-[#2D5A3C] text-white rounded-md hover:bg-[#23462F] transition-colors">
                        Lọc kết quả
                    </button>
                    @if(request()->hasAny(['search', 'order_status', 'payment_status', 'escrow_status', 'dispute_status', 'order_source']))
                        <a href="{{ route('admin.orders.index') }}" class="py-1.5 px-3 text-xs font-medium text-[#6E675F] hover:underline">
                            Xóa
                        </a>
                    @endif
                </div>
            </div>
        </form>
    </div>

    <!-- Orders Table (4 Independent State Machines Displayed) -->
    <div class="bg-white rounded-lg border border-[#E0D7C7] shadow-sm overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse text-xs">
                <thead>
                    <tr class="bg-[#F8F5EE] border-b border-[#E0D7C7] text-[#6E675F] uppercase tracking-wider text-[11px]">
                        <th class="py-3 px-4 font-semibold">Mã đơn & Nguồn</th>
                        <th class="py-3 px-4 font-semibold">Người mua & Người bán</th>
                        <th class="py-3 px-4 font-semibold text-right">Giá trị đơn hàng</th>
                        <th class="py-3 px-3 font-semibold text-center">1. Trạng thái Đơn</th>
                        <th class="py-3 px-3 font-semibold text-center">2. Thanh toán</th>
                        <th class="py-3 px-3 font-semibold text-center">3. Ký quỹ Escrow</th>
                        <th class="py-3 px-3 font-semibold text-center">4. Khiếu nại</th>
                        <th class="py-3 px-4 font-semibold text-center">Thao tác</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#E0D7C7]">
                    @forelse($orders as $order)
                        <tr class="hover:bg-[#FAF7F2] transition-colors">
                            <!-- Code & Source -->
                            <td class="py-3 px-4 font-mono">
                                <a href="{{ route('admin.orders.show', $order->id) }}" class="font-bold text-[#2D5A3C] hover:underline">
                                    #{{ $order->order_code }}
                                </a>
                                <div class="mt-0.5">
                                    @if($order->order_source === 'AUCTION')
                                        <span class="inline-block px-1.5 py-0.2 rounded text-[9px] font-bold bg-[#84664C] text-white">
                                            Đấu giá (AUC)
                                        </span>
                                    @else
                                        <span class="inline-block px-1.5 py-0.2 rounded text-[9px] font-medium bg-[#F2ECE1] text-[#6E675F]">
                                            Mua ngay
                                        </span>
                                    @endif
                                </div>
                                <div class="text-[10px] text-[#8C8477] mt-0.5">
                                    {{ $order->created_at->format('d/m/Y H:i') }}
                                </div>
                            </td>

                            <!-- Parties -->
                            <td class="py-3 px-4">
                                <div>
                                    <span class="text-[10px] text-[#8C8477]">Mua:</span>
                                    <strong class="text-[#2C2E2A]">{{ $order->buyer->full_name ?? 'N/A' }}</strong>
                                    <span class="text-[10px] text-[#8C8477] block">{{ $order->buyer->email ?? '' }}</span>
                                </div>
                                <div class="mt-1 pt-1 border-t border-[#F2ECE1]">
                                    <span class="text-[10px] text-[#8C8477]">Bán:</span>
                                    <strong class="text-[#2C2E2A]">{{ $order->seller->full_name ?? 'N/A' }}</strong>
                                </div>
                            </td>

                            <!-- Financial summary -->
                            <td class="py-3 px-4 text-right">
                                <div class="font-mono font-bold text-[#2C2E2A] text-xs">
                                    {{ number_format((float) $order->total_amount) }} đ
                                </div>
                                <div class="text-[10px] text-[#8C8477] font-mono">
                                    Hàng: {{ number_format((float) $order->item_subtotal) }} đ
                                </div>
                                <div class="text-[10px] text-[#84664C] font-mono">
                                    Phí BV: {{ number_format((float) $order->buyer_protection_fee) }} đ
                                </div>
                            </td>

                            <!-- 1. Order Status -->
                            <td class="py-3 px-3 text-center">
                                @php
                                    $ost = $order->order_status instanceof \App\Enums\OrderStatus ? $order->order_status : \App\Enums\OrderStatus::tryFrom($order->order_status);
                                    $orderBadge = match($ost) {
                                        \App\Enums\OrderStatus::PENDING_PAYMENT => 'bg-[#6E675F] text-white',
                                        \App\Enums\OrderStatus::PAID => 'bg-[#3B6E8C] text-white',
                                        \App\Enums\OrderStatus::PREPARING => 'bg-[#84664C] text-white',
                                        \App\Enums\OrderStatus::SHIPPED => 'bg-[#2D5A3C] text-white',
                                        \App\Enums\OrderStatus::DELIVERED => 'bg-[#1E7E34] text-white',
                                        \App\Enums\OrderStatus::COMPLETED => 'bg-[#2D5A3C] text-white',
                                        \App\Enums\OrderStatus::CANCELLED => 'bg-[#8B3A3A] text-white',
                                        \App\Enums\OrderStatus::REFUNDED => 'bg-[#C85A32] text-white',
                                        default => 'bg-gray-400 text-white',
                                    };
                                @endphp
                                <span class="inline-block px-2 py-0.5 rounded text-[10px] font-semibold uppercase tracking-wider {{ $orderBadge }}" title="{{ $ost?->label() }}">
                                    {{ $ost?->value ?? $order->order_status }}
                                </span>
                            </td>

                            <!-- 2. Payment Status -->
                            <td class="py-3 px-3 text-center">
                                @php
                                    $pst = $order->payment_status instanceof \App\Enums\PaymentStatus ? $order->payment_status : \App\Enums\PaymentStatus::tryFrom($order->payment_status);
                                    $payBadge = match($pst) {
                                        \App\Enums\PaymentStatus::PAID => 'bg-[#2D5A3C] text-white',
                                        \App\Enums\PaymentStatus::UNPAID, \App\Enums\PaymentStatus::PENDING => 'bg-[#F2ECE1] text-[#84664C] border border-[#C5BCAB]',
                                        \App\Enums\PaymentStatus::EXPIRED => 'bg-[#8B3A3A] text-white',
                                        \App\Enums\PaymentStatus::REFUNDED => 'bg-[#C85A32] text-white',
                                        default => 'bg-gray-400 text-white',
                                    };
                                @endphp
                                <span class="inline-block px-2 py-0.5 rounded text-[10px] font-semibold uppercase tracking-wider {{ $payBadge }}" title="{{ $pst?->label() }}">
                                    {{ $pst?->value ?? $order->payment_status }}
                                </span>
                            </td>

                            <!-- 3. Escrow Status -->
                            <td class="py-3 px-3 text-center">
                                @php
                                    $est = $order->escrow_status instanceof \App\Enums\EscrowStatus ? $order->escrow_status : \App\Enums\EscrowStatus::tryFrom($order->escrow_status);
                                    $escBadge = match($est) {
                                        \App\Enums\EscrowStatus::HELD => 'bg-[#84664C] text-white',
                                        \App\Enums\EscrowStatus::RELEASED => 'bg-[#2D5A3C] text-white',
                                        \App\Enums\EscrowStatus::REFUNDED => 'bg-[#C85A32] text-white',
                                        \App\Enums\EscrowStatus::PARTIALLY_REFUNDED => 'bg-[#3B6E8C] text-white',
                                        \App\Enums\EscrowStatus::NONE => 'bg-[#FAF7F2] text-[#8C8477]',
                                        default => 'bg-gray-400 text-white',
                                    };
                                @endphp
                                <span class="inline-block px-2 py-0.5 rounded text-[10px] font-semibold uppercase tracking-wider {{ $escBadge }}" title="{{ $est?->label() }}">
                                    {{ $est?->value ?? $order->escrow_status }}
                                </span>
                            </td>

                            <!-- 4. Dispute Status -->
                            <td class="py-3 px-3 text-center">
                                @php
                                    $dst = $order->dispute_status instanceof \App\Enums\DisputeStatus ? $order->dispute_status : \App\Enums\DisputeStatus::tryFrom($order->dispute_status);
                                    $dispBadge = match($dst) {
                                        \App\Enums\DisputeStatus::OPEN => 'bg-[#8B3A3A] text-white animate-pulse',
                                        \App\Enums\DisputeStatus::NEED_MORE_INFO => 'bg-[#C85A32] text-white',
                                        \App\Enums\DisputeStatus::RESOLVED => 'bg-[#2D5A3C] text-white',
                                        \App\Enums\DisputeStatus::NONE => 'bg-[#FAF7F2] text-[#8C8477]',
                                        default => 'bg-gray-400 text-white',
                                    };
                                @endphp
                                <span class="inline-block px-2 py-0.5 rounded text-[10px] font-semibold uppercase tracking-wider {{ $dispBadge }}" title="{{ $dst?->label() }}">
                                    {{ $dst?->value ?? $order->dispute_status }}
                                </span>
                            </td>

                            <!-- Actions -->
                            <td class="py-3 px-4 text-center">
                                <a href="{{ route('admin.orders.show', $order->id) }}"
                                   class="inline-block px-3 py-1 text-xs font-semibold rounded bg-[#F2ECE1] text-[#2C2E2A] hover:bg-[#E5DDCF] border border-[#C5BCAB] transition-colors">
                                    Soi 360&deg; &rsaquo;
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="8" class="py-8 text-center text-[#8C8477]">
                                <p class="text-sm">Không tìm thấy đơn hàng nào phù hợp với bộ lọc hiện tại.</p>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($orders->hasPages())
            <div class="p-4 border-t border-[#E0D7C7] bg-[#FAF7F2]">
                {{ $orders->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
