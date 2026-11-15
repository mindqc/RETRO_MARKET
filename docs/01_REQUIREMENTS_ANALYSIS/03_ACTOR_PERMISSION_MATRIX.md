# 03. ACTOR & PERMISSION MATRIX – RETRO MARKET (izithrift)

- **Document ID:** `DOC-PA02-ACTORS`
- **Version:** `1.1.0 (FINAL APPROVED)`
- **Status:** `DONE`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 01 – Project Discovery & Requirement Analysis`

---

## 1. Tổng Quan Mô Hình Phân Quyền (Authorization Architecture Overview)
Hệ thống **RETRO MARKET (`izithrift`)** áp dụng mô hình kết hợp giữa **RBAC (Role-Based Access Control – Kiểm soát truy cập dựa trên vai trò)** và **ABAC / Ownership Policy (Kiểm soát truy cập dựa trên quyền sở hữu tài nguyên và trạng thái nghiệp vụ)** tại tầng Backend Laravel 13:

1. **Nguyên tắc Tài khoản Đơn nhất (Unified C2C Account):** Mọi người dùng thông thường sau khi đăng ký (`Registered User`) đều sở hữu đồng thời năng lực **Người mua (Buyer Context)** và **Người bán (Seller Context)** trên cùng một tài khoản duy nhất. Hệ thống không tạo hai loại tài khoản Buyer/Seller tách biệt.
2. **Nguyên tắc Kiểm tra Quyền sở hữu & Chống tự giao dịch (Ownership & Anti-Self-Dealing):** Dù một tài khoản vừa là Buyer vừa là Seller, trên từng bản ghi cụ thể (`Product`, `Auction`, `Order`, `Dispute`), hệ thống xác định ngữ cảnh dựa trên `seller_id` và `buyer_id`:
   - Người dùng là chủ sở hữu sản phẩm (`auth()->id() == product.seller_id`) được cấp quyền quản lý bài đăng đó nhưng bị chặn quyền thêm vào giỏ hàng, đặt mua hoặc đặt giá thầu (bid) trên chính sản phẩm đó.
3. **Nguyên tắc Không tin cậy Client (Zero-Trust Client):** Ứng dụng Flutter chỉ ẩn/hiện nút bấm để tối ưu trải nghiệm người dùng (UX). Mọi giới hạn quyền hạn, chuyển đổi trạng thái đơn hàng, giải ngân/hoàn tiền Escrow và xác định người thắng đấu giá đều phải được kiểm tra bắt buộc qua **Laravel Middleware, Form Requests và Eloquent Policies**.

---

## 2. Danh Mục Các Tác Nhân Hệ Thống (Actor Catalog)

| Mã Actor | Tên Actor | Giao diện sử dụng | Mô tả vai trò & Trách nhiệm cốt lõi |
| :--- | :--- | :--- | :--- |
| `ACT-01` | **Guest** (Khách vãng lai) | Mobile App (`izithrift`) | Người dùng chưa đăng nhập. Có quyền duyệt xem các nội dung công khai (Trang chủ, Tìm kiếm, Chi tiết sản phẩm đã duyệt, Danh sách phiên đấu giá) nhưng bị chặn mọi thao tác tương tác hoặc giao dịch. |
| `ACT-02` | **Registered User** (Người dùng đã đăng nhập: Buyer & Seller) | Mobile App (`izithrift`) | Người dùng có tài khoản hoạt động (`ACTIVE`). Có toàn quyền mua sắm, tham gia đấu giá, chat, đánh giá, khiếu nại (trong ngữ cảnh **Buyer**) và đăng bán sản phẩm, quản lý đơn bán, chốt phiên đấu giá sớm, theo dõi ví doanh thu (trong ngữ cảnh **Seller**). |
| `ACT-03` | **Moderator** (Kiểm duyệt viên) | Admin Web (Laravel Blade) | Nhân sự kiểm duyệt nội dung. Chịu trách nhiệm duyệt (`APPROVED`) hoặc từ chối (`REJECTED`) sản phẩm đăng mới, xử lý báo cáo vi phạm (`Reports`) và ẩn đánh giá không phù hợp. Không có quyền can thiệp tài chính. |
| `ACT-04` | **Support Staff** (Nhân viên hỗ trợ) | Admin Web (Laravel Blade) | Nhân sự hỗ trợ khách hàng và tiếp nhận tranh chấp. Có quyền xem thông tin đơn hàng liên quan đến khiếu nại được giao, xem bằng chứng hai bên và gửi yêu cầu bổ sung bằng chứng (`REQUEST_MORE_EVIDENCE`). Không có quyền duyệt giải ngân hoặc hoàn tiền. |
| `ACT-05` | **Administrator** (Quản trị viên hệ thống) | Admin Web (Laravel Blade) | Quyền cao nhất trên hệ thống. Quản lý toàn bộ 14 phân hệ, cấu hình phiên đấu giá, cấu hình **Buyer Protection Fee**, ra quyết định tài chính cuối cùng cho các tranh chấp, quản lý nhân sự/tài khoản, xem Audit Logs và vận hành **Developer Tools (Demo Mode)**. |
| `ACT-06` | **System Scheduler** (Tác nhân tự động nội bộ) | Backend CLI / Cron (`schedule:work`) | Tác nhân nền của hệ thống Laravel. Thực thi các tác vụ tự động theo thời gian: mở/đóng phiên đấu giá, tạo đơn cho người thắng, hủy đơn quá hạn thanh toán, tự động hoàn tất đơn sau 24 giờ kể từ lúc `DELIVERED` và giải ngân Escrow đủ điều kiện. |

---

## 3. Ranh Giới Quyền Hạn Của Khách Vãng Lai (Guest Access Boundary – `DEC-01`)

### 3.1. Các hành động `Guest` ĐƯỢC PHÉP thực hiện (Public Read-Only)
- Xem màn hình Onboarding và Trang chủ (bao gồm Hero Banner Giáng sinh, bộ sưu tập vintage, danh mục, sản phẩm nổi bật, phiên đấu giá đang diễn ra).
- Tìm kiếm sản phẩm theo từ khóa, thương hiệu, danh mục; sử dụng bộ lọc và sắp xếp danh sách sản phẩm.
- Xem trang Chi tiết sản phẩm (chỉ các sản phẩm có trạng thái `APPROVED` hoặc `SOLD`), bao gồm ảnh, mô tả, tình trạng, lỗi (defects) và thông tin/điểm đánh giá công khai của Người bán.
- Xem trang Hồ sơ công khai của Người bán (`Seller Public Profile`) và danh sách các bài đánh giá (`Reviews`) của người bán đó.
- Xem danh sách các phiên đấu giá trong **Auction Hub** và xem chi tiết sản phẩm đấu giá (giá hiện tại, lịch sử trả giá ẩn danh một phần, đồng hồ đếm ngược).
- Thực hiện Đăng ký tài khoản mới (`Register`), Đăng nhập (`Login`) và Khôi phục mật khẩu (`Password Reset`).

### 3.2. Các hành động `Guest` BỊ CHẶN (Yêu cầu chuyển hướng sang màn hình Login)
Khi `Guest` nhấn vào bất kỳ nút hành động nào dưới đây, ứng dụng Flutter phải chặn thao tác và điều hướng sang màn hình Đăng nhập (kèm thông báo yêu cầu đăng nhập):
- Thêm sản phẩm vào Giỏ hàng (`Add to Cart`) hoặc bấm Mua ngay (`Buy Now`).
- Đặt giá thầu trong phiên đấu giá (`Place Bid`) hoặc theo dõi phiên đấu giá (`Watch Auction`).
- Lưu sản phẩm yêu thích (`Favorite`) hoặc bấm Theo dõi người bán (`Follow Seller`).
- Nhắn tin với người bán (`Chat with Seller`) hoặc gửi Báo cáo vi phạm (`Report Product/User`).
- Truy cập vào các tab yêu cầu định danh: **Seller Center (Đăng bán)**, **Giỏ hàng (Cart)**, **Đơn hàng (Orders)**, **Hộp thư Chat**, **Thông báo (Notifications)** và **Quản lý Hồ sơ cá nhân (My Profile)**.

---

## 4. Quy Tắc Ngữ Cảnh Hai Vai Trò & Quyền Hủy Đơn / Hoàn Tiền (`DEC-06`, `DEC-07`)

Một `Registered User` (`ACT-02`) không cần chuyển đổi tài khoản để mua hoặc bán, nhưng hệ thống kiểm soát quyền theo **Ngữ cảnh Bản ghi (Record Context)** và **Trạng thái Đơn hàng**:

| Ngữ cảnh nghiệp vụ | Điều kiện xác định tại Backend | Quyền được cấp | Hành vi bị cấm tuyệt đối (Ownership Guard) |
| :--- | :--- | :--- | :--- |
| **Buyer Context** (Khi đóng vai trò Người mua) | `auth()->id() != product.seller_id` (đối với sản phẩm) hoặc `auth()->id() == order.buyer_id` (đối với đơn hàng) | Thêm giỏ hàng, Checkout, Thanh toán QR mô phỏng, Hủy đơn trực tiếp khi ở `PENDING_PAYMENT` hoặc `PAID`, Gửi yêu cầu hủy đơn khi ở `PREPARING` (chờ Seller duyệt), Xác nhận đã nhận hàng (`Confirm Delivery`), Mở khiếu nại (`SHIPPED`/`DELIVERED`), Đánh giá người bán (`COMPLETED`). | Không được chỉnh sửa/xóa sản phẩm của người khác; không được cập nhật trạng thái vận chuyển (`SHIPPED`/`DELIVERED`); không được tự ý hủy đơn trực tiếp khi Seller đã bấm `PREPARING` hoặc `SHIPPED`. |
| **Seller Context** (Khi đóng vai trò Người bán) | `auth()->id() == product.seller_id` (đối với sản phẩm) hoặc `auth()->id() == order.seller_id` (đối với đơn hàng) | Tạo bài đăng (Fixed Price / Auction), Lưu nháp, Gửi duyệt, Sửa bài bị `REJECTED` để gửi lại, Chốt phiên đấu giá sớm (khi đạt điều kiện), Xác nhận chuẩn bị hàng (`PREPARING`), Hủy đơn trực tiếp (khi `PAID`/`PREPARING`) hoặc Duyệt/Từ chối yêu cầu hủy của Buyer khi đang `PREPARING`, Nhập mã vận đơn & cập nhật `SHIPPED`/`DELIVERED`, Xem ví & lịch sử giải ngân của chính mình. | **Cấm tự giao dịch:** Không được thêm sản phẩm của chính mình vào giỏ hàng; không được tự đặt mua; **không được tự trả giá (bid) trên sản phẩm đấu giá của chính mình**; không được tự bấm xác nhận nhận hàng (`Confirm Delivery`) thay cho người mua. |

### Quy Tắc Chi Tiết Về Quyền Hủy Đơn & Hoàn Tiền 100% (`DEC-06` & `DEC-07`)
1. **Khi đơn ở trạng thái `PENDING_PAYMENT`:** Buyer có quyền tự hủy đơn ngay lập tức (hoặc System Scheduler tự hủy khi hết hạn thanh toán). Không phát sinh giao dịch hoàn tiền vì chưa thanh toán.
2. **Khi đơn ở trạng thái `PAID` (Người bán chưa bấm `PREPARING`):** Cả **Buyer** và **Seller** đều có quyền chủ động bấm Hủy đơn ngay lập tức. Hệ thống tự động hoàn trả **100% `total_amount` (gồm cả `item_subtotal` + `buyer_protection_fee`)** từ trạng thái `ESCROW_HELD` về cho Buyer.
3. **Khi đơn ở trạng thái `PREPARING` (Người bán đã xác nhận chuẩn bị hàng):**
   - **Seller** vẫn có quyền chủ động hủy đơn (ví dụ phát hiện hàng lỗi trước khi gửi) $\rightarrow$ Hoàn trả 100% `total_amount` cho Buyer.
   - **Buyer** muốn hủy bắt buộc phải bấm **"Gửi yêu cầu hủy đơn" (Request Cancellation)** và phải được **Seller bấm Đồng ý (Approve Cancellation)** thì đơn mới chuyển sang `CANCELLED` và hoàn trả 100% `total_amount`. Nếu Seller từ chối và tiến hành gửi hàng (`SHIPPED`), đơn hàng tiếp tục luồng giao nhận.
4. **Khi đơn ở trạng thái `SHIPPED` hoặc `DELIVERED`:** Không bên nào được hủy đơn trực tiếp nữa. Nếu có vấn đề (không nhận được hàng, hàng rách, sai mô tả), **Buyer** sử dụng quyền **Mở Khiếu nại (`Dispute`)**. Nếu Admin phán quyết `APPROVE_BUYER_REFUND`, Buyer được hoàn trả đủ **100% `total_amount` (gồm cả `item_subtotal` + `buyer_protection_fee`)** đúng theo cam kết của Phí bảo vệ người mua.

---

## 5. Phân Tách Quyền Hạn Nội Bộ Giữa Admin, Moderator & Support Staff

1. **Moderator (`ACT-03`):**
   - **Được phép:** Xem danh sách chờ duyệt (`PENDING_REVIEW`), xem chi tiết sản phẩm & bằng chứng xác thực, duyệt (`APPROVED`) hoặc từ chối (`REJECTED` kèm lý do bắt buộc), ẩn sản phẩm vi phạm (`HIDDEN`), kiểm duyệt/ẩn đánh giá vi phạm (`Reviews`), xử lý báo cáo vi phạm nội dung (`Reports`).
   - **Bị cấm:** Không được khóa tài khoản vĩnh viễn của Admin khác, không được chỉnh sửa cấu hình phí nền tảng (`platform_settings`), không được can thiệp vào đơn hàng, thanh toán, sổ cái giữ tiền Escrow hoặc ra phán quyết hoàn tiền khiếu nại.
2. **Support Staff (`ACT-04`):**
   - **Được phép:** Truy cập danh sách khiếu nại (`Disputes`) được phân công, xem chi tiết đơn hàng/vận chuyển/lịch sử chat liên quan đến khiếu nại, xem bằng chứng do Buyer và Seller cung cấp, gửi yêu cầu bổ sung thêm bằng chứng (`REQUEST_MORE_EVIDENCE`), ghi chú kết quả xác minh sơ bộ cho Admin.
   - **Bị cấm (`Strict Financial Restriction`):** Tuyệt đối không được thực thi các quyết định làm thay đổi dòng tiền hoặc đóng tranh chấp (`APPROVE_BUYER_REFUND`, `RELEASE_TO_SELLER`, `PARTIAL_REFUND`, `REJECT_DISPUTE`), không được chỉnh sửa sổ cái Escrow hay thay đổi cài đặt hệ thống.
3. **Administrator (`ACT-05`):**
   - **Được phép:** Có toàn quyền của Moderator và Support Staff, cộng thêm quyền độc quyền đối với: Quản lý người dùng & phân quyền RBAC, Cấu hình khung giờ đấu giá (`Auction Sessions`), Ra phán quyết cuối cùng cho Khiếu nại (sinh bút toán hoàn tiền hoặc giải ngân), Quản lý cấu hình hệ thống (`Platform Settings` – bao gồm cấu hình **Buyer Protection Fee** và thời gian **Demo Mode**), Xem toàn bộ nhật ký kiểm toán (`Audit Logs`) và kích hoạt **Developer Tools (Manual Job Triggers)**.
   - **Giới hạn toàn vẹn dữ liệu (Data Integrity Guard ngay cả với Admin):** Ngay cả Administrator cũng **không được phép sửa hoặc xóa trực tiếp các dòng lịch sử trong bảng `escrow_transactions`, `wallet_transactions` hoặc `auction_bids`**. Mọi can thiệp tài chính của Admin bắt buộc phải đi qua luồng nghiệp vụ chính thống để sinh bút toán mới và tự động ghi vào `audit_logs`.

---

## 6. Ma Trận Phân Quyền Chi Tiết Toàn Hệ Thống (Master Permission Matrix)

**Ký hiệu quy ước trong bảng:**
- `YES`: Được phép thực hiện đầy đủ.
- `OWN`: Chỉ được phép thực hiện trên bản ghi thuộc quyền sở hữu của chính mình (`buyer_id` hoặc `seller_id` tương ứng).
- `NOT_OWN`: Chỉ được thực hiện trên sản phẩm/phiên đấu giá **không phải** do chính mình đăng bán (`auth()->id() != seller_id`).
- `ASSIGNED`: Chỉ được phép thao tác trên các hồ sơ khiếu nại được phân công hỗ trợ.
- `PUBLIC`: Chỉ được xem các bản ghi đã được duyệt công khai (`APPROVED` / `LIVE` / `COMPLETED`).
- `DEMO_ONLY`: Chỉ khả dụng khi cấu hình môi trường `DEMO_MODE=true`.
- `—`: Không có quyền (Bị từ chối bởi Backend Middleware/Policy với mã lỗi `401 Unauthorized` hoặc `403 Forbidden`).

### 6.1. Nhóm Xác Thực, Tài Khoản & Hồ Sơ (Authentication, Profile & Users)
| Mã Quyền | Hành động / Chức năng | Guest (`ACT-01`) | Buyer Context (`ACT-02`) | Seller Context (`ACT-02`) | Moderator (`ACT-03`) | Support Staff (`ACT-04`) | Admin (`ACT-05`) | System (`ACT-06`) |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `PERM-AU-01` | Đăng ký, Đăng nhập, Khôi phục mật khẩu | `YES` | `YES` | `YES` | `YES` | `YES` | `YES` | `—` |
| `PERM-AU-02` | Đăng xuất, Xem thông tin phiên đăng nhập hiện tại (`/auth/me`) | `—` | `YES` | `YES` | `YES` | `YES` | `YES` | `—` |
| `PERM-US-01` | Xem & cập nhật hồ sơ cá nhân, ảnh đại diện, mô tả | `—` | `OWN` | `OWN` | `OWN` | `OWN` | `YES` | `—` |
| `PERM-US-02` | Quản lý sổ địa chỉ nhận hàng (Thêm, sửa, xóa, đặt mặc định) | `—` | `OWN` | `OWN` | `—` | `—` | `—` | `—` |
| `PERM-US-03` | Xem hồ sơ công khai của Người bán & thống kê đánh giá | `PUBLIC` | `PUBLIC` | `PUBLIC` | `YES` | `YES` | `YES` | `—` |
| `PERM-US-04` | Theo dõi / Bỏ theo dõi người bán (`Follow Seller`) | `—` | `NOT_OWN` | `—` | `—` | `—` | `—` | `—` |
| `PERM-US-05` | Xem danh sách toàn bộ tài khoản người dùng trên hệ thống | `—` | `—` | `—` | `—` | `—` | `YES` | `—` |
| `PERM-US-06` | Khóa (`SUSPENDED` / `BANNED`) hoặc Mở khóa tài khoản người dùng | `—` | `—` | `—` | `—` | `—` | `YES` | `—` |
| `PERM-US-07` | Phân quyền vai trò nội bộ (`Role Assignment`) | `—` | `—` | `—` | `—` | `—` | `YES` | `—` |

### 6.2. Nhóm Danh Mục, Sản Phẩm & Kiểm Duyệt (Catalog, Product Listing & Moderation)
| Mã Quyền | Hành động / Chức năng | Guest (`ACT-01`) | Buyer Context (`ACT-02`) | Seller Context (`ACT-02`) | Moderator (`ACT-03`) | Support Staff (`ACT-04`) | Admin (`ACT-05`) | System (`ACT-06`) |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `PERM-PR-01` | Xem Trang chủ, Tìm kiếm, Lọc, Xem chi tiết sản phẩm đã duyệt | `PUBLIC` | `PUBLIC` | `PUBLIC` | `YES` | `YES` | `YES` | `—` |
| `PERM-PR-02` | Thêm / Xóa sản phẩm vào danh sách Yêu thích (`Favorites`) | `—` | `NOT_OWN` | `—` | `—` | `—` | `—` | `—` |
| `PERM-PR-03` | Tạo sản phẩm mới (Fixed Price / Auction), tải ảnh, lưu `DRAFT` | `—` | `—` | `YES` | `—` | `—` | `—` | `—` |
| `PERM-PR-04` | Gửi sản phẩm đi kiểm duyệt (`DRAFT`/`REJECTED` $\rightarrow$ `PENDING_REVIEW`) | `—` | `—` | `OWN` | `—` | `—` | `—` | `—` |
| `PERM-PR-05` | Chỉnh sửa thông tin sản phẩm, ẩn/lưu trữ sản phẩm của mình | `—` | `—` | `OWN` *(Khi chưa bán/đấu giá)* | `—` | `—` | `YES` | `—` |
| `PERM-PR-06` | Xem danh sách sản phẩm chờ duyệt (`PENDING_REVIEW`) & lịch sử duyệt | `—` | `—` | `OWN` | `YES` | `—` | `YES` | `—` |
| `PERM-PR-07` | Duyệt sản phẩm (`APPROVED`) hoặc Từ chối kèm lý do (`REJECTED`) | `—` | `—` | `—` | `YES` | `—` | `YES` | `—` |
| `PERM-PR-08` | Ẩn/Gỡ sản phẩm vi phạm đang hiển thị (`APPROVED` $\rightarrow$ `HIDDEN`) | `—` | `—` | `OWN` | `YES` | `—` | `YES` | `—` |
| `PERM-PR-09` | Tạo, sửa, ẩn/hiện Danh mục (`Categories`) & Thương hiệu (`Brands`) | `—` | `—` | `—` | `—` | `—` | `YES` | `—` |

### 6.3. Nhóm Đấu Giá Theo Phiên (Scheduled Auction System)
| Mã Quyền | Hành động / Chức năng | Guest (`ACT-01`) | Buyer Context (`ACT-02`) | Seller Context (`ACT-02`) | Moderator (`ACT-03`) | Support Staff (`ACT-04`) | Admin (`ACT-05`) | System (`ACT-06`) |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `PERM-AC-01` | Xem Auction Hub, chi tiết phiên, giá cao nhất & lịch sử trả giá | `PUBLIC` | `PUBLIC` | `PUBLIC` | `YES` | `YES` | `YES` | `—` |
| `PERM-AC-02` | Theo dõi phiên đấu giá (`Watch Auction`) | `—` | `NOT_OWN` | `—` | `—` | `—` | `—` | `—` |
| `PERM-AC-03` | Đặt giá thầu (`Place Bid`) trong phiên đang mở (`LIVE`) | `—` | `NOT_OWN` | `—` *(Cấm tự bid)* | `—` | `—` | `—` | `—` |
| `PERM-AC-04` | Tự động gia hạn thêm 2 phút khi có bid hợp lệ ở 2 phút cuối (Anti-sniping) | `—` | `—` | `—` | `—` | `—` | `—` | `YES` |
| `PERM-AC-05` | Chốt phiên đấu giá sớm (`Close Early` khi đã có bid hợp lệ $\ge$ giá sàn) | `—` | `—` | `OWN` | `—` | `—` | `—` | `—` |
| `PERM-AC-06` | Đóng phiên khi hết giờ, xác định người thắng & tự động tạo Đơn hàng | `—` | `—` | `—` | `—` | `—` | `DEMO_ONLY` | `YES` |
| `PERM-AC-07` | Đăng lại sản phẩm đấu giá sau khi người thắng quá hạn 30 phút không trả tiền | `—` | `—` | `OWN` | `—` | `—` | `—` | `—` |
| `PERM-AC-08` | Cấu hình khung giờ đấu giá hàng ngày (`Auction Sessions`) & bước giá sàn | `—` | `—` | `—` | `—` | `—` | `YES` | `—` |
| `PERM-AC-09` | Hủy phiên đấu giá có dấu hiệu gian lận / bất thường | `—` | `—` | `—` | `—` | `—` | `YES` | `—` |

### 6.4. Nhóm Giỏ Hàng, Đơn Hàng & Vận Chuyển (Cart, Orders & Shipping)
| Mã Quyền | Hành động / Chức năng | Guest (`ACT-01`) | Buyer Context (`ACT-02`) | Seller Context (`ACT-02`) | Moderator (`ACT-03`) | Support Staff (`ACT-04`) | Admin (`ACT-05`) | System (`ACT-06`) |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `PERM-OR-01` | Thêm/sửa/xóa sản phẩm Fixed Price trong Giỏ hàng | `—` | `NOT_OWN` | `—` *(Cấm tự mua)* | `—` | `—` | `—` | `—` |
| `PERM-OR-02` | Xem Checkout Preview (gồm Giá hàng + **Buyer Protection Fee**, ship = `0đ`) | `—` | `NOT_OWN` | `—` | `—` | `—` | `—` | `—` |
| `PERM-OR-03` | Tạo đơn hàng Fixed Price (1 Seller / 1 Order, lưu snapshot sản phẩm) | `—` | `NOT_OWN` | `—` | `—` | `—` | `—` | `—` |
| `PERM-OR-04` | Xem danh sách & chi tiết đơn hàng, lịch sử vận chuyển | `—` | `OWN` *(Đơn mua)* | `OWN` *(Đơn bán)* | `—` | `ASSIGNED` | `YES` | `—` |
| `PERM-OR-05A` | Hủy đơn hàng trực tiếp khi ở trạng thái `PENDING_PAYMENT` hoặc `PAID` | `—` | `OWN` | `OWN` *(Khi `PAID`)* | `—` | `—` | `YES` | `YES` *(Quá hạn)* |
| `PERM-OR-05B` | Gửi yêu cầu hủy đơn (Buyer) / Duyệt hoặc hủy đơn (Seller) khi đang `PREPARING` | `—` | `OWN` *(Gửi yêu cầu)* | `OWN` *(Duyệt / Tự hủy)* | `—` | `—` | `YES` | `—` |
| `PERM-OR-06` | Xác nhận chuẩn bị hàng (`PAID` $\rightarrow$ `PREPARING`) | `—` | `—` | `OWN` | `—` | `—` | `—` | `—` |
| `PERM-OR-07` | Nhập mã vận đơn thủ công & cập nhật trạng thái `SHIPPED` / `DELIVERED` | `—` | `—` | `OWN` | `—` | `—` | `—` | `—` |
| `PERM-OR-08` | Xác nhận đã nhận được hàng (`DELIVERED` $\rightarrow$ `COMPLETED`) | `—` | `OWN` | `—` | `—` | `—` | `—` | `—` |
| `PERM-OR-09` | Tự động hoàn tất đơn hàng sau 24 giờ từ lúc `DELIVERED` (nếu không có Dispute) | `—` | `—` | `—` | `—` | `—` | `DEMO_ONLY` | `YES` |

### 6.5. Nhóm Thanh Toán QR Mô Phỏng, Sổ Cái Escrow & Ví (Payment, Escrow & Wallet Ledger)
| Mã Quyền | Hành động / Chức năng | Guest (`ACT-01`) | Buyer Context (`ACT-02`) | Seller Context (`ACT-02`) | Moderator (`ACT-03`) | Support Staff (`ACT-04`) | Admin (`ACT-05`) | System (`ACT-06`) |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `PERM-FN-01` | Khởi tạo phiên thanh toán QR & xem mã QR thanh toán của đơn hàng | `—` | `OWN` | `—` | `—` | `—` | `YES` | `—` |
| `PERM-FN-02` | Kích hoạt nút mô phỏng thanh toán thành công (`Simulate Payment Success`) | `—` | `OWN` | `—` | `—` | `—` | `YES` | `—` |
| `PERM-FN-03` | Ghi nhận bút toán giữ tiền (`ESCROW_HOLD` = `total_amount`) sau khi thanh toán thành công | `—` | `—` | `—` | `—` | `—` | `—` | `YES` |
| `PERM-FN-04` | Giải ngân 100% tiền hàng (`item_subtotal`) vào ví Seller khi đơn `COMPLETED` | `—` | `—` | `—` | `—` | `—` | `—` | `YES` |
| `PERM-FN-04B` | Hoàn trả 100% `total_amount` (`item_subtotal` + `buyer_protection_fee`) cho Buyer khi hủy đơn hợp lệ hoặc thắng Dispute | `—` | `—` | `—` | `—` | `—` | `YES` *(Qua Dispute)* | `YES` *(Qua Hủy đơn)* |
| `PERM-FN-05` | Xem số dư ví mô phỏng & lịch sử biến động sổ cái của bản thân | `—` | `OWN` | `OWN` | `—` | `—` | `YES` | `—` |
| `PERM-FN-06` | Tra cứu toàn bộ giao dịch Payment, Escrow Ledger & phí bảo vệ người mua | `—` | `—` | `—` | `—` | `—` | `YES` | `—` |
| `PERM-FN-07` | Sửa hoặc xóa trực tiếp bản ghi lịch sử trong bảng `escrow_transactions` / `wallet_transactions` | `—` | `—` | `—` | `—` | `—` | `—` *(Cấm tuyệt đối)* | `—` *(Cấm tuyệt đối)* |

### 6.6. Nhóm Tương Tác, Đánh Giá & Giải Quyết Khiếu Nại (Chat, Reviews, Disputes & Reports)
| Mã Quyền | Hành động / Chức năng | Guest (`ACT-01`) | Buyer Context (`ACT-02`) | Seller Context (`ACT-02`) | Moderator (`ACT-03`) | Support Staff (`ACT-04`) | Admin (`ACT-05`) | System (`ACT-06`) |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `PERM-CM-01` | Khởi tạo hội thoại, gửi & nhận tin nhắn Chat 1-1, đánh dấu đã đọc | `—` | `OWN` | `OWN` | `—` | `—` | `—` | `—` |
| `PERM-CM-02` | Chặn người dùng (`Block User`) hoặc báo cáo hội thoại vi phạm | `—` | `OWN` | `OWN` | `—` | `—` | `—` | `—` |
| `PERM-CM-03` | Đánh giá 1–5 sao & viết nhận xét người bán (1 lần/đơn khi đã `COMPLETED`) | `—` | `OWN` | `—` | `—` | `—` | `—` | `—` |
| `PERM-CM-04` | Kiểm duyệt / Ẩn bài đánh giá vi phạm tiêu chuẩn cộng đồng | `—` | `—` | `—` | `YES` | `—` | `YES` | `—` |
| `PERM-CM-05` | Mở khiếu nại (`Dispute`) kèm bằng chứng khi đơn ở trạng thái `SHIPPED` / `DELIVERED` | `—` | `OWN` | `—` | `—` | `—` | `—` | `—` |
| `PERM-CM-06` | Tự động khóa giải ngân Escrow ngay khi có khiếu nại hợp lệ được mở | `—` | `—` | `—` | `—` | `—` | `—` | `YES` |
| `PERM-CM-07` | Phản hồi khiếu nại và tải lên bằng chứng đối chứng (phía Người bán) | `—` | `OWN` | `OWN` | `—` | `—` | `—` | `—` |
| `PERM-CM-08` | Xem hồ sơ khiếu nại và gửi yêu cầu bổ sung bằng chứng (`REQUEST_MORE_EVIDENCE`) | `—` | `—` | `—` | `—` | `ASSIGNED` | `YES` | `—` |
| `PERM-CM-09` | Ra quyết định tài chính cuối cùng cho Khiếu nại (Hoàn tiền 100% `total_amount` / Giải ngân / Hoàn 1 phần / Từ chối) | `—` | `—` | `—` | `—` | `—` | `YES` | `—` |
| `PERM-CM-10` | Gửi báo cáo vi phạm sản phẩm/người dùng (`Submit Report`) | `—` | `YES` | `YES` | `—` | `—` | `—` | `—` |
| `PERM-CM-11` | Xem và xử lý danh sách Báo cáo vi phạm (`Reports`) | `—` | `—` | `—` | `YES` | `—` | `YES` | `—` |
| `PERM-CM-12` | Xem và đánh dấu đã đọc Thông báo trong ứng dụng (`In-App Notifications`) | `—` | `OWN` | `OWN` | `OWN` | `OWN` | `OWN` | `—` |

### 6.7. Nhóm Cấu Hình Hệ Thống, Nhật Ký Kiểm Toán & Demo Mode (System Settings, Audit & DevTools)
| Mã Quyền | Hành động / Chức năng | Guest (`ACT-01`) | Buyer Context (`ACT-02`) | Seller Context (`ACT-02`) | Moderator (`ACT-03`) | Support Staff (`ACT-04`) | Admin (`ACT-05`) | System (`ACT-06`) |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `PERM-AD-01` | Xem Dashboard thống kê tổng quan hệ thống | `—` | `—` | `—` | `YES` *(Giới hạn)* | `YES` *(Giới hạn)* | `YES` *(Toàn bộ)* | `—` |
| `PERM-AD-02` | Cấu hình **Buyer Protection Fee** (% phí + phí cố định), hạn thanh toán, hạn hoàn tất đơn | `—` | `—` | `—` | `—` | `—` | `YES` | `—` |
| `PERM-AD-03` | Xem nhật ký kiểm toán quản trị (`Audit Logs`) | `—` | `—` | `—` | `—` | `—` | `YES` | `—` |
| `PERM-AD-04` | Sử dụng **Developer Tools** (Chạy Manual Job Trigger & cấu hình thời gian Demo Mode) | `—` | `—` | `—` | `—` | `—` | `DEMO_ONLY` | `—` |

---

## 7. Quy Tắc Thực Thi Bảo Mật & Kiểm Toán Quyền Hạn (Security & Audit Enforcement Rules)
1. **Chặn tài khoản bị khóa ngay ở tầng Middleware (`CheckAccountStatus`):** Nếu một tài khoản có trạng thái `SUSPENDED` hoặc `BANNED`, mọi request gửi kèm Sanctum Token của tài khoản đó phải bị từ chối ngay lập tức với mã `403 Forbidden` và thu hồi token hiện hành.
2. **Bắt buộc ghi Audit Log cho các hành động nhạy cảm (`Auditable Actions`):** Mọi thao tác của `Moderator`, `Support Staff` và `Administrator` làm thay đổi trạng thái tài khoản, kiểm duyệt sản phẩm, thay đổi cấu hình hệ thống, kích hoạt Demo Job hoặc phân xử khiếu nại tài chính đều phải tự động ghi nhận vào bảng `audit_logs` (gồm `actor_id`, `action`, `target_type`, `target_id`, `old_values`, `new_values`, `ip_address`, `created_at`).
3. **Bảo vệ các API Nội bộ / Hệ thống:** Người dùng thông thường (`Registered User`) không bao giờ được cung cấp endpoint để tự truyền trạng thái `PAID`, `ESCROW_RELEASED` hay `AUCTION_WON`. Các chuyển đổi này chỉ được kích hoạt nội bộ từ `PaymentService`, `EscrowService` và `AuctionClosingService`.