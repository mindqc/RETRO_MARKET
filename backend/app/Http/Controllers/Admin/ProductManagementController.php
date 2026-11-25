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

class ProductManagementController extends Controller
{
    public function __construct(
        protected ProductModerationService $moderationService
    ) {}

    /**
     * Display Master Product Inventory across all 7 statuses (Screen A-PR-01).
     */
    public function index(Request $request): View
    {
        $query = Product::query()
            ->with(['seller', 'category', 'brand', 'images']);

        // Filter: Status (all 7 statuses)
        if ($status = $request->input('status')) {
            $query->where('status', $status);
        }

        // Filter: Condition (5 levels)
        if ($condition = $request->input('condition')) {
            $query->where('condition', $condition);
        }

        // Filter: Listing Type
        if ($listingType = $request->input('listing_type')) {
            $query->where('listing_type', $listingType);
        }

        // Filter: Category
        if ($categoryId = $request->input('category_id')) {
            $query->where('category_id', $categoryId);
        }

        // Filter: Brand
        if ($brandId = $request->input('brand_id')) {
            $query->where('brand_id', $brandId);
        }

        // Filter: Search (code, title, seller)
        if ($search = trim($request->input('search', ''))) {
            $query->where(function ($q) use ($search) {
                $q->where('title', 'ilike', "%{$search}%")
                    ->orWhere('product_code', 'ilike', "%{$search}%")
                    ->orWhereHas('seller', function ($sq) use ($search) {
                        $sq->where('display_name', 'ilike', "%{$search}%")
                            ->orWhere('email', 'ilike', "%{$search}%");
                    });
            });
        }

        $products = $query->latest('id')->paginate(15)->withQueryString();

        $categories = Category::whereNull('parent_id')->with('children')->orderBy('name')->get();
        $brands = Brand::orderBy('name')->get();
        $conditions = ProductCondition::cases();
        $statuses = ProductStatus::cases();

        return view('admin.products.index', [
            'products' => $products,
            'categories' => $categories,
            'brands' => $brands,
            'conditions' => $conditions,
            'statuses' => $statuses,
            'filters' => $request->only(['status', 'condition', 'listing_type', 'category_id', 'brand_id', 'search']),
        ]);
    }

    /**
     * View detailed product record and full moderation logs.
     */
    public function show(int $id): View
    {
        $product = Product::with([
            'seller.profile',
            'category',
            'brand',
            'images',
            'moderationLogs' => fn ($q) => $q->with('moderator')->latest('id'),
        ])->findOrFail($id);

        return view('admin.products.show', [
            'product' => $product,
        ]);
    }

    /**
     * Administratively hide violating product listing (BR-PR-04).
     */
    public function hide(Request $request, int $id): RedirectResponse
    {
        $product = Product::findOrFail($id);

        $validated = $request->validate([
            'reason' => ['required', 'string', 'min:5', 'max:1000'],
        ], [
            'reason.required' => 'Bắt buộc phải nhập lý do khi ẩn sản phẩm.',
            'reason.min' => 'Lý do phải có tối thiểu 5 ký tự.',
        ]);

        /** @var \App\Models\User $user */
        $user = Auth::guard('web')->user();

        $this->moderationService->rejectOrHideProduct(
            moderator: $user,
            product: $product,
            action: 'HIDDEN',
            reason: $validated['reason']
        );

        return back()->with('success', "Đã tạm ẩn sản phẩm '{$product->title}' do vi phạm chính sách.");
    }

    /**
     * Restore visibility of previously hidden product.
     */
    public function unhide(Request $request, int $id): RedirectResponse
    {
        $product = Product::findOrFail($id);

        /** @var \App\Models\User $user */
        $user = Auth::guard('web')->user();

        $this->moderationService->approveProduct(
            moderator: $user,
            product: $product,
            verificationLevel: $product->verification_level ?? 'MODERATOR_REVIEWED',
            reason: $request->input('reason', 'Khôi phục hiển thị sản phẩm sau khi rà soát tuân thủ.')
        );

        return back()->with('success', "Đã khôi phục hiển thị sản phẩm '{$product->title}'.");
    }
}
