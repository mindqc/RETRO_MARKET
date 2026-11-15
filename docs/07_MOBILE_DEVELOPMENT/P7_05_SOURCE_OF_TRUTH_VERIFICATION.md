# P7-05: SOURCE OF TRUTH VERIFICATION & EVIDENCE COLLECTION REPORT

- **Project Codename:** `RETRO MARKET`
- **App Brand Name:** `izithrift`
- **Document ID:** `DOC-P705-SOT-VERIFICATION`
- **Target Task:** `Phase 07 – Task P7-05: Home, Catalog & Search`
- **Auditor:** Antigravity IDE Agent
- **Recipient:** Product Owner (PO) & Gemini Handoff Session
- **Verification Date:** `2026-11-15`
- **Operating Rule:** STRICT READ-ONLY AUDIT. Không sửa code, không sửa migrations, không sửa test, không sửa đặc tả.

---

## 1. Executive Summary

Báo cáo này cung cấp bằng chứng kỹ thuật trực tiếp từ mã nguồn và tài liệu trong repository để đối chiếu 4 điểm không nhất quán do Gemini phát hiện, đồng thời xác nhận tính sẵn sàng của đặc tả P7-06.

| Vấn đề kiểm tra | Tình trạng thực tế trong Repository | Đánh giá | Trạng thái xác minh |
| :--- | :--- | :--- | :---: |
| **1. Product Condition (4 hay 5 mức?)** | - Backend Enum & FormRequests: **5 mức** (`NEW_WITH_TAGS`, `LIKE_NEW`, `GOOD`, `FAIR`, `VINTAGE_WORN`).<br>- Mobile UI & Badges: **5 mức**.<br>- DB Migration Constraint (`chk_products_condition`): **Chỉ 4 mức** (thiếu `NEW_WITH_TAGS`).<br>- Tài liệu P1, P4, P5, P7-05 Spec: **Chỉ 4 mức**. | Xung đột tiềm ẩn giữa DB Check Constraint và Backend Enum / Mobile UI. Cần PO quyết định chuẩn hóa 4 hay 5 mức. | `VERIFIED` (Conflict Found) |
| **2. Repo / ViewModel Architecture** | - Đặc tả P7-05: 2 Repositories + 3 ViewModels.<br>- Thực tế Mobile: 1 Repository (`HomeCatalogRepository`) + 2 ViewModels (`HomeViewModel`, `CatalogSearchViewModel`). | Không mất chức năng, tuân thủ MVVM và phân tách tầng, nhưng gộp Taxonomy vào chung Search ViewModel. | `ACCEPTABLE` |
| **3. Search History (SharedPreferences)** | - `pubspec.yaml` có thư viện `shared_preferences`.<br>- Trong module Catalog/Search: **Hoàn toàn chưa triển khai** logic đọc/ghi lịch sử tìm kiếm và UI Recent Searches. | Thiếu chức năng UX so với mục 2.4 của đặc tả P7-05. | `NOT_IMPLEMENTED` |
| **4. API Sorting (`sort` vs `sort_by`)** | - Backend (`ProductSearchRequest`, `ProductDiscoveryService`, Feature Tests): Sử dụng tham số `sort` (`newest`, `price_asc`, `price_desc`, `popular`).<br>- Mobile (`ProductFilterQuery`, BottomSheet): Gửi đúng tham số `sort`.<br>- Đặc tả P7-05 text: Ghi nhầm `sort_by, sort_direction`. | Backend và Mobile **100% đồng nhất** trong mã nguồn thực tế. Lỗi chỉ nằm ở phần text của tài liệu đặc tả P7-05. | `VERIFIED` (In Sync in Code) |
| **P7-06 Specification** | File `docs/07_MOBILE_DEVELOPMENT/P7_06_PRODUCT_DETAIL_AND_STOREFRONT.md` **đã tồn tại** đầy đủ (6,507 bytes, 97 dòng, 4 màn hình: M-PD-01, M-PD-02, M-DS-04, M-US-03). | Sẵn sàng triển khai khi P7-05 được PO nghiệm thu. | `VERIFIED` |

