<?php

namespace App\Http\Controllers\Admin;

use App\Enums\ProductCondition;
use App\Enums\ProductStatus;
use App\Http\Controllers\Controller;
use App\Models\Brand;
use App\Models\Category;
use App\Models\Product;
use App\Services\Governance\ProductModerationService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

class ModerationController extends Controller
{
    public function __construct(
        protected ProductModerationService $moderationService
    ) {}

    /**
     * Display the Product Moderation Queue (Screen A-MD-01).
     */
    public function productQueue(Request $request): View
    {
        $query = Product::query()
            ->with(['seller', 'category', 'brand', 'images'])
            ->where('status', ProductStatus::PENDING_REVIEW);

        // Filter: Search (code or title)
        if ($search = trim($request->input('search', ''))) {
            $query->where(function ($q) use ($search) {
                $q->where('title', 'ilike', "%{$search}%")
                    ->orWhere('product_code', 'ilike', "%{$search}%");
            });
        }

        // Filter: Listing Type
        if ($listingType = $request->input('listing_type')) {
            $query->where('listing_type', $listingType);
        }

        // Filter: Condition (5 levels)
        if ($condition = $request->input('condition')) {
            $query->where('condition', $condition);
        }

        // Filter: Category
        if ($categoryId = $request->input('category_id')) {
            $query->where('category_id', $categoryId);
        }

        // Filter: Brand
        if ($brandId = $request->input('brand_id')) {
            $query->where('brand_id', $brandId);
        }

        $products = $query->latest('id')->paginate(12)->withQueryString();

        $categories = Category::whereNull('parent_id')->with('children')->orderBy('name')->get();
        $brands = Brand::orderBy('name')->get();
        $conditions = ProductCondition::cases();

        return view('admin.moderation.products.index', [
            'products' => $products,
            'categories' => $categories,
            'brands' => $brands,
            'conditions' => $conditions,
            'filters' => $request->only(['search', 'listing_type', 'condition', 'category_id', 'brand_id']),
        ]);
    }

    /**
     * Display Product Moderation Detail with Split-Pane Evidence & Defect Inspection (Screen A-MD-02).
     */
    public function productDetail(int $id): View
    {
        $product = Product::with([
            'seller.profile',
            'category',
            'brand',
            'images',
            'moderationLogs' => fn ($q) => $q->with('moderator')->latest('id'),
        ])->findOrFail($id);

        return view('admin.moderation.products.show', [
            'product' => $product,
        ]);
    }

    /**
     * Approve product listing (DEC-05).
     */
    public function approve(Request $request, int $id): RedirectResponse
    {
        $product = Product::findOrFail($id);

        $validated = $request->validate([
            'verification_level' => ['nullable', 'string', 'in:COMMUNITY_REPORTED,MODERATOR_REVIEWED,EXPERT_VERIFIED'],
            'reason' => ['nullable', 'string', 'max:500'],
        ]);

        /** @var \App\Models\User $user */
        $user = Auth::guard('web')->user();

        $this->moderationService->approveProduct(
            moderator: $user,
            product: $product,
            verificationLevel: $validated['verification_level'] ?? 'MODERATOR_REVIEWED',
            reason: $validated['reason'] ?? 'Sản phẩm đã được kiểm duyệt đạt chuẩn chất lượng.'
        );

        return redirect()->route('admin.moderation.products.index')
            ->with('success', "Đã duyệt và xuất bản sản phẩm '{$product->title}' thành công.");
    }

    /**
     * Reject product listing with mandatory reason (DEC-05).
     */
    public function reject(Request $request, int $id): RedirectResponse
    {
        $product = Product::findOrFail($id);

        $validated = $request->validate([
            'reason' => ['required', 'string', 'min:5', 'max:1000'],
        ], [
            'reason.required' => 'Bắt buộc phải nhập lý do khi từ chối sản phẩm (DEC-05).',
            'reason.min' => 'Lý do từ chối phải chứa tối thiểu 5 ký tự để hướng dẫn người bán sửa bài.',
        ]);

        /** @var \App\Models\User $user */
        $user = Auth::guard('web')->user();

        $this->moderationService->rejectOrHideProduct(
            moderator: $user,
            product: $product,
            action: 'REJECTED',
            reason: $validated['reason']
        );

        return redirect()->route('admin.moderation.products.index')
            ->with('success', "Đã từ chối bài đăng '{$product->title}'. Lý do đã được gửi tới người bán.");
    }
}
