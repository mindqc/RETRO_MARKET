<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Brand;
use App\Models\Category;
use App\Services\Catalog\CatalogTaxonomyService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

class CatalogController extends Controller
{
    public function __construct(
        protected CatalogTaxonomyService $taxonomyService
    ) {}

    /**
     * Display Catalog Management (Screen A-CT-01): Categories Tree & Vintage Brands.
     */
    public function index(): View
    {
        $categories = $this->taxonomyService->getAllCategoriesWithHierarchy();
        $brands = $this->taxonomyService->getAllBrands();
        $rootCategories = Category::whereNull('parent_id')->orderBy('name')->get();

        return view('admin.catalog.index', [
            'categories' => $categories,
            'brands' => $brands,
            'rootCategories' => $rootCategories,
        ]);
    }

    /**
     * Store new category (DEC-08-02).
     */
    public function storeCategory(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'slug' => ['nullable', 'string', 'max:120'],
            'parent_id' => ['nullable', 'integer', 'exists:categories,id'],
            'icon_name' => ['nullable', 'string', 'max:60'],
            'description' => ['nullable', 'string', 'max:1000'],
            'sort_order' => ['nullable', 'integer', 'min:0'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        /** @var \App\Models\User $user */
        $user = Auth::guard('web')->user();

        $category = $this->taxonomyService->createCategory($validated, $user);

        return redirect()->route('admin.catalog.index')
            ->with('success', "Đã tạo mới danh mục '{$category->name}' thành công.");
    }

    /**
     * Update category (DEC-08-02).
     */
    public function updateCategory(Request $request, int $id): RedirectResponse
    {
        $category = Category::findOrFail($id);

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'slug' => ['nullable', 'string', 'max:120'],
            'parent_id' => ['nullable', 'integer', 'exists:categories,id'],
            'icon_name' => ['nullable', 'string', 'max:60'],
            'description' => ['nullable', 'string', 'max:1000'],
            'sort_order' => ['nullable', 'integer', 'min:0'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        /** @var \App\Models\User $user */
        $user = Auth::guard('web')->user();

        $this->taxonomyService->updateCategory($category, $validated, $user);

        return redirect()->route('admin.catalog.index')
            ->with('success', "Đã cập nhật danh mục '{$category->name}' thành công.");
    }

    /**
     * Toggle category active status.
     */
    public function toggleCategory(int $id): RedirectResponse
    {
        $category = Category::findOrFail($id);

        /** @var \App\Models\User $user */
        $user = Auth::guard('web')->user();

        $this->taxonomyService->toggleCategoryActive($category, $user);

        return back()->with('success', "Đã cập nhật trạng thái hiển thị danh mục '{$category->name}'.");
    }

    /**
     * Delete category (DEC-08-02).
     */
    public function destroyCategory(int $id): RedirectResponse
    {
        $category = Category::findOrFail($id);

        /** @var \App\Models\User $user */
        $user = Auth::guard('web')->user();

        $this->taxonomyService->deleteCategory($category, $user);

        return redirect()->route('admin.catalog.index')
            ->with('success', "Đã xóa danh mục '{$category->name}' thành công.");
    }

    /**
     * Store brand (DEC-08-02).
     */
    public function storeBrand(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'slug' => ['nullable', 'string', 'max:120'],
            'origin_country' => ['nullable', 'string', 'max:60'],
            'logo_url' => ['nullable', 'url', 'max:500'],
            'description' => ['nullable', 'string', 'max:1000'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        /** @var \App\Models\User $user */
        $user = Auth::guard('web')->user();

        $brand = $this->taxonomyService->createBrand($validated, $user);

        return redirect()->route('admin.catalog.index')
            ->with('success', "Đã tạo mới thương hiệu '{$brand->name}' thành công.");
    }

    /**
     * Update brand (DEC-08-02).
     */
    public function updateBrand(Request $request, int $id): RedirectResponse
    {
        $brand = Brand::findOrFail($id);

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'slug' => ['nullable', 'string', 'max:120'],
            'origin_country' => ['nullable', 'string', 'max:60'],
            'logo_url' => ['nullable', 'url', 'max:500'],
            'description' => ['nullable', 'string', 'max:1000'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        /** @var \App\Models\User $user */
        $user = Auth::guard('web')->user();

        $this->taxonomyService->updateBrand($brand, $validated, $user);

        return redirect()->route('admin.catalog.index')
            ->with('success', "Đã cập nhật thương hiệu '{$brand->name}' thành công.");
    }

    /**
     * Toggle brand active status.
     */
    public function toggleBrand(int $id): RedirectResponse
    {
        $brand = Brand::findOrFail($id);

        /** @var \App\Models\User $user */
        $user = Auth::guard('web')->user();

        $this->taxonomyService->toggleBrandActive($brand, $user);

        return back()->with('success', "Đã cập nhật trạng thái thương hiệu '{$brand->name}'.");
    }

    /**
     * Delete brand (DEC-08-02).
     */
    public function destroyBrand(int $id): RedirectResponse
    {
        $brand = Brand::findOrFail($id);

        /** @var \App\Models\User $user */
        $user = Auth::guard('web')->user();

        $this->taxonomyService->deleteBrand($brand, $user);

        return redirect()->route('admin.catalog.index')
            ->with('success', "Đã xóa thương hiệu '{$brand->name}' thành công.");
    }
}