---

## 2. Repository & Source Files Inspected

Dưới đây là danh sách các tệp tin nguồn được đọc trực tiếp để thu thập bằng chứng:

1. **Governance & Requirements:**
   - `docs/01_REQUIREMENTS_ANALYSIS/06_BUSINESS_RULES.md`
   - `docs/01_REQUIREMENTS_ANALYSIS/09_REQUIREMENTS_TRACEABILITY.md`
   - `docs/04_SYSTEM_ARCHITECTURE_AND_DB/02_DATABASE_DESIGN/DB_01_CORE_SCHEMA.md`
   - `docs/05_BACKEND_FOUNDATION/P5_03_CONSTRAINTS_INTEGRITY.md`
   - `docs/06_BACKEND_DEVELOPMENT/P6_04_PRODUCT_AND_MODERATION.md`
   - `docs/07_MOBILE_DEVELOPMENT/P7_05_HOME_CATALOG_AND_SEARCH.md`
   - `docs/07_MOBILE_DEVELOPMENT/P7_06_PRODUCT_DETAIL_AND_STOREFRONT.md`
2. **Backend Phase 06:**
   - `backend/app/Enums/ProductCondition.php`
   - `backend/app/Http/Requests/Api/V1/Product/ProductSearchRequest.php`
   - `backend/app/Http/Requests/Api/V1/Product/StoreProductRequest.php`
   - `backend/app/Http/Requests/Api/V1/Product/UpdateProductRequest.php`
   - `backend/app/Services/Product/ProductDiscoveryService.php`
   - `backend/app/Http/Controllers/Api/V1/ProductController.php`
   - `backend/database/migrations/2026_11_14_000006_add_tier6_database_constraints_and_partial_indexes.php`
   - `backend/tests/Feature/Api/V1/ProductAndModerationTest.php`
3. **Mobile Phase 07:**
   - `mobile/lib/core/widgets/condition_badge.dart`
   - `mobile/lib/features/catalog/models/product_filter_query.dart`
   - `mobile/lib/features/catalog/models/product_summary_model.dart`
   - `mobile/lib/features/catalog/models/category_model.dart`
   - `mobile/lib/features/catalog/models/brand_model.dart`
   - `mobile/lib/features/catalog/models/taxonomy_model.dart`
   - `mobile/lib/features/catalog/repositories/home_catalog_repository.dart`
   - `mobile/lib/features/home/viewmodels/home_view_model.dart`
   - `mobile/lib/features/catalog/viewmodels/catalog_search_view_model.dart`
   - `mobile/lib/features/home/screens/home_screen.dart`
   - `mobile/lib/features/home/screens/featured_sellers_and_collections_screen.dart`
   - `mobile/lib/features/catalog/screens/category_taxonomy_screen.dart`
   - `mobile/lib/features/catalog/screens/product_search_screen.dart`
   - `mobile/lib/features/catalog/widgets/product_filter_bottom_sheet.dart`
   - `mobile/test/features/home_catalog_and_search_test.dart`

---

## 3. Product Condition Verification (4 hay 5 mức?)

### 3.1. Bằng chứng trong Backend

#### A. Enum `ProductCondition`
- **File:** `backend/app/Enums/ProductCondition.php` (Dòng 5–22)
- **Code thực tế:**
  ```php
  enum ProductCondition: string
  {
      case NEW_WITH_TAGS = 'NEW_WITH_TAGS';
      case LIKE_NEW = 'LIKE_NEW';
      case GOOD = 'GOOD';
      case FAIR = 'FAIR';
      case VINTAGE_WORN = 'VINTAGE_WORN';

      public function label(): string
      {
          return match ($this) {
              self::NEW_WITH_TAGS => 'Mới nguyên tem / Chưa qua sử dụng',
              self::LIKE_NEW => 'Như mới (95% - 99%)',
              self::GOOD => 'Tốt (Có dấu hiệu sử dụng nhẹ)',
              self::FAIR => 'Trung bình (Có khuyết điểm rõ)',
              self::VINTAGE_WORN => 'Vintage sờn rách tự nhiên (Đặc thù)',
          };
      }
  }
  ```
