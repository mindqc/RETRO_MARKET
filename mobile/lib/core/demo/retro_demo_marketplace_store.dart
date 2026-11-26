import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auctions/models/auction_bid_item_model.dart';
import '../../features/auctions/models/auction_card_model.dart';
import '../../features/auctions/models/auction_detail_model.dart';
import '../../features/catalog/models/category_model.dart';
import '../../features/catalog/models/product_detail_model.dart';
import '../../features/catalog/models/product_image_model.dart';
import '../../features/catalog/models/product_summary_model.dart';
import '../../features/catalog/models/seller_public_profile_model.dart';
import '../../features/home/models/auction_summary_model.dart';
import '../../features/home/models/featured_seller_model.dart';
import '../../features/orders/models/order_item_snapshot_model.dart';
import '../../features/orders/models/order_model.dart';
import '../../features/seller/models/seller_product_item_model.dart';
import '../utils/product_image_resolver.dart';

/// Rich metadata for nearby secondhand thrift shop cards displayed on Home & Storefront fallback.
class DemoNearbyShopInfo {
  final int sellerId;
  final String shopName;
  final String shopSlug;
  final String district;
  final String distanceLabel;
  final String specialtyTag;
  final String coverAsset;
  final String bio;
  final double trustScore;
  final double ratingAvg;
  final int completedOrdersCount;
  final int followersCount;
  final int activeItemsCount;

  const DemoNearbyShopInfo({
    required this.sellerId,
    required this.shopName,
    required this.shopSlug,
    required this.district,
    required this.distanceLabel,
    required this.specialtyTag,
    required this.coverAsset,
    required this.bio,
    required this.trustScore,
    required this.ratingAvg,
    required this.completedOrdersCount,
    required this.followersCount,
    required this.activeItemsCount,
  });

  FeaturedSellerModel toFeaturedSellerModel() => FeaturedSellerModel(
        id: sellerId,
        userId: sellerId,
        shopName: shopName,
        shopSlug: shopSlug,
        bio: bio,
        trustScore: trustScore,
        completedOrdersCount: completedOrdersCount,
        ratingAvg: ratingAvg,
        ratingCount: (completedOrdersCount / 3).round(),
      );
}

class _DemoCatalogSeed {
  final int id;
  final String title;
  final String slug;
  final String condition;
  final double price;
  final String imageAsset;
  final int sellerId;
  final String sellerName;
  final double sellerTrust;
  final int categoryId;
  final String categoryName;
  final String brandName;
  final String description;

  const _DemoCatalogSeed({
    required this.id,
    required this.title,
    required this.slug,
    required this.condition,
    required this.price,
    required this.imageAsset,
    required this.sellerId,
    required this.sellerName,
    required this.sellerTrust,
    required this.categoryId,
    required this.categoryName,
    required this.brandName,
    required this.description,
  });
}

/// Coherent demo-compatible marketplace state store for university presentations.
///
/// Rules:
/// - Never replaces working backend data when the API succeeds.
/// - Provides consistent, realistic Vietnamese vintage marketplace items across
///   Home Feed (44+ products, 8 nearby thrift shops), Product Detail, Auction Hub
///   (12 auctions across Ongoing / Ending Soon / Upcoming / Completed), Auction Room,
///   Chat Order Attachments, My Auctions, and Seller Listings.
/// - Newly submitted seller listings and auctions ALWAYS enter `PENDING_REVIEW`
///   and NEVER auto-publish to the public marketplace.
class RetroDemoMarketplaceStore extends ChangeNotifier {
  final List<SellerProductItemModel> _demoSubmittedListings = [];
  final Map<int, AuctionDetailModel> _demoAuctionsById = {};
  final Set<int> _registeredAuctionIds = <int>{};
  final Set<int> _favoritedProductIds = <int>{};
  final Set<int> _followedSellerIds = <int>{};
  int _nextDemoId = 9500;

  RetroDemoMarketplaceStore() {
    _seedConsistentDemoAuctions();
  }

  List<SellerProductItemModel> get demoSubmittedListings =>
      List.unmodifiable(_demoSubmittedListings);

  Set<int> get registeredAuctionIds => Set.unmodifiable(_registeredAuctionIds);

  bool isAuctionRegistered(int auctionId) =>
      _registeredAuctionIds.contains(auctionId);

  bool isProductFavorited(int productId) =>
      _favoritedProductIds.contains(productId);

  bool isSellerFollowed(int sellerId) =>
      _followedSellerIds.contains(sellerId);

  bool toggleLocalFollowSeller(int sellerId) {
    final bool nowFollowing;
    if (_followedSellerIds.contains(sellerId)) {
      _followedSellerIds.remove(sellerId);
      nowFollowing = false;
    } else {
      _followedSellerIds.add(sellerId);
      nowFollowing = true;
    }
    notifyListeners();
    return nowFollowing;
  }

  void toggleLocalFavorite(int productId) {
    if (_favoritedProductIds.contains(productId)) {
      _favoritedProductIds.remove(productId);
    } else {
      _favoritedProductIds.add(productId);
    }
    notifyListeners();
  }

  bool toggleLocalAuctionRegistration(int auctionId) {
    final bool nowRegistered;
    if (_registeredAuctionIds.contains(auctionId)) {
      _registeredAuctionIds.remove(auctionId);
      nowRegistered = false;
    } else {
      _registeredAuctionIds.add(auctionId);
      nowRegistered = true;
    }
    final existing = _demoAuctionsById[auctionId];
    if (existing != null) {
      _demoAuctionsById[auctionId] = existing.copyWith(
        isWatching: nowRegistered,
      );
    }
    notifyListeners();
    return nowRegistered;
  }

  /// Adds a seller-submitted listing (fixed price or auction) strictly as PENDING_REVIEW.
  /// Never auto-publishes to public discovery feeds.
  SellerProductItemModel addPendingSubmission({
    required String title,
    required String description,
    required int categoryId,
    required String categoryName,
    required String listingType,
    required double price,
    required int quantity,
    required String condition,
    required String defectInfo,
    required List<String> imageUrls,
    required bool submitForReview,
    double? startingPrice,
    double? minBidIncrement,
    double? reservePrice,
    DateTime? auctionStartsAt,
    DateTime? auctionEndsAt,
  }) {
    final id = _nextDemoId++;
    final status = submitForReview ? 'PENDING_REVIEW' : 'DRAFT';
    final primaryImg = imageUrls.isNotEmpty
        ? imageUrls.first
        : ProductImageResolver.fallbackAssetFor(
            title: title,
            categoryName: categoryName,
            id: id,
          );

    final item = SellerProductItemModel(
      id: id,
      productCode: 'PRD-DEMO-$id',
      title: title,
      description: description,
      slug: 'demo-$id',
      listingType: listingType.toUpperCase(),
      condition: condition.toUpperCase(),
      defectInfo: defectInfo,
      price: price,
      availableQuantity: listingType.toUpperCase() == 'AUCTION' ? 1 : quantity,
      status: status,
      primaryImageUrl: primaryImg,
      categoryId: categoryId,
      categoryName: categoryName,
      startingPrice: startingPrice,
      bidIncrement: minBidIncrement,
      reservePrice: reservePrice,
      auctionStartsAt: auctionStartsAt,
      auctionEndsAt: auctionEndsAt,
    );

    _demoSubmittedListings.insert(0, item);
    notifyListeners();
    return item;
  }

  /// Simulated demo bid update when backend bidding endpoint is unreachable.
  /// Updates consistent auction detail, highest bid, minimum next bid, and bid history.
  AuctionDetailModel? placeLocalDemoBid({
    required int auctionId,
    required double bidAmount,
    String bidderName = 'Minh Khôi (Demo)',
    int bidderId = 999,
  }) {
    final current = _demoAuctionsById[auctionId];
    if (current == null || !current.isLive) return null;
    if (bidAmount < current.minimumNextBid) return null;

    final now = DateTime.now();
    final remaining = current.auctionEndsAt.difference(now);
    final triggeredAntiSniping =
        remaining.inSeconds > 0 && remaining.inSeconds <= 120;
    final nextEnd = triggeredAntiSniping
        ? current.auctionEndsAt.add(const Duration(minutes: 2))
        : current.auctionEndsAt;

    final newBid = AuctionBidItemModel(
      id: now.millisecondsSinceEpoch,
      auctionId: auctionId,
      bidderId: bidderId,
      bidderName: bidderName,
      bidAmount: bidAmount,
      createdAt: now,
      triggeredAntiSniping: triggeredAntiSniping,
      isMine: true,
    );

    final updated = current.copyWith(
      currentHighestBid: bidAmount,
      minimumNextBid: bidAmount + current.minBidIncrement,
      bidCount: current.bidCount + 1,
      auctionEndsAt: nextEnd,
      extendedCount:
          triggeredAntiSniping ? current.extendedCount + 1 : current.extendedCount,
      leadingBidderId: bidderId,
      leadingBidderName: bidderName,
      isLeading: true,
      isOutbid: false,
      reservePriceMet:
          current.reservePrice == null || bidAmount >= current.reservePrice!,
      recentBids: [newBid, ...current.recentBids],
    );

    _demoAuctionsById[auctionId] = updated;
    notifyListeners();
    return updated;
  }

  AuctionDetailModel? getDemoAuctionDetail(int auctionId) =>
      _demoAuctionsById[auctionId];

  List<AuctionSummaryModel> get demoHomeAuctionSummaries {
    final active = _demoAuctionsById.values.where((a) => !a.isCompleted).toList()
      ..sort((a, b) {
        if (a.isLive && !b.isLive) return -1;
        if (!a.isLive && b.isLive) return 1;
        return a.auctionEndsAt.compareTo(b.auctionEndsAt);
      });
    return active
        .map(
          (a) => AuctionSummaryModel(
            id: a.id,
            productId: a.productId,
            title: a.productTitle,
            currentBid: a.currentHighestBid,
            startingPrice: a.startingPrice,
            bidCount: a.bidCount,
            watchCount: a.watchCount,
            startsAt: a.auctionStartsAt,
            endsAt: a.auctionEndsAt,
            primaryImageUrl: a.primaryImageUrl,
            categoryName: a.categoryName,
            status: a.status,
            extendedCount: a.extendedCount,
            isOwner: a.isOwner,
            sellerDisplayName: a.sellerDisplayName,
          ),
        )
        .toList();
  }

  List<AuctionCardModel> demoAuctionCardsForTab(String tab) {
    final now = DateTime.now();
    final all = _demoAuctionsById.values.map(_toCardModel).toList();
    switch (tab) {
      case 'all':
        all.sort((a, b) {
          int rank(AuctionCardModel m) {
            if (m.isLive && m.auctionEndsAt.difference(now).inMinutes <= 15) {
              return 0;
            }
            if (m.isLive) return 1;
            if (m.isScheduled) return 2;
            return 3;
          }

          final diff = rank(a).compareTo(rank(b));
          return diff != 0 ? diff : a.auctionEndsAt.compareTo(b.auctionEndsAt);
        });
        return all;
      case 'live':
        final live = all.where((a) => a.isLive).toList()
          ..sort((a, b) => a.auctionEndsAt.compareTo(b.auctionEndsAt));
        return live;
      case 'ending_soon':
        final ending = all
            .where(
              (a) =>
                  a.isLive &&
                  a.auctionEndsAt.isAfter(now) &&
                  a.auctionEndsAt.difference(now).inMinutes <= 15,
            )
            .toList()
          ..sort((a, b) => a.auctionEndsAt.compareTo(b.auctionEndsAt));
        return ending;
      case 'upcoming':
        final upcoming = all.where((a) => a.isScheduled).toList()
          ..sort(
            (a, b) => (a.auctionStartsAt ?? a.auctionEndsAt)
                .compareTo(b.auctionStartsAt ?? b.auctionEndsAt),
          );
        return upcoming;
      case 'completed':
        return all.where((a) => a.isCompleted).toList();
      case 'watchlist':
        return all.where((a) => a.isWatching).toList();
      case 'participating':
        return all.where((a) => a.myHighestBid != null || a.isLeading).toList();
      case 'won':
        return all.where((a) => a.myBidStatus == 'WON').toList();
      default:
        return all;
    }
  }

