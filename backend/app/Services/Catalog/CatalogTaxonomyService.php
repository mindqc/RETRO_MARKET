<?php

namespace App\Services\Catalog;

use App\Enums\ProductStatus;
use App\Models\Brand;
use App\Models\Category;
use App\Models\User;
use App\Services\Governance\AuditLogService;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class CatalogTaxonomyService
{
    public function __construct(
        protected ?AuditLogService $auditLogService = null
    ) {
        $this->auditLogService = $auditLogService ?? app(AuditLogService::class);
    }

    /**
     * Retrieve active hierarchical category tree and active brands (M-DS-01).
     */
    public function getActiveTaxonomy(): array
    {
        $categories = Category::query()
            ->whereNull('parent_id')
            ->where('is_active', true)
            ->with(['children' => function ($query) {
                $query->where('is_active', true)
                    ->withCount(['products as approved_products_count' => function ($pq) {
                        $pq->where('status', ProductStatus::APPROVED);
                    }])
                    ->orderBy('sort_order');
            }])
            ->withCount(['products as approved_products_count' => function ($query) {
                $query->where('status', ProductStatus::APPROVED);
            }])
            ->orderBy('sort_order')
            ->get();

        $brands = Brand::query()
            ->where('is_active', true)
            ->withCount(['products as approved_products_count' => function ($query) {
                $query->where('status', ProductStatus::APPROVED);
            }])
            ->orderBy('name')
            ->get();

        return [
            'categories' => $categories,
            'brands' => $brands,
        ];
    }

    /**
     * Retrieve all categories (including inactive) with recursive tree and product counts (A-CT-01).
     */
    public function getAllCategoriesWithHierarchy(): Collection
    {
        return Category::query()
            ->whereNull('parent_id')
            ->with(['children' => function ($query) {
                $query->withCount('products')
                    ->orderBy('sort_order')
                    ->orderBy('name');
            }])
            ->withCount('products')
            ->orderBy('sort_order')
            ->orderBy('name')
            ->get();
    }

    /**
     * Retrieve all brands with product count (A-CT-01).
     */
    public function getAllBrands(): Collection
    {
        return Brand::query()
            ->withCount('products')
            ->orderBy('name')
            ->get();
    }

    /**
     * Create a new category with audit logging (DEC-08-02).
     */
    public function createCategory(array $data, User $actor): Category
    {
        $name = trim($data['name'] ?? '');
        $slug = trim($data['slug'] ?? '') ?: Str::slug($name);

        if (Category::where('slug', $slug)->exists()) {
            throw ValidationException::withMessages([
                'slug' => ['Đường dẫn danh mục (slug) đã tồn tại trong hệ thống.'],
            ]);
        }

        $parentId = !empty($data['parent_id']) ? (int) $data['parent_id'] : null;
        if ($parentId && !Category::where('id', $parentId)->exists()) {
            throw ValidationException::withMessages([
                'parent_id' => ['Danh mục cha không tồn tại.'],
            ]);
        }

        return DB::transaction(function () use ($data, $name, $slug, $parentId, $actor) {
            $category = Category::create([
                'name' => $name,
                'slug' => $slug,
                'parent_id' => $parentId,
                'icon_name' => $data['icon_name'] ?? null,
                'description' => $data['description'] ?? null,
                'sort_order' => (int) ($data['sort_order'] ?? 0),
                'is_active' => isset($data['is_active']) ? (bool) $data['is_active'] : true,
            ]);

            $this->auditLogService->record(
                actor: $actor,
                action: 'CATEGORY_CREATED',
                targetType: 'categories',
                targetId: $category->id,
                reason: 'Quản trị viên tạo mới danh mục ' . $category->name,
                oldValues: null,
                newValues: $category->toArray(),
                ipAddress: request()?->ip() ?? '127.0.0.1'
            );

            return $category;
        });
    }

    /**
     * Update category with circular reference check and audit logging (DEC-08-02).
     */
    public function updateCategory(Category $category, array $data, User $actor): Category
    {
        $name = trim($data['name'] ?? $category->name);
        $slug = trim($data['slug'] ?? '') ?: Str::slug($name);

        if (Category::where('slug', $slug)->where('id', '<>', $category->id)->exists()) {
            throw ValidationException::withMessages([
                'slug' => ['Đường dẫn danh mục (slug) đã tồn tại trong hệ thống.'],
            ]);
        }

        $parentId = array_key_exists('parent_id', $data)
            ? (!empty($data['parent_id']) ? (int) $data['parent_id'] : null)
            : $category->parent_id;

        // Circular hierarchy check
        if ($parentId !== null) {
            if ($parentId === $category->id) {
                throw ValidationException::withMessages([
                    'parent_id' => ['Danh mục không thể làm cha của chính nó (vòng lặp phả hệ).'],
                ]);
            }

            // Check if parentId is a descendant of this category
            $descendantIds = $this->getDescendantIds($category);
            if (in_array($parentId, $descendantIds, true)) {
                throw ValidationException::withMessages([
                    'parent_id' => ['Không thể chọn danh mục con làm danh mục cha (vòng lặp phả hệ).'],
                ]);
            }
        }

        return DB::transaction(function () use ($category, $data, $name, $slug, $parentId, $actor) {
            $oldValues = $category->toArray();

            $category->update([
                'name' => $name,
                'slug' => $slug,
                'parent_id' => $parentId,
                'icon_name' => $data['icon_name'] ?? $category->icon_name,
                'description' => $data['description'] ?? $category->description,
                'sort_order' => isset($data['sort_order']) ? (int) $data['sort_order'] : $category->sort_order,
                'is_active' => isset($data['is_active']) ? (bool) $data['is_active'] : $category->is_active,
            ]);

            $this->auditLogService->record(
                actor: $actor,
                action: 'CATEGORY_UPDATED',
                targetType: 'categories',
                targetId: $category->id,
                reason: 'Quản trị viên cập nhật danh mục ' . $category->name,
                oldValues: $oldValues,
                newValues: $category->fresh()->toArray(),
                ipAddress: request()?->ip() ?? '127.0.0.1'
            );

            return $category->fresh();
        });
    }

    /**
     * Toggle category active state (DEC-08-02).
     */
    public function toggleCategoryActive(Category $category, User $actor): Category
    {
        return DB::transaction(function () use ($category, $actor) {
            $oldActive = $category->is_active;
            $newActive = !$oldActive;

            $category->update(['is_active' => $newActive]);

            $this->auditLogService->record(
                actor: $actor,
                action: $newActive ? 'CATEGORY_ACTIVATED' : 'CATEGORY_DEACTIVATED',
                targetType: 'categories',
                targetId: $category->id,
                reason: ($newActive ? 'Kích hoạt' : 'Ẩn') . ' danh mục ' . $category->name,
                oldValues: ['is_active' => $oldActive],
                newValues: ['is_active' => $newActive],
                ipAddress: request()?->ip() ?? '127.0.0.1'
            );

            return $category;
        });
    }

    /**
     * Delete category preventing hard-delete if products exist (DEC-08-02).
     */
    public function deleteCategory(Category $category, User $actor): void
    {
        $hasProducts = $category->products()->exists() ||
            $category->children()->whereHas('products')->exists();

        if ($hasProducts) {
            throw ValidationException::withMessages([
                'category' => ['Không thể xóa danh mục đang có sản phẩm liên kết (DEC-08-02). Vui lòng ẩn danh mục hoặc điều chuyển sản phẩm trước.'],
            ]);
        }

        DB::transaction(function () use ($category, $actor) {
            $catId = $category->id;
            $catName = $category->name;
            $oldValues = $category->toArray();

            // Reparent any child categories to root
            $category->children()->update(['parent_id' => null]);

            $category->delete();

            $this->auditLogService->record(
                actor: $actor,
                action: 'CATEGORY_DELETED',
                targetType: 'categories',
                targetId: $catId,
                reason: 'Xóa danh mục ' . $catName,
                oldValues: $oldValues,
                newValues: null,
                ipAddress: request()?->ip() ?? '127.0.0.1'
            );
        });
    }

    /**
     * Create brand with validation and audit logging (DEC-08-02).
     */
    public function createBrand(array $data, User $actor): Brand
    {
        $name = trim($data['name'] ?? '');
        $slug = trim($data['slug'] ?? '') ?: Str::slug($name);

        if (Brand::where('name', $name)->exists()) {
            throw ValidationException::withMessages([
                'name' => ['Tên thương hiệu đã tồn tại.'],
            ]);
        }

        if (Brand::where('slug', $slug)->exists()) {
            throw ValidationException::withMessages([
                'slug' => ['Đường dẫn thương hiệu (slug) đã tồn tại.'],
            ]);
        }

        return DB::transaction(function () use ($data, $name, $slug, $actor) {
            $brand = Brand::create([
                'name' => $name,
                'slug' => $slug,
                'origin_country' => $data['origin_country'] ?? null,
                'logo_url' => $data['logo_url'] ?? null,
                'description' => $data['description'] ?? null,
                'is_active' => isset($data['is_active']) ? (bool) $data['is_active'] : true,
            ]);

            $this->auditLogService->record(
                actor: $actor,
                action: 'BRAND_CREATED',
                targetType: 'brands',
                targetId: $brand->id,
                reason: 'Quản trị viên tạo mới thương hiệu ' . $brand->name,
                oldValues: null,
                newValues: $brand->toArray(),
                ipAddress: request()?->ip() ?? '127.0.0.1'
            );

            return $brand;
        });
    }

    /**
     * Update brand with audit logging (DEC-08-02).
     */
    public function updateBrand(Brand $brand, array $data, User $actor): Brand
    {
        $name = trim($data['name'] ?? $brand->name);
        $slug = trim($data['slug'] ?? '') ?: Str::slug($name);

        if (Brand::where('name', $name)->where('id', '<>', $brand->id)->exists()) {
            throw ValidationException::withMessages([
                'name' => ['Tên thương hiệu đã tồn tại.'],
            ]);
        }

        if (Brand::where('slug', $slug)->where('id', '<>', $brand->id)->exists()) {
            throw ValidationException::withMessages([
                'slug' => ['Đường dẫn thương hiệu (slug) đã tồn tại.'],
            ]);
        }

        return DB::transaction(function () use ($brand, $data, $name, $slug, $actor) {
            $oldValues = $brand->toArray();

            $brand->update([
                'name' => $name,
                'slug' => $slug,
                'origin_country' => $data['origin_country'] ?? $brand->origin_country,
                'logo_url' => $data['logo_url'] ?? $brand->logo_url,
                'description' => $data['description'] ?? $brand->description,
                'is_active' => isset($data['is_active']) ? (bool) $data['is_active'] : $brand->is_active,
            ]);

            $this->auditLogService->record(
                actor: $actor,
                action: 'BRAND_UPDATED',
                targetType: 'brands',
                targetId: $brand->id,
                reason: 'Quản trị viên cập nhật thương hiệu ' . $brand->name,
                oldValues: $oldValues,
                newValues: $brand->fresh()->toArray(),
                ipAddress: request()?->ip() ?? '127.0.0.1'
            );

            return $brand->fresh();
        });
    }

    /**
     * Toggle brand active status.
     */
    public function toggleBrandActive(Brand $brand, User $actor): Brand
    {
        return DB::transaction(function () use ($brand, $actor) {
            $oldActive = $brand->is_active;
            $newActive = !$oldActive;

            $brand->update(['is_active' => $newActive]);

            $this->auditLogService->record(
                actor: $actor,
                action: $newActive ? 'BRAND_ACTIVATED' : 'BRAND_DEACTIVATED',
                targetType: 'brands',
                targetId: $brand->id,
                reason: ($newActive ? 'Kích hoạt' : 'Ẩn') . ' thương hiệu ' . $brand->name,
                oldValues: ['is_active' => $oldActive],
                newValues: ['is_active' => $newActive],
                ipAddress: request()?->ip() ?? '127.0.0.1'
            );

            return $brand;
        });
    }

    /**
     * Delete brand ensuring no products are linked.
     */
    public function deleteBrand(Brand $brand, User $actor): void
    {
        if ($brand->products()->exists()) {
            throw ValidationException::withMessages([
                'brand' => ['Không thể xóa thương hiệu đang có sản phẩm liên kết (DEC-08-02).'],
            ]);
        }

        DB::transaction(function () use ($brand, $actor) {
            $brandId = $brand->id;
            $brandName = $brand->name;
            $oldValues = $brand->toArray();

            $brand->delete();

            $this->auditLogService->record(
                actor: $actor,
                action: 'BRAND_DELETED',
                targetType: 'brands',
                targetId: $brandId,
                reason: 'Xóa thương hiệu ' . $brandName,
                oldValues: $oldValues,
                newValues: null,
                ipAddress: request()?->ip() ?? '127.0.0.1'
            );
        });
    }

    /**
     * Helper to get all descendant IDs recursively.
     */
    protected function getDescendantIds(Category $category): array
    {
        $ids = [];
        foreach ($category->children as $child) {
            $ids[] = $child->id;
            $ids = array_merge($ids, $this->getDescendantIds($child));
        }
        return $ids;
    }
}
