@extends('layouts.admin')

@section('title', 'Quản lý Sản phẩm Toàn Sàn (A-PR-01)')
@section('header_title', 'Quản lý Sản phẩm Toàn Sàn – Master Inventory (A-PR-01)')

@section('content')
<div class="space-y-6">
    <!-- Header Summary -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
            <h3 class="font-serif text-2xl font-bold text-[#1F2937]">Kho Sản phẩm Toàn Sàn</h3>
            <p class="text-xs text-gray-500 mt-1">
                Theo dõi toàn diện danh mục sản phẩm qua 7 trạng thái vòng đời (DRAFT, PENDING_REVIEW, APPROVED, REJECTED, SOLD, HIDDEN, ARCHIVED).
            </p>
        </div>
        <div class="flex items-center space-x-2 font-mono text-xs">
            <span class="px-3 py-1.5 bg-[#F4EBDD] text-[#84664C] rounded-lg border border-[#D5CBC1] font-semibold">
                {{ $products->total() }} sản phẩm
            </span>
        </div>
    </div>

    <!-- Multi-criteria Filter Toolbar -->
    <div class="bg-white rounded-xl p-5 border border-[#E8E2D9] shadow-xs">
        <form method="GET" action="{{ route('admin.products.index') }}" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-6 gap-4">
            <!-- Search -->
            <div class="lg:col-span-2">
                <label for="search" class="block text-xs font-semibold uppercase tracking-wider text-[#5E5852] mb-1">Tìm kiếm</label>
                <input type="text"
                       name="search"
                       id="search"
                       value="{{ $filters['search'] ?? '' }}"
                       placeholder="Mã SP, tên, email người bán..."
                       class="w-full px-3 py-2 text-xs rounded-lg border border-[#D5CBC1] focus:ring-2 focus:ring-[#C85A32] bg-[#FCFAF7]">
            </div>

            <!-- Status Filter (7 statuses) -->
            <div>
                <label for="status" class="block text-xs font-semibold uppercase tracking-wider text-[#5E5852] mb-1">Trạng thái</label>
                <select name="status" id="status" class="w-full px-3 py-2 text-xs rounded-lg border border-[#D5CBC1] focus:ring-2 focus:ring-[#C85A32] bg-[#FCFAF7]">
                    <option value="">-- Tất cả 7 trạng thái --</option>
                    @foreach ($statuses as $st)
                        <option value="{{ $st->value }}" {{ ($filters['status'] ?? '') === $st->value ? 'selected' : '' }}>
                            {{ $st->value }} ({{ $st->label() }})
                        </option>
                    @endforeach
                </select>
            </div>

            <!-- Condition Filter (5 levels) -->
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

            <!-- Category Filter -->
            <div>
                <label for="category_id" class="block text-xs font-semibold uppercase tracking-wider text-[#5E5852] mb-1">Danh mục</label>
                <select name="category_id" id="category_id" class="w-full px-3 py-2 text-xs rounded-lg border border-[#D5CBC1] focus:ring-2 focus:ring-[#C85A32] bg-[#FCFAF7]">
                    <option value="">-- Tất cả --</option>
                    @foreach ($categories as $cat)
                        <option value="{{ $cat->id }}" {{ ($filters['category_id'] ?? '') == $cat->id ? 'selected' : '' }}>
                            {{ $cat->name }}
                        </option>
                    @endforeach
                </select>
            </div>

            <!-- Filter Buttons -->
            <div class="flex items-end space-x-2">
                <button type="submit" class="flex-1 py-2 px-3 bg-[#2D5A3C] hover:bg-[#23472F] text-white text-xs font-semibold rounded-lg shadow-xs transition-colors">
                    Lọc dữ liệu
                </button>
                <a href="{{ route('admin.products.index') }}" class="py-2 px-3 border border-[#D5CBC1] hover:bg-[#F4EBDD] text-xs font-medium rounded-lg text-gray-700 transition-colors">
                    Đặt lại
                </a>
            </div>
        </form>
    </div>

    <!-- Product Master Table -->
    <div class="bg-white rounded-xl border border-[#E8E2D9] shadow-xs overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse text-xs">
                <thead>
                    <tr class="bg-[#FBF8F3] border-b border-[#E8E2D9] text-[#5E5852] uppercase font-semibold">
                        <th class="py-3 px-4">Sản phẩm</th>
                        <th class="py-3 px-4">Người bán</th>
                        <th class="py-3 px-4">Độ mới đồ si</th>
                        <th class="py-3 px-4">Trạng thái sàn</th>
                        <th class="py-3 px-4">Giá bán</th>
                        <th class="py-3 px-4">Tồn kho</th>
                        <th class="py-3 px-4 text-right">Quản trị & Can thiệp</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#E8E2D9]">
                    @forelse ($products as $product)
                        @php
                            $thumb = $product->images->first()?->image_url ?? 'https://images.unsplash.com/photo-1523381294911-8d3cead13475?w=150';
                            $statusBadge = match ($product->status?->value) {
                                'APPROVED' => 'bg-emerald-100 text-emerald-800 border-emerald-300',
                                'PENDING_REVIEW' => 'bg-rose-100 text-rose-800 border-rose-300',
                                'REJECTED' => 'bg-red-100 text-red-800 border-red-300',
                                'SOLD' => 'bg-blue-100 text-blue-800 border-blue-300',
                                'HIDDEN' => 'bg-gray-200 text-gray-800 border-gray-400',
                                'DRAFT' => 'bg-gray-100 text-gray-600 border-gray-300',
                                default => 'bg-gray-100 text-gray-800 border-gray-300',
                            };
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
                                            {{ $product->product_code }} &bull; {{ $product->category?->name ?? 'N/A' }}
                                        </div>
                                    </div>
                                </div>
                            </td>
                            <td class="py-3 px-4">
                                <div class="font-medium text-[#1F2937]">{{ $product->seller?->display_name ?? 'N/A' }}</div>
                                <div class="text-[11px] text-gray-400">{{ $product->seller?->email }}</div>
                            </td>
                            <td class="py-3 px-4">
                                <span class="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-medium border {{ $condBadge }}">
                                    {{ $product->condition?->label() }}
                                </span>
                            </td>
                            <td class="py-3 px-4">
                                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold border {{ $statusBadge }}">
                                    {{ $product->status?->value }}
                                </span>
                            </td>
                            <td class="py-3 px-4">
                                <div class="font-mono font-bold tabular-nums text-[#1F2937]">
                                    {{ number_format($product->price, 0, ',', '.') }} VNĐ
                                </div>
                                <span class="text-[10px] uppercase font-semibold text-gray-400">
                                    {{ $product->listing_type === 'AUCTION' ? 'Đấu giá' : 'Giá cố định' }}
                                </span>
                            </td>
                            <td class="py-3 px-4 font-mono tabular-nums text-gray-700">
                                {{ $product->available_quantity }} / {{ $product->total_quantity }}
                            </td>
                            <td class="py-3 px-4 text-right space-x-2">
                                @if ($product->status === \App\Enums\ProductStatus::APPROVED)
                                    <!-- Hide Button with prompt/form -->
                                    <form method="POST" action="{{ route('admin.products.hide', $product->id) }}" class="inline" onsubmit="return confirm('Bạn có chắc chắn muốn tạm ẩn bài đăng này do vi phạm chính sách?');">
                                        @csrf
                                        <input type="hidden" name="reason" value="Vi phạm tiêu chuẩn cộng đồng hoặc thông tin không nhất quán (BR-PR-04)">
                                        <button type="submit" class="inline-flex items-center px-2.5 py-1 rounded bg-amber-50 hover:bg-amber-100 text-amber-800 border border-amber-300 text-[11px] font-medium transition-colors">
                                            Tạm ẩn
                                        </button>
                                    </form>
                                @elseif ($product->status === \App\Enums\ProductStatus::HIDDEN)
                                    <!-- Unhide Button -->
                                    <form method="POST" action="{{ route('admin.products.unhide', $product->id) }}" class="inline">
                                        @csrf
                                        <input type="hidden" name="reason" value="Khôi phục hiển thị sau khi rà soát tuân thủ.">
                                        <button type="submit" class="inline-flex items-center px-2.5 py-1 rounded bg-emerald-50 hover:bg-emerald-100 text-emerald-800 border border-emerald-300 text-[11px] font-medium transition-colors">
                                            Khôi phục
                                        </button>
                                    </form>
                                @endif

                                @if ($product->status === \App\Enums\ProductStatus::PENDING_REVIEW)
                                    <a href="{{ route('admin.moderation.products.show', $product->id) }}" class="inline-flex items-center px-2.5 py-1 rounded bg-[#C85A32] text-white text-[11px] font-medium hover:bg-[#B04C27] transition-colors">
                                        Thẩm định
                                    </a>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="py-12 px-4 text-center text-gray-400 italic">
                                Không tìm thấy sản phẩm nào khớp với điều kiện lọc.
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
