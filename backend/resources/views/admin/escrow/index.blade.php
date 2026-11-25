@extends('layouts.admin')

@section('title', 'Sổ cái Ký quỹ và Đối soát Tài chính - Retro Market Admin')

@section('content')
<div class="space-y-6">
    <!-- Breadcrumb & Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <nav class="flex items-center space-x-2 text-xs text-[#8C8477] mb-1">
                <a href="{{ route('admin.dashboard') }}" class="hover:underline">Quản trị</a>
                <span>&rsaquo;</span>
                <span class="text-[#2C2E2A] font-medium">Sổ cái Ký quỹ (Escrow)</span>
            </nav>
            <h1 class="text-2xl font-serif font-bold text-[#2C2E2A]">Sổ cái Ký quỹ và Đối soát Tài chính</h1>
            <p class="text-xs text-[#6E675F]">Tra cứu lịch sử giao dịch sổ cái bất biến (Immutable Ledger) và đối soát cân bằng tài chính toàn sàn.</p>
        </div>
        <div class="flex items-center space-x-2">
            <span class="px-3 py-1 text-xs font-mono font-semibold rounded bg-[#EAF2ED] text-[#2D5A3C] border border-[#2D5A3C]/30 flex items-center">
                <svg class="w-3.5 h-3.5 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/>
                </svg>
                Strictly Read-Only Explorer
            </span>
        </div>
    </div>

    <!-- ZERO LEDGER DRIFT RECONCILIATION AUDIT PANEL (AC-P804-01) -->
    <div class="bg-white p-5 rounded-xl border border-[#E0D7C7] shadow-sm space-y-4">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between border-b border-[#E0D7C7] pb-3 gap-2">
            <div class="flex items-center space-x-2">
                <svg class="w-5 h-5 text-[#2D5A3C]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/>
                </svg>
                <h2 class="text-sm font-serif font-bold text-[#2C2E2A]">Bảng Đối soát Cân bằng Tài chính Sổ cái (Zero Ledger Drift)</h2>
            </div>
            @if($ledgerStats['is_zero_drift'])
                <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-[#EAF2ED] text-[#2D5A3C] border border-[#2D5A3C]/30">
                    &#10003; ZERO LEDGER DRIFT [PASS]
                </span>
            @else
                <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-[#FBEAEB] text-[#8B3A3A] border border-[#8B3A3A]/30 animate-pulse">
                    &#10007; LEDGER DRIFT DETECTED: {{ number_format($ledgerStats['escrow_drift']) }} đ
                </span>
            @endif
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 text-xs">
            <!-- Escrow Held Total on Seller Profiles -->
            <div class="p-3 bg-[#FAF7F2] rounded-lg border border-[#E0D7C7]">
                <span class="text-[10px] uppercase font-bold text-[#8C8477]">1. Escrow Tạm giữ (Seller Profiles)</span>
                <p class="text-base font-bold font-mono text-[#2C2E2A] mt-1 tabular-nums">
                    {{ number_format($ledgerStats['seller_escrow_held_total']) }} đ
                </p>
                <span class="text-[10px] text-[#8C8477] block mt-0.5">Tổng số dư tạm giữ trên hồ sơ Người bán</span>
            </div>

            <!-- Active Orders in HELD Status -->
            <div class="p-3 bg-[#FAF7F2] rounded-lg border border-[#E0D7C7]">
                <span class="text-[10px] uppercase font-bold text-[#8C8477]">2. Tiền hàng Đơn đang HELD</span>
                <p class="text-base font-bold font-mono text-[#2C2E2A] mt-1 tabular-nums">
                    {{ number_format($ledgerStats['active_orders_held_total']) }} đ
                </p>
                <span class="text-[10px] text-[#8C8477] block mt-0.5">Tổng tiền hàng đơn hàng có escrow_status = HELD</span>
            </div>

            <!-- Reconciliation Drift Metric -->
            <div class="p-3 bg-[#FAF7F2] rounded-lg border border-[#E0D7C7]">
                <span class="text-[10px] uppercase font-bold text-[#8C8477]">3. Độ lệch Đối soát (Drift)</span>
                <p class="text-base font-bold font-mono {{ $ledgerStats['is_zero_drift'] ? 'text-[#2D5A3C]' : 'text-[#8B3A3A]' }} mt-1 tabular-nums">
                    {{ number_format($ledgerStats['escrow_drift']) }} đ
                </p>
                <span class="text-[10px] text-[#8C8477] block mt-0.5">Chênh lệch giữa Hồ sơ Shop và Đơn hàng</span>
            </div>

            <!-- Total Seller Wallet Balances -->
            <div class="p-3 bg-[#FAF7F2] rounded-lg border border-[#E0D7C7]">
                <span class="text-[10px] uppercase font-bold text-[#8C8477]">4. Tổng Số dư Ví Người bán</span>
                <p class="text-base font-bold font-mono text-[#84664C] mt-1 tabular-nums">
                    {{ number_format($ledgerStats['seller_wallet_total']) }} đ
                </p>
                <span class="text-[10px] text-[#8C8477] block mt-0.5">Tổng số dư khả dụng có thể rút (Wallet Balance)</span>
            </div>
        </div>
    </div>

    <!-- Platform Ledger Totals Cards -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#8C8477] uppercase tracking-wider">Tổng GMV Luân chuyển</span>
            <p class="text-lg font-bold font-mono text-[#2C2E2A] mt-1 tabular-nums">{{ number_format($ledgerStats['gross_volume']) }} đ</p>
            <span class="text-[10px] text-[#8C8477]">{{ $ledgerStats['total_escrow_tx_count'] }} giao dịch Escrow</span>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#2D5A3C] uppercase tracking-wider">Đã giải ngân Người bán</span>
            <p class="text-lg font-bold font-mono text-[#2D5A3C] mt-1 tabular-nums">{{ number_format($ledgerStats['seller_released']) }} đ</p>
            <span class="text-[10px] text-[#8C8477]">100% tiền hàng giải ngân</span>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#C85A32] uppercase tracking-wider">Đã hoàn tiền Người mua</span>
            <p class="text-lg font-bold font-mono text-[#C85A32] mt-1 tabular-nums">{{ number_format($ledgerStats['buyer_refunded']) }} đ</p>
            <span class="text-[10px] text-[#8C8477]">Hoàn 100% hoặc một phần</span>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#84664C] uppercase tracking-wider">Phí Nền tảng Thu giữ</span>
            <p class="text-lg font-bold font-mono text-[#84664C] mt-1 tabular-nums">{{ number_format($ledgerStats['platform_fee_retained']) }} đ</p>
            <span class="text-[10px] text-[#8C8477]">Doanh thu phí bảo vệ sàn</span>
        </div>
    </div>

    <!-- TABS & FILTER TOOLBAR -->
    <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm space-y-3">
        <!-- Tabs -->
        <div class="flex flex-wrap gap-2 border-b border-[#E0D7C7] pb-3">
            <a href="{{ route('admin.escrow.index', ['tab' => 'escrow']) }}"
               class="px-3 py-1.5 text-xs font-semibold rounded-md transition-colors {{ $tab === 'escrow' ? 'bg-[#2C2E2A] text-white' : 'bg-[#F2ECE1] text-[#6E675F] hover:bg-[#E5DDCF]' }}">
                Sổ cái Ký quỹ (Escrow Transactions)
            </a>
            <a href="{{ route('admin.escrow.index', ['tab' => 'wallet']) }}"
               class="px-3 py-1.5 text-xs font-semibold rounded-md transition-colors {{ $tab === 'wallet' ? 'bg-[#84664C] text-white' : 'bg-[#F2ECE1] text-[#6E675F] hover:bg-[#E5DDCF]' }}">
                Sổ cái Ví Người bán (Wallet Transactions)
            </a>
        </div>

        <!-- Filter Form -->
        <form method="GET" action="{{ route('admin.escrow.index') }}" class="flex flex-col md:flex-row gap-3">
            <input type="hidden" name="tab" value="{{ $tab }}">
            <div class="flex-1 relative">
                <input type="text" name="search" value="{{ request('search') }}"
                       placeholder="{{ $tab === 'wallet' ? 'Tìm theo mã giao dịch ví (WTX-...), mã đơn hàng, tên người bán...' : 'Tìm theo mã giao dịch (ESC-...), mã đơn hàng, tên người mua, người bán...' }}"
                       class="w-full pl-9 pr-3 py-2 text-xs border border-[#C5BCAB] rounded-md bg-[#FAF7F2] text-[#2C2E2A] placeholder-[#8C8477] focus:outline-none focus:ring-1 focus:ring-[#2D5A3C]">
                <svg class="w-4 h-4 absolute left-3 top-2.5 text-[#8C8477]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                </svg>
            </div>

            @if($tab === 'escrow')
                <div class="flex items-center gap-2">
                    <select name="transaction_type" class="py-2 px-3 text-xs border border-[#C5BCAB] rounded-md bg-[#FAF7F2] text-[#2C2E2A] focus:outline-none focus:ring-1 focus:ring-[#2D5A3C]">
                        <option value="">-- Tất cả loại nghiệp vụ --</option>
                        <option value="HOLD" {{ request('transaction_type') === 'HOLD' ? 'selected' : '' }}>HOLD - Tạm giữ tiền</option>
                        <option value="RELEASE" {{ request('transaction_type') === 'RELEASE' ? 'selected' : '' }}>RELEASE - Giải ngân 100% người bán</option>
                        <option value="FULL_REFUND" {{ request('transaction_type') === 'FULL_REFUND' ? 'selected' : '' }}>FULL_REFUND - Hoàn tiền 100% người mua</option>
                        <option value="PARTIAL_REFUND" {{ request('transaction_type') === 'PARTIAL_REFUND' ? 'selected' : '' }}>PARTIAL_REFUND - Hoàn một phần</option>
                    </select>
                    <button type="submit" class="px-4 py-2 text-xs font-semibold bg-[#2D5A3C] text-white rounded-md hover:bg-[#23462F] transition-colors">
                        Lọc
                    </button>
                    @if(request()->hasAny(['search', 'transaction_type']))
                        <a href="{{ route('admin.escrow.index', ['tab' => 'escrow']) }}" class="px-3 py-2 text-xs font-medium text-[#6E675F] hover:underline">
                            Xóa
                        </a>
                    @endif
                </div>
            @else
                <div class="flex items-center gap-2">
                    <select name="entry_type" class="py-2 px-3 text-xs border border-[#C5BCAB] rounded-md bg-[#FAF7F2] text-[#2C2E2A] focus:outline-none focus:ring-1 focus:ring-[#2D5A3C]">
                        <option value="">-- Tất cả biến động --</option>
                        <option value="CREDIT" {{ request('entry_type') === 'CREDIT' ? 'selected' : '' }}>CREDIT - Cộng tiền</option>
                        <option value="DEBIT" {{ request('entry_type') === 'DEBIT' ? 'selected' : '' }}>DEBIT - Trừ tiền</option>
                    </select>
                    <button type="submit" class="px-4 py-2 text-xs font-semibold bg-[#2D5A3C] text-white rounded-md hover:bg-[#23462F] transition-colors">
                        Lọc
                    </button>
                    @if(request()->hasAny(['search', 'entry_type']))
                        <a href="{{ route('admin.escrow.index', ['tab' => 'wallet']) }}" class="px-3 py-2 text-xs font-medium text-[#6E675F] hover:underline">
                            Xóa
                        </a>
                    @endif
                </div>
            @endif
        </form>
    </div>

    <!-- DATA TABLE: ESCROW TRANSACTIONS OR WALLET TRANSACTIONS -->
    <div class="bg-white rounded-lg border border-[#E0D7C7] shadow-sm overflow-hidden">
        @if($tab === 'escrow')
            <!-- ESCROW TRANSACTIONS TABLE -->
            <div class="overflow-x-auto">
                <table class="w-full text-left border-collapse text-xs">
                    <thead>
                        <tr class="bg-[#F8F5EE] border-b border-[#E0D7C7] text-[#6E675F] uppercase tracking-wider text-[11px]">
                            <th class="py-3 px-4 font-semibold">Mã giao dịch</th>
                            <th class="py-3 px-4 font-semibold">Đơn hàng</th>
                            <th class="py-3 px-4 font-semibold">Khách mua / Người bán</th>
                            <th class="py-3 px-4 font-semibold text-center">Nghiệp vụ</th>
                            <th class="py-3 px-4 font-semibold text-right">Tổng GD (Gross)</th>
                            <th class="py-3 px-4 font-semibold text-right">Giải ngân Bán</th>
                            <th class="py-3 px-4 font-semibold text-right">Hoàn tiền Mua</th>
                            <th class="py-3 px-4 font-semibold text-right">Phí sàn</th>
                            <th class="py-3 px-4 font-semibold">Thời điểm</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-[#E0D7C7]">
                        @forelse($escrowTransactions as $tx)
                            <tr class="hover:bg-[#FAF7F2] transition-colors">
                                <td class="py-3 px-4 font-mono font-bold text-[#2C2E2A]">
                                    {{ $tx->transaction_code }}
                                    <div class="text-[10px] text-[#8C8477] font-normal truncate max-w-[160px]" title="{{ $tx->note }}">
                                        {{ $tx->note }}
                                    </div>
                                </td>
                                <td class="py-3 px-4 font-mono">
                                    @if($tx->order)
                                        <a href="{{ route('admin.orders.show', $tx->order_id) }}" class="font-bold text-[#2D5A3C] hover:underline">
                                            #{{ $tx->order->order_code }}
                                        </a>
                                    @else
                                        #{{ $tx->order_id }}
                                    @endif
                                </td>
                                <td class="py-3 px-4">
                                    <p class="font-medium text-[#2C2E2A]">M: {{ $tx->buyer->full_name ?? 'N/A' }}</p>
                                    <p class="text-[10px] text-[#8C8477]">B: {{ $tx->seller->full_name ?? 'N/A' }}</p>
                                </td>
                                <td class="py-3 px-4 text-center">
                                    @php
                                        $badgeClass = match($tx->transaction_type) {
                                            'HOLD' => 'bg-[#84664C] text-white',
                                            'RELEASE' => 'bg-[#2D5A3C] text-white',
                                            'FULL_REFUND' => 'bg-[#C85A32] text-white',
                                            'PARTIAL_REFUND' => 'bg-[#3B6E8C] text-white',
                                            default => 'bg-gray-500 text-white',
                                        };
                                    @endphp
                                    <span class="inline-block px-2 py-0.5 rounded text-[10px] font-semibold uppercase tracking-wider {{ $badgeClass }}">
                                        {{ $tx->transaction_type }}
                                    </span>
                                </td>
                                <td class="py-3 px-4 text-right font-mono font-bold text-[#2C2E2A] tabular-nums">
                                    {{ number_format((float) $tx->gross_amount) }} đ
                                </td>
                                <td class="py-3 px-4 text-right font-mono text-[#2D5A3C] tabular-nums font-semibold">
                                    {{ (float) $tx->seller_released_amount > 0 ? number_format((float) $tx->seller_released_amount) . ' đ' : '-' }}
                                </td>
                                <td class="py-3 px-4 text-right font-mono text-[#C85A32] tabular-nums font-semibold">
                                    {{ (float) $tx->buyer_refunded_amount > 0 ? number_format((float) $tx->buyer_refunded_amount) . ' đ' : '-' }}
                                </td>
                                <td class="py-3 px-4 text-right font-mono text-[#84664C] tabular-nums">
                                    {{ (float) $tx->platform_fee_retained > 0 ? number_format((float) $tx->platform_fee_retained) . ' đ' : '-' }}
                                </td>
                                <td class="py-3 px-4 text-[11px] font-mono text-[#8C8477]">
                                    {{ $tx->created_at->format('d/m/Y H:i:s') }}
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="9" class="py-8 text-center text-[#8C8477]">
                                    <p class="text-sm">Không tìm thấy giao dịch ký quỹ nào phù hợp.</p>
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            @if($escrowTransactions->hasPages())
                <div class="p-4 border-t border-[#E0D7C7] bg-[#FAF7F2]">
                    {{ $escrowTransactions->links() }}
                </div>
            @endif
        @else
            <!-- WALLET TRANSACTIONS TABLE -->
            <div class="overflow-x-auto">
                <table class="w-full text-left border-collapse text-xs">
                    <thead>
                        <tr class="bg-[#F8F5EE] border-b border-[#E0D7C7] text-[#6E675F] uppercase tracking-wider text-[11px]">
                            <th class="py-3 px-4 font-semibold">Mã GD Ví</th>
                            <th class="py-3 px-4 font-semibold">Người bán (Chủ ví)</th>
                            <th class="py-3 px-4 font-semibold">Đơn hàng liên quan</th>
                            <th class="py-3 px-4 font-semibold text-center">Loại biến động</th>
                            <th class="py-3 px-4 font-semibold text-right">Số tiền</th>
                            <th class="py-3 px-4 font-semibold text-right">Số dư Trước &rarr; Sau</th>
                            <th class="py-3 px-4 font-semibold">Diễn giải</th>
                            <th class="py-3 px-4 font-semibold">Thời điểm</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-[#E0D7C7]">
                        @forelse($walletTransactions as $wtx)
                            <tr class="hover:bg-[#FAF7F2] transition-colors">
                                <td class="py-3 px-4 font-mono font-bold text-[#2C2E2A]">
                                    {{ $wtx->wallet_tx_code }}
                                </td>
                                <td class="py-3 px-4">
                                    <p class="font-medium text-[#2C2E2A]">{{ $wtx->seller->full_name ?? 'N/A' }}</p>
                                    <p class="text-[10px] text-[#8C8477]">{{ $wtx->seller->email ?? '' }}</p>
                                </td>
                                <td class="py-3 px-4 font-mono">
                                    @if($wtx->order)
                                        <a href="{{ route('admin.orders.show', $wtx->order_id) }}" class="text-[#2D5A3C] hover:underline">
                                            #{{ $wtx->order->order_code }}
                                        </a>
                                    @else
                                        -
                                    @endif
                                </td>
                                <td class="py-3 px-4 text-center">
                                    @if($wtx->entry_type === 'CREDIT')
                                        <span class="inline-block px-2 py-0.5 rounded text-[10px] font-bold bg-[#EAF2ED] text-[#2D5A3C]">
                                            + CREDIT (Cộng tiền)
                                        </span>
                                    @else
                                        <span class="inline-block px-2 py-0.5 rounded text-[10px] font-bold bg-[#FBEAEB] text-[#8B3A3A]">
                                            - DEBIT (Trừ tiền)
                                        </span>
                                    @endif
                                </td>
                                <td class="py-3 px-4 text-right font-mono font-bold {{ $wtx->entry_type === 'CREDIT' ? 'text-[#2D5A3C]' : 'text-[#8B3A3A]' }} tabular-nums text-sm">
                                    {{ $wtx->entry_type === 'CREDIT' ? '+' : '-' }}{{ number_format((float) $wtx->amount) }} đ
                                </td>
                                <td class="py-3 px-4 text-right font-mono text-[11px] tabular-nums">
                                    <span class="text-[#8C8477]">{{ number_format((float) $wtx->balance_before) }}</span>
                                    &rarr;
                                    <strong class="text-[#2C2E2A]">{{ number_format((float) $wtx->balance_after) }} đ</strong>
                                </td>
                                <td class="py-3 px-4 text-[11px] text-[#6E675F] max-w-[200px] truncate" title="{{ $wtx->description }}">
                                    {{ $wtx->description }}
                                </td>
                                <td class="py-3 px-4 text-[11px] font-mono text-[#8C8477]">
                                    {{ $wtx->created_at->format('d/m/Y H:i:s') }}
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="8" class="py-8 text-center text-[#8C8477]">
                                    <p class="text-sm">Không tìm thấy biến động số dư ví nào.</p>
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            @if($walletTransactions->hasPages())
                <div class="p-4 border-t border-[#E0D7C7] bg-[#FAF7F2]">
                    {{ $walletTransactions->links() }}
                </div>
            @endif
        @endif
    </div>
</div>
@endsection
