import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:izithrift/core/theme/app_colors.dart';
import 'package:izithrift/core/theme/design_tokens.dart';
import 'package:izithrift/core/theme/app_typography.dart';
import 'package:izithrift/core/theme/seasonal_decor_provider.dart';
import 'package:izithrift/core/utils/product_image_resolver.dart';
import 'package:izithrift/core/widgets/condition_badge.dart';
import 'package:izithrift/core/widgets/fashion_category_icon.dart';
import 'package:izithrift/core/widgets/izithrift_global_app_bar.dart';
import 'package:izithrift/core/widgets/izithrift_logo.dart';
import 'package:izithrift/core/widgets/retro_product_card.dart';
import 'package:izithrift/core/widgets/verification_badge.dart';
import 'package:izithrift/core/widgets/status_pill_badge.dart';
import 'package:izithrift/core/widgets/price_breakdown_card.dart';
import 'package:izithrift/core/widgets/server_countdown_timer.dart';
import 'package:izithrift/core/widgets/defect_authenticity_box.dart';
import 'package:izithrift/core/widgets/seasonal_decor_overlay.dart';
import 'package:izithrift/features/catalog/models/product_summary_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P7-02: Design System Tokens & Typography Tests', () {
    test('test_design_tokens_and_colors_match_spec', () {
      // 1. Verify Warm Thrift Palette tokens
      expect(AppColors.warmIvory, const Color(0xFFFBF8F3));
      expect(AppColors.primaryTerracotta, const Color(0xFFC85A32));
      expect(AppColors.secondaryPineGreen, const Color(0xFF2D5A3C));
      expect(AppColors.accentVintageGold, const Color(0xFFD4AF37));
      expect(AppColors.christmasBerryRed, const Color(0xFFB22222));
      expect(AppColors.textCharcoal, const Color(0xFF231F20));

      // 2. Verify Spacing & Radius tokens
      expect(DesignTokens.spaceXs, 4.0);
      expect(DesignTokens.spaceSm, 8.0);
      expect(DesignTokens.spaceMd, 12.0);
      expect(DesignTokens.spaceLg, 16.0);
      expect(DesignTokens.radiusSm, 8.0);
      expect(DesignTokens.radiusMd, 12.0);
      expect(DesignTokens.radiusFull, 999.0);

      // 3. Verify Tabular Figures in Prices & Timers
      expect(AppTypography.priceLarge.fontFeatures, isNotNull);
      expect(AppTypography.countdownTimer.fontFeatures, isNotNull);
    });
  });

  group('P7-02: Shared Badges & Defect Box Tests', () {
    testWidgets('test_condition_badge_renders_correct_vietnamese_labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ConditionBadge(condition: 'LIKE_NEW'),
                ConditionBadge(condition: 'GOOD'),
                ConditionBadge(condition: 'VINTAGE_WORN'),
                ConditionBadge(condition: 'NEW_WITH_TAGS'),
                ConditionBadge(condition: 'FAIR'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Như mới (99%)'), findsOneWidget);
      expect(find.text('Tốt (90%)'), findsOneWidget);
      expect(find.text('Dấu ấn vintage'), findsOneWidget);
      expect(find.text('Mới còn tag'), findsOneWidget);
      expect(find.text('Khá (80%)'), findsOneWidget);
    });

    testWidgets('test_verification_badge_renders_security_levels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                VerificationBadge(status: 'HIGH_VALUE_VERIFIED'),
                VerificationBadge(status: 'MODERATOR_REVIEWED'),
                VerificationBadge(status: 'BASIC_CHECKED'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Xác minh giá trị cao'), findsOneWidget);
      expect(find.text('Đã kiểm duyệt'), findsOneWidget);
      expect(find.text('Có chứng từ gốc'), findsOneWidget);
      expect(find.byIcon(Icons.verified_user), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('test_status_pill_badge_renders_expected_states', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusPillBadge(status: 'APPROVED'),
                StatusPillBadge(status: 'LIVE'),
                StatusPillBadge(status: 'COMPLETED'),
                StatusPillBadge(status: 'DISPUTED'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Đã duyệt'), findsOneWidget);
      expect(find.text('Đang đấu giá'), findsOneWidget);
      expect(find.text('Đã hoàn thành'), findsOneWidget);
      expect(find.text('Đang khiếu nại'), findsOneWidget);
    });

    testWidgets('test_defect_authenticity_box_renders_defect_and_rejection', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DefectAuthenticityBox(
              defectInfo: 'Vết xước nhẹ ở viền khóa đồng',
              rejectionReason: 'Ảnh chụp mờ, thiếu góc chụp nhãn hiệu',
            ),
          ),
        ),
      );

      expect(find.text('Lưu ý khuyết tật & hao mòn vintage (BR-PR-03)'), findsOneWidget);
      expect(find.text('Vết xước nhẹ ở viền khóa đồng'), findsOneWidget);
      expect(find.text('Lý do từ chối duyệt (DEC-05)'), findsOneWidget);
      expect(find.text('Ảnh chụp mờ, thiếu góc chụp nhãn hiệu'), findsOneWidget);
    });
  });

  group('P7-02: DEC-04 Financial Breakdown & Escrow Card Tests', () {
    testWidgets('test_price_breakdown_card_applies_dec_04_buyer_protection_fee', (tester) async {
      // 500.000 * 6% + 7.000 = 30.000 + 7.000 = 37.000đ
      // Total = 500.000 + 0 + 37.000 = 537.000đ
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PriceBreakdownCard(
                itemSubtotal: 500000,
                shippingFee: 0,
                showSellerNetAmount: true,
              ),
            ),
          ),
        ),
      );

      // Verify subtotal
      expect(find.text('500.000đ'), findsWidgets); // Tiền hàng & Thực nhận của người bán
      // Verify shipping free
      expect(find.text('Miễn phí'), findsOneWidget);
      // Verify DEC-04 fee
      expect(find.text('37.000đ'), findsOneWidget);
      // Verify total
      expect(find.text('537.000đ'), findsOneWidget);
      // Verify Escrow notice
      expect(find.textContaining('Tiền thanh toán được giữ trung gian tại Escrow'), findsOneWidget);
      // Verify seller net amount row
      expect(find.text('Thực nhận của người bán'), findsOneWidget);
    });
  });

  group('P7-02: Server Countdown Timer & Anti-Sniping Tests', () {
    testWidgets('test_server_countdown_timer_ticks_and_triggers_warning_under_120s', (tester) async {
      bool expiredCalled = false;
      final now = DateTime(2026, 12, 25, 12, 0, 0);

      // 1. Target time 90s in future (< 120s) -> should show warning icon & anti-sniping color
      final target90s = now.add(const Duration(seconds: 90));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServerCountdownTimer(
              endsAt: target90s,
              customClock: () => now,
              extendedCount: 2,
              onExpired: () => expiredCalled = true,
            ),
          ),
        ),
      );

      // Verify formatted time: 00:01:30
      expect(find.text('00:01:30'), findsOneWidget);
      // Verify anti-sniping timer warning icon
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      // Verify extended count badge
      expect(find.text('+2'), findsOneWidget);

      // 2. Target time in past -> triggers onExpired callback
      final pastTarget = now.subtract(const Duration(seconds: 10));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServerCountdownTimer(
              endsAt: pastTarget,
              customClock: () => now,
              onExpired: () => expiredCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('00:00:00'), findsOneWidget);
      expect(expiredCalled, isTrue);
    });
  });

  group('P7-02: Seasonal Holiday Decor Overlay Tests', () {
    testWidgets('test_seasonal_decor_overlay_toggle_and_persistence', (tester) async {
      final container = ProviderContainer(
        overrides: [
          seasonalDecorProvider.overrideWith((ref) => SeasonalDecorNotifier(null, true)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SeasonalDecorOverlay(
              child: Scaffold(
                body: Text('Trang chủ Retro Market'),
              ),
            ),
          ),
        ),
      );

      // 1. Decor enabled by default
      expect(find.byKey(const Key('seasonal_decor_overlay_active')), findsOneWidget);
      expect(find.text('Trang chủ Retro Market'), findsOneWidget);

      // 2. Toggle off decor
      container.read(seasonalDecorProvider.notifier).setEnabled(false);
      await tester.pumpAndSettle();

      // Overlay container should no longer be rendered
      expect(find.byKey(const Key('seasonal_decor_overlay_active')), findsNothing);
      expect(find.text('Trang chủ Retro Market'), findsOneWidget);
    });
  });

  group('Batch 2: Shared Logo, Upper Navigation, Fashion Icons & Compact Card Tests', () {
    testWidgets('IzithriftLogo renders horizontal, iconOnly, and stacked variants', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                IzithriftLogo(),
                IzithriftLogo.iconOnly(iconSize: 32),
                IzithriftLogo.stacked(
                  iconSize: 64,
                  fontSize: 28,
                  tagline: 'Kho đồ secondhand & vintage tuyển chọn',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('izithrift'), findsNWidgets(2));
      expect(find.text('Kho đồ secondhand & vintage tuyển chọn'), findsOneWidget);
    });

    testWidgets('IzithriftGlobalAppBar keeps unified height and shows only izithrift logo when showBrandMark is true', (tester) async {
      const rootBar = IzithriftGlobalAppBar(
        activeDestination: IzithriftUpperNavDestination.home,
      );
      const subBar = IzithriftGlobalAppBar.subPage(
        title: 'Danh mục sản phẩm',
        showBrandMark: true,
        activeDestination: IzithriftUpperNavDestination.discover,
      );

      expect(rootBar.preferredSize.height, subBar.preferredSize.height);
      expect(IzithriftGlobalAppBar.toolbarHeight, 58.0);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              appBar: subBar,
              body: SizedBox.shrink(),
            ),
          ),
        ),
      );

      expect(find.text('izithrift'), findsOneWidget);
      expect(find.text('Danh mục sản phẩm'), findsNothing);
      expect(find.byTooltip('Quay lại'), findsOneWidget);
      expect(find.byTooltip('Thông báo'), findsOneWidget);
      expect(find.byTooltip('Giỏ hàng'), findsOneWidget);
    });

    testWidgets('FashionCategoryIcon renders all 12 secondhand fashion glyphs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Wrap(
              children: FashionCategoryGlyph.values
                  .map(
                    (g) => FashionCategoryIcon(
                      glyph: g,
                      color: AppColors.pineDeep,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      );

      expect(
        find.byType(FashionCategoryIcon),
        findsNWidgets(FashionCategoryGlyph.values.length),
      );
    });

    testWidgets('Compact RetroProductCard removes photo corner freshness badge and groups distance, freshness, and Uy tín in one row', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 170,
                height: 238,
                child: RetroProductCard(
                  id: 101,
                  title: 'Áo Khoác Denim Levi\'s 90s Vintage',
                  price: 450000,
                  condition: 'LIKE_NEW',
                  categoryName: 'Denim Jacket',
                  distanceLabel: '1.2 km',
                  showConditionPercent: true,
                  sellerName: 'Tiệm Đồ Si Sài Gòn',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('1.2 km'), findsOneWidget);
      expect(find.text('Độ mới: 95%'), findsOneWidget);
      expect(find.byType(ConditionBadge), findsNothing);
      expect(find.text('Tiệm Đồ Si Sài Gòn'), findsOneWidget);
      expect(find.text('Uy tín'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    });

    test('ProductSummaryModel parses primary_image/images.first, prefers shop_name, and avoids raw technical codes', () {
      final fromImagesList = ProductSummaryModel.fromJson({
        'id': 42,
        'product_code': 'PRD-2026-0042',
        'title': 'Áo Sơ Mi Flannel Nhật 90s',
        'slug': 'ao-so-mi-flannel-nhat-90s',
        'listing_type': 'FIXED_PRICE',
        'condition': 'LIKE_NEW',
        'price': 320000,
        'status': 'APPROVED',
        'primary_image': null,
        'images': [
          {'image_url': 'https://cdn.example.org/p42-secondary.jpg', 'is_primary': false},
          {'image_url': 'https://cdn.example.org/p42-primary.jpg', 'is_primary': true},
        ],
        'seller': {
          'id': 7,
          'display_name': 'Nguyễn Văn A',
          'seller_profile': {
            'shop_name': 'Tiệm Flannel Đà Lạt',
            'shop_slug': 'tiem-flannel-da-lat',
          },
        },
        'category': {'id': 5, 'name': 'Vintage Shirt'},
      });

      expect(fromImagesList.primaryImageUrl, 'https://cdn.example.org/p42-primary.jpg');
      expect(fromImagesList.displayTitle, 'Áo Sơ Mi Flannel Nhật 90s');
      expect(fromImagesList.displaySellerName, 'Tiệm Flannel Đà Lạt');

      final technicalFallback = ProductSummaryModel.fromJson({
        'id': 43,
        'product_code': 'PRD-D95A1879',
        'title': 'prd_d95a1879',
        'slug': 'prd_d95a1879',
        'listing_type': 'FIXED_PRICE',
        'condition': 'GOOD',
        'price': 210000,
        'status': 'APPROVED',
        'primary_image': {'image_url': '/storage/products/item43.jpg'},
        'seller': {
          'id': 9,
          'display_name': 'seller_99a1b2',
          'shop_slug': 'seller_99a1b2',
        },
        'category': {'id': 2, 'name': 'Áo khoác Vintage'},
      });

      expect(technicalFallback.displayTitle, 'Đồ si Áo khoác Vintage');
      expect(technicalFallback.displaySellerName, 'Tiệm đồ si uy tín');
      expect(
        ProductImageResolver.resolveImage(
          rawUrl: technicalFallback.primaryImageUrl,
          title: technicalFallback.displayTitle,
          id: technicalFallback.id,
        ),
        endsWith('/storage/products/item43.jpg'),
      );
      expect(
        ProductImageResolver.resolveImage(
          rawUrl: 'https://images.unsplash.com/photo-1544441893-675973e31985?w=600',
          title: 'Túi Da Bò Vintage',
          id: 9,
        ),
        'https://images.unsplash.com/photo-1544441893-675973e31985?w=600',
      );
    });
  });
}
