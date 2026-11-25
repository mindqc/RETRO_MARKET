import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auctions/models/auction_bid_item_model.dart';
import '../../features/auctions/models/auction_card_model.dart';
import '../../features/auctions/models/auction_detail_model.dart';
import '../../features/catalog/models/category_model.dart';
import '../../features/catalog/models/product_detail_model.dart';
import '../../features/catalog/models/product_image_model.dart';
import '../../features/catalog/models/product_summary_model.dart';
import '../../features/home/models/auction_summary_model.dart';
import '../../features/home/models/featured_seller_model.dart';
import '../../features/seller/models/seller_product_item_model.dart';
import '../utils/product_image_resolver.dart';

/// Coherent demo-compatible marketplace state store for university presentations.
///
/// Rules:
/// - Never replaces working backend data when the API succeeds.
/// - Provides consistent, realistic Vietnamese vintage marketplace items across
///   Home Feed, Product Detail, Auction Hub, Auction Room, My Auctions, and Seller Listings
///   so all demo flows work seamlessly even when backend records are sparse or offline.
/// - Newly submitted seller listings and auctions ALWAYS enter `PENDING_REVIEW`
///   and NEVER auto-publish to the public marketplace.
class RetroDemoMarketplaceStore extends ChangeNotifier {
  final List<SellerProductItemModel> _demoSubmittedListings = [];
  final Map<int, AuctionDetailModel> _demoAuctionsById = {};
  final Set<int> _registeredAuctionIds = <int>{};
  final Set<int> _favoritedProductIds = <int>{};
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
    String bidderName = 'Bạn (Tài khoản Demo)',
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
    return _demoAuctionsById.values
        .where((a) => !a.isCompleted)
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
            status: a.status,
            extendedCount: a.extendedCount,
            isOwner: a.isOwner,
            sellerDisplayName: a.sellerDisplayName,
          ),
        )
        .toList();
  }

  List<AuctionCardModel> demoAuctionCardsForTab(String tab) {
    final all = _demoAuctionsById.values.map(_toCardModel).toList();
    switch (tab) {
      case 'all':
        return all;
      case 'live':
        return all.where((a) => a.isLive).toList();
      case 'ending_soon':
        return all
            .where(
              (a) =>
                  a.isLive &&
                  a.auctionEndsAt.difference(DateTime.now()).inMinutes <= 30,
            )
            .toList();
      case 'upcoming':
        return all.where((a) => a.isScheduled).toList();
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

  void _seedConsistentDemoAuctions() {
    final now = DateTime.now();

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
      watchCount: 38,
      status: 'LIVE',
      auctionStartsAt: now.subtract(const Duration(hours: 1)),
      auctionEndsAt: now.add(const Duration(minutes: 18, seconds: 42)),
      extendedCount: 0,
      productTitle: 'Máy Ảnh Phim SLR Cổ Nikon F3 50mm f/1.4 Đời 1982',
      productSlug: 'may-anh-phim-slr-nikon-f3',
      productDescription:
          'Thân máy cơ bền bỉ, đo sáng hoạt động chuẩn xác, kèm ống kính 50mm kính trong không mốc rễ. Đã vệ sinh kiểm tra tại tiệm đồ cổ Sài Gòn.',
      primaryImageUrl: ProductImageResolver.assetFilmCamera,
      productImages: const [ProductImageResolver.assetFilmCamera],
      categoryName: 'Đồ cổ',
      condition: 'LIKE_NEW',
      authenticityGuarantee: true,
      sellerDisplayName: 'Tiệm Phim & Đồ Cổ Chú Bảy',
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

    _demoAuctionsById[9002] = AuctionDetailModel(
      id: 9002,
      auctionCode: 'AUC-2026-9002',
      productId: 9102,
      sellerId: 502,
      startingPrice: 850000,
      minBidIncrement: 50000,
      minimumNextBid: 1150000,
      currentHighestBid: 1100000,
      bidCount: 9,
      watchCount: 27,
      status: 'LIVE',
      auctionStartsAt: now.subtract(const Duration(minutes: 40)),
      auctionEndsAt: now.add(const Duration(minutes: 4, seconds: 25)),
      extendedCount: 1,
      productTitle: 'Đồng Hồ Cơ Tự Động 17 Jewels Mặt Kem Dây Da Thập Niên 70',
      productSlug: 'dong-ho-co-tu-dong-17-jewels-70s',
      productDescription:
          'Đồng hồ cơ lên cót tự động mặt số kem nguyên bản, vỏ thép chải xước nhẹ đúng chất vintage, dây da bò khâu tay mới thay.',
      primaryImageUrl: ProductImageResolver.assetMechanicalWatch,
      productImages: const [ProductImageResolver.assetMechanicalWatch],
      categoryName: 'Phụ kiện',
      condition: 'GOOD',
      authenticityGuarantee: true,
      sellerDisplayName: 'Retro Closet Sài Gòn',
      sellerTrustScore: 96,
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
      watchCount: 32,
      status: 'SCHEDULED',
      auctionStartsAt: now.add(const Duration(hours: 1, minutes: 24)),
      auctionEndsAt: now.add(const Duration(hours: 3, minutes: 24)),
      productTitle: 'Áo Khoác Varsity Len Xanh Rêu Tay Da Kem 90s Độc Bản',
      productSlug: 'ao-khoac-varsity-len-xanh-reu-90s',
      productDescription:
          'Áo khoác varsity chất dạ len dày dặn phối tay da kem mềm mại, bo cổ sọc cổ điển cực hiếm size L châu Á.',
      primaryImageUrl: ProductImageResolver.assetVarsityJacket,
      productImages: const [ProductImageResolver.assetVarsityJacket],
      categoryName: 'Áo khoác',
      condition: 'LIKE_NEW',
      authenticityGuarantee: true,
      sellerDisplayName: 'Vintage House Quận 3',
      sellerTrustScore: 99,
      recentBids: const [],
    );

    _demoAuctionsById[9004] = AuctionDetailModel(
      id: 9004,
      auctionCode: 'AUC-2026-9004',
      productId: 9104,
      sellerId: 504,
      startingPrice: 480000,
      minBidIncrement: 20000,
      minimumNextBid: 500000,
      currentHighestBid: 480000,
      bidCount: 0,
      watchCount: 19,
      status: 'SCHEDULED',
      auctionStartsAt: now.add(const Duration(hours: 3, minutes: 10)),
      auctionEndsAt: now.add(const Duration(hours: 5, minutes: 10)),
      productTitle: 'Túi Đeo Chéo Da Bò Sáp Khóa Đồng Cổ Điển',
      productSlug: 'tui-deo-cheo-da-bo-sap-khoa-dong',
      productDescription:
          'Túi da bò thật nguyên miếng lên màu patina tự nhiên cực đẹp, khóa đồng đúc chắc chắn, vừa laptop 13 inch.',
      primaryImageUrl: ProductImageResolver.assetLeatherBag,
      productImages: const [ProductImageResolver.assetLeatherBag],
      categoryName: 'Túi',
      condition: 'GOOD',
      sellerDisplayName: 'Thrift Corner Hà Nội',
      sellerTrustScore: 95,
      recentBids: const [],
    );

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
      categoryName: 'Quần',
      condition: 'GOOD',
      sellerDisplayName: 'Retro Closet Sài Gòn',
      sellerTrustScore: 96,
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

  /// Realistic secondhand products for Nearby Popular Stores & New Arrivals fallback/enrichment.
  List<ProductSummaryModel> get demoCatalogProducts {
    return [
      ProductSummaryModel(
        id: 8101,
        productCode: 'PRD-2026-8101',
        title: 'Áo Khoác Varsity Len Xanh Rêu Tay Da Kem 90s',
        slug: 'ao-khoac-varsity-len-xanh-reu-90s',
        listingType: 'FIXED_PRICE',
        condition: 'LIKE_NEW',
        price: 389000,
        status: 'APPROVED',
        isFavorited: _favoritedProductIds.contains(8101),
        primaryImageUrl: ProductImageResolver.assetVarsityJacket,
        sellerId: 502,
        sellerDisplayName: 'Retro Closet Quận 1',
        sellerTrustScore: 98,
        categoryId: 1,
        categoryName: 'Áo khoác',
        brandName: 'Vintage USA',
      ),
      ProductSummaryModel(
        id: 8102,
        productCode: 'PRD-2026-8102',
        title: 'Áo Len Cardigan Xanh Navy Kẻ Đỏ Đô Cổ Điển',
        slug: 'ao-len-cardigan-xanh-navy-ke-do',
        listingType: 'FIXED_PRICE',
        condition: 'GOOD',
        price: 259000,
        status: 'APPROVED',
        isFavorited: _favoritedProductIds.contains(8102),
        primaryImageUrl: ProductImageResolver.assetKnitCardigan,
        sellerId: 503,
        sellerDisplayName: 'Vintage House Quận 3',
        sellerTrustScore: 97,
        categoryId: 2,
        categoryName: 'Áo',
        brandName: 'Ralph Retro',
      ),
      ProductSummaryModel(
        id: 8103,
        productCode: 'PRD-2026-8103',
        title: 'Quần Jean Selvedge Ống Đứng Thập Niên 90s',
        slug: 'quan-jean-selvedge-ong-dung-90s',
        listingType: 'FIXED_PRICE',
        condition: 'GOOD',
        price: 340000,
        status: 'APPROVED',
        isFavorited: _favoritedProductIds.contains(8103),
        primaryImageUrl: ProductImageResolver.assetDenimJeans,
        sellerId: 504,
        sellerDisplayName: 'Thrift Corner Bình Thạnh',
        sellerTrustScore: 95,
        categoryId: 3,
        categoryName: 'Quần',
        brandName: "Levi's 501",
      ),
      ProductSummaryModel(
        id: 8104,
        productCode: 'PRD-2026-8104',
        title: 'Giày Sneaker Retro Da Lộn Xanh Rêu Kem Size 41',
        slug: 'giay-sneaker-retro-da-lon-xanh-reu',
        listingType: 'FIXED_PRICE',
        condition: 'LIKE_NEW',
        price: 520000,
        status: 'APPROVED',
        isFavorited: _favoritedProductIds.contains(8104),
        primaryImageUrl: ProductImageResolver.assetRetroSneakers,
        sellerId: 505,
        sellerDisplayName: 'Tiệm Giày Si Phú Nhuận',
        sellerTrustScore: 96,
        categoryId: 4,
        categoryName: 'Giày',
        brandName: 'Court Retro',
      ),
      ProductSummaryModel(
        id: 8105,
        productCode: 'PRD-2026-8105',
        title: 'Túi Đeo Chéo Da Bò Sáp Khóa Đồng Vintage',
        slug: 'tui-deo-cheo-da-bo-sap-vintage',
        listingType: 'FIXED_PRICE',
        condition: 'VINTAGE_WORN',
        price: 465000,
        status: 'APPROVED',
        isFavorited: _favoritedProductIds.contains(8105),
        primaryImageUrl: ProductImageResolver.assetLeatherBag,
        sellerId: 506,
        sellerDisplayName: 'Xưởng Đồ Da Cũ Thủ Đức',
        sellerTrustScore: 99,
        categoryId: 5,
        categoryName: 'Túi',
        brandName: 'Coach Vintage',
      ),
      ProductSummaryModel(
        id: 8106,
        productCode: 'PRD-2026-8106',
        title: 'Sơ Mi Flannel Kẻ Caro Đỏ Rượu Xanh Rêu Dày',
        slug: 'so-mi-flannel-ke-caro-do-ruou',
        listingType: 'FIXED_PRICE',
        condition: 'LIKE_NEW',
        price: 215000,
        status: 'APPROVED',
        isFavorited: _favoritedProductIds.contains(8106),
        primaryImageUrl: ProductImageResolver.assetFlannelShirt,
        sellerId: 502,
        sellerDisplayName: 'Retro Closet Quận 1',
        sellerTrustScore: 98,
        categoryId: 2,
        categoryName: 'Áo',
        brandName: 'Pendleton',
      ),
      ProductSummaryModel(
        id: 8107,
        productCode: 'PRD-2026-8107',
        title: 'Đồng Hồ Cơ Mặt Kem Dây Da Nâu Cổ Điển 1978',
        slug: 'dong-ho-co-mat-kem-day-da-nau',
        listingType: 'FIXED_PRICE',
        condition: 'GOOD',
        price: 890000,
        status: 'APPROVED',
        isFavorited: _favoritedProductIds.contains(8107),
        primaryImageUrl: ProductImageResolver.assetMechanicalWatch,
        sellerId: 501,
        sellerDisplayName: 'Tiệm Phim & Đồ Cổ Chú Bảy',
        sellerTrustScore: 98,
        categoryId: 6,
        categoryName: 'Phụ kiện',
        brandName: 'Seiko Vintage',
      ),
      ProductSummaryModel(
        id: 8108,
        productCode: 'PRD-2026-8108',
        title: 'Máy Ảnh Phim 35mm SLR Cổ Điển Kèm Lens 50mm',
        slug: 'may-anh-phim-35mm-slr-co-dien',
        listingType: 'FIXED_PRICE',
        condition: 'FAIR',
        price: 1650000,
        status: 'APPROVED',
        isFavorited: _favoritedProductIds.contains(8108),
        primaryImageUrl: ProductImageResolver.assetFilmCamera,
        sellerId: 501,
        sellerDisplayName: 'Tiệm Phim & Đồ Cổ Chú Bảy',
        sellerTrustScore: 98,
        categoryId: 7,
        categoryName: 'Đồ cổ',
        brandName: 'Nikon Vintage',
      ),
    ];
  }

  /// Resolves a rich ProductDetailModel when tapping a demo-fallback product card.
  ProductDetailModel? getDemoProductDetail(int productId) {
    final match = demoCatalogProducts.where((p) => p.id == productId).firstOrNull;
    if (match == null) return null;

    final fee = (match.price * 0.06 + 7000).roundToDouble();
    final primaryUrl = match.primaryImageUrl ??
        ProductImageResolver.fallbackAssetFor(
          title: match.title,
          categoryName: match.categoryName,
          id: match.id,
        );

    return ProductDetailModel(
      id: match.id,
      productCode: match.productCode,
      title: match.title,
      slug: match.slug,
      description:
          'Sản phẩm secondhand tuyển chọn thủ công, đã giặt hấp sạch sẽ và kiểm tra đường may kỹ lưỡng trước khi lên kệ Retro Market. Phong cách vintage dễ phối đồ hằng ngày.',
      listingType: match.listingType,
      condition: match.condition,
      defectInfo:
          'Có dấu vết sử dụng rất nhẹ đúng chuẩn đồ si tuyển (${ProductImageResolver.conditionPercentLabel(match.condition)}), không rách thủng, khóa và nút hoạt động mượt.',
      verificationLevel: 'MODERATOR_REVIEWED',
      price: match.price,
      buyerProtectionFee: fee,
      totalBuyerPayable: match.price + fee,
      totalQuantity: 1,
      availableQuantity: 1,
      status: match.status,
      favoriteCount: 24,
      isFavorited: _favoritedProductIds.contains(match.id),
      isOwner: false,
      primaryImageUrl: primaryUrl,
      category: ProductCategoryBrief(
        id: match.categoryId ?? 1,
        name: match.categoryName ?? 'Vintage',
      ),
      brand: match.brandName != null
          ? ProductBrandBrief(id: match.id, name: match.brandName!)
          : null,
      seller: ProductSellerInfo(
        id: match.sellerId ?? 501,
        displayName: match.sellerDisplayName ?? 'Retro Closet',
        trustScore: match.sellerTrustScore ?? 98,
        averageRating: 4.9,
        completedOrdersCount: 142,
      ),
      images: [
        ProductImageModel(
          id: match.id * 10 + 1,
          imageUrl: primaryUrl,
          imageType: 'GALLERY',
          isPrimary: true,
        ),
      ],
      relatedProducts: demoCatalogProducts
          .where((p) => p.id != match.id)
          .take(4)
          .toList(),
    );
  }

  static const List<CategoryModel> fallbackCategories = [
    CategoryModel(id: 1, name: 'Áo khoác', slug: 'ao-khoac'),
    CategoryModel(id: 2, name: 'Áo', slug: 'ao'),
    CategoryModel(id: 3, name: 'Quần', slug: 'quan'),
    CategoryModel(id: 4, name: 'Giày', slug: 'giay'),
    CategoryModel(id: 5, name: 'Túi xách', slug: 'tui-xach'),
    CategoryModel(id: 6, name: 'Phụ kiện', slug: 'phu-kien'),
    CategoryModel(id: 7, name: 'Đồ cổ', slug: 'do-co'),
  ];

  static const List<FeaturedSellerModel> fallbackFeaturedSellers = [
    FeaturedSellerModel(
      id: 502,
      userId: 502,
      shopName: 'Retro Closet Quận 1',
      shopSlug: 'retro-closet-quan-1',
      trustScore: 98,
      ratingAvg: 4.9,
      completedOrdersCount: 328,
    ),
    FeaturedSellerModel(
      id: 503,
      userId: 503,
      shopName: 'Vintage House Quận 3',
      shopSlug: 'vintage-house-quan-3',
      trustScore: 97,
      ratingAvg: 4.8,
      completedOrdersCount: 210,
    ),
    FeaturedSellerModel(
      id: 504,
      userId: 504,
      shopName: 'Thrift Corner Bình Thạnh',
      shopSlug: 'thrift-corner-binh-thanh',
      trustScore: 95,
      ratingAvg: 4.7,
      completedOrdersCount: 180,
    ),
  ];
}

final retroDemoStoreProvider = ChangeNotifierProvider<RetroDemoMarketplaceStore>(
  (ref) => RetroDemoMarketplaceStore(),
);
