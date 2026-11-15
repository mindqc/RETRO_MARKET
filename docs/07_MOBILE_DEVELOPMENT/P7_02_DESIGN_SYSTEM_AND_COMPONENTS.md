# P7-02: DESIGN SYSTEM, WARM THRIFT TOKENS, SEASONAL OVERLAY & SHARED UI COMPONENTS SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P702-DESIGN-SYSTEM-COMPONENTS`
- **Version:** `1.0.0`
- **Status:** `DONE (100% PASS)`
- **Phase:** `Phase 07 – Task P7-02`
- **Dependencies:** `P7-01 Completed`

---

## 1. Objective (`Mục Tiêu`)
Hiện thực hóa toàn diện hệ thống thiết kế giao diện đồ cũ ấm áp (`Warm Editorial Archive`) và chủ đề Giáng sinh ấm áp (`Cozy Christmas`) theo đúng đặc tả Phase 03 (`COLOR_SYSTEM.md`, `TYPOGRAPHY.md`, `DESIGN_TOKENS.md`, `COMPONENT_LIBRARY.md`). Xây dựng thư viện Widget dùng chung (`shared widgets`) phục vụ 52 màn hình Mobile, bao gồm huy hiệu tình trạng đồ cũ, huy hiệu xác minh, đồng hồ đếm ngược đồng bộ thời gian máy chủ, thẻ chiết tính phí bảo vệ người mua `DEC-04`, và các trạng thái nạp dữ liệu/lỗi/trống.

---

## 2. Scope & Technical Specifications (`Phạm Vi & Đặc Tả Kỹ Thuật`)

### 2.1. Color Tokens (`Bảng Màu Chuẩn Hóa`)
- `Warm Cream` (Nền chính): `#F4EBDD`
- `Soft Beige` (Nền thẻ phụ / input): `#E9DDCB`
- `Forest Green` (Thương hiệu chính / Nút Primary): `#294638`
- `Burgundy` (Đấu giá / Điểm nhấn / Hủy / Báo cáo): `#873A43`
- `Vintage Brown` (Viền thẻ / Tiêu đề phụ): `#84664C`
- `Muted Gold` (Huy hiệu VIP / Tiêu điểm Giáng sinh): `#C5A66B`
- `Dark Charcoal` (Chữ chính / Đọc nội dung): `#302D2A`
- `Border Soft`: `rgba(132, 102, 76, 0.25)`

### 2.2. Typography Tokens (`Phông Chữ & Thứ Bậc Văn Bản`)
- **Brand Logo & Điểm nhấn hoài cổ:** `Wichita Vintage` (fallback `Fraunces`).
- **Tiêu đề tiếng Việt có dấu:** `Fraunces` (Serif cổ điển, hỗ trợ đầy đủ Unicode NFC).
- **Nội dung, Nút bấm, Bảng giá, Nhãn thông số:** `Be Vietnam Pro` (Sans-serif hiện đại, tối ưu cho giao diện tiếng Việt).

### 2.3. Seasonal Theme Provider & Christmas Overlay (`NFR-UX-02`)
- Xây dựng `SeasonalThemeNotifier` (`Provider`) quản lý trạng thái bật/tắt trang trí Giáng sinh:
  - Khởi tạo giá trị từ `UserProfile.seasonal_decor_enabled` khi đăng nhập hoặc cấu hình `SharedPreferences` cho Guest.
  - Khi bật: Hiển thị dải ruy-băng / dây thông tuyết nhẹ nhàng ở App Bar trên cùng và góc thẻ sản phẩm nổi bật mà không làm che khuất nội dung hay ảnh hưởng đến độ mượt mà (60fps).
  - Có thể chuyển đổi tức thì (`Toggle`) tại màn hình Cài đặt `M-PF-06`.

### 2.4. Shared UI Components Library (`Thư Viện Widget Dùng Chung`)
1. **`ConditionBadge`:**
   - Nhận giá trị `ProductCondition` (`NEW_WITH_TAGS`, `LIKE_NEW`, `GOOD`, `FAIR`, `VINTAGE_WORN`).
   - Hiển thị nhãn tiếng Việt tương ứng kèm màu sắc phân biệt trực quan (xanh lá cây, vàng nâu cổ điển, cam đồng).
