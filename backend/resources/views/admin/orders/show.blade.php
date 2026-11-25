@extends('layouts.admin')

@section('title', 'Chi tiết Đơn hàng #' . $order->order_code . ' - Retro Market Admin')

@section('content')
@php
    $ost = $order->order_status instanceof \App\Enums\OrderStatus ? $order->order_status : \App\Enums\OrderStatus::tryFrom($order->order_status);
    $pst = $order->payment_status instanceof \App\Enums\PaymentStatus ? $order->payment_status : \App\Enums\PaymentStatus::tryFrom($order->payment_status);
    $est = $order->escrow_status instanceof \App\Enums\EscrowStatus ? $order->escrow_status : \App\Enums\EscrowStatus::tryFrom($order->escrow_status);
    $dst = $order->dispute_status instanceof \App\Enums\DisputeStatus ? $order->dispute_status : \App\Enums\DisputeStatus::tryFrom($order->dispute_status);
@endphp

<div class="space-y-6">
    <!-- Breadcrumb & Nav -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <nav class="flex items-center space-x-2 text-xs text-[#8C8477] mb-1">
                <a href="{{ route('admin.dashboard') }}" class="hover:underline">Quản trị</a>
                <span>&rsaquo;</span>
                <a href="{{ route('admin.orders.index') }}" class="hover:underline">Đơn hàng & Escrow</a>
                <span>&rsaquo;</span>
                <span class="text-[#2C2E2A] font-medium font-mono">#{{ $order->order_code }}</span>
            </nav>
            <div class="flex items-center space-x-3">
                <h1 class="text-2xl font-serif font-bold text-[#2C2E2A]">Soi 360° Đơn hàng</h1>
                <span class="font-mono text-sm px-2 py-0.5 rounded bg-[#F2ECE1] text-[#2C2E2A] font-semibold">
                    #{{ $order->order_code }}
                </span>
                @if($order->order_source === 'AUCTION')
                    <span class="px-2 py-0.5 rounded text-xs font-bold bg-[#84664C] text-white">
                        Nguồn: Đấu giá (Auction)
                    </span>
                @else
                    <span class="px-2 py-0.5 rounded text-xs font-medium bg-[#F2ECE1] text-[#6E675F]">
                        Nguồn: Mua ngay (Direct)
                    </span>
                @endif
            </div>
        </div>
        <div>
            <a href="{{ route('admin.orders.index') }}"
               class="px-3 py-1.5 text-xs font-medium rounded border border-[#C5BCAB] bg-white text-[#2C2E2A] hover:bg-[#FAF7F2] transition-colors">
                &larr; Quay lại danh sách
            </a>
        </div>
    </div>

    <!-- 4 INDEPENDENT STATE MACHINES CONTROL PANEL (AC-P803-02) -->
    <div class="bg-white p-5 rounded-xl border border-[#E0D7C7] shadow-sm">
        <div class="flex items-center justify-between border-b border-[#E0D7C7] pb-3 mb-4">
            <h2 class="text-xs uppercase tracking-wider font-bold text-[#8C8477]">
                Hệ thống 4 Máy Trạng thái Độc lập (4 Independent State Machines)
            </h2>
            <span class="text-[11px] text-[#8C8477]">
                Khởi tạo: {{ $order->created_at->format('d/m/Y H:i:s') }}
            </span>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <!-- 1. Order Status -->
            <div class="p-3 rounded-lg border border-[#E0D7C7] bg-[#FAF7F2]">
                <div class="flex items-center justify-between mb-1">
                    <span class="text-[10px] uppercase font-bold text-[#8C8477]">1. Trạng thái Đơn hàng</span>
                    <span class="w-2 h-2 rounded-full bg-[#2D5A3C]"></span>
                </div>
                <div class="text-sm font-bold font-mono text-[#2C2E2A]">
                    {{ $ost?->value ?? $order->order_status }}
                </div>
                <p class="text-[11px] text-[#6E675F] mt-1">{{ $ost?->label() }}</p>
            </div>

            <!-- 2. Payment Status -->
            <div class="p-3 rounded-lg border border-[#E0D7C7] bg-[#FAF7F2]">
                <div class="flex items-center justify-between mb-1">
                    <span class="text-[10px] uppercase font-bold text-[#8C8477]">2. Trạng thái Thanh toán</span>
                    <span class="w-2 h-2 rounded-full bg-[#3B6E8C]"></span>
                </div>
                <div class="text-sm font-bold font-mono text-[#2C2E2A]">
                    {{ $pst?->value ?? $order->payment_status }}
                </div>
                <p class="text-[11px] text-[#6E675F] mt-1">{{ $pst?->label() }}</p>
            </div>

            <!-- 3. Escrow Status -->
            <div class="p-3 rounded-lg border border-[#E0D7C7] bg-[#FAF7F2]">
                <div class="flex items-center justify-between mb-1">
                    <span class="text-[10px] uppercase font-bold text-[#8C8477]">3. Ký quỹ Escrow</span>
                    <span class="w-2 h-2 rounded-full bg-[#84664C]"></span>
                </div>
                <div class="text-sm font-bold font-mono text-[#2C2E2A]">
                    {{ $est?->value ?? $order->escrow_status }}
                </div>
                <p class="text-[11px] text-[#6E675F] mt-1">{{ $est?->label() }}</p>
            </div>

            <!-- 4. Dispute Status -->
            <div class="p-3 rounded-lg border border-[#E0D7C7] bg-[#FAF7F2]">
                <div class="flex items-center justify-between mb-1">
                    <span class="text-[10px] uppercase font-bold text-[#8C8477]">4. Khiếu nại (Dispute)</span>
                    <span class="w-2 h-2 rounded-full {{ $dst === \App\Enums\DisputeStatus::OPEN ? 'bg-[#8B3A3A] animate-ping' : 'bg-[#6E675F]' }}"></span>
                </div>
                <div class="text-sm font-bold font-mono text-[#2C2E2A]">
                    {{ $dst?->value ?? $order->dispute_status }}
                </div>
                <p class="text-[11px] text-[#6E675F] mt-1">{{ $dst?->label() }}</p>
            </div>
        </div>
    </div>

    <!-- MAIN GRID: 2 Columns -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- LEFT: Items Snapshot, Address, Financials (2 cols) -->
        <div class="lg:col-span-2 space-y-6">
            <!-- IMMUTABLE ORDER ITEMS SNAPSHOT TABLE (AC-P803-02 / ImmutableLedgerRecord) -->
            <div class="bg-white rounded-lg border border-[#E0D7C7] shadow-sm overflow-hidden">
                <div class="px-5 py-4 border-b border-[#E0D7C7] flex items-center justify-between bg-[#F8F5EE]">
                    <div>
                        <h3 class="text-sm font-serif font-bold text-[#2C2E2A]">Bản ghi Ảnh chụp Sản phẩm (Immutable Items Snapshot)</h3>
                        <p class="text-[11px] text-[#8C8477]">Dữ liệu đóng băng tại thời điểm tạo đơn, chống sửa đổi khi phát sinh tranh chấp.</p>
                    </div>
                    <span class="text-[10px] font-mono px-2 py-0.5 rounded bg-[#EAF2ED] text-[#2D5A3C] font-semibold">
                        Append-Only Record
                    </span>
                </div>

                <div class="divide-y divide-[#E0D7C7]">
                    @forelse($order->items as $item)
                        <div class="p-4 flex flex-col sm:flex-row gap-4 items-start hover:bg-[#FAF7F2] transition-colors">
                            <div class="w-20 h-20 rounded-md border border-[#E0D7C7] overflow-hidden bg-[#F2ECE1] shrink-0">
                                @if($item->primary_image_snapshot)
                                    <img src="{{ $item->primary_image_snapshot }}" alt="{{ $item->product_title_snapshot }}" class="w-full h-full object-cover">
                                @else
                                    <div class="w-full h-full flex items-center justify-center text-[#8C8477] text-xs">No Img</div>
                                @endif
                            </div>
                            <div class="flex-1 space-y-1">
                                <div class="flex items-center justify-between">
                                    <h4 class="text-sm font-serif font-bold text-[#2C2E2A]">{{ $item->product_title_snapshot }}</h4>
                                    <span class="font-mono font-bold text-sm text-[#2C2E2A] tabular-nums">
                                        {{ number_format((float) $item->line_total) }} đ
                                    </span>
                                </div>
                                <div class="flex flex-wrap gap-2 text-[11px] text-[#6E675F]">
                                    <span>Mã SP: <strong class="font-mono text-[#2C2E2A]">{{ $item->product_code_snapshot }}</strong></span>
                                    <span>&bull;</span>
                                    <span>Tình trạng: <strong class="text-[#2C2E2A]">{{ $item->condition_snapshot }}</strong></span>
                                    <span>&bull;</span>
                                    <span>Đơn giá: <strong class="font-mono text-[#2C2E2A] tabular-nums">{{ number_format((float) $item->unit_price_snapshot) }} đ</strong> &times; {{ $item->quantity }}</span>
                                </div>
                                @if($item->defect_info_snapshot)
                                    <div class="text-[11px] text-[#8B3A3A] bg-[#FBEAEB] p-2 rounded mt-1">
                                        <strong>Ghi nhận lỗi/khuyết tật:</strong> {{ $item->defect_info_snapshot }}
                                    </div>
                                @endif
                            </div>
                        </div>
                    @empty
                        <div class="p-6 text-center text-[#8C8477] italic text-xs">Không có dữ liệu mặt hàng.</div>
                    @endforelse
                </div>
            </div>

            <!-- DEC-04 FINANCIAL BREAKDOWN TABLE (AC-P803-03) -->
            <div class="bg-white rounded-lg border border-[#E0D7C7] shadow-sm overflow-hidden">
                <div class="px-5 py-4 border-b border-[#E0D7C7] bg-[#F8F5EE] flex items-center justify-between">
                    <div>
                        <h3 class="text-sm font-serif font-bold text-[#2C2E2A]">Minh bạch Tài chính và Biểu phí DEC-04 (Financial Breakdown)</h3>
                        <p class="text-[11px] text-[#8C8477]">Hệ thống bảo vệ giao dịch: Phí bảo vệ 6% + 7.000 đ thu từ Người mua; Người bán nhận 100% giá trị hàng.</p>
                    </div>
                    <span class="text-xs font-mono font-bold text-[#84664C]">DEC-04 Policy</span>
                </div>

                <div class="p-5 space-y-3 text-xs">
                    <div class="flex items-center justify-between py-1 border-b border-[#F2ECE1]">
                        <span class="text-[#6E675F]">1. Tổng tiền hàng (Item Subtotal):</span>
                        <span class="font-mono font-semibold text-[#2C2E2A] tabular-nums">
                            {{ number_format((float) $order->item_subtotal) }} đ
                        </span>
                    </div>

                    <div class="flex items-center justify-between py-1 border-b border-[#F2ECE1]">
                        <span class="text-[#6E675F]">2. Phí vận chuyển (Shipping Fee):</span>
                        <span class="font-mono font-semibold text-[#2C2E2A] tabular-nums">
                            {{ number_format((float) $order->shipping_fee) }} đ <span class="text-[10px] text-[#8C8477]">(Mặc định 0 đ)</span>
                        </span>
                    </div>

                    <div class="flex items-center justify-between py-1 border-b border-[#F2ECE1] bg-[#FAF7F2] px-2 rounded">
                        <div>
                            <span class="text-[#2C2E2A] font-semibold">3. Phí Bảo vệ Người mua (Buyer Protection Fee):</span>
                            <span class="block text-[10px] text-[#8C8477]">
                                Công thức: (Tiền hàng &times; 6%) + 7.000 đ = ({{ number_format((float) $order->item_subtotal) }} &times; 6%) + 7.000 đ
                            </span>
                        </div>
                        <span class="font-mono font-bold text-[#C85A32] tabular-nums">
                            +{{ number_format((float) $order->buyer_protection_fee) }} đ
                        </span>
                    </div>

                    <div class="flex items-center justify-between py-2 border-b-2 border-[#2C2E2A] text-sm">
                        <span class="font-bold text-[#2C2E2A]">TỔNG TIỀN NGƯỜI MUA THANH TOÁN (Total Amount):</span>
                        <span class="font-mono font-black text-base text-[#2D5A3C] tabular-nums">
                            {{ number_format((float) $order->total_amount) }} đ
                        </span>
                    </div>

                    <!-- Seller Net Payout -->
                    <div class="flex items-center justify-between py-2 bg-[#EAF2ED] px-3 rounded-lg border border-[#2D5A3C]/30 text-xs">
                        <div>
                            <strong class="text-[#2D5A3C]">4. Thực nhận Người bán (Seller Net Payout):</strong>
                            <p class="text-[10px] text-[#2D5A3C]/80">100% Tiền hàng (0% phí chiết khấu người bán theo chuẩn DEC-04).</p>
                        </div>
                        <span class="font-mono font-bold text-sm text-[#2D5A3C] tabular-nums">
                            {{ number_format((float) $order->seller_net_amount) }} đ
                        </span>
                    </div>
                </div>
            </div>

            <!-- SHIPMENT & TRACKING TIMELINE -->
            <div class="bg-white rounded-lg border border-[#E0D7C7] shadow-sm p-5 space-y-3">
                <div class="flex items-center justify-between border-b border-[#E0D7C7] pb-3">
                    <h3 class="text-sm font-serif font-bold text-[#2C2E2A]">Theo dõi Vận chuyển & Giao hàng (Shipment)</h3>
                    @if($order->shipment)
                        <span class="px-2 py-0.5 rounded text-[10px] font-bold bg-[#EAF2ED] text-[#2D5A3C]">
                            {{ $order->shipment->carrier_name }}
                        </span>
                    @else
                        <span class="px-2 py-0.5 rounded text-[10px] font-medium bg-[#F2ECE1] text-[#8C8477]">
                            Chưa tạo vận đơn
                        </span>
                    @endif
                </div>

                @if($order->shipment)
                    <div class="grid grid-cols-1 sm:grid-cols-3 gap-3 text-xs">
                        <div>
                            <span class="text-[10px] uppercase text-[#8C8477] font-semibold">Đơn vị vận chuyển</span>
                            <p class="font-bold text-[#2C2E2A] mt-0.5">{{ $order->shipment->carrier_name }}</p>
                        </div>
                        <div>
                            <span class="text-[10px] uppercase text-[#8C8477] font-semibold">Mã vận đơn (Tracking Code)</span>
                            <p class="font-mono font-bold text-[#2D5A3C] mt-0.5">{{ $order->shipment->tracking_code }}</p>
                        </div>
                        <div>
                            <span class="text-[10px] uppercase text-[#8C8477] font-semibold">Trạng thái vận chuyển</span>
                            <p class="font-semibold text-[#2C2E2A] mt-0.5">{{ $order->shipment->status }}</p>
                        </div>
                    </div>
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs pt-2 border-t border-[#F2ECE1]">
                        <div>
                            <span class="text-[#8C8477]">Thời điểm gửi hàng:</span>
                            <span class="font-mono font-medium text-[#2C2E2A]">{{ $order->shipment->shipped_at ? $order->shipment->shipped_at->format('d/m/Y H:i') : 'Chưa giao đi' }}</span>
                        </div>
                        <div>
                            <span class="text-[#8C8477]">Thời điểm giao thành công:</span>
                            <span class="font-mono font-medium text-[#2C2E2A]">{{ $order->shipment->delivered_at ? $order->shipment->delivered_at->format('d/m/Y H:i') : 'Chưa đến nơi' }}</span>
                        </div>
                    </div>
                    @if($order->shipment->shipping_note)
                        <div class="text-[11px] text-[#6E675F] bg-[#FAF7F2] p-2 rounded">
                            <strong>Ghi chú giao hàng:</strong> {{ $order->shipment->shipping_note }}
                        </div>
                    @endif
                @else
                    <p class="text-xs text-[#8C8477] italic">Người bán chưa gửi hàng hoặc chưa cập nhật mã vận đơn lên hệ thống.</p>
                @endif
            </div>

            <!-- 3-TIER CANCELLATION STATE (DEC-06 / DEC-07) -->
            <div class="bg-white rounded-lg border border-[#E0D7C7] shadow-sm p-5 space-y-3">
                <h3 class="text-sm font-serif font-bold text-[#2C2E2A]">Nhật ký Hủy đơn 3 Cấp độ (3-Tier Cancellation Status DEC-06/07)</h3>
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
                    <div>
                        <span class="text-[#8C8477] block text-[10px] uppercase font-semibold">Yêu cầu hủy từ người mua:</span>
                        @if($order->cancellation_requested)
                            <span class="inline-block mt-0.5 px-2 py-0.5 rounded text-[10px] font-bold bg-[#F8E8E8] text-[#8B3A3A]">
                                Đang có yêu cầu hủy (Chờ người bán duyệt)
                            </span>
                            @if($order->cancellation_request_reason)
                                <p class="text-[11px] text-[#6E675F] mt-1">Lý do yêu cầu: <strong>{{ $order->cancellation_request_reason }}</strong></p>
                            @endif
                        @else
                            <span class="inline-block mt-0.5 px-2 py-0.5 rounded text-[10px] font-medium bg-[#F2ECE1] text-[#6E675F]">
                                Không có yêu cầu đang chờ
                            </span>
                        @endif
                    </div>
                    <div>
                        <span class="text-[#8C8477] block text-[10px] uppercase font-semibold">Kết quả hủy đơn:</span>
                        @if($order->cancelled_at)
                            <span class="inline-block mt-0.5 px-2 py-0.5 rounded text-[10px] font-bold bg-[#8B3A3A] text-white">
                                Đã hủy lúc {{ $order->cancelled_at->format('d/m/Y H:i') }}
                            </span>
                            <p class="text-[11px] text-[#6E675F] mt-1">
                                Hủy bởi vai trò: <strong class="text-[#2C2E2A]">{{ $order->cancelled_by_role ?? 'SYSTEM' }}</strong>
                            </p>
                            <p class="text-[11px] text-[#6E675F]">
                                Lý do: <strong>{{ $order->cancel_reason ?? 'N/A' }}</strong>
                            </p>
                        @else
                            <span class="inline-block mt-0.5 px-2 py-0.5 rounded text-[10px] font-medium bg-[#EAF2ED] text-[#2D5A3C]">
                                Đơn hàng đang duy trì hợp lệ
                            </span>
                        @endif
                    </div>
                </div>
            </div>
        </div>

        <!-- RIGHT: Parties, Address Snapshot, Timestamps (1 col) -->
        <div class="space-y-6">
            <!-- BUYER PROFILE CARD -->
            <div class="bg-white p-5 rounded-lg border border-[#E0D7C7] shadow-sm text-xs space-y-2">
                <span class="text-[10px] uppercase font-bold text-[#8C8477] tracking-wider">Thông tin Khách mua (Buyer)</span>
                <p class="font-bold text-sm text-[#2C2E2A]">{{ $order->buyer->full_name ?? 'N/A' }}</p>
                <p class="text-[#6E675F]">{{ $order->buyer->email ?? '' }}</p>
                <p class="text-[#8C8477]">SĐT: {{ $order->buyer->phone_number ?? 'Chưa cập nhật' }}</p>
                <p class="text-[11px] text-[#8C8477]">User ID: <span class="font-mono">#{{ $order->buyer_id }}</span></p>
            </div>

            <!-- SELLER PROFILE CARD -->
            <div class="bg-white p-5 rounded-lg border border-[#E0D7C7] shadow-sm text-xs space-y-2">
                <span class="text-[10px] uppercase font-bold text-[#8C8477] tracking-wider">Thông tin Người bán (Seller)</span>
                <p class="font-bold text-sm text-[#2C2E2A]">{{ $order->seller->full_name ?? 'N/A' }}</p>
                <p class="text-[#6E675F]">{{ $order->seller->email ?? '' }}</p>
                <p class="text-[#8C8477]">SĐT: {{ $order->seller->phone_number ?? 'Chưa cập nhật' }}</p>
                @if($order->seller?->sellerProfile)
                    <div class="pt-2 border-t border-[#F2ECE1] space-y-1">
                        <p class="font-medium text-[#2C2E2A]">Shop: {{ $order->seller->sellerProfile->shop_name ?? 'N/A' }}</p>
                        <p class="text-[11px] text-[#84664C]">
                            Escrow đang giữ: <strong class="font-mono">{{ number_format((float) $order->seller->sellerProfile->escrow_held_balance) }} đ</strong>
                        </p>
                    </div>
                @endif
            </div>

            <!-- SHIPPING ADDRESS SNAPSHOT CARD -->
            <div class="bg-white p-5 rounded-lg border border-[#E0D7C7] shadow-sm text-xs space-y-2">
                <div class="flex items-center justify-between">
                    <span class="text-[10px] uppercase font-bold text-[#8C8477] tracking-wider">Địa chỉ Giao hàng Snapshot</span>
                    <span class="text-[9px] font-mono px-1.5 py-0.2 rounded bg-[#FAF7F2] text-[#8C8477]">Snapshot</span>
                </div>
                @php
                    $addr = $order->shipping_address_snapshot ?? [];
                @endphp
                @if(!empty($addr))
                    <p class="font-bold text-[#2C2E2A]">{{ $addr['recipient_name'] ?? 'N/A' }}</p>
                    <p class="text-[#6E675F]">SĐT: {{ $addr['phone_number'] ?? 'N/A' }}</p>
                    <p class="text-[#2C2E2A] leading-relaxed">
                        {{ $addr['street_address'] ?? '' }}, {{ $addr['ward'] ?? '' }}, {{ $addr['district'] ?? '' }}, {{ $addr['city_province'] ?? '' }}
                    </p>
                @else
                    <p class="text-[#8C8477] italic">Không có snapshot địa chỉ giao hàng.</p>
                @endif
            </div>

            <!-- ORDER TIMESTAMPS MILESTONES -->
            <div class="bg-white p-5 rounded-lg border border-[#E0D7C7] shadow-sm text-xs space-y-2">
                <span class="text-[10px] uppercase font-bold text-[#8C8477] tracking-wider">Mốc Thời gian Vận hành</span>
                <div class="space-y-1.5 pt-1 text-[11px]">
                    <div class="flex justify-between">
                        <span class="text-[#8C8477]">Tạo đơn:</span>
                        <span class="font-mono">{{ $order->created_at->format('d/m/Y H:i') }}</span>
                    </div>
                    @if($order->payment_expires_at)
                        <div class="flex justify-between">
                            <span class="text-[#8C8477]">Hạn thanh toán:</span>
                            <span class="font-mono">{{ $order->payment_expires_at->format('d/m/Y H:i') }}</span>
                        </div>
                    @endif
                    @if($order->paid_at)
                        <div class="flex justify-between">
                            <span class="text-[#2D5A3C] font-semibold">Đã thanh toán:</span>
                            <span class="font-mono text-[#2D5A3C]">{{ $order->paid_at->format('d/m/Y H:i') }}</span>
                        </div>
                    @endif
                    @if($order->shipped_at)
                        <div class="flex justify-between">
                            <span class="text-[#8C8477]">Đã gửi hàng:</span>
                            <span class="font-mono">{{ $order->shipped_at->format('d/m/Y H:i') }}</span>
                        </div>
                    @endif
                    @if($order->delivered_at)
                        <div class="flex justify-between">
                            <span class="text-[#8C8477]">Đã giao:</span>
                            <span class="font-mono">{{ $order->delivered_at->format('d/m/Y H:i') }}</span>
                        </div>
                    @endif
                    @if($order->auto_complete_at)
                        <div class="flex justify-between">
                            <span class="text-[#84664C]">Tự động hoàn tất:</span>
                            <span class="font-mono">{{ $order->auto_complete_at->format('d/m/Y H:i') }}</span>
                        </div>
                    @endif
                    @if($order->completed_at)
                        <div class="flex justify-between font-bold">
                            <span class="text-[#2D5A3C]">Hoàn tất:</span>
                            <span class="font-mono text-[#2D5A3C]">{{ $order->completed_at->format('d/m/Y H:i') }}</span>
                        </div>
                    @endif
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
