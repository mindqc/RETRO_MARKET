<?php

namespace App\Http\Controllers\Admin;

use App\Enums\AuctionStatus;
use App\Http\Controllers\Controller;
use App\Models\Auction;
use App\Services\Auction\AuctionLifecycleService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class AuctionManagementController extends Controller
{
    public function __construct(
        protected AuctionLifecycleService $auctionLifecycleService
    ) {}

    /**
     * Display list of auctions (Screens A-AC-01 & A-AC-03).
     */
    public function index(Request $request): View
    {
        $query = Auction::query()
            ->with(['product.primaryImage', 'seller', 'leadingBidder', 'winner', 'session']);

        // Search: auction_code, product title, seller name or email
        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('auction_code', 'ilike', "%{$search}%")
                    ->orWhereHas('product', fn ($pq) => $pq->where('title', 'ilike', "%{$search}%"))
                    ->orWhereHas('seller', fn ($sq) => $sq->where('display_name', 'ilike', "%{$search}%")->orWhere('email', 'ilike', "%{$search}%"));
            });
        }

        // Tab or Status Filter
        $tab = $request->input('tab', 'all');
        if ($tab === 'live') {
            $query->whereIn('status', [AuctionStatus::LIVE, AuctionStatus::SCHEDULED]);
        } elseif ($tab === 'history') {
            $query->whereIn('status', [AuctionStatus::COMPLETED, AuctionStatus::ENDED_UNSOLD, AuctionStatus::WINNER_DEFAULTED, AuctionStatus::CANCELLED]);
        } elseif ($tab === 'defaulted') {
            $query->where('status', AuctionStatus::WINNER_DEFAULTED);
        }

        if ($status = $request->input('status')) {
            $query->where('status', $status);
        }

        // Stats summary
        $stats = [
            'total' => Auction::count(),
            'live' => Auction::where('status', AuctionStatus::LIVE)->count(),
            'scheduled' => Auction::where('status', AuctionStatus::SCHEDULED)->count(),
            'completed' => Auction::where('status', AuctionStatus::COMPLETED)->count(),
            'defaulted' => Auction::where('status', AuctionStatus::WINNER_DEFAULTED)->count(),
            'cancelled' => Auction::where('status', AuctionStatus::CANCELLED)->count(),
        ];

        $auctions = $query->orderByDesc('id')->paginate(15)->withQueryString();

        return view('admin.auctions.index', compact('auctions', 'stats', 'tab'));
    }

    /**
     * Display detailed auction monitor / ticket-stub inspector (Screen A-AC-02).
     */
    public function show(int $id): View
    {
        $auction = Auction::with([
            'product.images',
            'product.category',
            'seller.sellerProfile',
            'leadingBidder',
            'winner',
            'session',
            'bids.bidder',
            'order.paidPayment',
        ])->findOrFail($id);

        // Sort bids newest first
        $bids = $auction->bids->sortByDesc('id');

        return view('admin.auctions.show', compact('auction', 'bids'));
    }

    /**
     * Cancel an active or scheduled auction (Administrative Intervention).
     */
    public function cancel(Request $request, int $id): RedirectResponse
    {
        $validated = $request->validate([
            'reason' => 'required|string|min:5|max:500',
        ], [
            'reason.required' => 'Vui lòng nhập lý do hủy phiên đấu giá.',
            'reason.min' => 'Lý do hủy phải có ít nhất 5 ký tự.',
        ]);

        try {
            $auction = $this->auctionLifecycleService->cancelAuctionByAdmin(
                $request->user(),
                $id,
                $validated['reason']
            );

            return redirect()->route('admin.auctions.show', $auction->id)
                ->with('success', "Phiên đấu giá #{$auction->auction_code} đã được hủy thành công.");
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', $e->getMessage())
                ->withInput();
        }
    }
}
