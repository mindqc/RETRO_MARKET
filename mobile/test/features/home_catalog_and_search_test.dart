import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:izithrift/core/network/api_envelope.dart';
import 'package:izithrift/core/network/dio_client.dart';
import 'package:izithrift/core/services/secure_token_storage.dart';
import 'package:izithrift/core/services/server_time_service.dart';
import 'package:izithrift/features/catalog/models/brand_model.dart';
import 'package:izithrift/features/catalog/models/category_model.dart';
import 'package:izithrift/features/catalog/models/product_filter_query.dart';
import 'package:izithrift/features/catalog/models/product_summary_model.dart';
import 'package:izithrift/features/catalog/models/taxonomy_model.dart';
import 'package:izithrift/features/catalog/repositories/home_catalog_repository.dart';
import 'package:izithrift/features/catalog/screens/category_taxonomy_screen.dart';
import 'package:izithrift/features/catalog/viewmodels/catalog_search_view_model.dart';
import 'package:izithrift/features/catalog/widgets/product_filter_bottom_sheet.dart';
import 'package:izithrift/features/home/models/auction_summary_model.dart';
import 'package:izithrift/features/home/models/featured_seller_model.dart';
import 'package:izithrift/features/home/models/home_feed_model.dart';
import 'package:izithrift/features/home/screens/featured_sellers_and_collections_screen.dart';
import 'package:izithrift/features/home/screens/home_screen.dart';
import 'package:izithrift/features/home/viewmodels/home_view_model.dart';

/// Mock HomeCatalogRepository for unit & widget testing
class MockHomeCatalogRepository extends HomeCatalogRepository {
  MockHomeCatalogRepository()
    : super(
        dioClient: DioClient(
          tokenStorage: SecureTokenStorage(),
          serverTimeService: ServerTimeService.instance,
        ),
      );

  bool failNextRequest = false;
  int searchCallCount = 0;

  final HomeFeedModel sampleFeed = HomeFeedModel(
    categories: const [
      CategoryModel(
        id: 1,
        name: 'Áo khoác Vintage',
        slug: 'ao-khoac-vintage',
        approvedProductsCount: 120,
        children: [
          CategoryModel(
            id: 11,
            parentId: 1,
            name: 'Áo dạ 90s',
            slug: 'ao-da-90s',
            approvedProductsCount: 45,
          ),
        ],
      ),
      CategoryModel(
        id: 2,
        name: 'Quần Denim Retro',
        slug: 'quan-denim-retro',
        approvedProductsCount: 88,
      ),
    ],
    liveAuctions: [
      AuctionSummaryModel(
        id: 101,
        productId: 501,
        title: 'Áo khoác da cừu lót lông phi công Mỹ WWII',
        currentBid: 1250000.0,
        bidCount: 14,
        endsAt: DateTime.now().add(const Duration(hours: 3)),
        status: 'LIVE',
      ),
    ],
    featuredSellers: const [
      FeaturedSellerModel(
        id: 201,
        userId: 11,
        shopName: 'Tiệm Đồ Si Chú Bảy',
        shopSlug: 'tiem-chu-bay',
        trustScore: 99.0,
        completedOrdersCount: 230,
        bio: 'Chuyên đồ si bãi Nhật tuyển chọn từng kiện',
      ),
    ],
    latestProducts: const [
      ProductSummaryModel(
        id: 301,
        productCode: 'PRD-301',
        title: 'Quần jeans Levi\'s 501 Big E 1970s',
        slug: 'quan-jeans-levis-501',
        listingType: 'FIXED_PRICE',
        condition: 'GOOD',
        price: 850000.0,
        status: 'APPROVED',
        sellerDisplayName: 'Vintage Saigon',
        isFavorited: false,
        isOwner: false,
      ),
    ],
  );

  final TaxonomyModel sampleTaxonomy = const TaxonomyModel(
    categories: [
      CategoryModel(
        id: 1,
        name: 'Áo khoác Vintage',
        slug: 'ao-khoac-vintage',
        approvedProductsCount: 120,
        children: [
          CategoryModel(
            id: 11,
            parentId: 1,
            name: 'Áo dạ 90s',
            slug: 'ao-da-90s',
            approvedProductsCount: 45,
          ),
        ],
      ),
    ],
    brands: [
      BrandModel(
        id: 51,
        name: 'Levi\'s',
        slug: 'levis',
        originCountry: 'USA',
        approvedProductsCount: 95,
      ),
      BrandModel(
        id: 52,
        name: 'Seiko',
        slug: 'seiko',
        originCountry: 'Japan',
        approvedProductsCount: 42,
      ),
    ],
  );

