import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:izithrift/core/error/api_exception.dart';
import 'package:izithrift/core/error/error_code_enum.dart';
import 'package:izithrift/core/network/dio_client.dart';
import 'package:izithrift/core/services/secure_token_storage.dart';
import 'package:izithrift/core/theme/seasonal_decor_provider.dart';
import 'package:izithrift/features/auth/models/bootstrap_model.dart';
import 'package:izithrift/features/auth/models/user_model.dart';
import 'package:izithrift/features/auth/repositories/auth_repository.dart';
import 'package:izithrift/features/auth/viewmodels/auth_view_model.dart';
import 'package:izithrift/features/auth/screens/onboarding_screen.dart';
import 'package:izithrift/features/auth/screens/login_screen.dart';
import 'package:izithrift/features/auth/screens/register_screen.dart';
import 'package:izithrift/features/profile/models/profile_summary_model.dart';
import 'package:izithrift/features/profile/models/user_address_model.dart';
import 'package:izithrift/features/profile/repositories/profile_repository.dart';
import 'package:izithrift/features/profile/repositories/address_repository.dart';
import 'package:izithrift/features/profile/viewmodels/profile_view_model.dart';
import 'package:izithrift/features/profile/viewmodels/address_view_model.dart';
import 'package:izithrift/features/profile/screens/unified_personal_hub_screen.dart';
import 'package:izithrift/features/profile/screens/app_settings_screen.dart';

// Mock Repositories for UI Widget and Unit Testing
class MockAuthRepository extends AuthRepository {
  MockAuthRepository(SecureTokenStorage storage)
      : super(dioClient: DioClient(tokenStorage: storage), tokenStorage: storage);

  bool simulateSuspended = false;

  @override
  Future<BootstrapModel> fetchBootstrap() async {
    return const BootstrapModel(
      demoMode: true,
      protectionFeeRate: 0.06,
      protectionFixedFee: 7000.0,
    );
  }

  @override
  Future<UserModel> login({required String email, required String password}) async {
    if (simulateSuspended) {
      throw const ApiException(
        statusCode: 403,
        errorCode: 'ACCOUNT_SUSPENDED',
        errorCodeEnum: ErrorCodeEnum.accountSuspended,
        message: 'Tài khoản của bạn đã bị khóa do vi phạm chính sách cộng đồng.',
      );
    }

    final user = UserModel(
      id: 1,
      displayName: 'Nguyễn Văn Vintage',
      email: email,
      role: 'buyer_seller',
      status: 'ACTIVE',
      profile: const UserProfileModel(seasonalDecorEnabled: true),
      sellerProfile: const SellerProfileModel(shopSlug: 'tiem-vintage-nguyen', trustScore: 98.0),
    );

    await tokenStorage.saveTokens(
      accessToken: 'mock_token',
      userId: 1,
      role: 'buyer_seller',
      email: email,
    );
    return user;
  }

  @override
  Future<UserModel> register({
    required String displayName,
    required String email,
    String? phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    final user = UserModel(
      id: 2,
      displayName: displayName,
      email: email,
      phone: phone,
      role: 'buyer_seller',
      status: 'ACTIVE',
      sellerProfile: const SellerProfileModel(shopSlug: 'tiem-moi-mo', trustScore: 100.0),
    );

    await tokenStorage.saveTokens(
      accessToken: 'mock_reg_token',
      userId: 2,
      role: 'buyer_seller',
      email: email,
    );
    return user;
  }

  @override
  Future<void> logout() async {
    await tokenStorage.clearTokens();
  }
}

class MockProfileRepository extends ProfileRepository {
  MockProfileRepository(SecureTokenStorage storage)
      : super(dioClient: DioClient(tokenStorage: storage));

  @override
  Future<ProfileSummaryModel> fetchMyProfile() async {
    return const ProfileSummaryModel(
      user: UserModel(
        id: 1,
        displayName: 'Tiệm Đồ Cũ Sài Gòn',
        email: 'vintage.saigon@example.com',
        role: 'buyer_seller',
        status: 'ACTIVE',
        profile: UserProfileModel(bio: 'Đồ si tuyển chọn', seasonalDecorEnabled: true),
        sellerProfile: SellerProfileModel(
          shopSlug: 'tiem-do-cu-saigon',
          trustScore: 95.0,
          walletBalance: 1250000,
          escrowHeldBalance: 500000,
        ),
      ),
      orderStatusCounts: {
        'PENDING_PAYMENT': 2,
        'PAID': 1,
        'PREPARING': 1,
        'SHIPPED': 3,
        'DELIVERED': 0,
        'COMPLETED': 10,
        'DISPUTED': 1,
      },
      favoritesCount: 15,
      followingCount: 4,
    );
  }

