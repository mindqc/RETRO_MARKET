/// Named routes and paths for RETRO MARKET (izithrift)
class AppRoutes {
  AppRoutes._();

  // Root 5 Tabs (NAV-DEC-01)
  static const String home = '/home';
  static const String discover = '/discover';
  static const String auctions = '/auctions';
  static const String messages = '/messages';
  static const String profile = '/profile';

  // Auth & Onboarding
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Catalog, Search & Product Details
  static const String featuredSellers = '/home/featured';
  static const String search = '/search';
  static const String productDetail = '/products/:id';
  static String productDetailPath(int id) => '/products/$id';
  static const String sellerStorefront = '/sellers/:id';
  static String sellerStorefrontPath(int id) => '/sellers/$id';
  static const String sellerReviews = '/sellers/:id/reviews';
  static String sellerReviewsPath(int id) => '/sellers/$id/reviews';

  // Cart & Checkout
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String paymentQr = '/payments/:id';
  static String paymentQrPath(int id) => '/payments/$id';
  static const String paymentSuccess = '/payments/:id/success';
  static String paymentSuccessPath(int id) => '/payments/$id/success';
  static const String paymentFailure = '/payments/:id/failure';
  static String paymentFailurePath(int id) => '/payments/$id/failure';

  // Buyer Orders & Fulfillment (M-OR-02..05)
  static const String myOrders = '/orders/purchases';
  static const String myPurchases = '/orders/purchases';
  static String myPurchasesPath([String? tab]) => tab != null ? '/orders/purchases?tab=$tab' : '/orders/purchases';
  static const String orderDetail = '/orders/:id';
  static String orderDetailPath(int id) => '/orders/$id';
  static const String shipmentTracking = '/orders/:id/tracking';
  static String shipmentTrackingPath(int id) => '/orders/$id/tracking';
  static const String orderReview = '/orders/:id/review';
  static String orderReviewPath(int id) => '/orders/$id/review';

  // Disputes & Resolution (M-DP-01..03)
  static const String openDispute = '/orders/:id/dispute/create';
  static String openDisputePath(int id) => '/orders/$id/dispute/create';
  static const String disputeDetail = '/disputes/:id';
  static String disputeDetailPath(int id) => '/disputes/$id';
  static const String submitCounterEvidence = '/disputes/:id/evidence';
  static String submitCounterEvidencePath(int id) => '/disputes/$id/evidence';

  // Auction Room
  static const String myAuctions = '/auctions/mine';
  static const String auctionRoom = '/auctions/:id';
  static String auctionRoomPath(int id) => '/auctions/$id';

  // Chat & Communication
  static const String chatRoom = '/messages/:id';
  static String chatRoomPath(int id) => '/messages/$id';
  static const String notifications = '/notifications';

  // Seller Channel (NAV-DEC-02)
  static const String sellerHub = '/seller';
  static const String sellerListings = '/seller/listings';
  static const String sellerCreateListing = '/seller/create';
  static const String sellerEditListing = '/seller/listings/:id/edit';
  static String sellerEditListingPath(int id) => '/seller/listings/$id/edit';
  static const String sellerOrders = '/seller/orders';
  static const String sellerOrderDetail = '/seller/orders/:id';
  static String sellerOrderDetailPath(int id) => '/seller/orders/$id';
  static const String sellerWallet = '/seller/wallet';

  // Notification Deep-Link Route Aliases (P9-01)
  static const String buyerOrderAlias = '/buyer/orders/:id';
  static const String buyerDisputeAlias = '/buyer/disputes/:id';
  static const String sellerDisputeAlias = '/seller/disputes/:id';
  static const String sellerProductAlias = '/seller/products/:id';

  // Profile Sub-screens
  static const String editProfile = '/profile/edit';
  static const String addresses = '/profile/addresses';
  static const String addAddress = '/profile/addresses/new';
  static const String favorites = '/profile/favorites';
  static const String settings = '/profile/settings';
}
