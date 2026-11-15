/// API Endpoint Constants for RETRO MARKET (/api/v1/*)
class ApiEndpoints {
  ApiEndpoints._();

  // Foundation & Health
  static const String health = '/health';
  static const String bootstrap = '/bootstrap';

  // Authentication & Password Management
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // User Profile, Addresses & Settings
  static const String profile = '/profile';
  static const String changePassword = '/profile/password';
  static const String updateSettings = '/profile/settings';
  static const String myFavorites = '/profile/favorites';
  static const String addresses = '/profile/addresses';
  static String addressDetail(int id) => '/profile/addresses/$id';

  // Catalog Discovery & Home
  static const String home = '/home';
  static const String taxonomy = '/catalog/taxonomy';
  static const String products = '/products';
  static String productDetail(int id) => '/products/$id';
  static String toggleFavorite(int id) => '/products/$id/favorite';

  // Sellers & Storefronts
  static String sellerDetail(int id) => '/sellers/$id';
  static String sellerFollow(int id) => '/sellers/$id/follow';
  static String sellerReviews(int id) => '/sellers/$id/reviews';

  // Seller Channel
  static const String sellerDashboard = '/seller/dashboard';
  static const String sellerProducts = '/seller/products';
  static String sellerProductDetail(int id) => '/seller/products/$id';
  static String sellerProductStatus(int id) => '/seller/products/$id/status';
  static String sellerRelist(int id) => '/seller/products/$id/relist';
  static const String sellerOrders = '/seller/orders';
  static String sellerOrderPrepare(int id) => '/seller/orders/$id/prepare';
  static String sellerOrderShip(int id) => '/seller/orders/$id/ship';
  static String sellerOrderDeliver(int id) => '/seller/orders/$id/deliver';
  static String sellerOrderRespondCancel(int id) => '/seller/orders/$id/respond-cancel';
  static const String sellerWallet = '/seller/wallet';

  // Cart & Checkout
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';
  static String cartItemDetail(int id) => '/cart/items/$id';
  static const String checkoutPreview = '/checkout/preview';
  static const String placeOrder = '/orders';

  // Buyer Orders & Payments
  static const String myPurchases = '/orders/purchases';
  static String orderDetail(int id) => '/orders/$id';
  static String cancelOrder(int id) => '/orders/$id/cancel';
  static String withdrawCancelRequest(int id) => '/orders/$id/withdraw-cancel-request';
  static String confirmDelivery(int id) => '/orders/$id/confirm-delivery';
  static String submitReview(int id) => '/orders/$id/reviews';
  static String openDispute(int id) => '/orders/$id/disputes';

  static String paymentDetail(int id) => '/payments/$id';
  static String simulatePaymentSuccess(int id) => '/payments/$id/simulate-success';
  static String simulatePaymentFailure(int id) => '/payments/$id/simulate-failure';

  // Disputes
  static const String disputes = '/disputes';
  static String disputeDetail(int id) => '/disputes/$id';
  static String disputeEvidences(int id) => '/disputes/$id/evidences';
  static String adminResolveDispute(int id) => '/admin/disputes/$id/resolve';

  // Scheduled Auctions
  static const String auctions = '/auctions';
  static const String myAuctions = '/auctions/mine';
  static String auctionDetail(int id) => '/auctions/$id';
  static String auctionBids(int id) => '/auctions/$id/bids';
  static String auctionWatch(int id) => '/auctions/$id/watch';
  static String auctionCloseEarly(int id) => '/auctions/$id/close-early';

  // Communication & Engagement
  static const String conversations = '/conversations';
  static String conversationMessages(int id) => '/conversations/$id/messages';
  static const String notifications = '/notifications';
  static String markNotificationRead(int id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static const String reports = '/reports';

  // Developer Tools
  static const String triggerJobs = '/system/dev-tools/trigger-jobs';
}