  AuctionCardModel _toCardModel(AuctionDetailModel a) {
    final myBids = a.recentBids.where((b) => b.isMine).toList();
    return AuctionCardModel(
      id: a.id,
      auctionCode: a.auctionCode,
      productId: a.productId,
      sellerId: a.sellerId,
      startingPrice: a.startingPrice,
      minBidIncrement: a.minBidIncrement,
      currentHighestBid: a.currentHighestBid,
      bidCount: a.bidCount,
      watchCount: a.watchCount,
      status: a.status,
      auctionStartsAt: a.auctionStartsAt,
      auctionEndsAt: a.auctionEndsAt,
      extendedCount: a.extendedCount,
      productTitle: a.productTitle,
      productSlug: a.productSlug,
      primaryImageUrl: a.primaryImageUrl,
      categoryName: a.categoryName,
      condition: a.condition,
      sellerDisplayName: a.sellerDisplayName,
      sellerShopSlug: a.sellerShopSlug,
      sellerTrustScore: a.sellerTrustScore,
      leadingBidderId: a.leadingBidderId,
      leadingBidderName: a.leadingBidderName,
      myHighestBid: myBids.isNotEmpty ? myBids.first.bidAmount : null,
      myBidStatus: a.myBidStatus ?? (a.isLeading ? 'LEADING' : null),
      isWatching: a.isWatching || _registeredAuctionIds.contains(a.id),
      isOwner: a.isOwner,
    );
  }

