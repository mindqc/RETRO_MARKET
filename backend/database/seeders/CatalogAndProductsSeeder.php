<?php

namespace Database\Seeders;

use App\Enums\ProductCondition;
use App\Enums\ProductStatus;
use App\Models\Brand;
use App\Models\Category;
use App\Models\Product;
use App\Models\ProductImage;
use App\Models\ProductModerationLog;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class CatalogAndProductsSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. 8 Categories
        $categoriesData = [
            ['name' => 'Áo khoác Vintage', 'slug' => 'ao-khoac-vintage', 'icon' => 'jacket', 'desc' => 'Áo khoác dạ Tweed, măng tô, denim jacket và bomber cổ điển'],
            ['name' => 'Đầm & Chân váy Cổ điển', 'slug' => 'dam-chan-vay-co-dien', 'icon' => 'dress', 'desc' => 'Đầm vintage hoa nhí, chân váy Midi xếp ly thanh lịch'],
            ['name' => 'Túi xách & Đồ da', 'slug' => 'tui-xach-do-da', 'icon' => 'bag', 'desc' => 'Túi xách da thuộc thủ công, balo du mục và ví da secondhand'],
            ['name' => 'Đồng hồ & Trang sức Cổ', 'slug' => 'dong-ho-trang-suc-co', 'icon' => 'watch', 'desc' => 'Đồng hồ cơ Automatic, đồng hồ Casio điện tử và trang sức bạc xưa'],
            ['name' => 'Máy ảnh Film & Điện tử Retro', 'slug' => 'may-anh-film-dien-tu-retro', 'icon' => 'camera', 'desc' => 'Máy ảnh cơ 35mm, máy ảnh pns, walkman và đồ sưu tầm công nghệ retro'],
            ['name' => 'Đĩa than & Cassette', 'slug' => 'dia-than-cassette', 'icon' => 'vinyl', 'desc' => 'Băng từ cassette nhạc xưa, đĩa than vinyl âm thanh mộc mạc'],
            ['name' => 'Giày & Boots Da', 'slug' => 'giay-boots-da', 'icon' => 'boots', 'desc' => 'Boots da cổ cao, oxford brogue và giày da secondhand tuyển chọn'],
            ['name' => 'Phụ kiện Mùa Lễ Hội', 'slug' => 'phu-kien-mua-le-hoi', 'icon' => 'holiday', 'desc' => 'Khăn choàng len cashmere, ghim cài áo Noel và mũ beret ấm áp'],
        ];

        $categories = [];
        foreach ($categoriesData as $idx => $c) {
            $categories[$c['slug']] = Category::updateOrCreate(
                ['slug' => $c['slug']],
                [
                    'name' => $c['name'],
                    'icon_name' => $c['icon'],
                    'description' => $c['desc'],
                    'sort_order' => ($idx + 1) * 10,
                    'is_active' => true,
                ]
            );
        }

        // 2. 8 Brands
        $brandsData = [
            ['name' => "Levi's Vintage", 'slug' => 'levis-vintage', 'country' => 'Hoa Kỳ', 'desc' => 'Dòng denim huyền thoại với chất lượng vải dệt con thoi bền bỉ'],
            ['name' => "Burberrys' (Archive)", 'slug' => 'burberrys-archive', 'country' => 'Vương Quốc Anh', 'desc' => 'Áo khoác măng tô họa tiết kẻ kinh điển thập niên 80-90'],
            ['name' => 'Casio Retro', 'slug' => 'casio-retro', 'country' => 'Nhật Bản', 'desc' => 'Đồng hồ điện tử cổ điển mặt vuông vàng kim biểu tượng'],
            ['name' => 'Olympus Film', 'slug' => 'olympus-film', 'country' => 'Nhật Bản', 'desc' => 'Máy ảnh phim cơ học OM-Series và mju nhỏ gọn danh tiếng'],
            ['name' => 'Coach Vintage', 'slug' => 'coach-vintage', 'country' => 'Hoa Kỳ', 'desc' => 'Đồ da thuộc nguyên miếng cổ điển thập niên 90s'],
            ['name' => 'Seiko Automatic', 'slug' => 'seiko-automatic', 'country' => 'Nhật Bản', 'desc' => 'Đồng hồ cơ Seiko 5 và dòng cổ điển bền bỉ theo thời gian'],
            ['name' => 'Dr. Martens Classic', 'slug' => 'dr-martens-classic', 'country' => 'Vương Quốc Anh', 'desc' => 'Những đôi bốt da 1460, 1461 da sáp đượm màu thời gian'],
            ['name' => 'Handmade Archive', 'slug' => 'handmade-archive', 'country' => 'Việt Nam', 'desc' => 'Các tác phẩm may đo thủ công độc bản từ vải tái chế vintage'],
        ];

        $brands = [];
        foreach ($brandsData as $b) {
            $brands[$b['slug']] = Brand::updateOrCreate(
                ['slug' => $b['slug']],
                [
                    'name' => $b['name'],
                    'origin_country' => $b['country'],
                    'description' => $b['desc'],
                    'logo_url' => 'https://images.unsplash.com/photo-1544816155-12df9643f363?w=200',
                    'is_active' => true,
                ]
            );
        }

        // Retrieve users
        $sellerA = User::where('email', 'gau.vintage@izithrift.local')->first();
        $sellerB = User::where('email', 'retrolab.sg@izithrift.local')->first();
        $sellerC = User::where('email', 'tiemnhamay@izithrift.local')->first();
        $moderator = User::where('email', 'moderator@izithrift.local')->first();

        // 3. 16 Products Specification
        $productsData = [
            // Fixed-Price Approved (0001..0006)
            [
                'code' => 'PRD-2026-0001',
                'seller_id' => $sellerA->id,
                'category_slug' => 'ao-khoac-vintage',
                'brand_slug' => 'burberrys-archive',
                'title' => 'Áo Măng Tô Dạ Tweed Kẻ Caro Burberrys Vintage Thập Niên 90s',
                'slug' => 'ao-mang-to-da-tweed-burberrys-vintage-90s',
                'desc' => 'Mẫu áo khoác dạ tweed hai hàng khuy dáng suông, chất vải len pha dạ ấm áp, lót lụa nguyên bản họa tiết Nova Check.',
                'condition' => ProductCondition::GOOD,
                'defect' => 'Có sờn nhẹ ở viền cổ tay áo trái và mất 1 khuy phụ bên trong.',
                'type' => 'FIXED_PRICE',
                'price' => 750000.00,
                'status' => ProductStatus::APPROVED,
                'qty' => 5,
            ],
            [
                'code' => 'PRD-2026-0002',
                'seller_id' => $sellerA->id,
                'category_slug' => 'ao-khoac-vintage',
                'brand_slug' => 'levis-vintage',
                'title' => 'Áo Khoác Denim Levi\'s 70505 Trucker Jacket Made in USA',
                'slug' => 'ao-khoac-denim-levis-70505-trucker-jacket-usa',
                'desc' => 'Chiếc áo khoác denim cổ điển dòng 70505-0217, wash màu bạc tự nhiên với những vệt phai tuyệt đẹp.',
                'condition' => ProductCondition::FAIR,
                'defect' => 'Vải denim bạc màu quanh khuỷu tay và có một vết ố mờ nhỏ ở vạt dưới.',
                'type' => 'FIXED_PRICE',
                'price' => 550000.00,
                'status' => ProductStatus::APPROVED,
                'qty' => 5,
            ],
            [
                'code' => 'PRD-2026-0003',
                'seller_id' => $sellerB->id,
                'category_slug' => 'dong-ho-trang-suc-co',
                'brand_slug' => 'casio-retro',
                'title' => 'Đồng Hồ Điện Tử Casio A168W Vỏ Vàng Kim Nguyên Bản',
                'slug' => 'dong-ho-dien-tu-casio-a168w-vo-vang-kim',
                'desc' => 'Mặt số điện tử cổ điển với đèn nền Illuminator xanh ngọc, dây kim loại nguyên bản.',
                'condition' => ProductCondition::LIKE_NEW,
                'defect' => 'Xước dăm nhẹ mặt kính ở góc 1 giờ, pin mới thay hoạt động chuẩn xác.',
                'type' => 'FIXED_PRICE',
                'price' => 380000.00,
                'status' => ProductStatus::APPROVED,
                'qty' => 5,
            ],
            [
                'code' => 'PRD-2026-0004',
                'seller_id' => $sellerB->id,
                'category_slug' => 'dia-than-cassette',
                'brand_slug' => 'handmade-archive',
                'title' => 'Băng Cassette Nhạc Trịnh Công Sơn – Thu Âm Trước 1975',
                'slug' => 'bang-cassette-nhac-trinh-cong-son-truoc-1975',
                'desc' => 'Bản phát hành băng từ chất âm analog ấm áp, ruột băng còn mới, hộp nhựa nguyên bản.',
                'condition' => ProductCondition::GOOD,
                'defect' => 'Vỏ hộp nhựa ngoài có vết nứt nhỏ góc trên, dây băng đã vệ sinh sạch.',
                'type' => 'FIXED_PRICE',
                'price' => 250000.00,
                'status' => ProductStatus::APPROVED,
                'qty' => 5,
            ],
            [
                'code' => 'PRD-2026-0005',
                'seller_id' => $sellerC->id,
                'category_slug' => 'dam-chan-vay-co-dien',
                'brand_slug' => 'handmade-archive',
                'title' => 'Chân Váy Xòe Midi Xếp Ly Họa Tiết Caro Giáng Sinh Vintage',
                'slug' => 'chan-vay-xoe-midi-xep-ly-caro-giang-sinh-vintage',
                'desc' => 'Chân váy lưng cao chất len mỏng ấm cúng phối sắc đỏ Burgundy và xanh Forest Green đón mùa Noel.',
                'condition' => ProductCondition::LIKE_NEW,
                'defect' => 'Khóa kéo kim loại hơi khít cần bôi sáp nhẹ khi sử dụng.',
                'type' => 'FIXED_PRICE',
                'price' => 320000.00,
                'status' => ProductStatus::APPROVED,
                'qty' => 5,
            ],
            [
                'code' => 'PRD-2026-0006',
                'seller_id' => $sellerC->id,
                'category_slug' => 'phu-kien-mua-le-hoi',
                'brand_slug' => 'handmade-archive',
                'title' => 'Khăn Choàng Len Lông Cừu Dệt Họa Tiết Bắc Âu Cổ Điển',
                'slug' => 'khan-choang-len-long-cuu-bac-au-co-dien',
                'desc' => 'Khăn dệt tay sợi len dày dặn giữ ấm hoàn hảo, tông màu kem và đỏ đun ấm áp.',
                'condition' => ProductCondition::GOOD,
                'defect' => 'Vải có xù lông nhẹ tự nhiên đặc trưng của len cừu mộc.',
                'type' => 'FIXED_PRICE',
                'price' => 280000.00,
                'status' => ProductStatus::APPROVED,
                'qty' => 5,
            ],

            // Auction Products (0007..0011)
            [
                'code' => 'PRD-2026-0007',
                'seller_id' => $sellerB->id,
                'category_slug' => 'may-anh-film-dien-tu-retro',
                'brand_slug' => 'olympus-film',
                'title' => 'Máy Ảnh Film Cơ Olympus OM-10 Kèm Ống Kính F.Zuiko 50mm f/1.8',
                'slug' => 'may-anh-film-olympus-om-10-lens-50mm',
                'desc' => 'Body cơ khí nhỏ gọn ngắm quang học sáng rõ, đo sáng nhạy, ống kính trong veo không mốc rễ.',
                'condition' => ProductCondition::GOOD,
                'defect' => 'Vỏ máy cọ xát sờn sơn nhẹ ở đáy máy do gắn tripod, màn trập nảy êm.',
                'type' => 'AUCTION',
                'price' => 800000.00,
                'status' => ProductStatus::APPROVED,
                'qty' => 1,
            ],
            [
                'code' => 'PRD-2026-0008',
                'seller_id' => $sellerB->id,
                'category_slug' => 'dong-ho-trang-suc-co',
                'brand_slug' => 'seiko-automatic',
                'title' => 'Đồng Hồ Cơ Seiko 5 Automatic Mặt Vuông Xanh Thập Niên 80s',
                'slug' => 'dong-ho-seiko-5-automatic-mat-vuong-xanh-80s',
                'desc' => 'Cỗ máy 7009 bền bỉ lịch ngày thứ tự động, mặt số màu xanh navy chuyển sắc tuyệt đẹp.',
                'condition' => ProductCondition::GOOD,
                'defect' => 'Mặt kính khoáng xước dăm mảnh nhìn nghiêng mới thấy, đã lau dầu hoạt động chính xác.',
                'type' => 'AUCTION',
                'price' => 600000.00,
                'status' => ProductStatus::APPROVED,
                'qty' => 1,
            ],
            [
                'code' => 'PRD-2026-0009',
                'seller_id' => $sellerA->id,
                'category_slug' => 'tui-xach-do-da',
                'brand_slug' => 'coach-vintage',
                'title' => 'Túi Da Bò Thuộc Thao Tác Thủ Công Coach Vintage Dinky Crossbody',
                'slug' => 'tui-da-bo-coach-vintage-dinky-crossbody',
                'desc' => 'Chất da thuộc Glove Tanned Leather dày dặn kinh điển, khóa xoay đồng vàng nguyên bản.',
                'condition' => ProductCondition::VINTAGE_WORN,
                'defect' => 'Da có vết sẫm màu tự nhiên theo thời gian (patina) và trầy nhẹ góc đáy.',
                'type' => 'AUCTION',
                'price' => 900000.00,
                'status' => ProductStatus::APPROVED,
                'qty' => 1,
            ],
            [
                'code' => 'PRD-2026-0010',
                'seller_id' => $sellerA->id,
                'category_slug' => 'giay-boots-da',
                'brand_slug' => 'dr-martens-classic',
                'title' => 'Đôi Bốt Da Dr. Martens 1460 8 Lỗ Made in England',
                'slug' => 'doi-bot-da-dr-martens-1460-england',
                'desc' => 'Dòng bốt da sản xuất thủ công tại Anh quốc, đường chỉ vàng AirWair nổi tiếng.',
                'condition' => ProductCondition::GOOD,
                'defect' => 'Mũi giày có nếp gấp nhăn tự nhiên theo dáng chân, đế giày còn nguyên gai chống trượt.',
                'type' => 'AUCTION',
                'price' => 1000000.00,
                'status' => ProductStatus::SOLD,
                'qty' => 1,
            ],
            [
                'code' => 'PRD-2026-0011',
                'seller_id' => $sellerC->id,
                'category_slug' => 'ao-khoac-vintage',
                'brand_slug' => 'handmade-archive',
                'title' => 'Áo Len Cardigan Dệt Sợi Cổ Điển Họa Tiết Mùa Đông',
                'slug' => 'ao-len-cardigan-det-soi-co-dien-mua-dong',
                'desc' => 'Cardigan len dày cúc gỗ thủ công, phong cách mộc mạc ấm áp phong cách Đà Lạt.',
                'condition' => ProductCondition::FAIR,
                'defect' => 'Gấu áo có một sợi len bị sút nhẹ đã được cố định khéo léo.',
                'type' => 'AUCTION',
                'price' => 450000.00,
                'status' => ProductStatus::APPROVED,
                'qty' => 1,
            ],

            // Other Lifecycle States (0012..0016)
            [
                'code' => 'PRD-2026-0012',
                'seller_id' => $sellerA->id,
                'category_slug' => 'ao-khoac-vintage',
                'brand_slug' => 'levis-vintage',
                'title' => 'Bản Nháp: Áo Khoác Gió Retro Thể Thao 90s',
                'slug' => 'ban-nhap-ao-khoac-gio-retro-the-thao-90s',
                'desc' => 'Nội dung bản nháp của người bán đang soạn dở.',
                'condition' => ProductCondition::GOOD,
                'defect' => 'Chưa hoàn tất mô tả vết xước chi tiết.',
                'type' => 'FIXED_PRICE',
                'price' => 300000.00,
                'status' => ProductStatus::DRAFT,
                'qty' => 1,
            ],
            [
                'code' => 'PRD-2026-0013',
                'seller_id' => $sellerB->id,
                'category_slug' => 'dia-than-cassette',
                'brand_slug' => 'handmade-archive',
                'title' => 'Đĩa Than Nhạc Jazz Cổ Miles Davis – Kind of Blue Vinyl',
                'slug' => 'dia-than-nhac-jazz-miles-davis-kind-of-blue',
                'desc' => 'Đĩa than sưu tầm ấn bản Nhật kèm bìa Obi, đang chờ kiểm duyệt viên phê duyệt.',
                'condition' => ProductCondition::LIKE_NEW,
                'defect' => 'Bìa đĩa ố vàng nhẹ theo mép giấy, mặt đĩa bóng sạch.',
                'type' => 'FIXED_PRICE',
                'price' => 650000.00,
                'status' => ProductStatus::PENDING_REVIEW,
                'qty' => 1,
            ],
            [
                'code' => 'PRD-2026-0014',
                'seller_id' => $sellerA->id,
                'category_slug' => 'ao-khoac-vintage',
                'brand_slug' => 'burberrys-archive',
                'title' => 'Áo Dạ Ngắn Cổ Sen Vintage Thập Niên 80s (Bị Từ Chối Duyệt)',
                'slug' => 'ao-da-ngan-co-sen-vintage-80s-rejected',
                'desc' => 'Mẫu áo dạ ngắn vintage màu nâu hạt dẻ cổ trang nhã.',
                'condition' => ProductCondition::FAIR,
                'defect' => 'Rách nhẹ mép trong nách áo chưa chụp rõ.',
                'type' => 'FIXED_PRICE',
                'price' => 420000.00,
                'status' => ProductStatus::REJECTED,
                'rejection_reason' => 'Hình ảnh sản phẩm bị mờ và thiếu ảnh chụp cận cảnh vết sờn rách ở cổ áo',
                'qty' => 1,
            ],
            [
                'code' => 'PRD-2026-0015',
                'seller_id' => $sellerC->id,
                'category_slug' => 'phu-kien-mua-le-hoi',
                'brand_slug' => 'handmade-archive',
                'title' => 'Mũ Nồi Beret Len Vintage Tông Màu Đỏ Rượu (Tạm Ẩn)',
                'slug' => 'mu-noi-beret-len-vintage-do-ruou-hidden',
                'desc' => 'Mũ beret kiểu Pháp thanh lịch, đang tạm ẩn trên gian hàng theo yêu cầu người bán.',
                'condition' => ProductCondition::GOOD,
                'defect' => 'Có sợi len tưa nhẹ phía vành trong.',
                'type' => 'FIXED_PRICE',
                'price' => 180000.00,
                'status' => ProductStatus::HIDDEN,
                'qty' => 1,
            ],
            [
                'code' => 'PRD-2026-0016',
                'seller_id' => $sellerA->id,
                'category_slug' => 'tui-xach-do-da',
                'brand_slug' => 'coach-vintage',
                'title' => 'Ví Da Cầm Tay Vintage Dáng Dài Khóa Bấm Đồng Cổ (Đã Bán)',
                'slug' => 'vi-da-cam-tay-vintage-dang-dai-sold',
                'desc' => 'Ví da thuộc dáng dài nhiều ngăn đựng tiện lợi, đã giao dịch thành công.',
                'condition' => ProductCondition::GOOD,
                'defect' => 'Góc gập ví hơi ngả màu đậm do ma sát cầm nắm.',
                'type' => 'FIXED_PRICE',
                'price' => 500000.00,
                'status' => ProductStatus::SOLD,
                'qty' => 1,
                'avail' => 0,
            ],
        ];

        foreach ($productsData as $pd) {
            $cat = $categories[$pd['category_slug']];
            $brand = $brands[$pd['brand_slug']];

            $product = Product::updateOrCreate(
                ['product_code' => $pd['code']],
                [
                    'seller_id' => $pd['seller_id'],
                    'category_id' => $cat->id,
                    'brand_id' => $brand->id,
                    'title' => $pd['title'],
                    'slug' => $pd['slug'],
                    'description' => $pd['desc'],
                    'condition' => $pd['condition'],
                    'defect_info' => $pd['defect'],
                    'listing_type' => $pd['type'],
                    'price' => $pd['price'],
                    'total_quantity' => $pd['qty'],
                    'available_quantity' => $pd['avail'] ?? ($pd['status'] === ProductStatus::SOLD ? 0 : $pd['qty']),
                    'verification_level' => 'UNVERIFIED',
                    'status' => $pd['status'],
                    'rejection_reason' => $pd['rejection_reason'] ?? null,
                    'favorite_count' => 0,
                    'approved_at' => $pd['status'] === ProductStatus::APPROVED ? now() : null,
                    'approved_by' => $pd['status'] === ProductStatus::APPROVED ? $moderator->id : null,
                ]
            );

            // Seed Product Images
            $images = [
                ['url' => 'https://images.unsplash.com/photo-1544441893-675973e31985?w=600', 'type' => 'GALLERY', 'primary' => true, 'sort' => 1],
                ['url' => 'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=600', 'type' => 'DEFECT_CLOSEUP', 'primary' => false, 'sort' => 2],
                ['url' => 'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?w=600', 'type' => 'AUTHENTICITY_EVIDENCE', 'primary' => false, 'sort' => 3],
            ];

            foreach ($images as $img) {
                ProductImage::firstOrCreate(
                    [
                        'product_id' => $product->id,
                        'sort_order' => $img['sort'],
                    ],
                    [
                        'image_url' => $img['url'],
                        'image_type' => $img['type'],
                        'is_primary' => $img['primary'],
                        'file_size_bytes' => 1024000,
                    ]
                );
            }

            // If REJECTED or HIDDEN, seed product moderation log
            if ($pd['status'] === ProductStatus::REJECTED) {
                ProductModerationLog::firstOrCreate(
                    [
                        'product_id' => $product->id,
                        'action' => 'REJECTED',
                    ],
                    [
                        'moderator_id' => $moderator->id,
                        'previous_status' => 'PENDING_REVIEW',
                        'new_status' => 'REJECTED',
                        'verification_level_assigned' => 'UNVERIFIED',
                        'reason' => $pd['rejection_reason'],
                    ]
                );
            } elseif ($pd['status'] === ProductStatus::HIDDEN) {
                ProductModerationLog::firstOrCreate(
                    [
                        'product_id' => $product->id,
                        'action' => 'HIDDEN',
                    ],
                    [
                        'moderator_id' => $moderator->id,
                        'previous_status' => 'APPROVED',
                        'new_status' => 'HIDDEN',
                        'verification_level_assigned' => 'UNVERIFIED',
                        'reason' => 'Sản phẩm tạm thời bị ẩn theo yêu cầu người bán',
                    ]
                );
            }
        }
    }
}
