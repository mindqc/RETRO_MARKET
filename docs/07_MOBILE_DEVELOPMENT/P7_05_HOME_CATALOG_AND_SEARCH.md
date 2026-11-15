# P7-05: HOME DISCOVERY, TAXONOMY DIRECTORY & MULTI-FILTER SEARCH SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P705-HOME-CATALOG-SEARCH`
- **Version:** `1.0.0`
- **Status:** `DONE` (Nghiệm thu chính thức bởi Product Owner - 2026-11-15)
- **Phase:** `Phase 07 – Task P7-05`
- **Dependencies:** `P7-01, P7-02, P7-03, P7-04 Completed`

---

## 1. Objective & Scope (`Mục Tiêu & Phạm Vi`)
Hiện thực hóa trải nghiệm khám phá sản phẩm secondhand & vintage ở Tab 1 (Trang chủ) và Tab 2 (Khám phá / Tìm kiếm), tích hợp với các API `/api/v1/home`, `/api/v1/catalog/taxonomy` và `/api/v1/products`. Gói này bao gồm đúng **5 màn hình Mobile**:
- `M-HM-01`: Trang chủ Khám phá (Home Feed)
- `M-HM-02`: Danh sách Tiệm đồ si nổi bật / Bộ sưu tập theo mùa
- `M-DS-01`: Cây Danh mục & Thương hiệu (`Category & Brand Directory`)
- `M-DS-02`: Tìm kiếm từ khóa & Lưới kết quả sản phẩm (`Search Results`)
- `M-DS-03`: Bottom Sheet Bộ lọc Đa tiêu chí (`Multi-Filter Sheet`)

---

## 2. Screen Specifications & UX Flows (`Đặc Tả Chi Tiết 5 Màn Hình`)

### 2.1. `M-HM-01: Home Feed Screen` (Tab 1)
- **Top App Bar:**
  - Logo `izithrift` (Typography `Wichita Vintage`), thanh tìm kiếm thu nhỏ (nhấn chuyển sang `M-DS-02`), biểu tượng Thông báo (kèm chấm đỏ chưa đọc, chuyển sang `M-NT-01`), và Giỏ hàng (chuyển sang `M-CR-01`).
- **Hero Carousel Banner:**
  - Banner Giáng sinh ấm áp & Khuyến mãi tuần lễ đồ vintage.
- **Hàng Danh mục Nhanh (52x52px Icons):**
  - Áo khoác vintage, Quần denim retro, Túi xách da, Đồng hồ cổ, Giày da cũ, Đồ trang trí Giáng sinh. Nhấn vào danh mục mở `M-DS-02` với `category_id` tương ứng.
- **Dải Đấu Giá Sôi Động (`Live Auctions Horizontal Strip`):**
  - Hiển thị các phiên đấu giá `LIVE` có nhiều lượt trả giá nhất. Mỗi thẻ có huy hiệu đỏ nhấp nháy, giá hiện tại và `CountdownTimerWidget`. Nhấn vào mở `M-AC-03`.
- **Khu Vực Tiệm Đồ Si Uy Tín (`Featured Vintage Shops`):**
  - Thẻ tiệm nổi bật hiển thị Avatar, Shop Name, Trust Score (sao vàng), và 3 hình ảnh sản phẩm tiêu biểu. Nhấn vào mở `M-US-03`.
- **Lưới Hàng Mới Lên Kệ (`New Approved Arrivals Grid`):**
  - Bố cục lưới 2 cột (`StaggeredGrid` / `GridView.builder`), tích hợp `ProductCard`, phân trang cuộn vô tận (`infinite scroll`).

### 2.2. `M-HM-02: Curated Collections & Featured Stores`
- Hiển thị danh sách các tiệm đồ si tuyển chọn theo chủ đề: *"Áo dạ mùa đông 90s"*, *"Đồng hồ cơ Thụy Sỹ cổ điển"*, *"Denim Nhật Bản bãi tuyển"*.
- Bộ lọc nhanh theo khu vực (TP. Hồ Chí Minh, Hà Nội, Toàn quốc).