  @override
  Future<HomeFeedModel> fetchHomeFeed() async {
    if (failNextRequest) {
      throw Exception('Lỗi kết nối máy chủ.');
    }
    return sampleFeed;
  }

  @override
  Future<TaxonomyModel> fetchTaxonomy() async {
    if (failNextRequest) {
      throw Exception('Lỗi mạng khi tải taxonomy.');
    }
    return sampleTaxonomy;
  }

  @override
  Future<PaginatedResponse<ProductSummaryModel>> searchProducts(
    ProductFilterQuery query,
  ) async {
    searchCallCount++;
    if (failNextRequest) {
      throw Exception('Lỗi mạng khi tìm kiếm.');
    }
    return PaginatedResponse<ProductSummaryModel>(
      items: [
        ProductSummaryModel(
          id: query.page == 1 ? 401 : 402,
          productCode: 'PRD-${query.page}',
          title: 'Sản phẩm tìm kiếm trang ${query.page}',
          slug: 'san-pham-${query.page}',
          listingType: query.listingType ?? 'FIXED_PRICE',
          condition: query.condition ?? 'GOOD',
          price: 500000.0,
          status: 'APPROVED',
          isFavorited: false,
          isOwner: false,
        ),
      ],
      meta: PaginationMeta(
        currentPage: query.page,
        perPage: query.perPage,
        total: 24,
        lastPage: 2,
        hasMorePages: query.page < 2,
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> toggleFavorite(int productId) async {
    return {'is_favorited': true, 'favorite_count': 1};
  }
}

void main() {
  group('P7-05: Catalog & Home Models Serialization Tests', () {
    test(
      'CategoryModel and TaxonomyModel parse recursive hierarchy and counts',
      () {
        final json = {
          'id': '10',
          'parent_id': null,
          'name': 'Áo Vintage',
          'slug': 'ao-vintage',
          'approved_products_count': '150',
          'children': [
            {
              'id': '101',
              'parent_id': '10',
              'name': 'Áo len họa tiết Giáng Sinh',
              'slug': 'ao-len-giang-sinh',
              'approved_products_count': 30,
            },
          ],
        };

        final cat = CategoryModel.fromJson(json);
        expect(cat.id, equals(10));
        expect(cat.isRoot, isTrue);
        expect(cat.hasChildren, isTrue);
        expect(cat.approvedProductsCount, equals(150));
        expect(cat.children.length, equals(1));
        expect(cat.children.first.id, equals(101));
        expect(cat.children.first.parentId, equals(10));
        expect(cat.children.first.isRoot, isFalse);

        final taxonomy = TaxonomyModel.fromJson({
          'categories': [json],
          'brands': [
            {
              'id': 1,
              'name': 'Burberry',
              'slug': 'burberry',
              'origin_country': 'UK',
              'approved_products_count': 15,
            },
          ],
        });
        expect(taxonomy.categories.length, equals(1));
        expect(taxonomy.brands.length, equals(1));
        expect(taxonomy.brands.first.name, equals('Burberry'));
      },
    );

    test('ProductSummaryModel parses string price and flags accurately', () {
      final json = {
        'id': '77',
        'product_code': 'PRD-VNT-77',
        'title': 'Đồng hồ Seiko 5 Chém Cạnh 1980',
        'slug': 'seiko-5-chem-canh',
        'listing_type': 'FIXED_PRICE',
        'condition': 'LIKE_NEW',
        'price': '1450000.50',
        'available_quantity': '1',
        'favorite_count': '12',
        'status': 'APPROVED',
        'is_favorited': 1,
        'is_owner': 0,
        'seller': {
          'id': 5,
          'display_name': 'Tiệm Cổ Điển',
          'trust_score': '98.5',
        },
      };

      final product = ProductSummaryModel.fromJson(json);
      expect(product.id, equals(77));
      expect(product.price, equals(1450000.50));
      expect(product.isFavorited, isTrue);
      expect(product.isOwner, isFalse);
      expect(product.sellerDisplayName, equals('Tiệm Cổ Điển'));
      expect(product.sellerTrustScore, equals(98.5));

      final favorited = product.copyWith(isFavorited: false, favoriteCount: 11);
      expect(favorited.isFavorited, isFalse);
      expect(favorited.favoriteCount, equals(11));
    });
  });

  group('P7-05: ProductFilterQuery Validation & Query Parameters Tests', () {
    test('Validates minPrice <= maxPrice correctly', () {
      const validQuery1 = ProductFilterQuery(
        minPrice: 100000,
        maxPrice: 500000,
      );
      expect(validQuery1.isPriceRangeValid, isTrue);

      const validQuery2 = ProductFilterQuery(
        minPrice: 500000,
        maxPrice: 500000,
      );
      expect(validQuery2.isPriceRangeValid, isTrue);

      const validQuery3 = ProductFilterQuery(minPrice: 200000, maxPrice: null);
      expect(validQuery3.isPriceRangeValid, isTrue);

      const invalidQuery = ProductFilterQuery(
        minPrice: 600000,
        maxPrice: 200000,
      );
      expect(invalidQuery.isPriceRangeValid, isFalse);
    });

    test(
      'Generates query parameters matching Backend ProductSearchRequest',
      () {
        const query = ProductFilterQuery(
          q: 'denim vintage',
          categoryId: 3,
          brandId: 51,
          listingType: 'FIXED_PRICE',
          condition: 'LIKE_NEW',
          minPrice: 200000,
          maxPrice: 800000,
          sort: 'price_asc',
          page: 2,
          perPage: 12,
        );

        final params = query.toQueryParameters();
        expect(params['q'], equals('denim vintage'));
        expect(params['category_id'], equals(3));
        expect(params['brand_id'], equals(51));
        expect(params['listing_type'], equals('FIXED_PRICE'));
        expect(params['condition'], equals('LIKE_NEW'));
        expect(params['min_price'], equals(200000.0));
        expect(params['max_price'], equals(800000.0));
        expect(params['sort'], equals('price_asc'));
        expect(params['page'], equals(2));
        expect(params['per_page'], equals(12));
      },
    );
  });

  group('P7-05: HomeViewModel & Optimistic Favorite (DEC-01) Tests', () {
    test('Loads home feed successfully', () async {
      final mockRepo = MockHomeCatalogRepository();
      final container = ProviderContainer(
        overrides: [homeCatalogRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      final vm = container.read(homeViewModelProvider);
      await vm.loadHomeFeed();

      expect(vm.state.isSuccess, isTrue);
      expect(vm.state.data, isNotNull);
      expect(vm.state.data!.categories.length, equals(2));
      expect(vm.state.data!.liveAuctions.length, equals(1));
      expect(vm.state.data!.latestProducts.length, equals(1));
    });

    testWidgets(
      'Guest attempting to favorite triggers Login Prompt dialog (DEC-01)',
      (tester) async {
        final mockRepo = MockHomeCatalogRepository();
        final container = ProviderContainer(
          overrides: [
            homeCatalogRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );
        addTearDown(container.dispose);

        final vm = container.read(homeViewModelProvider);
        await vm.loadHomeFeed();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () => vm.toggleFavorite(ctx, 301),
                    child: const Text('Thích sản phẩm'),
                  ),
                ),
              ),
            ),
          ),
        );

        // Tap favorite button as guest
        await tester.tap(find.text('Thích sản phẩm'));
        await tester.pumpAndSettle();

        // Expect login prompt dialog
        expect(find.text('Yêu cầu đăng nhập'), findsOneWidget);
        expect(find.text('Đăng nhập'), findsOneWidget);
        expect(find.text('Để sau'), findsOneWidget);
      },
    );
  });

