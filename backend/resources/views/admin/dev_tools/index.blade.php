@extends('layouts.admin')

@section('title', 'Developer Tools & Manual Job Triggers - Retro Market Admin')

@section('content')
<div class="space-y-6">
    <!-- Breadcrumb & Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <nav class="flex items-center space-x-2 text-xs text-[#8C8477] mb-1">
                <a href="{{ route('admin.dashboard') }}" class="hover:underline">Quản trị</a>
                <span>&rsaquo;</span>
                <span class="text-[#2C2E2A] font-medium">Developer Tools</span>
            </nav>
            <h1 class="text-2xl font-serif font-bold text-[#2C2E2A]">Công cụ Trình diễn Đồ án (Developer Tools)</h1>
            <p class="text-xs text-[#6E675F]">Kích hoạt thủ công 4 Background Jobs định kỳ và kiểm chứng tính lũy đẳng trong môi trường Demo Mode (A-DT-01).</p>
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

    <!-- Dual-Gate Status Banner -->
    <div class="p-4 bg-[#F4EBDD] border border-[#C5A66B] rounded-lg shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div class="flex items-center gap-3">
            <span class="w-10 h-10 rounded-full bg-[#84664C] text-white flex items-center justify-center font-bold">
                ⚡
            </span>
            <div>
                <div class="flex items-center gap-2">
                    <h3 class="text-sm font-bold font-serif text-[#2C2E2A]">DUAL-GATE SECURITY: DEMO MODE ACTIVE</h3>
                    <span class="px-2 py-0.5 rounded text-[10px] font-bold bg-[#2D5A3C] text-white">
                        DEMO_MODE=true
                    </span>
                </div>
                <p class="text-xs text-[#6E675F] mt-0.5">
                    Hệ thống đang cấu hình các mốc thời gian rút gọn (2 phút / 30 giây) phục vụ hội đồng chấm đồ án theo ADR-05.
                </p>
            </div>
        </div>

        <div class="flex flex-wrap gap-2 text-xs">
            <div class="bg-white px-3 py-1.5 rounded border border-[#E0D7C7]">
                <span class="text-[#8C8477] text-[10px] block">Hạn thanh toán đấu giá</span>
                <strong class="font-mono text-[#84664C]">{{ $demoTimers['auction_payment_demo'] }}s (2m)</strong>
                <span class="text-[10px] text-gray-400">/ Prod {{ $demoTimers['auction_payment_prod'] }}s</span>
            </div>
            <div class="bg-white px-3 py-1.5 rounded border border-[#E0D7C7]">
                <span class="text-[#8C8477] text-[10px] block">Hạn hoàn tất đơn hàng</span>
                <strong class="font-mono text-[#84664C]">{{ $demoTimers['auto_complete_demo'] }}s (2m)</strong>
                <span class="text-[10px] text-gray-400">/ Prod 24h</span>
            </div>
            <div class="bg-white px-3 py-1.5 rounded border border-[#E0D7C7]">
                <span class="text-[#8C8477] text-[10px] block">Khung chống bắn tỉa</span>
                <strong class="font-mono text-[#84664C]">{{ $demoTimers['anti_sniping_demo'] }}s</strong>
                <span class="text-[10px] text-gray-400">/ Prod 120s</span>
            </div>
        </div>
    </div>

    <!-- Job Result Output Box (if triggered) -->
    @if(session('job_result'))
        <div class="bg-white p-4 rounded-lg border border-[#2D5A3C] shadow-sm animate-fadeIn">
            <h4 class="text-xs font-bold uppercase tracking-wider text-[#2D5A3C] mb-2 flex items-center gap-1.5">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                <span>Kết quả Thực thi Tác vụ vừa kích hoạt</span>
            </h4>
            <pre class="p-3 bg-gray-50 rounded text-xs font-mono text-[#2C2E2A] overflow-x-auto">{{ json_encode(session('job_result'), JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) }}</pre>
        </div>
    @endif

    <!-- Jobs Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        @foreach($jobs as $key => $job)
            @php
                $isBatch = ($key === 'RUN_ALL_LIFECYCLE_JOBS');
            @endphp
            <div class="bg-white rounded-lg border border-[#E0D7C7] p-5 shadow-sm flex flex-col justify-between {{ $isBatch ? 'md:col-span-2 border-2 border-[#84664C] bg-[#FAF8F5]' : '' }}">
                <div>
                    <div class="flex items-center justify-between gap-2 mb-2">
                        <span class="px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider {{ $isBatch ? 'bg-[#84664C] text-white' : 'bg-gray-100 text-[#6E675F]' }}">
                            {{ $job['badge'] }}
                        </span>
                        <span class="text-[10px] font-mono text-[#8C8477]">{{ $key }}</span>
                    </div>
                    <h3 class="text-base font-serif font-bold text-[#2C2E2A] mb-1">{{ $job['name'] }}</h3>
                    <p class="text-xs text-[#6E675F] leading-relaxed mb-3">{{ $job['description'] }}</p>
                    <div class="text-[11px] font-mono text-[#8C8477] bg-gray-50 p-2 rounded border border-gray-200 truncate">
                        Target: {{ $job['target'] }}
                    </div>
                </div>

                <div class="pt-4 mt-4 border-t border-[#E0D7C7] flex justify-end">
                    <form method="POST" action="{{ route('admin.dev_tools.trigger') }}">
                        @csrf
                        <input type="hidden" name="action_key" value="{{ $key }}">
                        <button type="submit"
                                onclick="return confirm('Kích hoạt thủ công tác vụ [{{ $key }}]?')"
                                class="px-4 py-2 {{ $isBatch ? 'bg-[#2D5A3C] hover:bg-[#234730] text-sm' : 'bg-[#84664C] hover:bg-[#6E543E] text-xs' }} text-white font-bold rounded-md shadow-sm transition-colors flex items-center gap-1.5">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                            <span>{{ $isBatch ? 'KÍCH HOẠT TẤT CẢ 4 CHU TRÌNH' : 'Kích hoạt Ngay' }}</span>
                        </button>
                    </form>
                </div>
            </div>
        @endforeach
    </div>

    <!-- Recent Triggers Audit Log -->
    <div class="bg-white rounded-lg border border-[#E0D7C7] shadow-sm overflow-hidden">
        <div class="p-4 bg-[#F8F5F0] border-b border-[#E0D7C7] flex items-center justify-between">
            <h3 class="text-sm font-serif font-bold text-[#2C2E2A]">Nhật ký Kích hoạt Gần đây (Manual Job Trigger History)</h3>
            <span class="text-xs text-[#8C8477]">Audit Logs: DEVTOOLS_MANUAL_JOB_TRIGGER</span>
        </div>
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse text-xs">
                <thead>
                    <tr class="bg-[#FAF8F5] border-b border-[#E0D7C7] text-[#8C8477] uppercase text-[10px]">
                        <th class="py-2.5 px-4">Thời gian</th>
                        <th class="py-2.5 px-4">Quản trị viên</th>
                        <th class="py-2.5 px-4">Tác vụ kích hoạt</th>
                        <th class="py-2.5 px-4">Diễn giải</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#E0D7C7]">
                    @forelse($recentTriggers as $trig)
                        <tr class="hover:bg-[#FAF8F5]">
                            <td class="py-2.5 px-4 font-mono text-[#8C8477]">{{ $trig->created_at->format('d/m/Y H:i:s') }}</td>
                            <td class="py-2.5 px-4 font-medium text-[#2C2E2A]">{{ $trig->actor?->display_name ?? 'Admin' }}</td>
                            <td class="py-2.5 px-4">
                                <span class="font-mono text-[11px] font-bold px-2 py-0.5 rounded bg-[#F0ECE1] text-[#84664C]">
                                    {{ $trig->reason }}
                                </span>
                            </td>
                            <td class="py-2.5 px-4 font-mono text-[11px] text-[#6E675F] max-w-md truncate">
                                {{ json_encode($trig->new_values) }}
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="4" class="py-4 text-center text-[#8C8477] italic">Chưa có lịch sử kích hoạt thủ công nào.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
