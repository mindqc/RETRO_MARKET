# 05. USE CASE SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-PA04-UC`
- **Version:** `1.1.0 (FINAL APPROVED)`
- **Status:** `DONE`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 01 – Project Discovery & Requirement Analysis`

---

## 1. Danh Mục Tổng Hợp Use Case Toàn Hệ Thống (Master Use Case Catalog)

Hệ thống **RETRO MARKET (`izithrift`)** bao gồm **26 Use Case chuẩn hóa** chia theo 8 phân hệ nghiệp vụ, ánh xạ trực tiếp với `04_FUNCTIONAL_REQUIREMENTS.md` và `03_ACTOR_PERMISSION_MATRIX.md`:

| Mã UC | Tên Use Case | Primary Actor | Secondary / Supporting Actor | Liên kết FR | Phân loại |
| :--- | :--- | :--- | :--- | :--- | :---: |
| `UC-AU-01` | Đăng ký, Đăng nhập & Chuyển tiếp từ Guest Mode | `ACT-01` (Guest) | `ACT-02` (Registered User) | `FR-AU-01`..`FR-AU-05` | `MVP` |
| `UC-US-01` | Quản lý Hồ sơ Cá nhân, Hồ sơ Người bán & Sổ Địa chỉ | `ACT-02` (User) | — | `FR-US-01`..`FR-US-03` | `MVP` |
| `UC-SL-01` | Đăng bán Sản phẩm mới (Fixed Price & Auction) | `ACT-02` (Seller) | — | `FR-SL-01`..`FR-SL-03` | `MVP` |
| `UC-SL-02` | Quản lý Bài đăng, Chỉnh sửa & Gửi duyệt lại sản phẩm bị `REJECTED` | `ACT-02` (Seller) | — | `FR-SL-04`..`FR-SL-06` | `MVP` |
| `UC-MD-01` | Kiểm duyệt Sản phẩm (`APPROVED` / `REJECTED`) | `ACT-03` (Moderator), `ACT-05` (Admin) | `ACT-02` (Seller - nhận thông báo) | `FR-MD-01`, `FR-MD-02` | `MVP` |
| `UC-DS-01` | Khám phá Trang chủ, Tìm kiếm, Lọc & Xem Chi tiết Sản phẩm | `ACT-01` (Guest), `ACT-02` (Buyer) | — | `FR-CT-01`, `FR-DS-01`..`FR-DS-03` | `MVP` |
| `UC-DS-02` | Lưu Sản phẩm Yêu thích & Theo dõi Người bán | `ACT-02` (Buyer) | — | `FR-DS-04`, `FR-US-04` | `ENHANCEMENT` |
| `UC-CR-01` | Quản lý Giỏ hàng (Nhóm theo từng Người bán) | `ACT-02` (Buyer) | — | `FR-CR-01` | `MVP` |
| `UC-OR-01` | Xem trước Checkout, Tính Buyer Protection Fee & Tạo Đơn hàng Snapshot | `ACT-02` (Buyer) | — | `FR-OR-01`, `FR-OR-02` | `MVP` |
| `UC-PM-01` | Thanh toán QR Mô phỏng & Khởi tạo Khoản Giữ Tiền (`ESCROW_HOLD`) | `ACT-02` (Buyer) | `ACT-06` (System Escrow Engine) | `FR-PM-01`, `FR-PM-02`, `FR-ES-01` | `MVP` |
| `UC-OR-02` | Hủy Đơn hàng & Yêu cầu Hủy đơn theo Trạng thái (`PENDING_PAYMENT` / `PAID` / `PREPARING`) | `ACT-02` (Buyer / Seller) | `ACT-06` (System Refund Engine) | `FR-OR-03` | `MVP` |
| `UC-SH-01` | Xác nhận Chuẩn bị hàng & Cập nhật Vận chuyển Thủ công (`PREPARING` $\rightarrow$ `SHIPPED` $\rightarrow$ `DELIVERED`) | `ACT-02` (Seller) | `ACT-02` (Buyer - theo dõi) | `FR-SH-01`, `FR-SH-02` | `MVP` |
| `UC-ES-01` | Xác nhận Nhận hàng / Tự động Hoàn tất sau 24h & Giải ngân 100% Tiền hàng cho Seller | `ACT-02` (Buyer), `ACT-06` (Scheduler) | `ACT-05` (Admin Demo Trigger) | `FR-SH-02`, `FR-ES-02` | `MVP` |
| `UC-AC-01` | Cấu hình Khung giờ Phiên Đấu giá Hàng ngày (`Auction Sessions`) | `ACT-05` (Admin) | `ACT-06` (Scheduler) | `FR-AC-01` | `MVP` |
| `UC-AC-02` | Tham gia Trả giá Đấu giá Đồng thời (`Place Bid`) & Gia hạn Anti-Sniping | `ACT-02` (Buyer) | `ACT-06` (System Bid Engine) | `FR-AC-02`, `FR-AC-03` | `MVP` |
| `UC-AC-03` | Người bán Chốt Phiên Đấu giá Sớm (`Seller Early Close`) | `ACT-02` (Seller) | `ACT-06` (System Order Engine) | `FR-AC-04` | `MVP` |
| `UC-AC-04` | Đóng Phiên Đấu giá Tự động, Xác định Người thắng & Xử lý Đơn Quá hạn Thanh toán | `ACT-06` (Scheduler) | `ACT-05` (Admin Demo Trigger), `ACT-02` | `FR-AC-05`, `FR-AC-06` | `MVP` |
| `UC-RV-01` | Đánh giá & Nhận xét Người bán sau khi Hoàn tất Đơn hàng | `ACT-02` (Buyer) | `ACT-03`, `ACT-05` (Kiểm duyệt) | `FR-RV-01` | `MVP` |
| `UC-DP-01` | Mở Khiếu nại (`SHIPPED` / `DELIVERED`), Khóa Giải ngân & Đối chứng Bằng chứng | `ACT-02` (Buyer) | `ACT-02` (Seller), `ACT-04` (Support) | `FR-DP-01`, `FR-DP-02` | `MVP` |
| `UC-DP-02` | Phân xử Khiếu nại & Thực thi Quyết định Tài chính (`REFUND` / `RELEASE` / `PARTIAL`) | `ACT-05` (Admin) | `ACT-04` (Support Staff) | `FR-DP-02`, `FR-DP-03` | `MVP` |
| `UC-CM-01` | Nhắn tin 1-1 giữa Người mua và Người bán (HTTP Polling Chat) | `ACT-02` (Buyer / Seller) | — | `FR-CM-01` | `ENHANCEMENT` |
| `UC-NT-01` | Nhận, Xem & Đánh dấu đã đọc Thông báo trong Ứng dụng | `ACT-02`..`ACT-05` | `ACT-06` (System Event) | `FR-NT-01` | `ENHANCEMENT` |
| `UC-AD-01` | Quản trị Tài khoản, Danh mục, Thương hiệu, Báo cáo & Audit Logs | `ACT-05` (Admin), `ACT-03` (Mod) | — | `FR-AD-01`..`FR-AD-03`, `FR-AD-06` | `MVP` |
| `UC-AD-02` | Cấu hình Thông số Hệ thống, **Buyer Protection Fee** & Vận hành **Demo Mode Developer Tools** | `ACT-05` (Admin) | `ACT-06` (System Services) | `FR-AD-04`, `FR-AD-05` | `MVP` |

---

## 2. Đặc Tả Chi Tiết Các Use Case Trọng Tâm (Detailed Use Case Specifications)

### `UC-AU-01`: Đăng ký, Đăng nhập & Chuyển tiếp từ Guest Mode
| Thành phần | Nội dung đặc tả |
| :--- | :--- |
| **Actor** | **Primary:** `ACT-01` (Guest), `ACT-02` (Registered User) |
| **Liên kết** | `FR-AU-01`..`FR-AU-05` \| `PERM-AU-01`, `PERM-AU-02` \| `DEC-01` |
| **Preconditions** | Ứng dụng `izithrift` kết nối thành công tới Backend API (`/api/v1`). Người dùng đang mở ứng dụng ở chế độ `Guest` hoặc tại màn hình xác thực. |
| **Main Flow (Đăng nhập & Chuyển tiếp)** | 1. `Guest` duyệt xem sản phẩm/đấu giá công khai và nhấn vào một hành động yêu cầu định danh (ví dụ: *Thêm vào giỏ*, *Mua ngay*, *Đặt giá thầu*, *Đăng bán*, *Chat*).<br>2. Ứng dụng chặn thao tác và điều hướng tới màn hình **Login**.<br>3. Người dùng nhập `email` và `password`, nhấn **Đăng nhập**.<br>4. Backend kiểm tra thông tin đăng nhập, xác nhận trạng thái tài khoản là `ACTIVE`, sinh `Sanctum Token` và trả về thông tin user kèm roles.<br>5. Ứng dụng lưu token vào `flutter_secure_storage`, cập nhật trạng thái phiên đăng nhập và đưa người dùng quay lại màn hình/hành động vừa thực hiện. |
| **Alternative Flow (A1 – Đăng ký mới)** | Tại bước 3, người dùng chọn **Đăng ký**:<br>1. Nhập `display_name`, `email`, `password`, `password_confirmation`.<br>2. Backend kiểm tra `email` chưa tồn tại, băm mật khẩu, khởi tạo bản ghi trong `users`, `user_profiles`, `seller_profiles` và gán role `Registered User` dentro một `DB::transaction()`.<br>3. Cấp token và đăng nhập tự động. |
| **Alternative Flow (A2 – Quên mật khẩu)** | Người dùng chọn **Quên mật khẩu**, nhập `email` $\rightarrow$ Backend gửi mã/link khôi phục qua Mailpit/Log driver (môi trường local) $\rightarrow$ Người dùng đặt lại mật khẩu mới. |
| **Exception Flow** | - **E1 (Sai thông tin):** Email hoặc mật khẩu không khớp $\rightarrow$ Backend trả lỗi `401 Unauthorized`, hiển thị thông báo lỗi.<br>- **E2 (Tài khoản bị khóa):** Tài khoản có trạng thái `SUSPENDED` hoặc `BANNED` $\rightarrow$ Backend trả lỗi `403 Forbidden` kèm lý do khóa, từ chối cấp token.<br>- **E3 (Vượt quá giới hạn thử):** Nhập sai liên tiếp quá ngưỡng cho phép $\rightarrow$ Backend trả lỗi `429 Too Many Requests` (Rate Limiting). |
| **Postconditions** | Người dùng chuyển sang trạng thái `Authenticated` (`ACT-02`), có đầy đủ quyền Mua và Bán trên cùng một tài khoản. |

---

### `UC-SL-01`: Đăng bán Sản phẩm mới (Fixed Price & Auction Listing)
| Thành phần | Nội dung đặc tả |
| :--- | :--- |
| **Actor** | **Primary:** `ACT-02` (Registered User trong ngữ cảnh **Seller**) |
| **Liên kết** | `FR-SL-01`..`FR-SL-03` \| `PERM-PR-03`, `PERM-PR-04` |
| **Preconditions** | Người dùng đã đăng nhập (`ACT-02`) và tài khoản đang ở trạng thái `ACTIVE`. Danh mục (`Categories`) và khung giờ phiên đấu giá (`Auction Sessions` cho trường hợp đấu giá) đã tồn tại trong CSDL. |
| **Main Flow (Gửi kiểm duyệt)** | 1. Người bán truy cập **Seller Center**, chọn **Đăng sản phẩm mới**.<br>2. Tải lên từ 1 đến nhiều hình ảnh sản phẩm và ảnh bằng chứng xác thực (`authenticity_evidence` nếu có).<br>3. Nhập tên sản phẩm, chọn Danh mục, Thương hiệu, Tình trạng (`condition`), nhập mô tả chi tiết và khai báo rõ thông tin lỗi/vết xước (`defect_info`).<br>4. Chọn loại hình bán (`listing_type`):<br>   - **Nếu chọn `FIXED_PRICE`:** Nhập giá bán cố định (`price > 0`) và số lượng khả dụng (`available_quantity >= 1`).<br>   - **Nếu chọn `AUCTION`:** Chọn khung giờ phiên đấu giá (`auction_session_id`), nhập giá khởi điểm (`starting_price > 0`), bước giá tối thiểu (`min_bid_increment > 0`) và giá sàn tùy chọn (`reserve_price`). Số lượng tự động khóa là `1`.<br>5. Người bán xem trước bài đăng (`Preview`) và nhấn **Gửi kiểm duyệt (Submit for Review)**.<br>6. Backend kiểm tra tính hợp lệ dữ liệu, lưu ảnh vào Local Filesystem, tạo bản ghi `products` (và bản ghi cấu hình `auctions` nếu là đấu giá) với trạng thái `PENDING_REVIEW`. |
| **Alternative Flow (A1 – Lưu bản nháp)** | Tại bước 5, người bán nhấn **Lưu nháp (Save Draft)**:<br>1. Hệ thống lưu sản phẩm với trạng thái `DRAFT` (cho phép thiếu một số trường chưa hoàn thiện).<br>2. Sản phẩm chỉ hiển thị trong tab `Draft` của Seller Center, chưa gửi vào hàng chờ của Moderator. |
| **Exception Flow** | - **E1 (Dữ liệu không hợp lệ):** Thiếu ảnh bắt buộc, giá $\le 0$, bước giá $\le 0$, hoặc chưa chọn danh mục $\rightarrow$ Backend trả lỗi `422 Unprocessable Entity` kèm chi tiết trường lỗi.<br>- **E2 (File ảnh vượt dung lượng/sai định dạng):** File không phải ảnh hợp lệ (`jpg`, `png`, `webp`) hoặc vượt kích thước cho phép $\rightarrow$ Từ chối tải lên và báo lỗi. |
| **Postconditions** | Bản ghi `products` có trạng thái `PENDING_REVIEW` (hoặc `DRAFT`). Sản phẩm **chưa** xuất hiện trên trang khám phá công khai hay trong phiên đấu giá công khai cho đến khi được Moderator/Admin duyệt. |

---

### `UC-MD-01`: Kiểm duyệt Sản phẩm (`APPROVED` / `REJECTED`) & Gửi duyệt lại (`Resubmit`)
| Thành phần | Nội dung đặc tả |
| :--- | :--- |
| **Actor** | **Primary:** `ACT-03` (Moderator) hoặc `ACT-05` (Administrator)<br>**Secondary:** `ACT-02` (Seller) |
| **Liên kết** | `FR-MD-01`, `FR-MD-02`, `FR-SL-05` \| `PERM-PR-06`, `PERM-PR-07` \| `DEC-05` |
| **Preconditions** | Quản trị viên đã đăng nhập vào **Admin Dashboard (Laravel Blade)** với quyền `Moderator` hoặc `Admin`. Có sản phẩm đang ở trạng thái `PENDING_REVIEW`. |
| **Main Flow (Phê duyệt – Approve)** | 1. Moderator mở trang **Product Moderation Queue** và chọn một sản phẩm `PENDING_REVIEW`.<br>2. Hệ thống hiển thị toàn bộ ảnh sản phẩm, mô tả tình trạng, khai báo lỗi (`defect_info`), bằng chứng xác thực, thông tin/lịch sử vi phạm của Seller và lịch sử kiểm duyệt cũ (`product_moderation_logs`).<br>3. Moderator kiểm tra tính hợp lệ, chọn mức độ xác minh thông tin (`verification_level`), nhập ghi chú kiểm duyệt và nhấn **Approve**.<br>4. Backend thực thi trong `DB::transaction()`:<br>   - Chuyển trạng thái sản phẩm sang `APPROVED`.<br>   - Nếu là hàng `AUCTION`, gán sản phẩm vào phiên đấu giá đã đăng ký (trạng thái `SCHEDULED`).<br>   - Ghi bản ghi mới vào `product_moderation_logs` và `audit_logs`.<br>   - Tạo thông báo `In-App Notification` báo cho Seller biết sản phẩm đã được duyệt. |
| **Alternative Flow (A1 – Từ chối / Yêu cầu chỉnh sửa – Reject)** | Tại bước 3, nếu sản phẩm thiếu ảnh thực tế, mô tả tình trạng không trung thực hoặc vi phạm quy định (`DEC-05`):<br>1. Moderator nhấn **Reject**, bắt buộc nhập lý do từ chối / hướng dẫn chỉnh sửa chi tiết (`reason`).<br>2. Backend chuyển trạng thái sản phẩm sang `REJECTED`, lưu `product_moderation_logs` + `audit_logs` và gửi thông báo kèm lý do cho Seller.<br>3. **Luồng Seller gửi duyệt lại (`UC-SL-02`):** Seller mở tab `Rejected` trên app Flutter, xem lýể do từ chối, sửa lại thông tin/ảnh theo yêu cầu và nhấn **Gửi duyệt lại (`Resubmit`)** $\rightarrow$ Sản phẩm chuyển từ `REJECTED` về lại `PENDING_REVIEW`. |
| **Exception Flow** | - **E1 (Thiếu lý do từ chối):** Moderator bấm `Reject` nhưng để trống trường lý do $\rightarrow$ Hệ thống chặn và yêu cầu nhập lý do bắt buộc.<br>- **E2 (Duyệt trùng đồng thời):** Sản phẩm đã được một Moderator khác xử lý trước đó vài giây (không còn ở trạng thái `PENDING_REVIEW`) $\rightarrow$ Backend báo lỗi xung đột trạng thái, không ghi đè quyết định. |
| **Postconditions** | Sản phẩm chuyển sang `APPROVED` (hiển thị công khai trên sàn) hoặc `REJECTED` (chờ người bán chỉnh sửa). Lịch sử kiểm duyệt và Audit Log được lưu vết đầy đủ. |

---

### `UC-DS-01`: Khám phá Trang chủ, Tìm kiếm, Lọc & Xem Chi tiết Sản phẩm
| Thành phần | Nội dung đặc tả |
| :--- | :--- |
| **Actor** | **Primary:** `ACT-01` (Guest), `ACT-02` (Buyer) |
| **Liên kết** | `FR-CT-01`, `FR-DS-01`..`FR-DS-03` \| `PERM-PR-01` \| `DEC-01` |
| **Preconditions** | Trong CSDL có các sản phẩm ở trạng thái `APPROVED` và các phiên đấu giá đang hoạt động. |
| **Main Flow** | 1. Người dùng mở ứng dụng `izithrift`, xem Trang chủ với Hero Banner Giáng sinh, các bộ sưu tập vintage, sản phẩm mới đăng và phiên đấu giá đang diễn ra.<br>2. Người dùng nhập từ khóa vào thanh tìm kiếm hoặc chọn một Danh mục (`Category`), kết hợp mở Bottom Sheet bộ lọc (Tình trạng `condition`, Khoảng giá, Loại hình bán `Fixed Price` / `Auction`) và chọn tiêu chí sắp xếp.<br>3. Backend truy vấn PostgreSQL (chỉ lấy các bản ghi `APPROVED`), trả về danh sách phân trang.<br>4. Người dùng nhấn vào một thẻ sản phẩm (`Product Card`) để mở màn hình **Product Detail**.<br>5. Hệ thống hiển thị ảnh chi tiết, giá, tình trạng, lỗi sản phẩm (`defect_info`), mức độ xác minh, thông tin người bán, điểm đánh giá và các nút hành động tương ứng với loại hình bán. |
| **Alternative Flow (A1 – Xem sản phẩm Đấu giá)** | Nếu sản phẩm có `listing_type = AUCTION`, màn hình Product Detail tự động thay thế cụm nút `Thêm vào giỏ / Mua ngay` bằng thông tin phiên đấu giá (Giá hiện tại, Bước giá tối thiểu, Đồng hồ đếm ngược, Lịch sử trả giá) và nút **Đặt giá thầu (`Place Bid`)**. |
| **Exception Flow** | - **E1 (Không tìm thấy kết quả):** Bộ lọc không khớp sản phẩm nào $\rightarrow$ Hiển thị giao diện `Empty State` phong cách Vintage kèm nút xóa bộ lọc.<br>- **E2 (Sản phẩm vừa bị ẩn/bán hết khi bấm vào):** Hiển thị trạng thái sản phẩm đã bán (`SOLD`) hoặc không còn khả dụng, vô hiệu hóa nút mua. |
| **Postconditions** | Người dùng xem được thông tin minh bạch của sản phẩm để ra quyết định thêm vào giỏ hàng, trả giá hoặc chat với người bán. |

---

### `UC-CR-01` & `UC-OR-01`: Quản lý Giỏ hàng, Tính Phí Bảo Vệ Người Mua & Tạo Đơn hàng Snapshot
| Thành phần | Nội dung đặc tả |
| :--- | :--- |
| **Actor** | **Primary:** `ACT-02` (Registered User trong ngữ cảnh **Buyer**) |
| **Liên kết** | `FR-CR-01`, `FR-OR-01`, `FR-OR-02` \| `PERM-OR-01`..`PERM-OR-03` \| `DEC-04` |
| **Preconditions** | Người mua đã đăng nhập (`ACT-02`), đã có ít nhất 1 địa chỉ nhận hàng (hoặc thêm mới tại bước Checkout). Sản phẩm thuộc loại `FIXED_PRICE`, có trạng thái `APPROVED`, `available_quantity >= 1` và `seller_id != auth()->id()`. |
| **Main Flow** | 1. Từ màn hình Chi tiết sản phẩm, Buyer nhấn **Thêm vào giỏ hàng** (hoặc **Mua ngay**).<br>2. Trong màn hình **Giỏ hàng (Cart)**, các sản phẩm được gom nhóm theo từng **Người bán (Seller)**. Buyer tích chọn các sản phẩm thuộc **cùng 1 Người bán** và nhấn **Thanh toán (Checkout)**.<br>3. Hệ thống gọi API `Checkout Preview` (`/orders/checkout-preview`): Backend kiểm tra lại giá hiện tại, tồn kho và tính toán chi phí theo quyết định `DEC-04`:<br>   - `item_subtotal` = $\sum (\text{price} \times \text{quantity})$.<br>   - `shipping_fee` = `0 VNĐ` (Miễn thu phí vận chuyển trên app).<br>   - `buyer_protection_fee` = `(item_subtotal * protection_fee_rate) + protection_fixed_fee` (lấy từ `platform_settings`).<br>   - `total_amount` = `item_subtotal + buyer_protection_fee`.<br>4. Buyer kiểm tra địa chỉ nhận hàng, bảng kê chi phí minh bạch và nhấn **Đặt hàng (Place Order)**.<br>5. Backend mở `DB::transaction()` và khóa dòng (`lockForUpdate()`) trên các bản ghi `products`:<br>   - Kiểm tra lại `available_quantity >= requested_quantity` và trạng thái `APPROVED`.<br>   - Trừ `available_quantity` (nếu về `0`, cập nhật trạng thái sản phẩm để chặn người khác mua tiếp).<br>   - Tạo bản ghi `orders` với: `order_status = PENDING_PAYMENT`, `payment_status = UNPAID`, `escrow_status = NONE`, lưu tách biệt `item_subtotal`, `buyer_protection_fee`, `total_amount` và tính cứng `payment_expires_at`.<br>   - Tạo các bản ghi `order_items` chứa **bản chụp (snapshot)** tên sản phẩm, giá đơn vị, tình trạng, mô tả lỗi và đường dẫn ảnh tại thời điểm mua.<br>   - Xóa các mục vừa đặt khỏi giỏ hàng của Buyer.<br>6. Điều hướng Buyer sang màn hình **Thanh toán QR Mô phỏng (`UC-PM-01`)**. |
| **Alternative Flow (A1 – Giỏ hàng có sản phẩm của nhiều Người bán)** | Nếu Buyer chọn sản phẩm của nhiều Seller khác nhau, hệ thống yêu cầu chọn thanh toán từng nhóm theo từng Seller (mỗi đơn hàng chỉ thuộc 1 Seller duy nhất). |
| **Exception Flow** | - **E1 (Người bán tự mua hàng của mình):** Nếu `auth()->id() == product.seller_id` $\rightarrow$ Backend từ chối với lỗi `403 Forbidden`.<br>- **E2 (Hết hàng đồng thời – Race Condition):** Người mua khác vừa đặt món hàng cuối cùng trước đó tích tắc $\rightarrow$ Nhờ `lockForUpdate()`, transaction thứ hai phát hiện `available_quantity < requested_quantity`, rollback và trả thông báo sản phẩm vừa hết hàng.<br>- **E3 (Sản phẩm đổi giá/bị ẩn trước lúc bấm Đặt hàng):** Backend phát hiện sai lệch so với lúc xem trước $\rightarrow$ Yêu cầu Buyer làm mới lại Checkout Preview. |
| **Postconditions** | Đơn hàng mới được tạo ở trạng thái `PENDING_PAYMENT` kèm đầy đủ dữ liệu snapshot và cấu trúc phí `Buyer Protection Fee`. Tồn kho sản phẩm được giữ chỗ. |

---

### `UC-PM-01`: Thanh toán QR Mô phỏng & Khởi tạo Khoản Giữ Tiền (`ESCROW_HOLD`)
| Thành phần | Nội dung đặc tả |
| :--- | :--- |
| **Actor** | **Primary:** `ACT-02` (Buyer)<br>**Secondary:** `ACT-06` (System Escrow Engine) |
| **Liên kết** | `FR-PM-01`, `FR-PM-02`, `FR-ES-01` \| `PERM-FN-01`..`PERM-FN-03` \| `DEC-04` |
| **Preconditions** | Đơn hàng (mua thẳng hoặc thắng đấu giá) đang ở trạng thái `order_status = PENDING_PAYMENT`, `payment_status = UNPAID` và thời gian hiện tại còn trong hạn `now() < payment_expires_at`. |
| **Main Flow** | 1. Buyer mở màn hình Thanh toán của đơn hàng. Hệ thống gọi API khởi tạo phiên thanh toán (`POST /payments/create`).<br>2. Backend tạo bản ghi `payments` với mã tham chiếu duy nhất (`payment_reference`), số tiền `amount = order.total_amount`, trạng thái `PENDING`, và trả về payload mã QR.<br>3. Ứng dụng Flutter hiển thị mã QR, mã đơn hàng, số tiền `total_amount` (gồm tiền hàng + Phí bảo vệ người mua), đồng hồ đếm ngược đến `payment_expires_at` và nút kiểm thử **"Mô phỏng Thanh toán Thành công" (Simulate Payment Success)**.<br>4. Buyer quét mã QR mô phỏng hoặc nhấn nút **Simulate Payment Success** (`POST /payments/{id}/simulate-success`).<br>5. Backend mở `DB::transaction()` và dùng `lockForUpdate()` trên bản ghi `orders` và `payments`:<br>   - Kiểm tra đơn hàng chưa được thanh toán (`payment_status != PAID`) và chưa hết hạn.<br>   - Cập nhật `payments.status = PAID`, `paid_at = now()`.<br>   - Cập nhật `orders.payment_status = PAID`, `orders.order_status = PAID`, `orders.escrow_status = HELD`.<br>   - **Ghi sổ cái bất biến (`escrow_transactions`):** Thêm mới 1 dòng giao dịch loại `HOLD` với số tiền `order.total_amount` (ghi rõ phần `item_subtotal` của Seller và phần `buyer_protection_fee`).<br>   - Tạo thông báo `In-App Notification` cho cả Buyer (thanh toán thành công, tiền đã được bảo vệ trong Escrow) và Seller (có đơn hàng mới đã thanh toán, chờ chuẩn bị hàng). |
| **Alternative Flow (A1 – Mô phỏng Thanh toán Thất bại & Thử lại)** | Buyer nhấn mô phỏng thất bại $\rightarrow$ Bản ghi `payments` hiện tại chuyển sang `FAILED`, đơn hàng vẫn ở `PENDING_PAYMENT`. Buyer có thể tạo phiên thanh toán mới nếu vẫn còn trong thời hạn `payment_expires_at`. |
| **Exception Flow** | - **E1 (Nhấn thanh toán 2 lần liên tiếp – Double Payment Attempt):** Request thứ hai bị chặn bởi row lock và kiểm tra `payment_status == PAID` $\rightarrow$ Trả về kết quả idempotent hoặc mã lỗi `409 Conflict`, tuyệt đối không tạo 2 bút toán `ESCROW_HOLD`.<br>- **E2 (Quá thời hạn thanh toán):** `now() >= payment_expires_at` $\rightarrow$ Từ chối thanh toán, đơn hàng được chuyển sang trạng thái hết hạn/hủy. |
| **Postconditions** | Trạng thái đơn hàng: `order_status = PAID`, `payment_status = PAID`, `escrow_status = HELD`. Tiền nằm an toàn trong sổ cái giữ tiền trung gian, chưa cộng vào số dư khả dụng của Seller. |

---

### `UC-OR-02`: Hủy Đơn hàng & Yêu cầu Hủy đơn theo Trạng thái (`DEC-06`, `DEC-07`)
| Thành phần | Nội dung đặc tả |
| :--- | :--- |
| **Actor** | **Primary:** `ACT-02` (Buyer hoặc Seller)<br>**Secondary:** `ACT-06` (System Refund Engine) |
| **Liên kết** | `FR-OR-03` \| `PERM-OR-05A`, `PERM-OR-05B`, `PERM-FN-04B` \| `DEC-06`, `DEC-07` |
| **Preconditions** | Đơn hàng đang ở một trong các trạng thái: `PENDING_PAYMENT`, `PAID` hoặc `PREPARING`. |
| **Main Flow (Hủy trực tiếp khi ở `PAID` – Seller chưa bấm `PREPARING`)** | 1. Khi đơn hàng đang ở trạng thái `PAID` (Seller chưa xác nhận chuẩn bị hàng), **Buyer** hoặc **Seller** nhấn nút **Hủy đơn hàng**, chọn lý do hủy và xác nhận.<br>2. Backend mở `DB::transaction()` và khóa dòng đơn hàng (`lockForUpdate()`):<br>   - Kiểm tra đúng điều kiện `order_status == PAID`.<br>   - Chuyển `order_status = CANCELLED`, `escrow_status = REFUNDED`.<br>   - **Hoàn tiền 100% (`DEC-07`):** Tạo bản ghi trong bảng `refunds` và thêm mới bút toán `REFUND` vào `escrow_transactions` với số tiền bằng đúng **100% `total_amount` (`item_subtotal` + `buyer_protection_fee`)** hoàn về cho Buyer.<br>   - Khôi phục lại số lượng tồn kho (`available_quantity`) và trạng thái `APPROVED` cho sản phẩm (nếu là đơn Fixed Price).<br>   - Gửi thông báo cho bên còn lại. |
| **Alternative Flow (A1 – Hủy khi ở `PENDING_PAYMENT`)** | Buyer nhấn Hủy đơn khi chưa thanh toán $\rightarrow$ Đơn chuyển ngay sang `CANCELLED`, khôi phục tồn kho sản phẩm, không phát sinh giao dịch tài chính vì chưa thu tiền. |
| **Alternative Flow (A2 – Hủy khi đơn đã ở `PREPARING`)** | 1. **Nếu người thao tác là Seller:** Seller bấm Hủy đơn (do phát hiện hàng lỗi/không thể giao) $\rightarrow$ Hệ thống hủy đơn ngay lập tức và hoàn trả **100% `total_amount`** cho Buyer như Main Flow.<br>2. **Nếu người thao tác là Buyer (`DEC-06`):** Vì Seller đã bắt đầu đóng gói (`PREPARING`), Buyer không thể tự hủy ngang mà chỉ được bấm **"Gửi yêu cầu hủy đơn" (`Request Cancellation`)**:<br>   - Hệ thống đánh dấu đơn có yêu cầu hủy (`cancellation_requested = true`) và thông báo cho Seller.<br>   - **Nếu Seller bấm Đồng ý (`Approve Cancellation`):** Đơn chuyển sang `CANCELLED` và hoàn trả **100% `total_amount`** cho Buyer.<br>   - **Nếu Seller bấm Từ chối (`Reject Cancellation`) và giao hàng:** Đơn tiếp tục chuyển sang `SHIPPED`. |
| **Exception Flow** | - **E1 (Gọi API hủy đơn khi đã `SHIPPED` / `DELIVERED`):** Backend từ chối với lỗi `422/403` (ở giai đoạn này Buyer phải sử dụng luồng Mở Khiếu nại `UC-DP-01`). |
| **Postconditions** | Đơn hàng hủy hợp lệ chuyển sang `CANCELLED`, tồn kho được hoàn lại, và Buyer nhận lại đủ 100% số tiền đã thanh toán (bao gồm cả Phí bảo vệ người mua). |

---

### `UC-SH-01` & `UC-ES-01`: Vận chuyển Thủ công, Xác nhận Nhận hàng / Tự động Hoàn tất sau 24h & Giải ngân Escrow
| Thành phần | Nội dung đặc tả |
| :--- | :--- |
| **Actor** | **Primary:** `ACT-02` (Seller & Buyer), `ACT-06` (System Scheduler)<br>**Secondary:** `ACT-05` (Admin qua Demo Mode Trigger) |
| **Liên kết** | `FR-SH-01`, `FR-SH-02`, `FR-ES-02` \| `PERM-OR-06`..`PERM-OR-09`, `PERM-FN-04` \| `DEC-04` |
| **Preconditions** | Đơn hàng đang ở trạng thái `order_status = PAID` và `escrow_status = HELD`. |
| **Main Flow (Giao hàng & Buyer chủ động Xác nhận Nhận hàng)** | 1. **Chuẩn bị hàng:** Seller mở chi tiết đơn bán, nhấn **Xác nhận chuẩn bị hàng** $\rightarrow$ Backend chuyển `order_status` từ `PAID` sang `PREPARING`.<br>2. **Gửi hàng:** Seller đóng gói hàng, nhập tên đơn vị vận chuyển, mã vận đơn (`tracking_code`) và nhấn **Xác nhận đã gửi hàng** $\rightarrow$ Backend tạo bản ghi `shipments` và chuyển `order_status` sang `SHIPPED`.<br>3. **Giao hàng thành công:** Khi bưu kiện tới nơi, Seller cập nhật trạng thái đơn sang **`DELIVERED`**. Ngay lúc này, Backend ghi nhận `delivered_at = now()` và tính cứng mốc thời gian tự động hoàn tất `auto_complete_at = now() + auto_complete_duration` (24 giờ ở Production Mode / 2 phút ở Demo Mode).<br>4. **Buyer xác nhận nhận hàng:** Buyer kiểm tra món đồ 2hand đúng mô tả, nhấn nút **Đã nhận được hàng (`Confirm Delivery`)** trên app.<br>5. **Giải ngân Escrow (`Release Escrow`):** Backend mở `DB::transaction()` kèm `lockForUpdate()`:<br>   - Kiểm tra `order_status == DELIVERED`, `escrow_status == HELD` và **không có khiếu nại đang mở (`dispute_status != OPEN`)**.<br>   - Chuyển `order_status = COMPLETED`, `escrow_status = RELEASED`.<br>   - Thêm bút toán `RELEASE` vào `escrow_transactions` và thêm bút toán `CREDIT` vào `wallet_transactions` của Seller với số tiền bằng đúng **100% tiền hàng (`item_subtotal`)** (`DEC-04`). Khoản `buyer_protection_fee` được hạch toán làm phí dịch vụ bảo vệ của nền tảng.<br>   - Cập nhật số dư ví khả dụng của Seller và gửi thông báo cho hai bên. |
| **Alternative Flow (A1 – Tự động Hoàn tất sau 24 giờ bởi System Scheduler / Demo Trigger)** | Tại bước 4, nếu Buyer quên không bấm xác nhận nhận hàng và cũng không mở khiếu nại:<br>1. Khi `now() >= order.auto_complete_at` (hoặc khi Admin kích hoạt job `Auto Complete Delivered Orders` trong Developer Tools ở Demo Mode).<br>2. Scheduled Job quét các đơn có `order_status = DELIVERED`, `escrow_status = HELD`, `dispute_status != OPEN` và `auto_complete_at <= now()`.<br>3. Với mỗi đơn, Job gọi cùng hàm Service giải ngân ở Bước 5 (bảo vệ bằng `lockForUpdate()` để đảm bảo tính lũy đẳng idempotent). |
| **Exception Flow** | - **E1 (Đơn đang có Khiếu nại mở):** Nếu Buyer đã mở khiếu nại (`dispute_status == OPEN`) trước mốc `auto_complete_at` $\rightarrow$ Scheduled Job bắt buộc bỏ qua đơn hàng này, giữ nguyên `escrow_status = HELD` chờ Admin phân xử.<br>- **E2 (Job chạy lặp 2 lần cùng lúc):** Nhờ kiểm tra trạng thái trong row lock, lần chạy thứ 2 thấy `escrow_status == RELEASED` sẽ tự động bỏ qua, không cộng tiền 2 lần cho Seller. |
| **Postconditions** | Đơn hàng đạt trạng thái `COMPLETED`, `escrow_status = RELEASED`. Seller nhận đủ 100% tiền hàng vào ví, và Buyer được mở quyền Đánh giá người bán (`UC-RV-01`). |

---

### `UC-AC-02`, `UC-AC-03` & `UC-AC-04`: Đấu giá Đồng thời, Anti-Sniping, Chốt sớm & Xử lý Đơn thắng Đấu giá
| Thành phần | Nội dung đặc tả |
| :--- | :--- |
| **Actor** | **Primary:** `ACT-02` (Buyer & Seller), `ACT-06` (System Scheduler)<br>**Secondary:** `ACT-05` (Admin Demo Trigger) |
| **Liên kết** | `FR-AC-01`..`FR-AC-06` \| `PERM-AC-03`..`PERM-AC-07` \| `DEC-02`, `DEC-04` |
| **Preconditions** | Sản phẩm đấu giá đã được duyệt (`APPROVED`) và phiên đấu giá đang trong khung giờ hoạt động (`auction.status = LIVE`, `now() < auction_ends_at`). |
| **Main Flow (Đặt giá thầu, Anti-sniping & Đóng phiên tạo đơn)** | 1. Buyer mở màn hình **Auction Detail** trong **Auction Hub**, xem giá cao nhất hiện tại (`current_highest_bid`), bước giá tối thiểu (`min_bid_increment`) và đồng hồ đếm ngược.<br>2. Buyer nhập mức giá thầu `bid_amount` và nhấn **Đặt giá (`Place Bid`)**.<br>3. Backend mở `DB::transaction()` và khóa dòng bản ghi `auctions` (`SELECT ... FOR UPDATE`):<br>   - Kiểm tra phiên còn `LIVE` và `now() < auction_ends_at` (dựa trên giờ chuẩn của máy chủ Backend, không tin cậy đồng hồ client).<br>   - Kiểm tra `auth()->id() != auction.seller_id` (chặn người bán tự trả giá).<br>   - Kiểm tra `bid_amount >= current_highest_bid + min_bid_increment` (hoặc `>= starting_price` nếu chưa có lượt bid nào).<br>   - Lưu vĩnh viễn bản ghi mới vào `auction_bids`, cập nhật `current_highest_bid = bid_amount` và `leading_bidder_id = auth()->id()`.<br>   - **Kiểm tra Anti-Sniping (`FR-AC-03`):** Nếu thời gian còn lại `(auction_ends_at - now()) <= anti_sniping_window` (2 phút ở Production / 30 giây ở Demo Mode), hệ thống tự động cộng thêm `anti_sniping_extension` (+2 phút / +30 giây) vào `auction_ends_at` và tăng `extended_count`.<br>   - Gửi thông báo `Outbid` cho người dẫn đầu trước đó.<br>4. **Đóng phiên & Tạo đơn tự động (`FR-AC-05`):** Khi `now() >= auction_ends_at`, Scheduled Job (hoặc Admin Demo Trigger) khóa bản ghi `auctions`:<br>   - Kiểm tra `leading_bidder_id != null` và `current_highest_bid >= reserve_price` (nếu có cấu hình giá sàn).<br>   - Cập nhật `auction.status = COMPLETED`, `winner_id = leading_bidder_id`.<br>   - **Tự động khởi tạo Đơn hàng (`orders`):** Gán `buyer_id = winner_id`, `item_subtotal = current_highest_bid`, tính `buyer_protection_fee`, `shipping_fee = 0`, `total_amount = item_subtotal + buyer_protection_fee`, trạng thái `PENDING_PAYMENT`, và gán hạn thanh toán `payment_expires_at` (**30 phút** ở Production / **2 phút** ở Demo Mode).<br>   - Gửi thông báo thắng đấu giá cho Winner để tiến hành thanh toán qua `UC-PM-01`. |
| **Alternative Flow (A1 – Người bán Chốt phiên sớm `Seller Early Close`)** | Khi phiên đang `LIVE`, nếu đã có người trả giá hợp lệ và `current_highest_bid >= reserve_price`, **Seller** nhấn **Chốt phiên sớm (`Close Early`)** $\rightarrow$ Backend ghi nhận `closed_early_by_seller = true`, ghi `audit_logs` và thực thi ngay Bước 4 để tạo đơn hàng cho người đang dẫn đầu. |
| **Alternative Flow (A2 – Kết thúc không có người thắng)** | Nếu hết giờ mà không có lượt bid nào hoặc giá cao nhất chưa đạt `reserve_price` $\rightarrow$ Phiên chuyển sang `ENDED_UNSOLD`, không tạo đơn hàng, cho phép Seller đăng lại vào phiên sau. |
| **Exception Flow (E1 – Hai người trả giá cùng lúc)** | Hai request đến cùng thời điểm $\rightarrow$ `lockForUpdate()` xếp hàng xử lý tuần tự; người thứ hai nếu có mức giá thấp hơn `(giá mới của người thứ nhất + bước giá)` sẽ nhận lỗi `409 Conflict` yêu cầu đặt mức giá cao hơn. |
| **Exception Flow (E2 – Người thắng không thanh toán sau 30 phút `DEC-02`)** | Khi `now() >= order.payment_expires_at` mà `payment_status == UNPAID`:<br>1. Scheduled Job chuyển đơn hàng đấu giá sang `EXPIRED` / `CANCELLED`.<br>2. Cập nhật trạng thái phiên đấu giá sang `WINNER_DEFAULTED` (ghi nhận lịch sử bỏ cọc/không thanh toán của Buyer).<br>3. Mở khóa sản phẩm để **Seller có quyền đăng lại vào phiên đấu giá tiếp theo** (không tự động ép người trả giá cao thứ 2 phải mua). |
| **Postconditions** | Lịch sử trả giá được bảo toàn tuyệt đối; chỉ có duy nhất 1 đơn hàng được tạo cho người thắng hợp lệ và kết nối liền mạch vào luồng Thanh toán & Escrow. |

---

### `UC-DP-01` & `UC-DP-02`: Mở Khiếu nại (`SHIPPED` / `DELIVERED`), Khóa Giải ngân & Admin Phân xử Tài chính
| Thành phần | Nội dung đặc tả |
| :--- | :--- |
| **Actor** | **Primary:** `ACT-02` (Buyer), `ACT-05` (Administrator)<br>**Secondary:** `ACT-02` (Seller), `ACT-04` (Support Staff), `ACT-06` (System Escrow Engine) |
| **Liên kết** | `FR-DP-01`..`FR-DP-03` \| `PERM-CM-05`..`PERM-CM-09` \| `DEC-03`, `DEC-07` |
| **Preconditions** | Đơn hàng đã thanh toán (`payment_status = PAID`), tiền đang được giữ (`escrow_status = HELD`), và trạng thái đơn hàng đang là **`SHIPPED`** hoặc **`DELIVERED`** (chưa chuyển sang `COMPLETED`) (`DEC-03`). |
| **Main Flow (Mở khiếu nại & Admin xử lý Hoàn tiền 100%)** | 1. **Buyer mở khiếu nại:** Trên màn hình Chi tiết đơn hàng, Buyer nhấn **Gửi khiếu nại (`Submit Dispute`)**, chọn lý do (*Hàng không đúng mô tả*, *Hàng bị rách/hư hỏng*, *Nghi ngờ hàng giả*, *Không nhận được hàng*, *Khác*), nhập mô tả chi tiết và tải lên ảnh bằng chứng (`dispute_evidence`).<br>2. **Tự động khóa giải ngân:** Backend mở `DB::transaction()`:<br>   - Tạo bản ghi `disputes` với trạng thái `OPEN`.<br>   - Cập nhật `orders.dispute_status = OPEN`.<br>   - **Khóa ngay lập tức cơ chế tự động hoàn tất đơn (`auto_complete`)** dù thời gian `auto_complete_at` có trôi qua.<br>   - Gửi thông báo cho Seller, Support Staff và Admin.<br>3. **Đối chứng & Hỗ trợ:** Seller tải lên bằng chứng phản hồi (ảnh lúc đóng gói, biên lai gửi hàng). Support Staff (`ACT-04`) hoặc Admin xem xét hồ sơ.<br>4. **Admin ra phán quyết (`UC-DP-02`):** Administrator (`ACT-05`) kiểm tra bằng chứng trên Admin Dashboard và chọn một trong các quyết định tài chính cuối cùng (ví dụ chọn **`APPROVE_BUYER_REFUND`** do hàng bị rách/sai mô tả):<br>5. Backend thực thi trong `DB::transaction()` kèm `lockForUpdate()`:<br>   - Cập nhật `disputes.status = RESOLVED`, `resolution = APPROVE_BUYER_REFUND`.<br>   - Cập nhật `orders.dispute_status = RESOLVED_REFUND`, `orders.order_status = REFUNDED`, `orders.escrow_status = REFUNDED`.<br>   - **Hoàn trả 100% (`DEC-07`):** Tạo bản ghi `refunds` và ghi bút toán `REFUND` vào `escrow_transactions` hoàn trả đủ **100% `total_amount` (`item_subtotal` + `buyer_protection_fee`)** về cho Buyer.<br>   - Ghi `audit_logs` và gửi thông báo kết quả phân xử cho cả Buyer và Seller. |
| **Alternative Flow (A1 – Yêu cầu bổ sung bằng chứng `REQUEST_MORE_EVIDENCE`)** | Tại bước 3, Support Staff hoặc Admin chọn `REQUEST_MORE_EVIDENCE` kèm nội dung yêu cầu $\rightarrow$ Trạng thái khiếu nại chuyển sang `NEED_MORE_INFO`, thông báo cho Buyer/Seller tải thêm ảnh bằng chứng; tiền vẫn tiếp tục được giữ trong `ESCROW_HELD`. |
| **Alternative Flow (A2 – Bác bỏ khiếu nại / Giải ngân cho Người bán `RELEASE_TO_SELLER`)** | Tại bước 4, nếu bằng chứng cho thấy Seller giao đúng hàng và khiếu nại của Buyer không có căn cứ:<br>- Admin chọn `RELEASE_TO_SELLER` (hoặc `REJECT_DISPUTE`).<br>- Hệ thống chuyển `order_status = COMPLETED`, `escrow_status = RELEASED`, giải ngân **100% `item_subtotal`** vào ví của Seller và ghi `audit_logs`. |
| **Alternative Flow (A3 – Hoàn tiền một phần `PARTIAL_REFUND`)** | Nếu hai bên đồng ý giữ lại món đồ với mức giảm giá bù lỗi nhỏ: Admin nhập số tiền hoàn cho Buyer (`refund_amount`) và số tiền giải ngân cho Seller (`release_amount`) sao cho tổng hợp lệ $\rightarrow$ Hệ thống ghi nhận đồng thời bút toán hoàn tiền một phần và giải ngân phần còn lại. |
| **Exception Flow** | - **E1 (Mở khiếu nại khi đơn đã `COMPLETED`):** Đơn đã qua 24h sau khi giao và đã giải ngân $\rightarrow$ Backend từ chối mở khiếu nại mới.<br>- **E2 (Support Staff cố gọi API phán quyết tài chính):** Bị chặn bởi Middleware/Policy (`403 Forbidden`) vì chỉ `Administrator` mới có quyền giải ngân/hoàn tiền tranh chấp. |
| **Postconditions** | Tranh chấp được đóng lại (`RESOLVED`), khoản tiền giữ trong Escrow được phân bổ chính xác theo phán quyết của Admin thông qua các bút toán sổ cái bất biến và lưu vết trong `audit_logs`. |

---

### `UC-RV-01`: Đánh giá & Nhận xét Người bán (Seller Rating & Review)
| Thành phần | Nội dung đặc tả |
| :--- | :--- |
| **Actor** | **Primary:** `ACT-02` (Buyer)<br>**Secondary:** `ACT-03` (Moderator), `ACT-05` (Admin) |
| **Liên kết** | `FR-RV-01` \| `PERM-CM-03`, `PERM-CM-04` |
| **Preconditions** | Đơn hàng thuộc quyền sở hữu của Buyer (`auth()->id() == order.buyer_id`), đã đạt trạng thái `order_status = COMPLETED` và chưa có bản ghi đánh giá nào gắn với `order_id` đó. |
| **Main Flow** | 1. Từ màn hình Chi tiết đơn hàng đã hoàn tất, Buyer nhấn **Đánh giá Người bán (`Rate Seller`)**.<br>2. Buyer chọn số sao từ `1` đến `5` và nhập nội dung nhận xét văn bản.<br>3. Backend kiểm tra điều kiện hợp lệ, lưu bản ghi vào bảng `reviews` (gắn với `order_id`, `product_id`, `buyer_id`, `seller_id`).<br>4. Trong cùng transaction, Backend tính toán lại điểm trung bình (`average_rating`) và tổng số lượt đánh giá (`review_count`) trong bảng `seller_profiles` của người bán.<br>5. Đánh giá hiển thị công khai trên hồ sơ của Người bán. |
| **Alternative Flow (A1 – Kiểm duyệt đánh giá vi phạm)** | Nếu bài đánh giá chứa ngôn từ xúc phạm/vi phạm, người dùng khác có thể gửi báo cáo (`Report`) và Moderator/Admin có quyền ẩn bài đánh giá đó (`is_hidden = true`) và tính lại điểm sao trung bình. |
| **Exception Flow** | - **E1 (Đánh giá trùng lặp):** Buyer gửi đánh giá lần thứ 2 cho cùng 1 `order_id` $\rightarrow$ Bị chặn bởi Unique Constraint và Validation (`409 Conflict`).<br>- **E2 (Đơn hàng chưa hoàn tất hoặc đã hoàn tiền):** Nếu `order_status != COMPLETED` $\rightarrow$ Backend từ chối (`403 Forbidden`). |
| **Postconditions** | Mỗi đơn hàng hoàn tất tạo ra tối đa 1 đánh giá xác thực, cập nhật trực tiếp uy tín của Người bán. |

---

### `UC-AD-02`: Cấu hình Hệ thống, Buyer Protection Fee & Vận hành Demo Mode Developer Tools
| Thành phần | Nội dung đặc tả |
| :--- | :--- |
| **Actor** | **Primary:** `ACT-05` (Administrator)<br>**Secondary:** `ACT-06` (System Services) |
| **Liên kết** | `FR-AD-04`, `FR-AD-05` \| `PERM-AD-02`, `PERM-AD-04` \| `DEC-04` |
| **Preconditions** | Người dùng đăng nhập vào Admin Dashboard với quyền `Administrator`. Đối với khu vực **Developer Tools**, biến môi trường `DEMO_MODE` phải đang được bật (`DEMO_MODE=true`). |
| **Main Flow (Cập nhật Cấu hình & Kích hoạt Demo Job)** | 1. **Cấu hình thông số nền tảng (`Platform Settings`):** Admin điều chỉnh tỷ lệ `protection_fee_rate` (trong dải `5% – 8%`), mức phí cố định `protection_fixed_fee` (`5.000đ – 10.000đ`), thời hạn thanh toán đấu giá và thời gian tự hoàn tất đơn (cấu hình riêng cho Production Mode và Demo Mode) $\rightarrow$ Lưu vào bảng `platform_settings` và ghi `audit_logs` (chỉ áp dụng cho các đơn hàng/phiên đấu giá tạo mới sau thời điểm lưu).<br>2. **Kích hoạt công cụ trình diễn (`Developer Tools`):** Khi bảo vệ đồ án, Admin mở trang **Developer Tools (Demo Mode)** và nhấn một trong các nút tác vụ:<br>   - **Run: Force Close Expired Auctions** (hoặc chọn tua nhanh thời gian kết thúc của 1 phiên demo về hiện tại rồi đóng phiên).<br>   - **Run: Expire Unpaid Auction Orders** (xử lý ngay đơn thắng đấu giá quá hạn thanh toán).<br>   - **Run: Auto Complete Delivered Orders & Release Escrow** (xử lý ngay việc tự động hoàn tất đơn đã `DELIVERED` đủ điều kiện và giải ngân tiền cho Seller).<br>3. Backend gọi trực tiếp vào cùng class Service mà Laravel Scheduler (`schedule:work`) sử dụng, thực thi logic nghiệp vụ chuẩn xác (vẫn kiểm tra không có `DISPUTED`, vẫn khóa dòng `lockForUpdate`), ghi nhận kết quả thực thi vào `audit_logs` và hiển thị tóm tắt số bản ghi vừa xử lý trên màn hình Admin. |
| **Exception Flow** | - **E1 (`DEMO_MODE=false`):** Nếu hệ thống không ở chế độ Demo, toàn bộ route và giao diện Developer Tools bị vô hiệu hóa (`403/404`).<br>- **E2 (Moderator/Support Staff truy cập):** Bị chặn bởi Middleware `Role:Admin` (`403 Forbidden`). |
| **Postconditions** | Quản trị viên chủ động trình diễn được toàn bộ các luồng nghiệp vụ phụ thuộc thời gian ngay lập tức trước hội đồng chấm thi mà không làm sai lệch bất kỳ quy tắc kiểm tra trạng thái hay sổ cái tài chính nào. |