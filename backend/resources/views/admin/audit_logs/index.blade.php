@extends('layouts.admin')

@section('title', 'Nhật ký Kiểm toán Hệ thống - Retro Market Admin')

@section('content')
<div class="space-y-6">
    <!-- Breadcrumb & Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <nav class="flex items-center space-x-2 text-xs text-[#8C8477] mb-1">
                <a href="{{ route('admin.dashboard') }}" class="hover:underline">Quản trị</a>
                <span>&rsaquo;</span>
                <span class="text-[#2C2E2A] font-medium">Nhật ký Kiểm toán</span>
            </nav>
            <h1 class="text-2xl font-serif font-bold text-[#2C2E2A]">Nhật ký Kiểm toán Hoạt động Quản trị (Audit Logs)</h1>
            <p class="text-xs text-[#6E675F]">Sổ kiểm toán bất biến (Immutable Append-Only) ghi nhận 100% mọi thao tác quản trị nhạy cảm (A-AD-01).</p>
        </div>
    </div>

    <!-- Metrics Cards -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#8C8477] uppercase tracking-wider">Tổng bản ghi kiểm toán</span>
            <p class="text-2xl font-bold font-serif text-[#2C2E2A] mt-1">{{ number_format($stats['total']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#2D5A3C] uppercase tracking-wider">Phát sinh hôm nay</span>
            <p class="text-2xl font-bold font-serif text-[#2D5A3C] mt-1">{{ number_format($stats['today']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#84664C] uppercase tracking-wider">Nhân sự thực hiện</span>
            <p class="text-2xl font-bold font-serif text-[#84664C] mt-1">{{ number_format($stats['actors_count']) }}</p>
        </div>
        <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
            <span class="text-[11px] font-semibold text-[#C5A66B] uppercase tracking-wider">Số loại hành động</span>
            <p class="text-2xl font-bold font-serif text-[#C5A66B] mt-1">{{ number_format($stats['actions_count']) }}</p>
        </div>
    </div>

    <!-- Filter & Search Toolbar -->
    <div class="bg-white p-4 rounded-lg border border-[#E0D7C7] shadow-sm">
        <form method="GET" action="{{ route('admin.audit_logs.index') }}" class="grid grid-cols-1 md:grid-cols-5 gap-3">
            <div class="relative md:col-span-2">
                <input type="text" name="search" value="{{ request('search') }}"
                       placeholder="Tìm theo lý do, mã target_id, tên nhân viên..."
                       class="w-full pl-9 pr-4 py-2 border border-[#E0D7C7] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#84664C]">
                <svg class="w-4 h-4 text-[#8C8477] absolute left-3 top-2.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                </svg>
            </div>

            <div>
                <select name="action" class="w-full py-2 px-3 border border-[#E0D7C7] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#84664C]">
                    <option value="">Tất cả hành động (Action)</option>
                    @foreach($availableActions as $act)
                        <option value="{{ $act }}" {{ request('action') === $act ? 'selected' : '' }}>{{ $act }}</option>
                    @endforeach
                </select>
            </div>

            <div>
                <select name="target_type" class="w-full py-2 px-3 border border-[#E0D7C7] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#84664C]">
                    <option value="">Tất cả đối tượng (Target)</option>
                    @foreach($availableTargetTypes as $target)
                        <option value="{{ $target }}" {{ request('target_type') === $target ? 'selected' : '' }}>{{ $target }}</option>
                    @endforeach
                </select>
            </div>

            <div class="flex gap-2">
                <button type="submit" class="px-4 py-2 bg-[#84664C] text-white rounded-md text-sm font-medium hover:bg-[#6E543E] transition-colors flex-1">
                    Lọc
                </button>
                @if(request()->anyFilled(['search', 'action', 'target_type', 'date_from', 'date_to']))
                    <a href="{{ route('admin.audit_logs.index') }}" class="px-3 py-2 bg-gray-100 text-[#6E675F] rounded-md text-sm font-medium hover:bg-gray-200 transition-colors flex items-center justify-center">
                        Xóa
                    </a>
                @endif
            </div>
        </form>
    </div>

    <!-- Audit Logs Table -->
    <div class="bg-white rounded-lg border border-[#E0D7C7] shadow-sm overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse text-xs">
                <thead>
                    <tr class="bg-[#F8F5F0] border-b border-[#E0D7C7] text-[10px] font-semibold text-[#8C8477] uppercase tracking-wider">
                        <th class="py-3 px-4">ID</th>
                        <th class="py-3 px-4">Thời gian</th>
                        <th class="py-3 px-4">Người thực hiện (Actor)</th>
                        <th class="py-3 px-4">Hành động (Action)</th>
                        <th class="py-3 px-4">Đối tượng (Target)</th>
                        <th class="py-3 px-4">Lý do & Diễn giải</th>
                        <th class="py-3 px-4">IP Address</th>
                        <th class="py-3 px-4 text-right">Chi tiết</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#E0D7C7]">
                    @forelse($auditLogs as $log)
                        <tr class="hover:bg-[#FAF8F5] transition-colors">
                            <td class="py-3 px-4 font-mono font-medium text-[#2C2E2A]">#{{ $log->id }}</td>
                            <td class="py-3 px-4 font-mono text-[#8C8477]">
                                {{ $log->created_at->format('d/m/Y H:i:s') }}
                            </td>
                            <td class="py-3 px-4">
                                <div class="font-medium text-[#2C2E2A]">{{ $log->actor?->display_name ?? 'System DevTools' }}</div>
                                <span class="inline-block px-1.5 py-0.5 rounded text-[10px] font-semibold mt-0.5
                                    {{ $log->actor_role === 'admin' ? 'bg-red-50 text-red-700' : 'bg-gray-100 text-gray-700' }}">
                                    {{ strtoupper($log->actor_role) }}
                                </span>
                            </td>
                            <td class="py-3 px-4">
                                <span class="inline-block px-2 py-0.5 rounded font-mono text-[11px] font-bold bg-[#F0ECE1] text-[#84664C]">
                                    {{ $log->action }}
                                </span>
                            </td>
                            <td class="py-3 px-4">
                                <span class="font-semibold text-[#2C2E2A]">{{ $log->target_type }}</span>
                                @if($log->target_id)
                                    <span class="font-mono text-[#8C8477]">#{{ $log->target_id }}</span>
                                @endif
                            </td>
                            <td class="py-3 px-4 max-w-xs truncate" title="{{ $log->reason }}">
                                {{ $log->reason ?? '—' }}
                            </td>
                            <td class="py-3 px-4 font-mono text-[#8C8477]">
                                {{ $log->ip_address ?? '127.0.0.1' }}
                            </td>
                            <td class="py-3 px-4 text-right">
                                @if($log->old_values || $log->new_values)
                                    <button type="button"
                                            onclick='openDiffModal({{ $log->id }}, @json($log->old_values), @json($log->new_values))'
                                            class="inline-flex items-center px-2 py-1 bg-gray-100 text-[#2C2E2A] rounded text-[11px] font-semibold hover:bg-gray-200 transition-colors">
                                        Xem Diff
                                    </button>
                                @else
                                    <span class="text-[#8C8477] italic">—</span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="8" class="py-8 text-center text-sm text-[#8C8477]">
                                Không tìm thấy bản ghi kiểm toán nào phù hợp với bộ lọc.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($auditLogs->hasPages())
            <div class="p-4 border-t border-[#E0D7C7]">
                {{ $auditLogs->links() }}
            </div>
        @endif
    </div>
</div>

<!-- Diff Modal -->
<div id="diffModal" class="fixed inset-0 z-50 hidden overflow-y-auto bg-black bg-opacity-40 flex items-center justify-center p-4">
    <div class="bg-white rounded-lg max-w-2xl w-full border border-[#E0D7C7] shadow-xl overflow-hidden animate-fadeIn">
        <div class="p-4 border-b border-[#E0D7C7] bg-[#F8F5F0] flex items-center justify-between">
            <h3 class="text-sm font-serif font-bold text-[#2C2E2A]" id="diffModalTitle">Chi tiết Dữ liệu Thay đổi (Audit Diff)</h3>
            <button type="button" onclick="closeDiffModal()" class="text-[#8C8477] hover:text-[#2C2E2A]">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
            </button>
        </div>

        <div class="p-5 grid grid-cols-1 md:grid-cols-2 gap-4 text-xs font-mono">
            <div>
                <span class="block text-[11px] font-bold uppercase tracking-wider text-[#8B3A3A] mb-1">Giá trị cũ (Old Values)</span>
                <pre id="oldValuesPre" class="p-3 bg-red-50 border border-red-200 rounded text-red-900 overflow-x-auto max-h-80 whitespace-pre-wrap"></pre>
            </div>
            <div>
                <span class="block text-[11px] font-bold uppercase tracking-wider text-[#2D5A3C] mb-1">Giá trị mới (New Values)</span>
                <pre id="newValuesPre" class="p-3 bg-green-50 border border-green-200 rounded text-green-900 overflow-x-auto max-h-80 whitespace-pre-wrap"></pre>
            </div>
        </div>

        <div class="p-4 bg-[#F8F5F0] border-t border-[#E0D7C7] flex justify-end">
            <button type="button" onclick="closeDiffModal()" class="px-4 py-2 bg-[#84664C] text-white rounded text-xs font-bold hover:bg-[#6E543E]">
                Đóng
            </button>
        </div>
    </div>
</div>

<script>
    function openDiffModal(logId, oldVals, newVals) {
        document.getElementById('diffModalTitle').textContent = `Chi tiết Thay đổi Bản ghi Audit #${logId}`;
        document.getElementById('oldValuesPre').textContent = oldVals ? JSON.stringify(oldVals, null, 2) : '(Trống / Không có)';
        document.getElementById('newValuesPre').textContent = newVals ? JSON.stringify(newVals, null, 2) : '(Trống / Không có)';
        document.getElementById('diffModal').classList.remove('hidden');
    }

    function closeDiffModal() {
        document.getElementById('diffModal').classList.add('hidden');
    }
</script>
@endsection
