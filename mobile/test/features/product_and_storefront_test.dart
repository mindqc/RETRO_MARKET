import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:izithrift/core/network/api_envelope.dart';
import 'package:izithrift/core/network/dio_client.dart';
import 'package:izithrift/core/services/secure_token_storage.dart';
import 'package:izithrift/core/services/server_time_service.dart';
import 'package:izithrift/core/theme/seasonal_decor_provider.dart';
import 'package:izithrift/core/widgets/price_breakdown_card.dart';
import 'package:izithrift/features/auth/models/user_model.dart';
import 'package:izithrift/features/auth/repositories/auth_repository.dart';
import 'package:izithrift/features/auth/viewmodels/auth_view_model.dart';
import 'package:izithrift/features/catalog/models/product_detail_model.dart';
import 'package:izithrift/features/catalog/models/product_image_model.dart';
import 'package:izithrift/features/catalog/models/product_summary_model.dart';
import 'package:izithrift/features/catalog/models/review_item_model.dart';
import 'package:izithrift/features/catalog/models/seller_public_profile_model.dart';
import 'package:izithrift/features/catalog/repositories/home_catalog_repository.dart';
import 'package:izithrift/features/catalog/repositories/seller_storefront_repository.dart';
import 'package:izithrift/features/catalog/screens/defect_verification_modal.dart';
import 'package:izithrift/features/catalog/screens/full_screen_zoom_viewer.dart';
import 'package:izithrift/features/catalog/screens/product_detail_screen.dart';
import 'package:izithrift/features/catalog/screens/public_seller_storefront_screen.dart';
import 'package:izithrift/features/home/models/auction_summary_model.dart';
import 'package:izithrift/features/profile/repositories/profile_repository.dart';

/// Fake AuthViewModel for testing Guest vs Authenticated behaviors
class FakeAuthViewModel extends AuthViewModel {
  bool fakeAuthenticated;
  UserModel? fakeUser;

  FakeAuthViewModel({this.fakeAuthenticated = false, this.fakeUser})
      : super(
          authRepository: AuthRepository(
            dioClient: DioClient(
              tokenStorage: SecureTokenStorage(),
              serverTimeService: ServerTimeService.instance,
            ),
            tokenStorage: SecureTokenStorage(),
          ),
          profileRepository: ProfileRepository(
            dioClient: DioClient(
              tokenStorage: SecureTokenStorage(),
              serverTimeService: ServerTimeService.instance,
            ),
          ),
          tokenStorage: SecureTokenStorage(),
          seasonalDecorNotifier: SeasonalDecorNotifier(),
        );

  @override
  bool get isAuthenticated => fakeAuthenticated;

  @override
  UserModel? get currentUser => fakeUser;
}

/// Mock HomeCatalogRepository for Product Detail
class MockHomeCatalogRepository extends HomeCatalogRepository {
  MockHomeCatalogRepository()
      : super(
          dioClient: DioClient(
            tokenStorage: SecureTokenStorage(),
            serverTimeService: ServerTimeService.instance,
          ),
        );

  ProductDetailModel? stubProduct;
  bool favoriteToggled = false;
  bool cartAdded = false;

  @override
  Future<ProductDetailModel> fetchProductDetail(int productId) async {
    if (stubProduct != null) return stubProduct!;
    return ProductDetailModel(
      id: productId,
      productCode: 'PRD-$productId',
      title: 'Áo khoác da cừu Vintage Bomber 1980s',
      slug: 'ao-khoac-da-cuu-vintage-bomber',
      description: 'Chất liệu da cừu thật nguyên bản, lót nỉ ấm, khóa kéo YKK cổ điển.',
      price: 650000.0,
      buyerProtectionFee: 46000.0,
      totalBuyerPayable: 696000.0,
      listingType: 'FIXED_PRICE',
      condition: 'LIKE_NEW',
      defectInfo: 'Sờn nhẹ viền cổ áo, tổng thể form dáng 95% nguyên bản.',
      verificationLevel: 'MODERATOR_REVIEWED',
      status: 'APPROVED',
      totalQuantity: 2,
      availableQuantity: 2,
      favoriteCount: 15,
      primaryImageUrl: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?auto=format&fit=crop&w=800&q=80',
      images: const [
        ProductImageModel(
          id: 1,
          imageUrl: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?auto=format&fit=crop&w=800&q=80',
          imageType: 'GALLERY',
          isPrimary: true,
        ),
        ProductImageModel(
          id: 2,
          imageUrl: 'https://images.unsplash.com/photo-1548883354-7622d03aca27?auto=format&fit=crop&w=800&q=80',
          imageType: 'DEFECT_CLOSEUP',
          defectNote: 'Vết sờn dăm nhẹ cổ áo',
        ),
      ],
      seller: const ProductSellerInfo(
        id: 10,
        displayName: 'Tiệm Đồ Si Chú Bảy',
        avatarUrl: null,
        shopSlug: 'tiem-chu-bay',
        trustScore: 99.0,
        averageRating: 4.9,
        completedOrdersCount: 120,
      ),
      isOwner: false,
      isFavorited: false,
    );
  }