  /// 12 curated demo auctions spanning Ongoing (4), Ending Soon (3), Upcoming (4), Completed (1).
  /// Auction #9001 & #9002 are flagship interactive demo auctions supporting live bidding.
  void _seedConsistentDemoAuctions() {
    final now = DateTime.now();

    // 1. Flagship Interactive Ongoing Auction (LIVE — 24m remaining)
    _demoAuctionsById[9001] = AuctionDetailModel(
      id: 9001,
      auctionCode: 'AUC-2026-9001',
      productId: 9101,
      sellerId: 501,
      startingPrice: 1200000,
      minBidIncrement: 50000,
      minimumNextBid: 1550000,
      currentHighestBid: 1500000,
      hasReservePrice: true,
      reservePriceMet: true,
      reservePrice: 1400000,
      bidCount: 14,
      watchCount: 42,
      status: 'LIVE',
      auctionStartsAt: now.subtract(const Duration(hours: 1)),
      auctionEndsAt: now.add(const Duration(minutes: 24, seconds: 42)),
      extendedCount: 0,
      productTitle: 'Máy Ảnh Phim SLR Cổ Nikon F3 50mm f/1.4 Đời 1982',
      productSlug: 'may-anh-phim-slr-nikon-f3',
      productDescription:
          'Thân máy cơ bền bỉ, đo sáng hoạt động chuẩn xác, kèm ống kính 50mm kính trong không mốc rễ. Đã vệ sinh kiểm tra tại Tiệm Phim Chú Bảy.',
      primaryImageUrl: ProductImageResolver.assetFilmCamera,
      productImages: const [ProductImageResolver.assetFilmCamera],
      categoryName: 'Đồ cổ',
      condition: 'LIKE_NEW',
      authenticityGuarantee: true,
      sellerDisplayName: 'Tiệm Phim & Đồ Cổ Chú Bảy',
      sellerShopSlug: 'tiem-phim-chu-bay',
      sellerTrustScore: 98,
      leadingBidderId: 701,
      leadingBidderName: 'Minh Khoa',
      recentBids: [
        AuctionBidItemModel(
          id: 1,
          auctionId: 9001,
          bidderId: 701,
          bidderName: 'Minh Khoa',
          bidAmount: 1500000,
          createdAt: now.subtract(const Duration(minutes: 2)),
        ),
        AuctionBidItemModel(
          id: 2,
          auctionId: 9001,
          bidderId: 702,
          bidderName: 'Thảo Vy',
          bidAmount: 1450000,
          createdAt: now.subtract(const Duration(minutes: 7)),
        ),
        AuctionBidItemModel(
          id: 3,
          auctionId: 9001,
          bidderId: 703,
          bidderName: 'Hoàng Nam',
          bidAmount: 1350000,
          createdAt: now.subtract(const Duration(minutes: 15)),
        ),
      ],
    );

    // 2. Ending Soon (LIVE — 4m25s remaining, Anti-Sniping active)
    _demoAuctionsById[9002] = AuctionDetailModel(
      id: 9002,
      auctionCode: 'AUC-2026-9002',
      productId: 9102,
      sellerId: 502,
      startingPrice: 850000,
      minBidIncrement: 50000,
      minimumNextBid: 1150000,
      currentHighestBid: 1100000,
      bidCount: 11,
      watchCount: 34,
      status: 'LIVE',
      auctionStartsAt: now.subtract(const Duration(minutes: 40)),
      auctionEndsAt: now.add(const Duration(minutes: 4, seconds: 25)),
      extendedCount: 1,
      productTitle: 'Đồng Hồ Cơ Tự Động 17 Jewels Mặt Kem Dây Da 70s',
      productSlug: 'dong-ho-co-tu-dong-17-jewels-70s',
      productDescription:
          'Đồng hồ cơ lên cót tự động mặt số kem nguyên bản, vỏ thép chải xước nhẹ đúng chất vintage, dây da bò khâu tay mới thay.',
      primaryImageUrl: ProductImageResolver.assetMechanicalWatch,
      productImages: const [ProductImageResolver.assetMechanicalWatch],
      categoryName: 'Watches',
      condition: 'GOOD',
      authenticityGuarantee: true,
      sellerDisplayName: 'Retro Closet Quận 1',
      sellerShopSlug: 'retro-closet-quan-1',
      sellerTrustScore: 98,
      leadingBidderId: 704,
      leadingBidderName: 'Quốc Bảo',
      recentBids: [
        AuctionBidItemModel(
          id: 4,
          auctionId: 9002,
          bidderId: 704,
          bidderName: 'Quốc Bảo',
          bidAmount: 1100000,
          createdAt: now.subtract(const Duration(seconds: 48)),
          triggeredAntiSniping: true,
        ),
        AuctionBidItemModel(
          id: 5,
          auctionId: 9002,
          bidderId: 705,
          bidderName: 'Lan Anh',
          bidAmount: 1050000,
          createdAt: now.subtract(const Duration(minutes: 4)),
        ),
      ],
    );

    // 3. Ending Soon (LIVE — 8m15s remaining)
    _demoAuctionsById[9009] = AuctionDetailModel(
      id: 9009,
      auctionCode: 'AUC-2026-9009',
      productId: 9109,
      sellerId: 505,
      startingPrice: 520000,
      minBidIncrement: 30000,
      minimumNextBid: 760000,
      currentHighestBid: 730000,
      bidCount: 8,
      watchCount: 29,
      status: 'LIVE',
      auctionStartsAt: now.subtract(const Duration(minutes: 52)),
      auctionEndsAt: now.add(const Duration(minutes: 8, seconds: 15)),
      extendedCount: 0,
      productTitle: 'Giày Sneaker Da Lộn Retro Court 88 Phối Xanh Rêu Size 41',
      productSlug: 'giay-sneaker-da-lon-retro-court-88',
      productDescription:
          'Bản sưu tầm da lộn màu xanh rêu phối kem cực hiếm, đế cao su bám tốt chưa mòn gót, đã spa sạch thơm.',
      primaryImageUrl: ProductImageResolver.assetRetroSneakers,
      productImages: const [ProductImageResolver.assetRetroSneakers],
      categoryName: 'Sneakers',
      condition: 'LIKE_NEW',
      authenticityGuarantee: true,
      sellerDisplayName: 'Tiệm Giày Si Phú Nhuận',
      sellerShopSlug: 'tiem-giay-si-phu-nhuan',
      sellerTrustScore: 96,
      leadingBidderId: 709,
      leadingBidderName: 'Tuấn Kiệt',
      recentBids: [
        AuctionBidItemModel(
          id: 11,
          auctionId: 9009,
          bidderId: 709,
          bidderName: 'Tuấn Kiệt',
          bidAmount: 730000,
          createdAt: now.subtract(const Duration(minutes: 1)),
        ),
        AuctionBidItemModel(
          id: 12,
          auctionId: 9009,
          bidderId: 710,
          bidderName: 'Gia Hân',
          bidAmount: 700000,
          createdAt: now.subtract(const Duration(minutes: 5)),
        ),
      ],
    );

    // 4. Ending Soon (LIVE — 12m40s remaining)
    _demoAuctionsById[9010] = AuctionDetailModel(
      id: 9010,
      auctionCode: 'AUC-2026-9010',
      productId: 9110,
      sellerId: 507,
      startingPrice: 360000,
      minBidIncrement: 20000,
      minimumNextBid: 520000,
      currentHighestBid: 500000,
      bidCount: 7,
      watchCount: 23,
      status: 'LIVE',
      auctionStartsAt: now.subtract(const Duration(minutes: 45)),
      auctionEndsAt: now.add(const Duration(minutes: 12, seconds: 40)),
      extendedCount: 0,
      productTitle: 'Sơ Mi Len Pendleton USA Kẻ Caro Đỏ Đô Thập Niên 80s',
      productSlug: 'so-mi-len-pendleton-usa-80s',
      productDescription:
          'Chất len virgin wool dệt tại Mỹ, họa tiết caro cổ điển sắc nét, tem xanh cổ điển còn nguyên vẹn.',
      primaryImageUrl: ProductImageResolver.assetFlannelShirt,
      productImages: const [ProductImageResolver.assetFlannelShirt],
      categoryName: 'Vintage Shirt',
      condition: 'LIKE_NEW',
      authenticityGuarantee: true,
      sellerDisplayName: 'Saigon Archive Tân Bình',
      sellerShopSlug: 'saigon-archive-tan-binh',
      sellerTrustScore: 97,
      leadingBidderId: 711,
      leadingBidderName: 'Khánh Linh',
      recentBids: [
        AuctionBidItemModel(
          id: 13,
          auctionId: 9010,
          bidderId: 711,
          bidderName: 'Khánh Linh',
          bidAmount: 500000,
          createdAt: now.subtract(const Duration(minutes: 3)),
        ),
      ],
    );

    // 5. Ongoing (LIVE — 42m remaining)
    _demoAuctionsById[9006] = AuctionDetailModel(
      id: 9006,
      auctionCode: 'AUC-2026-9006',
      productId: 9106,
      sellerId: 501,
      startingPrice: 1350000,
      minBidIncrement: 50000,
      minimumNextBid: 1700000,
      currentHighestBid: 1650000,
      hasReservePrice: true,
      reservePriceMet: true,
      reservePrice: 1500000,
      bidCount: 10,
      watchCount: 31,
      status: 'LIVE',
      auctionStartsAt: now.subtract(const Duration(minutes: 35)),
      auctionEndsAt: now.add(const Duration(minutes: 42, seconds: 10)),
      extendedCount: 0,
      productTitle: 'Đồng Hồ Seiko Chronograph 6139 Mặt Xanh Khói 1979',
      productSlug: 'dong-ho-seiko-chronograph-6139',
      productDescription:
          'Dòng bấm giờ cơ học huyền thoại của Seiko thập niên 70, kim reset chuẩn 12h, kính khoáng trong đẹp.',
      primaryImageUrl: ProductImageResolver.assetMechanicalWatch,
      productImages: const [ProductImageResolver.assetMechanicalWatch],
      categoryName: 'Watches',
      condition: 'GOOD',
      authenticityGuarantee: true,
      sellerDisplayName: 'Tiệm Phim & Đồ Cổ Chú Bảy',
      sellerShopSlug: 'tiem-phim-chu-bay',
      sellerTrustScore: 98,
      leadingBidderId: 712,
      leadingBidderName: 'Nhật Minh',
      recentBids: [
        AuctionBidItemModel(
          id: 14,
          auctionId: 9006,
          bidderId: 712,
          bidderName: 'Nhật Minh',
          bidAmount: 1650000,
          createdAt: now.subtract(const Duration(minutes: 6)),
        ),
      ],
    );

    // 6. Ongoing (LIVE — 58m remaining)
    _demoAuctionsById[9007] = AuctionDetailModel(
      id: 9007,
      auctionCode: 'AUC-2026-9007',
      productId: 9107,
      sellerId: 504,
      startingPrice: 680000,
      minBidIncrement: 30000,
      minimumNextBid: 890000,
      currentHighestBid: 860000,
      bidCount: 9,
      watchCount: 28,
      status: 'LIVE',
      auctionStartsAt: now.subtract(const Duration(minutes: 25)),
      auctionEndsAt: now.add(const Duration(minutes: 58, seconds: 30)),
      extendedCount: 0,
      productTitle: "Áo Khoác Denim Jacket Levi's Type III Made in USA 80s",
      productSlug: 'ao-khoac-denim-levis-type-3-80s',
      productDescription:
          'Form boxy ngắn cổ điển chuẩn Mỹ, chất vải 14oz lên màu fade tự nhiên cực đẹp, tem đỏ big E sưu tầm.',
      primaryImageUrl: ProductImageResolver.assetVarsityJacket,
      productImages: const [ProductImageResolver.assetVarsityJacket],
      categoryName: 'Denim Jacket',
      condition: 'GOOD',
      authenticityGuarantee: true,
      sellerDisplayName: 'Thrift Corner Bình Thạnh',
      sellerShopSlug: 'thrift-corner-binh-thanh',
      sellerTrustScore: 95,
      leadingBidderId: 713,
      leadingBidderName: 'Hải Đăng',
      recentBids: [
        AuctionBidItemModel(
          id: 15,
          auctionId: 9007,
          bidderId: 713,
          bidderName: 'Hải Đăng',
          bidAmount: 860000,
          createdAt: now.subtract(const Duration(minutes: 9)),
        ),
      ],
    );

    // 7. Ongoing (LIVE — 1h18m remaining)
    _demoAuctionsById[9008] = AuctionDetailModel(
      id: 9008,
      auctionCode: 'AUC-2026-9008',
      productId: 9108,
      sellerId: 506,
      startingPrice: 750000,
      minBidIncrement: 40000,
      minimumNextBid: 990000,
      currentHighestBid: 950000,
      bidCount: 6,
      watchCount: 25,
      status: 'LIVE',
      auctionStartsAt: now.subtract(const Duration(minutes: 15)),
      auctionEndsAt: now.add(const Duration(hours: 1, minutes: 18)),
      extendedCount: 0,
      productTitle: 'Túi Xách Da Bò Coach Turnlock Vintage Nâu Cognac 90s',
      productSlug: 'tui-da-coach-turnlock-90s',
      productDescription:
          'Da glovetanned nguyên tấm cực mềm bóng, khóa đồng xoay nguyên bản, lót da lộn sạch sẽ.',
      primaryImageUrl: ProductImageResolver.assetLeatherBag,
      productImages: const [ProductImageResolver.assetLeatherBag],
      categoryName: 'Leather Bags',
      condition: 'LIKE_NEW',
      authenticityGuarantee: true,
      sellerDisplayName: 'Xưởng Đồ Da Cũ Thủ Đức',
      sellerShopSlug: 'xuong-do-da-cu-thu-duc',
      sellerTrustScore: 99,
      leadingBidderId: 714,
      leadingBidderName: 'Phương Uyên',
      recentBids: [
        AuctionBidItemModel(
          id: 16,
          auctionId: 9008,
          bidderId: 714,
          bidderName: 'Phương Uyên',
          bidAmount: 950000,
          createdAt: now.subtract(const Duration(minutes: 11)),
        ),
      ],
    );

    // 8. Upcoming (SCHEDULED — starts in 1h24m)
    _demoAuctionsById[9003] = AuctionDetailModel(
      id: 9003,
      auctionCode: 'AUC-2026-9003',
      productId: 9103,
      sellerId: 503,
      startingPrice: 650000,
      minBidIncrement: 30000,
      minimumNextBid: 680000,
      currentHighestBid: 650000,
      bidCount: 0,
      watchCount: 36,
      status: 'SCHEDULED',
      auctionStartsAt: now.add(const Duration(hours: 1, minutes: 24)),
      auctionEndsAt: now.add(const Duration(hours: 3, minutes: 24)),
      productTitle: 'Áo Khoác Varsity Len Xanh Rêu Tay Da Kem 90s Độc Bản',
      productSlug: 'ao-khoac-varsity-len-xanh-reu-90s',
      productDescription:
          'Áo khoác varsity chất dạ len dày dặn phối tay da kem mềm mại, bo cổ sọc cổ điển cực hiếm size L châu Á.',
      primaryImageUrl: ProductImageResolver.assetVarsityJacket,
      productImages: const [ProductImageResolver.assetVarsityJacket],
      categoryName: 'Outerwear',
      condition: 'LIKE_NEW',
      authenticityGuarantee: true,
      sellerDisplayName: 'Vintage House Quận 3',
      sellerShopSlug: 'vintage-house-quan-3',
      sellerTrustScore: 97,
      recentBids: const [],
    );

    // 9. Upcoming (SCHEDULED — starts in 2h45m)
    _demoAuctionsById[9004] = AuctionDetailModel(
      id: 9004,
      auctionCode: 'AUC-2026-9004',
      productId: 9104,
      sellerId: 506,
      startingPrice: 480000,
      minBidIncrement: 20000,
      minimumNextBid: 500000,
      currentHighestBid: 480000,
      bidCount: 0,
      watchCount: 22,
      status: 'SCHEDULED',
      auctionStartsAt: now.add(const Duration(hours: 2, minutes: 45)),
      auctionEndsAt: now.add(const Duration(hours: 4, minutes: 45)),
      productTitle: 'Túi Đeo Chéo Da Bò Sáp Khóa Đồng Cổ Điển',
      productSlug: 'tui-deo-cheo-da-bo-sap-khoa-dong',
      productDescription:
          'Túi da bò thật nguyên miếng lên màu patina tự nhiên cực đẹp, khóa đồng đúc chắc chắn, vừa laptop 13 inch.',
      primaryImageUrl: ProductImageResolver.assetLeatherBag,
      productImages: const [ProductImageResolver.assetLeatherBag],
      categoryName: 'Leather Bags',
      condition: 'GOOD',
      sellerDisplayName: 'Xưởng Đồ Da Cũ Thủ Đức',
      sellerShopSlug: 'xuong-do-da-cu-thu-duc',
      sellerTrustScore: 99,
      recentBids: const [],
    );

    // 10. Upcoming (SCHEDULED — starts in 4h15m)
    _demoAuctionsById[9011] = AuctionDetailModel(
      id: 9011,
      auctionCode: 'AUC-2026-9011',
      productId: 9111,
      sellerId: 508,
      startingPrice: 390000,
      minBidIncrement: 20000,
      minimumNextBid: 410000,
      currentHighestBid: 390000,
      bidCount: 0,
      watchCount: 27,
      status: 'SCHEDULED',
      auctionStartsAt: now.add(const Duration(hours: 4, minutes: 15)),
      auctionEndsAt: now.add(const Duration(hours: 6, minutes: 15)),
      productTitle: 'Áo Thun Mỹ Boxy Tee Single Stitch Rock Tour 1994',
      productSlug: 'ao-thun-my-boxy-tee-1994',
      productDescription:
          'Áo thun Mỹ đường may đơn (single stitch) thập niên 90, hình in nứt nhẹ đúng chất archive sưu tầm.',
      primaryImageUrl: ProductImageResolver.assetFlannelShirt,
      productImages: const [ProductImageResolver.assetFlannelShirt],
      categoryName: 'American Tee',
      condition: 'VINTAGE_WORN',
      authenticityGuarantee: true,
      sellerDisplayName: '2hand Lab Quận 10',
      sellerShopSlug: '2hand-lab-quan-10',
      sellerTrustScore: 96,
      recentBids: const [],
    );

    // 11. Upcoming (SCHEDULED — starts in 5h50m)
    _demoAuctionsById[9012] = AuctionDetailModel(
      id: 9012,
      auctionCode: 'AUC-2026-9012',
      productId: 9112,
      sellerId: 503,
      startingPrice: 440000,
      minBidIncrement: 25000,
      minimumNextBid: 465000,
      currentHighestBid: 440000,
      bidCount: 0,
      watchCount: 18,
      status: 'SCHEDULED',
      auctionStartsAt: now.add(const Duration(hours: 5, minutes: 50)),
      auctionEndsAt: now.add(const Duration(hours: 7, minutes: 50)),
      productTitle: 'Áo Len Cardigan Mohair Dệt Nổi Nhật Bản Size M-L',
      productSlug: 'ao-len-cardigan-mohair-nhat',
      productDescription:
          'Len lông xù mềm ấm không dặm ngứa, cúc gỗ cổ điển, màu rêu trầm phối đỏ đô chuẩn phong cách mùa đông.',
      primaryImageUrl: ProductImageResolver.assetKnitCardigan,
      productImages: const [ProductImageResolver.assetKnitCardigan],
      categoryName: 'Sweaters',
      condition: 'LIKE_NEW',
      sellerDisplayName: 'Vintage House Quận 3',
      sellerShopSlug: 'vintage-house-quan-3',
      sellerTrustScore: 97,
      recentBids: const [],
    );

    // 12. Completed Auction
    _demoAuctionsById[9005] = AuctionDetailModel(
      id: 9005,
      auctionCode: 'AUC-2026-9005',
      productId: 9105,
      sellerId: 502,
      startingPrice: 420000,
      minBidIncrement: 20000,
      minimumNextBid: 640000,
      currentHighestBid: 620000,
      bidCount: 11,
      watchCount: 24,
      status: 'COMPLETED',
      auctionStartsAt: now.subtract(const Duration(hours: 5)),
      auctionEndsAt: now.subtract(const Duration(minutes: 25)),
      productTitle: 'Quần Jean Selvedge Ống Đứng Thập Niên 90s Size 31',
      productSlug: 'quan-jean-selvedge-90s-size-31',
      productDescription:
          'Denim biên đỏ dày 14oz, màu wash tự nhiên đều đẹp, khóa nút kim loại nguyên bản.',
      primaryImageUrl: ProductImageResolver.assetDenimJeans,
      productImages: const [ProductImageResolver.assetDenimJeans],
      categoryName: 'Flare Jeans',
      condition: 'GOOD',
      sellerDisplayName: 'Retro Closet Quận 1',
      sellerShopSlug: 'retro-closet-quan-1',
      sellerTrustScore: 98,
      winnerId: 708,
      winnerDisplayName: 'Đức Anh',
      recentBids: [
        AuctionBidItemModel(
          id: 9,
          auctionId: 9005,
          bidderId: 708,
          bidderName: 'Đức Anh',
          bidAmount: 620000,
          createdAt: now.subtract(const Duration(minutes: 26)),
        ),
      ],
    );
  }