2. **`VerificationBadge`:**
   - Nhận giá trị `ProductVerificationLevel` (`UNVERIFIED`, `EVIDENCE_PROVIDED`, `MODERATOR_REVIEWED`).
   - Hiển thị biểu tượng khiên xác thực và nhãn uy tín.
3. **`CountdownTimerWidget`:**
   - Nhận thời điểm đích (`DateTime targetTime`), tự động đồng bộ thời gian qua `ServerTimeService.now()`.
   - Cập nhật mỗi giây, tự động kích hoạt callback `onExpired()` khi thời gian về 00:00:00.
   - Hỗ trợ đổi màu đỏ Burgundy nhấp nháy khi thời gian còn dưới 2 phút (Anti-Sniping window `BR-AU-04`).
4. **`PriceBreakdownCard` (`DEC-04`):**
   - Hiển thị chi tiết bảng tính phí gồm: Tiền hàng (`item_subtotal`), Phí vận chuyển (`0đ`), Phí bảo vệ người mua (`buyer_protection_fee = 6% + 7.000đ`), và Tổng thanh toán (`total_amount`).
   - Hiển thị ghi chú cam kết hoàn tiền 100% khi có sự cố.
5. **`ProductCard` (Fixed-Price):**
   - Ảnh sản phẩm (`CachedNetworkImage` + `Shimmer`), tiêu đề, huy hiệu độ mới, giá bán VNĐ, lượt yêu thích, tên người bán/shop slug.
6. **`AuctionCard`:**
   - Huy hiệu `LIVE` đỏ nhấp nháy, giá đấu cao nhất hiện tại, số lượt trả giá (`bid_count`), và `CountdownTimerWidget`.
7. **`EmptyStateView` & `ErrorRetryView`:**
   - Hiển thị hình minh họa vintage, thông điệp tiếng Việt thân thiện, và nút `Thử lại` gọi hàm tải lại dữ liệu.

---

## 3. Files to Create in `P7-02`
- `mobile/lib/core/theme/app_colors.dart`
- `mobile/lib/core/theme/app_typography.dart`
- `mobile/lib/core/theme/retro_theme.dart`
- `mobile/lib/core/theme/seasonal_theme_provider.dart`
- `mobile/lib/core/widgets/condition_badge.dart`
- `mobile/lib/core/widgets/verification_badge.dart`
- `mobile/lib/core/widgets/countdown_timer_widget.dart`
- `mobile/lib/core/widgets/price_breakdown_card.dart`
- `mobile/lib/core/widgets/product_card.dart`
- `mobile/lib/core/widgets/auction_card.dart`
- `mobile/lib/core/widgets/skeleton_loader.dart`
- `mobile/lib/core/widgets/empty_state_view.dart`
- `mobile/lib/core/widgets/error_retry_view.dart`
- `mobile/lib/core/widgets/seasonal_decor_overlay.dart`
- `mobile/test/core/theme_and_components_test.dart`

---

## 4. Acceptance Criteria (`Tiêu Chí Nghiệm Thu P7-02`)
- [x] **AC-P702-01:** Bảng màu Retro Theme và Typography được cấu hình trọn vẹn trong `ThemeData`.
- [x] **AC-P702-02:** `CountdownTimerWidget` đếm ngược chính xác theo `ServerTimeService` và gọi `onExpired` khi hết hạn.
- [x] **AC-P702-03:** `PriceBreakdownCard` hiển thị đúng công thức `DEC-04` cho bất kỳ mức tiền hàng nào.
- [x] **AC-P702-04:** `SeasonalDecorOverlay` phản hồi đúng khi bật/tắt cờ `seasonal_decor_enabled`.
- [x] **AC-P702-05:** `flutter test test/core/theme_and_components_test.dart` đạt **100% PASS** (8/8 tests pass).