- **Nhận định:** Backend Enum khai báo **5 mức**.

#### B. Form Requests Validation
- **File:** `backend/app/Http/Requests/Api/V1/Product/StoreProductRequest.php` (Dòng 21):
  ```php
  'condition' => ['required', 'string', 'in:NEW_WITH_TAGS,LIKE_NEW,GOOD,FAIR,VINTAGE_WORN'],
  ```
- **File:** `backend/app/Http/Requests/Api/V1/Product/ProductSearchRequest.php` (Dòng 21):
  ```php
  'condition' => ['nullable', 'string', 'in:NEW_WITH_TAGS,LIKE_NEW,GOOD,FAIR,VINTAGE_WORN'],
  ```
- **File:** `backend/app/Http/Requests/Api/V1/Product/UpdateProductRequest.php` (Dòng 21):
  ```php
  'condition' => ['sometimes', 'string', 'in:NEW_WITH_TAGS,LIKE_NEW,GOOD,FAIR,VINTAGE_WORN'],
  ```
- **Nhận định:** Toàn bộ API Request validation tầng Laravel chấp nhận **5 mức**.

#### C. Database Migration & CHECK Constraint (PostgreSQL 18)
- **File:** `backend/database/migrations/2026_11_14_000006_add_tier6_database_constraints_and_partial_indexes.php` (Dòng 26):
  ```php
  DB::statement("ALTER TABLE products ADD CONSTRAINT chk_products_condition CHECK (condition IN ('LIKE_NEW', 'GOOD', 'FAIR', 'VINTAGE_WORN'));");
  ```
- **Tài liệu DB thiết kế:** `docs/04_SYSTEM_ARCHITECTURE_AND_DB/02_DATABASE_DESIGN/DB_01_CORE_SCHEMA.md` (Dòng 145 & 331):
  `CHECK (condition IN ('LIKE_NEW', 'GOOD', 'FAIR', 'VINTAGE_WORN'))`
- **Nhận định:** Database constraint **CHỈ CHẤP NHẬN 4 MỨC** (`LIKE_NEW`, `GOOD`, `FAIR`, `VINTAGE_WORN`), **KHÔNG CÓ** `NEW_WITH_TAGS`!
- **Rủi ro kỹ thuật:** Nếu người dùng tạo sản phẩm với `NEW_WITH_TAGS`, Laravel FormRequest cho qua nhưng PostgreSQL sẽ ném lỗi:
  `SQLSTATE[23514]: Check violation: 7 ERROR: new row for relation "products" violates check constraint "chk_products_condition"`

### 3.2. Bằng chứng trong Mobile

#### A. Widget `ConditionBadge`
- **File:** `mobile/lib/core/widgets/condition_badge.dart` (Dòng 43–81)
- **Code thực tế:**
  Hỗ trợ 5 trường hợp:
  - `'NEW_WITH_TAGS'` -> Nhãn: `"Mới còn tag"`
  - `'LIKE_NEW'` -> Nhãn: `"Như mới (99%)"`
  - `'GOOD'` -> Nhãn: `"Tốt (90%)"`
  - `'FAIR'` -> Nhãn: `"Khá (80%)"`
  - `'VINTAGE_WORN'` -> Nhãn: `"Dấu ấn vintage"`

#### B. Bottom Sheet Bộ Lọc (`ProductFilterBottomSheet`)
- **File:** `mobile/lib/features/catalog/widgets/product_filter_bottom_sheet.dart` (Dòng 296–327)
- **Code thực tế:**
  Hiển thị ChoiceChips cho cả 5 lựa chọn:
  - `"Mới nguyên tag (100%)"` (`NEW_WITH_TAGS`)
  - `"Như mới (95%+)"` (`LIKE_NEW`)
  - `"Tốt (85%-90%)"` (`GOOD`)
  - `"Chấp nhận được (70%-80%)"` (`FAIR`)
  - `"Vintage Worn (Cũ bạc đẹp)"` (`VINTAGE_WORN`)

