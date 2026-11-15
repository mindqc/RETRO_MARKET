<?php

namespace Database\Seeders;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\Cart;
use App\Models\PlatformSetting;
use App\Models\SellerProfile;
use App\Models\User;
use App\Models\UserAddress;
use App\Models\UserProfile;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class PlatformAndUsersSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Ensure 12 Platform Settings (DEC-04 & ADR-05)
        $defaultSettings = [
            ['key' => 'protection_fee_rate', 'value' => '0.06', 'value_type' => 'DECIMAL', 'description' => 'Tỷ lệ % Phí bảo vệ người mua (Mặc định 6%, cho phép 5%-8% theo DEC-04)'],
            ['key' => 'protection_fixed_fee', 'value' => '7000', 'value_type' => 'DECIMAL', 'description' => 'Phí bảo vệ cố định VND trên mỗi đơn hàng (Mặc định 7.000đ, cho phép 5k-10k theo DEC-04)'],
            ['key' => 'shipping_fee_default', 'value' => '0', 'value_type' => 'DECIMAL', 'description' => 'Phí vận chuyển thu trên ứng dụng (Cố định 0 VND theo DEC-04)'],
            ['key' => 'seller_commission_rate', 'value' => '0', 'value_type' => 'DECIMAL', 'description' => 'Hoa hồng thu từ người bán (Cố định 0% - Seller nhận đủ 100% tiền hàng theo DEC-04)'],
            ['key' => 'auction_payment_window_production_sec', 'value' => '1800', 'value_type' => 'INTEGER', 'description' => 'Thời hạn thanh toán đơn thắng đấu giá Production (30 phút = 1800 giây)'],
            ['key' => 'auction_payment_window_demo_sec', 'value' => '120', 'value_type' => 'INTEGER', 'description' => 'Thời hạn thanh toán đơn thắng đấu giá Demo Mode (2 phút = 120 giây theo ADR-05)'],
            ['key' => 'auto_complete_window_production_sec', 'value' => '86400', 'value_type' => 'INTEGER', 'description' => 'Thời gian tự hoàn tất đơn & giải ngân sau khi giao hàng Production (24 giờ = 86400 giây)'],
            ['key' => 'auto_complete_window_demo_sec', 'value' => '120', 'value_type' => 'INTEGER', 'description' => 'Thời gian tự hoàn tất đơn & giải ngân Demo Mode (2 phút = 120 giây theo ADR-05)'],
            ['key' => 'anti_sniping_trigger_window_production_sec', 'value' => '120', 'value_type' => 'INTEGER', 'description' => 'Khung giờ kích hoạt Anti-sniping trước khi hết phiên Production (2 phút cuối)'],
            ['key' => 'anti_sniping_trigger_window_demo_sec', 'value' => '30', 'value_type' => 'INTEGER', 'description' => 'Khung giờ kích hoạt Anti-sniping Demo Mode (30 giây cuối theo ADR-05)'],
            ['key' => 'anti_sniping_extend_duration_production_sec', 'value' => '120', 'value_type' => 'INTEGER', 'description' => 'Thời gian gia hạn phiên đấu giá khi có bid phút chót Production (+2 phút)'],
            ['key' => 'anti_sniping_extend_duration_demo_sec', 'value' => '30', 'value_type' => 'INTEGER', 'description' => 'Thời gian gia hạn phiên đấu giá Demo Mode (+30 giây theo ADR-05)'],
        ];

        foreach ($defaultSettings as $setting) {
            PlatformSetting::updateOrCreate(
                ['key' => $setting['key']],
                [
                    'value' => $setting['value'],
                    'value_type' => $setting['value_type'],
                    'description' => $setting['description'],
                ]
            );
        }

        // 2. 10 Standardized User Accounts
        $passwordHash = Hash::make('Retro@2026');

        $usersData = [
            [
                'email' => 'admin@izithrift.local',
                'display_name' => 'Quản Trị Viên Tối Cao',
                'phone' => '0901000001',
                'role' => UserRole::ADMIN,
                'status' => UserStatus::ACTIVE,
                'bio' => 'Quản trị viên nền tảng izithrift',
                'avatar' => 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
                'shop_slug' => 'izithrift-official',
                'address' => 'Tầng 12, Tòa nhà Bitexco, Bến Nghé, Quận 1, TP. Hồ Chí Minh',
            ],
            [
                'email' => 'moderator@izithrift.local',
                'display_name' => 'Kiểm Duyệt Viên Minh Anh',
                'phone' => '0901000002',
                'role' => UserRole::MODERATOR,
                'status' => UserStatus::ACTIVE,
                'bio' => 'Chuyên viên kiểm duyệt chất lượng đồ secondhand & vintage',
                'avatar' => 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200',
                'shop_slug' => 'moderator-desk',
                'address' => 'Số 45 Tràng Tiền, Hoàn Kiếm, Hà Nội',
            ],
            [
                'email' => 'support@izithrift.local',
                'display_name' => 'Hỗ Trợ Viên Hoàng Nam',
                'phone' => '0901000003',
                'role' => UserRole::SUPPORT,
                'status' => UserStatus::ACTIVE,
                'bio' => 'Chuyên viên tiếp nhận khiếu nại & chăm sóc khách hàng',
                'avatar' => 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
                'shop_slug' => 'support-desk',
                'address' => 'Số 120 Hai Bà Trưng, Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh',
            ],
            [
                'email' => 'gau.vintage@izithrift.local',
                'display_name' => 'Tiệm Đồ Si Nhà Gấu',
                'phone' => '0902000001',
                'role' => UserRole::REGISTERED_USER,
                'status' => UserStatus::ACTIVE,
                'bio' => 'Chuyên đồ si tuyển chọn Nhật - Hàn: Áo khoác dạ Tweed, blazer len, túi da retro',
                'avatar' => 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
                'shop_slug' => 'gau-vintage',
                'address' => 'Số 18 Ngõ 32 Chùa Láng, Đống Đa, Hà Nội',
                'trust_score' => 100.00,
                'rating' => 5.00,
            ],
            [
                'email' => 'retrolab.sg@izithrift.local',
                'display_name' => 'Sài Gòn Retro Lab',
                'phone' => '0902000002',
                'role' => UserRole::REGISTERED_USER,
                'status' => UserStatus::ACTIVE,
                'bio' => 'Không gian máy ảnh film, đĩa than cổ, cassette và đồ điện tử sưu tầm thập niên 80-90',
                'avatar' => 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
                'shop_slug' => 'retrolab-sg',
                'address' => 'Chung cư 42 Tôn Thất Thiệp, Bến Nghé, Quận 1, TP. Hồ Chí Minh',
                'trust_score' => 98.50,
                'rating' => 4.80,
            ],
            [
                'email' => 'tiemnhamay@izithrift.local',
                'display_name' => 'Tiệm Nhỏ Trên Mây',
                'phone' => '0902000003',
                'role' => UserRole::REGISTERED_USER,
                'status' => UserStatus::ACTIVE,
                'bio' => 'Chân váy Midi hoa nhí, cardigan len cừu và phụ kiện ấm cúng mùa Giáng sinh',
                'avatar' => 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200',
                'shop_slug' => 'tiem-nho-tren-may',
                'address' => 'Số 86 Lê Lợi, Phường 4, TP. Đà Lạt, Lâm Đồng',
                'trust_score' => 95.00,
                'rating' => 4.50,
            ],
            [
                'email' => 'buyer.linh@izithrift.local',
                'display_name' => 'Nguyễn Ngọc Linh',
                'phone' => '0903000001',
                'role' => UserRole::REGISTERED_USER,
                'status' => UserStatus::ACTIVE,
                'bio' => 'Tín đồ mê đồ si và phong cách thời trang ấm áp cổ điển',
                'avatar' => 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200',
                'shop_slug' => 'linh-wardrobe',
                'address' => 'Căn hộ 1402, Chung cư Vinhomes GreenBay, Mễ Trì, Nam Từ Liêm, Hà Nội',
            ],
            [
                'email' => 'buyer.kiet@izithrift.local',
                'display_name' => 'Trần Tuấn Kiệt',
                'phone' => '0903000002',
                'role' => UserRole::REGISTERED_USER,
                'status' => UserStatus::ACTIVE,
                'bio' => 'Sưu tập đồng hồ vintage và máy ảnh film cơ',
                'avatar' => 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=200',
                'shop_slug' => 'kiet-collector',
                'address' => 'Số 22/5 Đường số 8, Phường Bình An, TP. Thủ Đức, TP. Hồ Chí Minh',
            ],
            [
                'email' => 'buyer.ha@izithrift.local',
                'display_name' => 'Lê Thanh Hà',
                'phone' => '0903000003',
                'role' => UserRole::REGISTERED_USER,
                'status' => UserStatus::ACTIVE,
                'bio' => 'Người mua đồ secondhand thường xuyên',
                'avatar' => 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200',
                'shop_slug' => 'ha-vintage-corner',
                'address' => 'Số 15 Lê Duẩn, Phường Hải Châu 1, Hải Châu, Đà Nẵng',
                'auction_default_count' => 1,
            ],
            [
                'email' => 'suspended.user@izithrift.local',
                'display_name' => 'Tài Khoản Đang Tạm Khóa',
                'phone' => '0909999999',
                'role' => UserRole::REGISTERED_USER,
                'status' => UserStatus::SUSPENDED,
                'bio' => 'Tài khoản đang bị tạm ngưng giao dịch theo BR-AC-04',
                'avatar' => 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
                'shop_slug' => 'suspended-user-shop',
                'address' => 'Số 999 Đường Vi Phạm, TP. Hồ Chí Minh',
            ],
        ];

        foreach ($usersData as $u) {
            $user = User::updateOrCreate(
                ['email' => $u['email']],
                [
                    'display_name' => $u['display_name'],
                    'phone' => $u['phone'],
                    'password_hash' => $passwordHash,
                    'role' => $u['role'],
                    'status' => $u['status'],
                    'status_reason' => $u['status'] === UserStatus::SUSPENDED ? 'Vi phạm quy tắc kiểm duyệt nội dung cộng đồng' : null,
                    'suspended_until' => $u['status'] === UserStatus::SUSPENDED ? now()->addDays(7) : null,
                    'last_login_at' => now(),
                ]
            );

            // UserProfile
            UserProfile::updateOrCreate(
                ['user_id' => $user->id],
                [
                    'avatar_url' => $u['avatar'],
                    'bio' => $u['bio'],
                    'seasonal_decor_enabled' => true,
                ]
            );

            // SellerProfile (Unified account dual profile)
            SellerProfile::updateOrCreate(
                ['user_id' => $user->id],
                [
                    'shop_slug' => $u['shop_slug'],
                    'trust_score' => $u['trust_score'] ?? 100.00,
                    'average_rating' => $u['rating'] ?? 0.00,
                    'review_count' => 0,
                    'completed_orders_count' => 0,
                    'wallet_balance' => 0.00,
                    'escrow_held_balance' => 0.00,
                    'auction_default_count' => $u['auction_default_count'] ?? 0,
                    'dispute_lost_count' => 0,
                ]
            );

            // UserAddress
            UserAddress::updateOrCreate(
                ['user_id' => $user->id, 'is_default' => true],
                [
                    'recipient_name' => $u['display_name'],
                    'recipient_phone' => $u['phone'],
                    'province_city' => Str::contains($u['address'], 'Hà Nội') ? 'Thành phố Hà Nội' : 'Thành phố Hồ Chí Minh',
                    'district_ward' => 'Phường Trung Tâm',
                    'street_address' => $u['address'],
                    'is_default' => true,
                ]
            );

            // Cart
            Cart::firstOrCreate(['user_id' => $user->id]);
        }
    }
}