  /// 8 diverse curated nearby thrift shops for Home "Tiệm đồ si ở gần bạn" shop cards
  /// and Seller Storefront demo resolution.
  static const List<DemoNearbyShopInfo> demoNearbyShops = [
    DemoNearbyShopInfo(
      sellerId: 502,
      shopName: 'Retro Closet Quận 1',
      shopSlug: 'retro-closet-quan-1',
      district: 'Quận 1, TP.HCM',
      distanceLabel: '0,8 km',
      specialtyTag: 'Outerwear & Flannel',
      coverAsset: ProductImageResolver.assetVarsityJacket,
      bio: 'Tuyển chọn áo khoác varsity, flannel Mỹ và đồ si 90s đã giặt hấp sạch sẽ.',
      trustScore: 98.0,
      ratingAvg: 4.9,
      completedOrdersCount: 328,
      followersCount: 589,
      activeItemsCount: 42,
    ),
    DemoNearbyShopInfo(
      sellerId: 503,
      shopName: 'Vintage House Quận 3',
      shopSlug: 'vintage-house-quan-3',
      district: 'Quận 3, TP.HCM',
      distanceLabel: '1,3 km',
      specialtyTag: 'Sweaters & Cardigan',
      coverAsset: ProductImageResolver.assetKnitCardigan,
      bio: 'Len cardigan, sweater dệt kim và thời trang hoài cổ tuyển chọn mỗi tuần.',
      trustScore: 97.0,
      ratingAvg: 4.8,
      completedOrdersCount: 210,
      followersCount: 346,
      activeItemsCount: 35,
    ),
    DemoNearbyShopInfo(
      sellerId: 504,
      shopName: 'Thrift Corner Bình Thạnh',
      shopSlug: 'thrift-corner-binh-thanh',
      district: 'Bình Thạnh, TP.HCM',
      distanceLabel: '2,1 km',
      specialtyTag: 'Denim & Flare Jeans',
      coverAsset: ProductImageResolver.assetDenimJeans,
      bio: 'Chuyên denim selvedge, quần jean ống loe và áo khoác jean USA thập niên 80-90.',
      trustScore: 95.0,
      ratingAvg: 4.8,
      completedOrdersCount: 184,
      followersCount: 274,
      activeItemsCount: 29,
    ),
    DemoNearbyShopInfo(
      sellerId: 505,
      shopName: 'Tiệm Giày Si Phú Nhuận',
      shopSlug: 'tiem-giay-si-phu-nhuan',
      district: 'Phú Nhuận, TP.HCM',
      distanceLabel: '2,6 km',
      specialtyTag: 'Sneakers & Boots',
      coverAsset: ProductImageResolver.assetRetroSneakers,
      bio: 'Sneaker da lộn retro, giày classic kiểm định đế và form kỹ lưỡng trước khi bán.',
      trustScore: 96.0,
      ratingAvg: 4.8,
      completedOrdersCount: 156,
      followersCount: 229,
      activeItemsCount: 26,
    ),
    DemoNearbyShopInfo(
      sellerId: 506,
      shopName: 'Xưởng Đồ Da Cũ Thủ Đức',
      shopSlug: 'xuong-do-da-cu-thu-duc',
      district: 'TP. Thủ Đức',
      distanceLabel: '4,2 km',
      specialtyTag: 'Leather Bags & Belts',
      coverAsset: ProductImageResolver.assetLeatherBag,
      bio: 'Túi đeo chéo da bò sáp, túi Coach cổ và phụ kiện da thật bảo dưỡng thủ công.',
      trustScore: 99.0,
      ratingAvg: 4.9,
      completedOrdersCount: 198,
      followersCount: 305,
      activeItemsCount: 22,
    ),
    DemoNearbyShopInfo(
      sellerId: 501,
      shopName: 'Tiệm Phim & Đồ Cổ Chú Bảy',
      shopSlug: 'tiem-phim-chu-bay',
      district: 'Quận 5, TP.HCM',
      distanceLabel: '3,1 km',
      specialtyTag: 'Watches & Film',
      coverAsset: ProductImageResolver.assetFilmCamera,
      bio: 'Chuyên máy ảnh phim SLR cổ, ống kính MF và đồng hồ cơ Nhật Bản nguyên bản.',
      trustScore: 98.0,
      ratingAvg: 4.9,
      completedOrdersCount: 264,
      followersCount: 412,
      activeItemsCount: 19,
    ),
    DemoNearbyShopInfo(
      sellerId: 507,
      shopName: 'Saigon Archive Tân Bình',
      shopSlug: 'saigon-archive-tan-binh',
      district: 'Tân Bình, TP.HCM',
      distanceLabel: '3,5 km',
      specialtyTag: 'American & Boxy Tee',
      coverAsset: ProductImageResolver.assetFlannelShirt,
      bio: 'Kho áo thun Mỹ single-stitch, boxy tee form rộng và sơ mi workwear Nhật - Mỹ.',
      trustScore: 97.0,
      ratingAvg: 4.8,
      completedOrdersCount: 245,
      followersCount: 388,
      activeItemsCount: 51,
    ),
    DemoNearbyShopInfo(
      sellerId: 508,
      shopName: '2hand Lab Quận 10',
      shopSlug: '2hand-lab-quan-10',
      district: 'Quận 10, TP.HCM',
      distanceLabel: '1,9 km',
      specialtyTag: 'Trousers & Streetwear',
      coverAsset: ProductImageResolver.assetMechanicalWatch,
      bio: 'Quần âu xếp ly vintage, cargo Nhật, đồng hồ cổ và phụ kiện phối đồ unisex.',
      trustScore: 96.0,
      ratingAvg: 4.7,
      completedOrdersCount: 162,
      followersCount: 241,
      activeItemsCount: 33,
    ),
  ];

