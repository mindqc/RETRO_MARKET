# 09. REQUIREMENTS TRACEABILITY MATRIX (RTM) – RETRO MARKET (izithrift)

- **Document ID:** `DOC-PA08-RTM`
- **Version:** `1.0.0`
- **Status:** `READY FOR SIGN-OFF`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 01 – Project Discovery & Requirement Analysis`

---

## 1. Mục Đích Ma Trận Truy Vết (Purpose of RTM)
Ma trận Truy vết Yêu cầu (RTM) thiết lập liên kết hai chiều xuyên suốt giữa:
1. **Mục tiêu Dự án (`OBJ-*`)** trong `01_PROJECT_CHARTER.md`.
2. **Yêu cầu Chức năng (`FR-*`)** trong `04_FUNCTIONAL_REQUIREMENTS.md`.
3. **Ma trận Phân quyền (`PERM-*`)** trong `03_ACTOR_PERMISSION_MATRIX.md`.
4. **Đặc tả Use Case (`UC-*`)** trong `05_USE_CASE_SPECIFICATION.md`.
5. **Quy tắc Nghiệp vụ (`BR-*`) & Quyết định (`DEC-*` / `ADR-*`)** trong `06_BUSINESS_RULES.md` và `08_ASSUMPTIONS_AND_DECISIONS.md`.
6. **Phân hệ Triển khai & Kịch bản Kiểm thử Mục tiêu** tại các Phase tiếp theo.

---

## 2. Bảng Truy Vết Tổng Thể Toàn Hệ Thống (Master Traceability Matrix)

### 2.1. Phân Hệ Xác Thực, Tài Khoản & Hồ Sơ (`FR-AU`, `FR-US`)
| FR ID | Tóm tắt Yêu cầu | Mục tiêu (`OBJ`) | Quyền (`PERM`) | Use Case (`UC`) | Business Rules & Quyết định (`BR` / `DEC`) | Phase Triển khai | Kịch bản Kiểm thử (Phase 13) |
| :--- | :--- | :---: | :--- | :---: | :--- | :---: | :--- |
| `FR-AU-01` | Đăng ký tài khoản C2C hợp nhất (Buyer + Seller) | `OBJ-01` | `PERM-AU-01` | `UC-AU-01` | `BR-AC-01`, `NFR-SEC-01` | Phase 06, 07 | `TC-AUTH-01` (Register & Auto Profile Init) |
| `FR-AU-02` | Đăng nhập, cấp Sanctum Token & kiểm tra khóa tài khoản | `OBJ-01` | `PERM-AU-01` | `UC-AU-01` | `BR-AC-04`, `NFR-SEC-01`, `NFR-SEC-04` | Phase 06, 07 | `TC-AUTH-02` (Login Active vs Suspended) |
| `FR-AU-03` | Đăng xuất & thu hồi Token | `OBJ-01` | `PERM-AU-02` | `UC-AU-01` | `NFR-SEC-01` | Phase 06, 07 | `TC-AUTH-03` (Token Revocation) |
| `FR-AU-04` | Khôi phục mật khẩu (Local Mailpit/Log) | `OBJ-01` | `PERM-AU-01` | `UC-AU-01` | `ASM-04` | Phase 06, 07 | `TC-AUTH-04` (Password Reset Flow) |
| `FR-AU-05` | Chế độ Guest (Xem công khai, chặn tương tác) | `OBJ-01` | `PERM-PR-01`, `PERM-AC-01` | `UC-AU-01`, `UC-DS-01` | `BR-AC-03`, `DEC-01` | Phase 07, 08 | `TC-GUEST-01` (Public Read & Auth Redirect) |
| `FR-US-01` | Quản lý hồ sơ cá nhân, cửa hàng & upload Avatar | `OBJ-01` | `PERM-US-01` | `UC-US-01` | `NFR-SEC-02`, `NFR-SEC-05` | Phase 08 (M8.1) | `TC-USER-01` (Profile Update & Ownership) |
| `FR-US-02` | Quản lý sổ địa chỉ nhận hàng & địa chỉ mặc định | `OBJ-01` | `PERM-US-02` | `UC-US-01` | `NFR-SEC-02` | Phase 08 (M8.1) | `TC-USER-02` (Address CRUD & Default Flag) |
| `FR-US-03` | Xem hồ sơ công khai Người bán & thống kê sao | `OBJ-01` | `PERM-US-03` | `UC-US-01` | `DEC-01`, `BR-RV-01` | Phase 08 (M8.1) | `TC-USER-03` (Public Seller View) |
| `FR-US-04` | Theo dõi / Bỏ theo dõi Người bán (`Follow Seller`) | `OBJ-01` | `PERM-US-04` | `UC-DS-02` | `BR-AC-02` (Cấm tự follow) | Phase 08 (M8.6) | `TC-COMM-01` (Follow / Unfollow Guard) |

### 2.2. Phân Hệ Danh Mục, Kênh Người Bán & Kiểm Duyệt (`FR-CT`, `FR-SL`, `FR-MD`)
| FR ID | Tóm tắt Yêu cầu | Mục tiêu (`OBJ`) | Quyền (`PERM`) | Use Case (`UC`) | Business Rules & Quyết định (`BR` / `DEC`) | Phase Triển khai | Kịch bản Kiểm thử (Phase 13) |
| :--- | :--- | :---: | :--- | :---: | :--- | :---: | :--- |
| `FR-CT-01` | Danh sách Danh mục (`Categories`) & Thương hiệu (`Brands`) | `OBJ-01` | `PERM-PR-01`, `PERM-PR-09` | `UC-DS-01`, `UC-AD-01` | `NFR-REL-04` | Phase 08 (M8.2) | `TC-CAT-01` (Category Filter & Admin CRUD) |
| `FR-SL-01` | Đăng sản phẩm bán Giá cố định (`Fixed Price`) | `OBJ-02` | `PERM-PR-03` | `UC-SL-01` | `BR-PR-01`, `BR-PR-03`, `ASM-02` | Phase 08 (M8.3) | `Scenario A` (Step 1: Fixed-Price Listing) |
| `FR-SL-02` | Đăng sản phẩm Đấu giá (`Auction Listing`, `qty = 1`) | `OBJ-02` | `PERM-PR-03` | `UC-SL-01` | `BR-PR-01`, `BR-PR-03`, `ASM-02` | Phase 08, 10 (M10.2) | `Scenario B` (Step 1: Auction Listing) |
| `FR-SL-03` | Lưu bản nháp (`DRAFT`) & Gửi duyệt (`PENDING_REVIEW`) | `OBJ-02` | `PERM-PR-03`, `PERM-PR-04` | `UC-SL-01` | `BR-PR-02` | Phase 08 (M8.3) | `TC-PROD-01` (Draft vs Submit Review) |
| `FR-SL-04` | Quản lý sản phẩm theo 7 trạng thái trong Seller Center | `OBJ-01` | `PERM-PR-05`, `PERM-PR-08` | `UC-SL-02` | `BR-PR-05` (Khóa sửa khi đang giao dịch) | Phase 08 (M8.3) | `TC-PROD-02` (Edit Lock on Active Order/Auction) |
| `FR-SL-05` | Sửa bài đăng bị `REJECTED` & Gửi duyệt lại (`Resubmit`) | `OBJ-02` | `PERM-PR-04`, `PERM-PR-05` | `UC-SL-02`, `UC-MD-01` | `BR-PR-02`, `BR-PR-04`, `DEC-05` | Phase 08 (M8.4) | `TC-MOD-02` (Reject -> Edit -> Resubmit) |
| `FR-SL-06` | Thống kê doanh thu & xem Sổ cái Ví người bán | `OBJ-02` | `PERM-FN-05` | `UC-SL-02` | `BR-FN-04`, `BR-FN-07` | Phase 09 (M9.4) | `Scenario A` (Step 11: Seller Ledger Check) |
| `FR-MD-01` | Hàng chờ kiểm duyệt & xem bằng chứng/lịch sử duyệt | `OBJ-02` | `PERM-PR-06` | `UC-MD-01` | `BR-PR-03`, `BR-PR-04` | Phase 08 (M8.4) | `TC-MOD-01` (Moderation Queue & History) |
| `FR-MD-02` | Duyệt (`APPROVED`) hoặc Từ chối kèm lý do (`REJECTED`) | `OBJ-02` | `PERM-PR-07`, `PERM-PR-08` | `UC-MD-01` | `BR-PR-02`, `BR-PR-04`, `BR-AD-02`, `DEC-05`, `ADR-02` | Phase 08 (M8.4) | `Scenario A` (Step 2) & `Scenario B` (Step 2) |

### 2.3. Phân Hệ Khám Phá, Giỏ Hàng & Đặt Hàng (`FR-DS`, `FR-CR`, `FR-OR`)
| FR ID | Tóm tắt Yêu cầu | Mục tiêu (`OBJ`) | Quyền (`PERM`) | Use Case (`UC`) | Business Rules & Quyết định (`BR` / `DEC`) | Phase Triển khai | Kịch bản Kiểm thử (Phase 13) |
| :--- | :--- | :---: | :--- | :---: | :--- | :---: | :--- |
| `FR-DS-01` | Trang chủ chủ đề Vintage Editorial + Cozy Christmas | `OBJ-03` | `PERM-PR-01` | `UC-DS-01` | `BR-PR-02`, `NFR-UX-01`, `NFR-UX-02`, `ADR-07` | Phase 08 (M8.5) | `TC-UI-01` (Homepage & Seasonal Theme) |
| `FR-DS-02` | Tìm kiếm, Lọc đa tiêu chí & Sắp xếp có phân trang | `OBJ-01` | `PERM-PR-01` | `UC-DS-01` | `BR-PR-02`, `NFR-PER-02` | Phase 08 (M8.5) | `Scenario A` (Step 3: Search & Filter) |
| `FR-DS-03` | Xem Chi tiết Sản phẩm (Tách UI Fixed Price vs Auction) | `OBJ-01` | `PERM-PR-01` | `UC-DS-01` | `BR-PR-01`, `BR-PR-03`, `DEC-01` | Phase 08 (M8.5) | `TC-DISC-01` (Product Detail Context UI) |
| `FR-DS-04` | Thêm / Xóa sản phẩm Yêu thích (`Favorites`) | `OBJ-01` | `PERM-PR-02` | `UC-DS-02` | `BR-AC-02` | Phase 08 (M8.6) | `TC-FAV-01` (Wishlist Persistence) |
| `FR-CR-01` | Giỏ hàng nhóm theo Người bán (Chặn hàng Đấu giá & Tự mua) | `OBJ-01` | `PERM-OR-01` | `UC-CR-01` | `BR-AC-02`, `BR-OR-01` | Phase 08 (M8.7) | `Scenario A` (Step 4: Add to Cart & Validation) |
| `FR-OR-01` | Checkout Preview & Tính **Buyer Protection Fee** (`ship = 0đ`) | `OBJ-02` | `PERM-OR-02` | `UC-OR-01` | `BR-OR-01`, `BR-FN-01`, `BR-FN-02`, `DEC-04` | Phase 09 (M9.1) | `Scenario A` (Step 5: Fee Calculation Check) |
| `FR-OR-02` | Tạo Đơn hàng (`lockForUpdate`), trừ tồn kho & lưu Snapshot | `OBJ-02` | `PERM-OR-03` | `UC-OR-01` | `BR-OR-02`, `BR-OR-03`, `NFR-REL-01`, `NFR-REL-04` | Phase 09 (M9.2) | `Scenario A` (Step 6) & `Edge Case: Last Item Race` |
| `FR-OR-03` | Hủy đơn / Yêu cầu hủy đơn theo 3 cấp trạng thái & Hoàn 100% | `OBJ-02` | `PERM-OR-05A`, `PERM-OR-05B`, `PERM-FN-04B` | `UC-OR-02` | `BR-OR-04`, `BR-FN-05`, `DEC-06`, `DEC-07` | Phase 09 (M9.2, M9.4) | `TC-ORD-01` (Cancel at `PAID` vs `PREPARING`) |

### 2.4. Phân Hệ Thanh Toán QR Mô Phỏng, Sổ Cái Escrow & Vận Chuyển (`FR-PM`, `FR-ES`, `FR-SH`)
| FR ID | Tóm tắt Yêu cầu | Mục tiêu (`OBJ`) | Quyền (`PERM`) | Use Case (`UC`) | Business Rules & Quyết định (`BR` / `DEC`) | Phase Triển khai | Kịch bản Kiểm thử (Phase 13) |
| :--- | :--- | :---: | :--- | :---: | :--- | :---: | :--- |
| `FR-PM-01` | Khởi tạo phiên Thanh toán QR nội bộ & `payment_expires_at` | `OBJ-02` | `PERM-FN-01` | `UC-PM-01` | `BR-FN-02`, `ADR-05` | Phase 09 (M9.3) | `Scenario A` (Step 7: QR Generation) |
| `FR-PM-02` | Mô phỏng Thanh toán Thành công & Chống thanh toán trùng | `OBJ-02` | `PERM-FN-02` | `UC-PM-01` | `BR-FN-03`, `NFR-SEC-03`, `NFR-REL-01` | Phase 09 (M9.3) | `Edge Case: Double Payment Click` |
| `FR-ES-01` | Ghi nhận bút toán giữ tiền `ESCROW_HOLD` (= `total_amount`) | `OBJ-02` | `PERM-FN-03` | `UC-PM-01` | `BR-FN-03`, `BR-FN-07`, `ADR-03`, `ADR-04` | Phase 09 (M9.4) | `Scenario A` (Step 8: Escrow Hold Ledger) |
| `FR-SH-01` | Seller xác nhận `PREPARING`, nhập mã vận đơn `SHIPPED` & `DELIVERED` | `OBJ-02` | `PERM-OR-06`, `PERM-OR-07` | `UC-SH-01` | `BR-OR-05`, `ASM-05`, `ADR-05` | Phase 09 (M9.5, M9.6) | `Scenario A` (Step 9: Manual Shipment Flow) |
| `FR-SH-02` | Theo dõi Timeline vận chuyển & Buyer bấm `Confirm Delivery` | `OBJ-02` | `PERM-OR-04`, `PERM-OR-08` | `UC-SH-01`, `UC-ES-01` | `BR-FN-04` | Phase 09 (M9.6) | `Scenario A` (Step 10: Buyer Confirm Receipt) |
| `FR-ES-02` | Tự động hoàn tất sau 24h & Giải ngân **100% `item_subtotal`** cho Seller | `OBJ-02`, `OBJ-04` | `PERM-OR-09`, `PERM-FN-04` | `UC-ES-01` | `BR-FN-04`, `BR-FN-07`, `BR-AD-01`, `DEC-04` | Phase 09 (M9.7) | `Scenario A` (Step 11) & `TC-JOB-01` (24h Auto-Complete) |

### 2.5. Phân Hệ Đấu Giá Theo Phiên (`FR-AC`)
| FR ID | Tóm tắt Yêu cầu | Mục tiêu (`OBJ`) | Quyền (`PERM`) | Use Case (`UC`) | Business Rules & Quyết định (`BR` / `DEC`) | Phase Triển khai | Kịch bản Kiểm thử (Phase 13) |
| :--- | :--- | :---: | :--- | :---: | :--- | :---: | :--- |
| `FR-AC-01` | Quản lý khung giờ Phiên đấu giá (`Auction Sessions`) & Auction Hub | `OBJ-02` | `PERM-AC-01`, `PERM-AC-02`, `PERM-AC-08`, `PERM-AC-09` | `UC-AC-01` | `BR-AU-01` | Phase 10 (M10.1, M10.3) | `Scenario B` (Step 3: Session & Auction Hub) |
| `FR-AC-02` | Đặt giá thầu đồng thời (`lockForUpdate`), kiểm tra bước giá & lịch sử | `OBJ-02` | `PERM-AC-03` | `UC-AC-02` | `BR-AC-02`, `BR-AU-01`..`BR-AU-03`, `ADR-06` | Phase 10 (M10.4) | `Scenario B` (Steps 4–6) & `Edge Case: Simultaneous Bids` |
| `FR-AC-03` | Tự động gia hạn 2 phút cuối (`Anti-Sniping`) | `OBJ-02` | `PERM-AC-04` | `UC-AC-02` | `BR-AU-04`, `ADR-05` | Phase 10 (M10.5) | `TC-AUC-01` (Final 2-Min Bid Extension) |
| `FR-AC-04` | Người bán Chốt phiên đấu giá sớm (`Seller Early Close`) | `OBJ-02` | `PERM-AC-05` | `UC-AC-03` | `BR-AU-03`, `BR-AU-05` | Phase 10 (M10.8) | `TC-AUC-02` (Early Close with Reserve Price Check) |
| `FR-AC-05` | Đóng phiên tự động, xác định Người thắng & tạo Đơn hàng duy nhất | `OBJ-02`, `OBJ-04` | `PERM-AC-06` | `UC-AC-04` | `BR-AU-06`, `BR-FN-02`, `BR-AD-01` | Phase 10 (M10.6, M10.7) | `Scenario B` (Steps 7–11: Winner Order & Payment) |
| `FR-AC-06` | Hủy đơn đấu giá quá hạn 30 phút & cho phép Seller đăng lại | `OBJ-02`, `OBJ-04` | `PERM-AC-07` | `UC-AC-04` | `BR-AU-07`, `DEC-02`, `ADR-05` | Phase 10 (M10.7) | `Edge Case: Unpaid Winner Expiry & Relist` |

### 2.6. Phân Hệ Tương Tác, Đánh Giá, Khiếu Nại & Quản Trị (`FR-RV`, `FR-DP`, `FR-CM`, `FR-NT`, `FR-AD`)
| FR ID | Tóm tắt Yêu cầu | Mục tiêu (`OBJ`) | Quyền (`PERM`) | Use Case (`UC`) | Business Rules & Quyết định (`BR` / `DEC`) | Phase Triển khai | Kịch bản Kiểm thử (Phase 13) |
| :--- | :--- | :---: | :--- | :---: | :--- | :---: | :--- |
| `FR-RV-01` | Đánh giá 1–5 sao & nhận xét (1 lần/đơn `COMPLETED`) | `OBJ-01` | `PERM-CM-03`, `PERM-CM-04` | `UC-RV-01` | `BR-RV-01` | Phase 11 (M11.2) | `Scenario A` (Step 12) & `Duplicate Review Block` |
| `FR-DP-01` | Mở Khiếu nại ở `SHIPPED` / `DELIVERED` & Khóa cứng giải ngân | `OBJ-02` | `PERM-CM-05`, `PERM-CM-06` | `UC-DP-01` | `BR-DP-01`, `BR-DP-02`, `DEC-03`, `ADR-03` | Phase 11 (M11.4) | `Scenario C` (Steps 3–5: Dispute Locks Auto-Release) |
| `FR-DP-02` | Đối chứng bằng chứng & Yêu cầu bổ sung (`REQUEST_MORE_EVIDENCE`) | `OBJ-02` | `PERM-CM-07`, `PERM-CM-08` | `UC-DP-01`, `UC-DP-02` | `BR-DP-02` | Phase 11 (M11.4) | `Scenario C` (Step 6: Evidence & Support Review) |
| `FR-DP-03` | Admin phân xử tài chính (Hoàn 100% `total_amount` / Giải ngân / Hoàn 1 phần) | `OBJ-02` | `PERM-CM-09`, `PERM-FN-04B` | `UC-DP-02` | `BR-FN-05`..`BR-FN-07`, `BR-AD-02`, `DEC-07` | Phase 11, 12 (M12.8) | `Scenario C` (Steps 7–8: Full Refund Ledger Check) |
| `FR-CM-01` | Chat 1-1 Người mua – Người bán (HTTP Polling có kiểm soát) | `OBJ-01` | `PERM-CM-01`, `PERM-CM-02` | `UC-CM-01` | `BR-AC-02`, `NFR-PER-03`, `ADR-08` | Phase 11 (M11.1) | `TC-CHAT-01` (Send/Poll Messages & Timer Dispose) |
| `FR-CM-02` | Báo cáo vi phạm (`Reports`) & tính Điểm uy tín (`Trust Score`) | `OBJ-01` | `PERM-CM-10`, `PERM-CM-11` | `UC-AD-01` | `BR-AD-02` | Phase 11 (M11.3) | `TC-TRUST-01` (Report Moderation & Score Calc) |
| `FR-NT-01` | Thông báo trong ứng dụng (`In-App Notifications` & Unread Badge) | `OBJ-01` | `PERM-CM-12` | `UC-NT-01` | — | Phase 11 (M11.5) | `TC-NOTI-01` (Event Notification Trigger & Read State) |
| `FR-AD-01` | Admin Dashboard hiển thị số liệu thực từ PostgreSQL | `OBJ-02` | `PERM-AD-01` | `UC-AD-01` | `NFR-MNT-01`, `ADR-02` | Phase 12 (M12.2) | `TC-ADMIN-01` (Dashboard Live Metrics) |
| `FR-AD-02` | Quản lý Người dùng, Khóa/Mở khóa & Phát hiện bất thường | `OBJ-02` | `PERM-US-05`..`PERM-US-07`, `PERM-AC-09` | `UC-AD-01` | `BR-AC-04`, `BR-AD-02` | Phase 12 (M12.3) | `TC-ADMIN-02` (User Suspend & Token Revoke) |
| `FR-AD-03` | Giám sát Đơn hàng, Thanh toán & Sổ cái Escrow (Read-Only History) | `OBJ-02` | `PERM-FN-06`, `PERM-FN-07` | `UC-AD-01` | `BR-FN-07`, `ADR-04` | Phase 12 (M12.6, M12.7) | `TC-ADMIN-03` (Immutable Ledger Inspection) |
| `FR-AD-04` | Cấu hình `platform_settings` (**Buyer Protection Fee** & Demo Timers) | `OBJ-02`, `OBJ-04` | `PERM-AD-02` | `UC-AD-02` | `BR-FN-02`, `BR-AD-02`, `DEC-04`, `ADR-05` | Phase 06, 12 (M12.9) | `TC-ADMIN-04` (Dynamic Fee & Timer Config) |
| `FR-AD-05` | **Developer Tools (Demo Mode)**: Kích hoạt thủ công Scheduled Jobs | `OBJ-04` | `PERM-AD-04` | `UC-AD-02` | `BR-AD-01`, `BR-AD-02`, `ADR-05`, `NFR-ENV-02` | Phase 09, 10, 12 | `TC-DEMO-01` (Idempotent Manual Job Triggers) |
| `FR-AD-06` | Nhật ký Kiểm toán Quản trị (`Admin Audit Logs`) | `OBJ-02` | `PERM-AD-03` | `UC-AD-01` | `BR-AD-02` | Phase 06, 12 (M12.10) | `TC-ADMIN-05` (Audit Trail Verification) |

---

## 3. Thống Kê Độ Phủ Truy Vết (Traceability Coverage Summary)
- **Tổng số Mục tiêu Dự án (`OBJ-01`..`OBJ-04`):** `4/4` (Độ phủ `100%`).
- **Tổng số Yêu cầu Chức năng (`FR-*`):** `51/51` (Độ phủ `100%` – `46 MVP`, `5 ENHANCEMENT`).
- **Tổng số Quyền hạn (`PERM-*`):** `61/61` (Độ phủ `100%`).
- **Tổng số Use Case (`UC-*`):** `24/24` (Độ phủ `100%`).
- **Tổng số Quy tắc Nghiệp vụ (`BR-*`):** `33/33` (Độ phủ `100%`).
- **Tổng số Quyết định Nghiệp vụ & Kiến trúc (`DEC-01`..`DEC-07`, `ADR-01`..`ADR-08`):** `15/15` (Độ phủ `100%`).
- **Số lượng Yêu cầu Mồ côi (Orphan Requirements):** `0`.