### 2.3. `M-DS-01: Category & Brand Directory` (Tab 2 Root)
- Chia 2 Cột hoặc 2 Tab:
  - Cột/Tab 1: **Cây Danh mục Cấp cha & Cấp con** (dữ liệu từ `/api/v1/catalog/taxonomy`). Khi nhấn vào danh mục cha, tự mở rộng các danh mục con.
  - Cột/Tab 2: **Danh mục Thương hiệu** (A-Z, tìm kiếm nhanh tên thương hiệu như Levi's, Seiko, Burberry, Schott NYC...).

### 2.4. `M-DS-02: Search & Filter Results Screen`
- Thanh tìm kiếm từ khóa với các từ khóa thịnh hành (Lưu ý: Tính năng lưu lịch sử tìm kiếm cục bộ qua `SharedPreferences` được hoãn lại để hoàn thiện ở gói `P7-12: Polish & Final Review` theo quyết định PO).
- Thanh công cụ phụ:
  - Nút mở `M-DS-03` (kèm số lượng bộ lọc đang kích hoạt).
  - Thanh cuộn nhanh các chip lọc: `Giá cố định`, `Đấu giá`, `Độ mới 95%+`, `Freeship`.
- Lưới sản phẩm:
  - Trạng thái trống (`EmptyStateView`) khi không tìm thấy kết quả phù hợp, gợi ý từ khóa mở rộng.
  - Tải trang mượt mà (Skeleton loader khi đang tìm kiếm).

### 2.5. `M-DS-03: Multi-Filter Bottom Sheet`
- Bộ lọc mở rộng trượt từ dưới lên (`ModalBottomSheet`):
  - **Khoảng giá (`Price Range`):** Thanh trượt 2 đầu (`RangeSlider`) hoặc 2 ô nhập số tiền `Từ ... đ` đến `Đến ... đ` (tự động validate `min_price <= max_price`).
  - **Tình trạng sản phẩm (`Condition`):** Hộp chọn nhiều lựa chọn (chuẩn hóa đủ 5 mức: `NEW_WITH_TAGS`, `LIKE_NEW`, `GOOD`, `FAIR`, `VINTAGE_WORN`).
  - **Loại hình giao dịch (`Listing Type`):** Tất cả, Mua ngay (`FIXED_PRICE`), Đấu giá (`AUCTION`).
  - **Sắp xếp (`Sort`):** Mới nhất (`newest`), Giá tăng dần (`price_asc`), Giá giảm dần (`price_desc`), Yêu thích nhiều nhất (`popular`).
- Nút `[Thiết lập lại]` (xóa mọi bộ lọc) và `[Áp dụng (X sản phẩm)]`.

---

## 3. Architecture & State Management (MVVM Pattern)
- **Models:** `HomeFeedModel`, `CategoryModel`, `BrandModel`, `ProductSummaryModel`, `PaginationMetaModel`, `ProductFilterQuery`.
- **Repository (Kiến trúc gộp được PO phê duyệt):** `HomeCatalogRepository` (`mobile/lib/features/catalog/repositories/home_catalog_repository.dart`) đảm nhận toàn bộ API Trang chủ, Taxonomy và Product Discovery.
- **ViewModels (`BaseViewModel` / Riverpod):**
  - `HomeViewModel`: Quản lý nạp dữ liệu trang chủ, kéo để làm mới (`RefreshIndicator`).
  - `CatalogSearchViewModel`: Quản lý từ khóa, taxonomy danh mục & thương hiệu, trạng thái bộ lọc đa tiêu chí, phân trang cuộn vô tận (`per_page = 12`).

---

## 4. API Endpoints Utilized
- `GET /api/v1/home`
- `GET /api/v1/catalog/taxonomy`
- `GET /api/v1/products` (hỗ trợ các tham số lọc: `q`, `category_id`, `brand_id`, `listing_type`, `condition`, `min_price`, `max_price`, `sort` [`newest`, `price_asc`, `price_desc`, `popular`], `page`, `per_page`)
- `POST /api/v1/products/{id}/favorite`

---

## 5. Acceptance Criteria (`Tiêu Chí Nghiệm Thu P7-05`)
- [x] **AC-P705-01:** Màn hình Trang chủ tải dữ liệu mượt mà từ `/api/v1/home`, hỗ trợ kéo để làm mới (`HomeScreen` M-HM-01).
- [x] **AC-P705-02:** Cây danh mục phân cấp cha - con hiển thị đầy đủ và lọc đúng sản phẩm thuộc cả danh mục con (`CategoryTaxonomyScreen` M-DS-01).
- [x] **AC-P705-03:** Tìm kiếm từ khóa và Bottom Sheet bộ lọc kết hợp chuẩn xác, phân trang không bị giật lag (`ProductSearchScreen` M-DS-02, `ProductFilterBottomSheet` M-DS-03).
- [x] **AC-P705-04:** Viết đầy đủ Unit & Widget tests cho ViewModels và 5 màn hình trong `test/features/home_catalog_and_search_test.dart` đạt **100% PASS** (12/12 test scenarios passing, toàn bộ 57/57 mobile tests PASS).