### 3.3. Bằng chứng trong Tài liệu Đặc tả
- `docs/07_MOBILE_DEVELOPMENT/P7_05_HOME_CATALOG_AND_SEARCH.md` (Dòng 58):
  `- Tình trạng sản phẩm (Condition): Hộp chọn nhiều lựa chọn (Like New, Good, Fair, Vintage Worn).` (Chỉ liệt kê 4 mức).
- `docs/07_MOBILE_DEVELOPMENT/P7_02_DESIGN_SYSTEM_AND_COMPONENTS.md` (Dòng 41):
  `- Nhận giá trị ProductCondition (NEW_WITH_TAGS, LIKE_NEW, GOOD, FAIR, VINTAGE_WORN).` (Liệt kê 5 mức).

### 3.4. Kết luận Vấn đề 1
- **Backend Code & Mobile Code:** Thống nhất **5 mức**.
- **Database Migration & DB Documentation & P7-05 Spec:** Chỉ có **4 mức** (thiếu `NEW_WITH_TAGS`).
- **Sai lệch chính:** Nằm giữa Database Constraint `chk_products_condition` (4 giá trị) và Laravel Enum `ProductCondition` (5 giá trị).

---

## 4. Repository & ViewModel Architecture Verification

### 4.1. Đối chiếu Danh sách Class

| Thành phần theo Đặc tả P7-05 | File Implementation thực tế | Trạng thái |
| :--- | :--- | :---: |
| `CatalogRepository` | Gom vào `mobile/lib/features/catalog/repositories/home_catalog_repository.dart` (`HomeCatalogRepository`) | `VERIFIED` (Merged) |
| `ProductDiscoveryRepository` | Gom vào `mobile/lib/features/catalog/repositories/home_catalog_repository.dart` (`HomeCatalogRepository`) | `VERIFIED` (Merged) |
| `HomeFeedViewModel` | Đổi tên thành `mobile/lib/features/home/viewmodels/home_view_model.dart` (`HomeViewModel`) | `VERIFIED` |
| `TaxonomyViewModel` | Gom vào `mobile/lib/features/catalog/viewmodels/catalog_search_view_model.dart` (`CatalogSearchViewModel`) | `VERIFIED` (Merged) |
| `SearchFilterViewModel` | Gom vào `mobile/lib/features/catalog/viewmodels/catalog_search_view_model.dart` (`CatalogSearchViewModel`) | `VERIFIED` (Merged) |

### 4.2. Kiểm tra Phân Tách Trách Nhiệm (Separation of Concerns)
1. **Tầng Data Access (Repository):**
   - `HomeCatalogRepository` đóng gói toàn bộ lời gọi API qua `DioClient`: `fetchHomeFeed()`, `fetchTaxonomy()`, `searchProducts()`, `toggleFavorite()`.
   - Views không bao giờ gọi trực tiếp `DioClient`.
2. **Tầng State Management (ViewModel):**
   - `HomeViewModel` (kế thừa `BaseViewModel<HomeFeedModel>`): Quản lý feed trang chủ, pull-to-refresh, và kiểm tra đăng nhập khi yêu thích sản phẩm (`DEC-01`).
   - `CatalogSearchViewModel` (kế thừa `BaseViewModel<List<ProductSummaryModel>>`): Quản lý query lọc, phân trang vô tận `loadNextPage()`, chặn request nếu `minPrice > maxPrice`, và nạp taxonomy.
3. **Riverpod Providers:**
   - Khai báo độc lập: `homeCatalogRepositoryProvider`, `homeViewModelProvider`, `catalogSearchViewModelProvider`.
   - Đã loại bỏ việc kích hoạt network request tự động trong constructor provider để bảo đảm kiểm thử cô lập (không gây timeout `pumpAndSettle`).
