@extends('layouts.admin')

@section('title', 'Quản lý Phân loại & Danh mục (A-CT-01)')
@section('header_title', 'Quản trị Danh mục & Thương hiệu Vintage (A-CT-01)')

@section('content')
<div class="space-y-8" x-data="{ activeTab: 'categories', showCatModal: false, showBrandModal: false, editCat: null, editBrand: null }">
    <!-- Header Summary & Tab Switcher -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
            <h3 class="font-serif text-2xl font-bold text-[#1F2937]">Phân loại Sàn & Danh mục Vintage</h3>
            <p class="text-xs text-gray-500 mt-1">
                Quản lý cây danh mục phân cấp cha-con (Categories) và thương hiệu đồ si (Brands) đồng bộ hóa thời gian thực tới Mobile API (/api/v1/catalog/taxonomy).
            </p>
        </div>

        <!-- Tab Pills -->
        <div class="flex items-center space-x-1 bg-[#F4EBDD] p-1 rounded-xl border border-[#D5CBC1]">
            <button type="button"
                    @click="activeTab = 'categories'"
                    :class="activeTab === 'categories' ? 'bg-[#2D5A3C] text-white font-semibold' : 'text-[#84664C] hover:text-[#1F2937]'"
                    class="px-4 py-1.5 rounded-lg text-xs transition-colors">
                Cây Danh mục ({{ $categories->count() }} gốc)
            </button>
            <button type="button"
                    @click="activeTab = 'brands'"
                    :class="activeTab === 'brands' ? 'bg-[#2D5A3C] text-white font-semibold' : 'text-[#84664C] hover:text-[#1F2937]'"
                    class="px-4 py-1.5 rounded-lg text-xs transition-colors">
                Thương hiệu Vintage ({{ $brands->count() }})
            </button>
        </div>
    </div>

    <!-- TAB 1: CATEGORIES HIERARCHY TREE -->
    <div x-show="activeTab === 'categories'" class="space-y-6">
        <div class="flex items-center justify-between">
            <h4 class="font-serif text-lg font-bold text-[#1F2937]">Cây Phân Cấp Danh Mục</h4>
            @if (auth('web')->user()?->isAdmin())
                <button type="button"
                        @click="editCat = null; showCatModal = true"
                        class="inline-flex items-center px-3 py-1.5 rounded-lg bg-[#2D5A3C] hover:bg-[#23472F] text-white text-xs font-semibold shadow-xs transition-colors">
                    <svg class="w-4 h-4 mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                    </svg>
                    Thêm danh mục mới
                </button>
            @endif
        </div>

        <div class="bg-white rounded-xl border border-[#E8E2D9] shadow-xs overflow-hidden">
            <div class="divide-y divide-[#E8E2D9]">
                @forelse ($categories as $cat)
                    <div class="p-4 hover:bg-[#FCFAF7] transition-colors">
                        <!-- Root Category Row -->
                        <div class="flex items-center justify-between">
                            <div class="flex items-center space-x-3">
                                <span class="w-8 h-8 rounded-lg bg-[#F4EBDD] text-[#84664C] flex items-center justify-center font-bold text-xs font-mono border border-[#D5CBC1]">
                                    #{{ $cat->id }}
                                </span>
                                <div>
                                    <div class="font-bold text-sm text-[#1F2937] flex items-center space-x-2">
                                        <span>{{ $cat->name }}</span>
                                        <span class="font-mono text-[10px] text-gray-400">/{{ $cat->slug }}</span>
                                        @if (!$cat->is_active)
                                            <span class="px-1.5 py-0.5 rounded text-[10px] bg-gray-100 text-gray-500 font-semibold">Đã ẩn</span>
                                        @endif
                                    </div>
                                    <div class="text-[11px] text-gray-500 mt-0.5">
                                        {{ $cat->products_count }} sản phẩm gắn kết &bull; Thứ tự sắp xếp: {{ $cat->sort_order }}
                                    </div>
                                </div>
                            </div>

                            @if (auth('web')->user()?->isAdmin())
                                <div class="flex items-center space-x-2">
                                    <!-- Toggle Active Form -->
                                    <form method="POST" action="{{ route('admin.catalog.categories.toggle', $cat->id) }}" class="inline">
                                        @csrf
                                        <button type="submit" class="px-2.5 py-1 rounded text-[11px] font-medium border {{ $cat->is_active ? 'border-amber-300 text-amber-800 hover:bg-amber-50' : 'border-emerald-300 text-emerald-800 hover:bg-emerald-50' }}">
                                            {{ $cat->is_active ? 'Ẩn' : 'Hiện' }}
                                        </button>
                                    </form>

                                    <!-- Delete Category Form -->
                                    <form method="POST" action="{{ route('admin.catalog.categories.destroy', $cat->id) }}" class="inline" onsubmit="return confirm('Bạn có chắc chắn muốn xóa danh mục này?');">
                                        @csrf
                                        @method('DELETE')
                                        <button type="submit" class="px-2.5 py-1 rounded text-[11px] font-medium border border-rose-300 text-rose-800 hover:bg-rose-50">
                                            Xóa
                                        </button>
                                    </form>
                                </div>
                            @endif
                        </div>

                        <!-- Sub-categories (Children) -->
                        @if ($cat->children->isNotEmpty())
                            <div class="mt-3 ml-11 pl-4 border-l-2 border-[#D5CBC1] space-y-2">
                                @foreach ($cat->children as $sub)
                                    <div class="flex items-center justify-between py-1.5 px-3 rounded-lg bg-[#FBF8F3] border border-[#E8E2D9]">
                                        <div class="flex items-center space-x-2">
                                            <span class="text-xs font-semibold text-gray-800">{{ $sub->name }}</span>
                                            <span class="text-[10px] font-mono text-gray-400">/{{ $sub->slug }}</span>
                                            <span class="text-[10px] font-mono text-[#84664C]">({{ $sub->products_count }} SP)</span>
                                            @if (!$sub->is_active)
                                                <span class="text-[9px] px-1 bg-gray-200 text-gray-600 rounded">Ẩn</span>
                                            @endif
                                        </div>

                                        @if (auth('web')->user()?->isAdmin())
                                            <div class="flex items-center space-x-2">
                                                <form method="POST" action="{{ route('admin.catalog.categories.toggle', $sub->id) }}" class="inline">
                                                    @csrf
                                                    <button type="submit" class="text-[10px] text-gray-600 hover:text-black">
                                                        {{ $sub->is_active ? 'Ẩn' : 'Hiện' }}
                                                    </button>
                                                </form>
                                                <span class="text-gray-300">&bull;</span>
                                                <form method="POST" action="{{ route('admin.catalog.categories.destroy', $sub->id) }}" class="inline" onsubmit="return confirm('Xác nhận xóa danh mục con?');">
                                                    @csrf
                                                    @method('DELETE')
                                                    <button type="submit" class="text-[10px] text-rose-600 hover:text-rose-800">
                                                        Xóa
                                                    </button>
                                                </form>
                                            </div>
                                        @endif
                                    </div>
                                @endforeach
                            </div>
                        @endif
                    </div>
                @empty
                    <div class="p-8 text-center text-gray-400 italic text-xs">
                        Chưa có danh mục nào được khởi tạo trong hệ thống.
                    </div>
                @endforelse
            </div>
        </div>
    </div>

    <!-- TAB 2: BRANDS DIRECTORY -->
    <div x-show="activeTab === 'brands'" style="display: none;" class="space-y-6">
        <div class="flex items-center justify-between">
            <h4 class="font-serif text-lg font-bold text-[#1F2937]">Danh Mục Thương Hiệu Vintage</h4>
            @if (auth('web')->user()?->isAdmin())
                <button type="button"
                        @click="editBrand = null; showBrandModal = true"
                        class="inline-flex items-center px-3 py-1.5 rounded-lg bg-[#2D5A3C] hover:bg-[#23472F] text-white text-xs font-semibold shadow-xs transition-colors">
                    <svg class="w-4 h-4 mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                    </svg>
                    Thêm thương hiệu mới
                </button>
            @endif
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            @forelse ($brands as $brand)
                <div class="bg-white rounded-xl p-4 border border-[#E8E2D9] shadow-xs flex flex-col justify-between space-y-3">
                    <div class="flex items-start justify-between">
                        <div>
                            <div class="font-bold text-sm text-[#1F2937]">{{ $brand->name }}</div>
                            <div class="font-mono text-[10px] text-gray-400 mt-0.5">/{{ $brand->slug }}</div>
                        </div>
                        <span class="font-mono text-xs px-2 py-0.5 rounded bg-[#F4EBDD] text-[#84664C] font-semibold">
                            {{ $brand->products_count }} SP
                        </span>
                    </div>

                    @if ($brand->description)
                        <p class="text-xs text-gray-500 line-clamp-2">{{ $brand->description }}</p>
                    @endif

                    <div class="pt-3 border-t border-gray-100 flex items-center justify-between text-xs">
                        <span class="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-semibold {{ $brand->is_active ? 'bg-emerald-50 text-emerald-700' : 'bg-gray-100 text-gray-500' }}">
                            {{ $brand->is_active ? 'Đang hoạt động' : 'Tạm ẩn' }}
                        </span>

                        @if (auth('web')->user()?->isAdmin())
                            <div class="flex items-center space-x-2">
                                <form method="POST" action="{{ route('admin.catalog.brands.toggle', $brand->id) }}" class="inline">
                                    @csrf
                                    <button type="submit" class="text-[11px] text-[#84664C] hover:underline">
                                        {{ $brand->is_active ? 'Ẩn' : 'Hiện' }}
                                    </button>
                                </form>
                                <span class="text-gray-300">&bull;</span>
                                <form method="POST" action="{{ route('admin.catalog.brands.destroy', $brand->id) }}" class="inline" onsubmit="return confirm('Xóa thương hiệu này?');">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="text-[11px] text-rose-600 hover:underline">
                                        Xóa
                                    </button>
                                </form>
                            </div>
                        @endif
                    </div>
                </div>
            @empty
                <div class="col-span-full p-8 text-center text-gray-400 italic text-xs bg-white rounded-xl border border-[#E8E2D9]">
                    Chưa có thương hiệu nào được tạo.
                </div>
            @endforelse
        </div>
    </div>

    <!-- MODAL: ADD CATEGORY -->
    <div x-show="showCatModal" style="display: none;" class="fixed inset-0 z-50 overflow-y-auto bg-black/50 flex items-center justify-center p-4">
        <div class="bg-white rounded-2xl max-w-lg w-full p-6 shadow-xl border border-[#E8E2D9] space-y-5" @click.outside="showCatModal = false">
            <div class="flex items-center justify-between">
                <h4 class="font-serif text-lg font-bold text-[#1F2937]">Thêm Danh Mục Mới</h4>
                <button type="button" @click="showCatModal = false" class="text-gray-400 hover:text-gray-600 text-lg">&times;</button>
            </div>

            <form method="POST" action="{{ route('admin.catalog.categories.store') }}" class="space-y-4 text-xs">
                @csrf
                <div>
                    <label class="block font-semibold uppercase text-gray-600 mb-1">Tên danh mục <span class="text-rose-500">*</span></label>
                    <input type="text" name="name" required placeholder="Áo Khoác Vintage, Đồng Hồ Cổ..." class="w-full px-3 py-2 rounded-lg border border-[#D5CBC1] focus:ring-2 focus:ring-[#C85A32]">
                </div>

                <div>
                    <label class="block font-semibold uppercase text-gray-600 mb-1">Đường dẫn (Slug - Để trống để tự tạo)</label>
                    <input type="text" name="slug" placeholder="ao-khoac-vintage" class="w-full px-3 py-2 rounded-lg border border-[#D5CBC1] focus:ring-2 focus:ring-[#C85A32]">
                </div>

                <div>
                    <label class="block font-semibold uppercase text-gray-600 mb-1">Danh mục cha (Root Category)</label>
                    <select name="parent_id" class="w-full px-3 py-2 rounded-lg border border-[#D5CBC1] focus:ring-2 focus:ring-[#C85A32]">
                        <option value="">-- Danh mục gốc (Không có cha) --</option>
                        @foreach ($rootCategories as $rcat)
                            <option value="{{ $rcat->id }}">{{ $rcat->name }}</option>
                        @endforeach
                    </select>
                </div>

                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="block font-semibold uppercase text-gray-600 mb-1">Thứ tự hiển thị</label>
                        <input type="number" name="sort_order" value="0" min="0" class="w-full px-3 py-2 rounded-lg border border-[#D5CBC1]">
                    </div>
                    <div>
                        <label class="block font-semibold uppercase text-gray-600 mb-1">Trạng thái</label>
                        <select name="is_active" class="w-full px-3 py-2 rounded-lg border border-[#D5CBC1]">
                            <option value="1">Kích hoạt</option>
                            <option value="0">Tạm ẩn</option>
                        </select>
                    </div>
                </div>

                <div>
                    <label class="block font-semibold uppercase text-gray-600 mb-1">Mô tả</label>
                    <textarea name="description" rows="2" placeholder="Mô tả danh mục..." class="w-full px-3 py-2 rounded-lg border border-[#D5CBC1]"></textarea>
                </div>

                <div class="flex items-center justify-end space-x-2 pt-3 border-t border-gray-100">
                    <button type="button" @click="showCatModal = false" class="px-4 py-2 border border-[#D5CBC1] text-gray-700 rounded-lg font-medium hover:bg-gray-50">
                        Hủy
                    </button>
                    <button type="submit" class="px-4 py-2 bg-[#2D5A3C] hover:bg-[#23472F] text-white rounded-lg font-semibold shadow-xs">
                        Lưu Danh Mục
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- MODAL: ADD BRAND -->
    <div x-show="showBrandModal" style="display: none;" class="fixed inset-0 z-50 overflow-y-auto bg-black/50 flex items-center justify-center p-4">
        <div class="bg-white rounded-2xl max-w-lg w-full p-6 shadow-xl border border-[#E8E2D9] space-y-5" @click.outside="showBrandModal = false">
            <div class="flex items-center justify-between">
                <h4 class="font-serif text-lg font-bold text-[#1F2937]">Thêm Thương Hiệu Mới</h4>
                <button type="button" @click="showBrandModal = false" class="text-gray-400 hover:text-gray-600 text-lg">&times;</button>
            </div>

            <form method="POST" action="{{ route('admin.catalog.brands.store') }}" class="space-y-4 text-xs">
                @csrf
                <div>
                    <label class="block font-semibold uppercase text-gray-600 mb-1">Tên thương hiệu <span class="text-rose-500">*</span></label>
                    <input type="text" name="name" required placeholder="Levi's, Burberry, Omega..." class="w-full px-3 py-2 rounded-lg border border-[#D5CBC1] focus:ring-2 focus:ring-[#C85A32]">
                </div>

                <div>
                    <label class="block font-semibold uppercase text-gray-600 mb-1">Đường dẫn (Slug - Để trống để tự tạo)</label>
                    <input type="text" name="slug" placeholder="levis, burberry" class="w-full px-3 py-2 rounded-lg border border-[#D5CBC1] focus:ring-2 focus:ring-[#C85A32]">
                </div>

                <div>
                    <label class="block font-semibold uppercase text-gray-600 mb-1">Quốc gia xuất xứ</label>
                    <input type="text" name="origin_country" placeholder="Hoa Kỳ, Nhật Bản, Ý..." class="w-full px-3 py-2 rounded-lg border border-[#D5CBC1]">
                </div>

                <div>
                    <label class="block font-semibold uppercase text-gray-600 mb-1">Mô tả thương hiệu</label>
                    <textarea name="description" rows="2" placeholder="Di sản thương hiệu vintage..." class="w-full px-3 py-2 rounded-lg border border-[#D5CBC1]"></textarea>
                </div>

                <div class="flex items-center justify-end space-x-2 pt-3 border-t border-gray-100">
                    <button type="button" @click="showBrandModal = false" class="px-4 py-2 border border-[#D5CBC1] text-gray-700 rounded-lg font-medium hover:bg-gray-50">
                        Hủy
                    </button>
                    <button type="submit" class="px-4 py-2 bg-[#2D5A3C] hover:bg-[#23472F] text-white rounded-lg font-semibold shadow-xs">
                        Lưu Thương Hiệu
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection
