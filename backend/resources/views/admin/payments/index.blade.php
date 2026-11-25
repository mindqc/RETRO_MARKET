@extends('layouts.admin')

@section('title', 'Quản lý Giao dịch Thanh toán - Retro Market Admin')

@section('content')
<div class="space-y-6">
    <!-- Breadcrumb & Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <nav class="flex items-center space-x-2 text-xs text-[#8C8477] mb-1">
                <a href="{{ route('admin.dashboard') }}" class="hover:underline">Quản trị</a>
                <span>&rsaquo;</span>
                <span class="text-[#2C2E2A] font-medium">Giao dịch Thanh toán</span>
            </nav>
            <h1 class="text-2xl font-serif font-bold text-[#2C2E2A]">Quản lý Giao dịch Thanh toán (QR Sessions)</h1>
            <p class="text-xs text-[#6E675F]">Giám sát các phiên thanh toán Mock QR, nội dung chuyển khoản chuẩn hóa và trạng thái khớp lệnh thanh toán.</p>
        </div>
    </div>

    <!-- Summary Cards -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#8C8477] uppercase tracking-wider">Tổng số phiên QR</span>
            <p class="text-2xl font-bold font-serif text-[#2C2E2A] mt-1">{{ number_format($stats['total']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#2D5A3C] uppercase tracking-wider">Đã khớp thanh toán</span>
            <div class="mt-1 flex items-baseline justify-between">
                <p class="text-xl font-bold font-mono text-[#2D5A3C]">{{ number_format((float) $stats['paid_amount']) }} đ</p>
                <span class="text-xs text-[#2D5A3C] font-semibold">({{ $stats['paid_count'] }} phiên)</span>
            </div>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#C5A66B] uppercase tracking-wider">Đang chờ quét QR</span>
            <p class="text-2xl font-bold font-serif text-[#C5A66B] mt-1">{{ number_format($stats['pending_count']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#8B3A3A] uppercase tracking-wider">Đã hết hạn QR</span>
            <p class="text-2xl font-bold font-serif text-[#8B3A3A] mt-1">{{ number_format($stats['expired_count']) }}</p>
        </div>
    </div>

    <!-- Filter & Search Toolbar -->
    <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
        <form method="GET" action="{{ route('admin.payments.index') }}" class="flex flex-col md:flex-row gap-3">
            <div class="flex-1 relative">
                <input type="text" name="search" value="{{ request('search') }}"
                       placeholder="Tìm theo mã thanh toán (PAY-...), mã đơn (ORD-...), email/tên người nộp..."
                       class="w-full pl-9 pr-3 py-2 text-xs border border-[#C5BCAB] rounded-md bg-[#FAF7F2] text-[#2C2E2A] placeholder-[#8C8477] focus:outline-none focus:ring-1 focus:ring-[#2D5A3C]">
                <svg class="w-4 h-4 absolute left-3 top-2.5 text-[#8C8477]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                </svg>
            </div>
            <div class="flex items-center gap-2">
                <select name="status" class="py-2 px-3 text-xs border border-[#C5BCAB] rounded-md bg-[#FAF7F2] text-[#2C2E2A] focus:outline-none focus:ring-1 focus:ring-[#2D5A3C]">
                    <option value="">-- Tất cả trạng thái --</option>
                    @foreach(\App\Enums\PaymentStatus::cases() as $st)
                        <option value="{{ $st->value }}" {{ request('status') === $st->value ? 'selected' : '' }}>
                            {{ $st->value }} - {{ $st->label() }}
                        </option>
                    @endforeach
                </select>
                <button type="submit" class="px-4 py-2 text-xs font-semibold bg-[#2D5A3C] text-white rounded-md hover:bg-[#23462F] transition-colors">
                    Lọc
                </button>
                @if(request()->hasAny(['search', 'status']))
                    <a href="{{ route('admin.payments.index') }}" class="px-3 py-2 text-xs font-medium text-[#6E675F] hover:underline">
                        Xóa lọc
                    </a>
                @endif
            </div>
        </form>
    </div>

    <!-- Payments Table (AC-P803-04) -->
    <div class="bg-white rounded-lg border border-[#E0D7C7] shadow-sm overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse text-xs">
                <thead>
                    <tr class="bg-[#F8F5EE] border-b border-[#E0D7C7] text-[#6E675F] uppercase tracking-wider text-[11px]">
                        <th class="py-3 px-4 font-semibold">Mã giao dịch</th>
                        <th class="py-3 px-4 font-semibold">Đơn hàng liên kết</th>
                        <th class="py-3 px-4 font-semibold">Người nộp tiền</th>
                        <th class="py-3 px-4 font-semibold text-right">Số tiền QR</th>
                        <th class="py-3 px-4 font-semibold">Nội dung QR (Transfer Content)</th>
                        <th class="py-3 px-4 font-semibold text-center">Trạng thái</th>
                        <th class="py-3 px-4 font-semibold">Thời hạn & Khớp lệnh</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#E0D7C7]">
                    @forelse($payments as $payment)
                        <tr class="hover:bg-[#FAF7F2] transition-colors">
                            <!-- Payment Reference -->
                            <td class="py-3 px-4 font-mono font-bold text-[#2C2E2A]">
                                {{ $payment->payment_reference }}
                                <div class="text-[10px] text-[#8C8477] font-sans font-normal mt-0.5">
                                    {{ $payment->created_at->format('d/m/Y H:i:s') }}
                                </div>
                            </td>

                            <!-- Order Link -->
                            <td class="py-3 px-4 font-mono">
                                @if($payment->order)
                                    <a href="{{ route('admin.orders.show', $payment->order_id) }}" class="font-bold text-[#2D5A3C] hover:underline">
                                        #{{ $payment->order->order_code }}
                                    </a>
                                    <div class="text-[10px] text-[#8C8477] font-sans">
                                        {{ $payment->order->order_status->value }}
                                    </div>
                                @else
                                    <span class="text-[#8C8477]">Order #{{ $payment->order_id }}</span>
                                @endif
                            </td>

                            <!-- Payer -->
                            <td class="py-3 px-4">
                                <p class="font-medium text-[#2C2E2A]">{{ $payment->payer->full_name ?? 'N/A' }}</p>
                                <p class="text-[10px] text-[#8C8477]">{{ $payment->payer->email ?? '' }}</p>
                            </td>

                            <!-- Amount -->
                            <td class="py-3 px-4 text-right font-mono font-bold text-sm text-[#2C2E2A] tabular-nums">
                                {{ number_format((float) $payment->amount) }} đ
                            </td>

                            <!-- QR Payload / Transfer content -->
                            <td class="py-3 px-4 font-mono text-[11px] text-[#6E675F] max-w-[200px] truncate" title="{{ $payment->qr_payload }}">
                                <span class="px-1.5 py-0.5 rounded bg-[#F2ECE1] text-[#2C2E2A] font-semibold">
                                    {{ $payment->qr_payload ? Str::limit($payment->qr_payload, 35) : 'IZITHRIFT ' . ($payment->order?->order_code ?? '') }}
                                </span>
                            </td>

                            <!-- Status Badge -->
                            <td class="py-3 px-4 text-center">
                                @php
                                    $st = $payment->status instanceof \App\Enums\PaymentStatus ? $payment->status : \App\Enums\PaymentStatus::tryFrom($payment->status);
                                    $badge = match($st) {
                                        \App\Enums\PaymentStatus::PAID => 'bg-[#2D5A3C] text-white',
                                        \App\Enums\PaymentStatus::PENDING => 'bg-[#C5A66B] text-white',
                                        \App\Enums\PaymentStatus::EXPIRED => 'bg-[#8B3A3A] text-white',
                                        \App\Enums\PaymentStatus::FAILED => 'bg-red-700 text-white',
                                        \App\Enums\PaymentStatus::REFUNDED => 'bg-[#C85A32] text-white',
                                        default => 'bg-gray-400 text-white',
                                    };
                                @endphp
                                <span class="inline-block px-2 py-0.5 rounded text-[10px] font-semibold uppercase tracking-wider {{ $badge }}">
                                    {{ $st?->value ?? $payment->status }}
                                </span>
                                @if($payment->failure_reason)
                                    <div class="text-[9px] text-[#8B3A3A] mt-0.5 max-w-[120px] truncate mx-auto" title="{{ $payment->failure_reason }}">
                                        {{ $payment->failure_reason }}
                                    </div>
                                @endif
                            </td>

                            <!-- Expiration & Paid Timestamp -->
                            <td class="py-3 px-4 text-[11px]">
                                @if($payment->paid_at)
                                    <div class="text-[#2D5A3C] font-semibold">
                                        Khớp lệnh: <span class="font-mono">{{ $payment->paid_at->format('d/m/Y H:i:s') }}</span>
                                    </div>
                                @elseif($payment->expires_at)
                                    <div>
                                        <span class="text-[#8C8477]">Hạn QR:</span>
                                        <span class="font-mono {{ $payment->expires_at->isPast() ? 'text-[#8B3A3A] font-semibold' : 'text-[#2C2E2A]' }}">
                                            {{ $payment->expires_at->format('d/m/Y H:i:s') }}
                                        </span>
                                        @if($payment->expires_at->isPast() && $payment->status === \App\Enums\PaymentStatus::PENDING)
                                            <span class="text-[9px] text-[#8B3A3A] block font-bold">(Đã quá hạn)</span>
                                        @endif
                                    </div>
                                @else
                                    <span class="text-[#8C8477]">N/A</span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="py-8 text-center text-[#8C8477]">
                                <p class="text-sm">Không tìm thấy giao dịch thanh toán nào phù hợp với bộ lọc.</p>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($payments->hasPages())
            <div class="p-4 border-t border-[#E0D7C7] bg-[#FAF7F2]">
                {{ $payments->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