4. **Nhược điểm của việc gộp Taxonomy vào Search ViewModel:**
   - `CatalogSearchViewModel` có generic type là `List<ProductSummaryModel>`, trong khi `_taxonomy` (`TaxonomyModel?`) là một property phụ. Khi taxonomy được nạp hoặc cập nhật, ViewModel gọi `notifyListeners()`, có thể kích hoạt build lại các widget đang lắng nghe danh sách sản phẩm.
5. **Chức năng có bị mất không?**
   - **Không.** Toàn bộ chức năng nạp danh mục, mở rộng cây cha - con, chọn thương hiệu, tìm kiếm, phân trang và toggle favorite đều hoạt động đầy đủ.

### 4.3. Kết luận Vấn đề 2
- **Trạng thái:** `ACCEPTABLE`. Cấu trúc gộp 1 Repo + 2 ViewModels vẫn tuân thủ đầy đủ mô hình MVVM, phân tách tầng sạch sẽ, hoạt động ổn định và vượt qua 100% test suite.

---

## 5. Search History Verification (SharedPreferences)

### 5.1. Bằng chứng Mã Nguồn
- **Đặc tả P7-05 (Mục 2.4, Dòng 47):**
  `"Thanh tìm kiếm từ khóa với lịch sử tìm kiếm gần đây (SharedPreferences) và các từ khóa thịnh hành."`
- **File `mobile/pubspec.yaml` (Dòng 39):**
  `shared_preferences: ^2.5.4` (Thư viện đã có sẵn trong dự án).
- **Kiểm tra mã nguồn `mobile/lib/features/catalog/`:**
  - Không có bất kỳ import `shared_preferences` nào trong thư mục `catalog/`.
  - Không có SharedPreferences key nào cho `search_history`.
  - Không có logic lưu từ khóa khi submit tìm kiếm.
  - Không có logic đọc danh sách lịch sử hay xóa lịch sử.
- **Kiểm tra màn hình `M-DS-02` (`product_search_screen.dart`):**
  - Thanh tìm kiếm chỉ có TextField và nút xóa text trong ô nhập (`onPressed: () => _searchController.clear()`).
  - Khi chưa nhập từ khóa, màn hình hiển thị danh sách sản phẩm mặc định hoặc trạng thái trống, hoàn toàn không có danh sách/chip "Tìm kiếm gần đây" hay "Từ khóa thịnh hành".
- **Kiểm tra Unit/Widget Tests:**
  - File `home_catalog_and_search_test.dart` không có test case nào cho Search History.

### 5.2. Đánh giá Mức Độ Ảnh Hưởng
- Chức năng tìm kiếm từ khóa chính (`search by keyword`) vẫn hoạt động 100% qua API backend.
- Việc thiếu Search History không làm gãy luồng tìm kiếm, nhưng là tính năng UX bị thiếu so với đặc tả.

### 5.3. Kết luận Vấn đề 3
- **Trạng thái:** `NOT_IMPLEMENTED`.

---

## 6. API Sorting Verification (`sort` hay `sort_by` + `sort_direction`?)

### 6.1. Bằng chứng trong Backend

#### A. Form Request
- **File:** `backend/app/Http/Requests/Api/V1/Product/ProductSearchRequest.php` (Dòng 25)
- **Code thực tế:**
  ```php
  'sort' => ['nullable', 'string', 'in:newest,price_asc,price_desc,popular'],
  ```
- **Nhận định:** Backend FormRequest chỉ khai báo và chấp nhận tham số `sort`. Hoàn toàn không có `sort_by` hay `sort_direction`.

