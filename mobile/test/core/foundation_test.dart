import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izithrift/app.dart';
import 'package:izithrift/core/config/env_config.dart';
import 'package:izithrift/core/constants/api_endpoints.dart';
import 'package:izithrift/core/network/dio_client.dart';
import 'package:izithrift/core/services/secure_token_storage.dart';
import 'package:izithrift/core/theme/seasonal_decor_provider.dart';
import 'package:izithrift/core/utils/safe_json_parser.dart';
import 'package:izithrift/core/utils/vnd_formatter.dart';
import 'package:izithrift/features/auth/models/user_model.dart';
import 'package:izithrift/features/auth/repositories/auth_repository.dart';
import 'package:izithrift/features/auth/viewmodels/auth_view_model.dart';
import 'package:izithrift/features/profile/models/profile_summary_model.dart';
import 'package:izithrift/features/profile/repositories/profile_repository.dart';

class _TestProfileRepository extends ProfileRepository {
  _TestProfileRepository(SecureTokenStorage storage, this.user)
      : super(dioClient: DioClient(tokenStorage: storage));

  final UserModel user;

  @override
  Future<ProfileSummaryModel> fetchMyProfile() async {
    return ProfileSummaryModel(user: user);
  }
}

void main() {
  group('P7-01: Foundation Core Utils & Config Tests', () {
    test('EnvConfig and ApiEndpoints definitions', () {
      expect(EnvConfig.appName, equals('izithrift'));
      expect(EnvConfig.projectCodename, equals('RETRO MARKET'));
      expect(EnvConfig.apiBaseUrl, isNotEmpty);

      expect(ApiEndpoints.bootstrap, equals('/bootstrap'));
      expect(ApiEndpoints.login, equals('/auth/login'));
      expect(ApiEndpoints.home, equals('/home'));
      expect(ApiEndpoints.productDetail(42), equals('/products/42'));
      expect(ApiEndpoints.sellerDetail(10), equals('/sellers/10'));
      expect(ApiEndpoints.orderDetail(100), equals('/orders/100'));
      expect(ApiEndpoints.auctionDetail(5), equals('/auctions/5'));
    });

    test('SafeJsonParser.toDouble converts various Laravel serialized formats', () {
      // String from PostgreSQL NUMERIC(15,2)
      expect(SafeJsonParser.toDouble('431000.00'), equals(431000.0));
      expect(SafeJsonParser.toDouble('0.0600'), equals(0.06));
      expect(SafeJsonParser.toDouble(' 350000.50 '), equals(350000.5));

      // Int and double
      expect(SafeJsonParser.toDouble(7000), equals(7000.0));
      expect(SafeJsonParser.toDouble(400000.5), equals(400000.5));

      // Null and invalid strings
      expect(SafeJsonParser.toDouble(null), equals(0.0));
      expect(SafeJsonParser.toDouble(null, defaultValue: 10.0), equals(10.0));
      expect(SafeJsonParser.toDouble('invalid_number'), equals(0.0));
      expect(SafeJsonParser.toDouble('', defaultValue: -1.0), equals(-1.0));
    });

    test('SafeJsonParser.toInt, toBool and toDateTime parse safely', () {
      // toInt
      expect(SafeJsonParser.toInt('12'), equals(12));
      expect(SafeJsonParser.toInt(12), equals(12));
      expect(SafeJsonParser.toInt(12.8), equals(12));
      expect(SafeJsonParser.toInt('12.5'), equals(12));
      expect(SafeJsonParser.toInt(null), equals(0));

      // toBool
      expect(SafeJsonParser.toBool(true), isTrue);
      expect(SafeJsonParser.toBool(false), isFalse);
      expect(SafeJsonParser.toBool(1), isTrue);
      expect(SafeJsonParser.toBool(0), isFalse);
      expect(SafeJsonParser.toBool('true'), isTrue);
      expect(SafeJsonParser.toBool('1'), isTrue);
      expect(SafeJsonParser.toBool('false'), isFalse);
      expect(SafeJsonParser.toBool('0'), isFalse);
      expect(SafeJsonParser.toBool(null), isFalse);

      // toDateTime
      final dt = SafeJsonParser.toDateTime('2026-11-14T18:25:26+07:00');
      expect(dt, isNotNull);
      expect(dt!.year, equals(2026));
      expect(dt.month, equals(11));
      expect(dt.day, equals(14));
      expect(SafeJsonParser.toDateTime(null), isNull);
      expect(SafeJsonParser.toDateTime('not-a-date'), isNull);
    });

    test('VndFormatter formats currency accurately according to Vietnamese conventions', () {
      expect(VndFormatter.format(431000), equals('431.000đ'));
      expect(VndFormatter.format(1067000.0), equals('1.067.000đ'));
      expect(VndFormatter.format(0), equals('0đ'));
      expect(VndFormatter.format(null), equals('0đ'));

      // Compact format
      expect(VndFormatter.formatCompact(850000), equals('850k'));
      expect(VndFormatter.formatCompact(1200000), equals('1,2tr'));
      expect(VndFormatter.formatCompact(45000000), equals('45tr'));
      expect(VndFormatter.formatCompact(2500000000), equals('2,5tỷ'));
    });
  });

  group('P7-01: 5-Tab Navigation Shell & App Smoke Test', () {
    testWidgets('Renders all 5 Navigation Tabs and switches branches smoothly', (tester) async {
      final tokenStorage = SecureTokenStorage.inMemory();
      await tokenStorage.saveTokens(
        accessToken: 'test_token',
        userId: 1,
        role: 'buyer_seller',
        email: 'test@izithrift.vn',
      );
      const testUser = UserModel(
        id: 1,
        displayName: 'Tiệm Đồ Cũ Test',
        email: 'test@izithrift.vn',
        role: 'buyer_seller',
        status: 'ACTIVE',
        profile: UserProfileModel(seasonalDecorEnabled: true),
        sellerProfile: SellerProfileModel(
          shopSlug: 'tiem-do-cu-test',
          trustScore: 98.0,
          walletBalance: 1250000.0,
          escrowHeldBalance: 500000.0,
        ),
      );
      final testProfileRepo = _TestProfileRepository(tokenStorage, testUser);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureTokenStorageProvider.overrideWithValue(tokenStorage),
            seasonalDecorProvider.overrideWith(
              (ref) => SeasonalDecorNotifier(null, true),
            ),
            profileRepositoryProvider.overrideWithValue(testProfileRepo),
            authViewModelProvider.overrideWith((ref) {
              final vm = AuthViewModel(
                authRepository: ref.watch(authRepositoryProvider),
                profileRepository: testProfileRepo,
                tokenStorage: tokenStorage,
                seasonalDecorNotifier: ref.watch(seasonalDecorProvider.notifier),
              );
              vm.updateCurrentUser(testUser);
              return vm;
            }),
          ],
          child: const IzithriftApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Check App starts at Tab 1: Trang chủ with unified izithrift Global AppBar
      expect(find.text('Trang chủ'), findsWidgets);
      expect(find.text('izithrift'), findsWidgets);

      // Check all 5 Bottom Navigation destinations exist
      expect(find.text('Tin nhắn'), findsOneWidget);
      expect(find.text('Đăng bán'), findsOneWidget);
      expect(find.text('Đấu giá'), findsOneWidget);
      expect(find.text('Cá nhân'), findsOneWidget);

      // Switch to Tab 2: Tin nhắn
      await tester.tap(find.text('Tin nhắn').last);
      await tester.pumpAndSettle();
      expect(find.text('izithrift'), findsWidgets);
      expect(find.text('Tin nhắn'), findsWidgets);

      // Tap central Đăng bán CTA to verify Sell Bottom Sheet opens cleanly
      await tester.tap(find.text('Đăng bán').last);
      await tester.pumpAndSettle();
      expect(find.text('Đăng bán sản phẩm'), findsOneWidget);
      expect(find.text('Tạo phiên đấu giá'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Switch to Tab 4: Đấu giá
      await tester.tap(find.text('Đấu giá').last);
      await tester.pumpAndSettle();
      expect(find.text('izithrift'), findsWidgets);
      expect(find.text('Săn món đồ độc đáo với mức giá của bạn.'), findsOneWidget);

      // Switch to Tab 5: Cá nhân
      await tester.tap(find.text('Cá nhân').last);
      await tester.pumpAndSettle();
      expect(find.text('izithrift'), findsWidgets);
      expect(find.text('Tiệm Đồ Cũ Test'), findsOneWidget);
      expect(find.text('Kênh Người bán izithrift'), findsOneWidget);

      // Switch back to Tab 1: Trang chủ
      await tester.tap(find.text('Trang chủ').last);
      await tester.pumpAndSettle();
      expect(find.text('izithrift'), findsWidgets);
    });
  });
}
