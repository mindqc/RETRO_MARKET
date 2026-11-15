# P7-06: PRODUCT DETAIL, DEFECT VERIFICATION & PUBLIC SELLER STOREFRONT SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P706-PRODUCT-DETAIL-STOREFRONT`
- **Version:** `1.0.0`
- **Status:** `DONE` (Nghiệm thu chính thức bởi Product Owner - 2026-11-15)
- **Phase:** `Phase 07 – Task P7-06`
- **Dependencies:** `P7-01, P7-02, P7-03, P7-05 Completed`

---

## 1. Objective & Scope (`Mục Tiêu & Phạm Vi`)
Hiện thực hóa trang xem chi tiết sản phẩm secondhand (`M-PD-01`), khu vực kiểm định lỗi và độ mới đặc thù đồ si (`M-PD-02`), trình xem phóng to ảnh cận cảnh vết xước/lỗi (`M-DS-04`), và trang cửa hàng công khai của Người bán (`M-US-03`). Gói này bao gồm đúng **4 màn hình Mobile**:
- `M-PD-01`: Chi tiết Sản phẩm Giá cố định (`Product Detail`)
- `M-PD-02`: Bảng Thông tin Lỗi & Bằng chứng Kiểm định (`Defect & Condition Card`)
- `M-DS-04`: Trình xem ảnh phóng to toàn màn hình (`Full-Screen Zoom Viewer`)
- `M-US-03`: Trang Cửa hàng Công khai của Tiệm (`Public Seller Storefront`)

---

## 2. Screen Specifications & UX Flows (`Đặc Tả Chi Tiết 4 Màn Hình`)

### 2.1. `M-PD-01: Product Detail Screen`
- **Thanh App Bar Nổi:**
  - Nút quay lại, Nút thích (`Toggle Favorite` gọi `POST /api/v1/products/{id}/favorite`), Nút chia sẻ, Nút giỏ hàng (kèm huy hiệu số lượng).
- **Thư Viện Ảnh Sản Phẩm (`Image Carousel`):**
  - Trượt ngang danh sách ảnh, hiển thị chỉ số ảnh `1/5`.
  - Nhấn vào bất kỳ ảnh nào để mở `M-DS-04` phóng to toàn màn hình.
- **Khối Thông Tin Chính:**
  - Giá bán hiển thị lớn (`24px Bold #873A43`).
  - Tiêu đề sản phẩm, mã sản phẩm (`product_code`), danh mục, thương hiệu.
  - Huy hiệu `ConditionBadge` và `VerificationBadge`.
  - Thông số tồn kho: `Còn lại X sản phẩm`.
- **Khối Kiểm Định Đồ Si & Khuyết Điểm (`Vintage Condition Section`):**
  - Hộp cảnh báo màu be/vintage: Tóm tắt vết xước / hao mòn (`defect_info`).
  - Nút `[🔍 Xem chi tiết phiếu kiểm định]` mở `M-PD-02`.
- **Khối Thẻ Chủ Tiệm (`Seller Micro-Card`):**
  - Avatar tiệm, Tên tiệm, `shop_slug`, Huy hiệu `Điểm uy tín (Trust Score)`.
  - Nút `[Xem Tiệm]` chuyển sang `M-US-03`.
  - Nút `[Chat với Tiệm]` mở cuộc trò chuyện 1-1 tại `M-CM-02` (tự động đính kèm ngữ cảnh sản phẩm này).
- **Thanh Đặt Hàng Cố Định Dưới Cùng (`Bottom Action Bar`):**
  - **Quy tắc `BR-AC-02` (Self-Transaction Forbidden):**
    - Nếu sản phẩm thuộc về chính người dùng đang đăng nhập (`is_owner == true`):
      - Ẩn hoặc vô hiệu hóa 2 nút Mua/Thêm vào giỏ.
      - Hiển thị thông báo: *"Đây là sản phẩm của bạn"*, kèm nút `[Chỉnh sửa bài đăng]` dẫn sang `M-SL-04`.
    - Nếu là người mua khác:
      - Nút `[Thêm vào giỏ hàng]`: Gọi `POST /api/v1/cart/items`, hiển thị Toast thành công.
      - Nút `[Mua ngay]`: Bật Bottom Sheet chọn số lượng, sau đó chuyển thẳng sang `M-OR-01` (`source: 'BUY_NOW'`).

### 2.2. `M-PD-02: Defect & Condition Verification Modal`
- Hiển thị đầy đủ biên bản mô tả khuyết điểm:
  - Tình trạng tổng thể (`condition` và giải nghĩa chi tiết).
  - Vị trí các lỗi cụ thể (ví dụ: *Sờn nhẹ cổ áo, mất 1 cúc phụ ở tay áo trái*).
  - Bằng chứng hình ảnh chụp cận cảnh từng vết lỗi do người bán cung cấp hoặc moderator yêu cầu.

### 2.3. `M-DS-04: Full-Screen Zoom Viewer`
- Sử dụng `InteractiveViewer` cho phép người dùng thao tác hai ngón tay phóng to thu nhỏ ảnh (`pinch-to-zoom`) lên đến 400% để soi rõ đường kim mũi chỉ, nhãn mác, chất vải hoặc vết trầy xước tự nhiên của đồ vintage.
- Nút đóng ở góc trên và thanh vuốt chuyển đổi giữa các ảnh.

