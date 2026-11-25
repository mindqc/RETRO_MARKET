import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/main_navigation_shell.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_reset_password_screen.dart';
import '../../features/profile/screens/unified_personal_hub_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/address_list_screen.dart';
import '../../features/profile/screens/add_edit_address_screen.dart';
import '../../features/profile/screens/app_settings_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/featured_sellers_and_collections_screen.dart';
import '../../features/catalog/screens/category_taxonomy_screen.dart';
import '../../features/catalog/screens/product_search_screen.dart';
import '../../features/catalog/screens/product_detail_screen.dart';
import '../../features/catalog/screens/public_seller_storefront_screen.dart';
import '../../features/seller/screens/seller_hub_screen.dart';
import '../../features/seller/screens/seller_listings_screen.dart';
import '../../features/seller/screens/create_listing_screen.dart';
import '../../features/seller/screens/edit_resubmit_listing_screen.dart';
import '../../features/seller/screens/seller_wallet_ledger_screen.dart';
import '../../features/seller/models/seller_product_item_model.dart';
import '../../features/cart/screens/shopping_cart_screen.dart';
import '../../features/cart/screens/checkout_screen.dart';
import '../../features/cart/screens/mock_qr_payment_screen.dart';
import '../../features/cart/screens/payment_success_screen.dart';
import '../../features/cart/screens/payment_failure_screen.dart';
import '../../features/cart/models/payment_session_model.dart';
import '../../features/orders/models/order_model.dart';
import '../../features/orders/models/dispute_model.dart';
import '../../features/orders/screens/my_purchases_screen.dart';
import '../../features/orders/screens/purchase_order_detail_screen.dart';
import '../../features/orders/screens/shipment_tracking_screen.dart';
import '../../features/orders/screens/seller_orders_screen.dart';
import '../../features/orders/screens/seller_order_detail_screen.dart';
import '../../features/orders/screens/open_dispute_screen.dart';
import '../../features/orders/screens/dispute_detail_screen.dart';
import '../../features/orders/screens/submit_counter_evidence_screen.dart';
import '../../features/auctions/screens/scheduled_auction_hub_screen.dart';
import '../../features/auctions/screens/my_auctions_screen.dart';
import '../../features/auctions/screens/live_bidding_room_screen.dart';
import '../../features/engagement/screens/conversation_inbox_screen.dart';
import '../../features/engagement/screens/chat_room_screen.dart';
import '../../features/engagement/screens/notification_center_screen.dart';
import '../../features/engagement/screens/saved_favorites_and_shops_screen.dart';
import '../../features/engagement/screens/submit_verified_review_screen.dart';
import '../../features/engagement/screens/seller_reviews_list_screen.dart';
import 'app_routes.dart';