  static const List<_DemoCatalogSeed> _demoCatalogSeeds = [
    // ── Original 8 core curated items (IDs 8101..8108 preserved) ──
    _DemoCatalogSeed(
      id: 8101,
      title: 'Áo Khoác Varsity Len Xanh Rêu Tay Da Kem 90s',
      slug: 'ao-khoac-varsity-len-xanh-reu-90s',
      condition: 'LIKE_NEW',
      price: 389000,
      imageAsset: ProductImageResolver.assetVarsityJacket,
      sellerId: 502,
      sellerName: 'Retro Closet Quận 1',
      sellerTrust: 98,
      categoryId: 12,
      categoryName: 'Outerwear',
      brandName: 'Vintage USA',
      description: 'Form varsity chuẩn thập niên 90, thân dạ len dày ấm phối tay da kem mềm, cúc bấm kim loại chắc chắn.',
    ),
    _DemoCatalogSeed(
      id: 8102,
      title: 'Áo Len Cardigan Xanh Navy Kẻ Đỏ Đô Cổ Điển',
      slug: 'ao-len-cardigan-xanh-navy-ke-do',
      condition: 'GOOD',
      price: 259000,
      imageAsset: ProductImageResolver.assetKnitCardigan,
      sellerId: 503,
      sellerName: 'Vintage House Quận 3',
      sellerTrust: 97,
      categoryId: 11,
      categoryName: 'Sweaters',
      brandName: 'Ralph Retro',
      description: 'Chất len cotton mềm mịn, dễ layer cùng sơ mi hoặc áo thun trắng, không xù lông.',
    ),
    _DemoCatalogSeed(
      id: 8103,
      title: 'Quần Jean Selvedge Ống Đứng Thập Niên 90s',
      slug: 'quan-jean-selvedge-ong-dung-90s',
      condition: 'GOOD',
      price: 340000,
      imageAsset: ProductImageResolver.assetDenimJeans,
      sellerId: 504,
      sellerName: 'Thrift Corner Bình Thạnh',
      sellerTrust: 95,
      categoryId: 3,
      categoryName: 'Flare Jeans',
      brandName: "Levi's 501",
      description: 'Denim biên đỏ dày 14oz lên màu xanh chàm tự nhiên, form thẳng cổ điển size 30-31.',
    ),
    _DemoCatalogSeed(
      id: 8104,
      title: 'Giày Sneaker Retro Da Lộn Xanh Rêu Kem Size 41',
      slug: 'giay-sneaker-retro-da-lon-xanh-reu',
      condition: 'LIKE_NEW',
      price: 520000,
      imageAsset: ProductImageResolver.assetRetroSneakers,
      sellerId: 505,
      sellerName: 'Tiệm Giày Si Phú Nhuận',
      sellerTrust: 96,
      categoryId: 7,
      categoryName: 'Sneakers',
      brandName: 'Court Retro',
      description: 'Sneaker da lộn màu xanh rêu vintage, đế gum nguyên bản còn gai rất mới.',
    ),
    _DemoCatalogSeed(
      id: 8105,
      title: 'Túi Đeo Chéo Da Bò Sáp Khóa Đồng Vintage',
      slug: 'tui-deo-cheo-da-bo-sap-vintage',
      condition: 'VINTAGE_WORN',
      price: 465000,
      imageAsset: ProductImageResolver.assetLeatherBag,
      sellerId: 506,
      sellerName: 'Xưởng Đồ Da Cũ Thủ Đức',
      sellerTrust: 99,
      categoryId: 8,
      categoryName: 'Leather Bags',
      brandName: 'Coach Vintage',
      description: 'Da bò sáp thật lên màu patina cổ điển, nhiều ngăn tiện dụng đựng iPad và sổ tay.',
    ),
    _DemoCatalogSeed(
      id: 8106,
      title: 'Sơ Mi Flannel Kẻ Caro Đỏ Rượu Xanh Rêu Dày',
      slug: 'so-mi-flannel-ke-caro-do-ruou',
      condition: 'LIKE_NEW',
      price: 215000,
      imageAsset: ProductImageResolver.assetFlannelShirt,
      sellerId: 502,
      sellerName: 'Retro Closet Quận 1',
      sellerTrust: 98,
      categoryId: 5,
      categoryName: 'Vintage Shirt',
      brandName: 'Pendleton',
      description: 'Vải flannel chải bông mềm ấm, phom suông mặc khoác ngoài hoặc cài nút đều đẹp.',
    ),
    _DemoCatalogSeed(
      id: 8107,
      title: 'Đồng Hồ Cơ Mặt Kem Dây Da Nâu Cổ Điển 1978',
      slug: 'dong-ho-co-mat-kem-day-da-nau',
      condition: 'GOOD',
      price: 890000,
      imageAsset: ProductImageResolver.assetMechanicalWatch,
      sellerId: 501,
      sellerName: 'Tiệm Phim & Đồ Cổ Chú Bảy',
      sellerTrust: 98,
      categoryId: 9,
      categoryName: 'Watches',
      brandName: 'Seiko Vintage',
      description: 'Máy cơ tự động Nhật Bản chạy chuẩn giờ, mặt số tia kem lịch sự size 36mm.',
    ),
    _DemoCatalogSeed(
      id: 8108,
      title: 'Máy Ảnh Phim 35mm SLR Cổ Điển Kèm Lens 50mm',
      slug: 'may-anh-phim-35mm-slr-co-dien',
      condition: 'FAIR',
      price: 1650000,
      imageAsset: ProductImageResolver.assetFilmCamera,
      sellerId: 501,
      sellerName: 'Tiệm Phim & Đồ Cổ Chú Bảy',
      sellerTrust: 98,
      categoryId: 10,
      categoryName: 'Accessories',
      brandName: 'Nikon Vintage',
      description: 'Thân máy cơ thép bền bỉ, tốc cơ chuẩn, đi kèm dây đeo da bò vintage.',
    ),

    // ── 36 Additional Curated Secondhand Fashion Products (IDs 8109..8144 -> 44 total) ──
    _DemoCatalogSeed(
      id: 8109,
      title: 'Áo Thun Mỹ American Tee Harley 90s Wash Than',
      slug: 'ao-thun-my-american-tee-harley-90s',
      condition: 'GOOD',
      price: 245000,
      imageAsset: ProductImageResolver.assetFlannelShirt,
      sellerId: 507,
      sellerName: 'Saigon Archive Tân Bình',
      sellerTrust: 97,
      categoryId: 1,
      categoryName: 'American Tee',
      brandName: 'Hanes Beefy',
      description: 'Vải cotton Mỹ dày 100%, màu đen wash than tự nhiên, hình in trước sau đậm chất 90s.',
    ),
    _DemoCatalogSeed(
      id: 8110,
      title: 'Áo Thun Boxy Tee Trắng Ngà Cổ Bo Dày 260gsm',
      slug: 'ao-thun-boxy-tee-trang-nga-260gsm',
      condition: 'NEW_WITH_TAGS',
      price: 185000,
      imageAsset: ProductImageResolver.assetFlannelShirt,
      sellerId: 507,
      sellerName: 'Saigon Archive Tân Bình',
      sellerTrust: 97,
      categoryId: 2,
      categoryName: 'Boxy Tee',
      brandName: 'Champion USA',
      description: 'Form boxy rộng vai ngắn thân tôn dáng, vải cotton nặng tay giữ form chuẩn.',
    ),
    _DemoCatalogSeed(
      id: 8111,
      title: 'Quần Jean Ống Loe Flare Jeans Levi 517 Wash Xanh Nhạt',
      slug: 'quan-jean-ong-loe-flare-levis-517',
      condition: 'LIKE_NEW',
      price: 395000,
      imageAsset: ProductImageResolver.assetDenimJeans,
      sellerId: 504,
      sellerName: 'Thrift Corner Bình Thạnh',
      sellerTrust: 95,
      categoryId: 3,
      categoryName: 'Flare Jeans',
      brandName: "Levi's 517",
      description: 'Dáng bootcut/flare kéo dài chân cực đẹp, vải denim đứng form size 29-30.',
    ),
    _DemoCatalogSeed(
      id: 8112,
      title: 'Áo Khoác Denim Jacket Wrangler Lót Lông Cừu Cổ Điển',
      slug: 'ao-khoac-denim-jacket-wrangler-sherpa',
      condition: 'GOOD',
      price: 485000,
      imageAsset: ProductImageResolver.assetVarsityJacket,
      sellerId: 504,
      sellerName: 'Thrift Corner Bình Thạnh',
      sellerTrust: 95,
      categoryId: 4,
      categoryName: 'Denim Jacket',
      brandName: 'Wrangler USA',
      description: 'Áo khoác jean lót lông cừu ấm áp, túi ngực chữ W đặc trưng thập niên 80.',
    ),
    _DemoCatalogSeed(
      id: 8113,
      title: 'Sơ Mi Vintage Shirt Kẻ Sọc Xanh Pastel Oxford Mỹ',
      slug: 'so-mi-vintage-shirt-oxford-xanh-pastel',
      condition: 'LIKE_NEW',
      price: 195000,
      imageAsset: ProductImageResolver.assetFlannelShirt,
      sellerId: 502,
      sellerName: 'Retro Closet Quận 1',
      sellerTrust: 98,
      categoryId: 5,
      categoryName: 'Vintage Shirt',
      brandName: 'Ralph Lauren',
      description: 'Vải oxford dệt nổi thoáng mát, logo ngựa thêu sắc nét, phù hợp đi học đi làm.',
    ),
    _DemoCatalogSeed(
      id: 8114,
      title: 'Quần Âu Xếp Ly Trousers Ống Suông Nâu Đậm Nhật Bản',
      slug: 'quan-au-xep-ly-trousers-nau-dam',
      condition: 'LIKE_NEW',
      price: 275000,
      imageAsset: ProductImageResolver.assetDenimJeans,
      sellerId: 508,
      sellerName: '2hand Lab Quận 10',
      sellerTrust: 96,
      categoryId: 6,
      categoryName: 'Trousers',
      brandName: 'Beams Vintage',
      description: 'Quần tây hai ly trước dáng suông rộng chuẩn Nhật, chất vải rũ nhẹ không nhăn.',
    ),
    _DemoCatalogSeed(
      id: 8115,
      title: 'Giày Sneaker New Balance 574 Xám Cổ Điển Size 40',
      slug: 'giay-sneaker-nb-574-xam-co-dien',
      condition: 'GOOD',
      price: 590000,
      imageAsset: ProductImageResolver.assetRetroSneakers,
      sellerId: 505,
      sellerName: 'Tiệm Giày Si Phú Nhuận',
      sellerTrust: 96,
      categoryId: 7,
      categoryName: 'Sneakers',
      brandName: 'New Balance',
      description: 'Phối màu xám lông chuột biểu tượng, da lộn êm chân, vệ sinh khử khuẩn sẵn.',
    ),
    _DemoCatalogSeed(
      id: 8116,
      title: 'Túi Tote Da Bò Thật Dáng Hộp Nâu Hạt Dẻ Vintage',
      slug: 'tui-tote-da-bo-that-nau-hat-de',
      condition: 'LIKE_NEW',
      price: 540000,
      imageAsset: ProductImageResolver.assetLeatherBag,
      sellerId: 506,
      sellerName: 'Xưởng Đồ Da Cũ Thủ Đức',
      sellerTrust: 99,
      categoryId: 8,
      categoryName: 'Leather Bags',
      brandName: 'Fossil Vintage',
      description: 'Vừa laptop 14 inch, quai đeo bản vừa êm vai, đường chỉ khâu tay bền chắc.',
    ),
    _DemoCatalogSeed(
      id: 8117,
      title: 'Đồng Hồ Casio Vintage Mặt Vuông Dây Thép Bạc',
      slug: 'dong-ho-casio-vintage-mat-vuong',
      condition: 'NEW_WITH_TAGS',
      price: 420000,
      imageAsset: ProductImageResolver.assetMechanicalWatch,
      sellerId: 508,
      sellerName: '2hand Lab Quận 10',
      sellerTrust: 96,
      categoryId: 9,
      categoryName: 'Watches',
      brandName: 'Casio Japan',
      description: 'Thiết kế retro thập niên 80 siêu nhẹ, đầy đủ đèn nền, báo thức và bấm giờ.',
    ),
    _DemoCatalogSeed(
      id: 8118,
      title: 'Thắt Lưng Da Bò Khóa Đồng Đúc Vintage Bản 3.2cm',
      slug: 'that-lung-da-bo-khoa-dong-duc',
      condition: 'GOOD',
      price: 165000,
      imageAsset: ProductImageResolver.assetLeatherBag,
      sellerId: 506,
      sellerName: 'Xưởng Đồ Da Cũ Thủ Đức',
      sellerTrust: 99,
      categoryId: 10,
      categoryName: 'Accessories',
      brandName: 'Handmade Japan',
      description: 'Da nguyên miếng dày 4mm không bong tróc, mặt khóa đồng thau màu cũ tự nhiên.',
    ),
    _DemoCatalogSeed(
      id: 8119,
      title: 'Áo Len Sweater Cổ Tròn Vặn Thừng Màu Kem Sữa',
      slug: 'ao-len-sweater-van-thung-kem-sua',
      condition: 'LIKE_NEW',
      price: 280000,
      imageAsset: ProductImageResolver.assetKnitCardigan,
      sellerId: 503,
      sellerName: 'Vintage House Quận 3',
      sellerTrust: 97,
      categoryId: 11,
      categoryName: 'Sweaters',
      brandName: 'Uniqlo Archive',
      description: 'Họa tiết len vặn thừng nổi dày dặn, tông màu kem sữa dễ phối mọi kiểu quần.',
    ),
    _DemoCatalogSeed(
      id: 8120,
      title: 'Áo Khoác Workwear Canvas Nâu Đất Lót Chần Bông',
      slug: 'ao-khoac-workwear-canvas-nau-dat',
      condition: 'VINTAGE_WORN',
      price: 620000,
      imageAsset: ProductImageResolver.assetVarsityJacket,
      sellerId: 502,
      sellerName: 'Retro Closet Quận 1',
      sellerTrust: 98,
      categoryId: 12,
      categoryName: 'Outerwear',
      brandName: 'Carhartt Detroit',
      description: 'Chất vải canvas bền bỉ phai màu đẹp theo thời gian, cổ nhung tăm nâu đặc trưng.',
    ),
    _DemoCatalogSeed(
      id: 8121,
      title: 'Áo Thun Mỹ American Tee National Park In Cổ Điển',
      slug: 'ao-thun-my-national-park-vintage',
      condition: 'LIKE_NEW',
      price: 210000,
      imageAsset: ProductImageResolver.assetFlannelShirt,
      sellerId: 507,
      sellerName: 'Saigon Archive Tân Bình',
      sellerTrust: 97,
      categoryId: 1,
      categoryName: 'American Tee',
      brandName: 'Gildan Heavy',
      description: 'Hình in phong cảnh rừng thông màu cổ điển, vải mềm rũ mặc cực kỳ thoải mái.',
    ),
    _DemoCatalogSeed(
      id: 8122,
      title: 'Áo Thun Boxy Tee Xanh Rêu Rửa Axit Form Rộng',
      slug: 'ao-thun-boxy-tee-xanh-reu-wash',
      condition: 'GOOD',
      price: 175000,
      imageAsset: ProductImageResolver.assetFlannelShirt,
      sellerId: 507,
      sellerName: 'Saigon Archive Tân Bình',
      sellerTrust: 97,
      categoryId: 2,
      categoryName: 'Boxy Tee',
      brandName: 'Pro Club',
      description: 'Tông xanh rêu wash nhẹ bụi bặm, cổ tròn ôm gọn không giãn.',
    ),
    _DemoCatalogSeed(
      id: 8123,
      title: 'Quần Jean Ống Loe Flare Jeans Nữ Lưng Cao Đậm Vintage',
      slug: 'quan-jean-ong-loe-lung-cao-vintage',
      condition: 'LIKE_NEW',
      price: 330000,
      imageAsset: ProductImageResolver.assetDenimJeans,
      sellerId: 504,
      sellerName: 'Thrift Corner Bình Thạnh',
      sellerTrust: 95,
      categoryId: 3,
      categoryName: 'Flare Jeans',
      brandName: 'Lee Riders',
      description: 'Quần jean ống loe lưng cao tôn vòng eo, wash xanh cổ điển size 27-28.',
    ),
    _DemoCatalogSeed(
      id: 8124,
      title: 'Áo Khoác Denim Jacket Xanh Indigo Wash Nhẹ Size L',
      slug: 'ao-khoac-denim-jacket-indigo-size-l',
      condition: 'LIKE_NEW',
      price: 445000,
      imageAsset: ProductImageResolver.assetVarsityJacket,
      sellerId: 504,
      sellerName: 'Thrift Corner Bình Thạnh',
      sellerTrust: 95,
      categoryId: 4,
      categoryName: 'Denim Jacket',
      brandName: 'Edwin Japan',
      description: 'Denim Nhật dệt mịn, nút đồng khắc logo sắc nét, độ mới cao 95%.',
    ),
    _DemoCatalogSeed(
      id: 8125,
      title: 'Sơ Mi Nhung Tăm Corduroy Nâu Cà Phê Cổ Điển',
      slug: 'so-mi-nhung-tam-corduroy-nau-ca-phe',
      condition: 'GOOD',
      price: 235000,
      imageAsset: ProductImageResolver.assetFlannelShirt,
      sellerId: 503,
      sellerName: 'Vintage House Quận 3',
      sellerTrust: 97,
      categoryId: 5,
      categoryName: 'Vintage Shirt',
      brandName: 'L.L.Bean',
      description: 'Nhung tăm sọc nhỏ mềm mịn, mặc làm overshirt khoác nhẹ buổi tối siêu hợp.',
    ),
    _DemoCatalogSeed(
      id: 8126,
      title: 'Quần Kaki Trousers Dickies 874 Màu Be Cát Size 32',
      slug: 'quan-kaki-trousers-dickies-874-be',
      condition: 'GOOD',
      price: 260000,
      imageAsset: ProductImageResolver.assetDenimJeans,
      sellerId: 508,
      sellerName: '2hand Lab Quận 10',
      sellerTrust: 96,
      categoryId: 6,
      categoryName: 'Trousers',
      brandName: 'Dickies USA',
      description: 'Dáng ống đứng huyền thoại, chất vải kaki đứng form bền màu.',
    ),
    _DemoCatalogSeed(
      id: 8127,
      title: 'Giày Converse Chuck 70 Low Trắng Ngà Cổ Điển Size 39',
      slug: 'giay-converse-chuck-70-low-trang-nga',
      condition: 'LIKE_NEW',
      price: 495000,
      imageAsset: ProductImageResolver.assetRetroSneakers,
      sellerId: 505,
      sellerName: 'Tiệm Giày Si Phú Nhuận',
      sellerTrust: 96,
      categoryId: 7,
      categoryName: 'Sneakers',
      brandName: 'Converse 70s',
      description: 'Đế ngà bóng chuẩn 70s, tem gót đen sắc nét, đi êm và rất dễ phối đồ si.',
    ),
    _DemoCatalogSeed(
      id: 8128,
      title: 'Túi Đeo Vai Da Thật Mini Baguette Đen Bóng 90s',
      slug: 'tui-deo-vai-da-that-baguette-90s',
      condition: 'LIKE_NEW',
      price: 410000,
      imageAsset: ProductImageResolver.assetLeatherBag,
      sellerId: 506,
      sellerName: 'Xưởng Đồ Da Cũ Thủ Đức',
      sellerTrust: 99,
      categoryId: 8,
      categoryName: 'Leather Bags',
      brandName: 'Bally Vintage',
      description: 'Dáng kẹp nách thanh lịch thập niên 90, da mềm không trầy xước.',
    ),
    _DemoCatalogSeed(
      id: 8129,
      title: 'Đồng Hồ Citizen Automatic Mặt Xanh Lục Bảo Dây Da',
      slug: 'dong-ho-citizen-automatic-xanh-luc-bao',
      condition: 'GOOD',
      price: 960000,
      imageAsset: ProductImageResolver.assetMechanicalWatch,
      sellerId: 501,
      sellerName: 'Tiệm Phim & Đồ Cổ Chú Bảy',
      sellerTrust: 98,
      categoryId: 9,
      categoryName: 'Watches',
      brandName: 'Citizen Japan',
      description: 'Mặt chải tia xanh lục bảo hiếm gặp, kính sáng đẹp, lịch thứ ngày đầy đủ.',
    ),
    _DemoCatalogSeed(
      id: 8130,
      title: 'Kính Mát Gọng Đồi Mồi Vintage Tròng Trà Nhẹ',
      slug: 'kinh-mat-gong-doi-moi-vintage',
      condition: 'NEW_WITH_TAGS',
      price: 155000,
      imageAsset: ProductImageResolver.assetMechanicalWatch,
      sellerId: 508,
      sellerName: '2hand Lab Quận 10',
      sellerTrust: 96,
      categoryId: 10,
      categoryName: 'Accessories',
      brandName: 'Tokyo Optics',
      description: 'Gọng acetate đồi mồi ôm mặt nhẹ nhàng, tròng chống tia UV400 màu trà cổ điển.',
    ),
    _DemoCatalogSeed(
      id: 8131,
      title: 'Áo Len Gile Sweater Vest Họa Tiết Quả Trám Học Đường',
      slug: 'ao-len-gile-sweater-vest-qua-tram',
      condition: 'LIKE_NEW',
      price: 190000,
      imageAsset: ProductImageResolver.assetKnitCardigan,
      sellerId: 503,
      sellerName: 'Vintage House Quận 3',
      sellerTrust: 97,
      categoryId: 11,
      categoryName: 'Sweaters',
      brandName: 'Tommy Vintage',
      description: 'Phong cách preppy cổ điển, phối cùng sơ mi trắng hoặc áo thun cực kỳ nổi bật.',
    ),
    _DemoCatalogSeed(
      id: 8132,
      title: 'Áo Khoác Bomber Nylon Xanh Ô Liu Lót Cam Ma-1',
      slug: 'ao-khoac-bomber-nylon-ma1-xanh-oliu',
      condition: 'GOOD',
      price: 450000,
      imageAsset: ProductImageResolver.assetVarsityJacket,
      sellerId: 502,
      sellerName: 'Retro Closet Quận 1',
      sellerTrust: 98,
      categoryId: 12,
      categoryName: 'Outerwear',
      brandName: 'Alpha Industries',
      description: 'Khóa đồng kéo êm, túi hộp tay áo chuẩn quân đội, bo gấu còn ôm chắc.',
    ),
    _DemoCatalogSeed(
      id: 8133,
      title: 'Áo Thun Mỹ American Tee Collegiate Đại Học Michigan 90s',
      slug: 'ao-thun-my-collegiate-michigan-90s',
      condition: 'VINTAGE_WORN',
      price: 225000,
      imageAsset: ProductImageResolver.assetFlannelShirt,
      sellerId: 507,
      sellerName: 'Saigon Archive Tân Bình',
      sellerTrust: 97,
      categoryId: 1,
      categoryName: 'American Tee',
      brandName: 'Russell Athletic',
      description: 'Chất cotton pha mềm mát màu xanh navy phai nhẹ, chữ in phong cách đại học Mỹ.',
    ),
    _DemoCatalogSeed(
      id: 8134,
      title: 'Áo Thun Boxy Tee Nâu Espresso Wash Vintage Size L',
      slug: 'ao-thun-boxy-tee-nau-espresso',
      condition: 'LIKE_NEW',
      price: 199000,
      imageAsset: ProductImageResolver.assetFlannelShirt,
      sellerId: 507,
      sellerName: 'Saigon Archive Tân Bình',
      sellerTrust: 97,
      categoryId: 2,
      categoryName: 'Boxy Tee',
      brandName: 'Los Angeles Apparel',
      description: 'Màu nâu cà phê đậm hot trend, dáng boxy gọn gàng không quá dài.',
    ),
    _DemoCatalogSeed(
      id: 8135,
      title: 'Quần Jean Ống Loe Flare Jeans Wash Đen Khói 2000s',
      slug: 'quan-jean-flare-wash-den-khoi',
      condition: 'GOOD',
      price: 360000,
      imageAsset: ProductImageResolver.assetDenimJeans,
      sellerId: 504,
      sellerName: 'Thrift Corner Bình Thạnh',
      sellerTrust: 95,
      categoryId: 3,
      categoryName: 'Flare Jeans',
      brandName: 'Diesel Y2K',
      description: 'Vệt wash khói cá tính đậm chất Y2K, chất jean dày mềm dễ vận động.',
    ),
    _DemoCatalogSeed(
      id: 8136,
      title: 'Áo Khoác Denim Jacket Wash Đen Xám Form Oversize',
      slug: 'ao-khoac-denim-jacket-den-xam',
      condition: 'LIKE_NEW',
      price: 470000,
      imageAsset: ProductImageResolver.assetVarsityJacket,
      sellerId: 502,
      sellerName: 'Retro Closet Quận 1',
      sellerTrust: 98,
      categoryId: 4,
      categoryName: 'Denim Jacket',
      brandName: 'Gap 1998',
      description: 'Màu đen wash xám cực dễ mặc, tay áo rộng thoải mái khoác ngoài hoodie.',
    ),
    _DemoCatalogSeed(
      id: 8137,
      title: 'Sơ Mi Lụa Hoa Văn Vintage Nhật Bản Tay Ngắn Form Rộng',
      slug: 'so-mi-lua-hoa-van-vintage-nhat',
      condition: 'LIKE_NEW',
      price: 185000,
      imageAsset: ProductImageResolver.assetFlannelShirt,
      sellerId: 503,
      sellerName: 'Vintage House Quận 3',
      sellerTrust: 97,
      categoryId: 5,
      categoryName: 'Vintage Shirt',
      brandName: 'Shimokitazawa',
      description: 'Chất rayon lụa rũ mát mịn, họa tiết hình học cổ điển không đụng hàng.',
    ),
    _DemoCatalogSeed(
      id: 8138,
      title: 'Quần Cargo Túi Hộp Trousers Xanh Rêu Quân Đội Nhật',
      slug: 'quan-cargo-tui-hop-xanh-reu-nhat',
      condition: 'GOOD',
      price: 315000,
      imageAsset: ProductImageResolver.assetDenimJeans,
      sellerId: 508,
      sellerName: '2hand Lab Quận 10',
      sellerTrust: 96,
      categoryId: 6,
      categoryName: 'Trousers',
      brandName: 'Military Surplus',
      description: 'Vải ripstop thoáng bền, dây rút gấu điều chỉnh dáng suông hoặc bo jogger.',
    ),
    _DemoCatalogSeed(
      id: 8139,
      title: 'Giày Adidas Samba Classic Trắng Sọc Đen Size 42',
      slug: 'giay-adidas-samba-classic-42',
      condition: 'GOOD',
      price: 680000,
      imageAsset: ProductImageResolver.assetRetroSneakers,
      sellerId: 505,
      sellerName: 'Tiệm Giày Si Phú Nhuận',
      sellerTrust: 96,
      categoryId: 7,
      categoryName: 'Sneakers',
      brandName: 'Adidas Originals',
      description: 'Mũi da lộn xám sạch đẹp, đế gum bám chắc, dòng retro kinh điển.',
    ),
    _DemoCatalogSeed(
      id: 8140,
      title: 'Túi Messenger Da Bò Nâu Đậm Đựng Laptop 15 Inch',
      slug: 'tui-messenger-da-bo-nau-dam',
      condition: 'FAIR',
      price: 510000,
      imageAsset: ProductImageResolver.assetLeatherBag,
      sellerId: 506,
      sellerName: 'Xưởng Đồ Da Cũ Thủ Đức',
      sellerTrust: 99,
      categoryId: 8,
      categoryName: 'Leather Bags',
      brandName: 'Porter Vintage',
      description: 'Chất da bò nguyên tấm dày dặn, khóa nắp cổ điển, phù hợp sinh viên và dân thiết kế.',
    ),
    _DemoCatalogSeed(
      id: 8141,
      title: 'Đồng Hồ Orient 3 Sao Tự Động Mặt Vàng Champange 80s',
      slug: 'dong-ho-orient-3-sao-mat-vang',
      condition: 'GOOD',
      price: 1120000,
      imageAsset: ProductImageResolver.assetMechanicalWatch,
      sellerId: 501,
      sellerName: 'Tiệm Phim & Đồ Cổ Chú Bảy',
      sellerTrust: 98,
      categoryId: 9,
      categoryName: 'Watches',
      brandName: 'Orient Japan',
      description: 'Cọc số nổi ánh vàng cổ điển, máy cơ 21 chân kính chạy êm bền bỉ.',
    ),
    _DemoCatalogSeed(
      id: 8142,
      title: 'Mũ Lưỡi Trai Nhung Tăm Xanh Rêu Thêu Chữ Retro',
      slug: 'mu-luoi-trai-nhung-tam-xanh-reu',
      condition: 'NEW_WITH_TAGS',
      price: 115000,
      imageAsset: ProductImageResolver.assetVarsityJacket,
      sellerId: 508,
      sellerName: '2hand Lab Quận 10',
      sellerTrust: 96,
      categoryId: 10,
      categoryName: 'Accessories',
      brandName: 'New Era Vintage',
      description: 'Chất nhung tăm mềm nhẹ, khóa đồng điều chỉnh phía sau, form ôm đầu đẹp.',
    ),
    _DemoCatalogSeed(
      id: 8143,
      title: 'Áo Len Sweater Cổ Lọ Wool Đỏ Rượu Vang Mùa Đông',
      slug: 'ao-len-sweater-co-lo-do-ruou',
      condition: 'LIKE_NEW',
      price: 295000,
      imageAsset: ProductImageResolver.assetKnitCardigan,
      sellerId: 503,
      sellerName: 'Vintage House Quận 3',
      sellerTrust: 97,
      categoryId: 11,
      categoryName: 'Sweaters',
      brandName: 'Muji Archive',
      description: 'Màu đỏ rượu vang cực kỳ hợp không khí Giáng sinh & mùa lạnh, len ấm mềm.',
    ),
    _DemoCatalogSeed(
      id: 8144,
      title: 'Áo Măng Tô Dạ Outerwear Dáng Dài Màu Camel Cổ Điển',
      slug: 'ao-mang-to-da-outerwear-camel',
      condition: 'LIKE_NEW',
      price: 780000,
      imageAsset: ProductImageResolver.assetVarsityJacket,
      sellerId: 502,
      sellerName: 'Retro Closet Quận 1',
      sellerTrust: 98,
      categoryId: 12,
      categoryName: 'Outerwear',
      brandName: 'Burberrys Vintage',
      description: 'Dáng áo măng tô dạ ép đứng form, lớp lót lụa kẻ caro tinh tế, độ mới 95%.',
    ),
  ];