  @override
  Future<Map<String, dynamic>> toggleFavorite(int productId) async {
    favoriteToggled = true;
    return {'is_favorited': true, 'favorite_count': 16};
  }

  @override
  Future<Map<String, dynamic>> addToCart({required int productId, int quantity = 1}) async {
    cartAdded = true;
    return {'product_id': productId, 'quantity': quantity};
  }
}

/// Mock SellerStorefrontRepository
class MockSellerStorefrontRepository extends SellerStorefrontRepository {
  MockSellerStorefrontRepository()
      : super(
          dioClient: DioClient(
            tokenStorage: SecureTokenStorage(),
            serverTimeService: ServerTimeService.instance,
          ),
        );

  SellerPublicProfileModel? stubSeller;
  bool followToggled = false;

  @override
  Future<SellerPublicProfileModel> fetchSellerStorefront(
    int sellerId, {
    String tab = 'approved',
    int page = 1,
    int perPage = 12,
  }) async {
    if (stubSeller != null) return stubSeller!;
    return SellerPublicProfileModel(
      userId: sellerId,
      displayName: 'Tiệm Đồ Si Chú Bảy',
      shopSlug: 'tiem-chu-bay',
      bio: 'Chuyên đồ si bãi Nhật, Mỹ tuyển chọn từng chiếc chuẩn vintage.',
      trustScore: 98.0,
      averageRating: 4.9,
      reviewCount: 38,
      completedOrdersCount: 142,
      followersCount: 520,
      isFollowing: false,
      isOwner: false,
      activeListings: const [
        ProductSummaryModel(
          id: 501,
          productCode: 'PRD-501',
          title: 'Áo khoác da Bomber',
          slug: 'ao-khoac-da-bomber',
          listingType: 'FIXED_PRICE',
          condition: 'LIKE_NEW',
          price: 650000.0,
          status: 'APPROVED',
          sellerDisplayName: 'Tiệm Đồ Si Chú Bảy',
        ),
      ],
      auctions: [
        AuctionSummaryModel(
          id: 601,
          productId: 502,
          title: 'Đồng hồ cơ Seiko 5 Automatic 1978',
          currentBid: 950000.0,
          bidCount: 12,
          endsAt: DateTime.now().add(const Duration(hours: 4)),
          status: 'LIVE',
        ),
      ],
      soldListings: const [
        ProductSummaryModel(
          id: 503,
          productCode: 'PRD-503',
          title: 'Quần jeans Levi\'s 501 vintage',
          slug: 'quan-jeans-levis-501',
          listingType: 'FIXED_PRICE',
          condition: 'GOOD',
          price: 450000.0,
          status: 'SOLD',
          sellerDisplayName: 'Tiệm Đồ Si Chú Bảy',
        ),
      ],
      reviews: [
        ReviewItemModel(
          id: 1,
          rating: 5,
          comment: 'Áo da đẹp hơn mong đợi, form chuẩn vintage 90s, đóng gói cẩn thận!',
          reviewerName: 'Thanh Tùng',
          productTitle: 'Áo khoác da cừu Vintage',
          isVerifiedPurchase: true,
          createdAt: DateTime(2026, 11, 10),
        ),
      ],
    );
  }

  @override
  Future<Map<String, dynamic>> toggleFollowSeller(int sellerId) async {
    followToggled = true;
    return {'is_following': true, 'followers_count': 521};
  }

