@extends('layouts.admin')

@section('title', 'Hàng đợi Kiểm duyệt Sản phẩm (A-MD-01)')
@section('header_title', 'Hàng đợi Kiểm duyệt Sản phẩm (A-MD-01)')

@section('content')
<div class="space-y-6">
    <!-- Header Summary & Quick Stats -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
            <h3 class="font-serif text-2xl font-bold text-[#1F2937]">Hàng đợi Chờ Kiểm duyệt</h3>
            <p class="text-xs text-gray-500 mt-1">
                Các sản phẩm đăng mới (M-SL-03) và gửi duyệt lại sau chỉnh sửa (M-SL-04 theo DEC-05) đang ở trạng thái <span class="font-mono font-semibold text-rose-600">PENDING_REVIEW</span>.
            </p>
        </div>
        <div class="flex items-center space-x-2">
            <span class="px-3 py-1.5 bg-rose-50 border border-rose-200 text-rose-700 text-xs font-semibold rounded-lg font-mono">
                {{ $products->total() }} bài đăng đang chờ xử lý
            </span>
        </div>
    </div>

    <!-- Filter & Search Toolbar -->
    <div class="bg-white rounded-xl p-5 border border-[#E8E2D9] shadow-xs">
        <form method="GET" action="{{ route('admin.moderation.products.index') }}" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-6 gap-4">
            <!-- Search -->
            <div class="lg:col-span-2">
                <label for="search" class="block text-xs font-semibold uppercase tracking-wider text-[#5E5852] mb-1">Tìm kiếm</label>
                <input type="text"
                       name="search"
                       id="search"
                       value="{{ $filters['search'] ?? '' }}"
                       placeholder="Mã SP (PRD-...) hoặc tên sản phẩm..."
                       class="w-full px-3 py-2 text-xs rounded-lg border border-[#D5CBC1] focus:ring-2 focus:ring-[#C85A32] focus:border-[#C85A32] bg-[#FCFAF7]">
            </div>

            <!-- Listing Type -->
            <div>
                <label for="listing_type" class="block text-xs font-semibold uppercase tracking-wider text-[#5E5852] mb-1">Hình thức bán</label>
                <select name="listing_type" id="listing_type" class="w-full px-3 py-2 text-xs rounded-lg border border-[#D5CBC1] focus:ring-2 focus:ring-[#C85A32] bg-[#FCFAF7]">
                    <option value="">-- Tất cả --</option>
                    <option value="FIXED_PRICE" {{ ($filters['listing_type'] ?? '') === 'FIXED_PRICE' ? 'selected' : '' }}>Giá cố định</option>
                    <option value="AUCTION" {{ ($filters['listing_type'] ?? '') === 'AUCTION' ? 'selected' : '' }}>Đấu giá sàn</option>
                </select>
            </div>

            <!-- Condition (5 levels) -->
            <div>
                <label for="condition" class="block text-xs font-semibold uppercase tracking-wider text-[#5E5852] mb-1">Độ mới (Condition)</label>
                <select name="condition" id="condition" class="w-full px-3 py-2 text-xs rounded-lg border border-[#D5CBC1] focus:ring-2 focus:ring-[#C85A32] bg-[#FCFAF7]">
                    <option value="">-- Tất cả 5 mức --</option>
                    @foreach ($conditions as $cond)
                        <option value="{{ $cond->value }}" {{ ($filters['condition'] ?? '') === $cond->value ? 'selected' : '' }}>
                            {{ $cond->label() }}
                        </option>
                    @endforeach
                </select>
            </div>

            <!-- Category -->
            <div>
                <label for="category_id" class="block text-xs font-semibold uppercase tracking-wider text-[#5E5852] mb-1">Danh mục</label>
                <select name="category_id" id="category_id" class="w-full px-3 py-2 text-xs rounded-lg border border-[#D5CBC1] focus:ring-2 focus:ring-[#C85A32] bg-[#FCFAF7]">
                    <option value="">-- Tất cả --</option>
                    @foreach ($categories as $cat)
                        <option value="{{ $cat->id }}" {{ ($filters['category_id'] ?? '') == $cat->id ? 'selected' : '' }}>
                            {{ $cat->name }}
                        </option>
                        @foreach ($cat->children as $sub)
                            <option value="{{ $sub->id }}" {{ ($filters['category_id'] ?? '') == $sub->id ? 'selected' : '' }}>
                                &nbsp;&nbsp;&bull; {{ $sub->name }}
                            </option>
                        @endforeach
                    @endforeach
                </select>
            </div>

            <!-- Actions -->
            <div class="flex items-end space-x-2">
                <button type="submit" class="flex-1 py-2 px-3 bg-[#2D5A3C] hover:bg-[#23472F] text-white text-xs font-semibold rounded-lg shadow-xs transition-colors">
                    Lọc dữ liệu
                </button>
                <a href="{{ route('admin.moderation.products.index') }}" class="py-2 px-3 border border-[#D5CBC1] hover:bg-[#F4EBDD] text-xs font-medium rounded-lg text-gray-700 transition-colors">
                    Đặt lại
                </a>
            </div>
        </form>
    </div>

    <!-- Product Queue Table -->
    <div class="bg-white rounded-xl border border-[#E8E2D9] shadow-xs overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse text-xs">
                <thead>
                    <tr class="bg-[#FBF8F3] border-b border-[#E8E2D9] text-[#5E5852] uppercase font-semibold">
                        <th class="py-3 px-4">Sản phẩm</th>
                        <th class="py-3 px-4">Người bán</th>
                        <th class="py-3 px-4">Phân loại & Thương hiệu</th>
                        <th class="py-3 px-4">Tình trạng đồ si</th>
                        <th class="py-3 px-4">Hình thức & Giá</th>
                        <th class="py-3 px-4">Thời gian gửi</th>
                        <th class="py-3 px-4 text-right">Thao tác</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#E8E2D9]">
                    @forelse ($products as $product)
                        @php
                            $thumb = $product->images->first()?->image_url ?? 'https://images.unsplash.com/photo-1523381294911-8d3cead13475?w=150';
                            $condBadge = match ($product->condition?->value) {
                                'NEW_WITH_TAGS' => 'bg-purple-100 text-purple-800 border-purple-200',
                                'LIKE_NEW' => 'bg-emerald-100 text-emerald-800 border-emerald-200',
                                'GOOD' => 'bg-blue-100 text-blue-800 border-blue-200',
                                'FAIR' => 'bg-amber-100 text-amber-800 border-amber-200',
                                'VINTAGE_WORN' => 'bg-[#F4EBDD] text-[#84664C] border-[#D5CBC1]',
                                default => 'bg-gray-100 text-gray-800 border-gray-200',
                            };
                        @endphp
                        <tr class="hover:bg-[#FCFAF7] transition-colors">
                            <td class="py-3 px-4">
                                <div class="flex items-center space-x-3">
                                    <img src="{{ $thumb }}" alt="{{ $product->title }}" class="w-12 h-12 rounded-lg object-cover border border-[#E8E2D9] shrink-0 bg-[#F4EBDD]">
                                    <div>
                                        <div class="font-semibold text-[#1F2937] hover:text-[#C85A32] line-clamp-1">
                                            {{ $product->title }}
                                        </div>
                                        <div class="font-mono text-[10px] text-gray-400 mt-0.5">
                                            {{ $product->product_code }}
                                        </div>
                                    </div>
                                </div>
                            </td>
                            <td class="py-3 px-4">
                                <div class="font-medium text-[#1F2937]">{{ $product->seller?->display_name ?? 'N/A' }}</div>
                                <div class="text-[11px] text-gray-400">{{ $product->seller?->email }}</div>
                            </td>
                            <td class="py-3 px-4">
                                <div class="font-medium text-gray-700">{{ $product->category?->name ?? 'Chưa phân loại' }}</div>
                                <div class="text-[11px] text-gray-400">{{ $product->brand?->name ?? 'Vintage / No Brand' }}</div>
                            </td>
                            <td class="py-3 px-4">
                                <span class="inline-flex items-center px-2 py-0.5 rounded text-[11px] font-medium border {{ $condBadge }}">
                                    {{ $product->condition?->label() ?? 'Không rõ' }}
                                </span>
                                @if ($product->defect_info)
                                    <div class="text-[10px] text-amber-700 italic mt-1 line-clamp-1">
                                        Lỗi: {{ $product->defect_info }}
                                    </div>
                                @endif
                            </td>
                            <td class="py-3 px-4">
                                <div class="font-mono font-bold tabular-nums text-[#1F2937]">
                                    {{ number_format($product->price, 0, ',', '.') }} VNĐ
                                </div>
                                <span class="inline-block mt-0.5 text-[10px] uppercase font-semibold {{ $product->listing_type === 'AUCTION' ? 'text-indigo-600' : 'text-gray-500' }}">
                                    {{ $product->listing_type === 'AUCTION' ? 'Đấu giá' : 'Giá cố định' }}
                                </span>
                            </td>
                            <td class="py-3 px-4 text-gray-500 font-mono text-[11px]">
                                {{ $product->created_at?->timezone('Asia/Ho_Chi_Minh')->format('d/m/Y H:i') }}
                            </td>
                            <td class="py-3 px-4 text-right">
                                <a href="{{ route('admin.moderation.products.show', $product->id) }}"
                                   class="inline-flex items-center px-3 py-1.5 rounded-lg bg-[#C85A32] hover:bg-[#B04C27] text-white text-xs font-semibold shadow-xs transition-colors">
                                    Thẩm định
                                    <svg class="w-3.5 h-3.5 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
                                    </svg>
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="py-12 px-4 text-center text-gray-400 italic">
                                Hiện không có sản phẩm nào trong hàng đợi kiểm duyệt (PENDING_REVIEW).
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if ($products->hasPages())
            <div class="p-4 border-t border-[#E8E2D9] bg-[#FBF8F3]">
                {{ $products->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