  /// 44+ realistic secondhand products for Home Discovery Feed & New Arrivals fallback/enrichment.
  List<ProductSummaryModel> get demoCatalogProducts {
    return _demoCatalogSeeds
        .map(
          (seed) => ProductSummaryModel(
            id: seed.id,
            productCode: 'PRD-2026-${seed.id}',
            title: seed.title,
            slug: seed.slug,
            listingType: 'FIXED_PRICE',
            condition: seed.condition,
            price: seed.price,
            status: 'APPROVED',
            isFavorited: _favoritedProductIds.contains(seed.id),
            primaryImageUrl: seed.imageAsset,
            sellerId: seed.sellerId,
            sellerDisplayName: seed.sellerName,
            sellerTrustScore: seed.sellerTrust,
            categoryId: seed.categoryId,
            categoryName: seed.categoryName,
            brandName: seed.brandName,
          ),
        )
        .toList();
  }

  /// Demo buyer orders used as offline/demo fallback in Chat Order Attachment picker
  /// (associated cleanly with demo shops so sellers can identify orders in chat).
  List<OrderModel> get demoBuyerOrders {
    final now = DateTime.now();
    return [
      OrderModel(
        id: 7001,
        orderCode: 'ORD-2026-7001',
        buyerId: 999,
        buyerName: 'Minh Khôi (Demo)',
        sellerId: 201,
        shopName: 'Tiệm Cổ Điển Sài Gòn',
        shopSlug: 'tiem-co-dien-sg',
        trustScore: 98,
        recipientName: 'Minh Khôi',
        recipientPhone: '0909 123 456',
        fullAddress: '128 Nguyễn Thị Minh Khai, Quận 3, TP.HCM',
        orderStatus: 'SHIPPED',
        paymentStatus: 'PAID',
        escrowStatus: 'HELD',
        disputeStatus: 'NONE',
        itemSubtotal: 389000,
        shippingFee: 22000,
        buyerProtectionFee: 30340,
        totalAmount: 441340,
        sellerNetPayout: 389000,
        createdAt: now.subtract(const Duration(days: 1, hours: 4)),
        paidAt: now.subtract(const Duration(days: 1, hours: 3)),
        shippedAt: now.subtract(const Duration(hours: 10)),
        items: const [
          OrderItemSnapshotModel(
            id: 1,
            productId: 8101,
            productCode: 'PRD-2026-8101',
            productTitle: 'Áo Khoác Varsity Len Xanh Rêu Tay Da Kem 90s',
            primaryImageUrl: ProductImageResolver.assetVarsityJacket,
            condition: 'LIKE_NEW',
            unitPrice: 389000,
            quantity: 1,
            subtotal: 389000,
          ),
        ],
      ),
      OrderModel(
        id: 7002,
        orderCode: 'ORD-2026-7002',
        buyerId: 999,
        buyerName: 'Minh Khôi (Demo)',
        sellerId: 502,
        shopName: 'Retro Closet Quận 1',
        shopSlug: 'retro-closet-quan-1',
        trustScore: 98,
        recipientName: 'Minh Khôi',
        recipientPhone: '0909 123 456',
        fullAddress: '128 Nguyễn Thị Minh Khai, Quận 3, TP.HCM',
        orderStatus: 'PREPARING',
        paymentStatus: 'PAID',
        escrowStatus: 'HELD',
        disputeStatus: 'NONE',
        itemSubtotal: 215000,
        shippingFee: 18000,
        buyerProtectionFee: 19900,
        totalAmount: 252900,
        sellerNetPayout: 215000,
        createdAt: now.subtract(const Duration(hours: 6)),
        paidAt: now.subtract(const Duration(hours: 5)),
        items: const [
          OrderItemSnapshotModel(
            id: 2,
            productId: 8106,
            productCode: 'PRD-2026-8106',
            productTitle: 'Sơ Mi Flannel Kẻ Caro Đỏ Rượu Xanh Rêu Dày',
            primaryImageUrl: ProductImageResolver.assetFlannelShirt,
            condition: 'LIKE_NEW',
            unitPrice: 215000,
            quantity: 1,
            subtotal: 215000,
          ),
        ],
      ),
      OrderModel(
        id: 7003,
        orderCode: 'ORD-2026-7003',
        buyerId: 999,
        buyerName: 'Minh Khôi (Demo)',
        sellerId: 202,
        shopName: 'Analog Film & Thrift',
        shopSlug: 'analog-film-thrift',
        trustScore: 96,
        recipientName: 'Minh Khôi',
        recipientPhone: '0909 123 456',
        fullAddress: '128 Nguyễn Thị Minh Khai, Quận 3, TP.HCM',
        orderStatus: 'DELIVERED',
        paymentStatus: 'PAID',
        escrowStatus: 'HELD',
        disputeStatus: 'NONE',
        itemSubtotal: 1650000,
        shippingFee: 0,
        buyerProtectionFee: 106000,
        totalAmount: 1756000,
        sellerNetPayout: 1650000,
        createdAt: now.subtract(const Duration(days: 3)),
        paidAt: now.subtract(const Duration(days: 3)),
        deliveredAt: now.subtract(const Duration(hours: 4)),
        items: const [
          OrderItemSnapshotModel(
            id: 3,
            productId: 8108,
            productCode: 'PRD-2026-8108',
            productTitle: 'Máy Ảnh Phim 35mm SLR Cổ Điển Kèm Lens 50mm',
            primaryImageUrl: ProductImageResolver.assetFilmCamera,
            condition: 'FAIR',
            unitPrice: 1650000,
            quantity: 1,
            subtotal: 1650000,
          ),
        ],
      ),
      OrderModel(
        id: 7004,
        orderCode: 'ORD-2026-7004',
        buyerId: 999,
        buyerName: 'Minh Khôi (Demo)',
        sellerId: 203,
        shopName: 'Tiệm Giày Si Quận 3',
        shopSlug: 'tiem-giay-si-q3',
        trustScore: 95,
        recipientName: 'Minh Khôi',
        recipientPhone: '0909 123 456',
        fullAddress: '128 Nguyễn Thị Minh Khai, Quận 3, TP.HCM',
        orderStatus: 'COMPLETED',
        paymentStatus: 'PAID',
        escrowStatus: 'RELEASED',
        disputeStatus: 'NONE',
        itemSubtotal: 520000,
        shippingFee: 20000,
        buyerProtectionFee: 38200,
        totalAmount: 578200,
        sellerNetPayout: 520000,
        createdAt: now.subtract(const Duration(days: 6)),
        completedAt: now.subtract(const Duration(days: 2)),
        items: const [
          OrderItemSnapshotModel(
            id: 4,
            productId: 8104,
            productCode: 'PRD-2026-8104',
            productTitle: 'Giày Sneaker Retro Da Lộn Xanh Rêu Kem Size 41',
            primaryImageUrl: ProductImageResolver.assetRetroSneakers,
            condition: 'LIKE_NEW',
            unitPrice: 520000,
            quantity: 1,
            subtotal: 520000,
          ),
        ],
      ),
      OrderModel(
        id: 7005,
        orderCode: 'ORD-2026-7005',
        buyerId: 999,
        buyerName: 'Minh Khôi (Demo)',
        sellerId: 504,
        shopName: 'Thrift Corner Bình Thạnh',
        shopSlug: 'thrift-corner-binh-thanh',
        trustScore: 95,
        recipientName: 'Minh Khôi',
        recipientPhone: '0909 123 456',
        fullAddress: '128 Nguyễn Thị Minh Khai, Quận 3, TP.HCM',
        orderStatus: 'PAID',
        paymentStatus: 'PAID',
        escrowStatus: 'HELD',
        disputeStatus: 'NONE',
        itemSubtotal: 395000,
        shippingFee: 22000,
        buyerProtectionFee: 30700,
        totalAmount: 447700,
        sellerNetPayout: 395000,
        createdAt: now.subtract(const Duration(hours: 14)),
        paidAt: now.subtract(const Duration(hours: 13)),
        items: const [
          OrderItemSnapshotModel(
            id: 5,
            productId: 8111,
            productCode: 'PRD-2026-8111',
            productTitle: 'Quần Jean Ống Loe Flare Jeans Levi 517 Wash Xanh Nhạt',
            primaryImageUrl: ProductImageResolver.assetDenimJeans,
            condition: 'LIKE_NEW',
            unitPrice: 395000,
            quantity: 1,
            subtotal: 395000,
          ),
        ],
      ),
    ];
  }

