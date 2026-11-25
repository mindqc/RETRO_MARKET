@extends('layouts.admin')

@section('title', 'Hồ sơ Khiếu nại #' . $dispute->dispute_code . ' - Retro Market Admin')

@section('content')
@php
    $currentUser = auth('web')->user();
    $isAdmin = $currentUser && $currentUser->isAdmin();
    $st = $dispute->status instanceof \App\Enums\DisputeStatus ? $dispute->status : \App\Enums\DisputeStatus::tryFrom($dispute->status);
    $isResolved = ($st === \App\Enums\DisputeStatus::RESOLVED);
@endphp

<div class="space-y-6">
    <!-- Breadcrumb & Nav -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <nav class="flex items-center space-x-2 text-xs text-[#8C8477] mb-1">
                <a href="{{ route('admin.dashboard') }}" class="hover:underline">Quản trị</a>
                <span>&rsaquo;</span>
                <a href="{{ route('admin.disputes.index') }}" class="hover:underline">Tranh chấp & Khiếu nại</a>
                <span>&rsaquo;</span>
                <span class="text-[#2C2E2A] font-medium font-mono">{{ $dispute->dispute_code }}</span>
            </nav>
            <div class="flex items-center space-x-3">
                <h1 class="text-2xl font-serif font-bold text-[#2C2E2A]">Hồ sơ Xử lý Khiếu nại (Case Room)</h1>
                <span class="font-mono text-sm px-2 py-0.5 rounded bg-[#F2ECE1] text-[#2C2E2A] font-semibold">
                    {{ $dispute->dispute_code }}
                </span>
                @php
                    $badgeClass = match($st) {
                        \App\Enums\DisputeStatus::OPEN => 'bg-[#8B3A3A] text-white animate-pulse',
                        \App\Enums\DisputeStatus::NEED_MORE_INFO => 'bg-[#C85A32] text-white',
                        \App\Enums\DisputeStatus::RESOLVED => 'bg-[#2D5A3C] text-white',
                        default => 'bg-gray-500 text-white',
                    };
                @endphp
                <span class="px-2.5 py-0.5 rounded text-xs font-semibold uppercase tracking-wider {{ $badgeClass }}">
                    {{ $st?->value ?? $dispute->status }} - {{ $st?->label() }}
                </span>
            </div>
        </div>
        <div>
            <a href="{{ route('admin.disputes.index') }}"
               class="px-3 py-1.5 text-xs font-medium rounded border border-[#C5BCAB] bg-white text-[#2C2E2A] hover:bg-[#FAF7F2] transition-colors">
                &larr; Quay lại danh sách
            </a>
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

    <!-- FROZEN ESCROW FUNDS BANNER (DEC-03 / BR-DP-02) -->
    <div class="bg-[#FBEAEB] border border-[#8B3A3A] rounded-xl p-4 text-xs flex flex-col sm:flex-row sm:items-center justify-between gap-3 shadow-sm">
        <div class="flex items-center space-x-3">
            <span class="w-10 h-10 rounded-full bg-[#8B3A3A] text-white flex items-center justify-center shrink-0">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/>
                </svg>
            </span>
            <div>
                <span class="text-[10px] uppercase font-bold text-[#8B3A3A] tracking-wider block">QUỸ TIỀN TRUNG GIAN BỊ ĐÓNG BĂNG (FROZEN ESCROW FUNDS)</span>
                <p class="text-sm font-bold text-[#2C2E2A]">
                    Tiền hàng đóng băng: <span class="font-mono text-[#8B3A3A]">{{ number_format((float) ($dispute->order?->item_subtotal ?? 0)) }} đ</span>
                    <span class="text-[#8C8477] font-normal text-xs">(Tổng tiền thanh toán: {{ number_format((float) ($dispute->order?->total_amount ?? 0)) }} đ)</span>
                </p>
                <p class="text-[11px] text-[#6E675F]">
                    Theo quy tắc DEC-03 & BR-DP-02: Toàn bộ quy trình tự động giải ngân sau 24h bị vô hiệu hóa tuyệt đối cho đến khi có phán quyết từ Admin.
                </p>
            </div>
        </div>
        <div class="text-right">
            <span class="px-2.5 py-1 rounded text-[11px] font-bold bg-[#8B3A3A] text-white uppercase tracking-wider">
                FROZEN
            </span>
        </div>
    </div>

    <!-- SPLIT-PANE WORKBENCH (2 Columns) -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- LEFT PANE: Order Context, Parties, Reason (1 col) -->
        <div class="space-y-6">
            <!-- Order Context Card -->
            <div class="bg-white p-5 rounded-lg border border-[#E0D7C7] shadow-sm text-xs space-y-3">
                <div class="flex items-center justify-between border-b border-[#E0D7C7] pb-2">
                    <span class="text-[10px] uppercase font-bold text-[#8C8477]">Đơn hàng liên quan</span>
                    @if($dispute->order)
                        <a href="{{ route('admin.orders.show', $dispute->order_id) }}" class="font-mono font-bold text-[#2D5A3C] hover:underline">
                            #{{ $dispute->order->order_code }}
                        </a>
                    @endif
                </div>

                <div>
                    <span class="text-[#8C8477]">Lý do khiếu nại:</span>
                    <p class="font-bold text-[#84664C] text-sm mt-0.5">{{ $dispute->reason_category }}</p>
                </div>

                <div>
                    <span class="text-[#8C8477]">Mô tả từ Người mua:</span>
                    <p class="text-[#2C2E2A] bg-[#FAF7F2] p-2 rounded mt-1 border border-[#F2ECE1]">
                        {{ $dispute->buyer_description }}
                    </p>
                </div>

                <!-- Snapshot Item Thumbnail -->
                @if($dispute->order?->items?->first())
                    @php $item = $dispute->order->items->first(); @endphp
                    <div class="pt-2 border-t border-[#F2ECE1] flex items-center space-x-3">
                        <div class="w-12 h-12 rounded border border-[#E0D7C7] overflow-hidden bg-[#F2ECE1] shrink-0">
                            @if($item->primary_image_snapshot)
                                <img src="{{ $item->primary_image_snapshot }}" alt="{{ $item->product_title_snapshot }}" class="w-full h-full object-cover">
                            @else
                                <div class="w-full h-full flex items-center justify-center text-[10px] text-[#8C8477]">No Img</div>
                            @endif
                        </div>
                        <div class="min-w-0">
                            <p class="font-medium text-[#2C2E2A] truncate">{{ $item->product_title_snapshot }}</p>
                            <p class="text-[10px] text-[#8C8477]">Tình trạng: {{ $item->condition_snapshot }}</p>
                        </div>
                    </div>
                @endif
            </div>

            <!-- Parties Profile Card -->
            <div class="bg-white p-5 rounded-lg border border-[#E0D7C7] shadow-sm text-xs space-y-4">
                <div>
                    <span class="text-[10px] uppercase font-bold text-[#8C8477] tracking-wider block mb-1">Người khiếu nại (Buyer)</span>
                    <p class="font-bold text-[#2C2E2A]">{{ $dispute->buyer->full_name ?? 'N/A' }}</p>
                    <p class="text-[#6E675F]">{{ $dispute->buyer->email ?? '' }}</p>
                    <p class="text-[#8C8477]">SĐT: {{ $dispute->buyer->phone_number ?? 'N/A' }}</p>
                </div>
                <div class="pt-3 border-t border-[#F2ECE1]">
                    <span class="text-[10px] uppercase font-bold text-[#8C8477] tracking-wider block mb-1">Người bị khiếu nại (Seller)</span>
                    <p class="font-bold text-[#2C2E2A]">{{ $dispute->seller->full_name ?? 'N/A' }}</p>
                    <p class="text-[#6E675F]">{{ $dispute->seller->email ?? '' }}</p>
                    <p class="text-[#8C8477]">SĐT: {{ $dispute->seller->phone_number ?? 'N/A' }}</p>
                    @if($dispute->seller?->sellerProfile)
                        <p class="text-[11px] text-[#84664C] mt-1">
                            Escrow giữ: <strong class="font-mono">{{ number_format((float) $dispute->seller->sellerProfile->escrow_held_balance) }} đ</strong>
                        </p>
                    @endif
                </div>
            </div>

            <!-- Shipment Status -->
            @if($dispute->order?->shipment)
                <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm text-xs space-y-1">
                    <span class="text-[10px] uppercase font-bold text-[#8C8477]">Vận đơn giao hàng</span>
                    <p class="font-bold text-[#2C2E2A]">{{ $dispute->order->shipment->carrier_name }}</p>
                    <p class="font-mono text-[#2D5A3C] font-semibold">{{ $dispute->order->shipment->tracking_code }}</p>
                    <p class="text-[#8C8477] text-[11px]">Trạng thái: {{ $dispute->order->shipment->status }}</p>
                </div>
            @endif
        </div>

        <!-- RIGHT PANE: 2-Way Evidence Timeline & Action Forms (2 cols) -->
        <div class="lg:col-span-2 space-y-6">
            <!-- 2-WAY EVIDENCE INTERACTION TIMELINE -->
            <div class="bg-white rounded-lg border border-[#E0D7C7] shadow-sm overflow-hidden">
                <div class="px-5 py-4 border-b border-[#E0D7C7] bg-[#F8F5EE] flex items-center justify-between">
                    <div>
                        <h3 class="text-sm font-serif font-bold text-[#2C2E2A]">Dòng Thời gian Bằng chứng & Đối chất 2 Chiều</h3>
                        <p class="text-[11px] text-[#8C8477]">Ghi nhận toàn bộ bằng chứng chứng minh, lập luận phản hồi và yêu cầu từ đội ngũ hỗ trợ.</p>
                    </div>
                    <span class="text-[11px] text-[#8C8477] font-semibold">
                        {{ $dispute->evidences->count() }} bản ghi chứng cứ
                    </span>
                </div>

                <div class="p-5 space-y-4">
                    @forelse($dispute->evidences as $evidence)
                        @php
                            $isBuyerProof = ($evidence->evidence_type === 'BUYER_PROOF');
                            $isSellerProof = ($evidence->evidence_type === 'SELLER_COUNTER_PROOF');
                            $isStaffNote = ($evidence->evidence_type === 'STAFF_REQUEST_NOTE');

                            $cardBg = match($evidence->evidence_type) {
                                'BUYER_PROOF' => 'bg-[#FAF7F2] border-[#E0D7C7]',
                                'SELLER_COUNTER_PROOF' => 'bg-[#F4EFE6] border-[#D4C8B5]',
                                'STAFF_REQUEST_NOTE' => 'bg-[#EBF3F8] border-[#3B6E8C]/30',
                                default => 'bg-white border-gray-200',
                            };

                            $roleLabel = match($evidence->evidence_type) {
                                'BUYER_PROOF' => 'Người mua (Buyer)',
                                'SELLER_COUNTER_PROOF' => 'Người bán (Seller phản bác)',
                                'STAFF_REQUEST_NOTE' => 'Nhân viên Hỗ trợ / Quản trị viên (Staff Request)',
                                default => $evidence->uploader_role,
                            };
                        @endphp

                        <div class="p-4 rounded-lg border {{ $cardBg }} text-xs space-y-2">
                            <div class="flex items-center justify-between">
                                <div class="flex items-center space-x-2">
                                    <span class="font-bold text-[#2C2E2A]">{{ $roleLabel }}</span>
                                    <span class="text-[10px] text-[#8C8477]">({{ $evidence->uploader->full_name ?? 'N/A' }})</span>
                                </div>
                                <span class="font-mono text-[10px] text-[#8C8477]">
                                    {{ $evidence->created_at->format('d/m/Y H:i:s') }}
                                </span>
                            </div>

                            <p class="text-[#2C2E2A] leading-relaxed whitespace-pre-line">
                                {{ $evidence->message_note }}
                            </p>

                            @if($evidence->file_url)
                                <div class="pt-2">
                                    <a href="{{ $evidence->file_url }}" target="_blank" class="inline-flex items-center text-xs text-[#2D5A3C] font-semibold hover:underline">
                                        <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13"/>
                                        </svg>
                                        Xem tài liệu / Ảnh đính kèm &rsaquo;
                                    </a>
                                </div>
                            @endif
                        </div>
                    @empty
                        <p class="text-xs text-[#8C8477] italic py-4 text-center">Chưa có bản ghi bằng chứng đối chất nào.</p>
                    @endforelse
                </div>
            </div>

            <!-- ACTION WORKBENCH (SEPARATION OF DUTIES DEC-08-03) -->
            @if(!$isResolved)
                <!-- ACTION 1: REQUEST MORE INFO FORM (Support & Admin) -->
                <div class="bg-white rounded-lg border border-[#E0D7C7] shadow-sm p-5 space-y-3">
                    <div class="flex items-center justify-between border-b border-[#E0D7C7] pb-2">
                        <div class="flex items-center space-x-2">
                            <svg class="w-4 h-4 text-[#3B6E8C]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
                            </svg>
                            <h3 class="text-xs font-serif font-bold text-[#2C2E2A]">Yêu cầu Bổ sung Bằng chứng (STAFF_REQUEST_NOTE)</h3>
                        </div>
                        <span class="text-[10px] text-[#8C8477]">Dành cho: Support & Admin</span>
                    </div>

                    <form method="POST" action="{{ route('admin.disputes.request_info', $dispute->id) }}" class="space-y-3">
                        @csrf
                        <div>
                            <textarea name="message_note" rows="3" required placeholder="Nhập nội dung hướng dẫn yêu cầu người mua hoặc người bán cung cấp thêm bằng chứng chứng minh (ít nhất 5 ký tự)..."
                                      class="w-full p-2.5 text-xs border border-[#C5BCAB] rounded-md bg-[#FAF7F2] text-[#2C2E2A] focus:outline-none focus:ring-1 focus:ring-[#3B6E8C]"></textarea>
                        </div>
                        <div class="flex justify-end">
                            <button type="submit" class="px-4 py-2 text-xs font-semibold rounded bg-[#3B6E8C] text-white hover:bg-[#2F5770] transition-colors">
                                Gửi yêu cầu bổ sung &rarr; Chuyển sang NEED_MORE_INFO
                            </button>
                        </div>
                    </form>
                </div>

                <!-- ACTION 2: SUPREME FINANCIAL VERDICT (Admin Only - DEC-07 / DEC-08-03) -->
                @if($isAdmin)
                    <div class="bg-white rounded-lg border-2 border-[#8B3A3A] shadow-md overflow-hidden">
                        <div class="bg-[#8B3A3A] px-5 py-3 text-white flex items-center justify-between">
                            <div class="flex items-center space-x-2">
                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 6l3 1m0 0l-3 9a5.002 5.002 0 006.001 0M6 7l3 9M6 7l6-2m6 2l3-1m-3 1l-3 9a5.002 5.002 0 006.001 0M18 7l3 9m-3-9l-6-2m0-2v2m0 16V5m0 16H9m3 0h3"/>
                                </svg>
                                <h3 class="font-serif font-bold text-sm">Phán quyết Tài chính Tối cao (Supreme Admin Financial Verdict)</h3>
                            </div>
                            <span class="text-[10px] uppercase font-bold tracking-wider px-2 py-0.5 rounded bg-white text-[#8B3A3A]">
                                Admin Only (DEC-08-03)
                            </span>
                        </div>

                        <form method="POST" action="{{ route('admin.disputes.verdict', $dispute->id) }}" class="p-5 space-y-4 text-xs">
                            @csrf
                            <div>
                                <label class="block font-bold text-[#2C2E2A] mb-1">Lựa chọn Phán quyết Tài chính <span class="text-[#8B3A3A]">*</span></label>
                                <div class="space-y-2">
                                    <label class="flex items-start space-x-2 p-2.5 rounded border border-[#E0D7C7] hover:bg-[#FAF7F2] cursor-pointer">
                                        <input type="radio" name="verdict" value="APPROVE_BUYER_REFUND" class="mt-0.5 text-[#8B3A3A]" required checked>
                                        <div>
                                            <strong class="text-[#8B3A3A] block">1. APPROVE_BUYER_REFUND (Hoàn tiền 100% cho Người mua)</strong>
                                            <span class="text-[11px] text-[#6E675F]">
                                                Hoàn trả đầy đủ 100% tổng tiền thanh toán (bao gồm cả phí bảo vệ) cho Người mua theo chuẩn DEC-07. Hủy đơn và khấu trừ số dư ký quỹ của Người bán.
                                            </span>
                                        </div>
                                    </label>

                                    <label class="flex items-start space-x-2 p-2.5 rounded border border-[#E0D7C7] hover:bg-[#FAF7F2] cursor-pointer">
                                        <input type="radio" name="verdict" value="RELEASE_TO_SELLER" class="mt-0.5 text-[#2D5A3C]">
                                        <div>
                                            <strong class="text-[#2D5A3C] block">2. RELEASE_TO_SELLER (Bác bỏ khiếu nại & Giải ngân cho Người bán)</strong>
                                            <span class="text-[11px] text-[#6E675F]">
                                                Bác bỏ khiếu nại, mở khóa giải ngân 100% tiền hàng vào Ví khả dụng của Người bán theo chuẩn DEC-04. Hoàn tất đơn hàng.
                                            </span>
                                        </div>
                                    </label>

                                    <label class="flex items-start space-x-2 p-2.5 rounded border border-[#E0D7C7] hover:bg-[#FAF7F2] cursor-pointer">
                                        <input type="radio" name="verdict" value="PARTIAL_REFUND" class="mt-0.5 text-[#3B6E8C]">
                                        <div class="flex-1">
                                            <strong class="text-[#3B6E8C] block">3. PARTIAL_REFUND (Hoàn tiền một phần theo thỏa thuận BR-FN-06)</strong>
                                            <span class="text-[11px] text-[#6E675F] block mb-2">
                                                Hoàn một phần tiền hàng cho Người mua; phần tiền hàng còn lại giải ngân vào Ví của Người bán.
                                            </span>
                                            <div>
                                                <label class="block text-[10px] uppercase font-bold text-[#8C8477]">Số tiền hoàn cho Người mua (VNĐ):</label>
                                                <input type="number" name="partial_refund_to_buyer" step="1000" min="1000"
                                                       placeholder="Nhập số tiền hoàn (VD: 100000)..."
                                                       class="w-full max-w-xs mt-1 p-1.5 border border-[#C5BCAB] rounded text-xs font-mono">
                                            </div>
                                        </div>
                                    </label>
                                </div>
                            </div>

                            <div>
                                <label class="block font-bold text-[#2C2E2A] mb-1">Căn cứ Phán quyết (Resolution Note) <span class="text-[#8B3A3A]">*</span></label>
                                <textarea name="resolution_note" rows="3" required placeholder="Nhập căn cứ chứng cứ, biên bản phân xử của Quản trị viên (ít nhất 5 ký tự)..."
                                          class="w-full p-2.5 text-xs border border-[#C5BCAB] rounded-md bg-[#FAF7F2] text-[#2C2E2A] focus:outline-none focus:ring-1 focus:ring-[#8B3A3A]"></textarea>
                            </div>

                            <div class="flex justify-end pt-2">
                                <button type="submit" class="px-5 py-2.5 text-xs font-bold rounded bg-[#8B3A3A] text-white hover:bg-[#6D2E2E] transition-colors shadow">
                                    Thực thi Phán quyết Tài chính (Execute Financial Verdict)
                                </button>
                            </div>
                        </form>
                    </div>
                @else
                    <!-- Separation of Duties Notice for Support / Moderator -->
                    <div class="bg-[#F2ECE1] p-4 rounded-lg border border-[#C5BCAB] text-xs text-[#6E675F] space-y-1">
                        <strong class="text-[#2C2E2A] block font-serif">Nguyên tắc Phân định Trách nhiệm (Separation of Duties DEC-08-03):</strong>
                        <p>
                            Bạn đang đăng nhập với vai trò <strong>{{ $currentUser->role->value ?? 'SUPPORT' }}</strong>. Bạn có thẩm quyền xem xét chứng cứ và gửi yêu cầu bổ sung bằng chứng (STAFF_REQUEST_NOTE).
                        </p>
                        <p class="text-[#84664C]">
                            Thẩm quyền ra Phán quyết tài chính cuối cùng (hoàn tiền hoặc giải ngân) thuộc về duy nhất vai trò <strong>Admin</strong> để đảm bảo an toàn quỹ Escrow.
                        </p>
                    </div>
                @endif
            @else
                <!-- RESOLVED VERDICT STAMP -->
                <div class="bg-[#EAF2ED] rounded-lg border-2 border-[#2D5A3C] p-5 text-xs space-y-3">
                    <div class="flex items-center justify-between border-b border-[#2D5A3C]/30 pb-2">
                        <div class="flex items-center space-x-2">
                            <span class="w-6 h-6 rounded-full bg-[#2D5A3C] text-white flex items-center justify-center font-bold text-xs">&#10003;</span>
                            <h3 class="font-serif font-bold text-sm text-[#2D5A3C]">Khiếu nại Đã có Phán quyết Chính thức</h3>
                        </div>
                        <span class="font-mono text-[#8C8477]">
                            Thời điểm: {{ $dispute->resolved_at ? $dispute->resolved_at->format('d/m/Y H:i:s') : 'N/A' }}
                        </span>
                    </div>

                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <div>
                            <span class="text-[10px] uppercase font-bold text-[#8C8477]">Phán quyết của Admin:</span>
                            <p class="font-mono font-bold text-[#2D5A3C] text-sm mt-0.5">{{ $dispute->admin_verdict }}</p>
                            @if($dispute->admin_verdict === 'PARTIAL_REFUND')
                                <p class="text-[11px] text-[#3B6E8C] font-mono mt-0.5">
                                    Hoàn người mua: {{ number_format((float) $dispute->partial_refund_to_buyer) }} đ
                                </p>
                            @endif
                        </div>
                        <div>
                            <span class="text-[10px] uppercase font-bold text-[#8C8477]">Quản trị viên phân xử:</span>
                            <p class="font-bold text-[#2C2E2A] mt-0.5">{{ $dispute->resolvedByAdmin->full_name ?? 'Admin' }}</p>
                            <p class="text-[10px] text-[#8C8477]">{{ $dispute->resolvedByAdmin->email ?? '' }}</p>
                        </div>
                    </div>

                    <div class="pt-2 border-t border-[#2D5A3C]/20">
                        <span class="text-[10px] uppercase font-bold text-[#8C8477] block mb-1">Ghi chú phán quyết:</span>
                        <p class="text-[#2C2E2A] bg-white p-3 rounded border border-[#2D5A3C]/30 leading-relaxed font-medium">
                            {{ $dispute->resolution_note ?? 'Không có ghi chú.' }}
                        </p>
                    </div>
                </div>
            @endif
        </div>
    </div>
</div>
@endsection
