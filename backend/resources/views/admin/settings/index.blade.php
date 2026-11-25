@extends('layouts.admin')

@section('title', 'Cấu hình Nền tảng - Retro Market Admin')

@section('content')
<div class="space-y-6">
    <!-- Breadcrumb & Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <nav class="flex items-center space-x-2 text-xs text-[#8C8477] mb-1">
                <a href="{{ route('admin.dashboard') }}" class="hover:underline">Quản trị</a>
                <span>&rsaquo;</span>
                <span class="text-[#2C2E2A] font-medium">Cấu hình Nền tảng</span>
            </nav>
            <h1 class="text-2xl font-serif font-bold text-[#2C2E2A]">Cấu hình Nền tảng Hệ thống (Platform Settings)</h1>
            <p class="text-xs text-[#6E675F]">Thiết lập các tham số tài chính DEC-04, khung giờ chống bắn tỉa đấu giá và thời hạn tự động giải ngân (A-ST-01).</p>
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

    <form method="POST" action="{{ route('admin.settings.update') }}" class="space-y-6">
        @csrf

        @foreach($groups as $groupKey => $group)
            <div class="bg-white rounded-lg border border-[#E0D7C7] p-5 shadow-sm">
                <div class="border-b border-[#E0D7C7] pb-3 mb-4">
                    <h2 class="text-base font-serif font-bold text-[#2C2E2A]">{{ $group['title'] }}</h2>
                    <p class="text-xs text-[#6E675F]">{{ $group['description'] }}</p>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    @foreach($group['keys'] as $k)
                        @php
                            $setting = $allSettings[$k] ?? null;
                            $isReadOnly = in_array($k, ['shipping_fee_default', 'seller_commission_rate'], true);
                        @endphp
                        @if($setting)
                            <div class="p-3.5 bg-[#FAF8F5] rounded-md border border-[#E0D7C7]">
                                <div class="flex items-start justify-between gap-2 mb-1.5">
                                    <label for="setting_{{ $k }}" class="font-mono text-xs font-bold text-[#2C2E2A]">
                                        {{ $k }}
                                    </label>
                                    <span class="text-[10px] font-mono px-1.5 py-0.5 rounded bg-gray-200 text-[#6E675F]">
                                        {{ $setting->value_type }}
                                    </span>
                                </div>
                                <p class="text-[11px] text-[#6E675F] mb-2 leading-relaxed">{{ $setting->description }}</p>

                                <div>
                                    @if($k === 'protection_fee_rate')
                                        <div class="relative">
                                            <input type="number" step="0.0001" min="0.05" max="0.08" id="setting_{{ $k }}"
                                                   name="settings[{{ $k }}]" value="{{ old("settings.{$k}", $setting->value) }}"
                                                   required
                                                   class="w-full p-2 border border-[#E0D7C7] rounded text-sm font-mono focus:outline-none focus:ring-1 focus:ring-[#84664C]">
                                            <span class="text-xs text-[#8C8477] absolute right-3 top-2.5">x 100% (5% - 8%)</span>
                                        </div>
                                    @elseif($k === 'protection_fixed_fee')
                                        <div class="relative">
                                            <input type="number" step="100" min="5000" max="10000" id="setting_{{ $k }}"
                                                   name="settings[{{ $k }}]" value="{{ old("settings.{$k}", $setting->value) }}"
                                                   required
                                                   class="w-full p-2 border border-[#E0D7C7] rounded text-sm font-mono focus:outline-none focus:ring-1 focus:ring-[#84664C]">
                                            <span class="text-xs text-[#8C8477] absolute right-3 top-2.5">VND (5k - 10k)</span>
                                        </div>
                                    @elseif($isReadOnly)
                                        <input type="text" id="setting_{{ $k }}"
                                               name="settings[{{ $k }}]" value="{{ $setting->value }}"
                                               readonly
                                               class="w-full p-2 border border-gray-200 bg-gray-100 rounded text-sm font-mono text-gray-500 cursor-not-allowed">
                                    @elseif($setting->value_type === 'INTEGER')
                                        <div class="relative">
                                            <input type="number" step="1" min="1" id="setting_{{ $k }}"
                                                   name="settings[{{ $k }}]" value="{{ old("settings.{$k}", $setting->value) }}"
                                                   required
                                                   class="w-full p-2 border border-[#E0D7C7] rounded text-sm font-mono focus:outline-none focus:ring-1 focus:ring-[#84664C]">
                                            <span class="text-xs text-[#8C8477] absolute right-3 top-2.5">giây (seconds)</span>
                                        </div>
                                    @else
                                        <input type="text" id="setting_{{ $k }}"
                                               name="settings[{{ $k }}]" value="{{ old("settings.{$k}", $setting->value) }}"
                                               class="w-full p-2 border border-[#E0D7C7] rounded text-sm font-mono focus:outline-none focus:ring-1 focus:ring-[#84664C]">
                                    @endif
                                </div>

                                @if($setting->updater)
                                    <div class="text-[10px] text-[#8C8477] mt-1.5 flex items-center justify-between">
                                        <span>Cập nhật bởi: <strong>{{ $setting->updater->display_name }}</strong></span>
                                        <span>{{ $setting->updated_at ? $setting->updated_at->format('d/m/Y H:i') : '' }}</span>
                                    </div>
                                @endif
                            </div>
                        @endif
                    @endforeach
                </div>
            </div>
        @endforeach

        <!-- Audit Note & Confirmation Card -->
        <div class="bg-white rounded-lg border border-[#E0D7C7] p-5 shadow-sm space-y-4">
            <div>
                <label for="reason" class="block text-xs font-bold uppercase tracking-wider text-[#2C2E2A] mb-1">
                    Lý do điều chỉnh cấu hình hệ thống <span class="text-red-500">*</span>
                </label>
                <textarea id="reason" name="reason" rows="3" required minlength="5" maxlength="1000"
                          placeholder="Nhập lý do thay đổi biểu phí hoặc tham số hệ thống (bắt buộc tối thiểu 5 ký tự để ghi nhận Audit Logs)..."
                          class="w-full p-3 border border-[#E0D7C7] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#84664C]"></textarea>
                <p class="text-[11px] text-[#8C8477] mt-1">
                    Mọi thay đổi cấu hình sẽ lập tức xóa bộ nhớ đệm cache và ghi lại snapshot giá trị cũ - giá trị mới vào nhật ký kiểm toán bất biến.
                </p>
            </div>

            <div class="flex justify-end pt-2">
                <button type="submit"
                        onclick="return confirm('Bạn có chắc chắn muốn cập nhật các tham số cấu hình nền tảng này?')"
                        class="px-6 py-2.5 bg-[#84664C] text-white rounded-md text-xs font-bold hover:bg-[#6E543E] transition-colors shadow-sm">
                    Lưu Thay đổi Cấu hình Nền tảng
                </button>
            </div>
        </div>
    </form>
</div>
@endsection