/// Centralized Routing for RETRO MARKET (izithrift) using GoRouter.
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'rootNav');

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: false,
    routes: [
      // Standalone Auth & Onboarding Routes
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotResetPasswordScreen(),
      ),

      // Profile Sub-screens
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.addresses,
        builder: (context, state) => const AddressListScreen(),
      ),
      GoRoute(
        path: AppRoutes.addAddress,
        builder: (context, state) => const AddEditAddressScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const AppSettingsScreen(),
      ),

      // Catalog & Discovery Standalone Routes
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) =>
            ProductSearchScreen(initialKeyword: state.uri.queryParameters['q']),
      ),
      GoRoute(
        path: AppRoutes.featuredSellers,
        builder: (context, state) =>
            const FeaturedSellersAndCollectionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.sellerStorefront,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return PublicSellerStorefrontScreen(sellerId: id);
        },
      ),

      // Seller Channel Routes (NAV-DEC-02)
      GoRoute(
        path: AppRoutes.sellerHub,
        builder: (context, state) => const SellerHubScreen(),
      ),
      GoRoute(
        path: AppRoutes.sellerListings,
        builder: (context, state) => const SellerListingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.sellerCreateListing,
        builder: (context, state) => const CreateListingScreen(),
      ),
      GoRoute(
        path: AppRoutes.sellerEditListing,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          final product = state.extra is SellerProductItemModel
              ? state.extra as SellerProductItemModel
              : null;
          return EditResubmitListingScreen(
            productId: id,
            initialProduct: product,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.sellerWallet,
        builder: (context, state) => const SellerWalletLedgerScreen(),
      ),

      // Cart & Checkout Routes (M-CR-01, M-OR-01, M-PM-01..03)
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const ShoppingCartScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) {
          final extraMap = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : <String, dynamic>{};

          final queryParams = state.uri.queryParameters;

          // Extra takes priority; query parameters are fallback.
          final source =
              extraMap['source']?.toString() ?? queryParams['source'] ?? 'CART';

          final rawCartItemIds = extraMap['cartItemIds'];

          final cartItemIds = rawCartItemIds is List<int>
              ? rawCartItemIds
              : (rawCartItemIds is List
                    ? rawCartItemIds
                          .map((e) => int.tryParse(e.toString()) ?? 0)
                          .toList()
                    : null);

          final productId = int.tryParse(
            extraMap['productId']?.toString() ?? queryParams['productId'] ?? '',
          );

          final quantity = int.tryParse(
            extraMap['quantity']?.toString() ?? queryParams['quantity'] ?? '',
          );

          return CheckoutScreen(
            source: source,
            cartItemIds: cartItemIds,
            productId: productId,
            quantity: quantity,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.paymentQr,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          final session = state.extra is PaymentSessionModel
              ? state.extra as PaymentSessionModel
              : null;
          return MockQrPaymentScreen(paymentId: id, initialSession: session);
        },
      ),
      GoRoute(
        path: AppRoutes.paymentSuccess,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          final session = state.extra is PaymentSessionModel
              ? state.extra as PaymentSessionModel
              : null;
          return PaymentSuccessScreen(paymentId: id, session: session);
        },
      ),
      GoRoute(
        path: AppRoutes.paymentFailure,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          final session = state.extra is PaymentSessionModel
              ? state.extra as PaymentSessionModel
              : null;
          return PaymentFailureScreen(paymentId: id, session: session);
        },
      ),

      // Buyer Orders & Fulfillment (M-OR-02..05)
      GoRoute(
        path: AppRoutes.myPurchases,
        builder: (context, state) => MyPurchasesScreen(
          initialTab: state.uri.queryParameters['tab'] ?? 'ALL',
        ),
      ),
      GoRoute(
        path: AppRoutes.orderDetail,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          final order = state.extra is OrderModel
              ? state.extra as OrderModel
              : null;
          return PurchaseOrderDetailScreen(orderId: id, initialOrder: order);
        },
      ),
      GoRoute(
        path: AppRoutes.shipmentTracking,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          final order = state.extra is OrderModel
              ? state.extra as OrderModel
              : null;
          return ShipmentTrackingScreen(orderId: id, initialOrder: order);
        },
      ),

      // Seller Orders Management (M-SL-05..06)
      GoRoute(
        path: AppRoutes.sellerOrders,
        builder: (context, state) => SellerOrdersScreen(
          initialTab: state.uri.queryParameters['tab'] ?? 'ALL',
        ),
      ),
      GoRoute(
        path: AppRoutes.sellerOrderDetail,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          final order = state.extra is OrderModel
              ? state.extra as OrderModel
              : null;
          return SellerOrderDetailScreen(orderId: id, initialOrder: order);
        },
      ),

      // Disputes & Resolution (M-DP-01..03)
      GoRoute(
        path: AppRoutes.openDispute,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return OpenDisputeScreen(orderId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.disputeDetail,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          final dispute = state.extra is DisputeModel
              ? state.extra as DisputeModel
              : null;
          return DisputeDetailScreen(disputeId: id, initialDispute: dispute);
        },
      ),
      GoRoute(
        path: AppRoutes.submitCounterEvidence,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return SubmitCounterEvidenceScreen(disputeId: id);
        },
      ),

      // Auction Room & Activities (M-AC-02, M-AC-03)
      GoRoute(
        path: AppRoutes.myAuctions,
        builder: (context, state) => const MyAuctionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.auctionRoom,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return LiveBiddingRoomScreen(auctionId: id);
        },
      ),

      // Engagement & Chat Standalone Routes (M-CM-02, M-NT-01, M-PF-05, M-RV-01..02)
      GoRoute(
        path: AppRoutes.chatRoom,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return ChatRoomScreen(conversationId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        builder: (context, state) => const SavedFavoritesAndShopsScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderReview,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          final code = state.uri.queryParameters['code'];
          return SubmitVerifiedReviewScreen(orderId: id, orderCode: code);
        },
      ),
      GoRoute(
        path: AppRoutes.sellerReviews,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return SellerReviewsListScreen(sellerId: id);
        },
      ),

      // Notification Deep-Link Route Aliases (P9-01)
      GoRoute(
        path: AppRoutes.buyerOrderAlias,
        redirect: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return state.uri.replace(path: '/orders/$id').toString();
        },
      ),
      GoRoute(
        path: AppRoutes.buyerDisputeAlias,
        redirect: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return state.uri.replace(path: '/disputes/$id').toString();
        },
      ),
      GoRoute(
        path: AppRoutes.sellerDisputeAlias,
        redirect: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return state.uri.replace(path: '/disputes/$id').toString();
        },
      ),
      GoRoute(
        path: AppRoutes.sellerProductAlias,
        redirect: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return state.uri
              .replace(path: '/seller/listings/$id/edit')
              .toString();
        },
      ),

      // 5-Tab Bottom Navigation Shell (NAV-DEC-01)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Home (Trang chủ - M-HM-01)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Branch 2: Discover (Khám phá - M-DS-01)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.discover,
                builder: (context, state) => const CategoryTaxonomyScreen(),
              ),
            ],
          ),

          // Branch 3: Auctions (Đấu giá - M-AC-01)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.auctions,
                builder: (context, state) => const ScheduledAuctionHubScreen(),
              ),
            ],
          ),

          // Branch 4: Messages (Tin nhắn - M-CM-01)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.messages,
                builder: (context, state) => const ConversationInboxScreen(),
              ),
            ],
          ),

          // Branch 5: Profile (Cá nhân & Kênh người bán - M-PF-01)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const UnifiedPersonalHubScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