#### B. Service Logic
- **File:** `backend/app/Services/Product/ProductDiscoveryService.php` (Dòng 70–75)
- **Code thực tế:**
  ```php
  match ($filters['sort'] ?? 'newest') {
      'price_asc' => $query->orderBy('price', 'asc')->orderByDesc('id'),
      'price_desc' => $query->orderBy('price', 'desc')->orderByDesc('id'),
      'popular' => $query->orderByDesc('favorite_count')->orderByDesc('id'),
      default => $query->orderByDesc('approved_at')->orderByDesc('id'),
  };
  ```
- **Nhận định:** Service chỉ đọc `$filters['sort']`.

#### C. Backend Feature Tests
- **File:** `backend/tests/Feature/Api/V1/ProductAndModerationTest.php` (Dòng 75, 83)
- **Code thực tế:**
  ```php
  $sortAscResponse = $this->getJson('/api/v1/products?sort=price_asc');
  ...
  $sortDescResponse = $this->getJson('/api/v1/products?sort=price_desc');
  ```
- **Nhận định:** Feature Test của Backend kiểm thử trực tiếp tham số `sort`.

### 6.2. Bằng chứng trong Mobile

#### A. Model Query
- **File:** `mobile/lib/features/catalog/models/product_filter_query.dart` (Dòng 13, 114–116)
- **Code thực tế:**
  ```dart
  final String? sort; // 'newest', 'price_asc', 'price_desc', 'popular'
  ...
  if (sort != null && sort!.isNotEmpty) {
    params['sort'] = sort;
  }
  ```

#### B. UI Filter Bottom Sheet
- **File:** `mobile/lib/features/catalog/widgets/product_filter_bottom_sheet.dart` (Dòng 344–368)
- **Code thực tế:**
  Gán trực tiếp các giá trị `newest`, `price_asc`, `price_desc`, `popular` vào `_sort`.

#### C. Mobile Unit Test
- **File:** `mobile/test/features/home_catalog_and_search_test.dart` (Dòng 364–376)
- **Code thực tế:**
  ```dart
  expect(params['sort'], equals('price_asc'));
  ```

### 6.3. Bằng chứng trong Đặc tả P7-05
- **File:** `docs/07_MOBILE_DEVELOPMENT/P7_05_HOME_CATALOG_AND_SEARCH.md` (Dòng 78):
  `GET /api/v1/products (hỗ trợ các tham số lọc: q, category_id, brand_id, listing_type, condition, min_price, max_price, sort_by, sort_direction, page, per_page)`
- **Nhận định:** Dòng 78 trong tài liệu đặc tả ghi nhầm `sort_by, sort_direction`. Trong khi đó, Backend đã hoàn thiện từ Phase 06 chỉ dùng `sort`.

### 6.4. Kết luận Vấn đề 4
- **Backend Code và Mobile Code:** **100% ĐỒNG NHẤT** khi cùng dùng `sort` (`newest`, `price_asc`, `price_desc`, `popular`).
- **Sai lệch:** Nằm ở câu chữ trong tài liệu đặc tả P7-05.

---

## 7. P7-06 Specification Availability

- **File Path:** `docs/07_MOBILE_DEVELOPMENT/P7_06_PRODUCT_DETAIL_AND_STOREFRONT.md`
- **Trạng thái tệp:** `TỒN TẠI (EXISTS)`
- **Kích thước:** `6,507 bytes` (97 dòng)
- **Metadata:**
  - Document ID: `DOC-P706-PRODUCT-DETAIL-STOREFRONT`
  - Version: `1.0.0`
  - Status: `PLANNED / WAITING FOR PO APPROVAL`
  - Dependencies: `P7-01, P7-02, P7-03, P7-05 Completed`
- **Phạm vi 4 màn hình được định nghĩa:**
  1. `M-PD-01`: Chi tiết Sản phẩm Giá cố định (`Product Detail Screen`).
  2. `M-PD-02`: Bảng Thông tin Lỗi & Bằng chứng Kiểm định (`Defect & Condition Card`).
  3. `M-DS-04`: Trình xem ảnh phóng to toàn màn hình (`Full-Screen Zoom Viewer` với `InteractiveViewer`).
  4. `M-US-03`: Trang Cửa hàng Công khai của Tiệm (`Public Seller Storefront Screen`).