### 2.4. `M-US-03: Public Seller Storefront Screen`
- **Banner & Thông Tin Tiệm:**
  - Ảnh bìa phong cách vintage, Avatar tiệm, Tên tiệm, Bio giới thiệu.
  - Điểm uy tín `Trust Score` (ví dụ: `100.0/100`), Số lượng đánh giá (`review_count`), Điểm trung bình (`average_rating` ⭐ 5.0).
  - Tỷ lệ hoàn thành đơn hàng, thời gian tham gia nền tảng.
  - Nút `[Theo dõi Tiệm / Đang theo dõi]` gọi `POST /api/v1/sellers/{id}/follow`.
  - Nút `[Nhắn tin với Tiệm]` mở `M-CM-02`.
- **Hệ Thống 4 Tab Nội Dung:**
  - Tab 1: **Tất cả đồ đang bán** (Lưới sản phẩm `ProductCard`).
  - Tab 2: **Đấu giá của Tiệm** (Các phiên `LIVE` và `SCHEDULED` của tiệm).
  - Tab 3: **Đồ đã bán** (`SOLD` archive).
  - Tab 4: **Đánh giá từ Người mua** (Hiển thị các đánh giá đã xác minh `VerifiedReviewItem` từ các đơn mua thật).

---

## 3. Architecture & State Management (MVVM Pattern)
- **Models:** `ProductDetailModel`, `ProductImageModel`, `SellerPublicProfileModel`, `ReviewItemModel`.
- **Repositories (Tuân thủ Kiến trúc Gộp được PO Phê duyệt):**
  - `HomeCatalogRepository` (`mobile/lib/features/catalog/repositories/home_catalog_repository.dart`): Cung cấp `fetchProductDetail`, `toggleFavorite`, `addToCart`.
  - `SellerStorefrontRepository` (`mobile/lib/features/catalog/repositories/seller_storefront_repository.dart`): Cung cấp `fetchSellerStorefront`, `toggleFollowSeller`, `fetchSellerReviews`.
- **ViewModels (`BaseViewModel` / Riverpod):**
  - `ProductDetailViewModel`: Quản lý nạp chi tiết sản phẩm, toggle favorite, thêm vào giỏ, kiểm tra `is_owner` (`BR-AC-02`), chỉ số ảnh hiện tại.
  - `SellerStorefrontViewModel`: Quản lý hồ sơ tiệm công khai, toggle follow, quản lý 4 tab nội dung và danh sách đánh giá xác thực.

---

## 4. API Endpoints Utilized
- `GET /api/v1/products/{id}`
- `POST /api/v1/products/{id}/favorite`
- `POST /api/v1/cart/items`
- `GET /api/v1/sellers/{id}`
- `POST /api/v1/sellers/{id}/follow`
- `GET /api/v1/sellers/{id}/reviews`

---

## 5. Acceptance Criteria (`Tiêu Chí Nghiệm Thu P7-06`)
- [x] **AC-P706-01:** Trang chi tiết sản phẩm hiển thị đầy đủ hình ảnh, giá, mô tả lỗi, bảng chi tiết thanh toán `DEC-04`, và nút mua bị khóa đúng quy tắc `BR-AC-02` khi xem bài đăng của chính mình.
- [x] **AC-P706-02:** Trình xem ảnh `InteractiveViewer` phóng to mượt mà lên tới 400%, soi rõ chi tiết khuyết điểm đồ vintage.
- [x] **AC-P706-03:** Trang cửa hàng công khai hiển thị đúng Trust Score, đánh giá xác thực, và nút theo dõi tiệm cập nhật tức thì (Optimistic UI).
- [x] **AC-P706-04:** Viết đầy đủ Unit & Widget tests cho ViewModels và 4 màn hình trong `test/features/product_and_storefront_test.dart` đạt **100% PASS** (7/7 tests passed; toàn bộ 64/64 mobile tests PASS, flutter analyze: 0 issues).

---

## 6. Verification Summary & Artifacts
| Thành phần | Đường dẫn tệp tin | Ghi chú & Đánh giá |
| :--- | :--- | :--- |
| **Models** | `mobile/lib/features/catalog/models/` | `ProductImageModel`, `ProductDetailModel`, `ReviewItemModel`, `SellerPublicProfileModel` (hỗ trợ 5 mức Condition, SafeJsonParser, DEC-04). |
| **Repositories** | `mobile/lib/features/catalog/repositories/` | Mở rộng `HomeCatalogRepository`, tạo mới `SellerStorefrontRepository`. |
| **ViewModels** | `mobile/lib/features/catalog/viewmodels/` | `ProductDetailViewModel`, `SellerStorefrontViewModel` kết nối Riverpod. |
| **Screens** | `mobile/lib/features/catalog/screens/` | `ProductDetailScreen` (M-PD-01), `DefectVerificationModal` (M-PD-02), `FullScreenZoomViewer` (M-DS-04), `PublicSellerStorefrontScreen` (M-US-03). |
| **Routing** | `mobile/lib/core/router/app_router.dart` | Đăng ký `/products/:id` và `/sellers/:id`. |
| **Tests** | `mobile/test/features/product_and_storefront_test.dart` | 7 kịch bản kiểm thử toàn diện đạt **100% PASS**. |