  /// Resolves a rich ProductDetailModel when tapping any demo product card (8101..8144),
  /// a pinned demo auction item (9101..9112), or a demo sold profile item (9401..9402).
  ProductDetailModel? getDemoProductDetail(int productId) {
    final matchingSeeds = _demoCatalogSeeds.where((s) => s.id == productId);
    final seed = matchingSeeds.isNotEmpty ? matchingSeeds.first : null;
    if (seed != null) {
      final fee = (seed.price * 0.06 + 7000).roundToDouble();
      final matchingShops =
          demoNearbyShops.where((s) => s.sellerId == seed.sellerId);
      final shopMeta = matchingShops.isNotEmpty ? matchingShops.first : null;

      return ProductDetailModel(
        id: seed.id,
        productCode: 'PRD-2026-${seed.id}',
        title: seed.title,
        slug: seed.slug,
        description:
            '${seed.description} Sản phẩm đã được giặt hấp sạch sẽ và kiểm tra đường may kỹ lưỡng trước khi lên kệ izithrift.',
        listingType: 'FIXED_PRICE',
        condition: seed.condition,
        defectInfo:
            'Tình trạng thực tế ${ProductImageResolver.conditionPercentLabel(seed.condition)} đúng chuẩn đồ si tuyển, không rách thủng, khóa và nút hoạt động mượt.',
        verificationLevel: 'MODERATOR_REVIEWED',
        price: seed.price,
        buyerProtectionFee: fee,
        totalBuyerPayable: seed.price + fee,
        totalQuantity: 1,
        availableQuantity: 1,
        status: 'APPROVED',
        favoriteCount: 16 + (seed.id % 29),
        isFavorited: _favoritedProductIds.contains(seed.id),
        isOwner: false,
        primaryImageUrl: seed.imageAsset,
        category: ProductCategoryBrief(
          id: seed.categoryId,
          name: seed.categoryName,
        ),
        brand: ProductBrandBrief(id: seed.id, name: seed.brandName),
        seller: ProductSellerInfo(
          id: seed.sellerId,
          displayName: seed.sellerName,
          shopSlug: shopMeta?.shopSlug,
          trustScore: seed.sellerTrust,
          averageRating: shopMeta?.ratingAvg ?? 4.9,
          completedOrdersCount: shopMeta?.completedOrdersCount ?? 142,
        ),
        images: [
          ProductImageModel(
            id: seed.id * 10 + 1,
            imageUrl: seed.imageAsset,
            imageType: 'GALLERY',
            isPrimary: true,
          ),
        ],
        relatedProducts: demoCatalogProducts
            .where((p) => p.id != seed.id && p.categoryId == seed.categoryId)
            .take(4)
            .toList()
          ..addAll(
            demoCatalogProducts
                .where((p) => p.id != seed.id && p.categoryId != seed.categoryId)
                .take(4),
          ),
      );
    }

    final matchingAuctions =
        _demoAuctionsById.values.where((a) => a.productId == productId);
    final auctionMatch =
        matchingAuctions.isNotEmpty ? matchingAuctions.first : null;
    if (auctionMatch != null) {
      final price = auctionMatch.currentHighestBid;
      final fee = (price * 0.06 + 7000).roundToDouble();
      final primaryUrl = auctionMatch.primaryImageUrl ??
          ProductImageResolver.fallbackAssetFor(
            title: auctionMatch.productTitle,
            categoryName: auctionMatch.categoryName,
            id: auctionMatch.productId,
          );

      final resolvedCondition = auctionMatch.condition ?? 'GOOD';

      return ProductDetailModel(
        id: auctionMatch.productId,
        productCode: auctionMatch.auctionCode,
        title: auctionMatch.productTitle,
        slug: auctionMatch.productSlug ?? 'auction-${auctionMatch.productId}',
        description: auctionMatch.productDescription ??
            'Sản phẩm đấu giá tuyển chọn trên izithrift Retro Market.',
        listingType: 'AUCTION',
        condition: resolvedCondition,
        defectInfo:
            'Đã kiểm tra thực tế trước khi mở phiên đấu giá (${ProductImageResolver.conditionPercentLabel(resolvedCondition)}).',
        verificationLevel:
            auctionMatch.authenticityGuarantee ? 'MODERATOR_REVIEWED' : 'SELF_DECLARED',
        price: price,
        buyerProtectionFee: fee,
        totalBuyerPayable: price + fee,
        totalQuantity: 1,
        availableQuantity: auctionMatch.isCompleted ? 0 : 1,
        status: auctionMatch.isCompleted ? 'SOLD' : 'APPROVED',
        favoriteCount: auctionMatch.watchCount,
        isFavorited: _favoritedProductIds.contains(auctionMatch.productId),
        isOwner: auctionMatch.isOwner,
        primaryImageUrl: primaryUrl,
        category: ProductCategoryBrief(
          id: 1,
          name: auctionMatch.categoryName ?? 'Đấu giá vintage',
        ),
        seller: ProductSellerInfo(
          id: auctionMatch.sellerId,
          displayName: auctionMatch.sellerDisplayName ?? 'Chủ tiệm Retro',
          shopSlug: auctionMatch.sellerShopSlug,
          avatarUrl: auctionMatch.sellerAvatarUrl,
          trustScore: auctionMatch.sellerTrustScore,
          averageRating: 4.9,
          completedOrdersCount: 142,
        ),
        images: [
          ProductImageModel(
            id: auctionMatch.productId * 10 + 1,
            imageUrl: primaryUrl,
            imageType: 'GALLERY',
            isPrimary: true,
          ),
        ],
        relatedProducts: demoCatalogProducts.take(4).toList(),
      );
    }

    if (productId == 9401 || productId == 9402) {
      final isSweater = productId == 9401;
      final price = isSweater ? 290000.0 : 850000.0;
      final fee = (price * 0.06 + 7000).roundToDouble();
      final primaryUrl = isSweater
          ? ProductImageResolver.assetKnitCardigan
          : ProductImageResolver.assetMechanicalWatch;

      return ProductDetailModel(
        id: productId,
        productCode: isSweater ? 'PRD-SOLD-9401' : 'PRD-SOLD-9402',
        title: isSweater
            ? 'Áo Len Cổ Lọ Vintage Wool Đỏ Đô'
            : 'Đồng Hồ Cơ Vintage Dây Da Nâu Nhật Bản',
        slug: isSweater ? 'ao-len-co-lo-vintage' : 'dong-ho-co-vintage',
        description: isSweater
            ? 'Áo len ấm mùa đông đã giao thành công cho người mua.'
            : 'Đồng hồ cơ lên cót tay hoạt động chuẩn xác, đã giao hoàn tất cho người thắng phiên.',
        listingType: isSweater ? 'FIXED_PRICE' : 'AUCTION',
        condition: isSweater ? 'LIKE_NEW' : 'GOOD',
        defectInfo: 'Sản phẩm đã bán và hoàn tất giao dịch.',
        verificationLevel: 'MODERATOR_REVIEWED',
        price: price,
        buyerProtectionFee: fee,
        totalBuyerPayable: price + fee,
        totalQuantity: 1,
        availableQuantity: 0,
        status: 'SOLD',
        favoriteCount: isSweater ? 18 : 31,
        isFavorited: _favoritedProductIds.contains(productId),
        isOwner: true,
        primaryImageUrl: primaryUrl,
        category: ProductCategoryBrief(
          id: isSweater ? 11 : 9,
          name: isSweater ? 'Sweaters' : 'Watches',
        ),
        seller: const ProductSellerInfo(
          id: 502,
          displayName: 'Retro Closet Quận 1',
          shopSlug: 'retro-closet-quan-1',
          trustScore: 98,
          averageRating: 4.9,
          completedOrdersCount: 328,
        ),
        images: [
          ProductImageModel(
            id: productId * 10 + 1,
            imageUrl: primaryUrl,
            imageType: 'GALLERY',
            isPrimary: true,
          ),
        ],
        relatedProducts: demoCatalogProducts.take(4).toList(),
      );
    }

    return null;
  }

