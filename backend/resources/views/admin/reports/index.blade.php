@extends('layouts.admin')

@section('title', 'Quản lý Báo cáo Vi phạm - Retro Market Admin')

@section('content')
<div class="space-y-6">
    <!-- Breadcrumb & Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <nav class="flex items-center space-x-2 text-xs text-[#8C8477] mb-1">
                <a href="{{ route('admin.dashboard') }}" class="hover:underline">Quản trị</a>
                <span>&rsaquo;</span>
                <span class="text-[#2C2E2A] font-medium">Báo cáo Vi phạm</span>
            </nav>
            <h1 class="text-2xl font-serif font-bold text-[#2C2E2A]">Quản lý Báo cáo Vi phạm (Violation Reports)</h1>
            <p class="text-xs text-[#6E675F]">Tiếp nhận, thẩm tra nội dung vi phạm và áp dụng chế tài xử phạt theo quy chế sàn (A-CM-01).</p>
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
    @if($errors->any())
        <div class="p-4 bg-[#FBEAEB] border-l-4 border-[#8B3A3A] text-[#8B3A3A] rounded-r-md text-sm font-medium shadow-sm">
            <ul class="list-disc pl-5 space-y-1">
                @foreach($errors->all() as $err)
                    <li>{{ $err }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <!-- Metrics Cards -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#8C8477] uppercase tracking-wider">Tổng số báo cáo</span>
            <p class="text-2xl font-bold font-serif text-[#2C2E2A] mt-1">{{ number_format($stats['total']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#8B3A3A] uppercase tracking-wider">Đang chờ xử lý (Pending)</span>
            <p class="text-2xl font-bold font-serif text-[#8B3A3A] mt-1">{{ number_format($stats['pending']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#2D5A3C] uppercase tracking-wider">Đã xử lý & Xử phạt</span>
            <p class="text-2xl font-bold font-serif text-[#2D5A3C] mt-1">{{ number_format($stats['resolved']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#6E675F] uppercase tracking-wider">Đã bác bỏ (Dismissed)</span>
            <p class="text-2xl font-bold font-serif text-[#6E675F] mt-1">{{ number_format($stats['dismissed']) }}</p>
        </div>
    </div>

    <!-- Filter & Search Toolbar -->
    <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
        <form method="GET" action="{{ route('admin.moderation.reports.index') }}" class="flex flex-col md:flex-row gap-3">
            <div class="flex-1 relative">
                <input type="text" name="search" value="{{ request('search') }}"
                       placeholder="Tìm theo ID, mô tả, người báo cáo..."
                       class="w-full pl-9 pr-4 py-2 border border-[#E0D7C7] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#84664C]">
                <svg class="w-4 h-4 text-[#8C8477] absolute left-3 top-2.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                </svg>
            </div>

            <div class="w-full md:w-44">
                <select name="status" class="w-full py-2 px-3 border border-[#E0D7C7] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#84664C]">
                    <option value="">Tất cả trạng thái</option>
                    <option value="PENDING" {{ request('status') === 'PENDING' ? 'selected' : '' }}>Chờ xử lý (PENDING)</option>
                    <option value="RESOLVED_ACTION_TAKEN" {{ request('status') === 'RESOLVED_ACTION_TAKEN' ? 'selected' : '' }}>Đã xử phạt</option>
                    <option value="DISMISSED" {{ request('status') === 'DISMISSED' ? 'selected' : '' }}>Đã bác bỏ</option>
                </select>
            </div>

            <div class="w-full md:w-44">
                <select name="target_type" class="w-full py-2 px-3 border border-[#E0D7C7] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#84664C]">
                    <option value="">Tất cả đối tượng</option>
                    <option value="PRODUCT" {{ request('target_type') === 'PRODUCT' ? 'selected' : '' }}>Sản phẩm (PRODUCT)</option>
                    <option value="USER" {{ request('target_type') === 'USER' ? 'selected' : '' }}>Người dùng (USER)</option>
                    <option value="CONVERSATION" {{ request('target_type') === 'CONVERSATION' ? 'selected' : '' }}>Tin nhắn (CONVERSATION)</option>
                </select>
            </div>

            <div class="w-full md:w-44">
                <select name="reason_category" class="w-full py-2 px-3 border border-[#E0D7C7] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#84664C]">
                    <option value="">Tất cả lý do</option>
                    <option value="PROHIBITED_ITEM" {{ request('reason_category') === 'PROHIBITED_ITEM' ? 'selected' : '' }}>Hàng cấm</option>
                    <option value="COUNTERFEIT" {{ request('reason_category') === 'COUNTERFEIT' ? 'selected' : '' }}>Hàng giả / Nhái</option>
                    <option value="SCAM" {{ request('reason_category') === 'SCAM' ? 'selected' : '' }}>Lừa đảo</option>
                    <option value="HARASSMENT" {{ request('reason_category') === 'HARASSMENT' ? 'selected' : '' }}>Quấy rối / Đe dọa</option>
                    <option value="OFF_PLATFORM_TRANSACTION" {{ request('reason_category') === 'OFF_PLATFORM_TRANSACTION' ? 'selected' : '' }}>Giao dịch ngoài sàn</option>
                    <option value="OTHER" {{ request('reason_category') === 'OTHER' ? 'selected' : '' }}>Khác</option>
                </select>
            </div>

            <div class="flex gap-2">
                <button type="submit" class="px-4 py-2 bg-[#84664C] text-white rounded-md text-sm font-medium hover:bg-[#6E543E] transition-colors">
                    Lọc
                </button>
                @if(request()->anyFilled(['search', 'status', 'target_type', 'reason_category']))
                    <a href="{{ route('admin.moderation.reports.index') }}" class="px-3 py-2 bg-gray-100 text-[#6E675F] rounded-md text-sm font-medium hover:bg-gray-200 transition-colors flex items-center justify-center">
                        Xóa lọc
                    </a>
                @endif
            </div>
        </form>
    </div>

    <!-- Reports Table -->
    <div class="bg-white rounded-lg border border-[#E0D7C7] shadow-sm overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse text-sm">
                <thead>
                    <tr class="bg-[#F8F5F0] border-b border-[#E0D7C7] text-[11px] font-semibold text-[#8C8477] uppercase tracking-wider">
                        <th class="py-3 px-4">ID</th>
                        <th class="py-3 px-4">Người báo cáo</th>
                        <th class="py-3 px-4">Đối tượng vi phạm</th>
                        <th class="py-3 px-4">Lý do & Nội dung</th>
                        <th class="py-3 px-4">Trạng thái</th>
                        <th class="py-3 px-4">Xử lý & Ghi chú</th>
                        <th class="py-3 px-4 text-right">Thao tác</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#E0D7C7]">
                    @forelse($reports as $report)
                        <tr class="hover:bg-[#FAF8F5] transition-colors">
                            <td class="py-3 px-4 font-mono font-medium text-[#2C2E2A]">#{{ $report->id }}</td>
                            <td class="py-3 px-4">
                                <div class="font-medium text-[#2C2E2A]">{{ $report->reporter?->full_name ?? 'N/A' }}</div>
                                <div class="text-xs text-[#8C8477]">{{ $report->reporter?->email }}</div>
                            </td>
                            <td class="py-3 px-4">
                                @php
                                    $targetBadgeClasses = match($report->target_type) {
                                        'PRODUCT' => 'bg-blue-50 text-blue-700 border-blue-200',
                                        'USER' => 'bg-purple-50 text-purple-700 border-purple-200',
                                        'CONVERSATION' => 'bg-amber-50 text-amber-700 border-amber-200',
                                        default => 'bg-gray-50 text-gray-700 border-gray-200',
                                    };
                                @endphp
                                <div class="flex items-center gap-2">
                                    <span class="inline-flex items-center px-2 py-0.5 rounded text-[11px] font-bold border {{ $targetBadgeClasses }}">
                                        {{ $report->target_type }}
                                    </span>
                                    <span class="font-mono text-xs text-[#2C2E2A]">ID: {{ $report->target_id }}</span>
                                </div>
                                @if($report->target_type === 'PRODUCT')
                                    <div class="mt-1">
                                        <a href="{{ route('admin.moderation.products.show', $report->target_id) }}" target="_blank" class="text-xs text-[#84664C] hover:underline flex items-center gap-0.5">
                                            <span>Xem trên sàn</span>
                                            <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path></svg>
                                        </a>
                                    </div>
                                @endif
                            </td>
                            <td class="py-3 px-4 max-w-xs">
                                <span class="inline-block px-1.5 py-0.5 text-[10px] font-medium bg-[#F0ECE1] text-[#84664C] rounded mb-1">
                                    {{ $report->reason_category }}
                                </span>
                                <p class="text-xs text-[#2C2E2A] line-clamp-2" title="{{ $report->description }}">{{ $report->description }}</p>
                                <span class="text-[10px] text-[#8C8477] mt-1 block">{{ $report->created_at->format('d/m/Y H:i') }}</span>
                            </td>
                            <td class="py-3 px-4">
                                @if($report->status === 'PENDING')
                                    <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-red-100 text-[#8B3A3A]">
                                        Chờ xử lý
                                    </span>
                                @elseif($report->status === 'RESOLVED_ACTION_TAKEN')
                                    <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-green-100 text-[#2D5A3C]">
                                        Đã xử phạt
                                    </span>
                                @elseif($report->status === 'DISMISSED')
                                    <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-gray-100 text-gray-700">
                                        Đã bác bỏ
                                    </span>
                                @endif
                            </td>
                            <td class="py-3 px-4 max-w-xs">
                                @if($report->handled_by)
                                    <div class="text-xs font-medium text-[#2C2E2A]">{{ $report->handler?->full_name ?? 'Staff #'.$report->handled_by }}</div>
                                    <div class="text-[10px] text-[#8C8477]">{{ $report->handled_at?->format('d/m/Y H:i') }}</div>
                                    @if($report->resolution_note)
                                        <p class="text-xs text-[#6E675F] italic mt-1 line-clamp-2" title="{{ $report->resolution_note }}">"{{ $report->resolution_note }}"</p>
                                    @endif
                                @else
                                    <span class="text-xs text-[#8C8477] italic">Chưa tiếp nhận</span>
                                @endif
                            </td>
                            <td class="py-3 px-4 text-right">
                                @if($report->status === 'PENDING')
                                    <button type="button"
                                            onclick="openResolveModal('{{ $report->id }}', '{{ $report->target_type }}', '{{ $report->target_id }}', '{{ addslashes($report->reason_category) }}')"
                                            class="inline-flex items-center px-3 py-1.5 bg-[#84664C] text-white rounded text-xs font-medium hover:bg-[#6E543E] transition-colors shadow-sm">
                                        Xử lý báo cáo
                                    </button>
                                @else
                                    <span class="text-xs text-[#8C8477] italic">Đã đóng</span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="py-8 text-center text-sm text-[#8C8477]">
                                Không có báo cáo vi phạm nào phù hợp với bộ lọc.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($reports->hasPages())
            <div class="p-4 border-t border-[#E0D7C7]">
                {{ $reports->links() }}
            </div>
        @endif
    </div>
</div>

<!-- Resolve Report Modal -->
<div id="resolveModal" class="fixed inset-0 z-50 hidden overflow-y-auto bg-black bg-opacity-40 flex items-center justify-center p-4">
    <div class="bg-white rounded-lg max-w-lg w-full border border-[#E0D7C7] shadow-xl overflow-hidden animate-fadeIn">
        <form id="resolveForm" method="POST" action="">
            @csrf
            <div class="p-5 border-b border-[#E0D7C7] bg-[#F8F5F0] flex items-center justify-between">
                <div>
                    <h3 class="text-base font-serif font-bold text-[#2C2E2A]">Xử lý Báo cáo Vi phạm</h3>
                    <p class="text-xs text-[#6E675F]" id="modalReportInfo">Báo cáo #</p>
                </div>
                <button type="button" onclick="closeResolveModal()" class="text-[#8C8477] hover:text-[#2C2E2A]">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                </button>
            </div>

            <div class="p-5 space-y-4">
                <div>
                    <label class="block text-xs font-bold uppercase tracking-wider text-[#2C2E2A] mb-2">Quyết định xử lý <span class="text-red-500">*</span></label>
                    <div class="grid grid-cols-2 gap-3">
                        <label class="flex items-center gap-2 p-3 border border-[#E0D7C7] rounded-md cursor-pointer hover:bg-[#FAF8F5]">
                            <input type="radio" name="status" value="RESOLVED_ACTION_TAKEN" checked class="text-[#84664C] focus:ring-[#84664C]">
                            <span class="text-xs font-semibold text-[#2D5A3C]">Đã xử lý & Xử phạt</span>
                        </label>
                        <label class="flex items-center gap-2 p-3 border border-[#E0D7C7] rounded-md cursor-pointer hover:bg-[#FAF8F5]">
                            <input type="radio" name="status" value="DISMISSED" class="text-[#84664C] focus:ring-[#84664C]">
                            <span class="text-xs font-semibold text-[#6E675F]">Bác bỏ (Dismissed)</span>
                        </label>
                    </div>
                </div>

                <div>
                    <label for="resolution_note" class="block text-xs font-bold uppercase tracking-wider text-[#2C2E2A] mb-1">
                        Ghi chú phân xử / Biện pháp chế tài <span class="text-red-500">*</span>
                    </label>
                    <textarea id="resolution_note" name="resolution_note" rows="4" required minlength="5" maxlength="1000"
                              placeholder="Nhập lý do bác bỏ hoặc nội dung biện pháp xử lý vi phạm đã thực hiện (tối thiểu 5 ký tự)..."
                              class="w-full p-3 border border-[#E0D7C7] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#84664C]"></textarea>
                    <p class="text-[11px] text-[#8C8477] mt-1">Ghi chú phân xử sẽ được ghi nhận vào nhật ký kiểm toán bất biến (Audit Logs) vĩnh viễn.</p>
                </div>
            </div>

            <div class="p-4 bg-[#F8F5F0] border-t border-[#E0D7C7] flex justify-end gap-2">
                <button type="button" onclick="closeResolveModal()" class="px-4 py-2 border border-[#E0D7C7] text-[#2C2E2A] rounded-md text-xs font-medium hover:bg-gray-100 transition-colors">
                    Hủy bỏ
                </button>
                <button type="submit" class="px-4 py-2 bg-[#84664C] text-white rounded-md text-xs font-bold hover:bg-[#6E543E] transition-colors shadow-sm">
                    Xác nhận Xử lý Báo cáo
                </button>
            </div>
        </form>
    </div>
</div>

<script>
    function openResolveModal(reportId, targetType, targetId, reasonCategory) {
        const modal = document.getElementById('resolveModal');
        const form = document.getElementById('resolveForm');
        const info = document.getElementById('modalReportInfo');

        form.action = `/admin/moderation/reports/${reportId}/resolve`;
        info.textContent = `Báo cáo #${reportId} • ${targetType} #${targetId} (${reasonCategory})`;

        modal.classList.remove('hidden');
    }

    function closeResolveModal() {
        const modal = document.getElementById('resolveModal');
        modal.classList.add('hidden');
    }
</script>
@endsection