  @override
  Future<bool> updateSeasonalSetting(bool enabled) async => true;

  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (currentPassword == 'wrong_password') return false;
    return true;
  }
}

class MockAddressRepository extends AddressRepository {
  MockAddressRepository(SecureTokenStorage storage)
      : super(dioClient: DioClient(tokenStorage: storage));

  final List<UserAddressModel> _mockDb = [
    const UserAddressModel(
      id: 1,
      recipientName: 'Trần Văn A',
      recipientPhone: '0901234567',
      provinceCity: 'TP. Hồ Chí Minh',
      districtWard: 'Quận 1',
      streetAddress: '123 Đồng Khởi',
      isDefault: true,
    ),
  ];

  @override
  Future<List<UserAddressModel>> listAddresses() async => List.from(_mockDb);

  @override
  Future<UserAddressModel> createAddress({
    required String recipientName,
    required String recipientPhone,
    required String provinceCity,
    required String districtWard,
    required String streetAddress,
    bool isDefault = false,
  }) async {
    final newAddr = UserAddressModel(
      id: _mockDb.length + 1,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      provinceCity: provinceCity,
      districtWard: districtWard,
      streetAddress: streetAddress,
      isDefault: isDefault,
    );
    _mockDb.add(newAddr);
    return newAddr;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P7-04: Models SafeJsonParser Serialization Tests', () {
    test('BootstrapModel parses backend configuration accurately', () {
      final json = {
        'server_time': '2026-11-14T21:00:00.000Z',
        'demo_mode': true,
        'protection_fee_rate': 0.06,
        'protection_fixed_fee': 7000.0,
        'shipping_fee_default': 0.0,
        'current_user': {
          'id': 10,
          'display_name': 'Vintage Buyer',
          'email': 'buyer@example.com',
          'role': 'buyer_seller',
          'status': 'ACTIVE',
        },
      };

      final bootstrap = BootstrapModel.fromJson(json);
      expect(bootstrap.demoMode, isTrue);
      expect(bootstrap.protectionFeeRate, 0.06);
      expect(bootstrap.protectionFixedFee, 7000.0);
      expect(bootstrap.currentUser?.id, 10);
      expect(bootstrap.currentUser?.displayName, 'Vintage Buyer');
    });

    test('ProfileSummaryModel parses order counts and seller balances', () {
      final json = {
        'user': {
          'id': 5,
          'display_name': 'Shop Secondhand',
          'email': 'shop@example.com',
          'role': 'buyer_seller',
          'status': 'ACTIVE',
          'seller_profile': {
            'shop_slug': 'shop-secondhand',
            'trust_score': '98.5',
            'wallet_balance': '2500000.00',
            'escrow_held_balance': '750000.00',
          },
        },
        'order_status_counts': {
          'PENDING_PAYMENT': 3,
          'PAID': 2,
          'SHIPPED': 4,
          'DISPUTED': 1,
        },
        'favorites_count': 12,
        'following_count': 5,
      };

      final summary = ProfileSummaryModel.fromJson(json);
      expect(summary.user.displayName, 'Shop Secondhand');
      expect(summary.user.sellerProfile?.trustScore, 98.5);
      expect(summary.user.sellerProfile?.walletBalance, 2500000.0);
      expect(summary.pendingPaymentCount, 3);
      expect(summary.paidCount, 2);
      expect(summary.shippedCount, 4);
      expect(summary.disputedCount, 1);
      expect(summary.favoritesCount, 12);
    });

    test('UserAddressModel parses formatted delivery address', () {
      final json = {
        'id': 101,
        'recipient_name': 'Lê Hoàng Nam',
        'recipient_phone': '0987654321',
        'province_city': 'Hà Nội',
        'district_ward': 'Quận Ba Đình',
        'street_address': 'Số 10 Kim Mã',
        'is_default': true,
      };

      final address = UserAddressModel.fromJson(json);
      expect(address.id, 101);
      expect(address.recipientName, 'Lê Hoàng Nam');
      expect(address.fullAddress, 'Số 10 Kim Mã, Quận Ba Đình, Hà Nội');
      expect(address.isDefault, isTrue);
    });
  });

  group('P7-04: Onboarding Screen (M-AU-02) Widget Tests', () {
    testWidgets('Renders all 3 slides and action buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      expect(find.text('Kho đồ vintage tuyển chọn'), findsOneWidget);
      expect(find.text('Đăng nhập / Đăng ký'), findsOneWidget);
      expect(find.text('Khám phá ngay (Guest)'), findsOneWidget);
      expect(find.text('Bỏ qua'), findsOneWidget);

      // Swipe to slide 2
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.text('Đấu giá công bằng Anti-Sniping'), findsOneWidget);

      // Swipe to slide 3
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.text('Bảo vệ người mua 100% qua Escrow'), findsOneWidget);
    });
  });

  group('P7-04: Login & Account Suspension (M-AU-03) Tests', () {
    testWidgets('LoginScreen shows suspension dialog on 403 ACCOUNT_SUSPENDED (BR-AC-04)', (tester) async {
      final storage = SecureTokenStorage.inMemory();
      final mockAuth = MockAuthRepository(storage)..simulateSuspended = true;
      final mockProfile = MockProfileRepository(storage);
      final seasonalNotifier = SeasonalDecorNotifier(null, true);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
          profileRepositoryProvider.overrideWithValue(mockProfile),
          secureTokenStorageProvider.overrideWithValue(storage),
          authViewModelProvider.overrideWith((ref) => AuthViewModel(
                authRepository: mockAuth,
                profileRepository: mockProfile,
                tokenStorage: storage,
                seasonalDecorNotifier: seasonalNotifier,
              )),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Fill in credentials
      final emailField = find.ancestor(
        of: find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.keyboardType == TextInputType.emailAddress,
        ),
        matching: find.byType(TextFormField),
      );
      expect(emailField, findsOneWidget);
      await tester.enterText(emailField, 'suspended@example.com');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nhập mật khẩu của bạn'),
        'secret123',
      );

      // Click login
      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pumpAndSettle();

      // Verify suspension alert dialog appeared per BR-AC-04
      expect(find.text('Tài khoản bị tạm khóa'), findsOneWidget);
      expect(find.textContaining('khóa do vi phạm'), findsWidgets);
      expect(find.text('Tôi đã hiểu'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Tôi đã hiểu'));
      await tester.pumpAndSettle();
      expect(find.text('Tài khoản bị tạm khóa'), findsNothing);
    });
  });

  group('P7-04: Register Unified Account (M-AU-04) Tests', () {
    testWidgets('RegisterScreen displays BR-AC-01 callout and validates password confirmation', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      expect(find.textContaining('Tài khoản hợp nhất Người mua & Người bán (BR-AC-01)'), findsOneWidget);
      expect(find.text('Đăng ký tài khoản'), findsWidgets);

      // Tap submit with empty form -> triggers validation
      final submitBtn = find.widgetWithText(ElevatedButton, 'Đăng ký tài khoản');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập tên hiển thị.'), findsOneWidget);
      expect(find.text('Vui lòng nhập địa chỉ email.'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu.'), findsOneWidget);
    });
  });

  group('P7-04: Unified Personal Hub (M-PF-01) Tests', () {
    testWidgets('Displays Guest state prompt when not authenticated', (tester) async {
      final storage = SecureTokenStorage.inMemory();
      final mockAuth = MockAuthRepository(storage);
      final mockProfile = MockProfileRepository(storage);
      final seasonalNotifier = SeasonalDecorNotifier(null, true);

      final container = ProviderContainer(
        overrides: [
          authViewModelProvider.overrideWith((ref) => AuthViewModel(
                authRepository: mockAuth,
                profileRepository: mockProfile,
                tokenStorage: storage,
                seasonalDecorNotifier: seasonalNotifier,
              )),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: UnifiedPersonalHubScreen(),
          ),
        ),
      );

      expect(find.text('Tham gia cộng đồng izithrift'), findsOneWidget);
      expect(find.text('Đăng nhập / Đăng ký'), findsOneWidget);
    });

    testWidgets('Displays authenticated profile, order status counters & seller mode banner (NAV-DEC-02)', (tester) async {
      final storage = SecureTokenStorage.inMemory();
      await storage.saveTokens(accessToken: 'token', userId: 1, role: 'buyer_seller', email: 'test@example.com');
      final mockAuth = MockAuthRepository(storage);
      final mockProfile = MockProfileRepository(storage);
      final seasonalNotifier = SeasonalDecorNotifier(null, true);

      final authVm = AuthViewModel(
        authRepository: mockAuth,
        profileRepository: mockProfile,
        tokenStorage: storage,
        seasonalDecorNotifier: seasonalNotifier,
      );

      final profileVm = ProfileViewModel(
        profileRepository: mockProfile,
        seasonalDecorNotifier: seasonalNotifier,
      );

      await profileVm.loadProfileSummary();
      authVm.updateCurrentUser(profileVm.profileSummary!.user);

      final container = ProviderContainer(
        overrides: [
          authViewModelProvider.overrideWith((ref) => authVm),
          profileViewModelProvider.overrideWith((ref) => profileVm),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: UnifiedPersonalHubScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify user info
      expect(find.text('Tiệm Đồ Cũ Sài Gòn'), findsOneWidget);
      expect(find.textContaining('Uy tín: 95%'), findsOneWidget);

      // Verify seller mode switch banner (NAV-DEC-02)
      expect(find.text('Kênh Người bán izithrift'), findsOneWidget);
      expect(find.textContaining('Ví: 1.250.000đ'), findsOneWidget);

      // Verify order counters
      expect(find.text('Chờ thanh toán'), findsOneWidget);
      expect(find.text('Chờ gửi hàng'), findsOneWidget);
      expect(find.text('Đang giao'), findsOneWidget);
      expect(find.text('Khiếu nại'), findsOneWidget);
    });
  });

  group('P7-04: Address Book (M-PF-03, M-PF-04) ViewModel & Invariant Tests', () {
    test('AddressViewModel adds address and maintains single default address', () async {
      final storage = SecureTokenStorage.inMemory();
      final mockAddressRepo = MockAddressRepository(storage);
      final vm = AddressViewModel(addressRepository: mockAddressRepo);

      await vm.loadAddresses();
      expect(vm.addresses.length, 1);
      expect(vm.defaultAddress?.streetAddress, '123 Đồng Khởi');

      // Add second address set as default -> previous default should become false
      await vm.createAddress(
        recipientName: 'Trần Văn B',
        recipientPhone: '0988776655',
        provinceCity: 'Hà Nội',
        districtWard: 'Hoàn Kiếm',
        streetAddress: '45 Tràng Tiền',
        isDefault: true,
      );

      expect(vm.addresses.length, 2);
      final firstAddr = vm.addresses.firstWhere((a) => a.id == 1);
      final secondAddr = vm.addresses.firstWhere((a) => a.id == 2);

      expect(firstAddr.isDefault, isFalse);
      expect(secondAddr.isDefault, isTrue);
      expect(vm.defaultAddress?.streetAddress, '45 Tràng Tiền');
    });
  });

  group('P7-04: App Settings & Seasonal Decor Toggle (M-PF-06) Tests', () {
    testWidgets('Toggling seasonal decor switch updates state and provider immediately (NFR-UX-02)', (tester) async {
      final storage = SecureTokenStorage.inMemory();
      await storage.saveTokens(accessToken: 'token', userId: 1, role: 'buyer_seller', email: 'test@example.com');
      final mockAuth = MockAuthRepository(storage);
      final mockProfile = MockProfileRepository(storage);
      final seasonalNotifier = SeasonalDecorNotifier(null, true);

      final authVm = AuthViewModel(
        authRepository: mockAuth,
        profileRepository: mockProfile,
        tokenStorage: storage,
        seasonalDecorNotifier: seasonalNotifier,
      );
      authVm.updateCurrentUser(const UserModel(
        id: 1,
        displayName: 'User',
        email: 'user@example.com',
        role: 'buyer_seller',
        status: 'ACTIVE',
      ));

      final container = ProviderContainer(
        overrides: [
          authViewModelProvider.overrideWith((ref) => authVm),
          profileRepositoryProvider.overrideWithValue(mockProfile),
          seasonalDecorProvider.overrideWith((ref) => seasonalNotifier),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AppSettingsScreen(),
          ),
        ),
      );

      // Verify switch is present and on
      expect(find.textContaining('Chủ đề Giáng sinh ấm áp'), findsOneWidget);
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      expect(container.read(seasonalDecorProvider), isTrue);

      // Toggle off
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(container.read(seasonalDecorProvider), isFalse);
    });
  });
}