  /// Resolves a demo seller storefront when backend is offline for demo seller IDs.
  SellerPublicProfileModel? getDemoSellerStorefront(int sellerId) {
    final matchingShops = demoNearbyShops.where((s) => s.sellerId == sellerId);
    final meta = matchingShops.isNotEmpty ? matchingShops.first : null;
    if (meta == null) return null;

    final activeListings = demoCatalogProducts
        .where((p) => p.sellerId == sellerId)
        .toList();
    final auctions = demoHomeAuctionSummaries
        .where((a) => _demoAuctionsById[a.id]?.sellerId == sellerId)
        .toList();
    final isFollowing = _followedSellerIds.contains(sellerId);

    return SellerPublicProfileModel(
      userId: sellerId,
      displayName: meta.shopName,
      shopSlug: meta.shopSlug,
      bio: '${meta.bio} • ${meta.district}',
      trustScore: meta.trustScore,
      averageRating: meta.ratingAvg,
      reviewCount: (meta.completedOrdersCount / 3).round(),
      completedOrdersCount: meta.completedOrdersCount,
      followersCount: meta.followersCount + (isFollowing ? 1 : 0),
      isFollowing: isFollowing,
      isOwner: false,
      activeListings: activeListings.isNotEmpty
          ? activeListings
          : demoCatalogProducts.take(4).toList(),
      auctions: auctions,
    );
  }

  static const List<CategoryModel> fallbackCategories = [
    CategoryModel(id: 1, name: 'American Tee', slug: 'american-tee'),
    CategoryModel(id: 2, name: 'Boxy Tee', slug: 'boxy-tee'),
    CategoryModel(id: 3, name: 'Flare Jeans', slug: 'flare-jeans'),
    CategoryModel(id: 4, name: 'Denim Jacket', slug: 'denim-jacket'),
    CategoryModel(id: 5, name: 'Vintage Shirt', slug: 'vintage-shirt'),
    CategoryModel(id: 6, name: 'Trousers', slug: 'trousers'),
    CategoryModel(id: 7, name: 'Sneakers', slug: 'sneakers'),
    CategoryModel(id: 8, name: 'Leather Bags', slug: 'leather-bags'),
    CategoryModel(id: 9, name: 'Watches', slug: 'watches'),
    CategoryModel(id: 10, name: 'Accessories', slug: 'accessories'),
    CategoryModel(id: 11, name: 'Sweaters', slug: 'sweaters'),
    CategoryModel(id: 12, name: 'Outerwear', slug: 'outerwear'),
  ];

  static final List<FeaturedSellerModel> fallbackFeaturedSellers =
      demoNearbyShops.map((shop) => shop.toFeaturedSellerModel()).toList();
}

final retroDemoStoreProvider = ChangeNotifierProvider<RetroDemoMarketplaceStore>(
  (ref) => RetroDemoMarketplaceStore(),
);