  @override
  Future<PaginatedResponse<ReviewItemModel>> fetchSellerReviews(
    int sellerId, {
    int? rating,
    int page = 1,
    int perPage = 10,
  }) async {
    return PaginatedResponse<ReviewItemModel>(
      items: [
        ReviewItemModel(
          id: 1,
          rating: 5,
          comment: 'Áo da đẹp hơn mong đợi, form chuẩn vintage 90s, đóng gói cẩn thận!',
          reviewerName: 'Thanh Tùng',
          productTitle: 'Áo khoác da cừu Vintage',
          isVerifiedPurchase: true,
          createdAt: DateTime(2026, 11, 10),
        ),
      ],
      meta: const PaginationMeta(
        currentPage: 1,
        lastPage: 1,
        perPage: 10,
        total: 1,
        hasMorePages: false,
      ),
    );
  }
}

void main() {
  group('Phase 07 - Task P7-06: Product Detail & Seller Storefront Test Suite', () {
    // -------------------------------------------------------------------------
    // Test 1: Model Parsing with SafeJsonParser across 5 Condition levels & DEC-04
    // -------------------------------------------------------------------------
    test('1. Parse ProductDetailModel, SellerPublicProfileModel, ReviewItemModel with SafeJsonParser across all 5 Condition levels', () {
      final conditions = [
        'NEW_WITH_TAGS',
        'LIKE_NEW',
        'GOOD',
        'FAIR',
        'VINTAGE_WORN',
      ];

      for (final cond in conditions) {
        final json = {
          'id': 101,
          'product_code': 'PRD-101',
          'title': 'Sản phẩm vintage condition $cond',
          'slug': 'san-pham-vintage',
          'description': 'Mô tả chi tiết',
          'price': '500000.00',
          'listing_type': 'FIXED_PRICE',
          'condition': cond,
          'defect_info': 'Xước nhẹ',
          'verification_level': 'MODERATOR_REVIEWED',
          'status': 'APPROVED',
          'available_quantity': '3',
          'favorite_count': '12',
          'is_owner': 0,
          'is_favorited': 1,
          'images': [
            {
              'id': 1,
              'image_url': 'https://example.com/img1.jpg',
              'image_type': 'GALLERY',
              'is_primary': 1,
              'sort_order': 0,
              'file_size_bytes': 102400,
            },
            {
              'id': 2,
              'image_url': 'https://example.com/defect.jpg',
              'image_type': 'DEFECT_CLOSEUP',
              'defect_note': 'Cận cảnh vết ố',
              'sort_order': 1,
            },
          ],
        };

        final product = ProductDetailModel.fromJson(json);

        expect(product.id, 101);
        expect(product.condition, cond);
        expect(product.price, 500000.0);
        // DEC-04: round(500,000 * 6% + 7,000) = 37,000
        expect(product.buyerProtectionFee, 37000.0);
        expect(product.totalBuyerPayable, 537000.0);
        expect(product.isOwner, false);
        expect(product.isFavorited, true);
        expect(product.images.length, 2);
        expect(product.images[1].imageType, 'DEFECT_CLOSEUP');
        expect(product.images[1].defectNote, 'Cận cảnh vết ố');
      }

      // Test ReviewItemModel
      final reviewJson = {
        'id': 77,
        'order_id': 120,
        'product_id': 101,
        'rating': 5,
        'comment': 'Đồ rất mới và đẹp!',
        'reviewer': {
          'id': 5,
          'display_name': 'Hoàng Long',
          'avatar_url': 'https://example.com/avatar.jpg',
        },
        'product': {
          'id': 101,
          'title': 'Áo vintage',
        },
        'is_verified_purchase': true,
      };
      final review = ReviewItemModel.fromJson(reviewJson);
      expect(review.id, 77);
      expect(review.rating, 5);
      expect(review.reviewerName, 'Hoàng Long');
      expect(review.isVerifiedPurchase, true);

      // Test SellerPublicProfileModel
      final sellerJson = {
        'seller': {
          'id': 10,
          'display_name': 'Tiệm Cũ Sài Gòn',
          'shop_slug': 'tiem-cu-sg',
          'trust_score': '99.50',
          'average_rating': '4.95',
          'review_count': 45,
          'completed_orders_count': 160,
        },
        'followers_count': 320,
        'is_following': 1,
        'is_owner': 0,
      };
      final seller = SellerPublicProfileModel.fromJson(sellerJson);
      expect(seller.userId, 10);
      expect(seller.displayName, 'Tiệm Cũ Sài Gòn');
      expect(seller.trustScore, 99.5);
      expect(seller.followersCount, 320);
      expect(seller.isFollowing, true);
    });

    // -------------------------------------------------------------------------
    // Test 2: ProductDetailScreen (M-PD-01) displays price breakdown and seller card
    // -------------------------------------------------------------------------
    testWidgets('2. ProductDetailScreen displays product title, code, PriceBreakdownCard DEC-04, seller card and defect inspection when isOwner is false', (tester) async {
      final mockRepo = MockHomeCatalogRepository();
      final fakeAuth = FakeAuthViewModel(fakeAuthenticated: true);

      final container = ProviderContainer(
        overrides: [
          homeCatalogRepositoryProvider.overrideWithValue(mockRepo),
          authViewModelProvider.overrideWith((ref) => fakeAuth),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProductDetailScreen(productId: 201),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify product code and title
      expect(find.text('PRD-201'), findsOneWidget);
      expect(find.text('Áo khoác da cừu Vintage Bomber 1980s'), findsOneWidget);

      // Verify PriceBreakdownCard (DEC-04)
      expect(find.byType(PriceBreakdownCard), findsOneWidget);
      expect(find.text('Chi tiết thanh toán'), findsOneWidget);
      expect(find.text('Phí bảo vệ người mua'), findsOneWidget);

      // Verify Seller Micro-Card
      expect(find.text('Tiệm Đồ Si Chú Bảy'), findsOneWidget);
      expect(find.text('Xem Tiệm'), findsOneWidget);

      // Verify Defect Inspection Trigger
      expect(find.text('Kiểm định khuyết điểm đồ si'), findsOneWidget);
      expect(find.text('Xem phiếu kiểm định →'), findsOneWidget);

      // Verify Buyer buttons are active (isOwner == false)
      expect(find.text('Thêm vào giỏ'), findsOneWidget);
      expect(find.text('Mua ngay'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 3: Enforcing BR-AC-02 (Self-Transaction Forbidden)
    // -------------------------------------------------------------------------
    testWidgets('3. Enforce BR-AC-02: When isOwner is true, buy and add to cart buttons are hidden and owner management banner is displayed', (tester) async {
      final mockRepo = MockHomeCatalogRepository();
      mockRepo.stubProduct = (await mockRepo.fetchProductDetail(201)).copyWith(isOwner: true);

      final container = ProviderContainer(
        overrides: [
          homeCatalogRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProductDetailScreen(productId: 201),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Buyer buttons must NOT be present
      expect(find.text('Thêm vào giỏ'), findsNothing);
      expect(find.text('Mua ngay'), findsNothing);

      // Owner restriction banner must be displayed
      expect(find.text('Đây là sản phẩm của bạn'), findsOneWidget);
      expect(find.text('Bạn không thể mua hàng của chính mình (BR-AC-02).'), findsOneWidget);
      expect(find.text('Quản lý'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 4: DefectVerificationModal (M-PD-02) explains 5 Condition tiers
    // -------------------------------------------------------------------------
    testWidgets('4. DefectVerificationModal displays defect details, evidence gallery and explanations for all 5 condition levels', (tester) async {
      final sampleProduct = ProductDetailModel(
        id: 301,
        productCode: 'PRD-301',
        title: 'Áo len dệt kim vintage',
        slug: 'ao-len-vintage',
        description: 'Mô tả áo len',
        price: 250000.0,
        buyerProtectionFee: 22000.0,
        totalBuyerPayable: 272000.0,
        listingType: 'FIXED_PRICE',
        condition: 'NEW_WITH_TAGS',
        defectInfo: 'Áo nguyên mác, chưa mặc, không xước rách.',
        verificationLevel: 'HIGH_VALUE_VERIFIED',
        status: 'APPROVED',
        primaryImageUrl: 'https://example.com/img.jpg',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefectVerificationModal(product: sampleProduct),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Phiếu Kiểm Định Đồ Si'), findsOneWidget);
      expect(find.text('Thang Chuẩn Tình Trạng Đồ Si (5 Mức)'), findsOneWidget);

      final modalScrollable = find
          .descendant(
            of: find.byType(DefectVerificationModal),
            matching: find.byType(Scrollable),
          )
          .first;

      // Verify top tiers are visible
      expect(find.text('Mới còn tag (New With Tags)'), findsOneWidget);
      expect(find.text('Như mới (Like New 95% - 99%)'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Tốt (Good)'),
        100,
        scrollable: modalScrollable,
      );
      expect(find.text('Tốt (Good)'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Sản phẩm này'),
        100,
        scrollable: modalScrollable,
      );
      expect(find.text('Sản phẩm này'), findsOneWidget);

      // Scroll to reveal remaining condition tiers
      await tester.scrollUntilVisible(
        find.text('Trung bình (Fair)'),
        100,
        scrollable: modalScrollable,
      );
      expect(find.text('Trung bình (Fair)'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Vintage sờn rách tự nhiên (Vintage Worn)'),
        100,
        scrollable: modalScrollable,
      );
      expect(find.text('Vintage sờn rách tự nhiên (Vintage Worn)'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 5: FullScreenZoomViewer (M-DS-04) InteractiveViewer
    // -------------------------------------------------------------------------
    testWidgets('5. FullScreenZoomViewer initializes InteractiveViewer with maxScale 4.0 and navigates between photos', (tester) async {
      const sampleImages = [
        ProductImageModel(
          id: 1,
          imageUrl: 'https://example.com/img1.jpg',
          imageType: 'GALLERY',
        ),
        ProductImageModel(
          id: 2,
          imageUrl: 'https://example.com/img2.jpg',
          imageType: 'DEFECT_CLOSEUP',
          defectNote: 'Chỗ rách nhẹ ở gấu áo',
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: FullScreenZoomViewer(
            images: sampleImages,
            initialIndex: 0,
            title: 'Áo vintage 1980s',
          ),
        ),
      );
      await tester.pump();

      // Check InteractiveViewer exists with maxScale: 4.0
      final viewerFinder = find.byType(InteractiveViewer);
      expect(viewerFinder, findsOneWidget);
      final interactiveViewer = tester.widget<InteractiveViewer>(viewerFinder);
      expect(interactiveViewer.maxScale, 4.0);
      expect(interactiveViewer.minScale, 1.0);

      // Check Photo counter
      expect(find.text('Ảnh 1 / 2'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 6: PublicSellerStorefrontScreen (M-US-03) 4 Tabs & Reviews
    // -------------------------------------------------------------------------
    testWidgets('6. PublicSellerStorefrontScreen displays Trust Score, stats and navigates smoothly between 4 content tabs', (tester) async {
      final mockSellerRepo = MockSellerStorefrontRepository();

      final container = ProviderContainer(
        overrides: [
          sellerStorefrontRepositoryProvider.overrideWithValue(mockSellerRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PublicSellerStorefrontScreen(sellerId: 10),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header info
      expect(find.text('Tiệm Đồ Si Chú Bảy'), findsWidgets);
      expect(find.text('Trust 98/100'), findsOneWidget);
      expect(find.text('+ Theo dõi'), findsOneWidget);

      // Verify 4 Tab labels
      expect(find.text('Đang bán (1)'), findsOneWidget);
      expect(find.text('Đấu giá (1)'), findsOneWidget);
      expect(find.text('Đã bán (1)'), findsOneWidget);
      expect(find.text('Đánh giá (38)'), findsOneWidget);

      // Tap on 'Đánh giá' tab
      await tester.tap(find.text('Đánh giá (38)'));
      await tester.pumpAndSettle();

      // Verify verified review displayed
      expect(find.text('Thanh Tùng'), findsOneWidget);
      expect(find.text('Đã mua hàng'), findsOneWidget);
      expect(find.text('Áo da đẹp hơn mong đợi, form chuẩn vintage 90s, đóng gói cẩn thận!'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 7: Interaction Guards (DEC-01 Guest Prompt & Optimistic updates)
    // -------------------------------------------------------------------------
    testWidgets('7. Interaction: Follow Seller and Add to Cart trigger guest login prompt when unauthenticated', (tester) async {
      final mockRepo = MockHomeCatalogRepository();
      final fakeAuthGuest = FakeAuthViewModel(fakeAuthenticated: false);

      final container = ProviderContainer(
        overrides: [
          homeCatalogRepositoryProvider.overrideWithValue(mockRepo),
          authViewModelProvider.overrideWith((ref) => fakeAuthGuest),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProductDetailScreen(productId: 201),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Guest clicks 'Thêm vào giỏ' -> triggers DEC-01 guest prompt dialog
      await tester.tap(find.text('Thêm vào giỏ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Yêu cầu đăng nhập'), findsOneWidget);
      expect(find.text('Đăng nhập ngay'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Để sau'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Guest clicks Favorite icon -> also triggers DEC-01 guest prompt dialog
      await tester.tap(find.byTooltip('Yêu thích'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Yêu cầu đăng nhập'), findsOneWidget);
    });
  });
}