- **API Endpoints sử dụng:**
  - `GET /api/v1/products/{id}`
  - `POST /api/v1/products/{id}/favorite`
  - `POST /api/v1/cart/items`
  - `GET /api/v1/sellers/{id}`
  - `POST /api/v1/sellers/{id}/follow`
  - `GET /api/v1/sellers/{id}/reviews`

---

## 8. Conflicts Between Specification and Implementation

| STT | Vị trí đặc tả | Nội dung đặc tả | Thực tế Backend Phase 06 | Thực tế Mobile Phase 07 | Bản chất xung đột |
| :---: | :--- | :--- | :--- | :--- | :--- |
| 1 | `P7_05...md` Dòng 58 | 4 mức condition (`Like New, Good, Fair, Vintage Worn`) | - Enum: 5 mức<br>- Requests: 5 mức<br>- DB Migration: 4 mức | UI & Badge: 5 mức | Xung đột kỹ thuật giữa Database Constraint (4 mức) và Backend Enum / Mobile (5 mức). |
| 2 | `P7_05...md` Dòng 66-72 | 2 Repositories + 3 ViewModels | 2 Controllers (`CatalogController`, `ProductController`) | 1 Repository + 2 ViewModels | Gom nhóm cấu trúc để giảm phân mảnh và tránh phụ thuộc chéo. |
| 3 | `P7_05...md` Dòng 47 | Thanh tìm kiếm có lưu lịch sử (`SharedPreferences`) | N/A (Client-side feature) | Chưa cài đặt logic đọc/ghi lịch sử tìm kiếm | Thiếu tính năng UX so với mô tả. |
| 4 | `P7_05...md` Dòng 78 | Tham số API: `sort_by, sort_direction` | Tham số API: `sort` (`newest`, `price_asc`, `price_desc`, `popular`) | Tham số gửi đi: `sort` | Lỗi văn bản trong tài liệu đặc tả; mã nguồn Backend và Mobile đã khớp 100%. |

---

## 9. Technical Risks & Recommendations

### Rủi ro 1: Vi phạm Check Constraint Database khi chọn `NEW_WITH_TAGS`
- **Mức độ:** `CAO (High)`
- **Mô tả:** Mobile gửi `condition = 'NEW_WITH_TAGS'` -> Backend Laravel validate thành công -> PostgreSQL chặn vì `chk_products_condition` chỉ có `('LIKE_NEW', 'GOOD', 'FAIR', 'VINTAGE_WORN')` -> Gây lỗi HTTP 500 khi người bán đăng đồ mới nguyên tag.
- **Khuyến nghị:** PO cần phê duyệt phương án cho phép 5 mức hay 4 mức. Nếu chọn 5 mức, cần bổ sung migration sửa `chk_products_condition`.

### Rủi ro 2: Thiếu Search History
- **Mức độ:** `THẤP (Low)`
- **Mô tả:** Người dùng không xem lại được từ khóa đã tìm kiếm trước đó.
- **Khuyến nghị:** Bổ sung một Service nhỏ `SearchHistoryService` sử dụng `SharedPreferences` ở đầu Phase 07 (hoặc trong P7-06/P7-07) mà không ảnh hưởng đến kiến trúc cốt lõi.

### Rủi ro 3: Lỗi chính tả trong tài liệu đặc tả P7-05 (`sort_by` vs `sort`)
- **Mức độ:** `RẤT THẤP (Trivial)`
- **Khuyến nghị:** Cập nhật lại câu chữ tại Dòng 78 trong `P7_05_HOME_CATALOG_AND_SEARCH.md` để ghi nhận tham số `sort` cho đồng nhất với Backend Phase 06.

---

## 10. PO Decisions Required (Danh Sách Quyết Định Cần PO Phê Duyệt)

Kính đề nghị Product Owner xem xét và phê duyệt 3 quyết định chính thức:

### Quyết định 1: Chuẩn hóa số mức Condition (4 hay 5 mức?)
- **Lựa chọn 1A (Khuyến nghị):** **Chấp nhận 5 mức** (`NEW_WITH_TAGS`, `LIKE_NEW`, `GOOD`, `FAIR`, `VINTAGE_WORN`).
  - *Lý do:* Chợ đồ vintage / secondhand thực tế vẫn có các kiện hàng si bãi còn nguyên tag (Deadstock / New Old Stock). Backend Enum và Mobile UI đã làm sẵn 5 mức.
  - *Hành động kỹ thuật kéo theo:* Cần tạo một migration nhỏ trong Backend để cập nhật constraint `chk_products_condition` cho phép thêm `NEW_WITH_TAGS`.
- **Lựa chọn 1B:** **Chốt cứng 4 mức** (`LIKE_NEW`, `GOOD`, `FAIR`, `VINTAGE_WORN`).
  - *Lý do:* Đúng nguyên bản định nghĩa đồ si cũ ban đầu của Phase 04/05.
  - *Hành động kỹ thuật kéo theo:* Xóa `NEW_WITH_TAGS` khỏi Enum PHP, FormRequests và xóa lựa chọn này khỏi Mobile UI / Badge.

### Quyết định 2: Chấp thuận cấu trúc Repository & ViewModel gộp của P7-05
- **Lựa chọn 2A (Khuyến nghị):** Phê duyệt cấu trúc hiện tại (`HomeCatalogRepository`, `HomeViewModel`, `CatalogSearchViewModel`) là `ACCEPTABLE`, không yêu cầu refactor vì toàn bộ nghiệp vụ và kiểm thử đã đạt 100%.
- **Lựa chọn 2B:** Yêu cầu refactor tách thành đúng 2 Repositories và 3 ViewModels theo tên gọi ban đầu của đặc tả.

### Quyết định 3: Xử lý chức năng Search History (SharedPreferences)
- **Lựa chọn 3A (Khuyến nghị):** Tạm thời chấp nhận nghiệm thu P7-05 để tiếp tục tiến độ sang P7-06; tạo một sub-task nhỏ bổ sung Search History trong đợt Polish UI/UX.
- **Lựa chọn 3B:** Yêu cầu hoàn thiện ngay Search History với SharedPreferences trước khi ký duyệt nghiệm thu P7-05.

---

## 11. Final Verification Status (Bảng Tổng Kết)

| Hạng mục | Backend Phase 06 | Mobile Phase 07 | Specification P7-05 | Kết luận Kỹ Thuật | Trạng thái |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **Product Condition** | Enum & Request: 5 mức.<br>DB Constraint: 4 mức. | UI & Badge: 5 mức. | Ghi 4 mức ở mục 2.5; P7-02 ghi 5 mức. | Xung đột giữa DB Constraint và Enum/Mobile. | `NEEDS_PO_CONFIRMATION` |
| **Repository / ViewModel** | 2 Controllers API | 1 Repo + 2 ViewModels | 2 Repos + 3 ViewModels | Kiến trúc gộp hoạt động tốt, không mất tính năng. | `ACCEPTABLE` |
| **Search History** | N/A | Chưa triển khai | Yêu cầu SharedPreferences | Thiếu chức năng UX. | `NOT_IMPLEMENTED` |
| **API Sorting** | Nhận `sort` (`newest`, `price_asc`, `price_desc`, `popular`) | Gửi `sort` | Ghi nhầm `sort_by, sort_direction` | Mã nguồn Backend & Mobile đã khớp 100%. | `VERIFIED` |
| **P7-06 Spec Availability** | N/A | N/A | Đã có sẵn file `P7_06...md` (97 dòng) | Đầy đủ đặc tả cho 4 màn hình chi tiết & tiệm. | `VERIFIED` |

---
*Báo cáo được khởi tạo tự động dựa trên kiểm tra mã nguồn thực tế tại commit hiện tại.*
