@extends('layouts.admin')

@section('title', 'Thẩm định Sản phẩm: ' . $product->product_code . ' (A-MD-02)')
@section('header_title', 'Thẩm định Chi tiết Sản phẩm (A-MD-02)')

@section('content')
<div class="space-y-6">
    <!-- Breadcrumb & Status Navigation -->
    <div class="flex items-center justify-between">
        <div class="flex items-center space-x-2 text-xs text-gray-500">
            <a href="{{ route('admin.moderation.products.index') }}" class="hover:text-[#C85A32] flex items-center">
                <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
                </svg>
                Quay lại hàng đợi
            </a>
            <span>&bull;</span>
            <span class="font-mono text-[#1F2937] font-semibold">{{ $product->product_code }}</span>
        </div>

        <div class="flex items-center space-x-2">
            <span class="px-2.5 py-1 rounded text-xs font-semibold bg-rose-100 text-rose-800 border border-rose-300 font-mono">
                Trạng thái: {{ $product->status->value }}
            </span>
        </div>
    </div>

    <!-- Split-Pane Evidence Review Layout -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <!-- Left Pane: Image Gallery & Close-Up Evidence (5 cols) -->
        <div class="lg:col-span-5 space-y-4">
            <div class="bg-white rounded-xl p-5 border border-[#E8E2D9] shadow-xs">
                <div class="flex items-center justify-between mb-4">
                    <h4 class="font-serif text-base font-bold text-[#1F2937]">Thư viện Ảnh Thẩm định</h4>
                    <span class="text-xs text-gray-400 font-mono">{{ $product->images->count() }} tệp ảnh</span>
                </div>

                <!-- Primary Image Display -->
                @php
                    $primary = $product->images->first();
                @endphp
                <div class="rounded-xl overflow-hidden border border-[#E8E2D9] bg-[#F4EBDD] aspect-square flex items-center justify-center">
                    @if ($primary)
                        <img src="{{ $primary->image_url }}" alt="{{ $product->title }}" class="w-full h-full object-cover">
                    @else
                        <div class="text-center p-6 text-gray-400">
                            <svg class="w-12 h-12 mx-auto mb-2 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                            </svg>
                            <p class="text-xs">Không có hình ảnh</p>
                        </div>
                    @endif
                </div>

                <!-- Image Thumbnails Grid -->
                @if ($product->images->count() > 1)
                    <div class="grid grid-cols-4 gap-2 mt-3">
                        @foreach ($product->images as $img)
                            <a href="{{ $img->image_url }}" target="_blank" class="block rounded-lg overflow-hidden border border-[#E8E2D9] hover:border-[#C85A32] transition-colors aspect-square bg-[#F4EBDD]">
                                <img src="{{ $img->image_url }}" alt="Evidence" class="w-full h-full object-cover">
                            </a>
                        @endforeach
                    </div>
                @endif

                <p class="text-[11px] text-gray-400 italic text-center mt-3">
                    Nhấp vào từng ảnh thu nhỏ để mở xem chi tiết độ phân giải gốc.
                </p>
            </div>

            <!-- Seller Info Card -->
            <div class="bg-white rounded-xl p-5 border border-[#E8E2D9] shadow-xs space-y-3">
                <h4 class="font-serif text-sm font-bold text-[#1F2937]">Hồ sơ Người bán (Seller)</h4>
                <div class="flex items-center space-x-3">
                    <div class="w-10 h-10 rounded-full bg-[#2D5A3C] text-white flex items-center justify-center font-bold font-serif">
                        {{ substr($product->seller?->display_name ?? 'S', 0, 1) }}
                    </div>
                    <div>
                        <div class="font-semibold text-xs text-[#1F2937]">{{ $product->seller?->display_name }}</div>
                        <div class="text-[11px] text-gray-400">{{ $product->seller?->email }}</div>
                    </div>
                </div>

                <div class="grid grid-cols-2 gap-2 pt-2 border-t border-gray-100 text-xs">
                    <div>
                        <span class="text-gray-400 text-[10px] uppercase">Điểm tín nhiệm:</span>
                        <div class="font-mono font-bold text-[#2D5A3C]">{{ $product->seller?->sellerProfile?->trust_score ?? 100 }} / 100</div>
                    </div>
                    <div>
                        <span class="text-gray-400 text-[10px] uppercase">Đơn hoàn tất:</span>
                        <div class="font-mono font-bold text-[#1F2937]">{{ $product->seller?->sellerProfile?->completed_orders_count ?? 0 }}</div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Right Pane: Metadata, Inspection-Slip Motif & Action Desk (7 cols) -->
        <div class="lg:col-span-7 space-y-5">
            <!-- Main Item Header Card -->
            <div class="bg-white rounded-xl p-6 border border-[#E8E2D9] shadow-xs space-y-4">
                <div class="flex items-start justify-between gap-4">
                    <div>
                        <span class="text-xs uppercase font-mono tracking-wider text-[#84664C]">
                            {{ $product->category?->name ?? 'Chưa phân loại' }} &bull; {{ $product->brand?->name ?? 'Vintage' }}
                        </span>
                        <h2 class="font-serif text-xl font-bold text-[#1F2937] mt-1">{{ $product->title }}</h2>
                    </div>
                    <div class="text-right shrink-0">
                        <div class="text-2xl font-bold font-mono tabular-nums text-[#C85A32]">
                            {{ number_format($product->price, 0, ',', '.') }} <span class="text-xs font-normal text-gray-500">VNĐ</span>
                        </div>
                        <span class="text-[11px] uppercase font-semibold text-gray-400">
                            {{ $product->listing_type === 'AUCTION' ? 'Đấu giá sàn' : 'Giá cố định' }}
                        </span>
                    </div>
                </div>

                <!-- 5-Level Product Condition Badge -->
                @php
                    $condStyle = match ($product->condition?->value) {
                        'NEW_WITH_TAGS' => 'bg-purple-50 text-purple-800 border-purple-300',
                        'LIKE_NEW' => 'bg-emerald-50 text-emerald-800 border-emerald-300',
                        'GOOD' => 'bg-blue-50 text-blue-800 border-blue-300',
                        'FAIR' => 'bg-amber-50 text-amber-800 border-amber-300',
                        'VINTAGE_WORN' => 'bg-[#F4EBDD] text-[#84664C] border-[#D5CBC1]',
                        default => 'bg-gray-50 text-gray-800 border-gray-300',
                    };
                @endphp
                <div class="flex items-center space-x-3 p-3 rounded-lg border {{ $condStyle }}">
                    <div class="font-semibold text-xs">Độ mới công bố:</div>
                    <div class="text-xs font-bold">{{ $product->condition?->label() }}</div>
                    <span class="text-[10px] font-mono px-2 py-0.5 rounded bg-white/70 border border-current">
                        {{ $product->condition?->value }}
                    </span>
                </div>

                <!-- Inspection-Slip Motif for Defect Info (BR-PR-03) -->
                <div class="rounded-xl border-2 border-dashed border-[#D5CBC1] bg-[#FCFAF7] p-4 relative">
                    <div class="flex items-center justify-between mb-2">
                        <span class="inline-flex items-center text-xs font-serif font-bold uppercase tracking-wider text-[#84664C]">
                            <svg class="w-4 h-4 mr-1 text-[#C85A32]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
                            </svg>
                            Phiếu Khai Báo Khuyết Điểm Đồ Si (BR-PR-03)
                        </span>
                        <span class="text-[10px] font-mono text-gray-400">Min 5 chars enforced</span>
                    </div>

                    @if ($product->defect_info)
                        <div class="p-3 bg-white rounded-lg border border-[#E8E2D9] text-xs text-[#1F2937] leading-relaxed">
                            {{ $product->defect_info }}
                        </div>
                    @else
                        <div class="p-3 bg-emerald-50 rounded-lg border border-emerald-200 text-xs text-emerald-800 italic">
                            Người bán cam kết sản phẩm không có khuyết điểm đáng kể.
                        </div>
                    @endif
                </div>

                <!-- Description -->
                <div>
                    <h5 class="text-xs font-semibold uppercase tracking-wider text-[#5E5852] mb-1">Mô tả bài đăng:</h5>
                    <div class="p-3 bg-[#FCFAF7] rounded-lg border border-[#E8E2D9] text-xs text-gray-700 whitespace-pre-line leading-relaxed">
                        {{ $product->description ?: 'Không có mô tả chi tiết.' }}
                    </div>
                </div>
            </div>

            <!-- Immutable Moderation History -->
            @if ($product->moderationLogs->isNotEmpty())
                <div class="bg-white rounded-xl p-5 border border-[#E8E2D9] shadow-xs">
                    <h4 class="font-serif text-sm font-bold text-[#1F2937] mb-3">Lịch sử Kiểm duyệt Bất biến (Moderation Logs)</h4>
                    <div class="space-y-3">
                        @foreach ($product->moderationLogs as $log)
                            <div class="p-3 bg-[#FCFAF7] rounded-lg border border-[#E8E2D9] text-xs flex items-start justify-between">
                                <div>
                                    <div class="flex items-center space-x-2">
                                        <span class="font-bold {{ $log->action === 'APPROVED' ? 'text-emerald-700' : 'text-rose-700' }}">
                                            {{ $log->action }}
                                        </span>
                                        <span class="text-gray-400">&bull;</span>
                                        <span class="text-gray-600">{{ $log->moderator?->display_name ?? 'Hệ thống' }}</span>
                                    </div>
                                    <div class="text-gray-600 mt-1 italic">
                                        "{{ $log->reason }}"
                                    </div>
                                </div>
                                <div class="text-[11px] font-mono text-gray-400 shrink-0">
                                    {{ $log->created_at?->timezone('Asia/Ho_Chi_Minh')->format('d/m/Y H:i') }}
                                </div>
                            </div>
                        @endforeach
                    </div>
                </div>
            @endif

            <!-- Moderation Action Desk -->
            <div class="bg-white rounded-xl p-6 border border-[#E8E2D9] shadow-xs space-y-6">
                <h4 class="font-serif text-base font-bold text-[#1F2937]">Quyết định Thẩm định (Moderation Verdict)</h4>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <!-- Approve Form -->
                    <form method="POST" action="{{ route('admin.moderation.products.approve', $product->id) }}" class="p-4 rounded-xl border border-emerald-200 bg-emerald-50/40 space-y-3">
                        @csrf
                        <div class="flex items-center space-x-2 text-emerald-800 font-bold text-xs uppercase tracking-wider">
                            <svg class="w-4 h-4 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                            </svg>
                            <span>Duyệt & Xuất bản (Approve)</span>
                        </div>

                        <div>
                            <label for="verification_level" class="block text-[11px] font-semibold text-gray-600 mb-1">Cấp độ kiểm thực</label>
                            <select name="verification_level" id="verification_level" class="w-full px-2.5 py-1.5 text-xs rounded border border-[#D5CBC1] bg-white">
                                <option value="MODERATOR_REVIEWED">Kiểm duyệt viên chuẩn (MODERATOR_REVIEWED)</option>
                                <option value="EXPERT_VERIFIED">Chuyên gia giám định (EXPERT_VERIFIED)</option>
                            </select>
                        </div>

                        <div>
                            <label for="approve_reason" class="block text-[11px] font-semibold text-gray-600 mb-1">Ghi chú duyệt (Tùy chọn)</label>
                            <input type="text" name="reason" id="approve_reason" placeholder="Đạt chuẩn kiểm duyệt..." class="w-full px-2.5 py-1.5 text-xs rounded border border-[#D5CBC1] bg-white">
                        </div>

                        <button type="submit" class="w-full py-2.5 px-4 bg-[#2D5A3C] hover:bg-[#23472F] text-white text-xs font-semibold rounded-lg shadow-xs transition-colors">
                            Phê duyệt Xuất bản
                        </button>
                    </form>

                    <!-- Reject Form (DEC-05) -->
                    <form method="POST" action="{{ route('admin.moderation.products.reject', $product->id) }}" class="p-4 rounded-xl border border-rose-200 bg-rose-50/40 space-y-3">
                        @csrf
                        <div class="flex items-center space-x-2 text-rose-800 font-bold text-xs uppercase tracking-wider">
                            <svg class="w-4 h-4 text-rose-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                            </svg>
                            <span>Từ chối Bài đăng (Reject - DEC-05)</span>
                        </div>

                        <div>
                            <label for="reject_reason" class="block text-[11px] font-semibold text-rose-800 mb-1">
                                Lý do từ chối <span class="text-rose-600 font-bold">*</span> (Bắt buộc, tối thiểu 5 ký tự)
                            </label>
                            <textarea name="reason"
                                      id="reject_reason"
                                      rows="3"
                                      required
                                      placeholder="Nêu rõ lý do (ví dụ: Hình ảnh mờ, khuyết điểm chưa khai báo đúng, đồ giả thương hiệu...) để người bán chỉnh sửa trên M-SL-04..."
                                      class="w-full px-2.5 py-1.5 text-xs rounded border border-rose-300 bg-white focus:ring-2 focus:ring-rose-500"></textarea>
                        </div>

                        <button type="submit" class="w-full py-2.5 px-4 bg-[#C85A32] hover:bg-[#B04C27] text-white text-xs font-semibold rounded-lg shadow-xs transition-colors">
                            Từ chối Bài đăng (DEC-05)
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