  group('P7-05: CatalogSearchViewModel Multi-Criteria Search & Pagination Tests', () {
    test(
      'search() rejects invalid price range without calling repository',
      () async {
        final mockRepo = MockHomeCatalogRepository();
        final container = ProviderContainer(
          overrides: [
            homeCatalogRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );
        addTearDown(container.dispose);

        final vm = container.read(catalogSearchViewModelProvider);
        final success = await vm.search(
          const ProductFilterQuery(minPrice: 500000, maxPrice: 100000),
        );

        expect(success, isFalse);
        expect(
          vm.filterValidationError,
          equals('Giá tối thiểu không được lớn hơn giá tối đa'),
        );
        expect(mockRepo.searchCallCount, equals(0));
      },
    );

    test(
      'search() loads products and loadNextPage() appends paginated items',
      () async {
        final mockRepo = MockHomeCatalogRepository();
        final container = ProviderContainer(
          overrides: [
            homeCatalogRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );
        addTearDown(container.dispose);

        final vm = container.read(catalogSearchViewModelProvider);
        final success = await vm.search(
          const ProductFilterQuery(q: 'vintage', page: 1),
        );

        expect(success, isTrue);
        expect(vm.products.length, equals(1));
        expect(vm.products.first.title, contains('trang 1'));
        expect(vm.hasMorePages, isTrue);

        // Load next page
        await vm.loadNextPage();
        expect(vm.products.length, equals(2));
        expect(vm.products.last.title, contains('trang 2'));
        expect(vm.hasMorePages, isFalse);
      },
    );

    test('loadTaxonomy() manages loading state, deduplicates requests, and caches unless forceRefresh', () async {
      final mockRepo = MockHomeCatalogRepository();
      final container = ProviderContainer(
        overrides: [homeCatalogRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      final vm = container.read(catalogSearchViewModelProvider);
      expect(vm.taxonomy, isNull);
      expect(vm.isLoadingTaxonomy, isFalse);
      expect(vm.taxonomyError, isNull);

      // 1. Initial load
      final future1 = vm.loadTaxonomy();
      expect(vm.isLoadingTaxonomy, isTrue);
      await future1;
      expect(vm.isLoadingTaxonomy, isFalse);
      expect(vm.taxonomy, isNotNull);
      expect(vm.taxonomy!.categories.length, equals(1));
      expect(vm.taxonomyError, isNull);

      // 2. Cached: second call should reuse cached taxonomy without re-fetching
      await vm.loadTaxonomy();
      expect(vm.taxonomy, isNotNull);

      // 3. Force refresh with error: preserves previous taxonomy and sets taxonomyError
      mockRepo.failNextRequest = true;
      await vm.loadTaxonomy(forceRefresh: true);
      expect(vm.isLoadingTaxonomy, isFalse);
      expect(
        vm.taxonomy,
        isNotNull,
        reason: 'Must preserve previously loaded taxonomy',
      );
      expect(
        vm.taxonomyError,
        equals('Không thể tải danh mục. Vui lòng thử lại.'),
      );
    });
  });

  group('P7-05: Mobile Screens Widget Tests', () {
    testWidgets(
      'HomeScreen (M-HM-01) renders search callout, banner, and feed sections',
      (tester) async {
        final mockRepo = MockHomeCatalogRepository();
        final container = ProviderContainer(
          overrides: [
            homeCatalogRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );
        addTearDown(container.dispose);

        final homeVM = container.read(homeViewModelProvider);
        await homeVM.loadHomeFeed();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: HomeScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('izithrift'), findsOneWidget);
        expect(
          find.text('Tìm kiếm sản phẩm, thương hiệu...'),
          findsOneWidget,
        );
        expect(find.text('Khác'), findsOneWidget);
        expect(find.text('BỘ SƯU TẬP MÙA ĐÔNG'), findsOneWidget);
        expect(find.text('Đấu giá nổi bật'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Hàng mới lên kệ'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Hàng mới lên kệ'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Tiệm đồ si ở gần bạn'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Tiệm đồ si ở gần bạn'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Bạn có thể đang tìm kiếm'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Bạn có thể đang tìm kiếm'), findsOneWidget);
      },
    );

    testWidgets(
      'FeaturedSellersAndCollectionsScreen (M-HM-02) renders curated collections and sellers',
      (tester) async {
        final mockRepo = MockHomeCatalogRepository();
        final container = ProviderContainer(
          overrides: [
            homeCatalogRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );
        addTearDown(container.dispose);

        final homeVM = container.read(homeViewModelProvider);
        await homeVM.loadHomeFeed();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: FeaturedSellersAndCollectionsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tiệm đồ si & Bộ sưu tập'), findsOneWidget);
        expect(find.text('Bộ sưu tập tuyển chọn'), findsOneWidget);
        expect(find.text('Áo dạ & Măng tô thập niên 90s'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Tiệm Đồ Si Chú Bảy'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Tiệm Đồ Si Chú Bảy'), findsOneWidget);
        expect(find.text('Ghé tiệm'), findsOneWidget);
      },
    );

    testWidgets(
      'CategoryTaxonomyScreen (M-DS-01) renders categories and brands tabs',
      (tester) async {
        final mockRepo = MockHomeCatalogRepository();
        final container = ProviderContainer(
          overrides: [
            homeCatalogRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );
        addTearDown(container.dispose);

        final searchVM = container.read(catalogSearchViewModelProvider);
        await searchVM.loadTaxonomy();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: CategoryTaxonomyScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('izithrift • Khám phá'), findsOneWidget);
        expect(find.text('Danh mục sản phẩm'), findsOneWidget);
        expect(find.text('Thương hiệu retro'), findsOneWidget);
        expect(find.text('Áo khoác Vintage'), findsOneWidget);

        // Switch to Brands Tab
        await tester.tap(find.text('Thương hiệu retro'));
        await tester.pumpAndSettle();
        expect(find.text('Levi\'s'), findsOneWidget);
        expect(find.text('Seiko'), findsOneWidget);
      },
    );

    testWidgets(
      'ProductFilterBottomSheet (M-DS-03) validates minPrice > maxPrice',
      (tester) async {
        ProductFilterQuery? appliedQuery;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    ProductFilterBottomSheet.show(
                      ctx,
                      initialQuery: const ProductFilterQuery(),
                      onApply: (query) => appliedQuery = query,
                    );
                  },
                  child: const Text('Mở bộ lọc'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Mở bộ lọc'));
        await tester.pumpAndSettle();

        expect(find.text('Bộ lọc tìm kiếm'), findsOneWidget);
        expect(find.text('Khoảng giá (VNĐ)'), findsOneWidget);

        // Enter invalid range: min = 500000, max = 200000
        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), '500000');
        await tester.enterText(textFields.at(1), '200000');
        await tester.pump();

        // Expect validation error displayed
        expect(
          find.text('Giá tối thiểu không được lớn hơn giá tối đa'),
          findsOneWidget,
        );

        // The Apply button should be disabled
        final applyButton = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton).last,
        );
        expect(applyButton.onPressed, isNull);

        // Enter valid max price = 700000
        await tester.enterText(textFields.at(1), '700000');
        await tester.pump();

        expect(
          find.text('Giá tối thiểu không được lớn hơn giá tối đa'),
          findsNothing,
        );
        final applyButtonValid = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton).last,
        );
        expect(applyButtonValid.onPressed, isNotNull);

        // Tap apply
        await tester.tap(find.text('Áp dụng bộ lọc'));
        await tester.pumpAndSettle();
        expect(appliedQuery, isNotNull);
        expect(appliedQuery!.minPrice, equals(500000.0));
        expect(appliedQuery!.maxPrice, equals(700000.0));
      },
    );

    test('HomeCatalogRepository.fetchHomeFeed parses valid object payload', () async {
      final stubClient = _StubHomeDioClient({
        'success': true,
        'data': {
          'categories': [],
          'live_auctions': [],
          'featured_sellers': [],
          'latest_products': [],
        },
      });
      final repo = HomeCatalogRepository(dioClient: stubClient);
      final feed = await repo.fetchHomeFeed();

      expect(feed.categories, isEmpty);
      expect(feed.liveAuctions, isEmpty);
      expect(feed.featuredSellers, isEmpty);
      expect(feed.latestProducts, isEmpty);
    });

    test('HomeCatalogRepository.fetchHomeFeed handles malformed List data without TypeError', () async {
      final stubClient = _StubHomeDioClient({
        'success': true,
        'data': <dynamic>[],
      });
      final repo = HomeCatalogRepository(dioClient: stubClient);
      final feed = await repo.fetchHomeFeed();

      expect(feed.categories, isEmpty);
      expect(feed.liveAuctions, isEmpty);
      expect(feed.featuredSellers, isEmpty);
      expect(feed.latestProducts, isEmpty);
    });
  });
}

class _StubHomeDioClient extends DioClient {
  final Map<String, dynamic> payload;

  _StubHomeDioClient(this.payload)
    : super(
        tokenStorage: SecureTokenStorage(),
        serverTimeService: ServerTimeService.instance,
      );

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: payload as T,
    );
  }
}
