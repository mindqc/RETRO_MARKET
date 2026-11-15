# 04. FUNCTIONAL REQUIREMENTS – RETRO MARKET (izithrift)

- **Document ID:** `DOC-PA03-FR`
- **Version:** `1.1.0 (FINAL APPROVED)`
- **Status:** `DONE`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 01 – Project Discovery & Requirement Analysis`

---

## 1. Quy Ước Định Danh & Phân Loại Yêu Cầu (Conventions & Priority Levels)

Mỗi yêu cầu chức năng trong tài liệu này tuân thủ cấu trúc chuẩn để liên kết trực tiếp với Use Case (`PA-04`), Business Rules (`PA-05`), API Specification và Test Cases:
- **Mã định danh (`FR ID`):** `FR-<NHÓM>-<SỐ THỨ TỰ>` (Ví dụ: `FR-AU-01`, `FR-PR-01`).
- **Mức độ ưu tiên (`Priority`):**
  - `MVP`: Tính năng cốt lõi bắt buộc hoàn thành trước để vận hành luồng giao dịch chính (Core Marketplace, Moderation, Order/Escrow, Auction, Rating, Dispute, Admin).
  - `ENHANCEMENT`: Tính năng nâng cấp nằm trong phạm vi đồ án nhưng triển khai sau khi nhóm `MVP` đã ổn định (Chat Polling, Favorites, Follow Seller, In-App Notifications, Seller Trust Score).
- **Liên kết Phân quyền (`Permission Ref`):** Tham chiếu trực tiếp tới mã `PERM-*` trong tài liệu `03_ACTOR_PERMISSION_MATRIX.md`.

---

## 2. Phân Hệ 1: Xác Thực, Tài Khoản & Hồ Sơ Người Dùng (Authentication, Profile & Address – `FR-AU`, `FR-US`)

| FR ID | Tên Chức Năng | Mô Tả Chi Tiết Yêu Cầu & Kết Quả Đầu Ra | Actor & Quyền | Ưu Tiên |
| :--- | :--- | :--- | :--- | :---: |
| `FR-AU-01` | Đăng ký tài khoản mới | Cho phép người dùng tạo tài khoản bằng `email` (duy nhất), `password` và `display_name`. Hệ thống băm mật khẩu an toàn tại Backend, tự động khởi tạo `user_profiles`, `seller_profiles` và gán vai trò `Registered User` (hỗ trợ cả quyền Mua và Bán). | `ACT-01` (`PERM-AU-01`) | `MVP` |
| `FR-AU-02` | Đăng nhập & Cấp Token | Xác thực `email` và `password`. Nếu tài khoản đang `ACTIVE`, hệ thống trả về `Laravel Sanctum` access token để ứng dụng Flutter lưu vào `flutter_secure_storage`. Nếu tài khoản bị `SUSPENDED` hoặc `BANNED`, từ chối đăng nhập kèm thông báo lý do. | `ACT-01`, `ACT-02` (`PERM-AU-01`) | `MVP` |
| `FR-AU-03` | Đăng xuất & Thu hồi Token | Cho phép người dùng đăng xuất khỏi thiết bị hiện tại; Backend xóa/thu hồi Sanctum token tương ứng và Flutter xóa token khỏi bộ nhớ bảo mật. | `ACT-02`..`ACT-05` (`PERM-AU-02`) | `MVP` |
| `FR-AU-04` | Khôi phục mật khẩu | Cho phép người dùng yêu cầu đặt lại mật khẩu qua email (sử dụng Mailpit/Log driver trên môi trường local) và cập nhật mật khẩu mới. | `ACT-01`, `ACT-02` (`PERM-AU-01`) | `MVP` |
| `FR-AU-05` | Chế độ Khách vãng lai (Guest Mode) | Cho phép `Guest` truy cập các màn hình công khai (Home, Search, Product Detail, Seller Public Profile, Auction Hub) mà không cần token. Tự động chặn và điều hướng sang màn hình Login khi `Guest` nhấn vào bất kỳ nút tương tác/giao dịch nào (`DEC-01`). | `ACT-01` (`PERM-PR-01`, `PERM-AC-01`) | `MVP` |
| `FR-US-01` | Quản lý hồ sơ cá nhân & người bán | Cho phép người dùng xem và cập nhật `display_name`, số điện thoại, mô tả cá nhân/cửa hàng (`bio`), và tải lên ảnh đại diện (`avatar`) lưu trên Local Filesystem. | `ACT-02` (`PERM-US-01`) | `MVP` |
| `FR-US-02` | Quản lý sổ địa chỉ nhận hàng | Cho phép người dùng thêm mới, chỉnh sửa, xóa và đặt 1 địa chỉ làm mặc định (`is_default = true`) phục vụ bước Checkout. | `ACT-02` (`PERM-US-02`) | `MVP` |
| `FR-US-03` | Xem hồ sơ công khai Người bán | Hiển thị thông tin cửa hàng của người bán, điểm đánh giá trung bình, tổng số lượt đánh giá, tỷ lệ hoàn tất đơn, danh sách sản phẩm đang bán (`APPROVED`) và danh sách đánh giá từ người mua trước. | `ACT-01`, `ACT-02` (`PERM-US-03`) | `MVP` |
| `FR-US-04` | Theo dõi Người bán (Follow Seller) | Cho phép người dùng theo dõi hoặc bỏ theo dõi một người bán khác (`auth()->id() != seller_id`) và xem danh sách các người bán đang theo dõi. | `ACT-02` (`PERM-US-04`) | `ENHANCEMENT` |

---

## 3. Phân Hệ 2: Danh Mục, Kênh Người Bán & Kiểm Duyệt Sản Phẩm (Catalog, Seller Center & Moderation – `FR-CT`, `FR-SL`, `FR-MD`)

| FR ID | Tên Chức Năng | Mô Tả Chi Tiết Yêu Cầu & Kết Quả Đầu Ra | Actor & Quyền | Ưu Tiên |
| :--- | :--- | :--- | :--- | :---: |
| `FR-CT-01` | Danh mục & Thương hiệu | Cung cấp danh sách Danh mục (`Categories` – quần áo vintage, giày dép, phụ kiện, đồ decor cổ điển...) và Thương hiệu (`Brands`) đang hoạt động để gắn nhãn sản phẩm và lọc tìm kiếm. | `ACT-01`, `ACT-02` (`PERM-PR-01`) | `MVP` |
| `FR-SL-01` | Tạo sản phẩm bán Giá cố định (Fixed Price) | Cho phép người bán tạo bài đăng với: tên sản phẩm, mô tả chi tiết, danh mục, thương hiệu, tình trạng (`condition`: Like New, Good, Fair, Vintage Worn...), mô tả lỗi/vết xước (`defect_info`), nhiều hình ảnh sản phẩm, bằng chứng xác thực (`authenticity_evidence`), giá bán cố định (`price > 0`) và số lượng khả dụng (`available_quantity >= 1`). | `ACT-02` (`PERM-PR-03`) | `MVP` |
| `FR-SL-02` | Tạo sản phẩm bán Đấu giá (Auction Listing) | Cho phép người bán tạo bài đăng đấu giá (số lượng mặc định = `1`) với đầy đủ thông tin sản phẩm kèm cấu hình đấu giá: chọn khung giờ phiên (`auction_session_id`), giá khởi điểm (`starting_price > 0`), bước giá tối thiểu (`min_bid_increment > 0`), và giá sàn tùy chọn (`reserve_price`). | `ACT-02` (`PERM-PR-03`) | `MVP` |
| `FR-SL-03` | Lưu nháp & Gửi kiểm duyệt | Cho phép người bán lưu sản phẩm ở trạng thái `DRAFT` để sửa sau, hoặc bấm Gửi duyệt để chuyển trạng thái sang `PENDING_REVIEW`. Mọi sản phẩm gửi duyệt mới đều bắt buộc đi qua hàng chờ kiểm duyệt trước khi hiển thị công khai. | `ACT-02` (`PERM-PR-03`, `PERM-PR-04`) | `MVP` |
| `FR-SL-04` | Quản lý danh sách sản phẩm của Người bán | Trong **Seller Center**, hiển thị sản phẩm của chính người bán chia theo các tab trạng thái: `DRAFT`, `PENDING_REVIEW`, `APPROVED`, `REJECTED`, `SOLD`, `HIDDEN`, `ARCHIVED`. Cho phép người bán ẩn (`HIDDEN`) hoặc lưu trữ (`ARCHIVED`) sản phẩm khi chưa có giao dịch/đấu giá đang chạy. | `ACT-02` (`PERM-PR-05`) | `MVP` |
| `FR-SL-05` | Chỉnh sửa & Gửi duyệt lại sản phẩm bị từ chối | Khi sản phẩm bị Moderator đánh dấu `REJECTED` (`DEC-05`), người bán xem được lý do từ chối/yêu cầu chỉnh sửa chi tiết, thực hiện cập nhật thông tin/hình ảnh và bấm gửi duyệt lại (`REJECTED` $\rightarrow$ `PENDING_REVIEW`). | `ACT-02` (`PERM-PR-04`, `PERM-PR-05`) | `MVP` |
| `FR-SL-06` | Thống kê doanh thu & Sổ cái Ví người bán | Hiển thị trong Seller Center: tổng doanh thu đã giải ngân, số tiền đang chờ giải ngân trong Escrow, số đơn hàng đã bán và lịch sử biến động sổ cái ví (`wallet_transactions`). | `ACT-02` (`PERM-FN-05`) | `MVP` |
| `FR-MD-01` | Hàng chờ & Chi tiết Kiểm duyệt sản phẩm | Cung cấp giao diện trên Admin Web cho Moderator/Admin xem danh sách sản phẩm `PENDING_REVIEW`, kiểm tra toàn bộ hình ảnh, tình trạng, mô tả lỗi, bằng chứng xác thực, hồ sơ người bán và lịch sử kiểm duyệt trước đó (`product_moderation_logs`). | `ACT-03`, `ACT-05` (`PERM-PR-06`) | `MVP` |
| `FR-MD-02` | Phê duyệt hoặc Từ chối sản phẩm | Cho phép Moderator/Admin quyết định: (1) **Approve**: chuyển sản phẩm sang `APPROVED`, gán mức độ xác minh (`verification_level`) và đưa lên sàn (hoặc đưa vào phiên đấu giá đã chọn); (2) **Reject**: chuyển sang `REJECTED` kèm lý do bắt buộc (`DEC-05`). Mọi quyết định đều phải lưu vào `product_moderation_logs` và `audit_logs`, đồng thời tạo thông báo cho người bán. | `ACT-03`, `ACT-05` (`PERM-PR-07`) | `MVP` |

---

## 4. Phân Hệ 3: Khám Phá, Tìm Kiếm & Yêu Thích (Product Discovery, Search & Favorites – `FR-DS`)

| FR ID | Tên Chức Năng | Mô Tả Chi Tiết Yêu Cầu & Kết Quả Đầu Ra | Actor & Quyền | Ưu Tiên |
| :--- | :--- | :--- | :--- | :---: |
| `FR-DS-01` | Trang chủ chủ đề Vintage Christmas | Hiển thị Hero Banner chủ đề Giáng sinh ấm cúng, thanh tìm kiếm, điều hướng danh mục, bộ sưu tập vintage nổi bật, sản phẩm secondhand mới đăng (`APPROVED`), phiên đấu giá đang diễn ra (`LIVE`) và sắp kết thúc (`ENDING_SOON`), cùng danh sách người bán uy tín. | `ACT-01`, `ACT-02` (`PERM-PR-01`) | `MVP` |
| `FR-DS-02` | Tìm kiếm, Bộ lọc & Sắp xếp | Cho phép tìm kiếm theo tên sản phẩm, thương hiệu, danh mục; kết hợp bộ lọc theo tình trạng (`condition`), khoảng giá (`min_price` – `max_price`), khu vực/địa점 người bán, loại hình bán (`FIXED_PRICE` / `AUCTION`); sắp xếp theo mới nhất, giá thấp đến cao, giá cao đến thấp, độ phổ biến (có phân trang từ PostgreSQL). | `ACT-01`, `ACT-02` (`PERM-PR-01`) | `MVP` |
| `FR-DS-03` | Xem Chi tiết Sản phẩm | Hiển thị bộ ảnh sản phẩm (carousel), tên, giá bán, tình trạng, thông tin lỗi/khuyết điểm (`defect_info`), thương hiệu, danh mục, mức độ xác minh, thông tin người bán & điểm sao, sản phẩm liên quan. Hiển thị nút `Thêm vào giỏ` / `Mua ngay` cho hàng giá cố định, hoặc chuyển sang giao diện đặt giá thầu cho hàng đấu giá. | `ACT-01`, `ACT-02` (`PERM-PR-01`) | `MVP` |
| `FR-DS-04` | Quản lý sản phẩm Yêu thích (Favorites) | Cho phép người mua lưu/bỏ lưu sản phẩm vào danh sách Yêu thích và xem lại danh sách các món đồ đã lưu. | `ACT-02` (`PERM-PR-02`) | `ENHANCEMENT` |

---

## 5. Phân Hệ 4: Giỏ Hàng, Đặt Hàng & Phí Bảo Vệ Người Mua (Cart, Checkout & Buyer Protection Fee – `FR-CR`, `FR-OR`)

| FR ID | Tên Chức Năng | Mô Tả Chi Tiết Yêu Cầu & Kết Quả Đầu Ra | Actor & Quyền | Ưu Tiên |
| :--- | :--- | :--- | :--- | :---: |
| `FR-CR-01` | Quản lý Giỏ hàng (Shopping Cart) | Cho phép người mua thêm sản phẩm `FIXED_PRICE` (đang `APPROVED`, còn tồn kho và `seller_id != auth()->id()`) vào giỏ hàng, thay đổi số lượng (không vượt quá `available_quantity`), xóa sản phẩm và nhóm các sản phẩm trong giỏ theo từng Người bán. Chặn tuyệt đối việc thêm sản phẩm đấu giá vào giỏ hàng. | `ACT-02` (`PERM-OR-01`) | `MVP` |
| `FR-OR-01` | Xem trước Thanh toán & Tính Phí Bảo Vệ Người Mua (Checkout Preview) | Cho phép người mua chọn các sản phẩm của **cùng 1 người bán** trong giỏ hàng và chọn địa chỉ nhận hàng. Backend kiểm tra lại tính khả dụng, giá hiện hành và trả về bảng tính chi tiết (`DEC-04`):<br>- **Tiền hàng (`item_subtotal`):** Tổng `price * quantity`.<br>- **Phí vận chuyển (`shipping_fee`):** `0 VNĐ` (Không thu phí vận chuyển trên app).<br>- **Phí bảo vệ người mua (`buyer_protection_fee`):** `(item_subtotal * protection_fee_rate) + protection_fixed_fee` (lấy từ `platform_settings`).<br>- **Tổng thanh toán (`total_amount`):** `item_subtotal + buyer_protection_fee`. | `ACT-02` (`PERM-OR-02`) | `MVP` |
| `FR-OR-02` | Khởi tạo Đơn hàng & Lưu Snapshot | Khi người mua xác nhận đặt hàng, Backend thực thi trong `DB::transaction()` có khóa dòng (`lockForUpdate`) trên sản phẩm: kiểm tra lại tồn kho, trừ `available_quantity` (nếu về `0` thì đánh dấu tạm giữ/hết hàng), tạo bản ghi `orders` (trạng thái `PENDING_PAYMENT`, gán `payment_expires_at`), và lưu **bản chụp (snapshot)** tên sản phẩm, giá, tình trạng, mô tả lỗi, ảnh đại diện vào bảng `order_items`. | `ACT-02` (`PERM-OR-03`) | `MVP` |
| `FR-OR-03` | Hủy đơn hàng & Yêu cầu hủy đơn theo trạng thái (`DEC-06`, `DEC-07`) | Thực thi cơ chế hủy đơn theo đúng trạng thái:<br>1. Ở `PENDING_PAYMENT`: Buyer tự hủy (hoặc System tự hủy khi quá hạn) $\rightarrow$ hoàn lại số lượng tồn kho sản phẩm.<br>2. Ở `PAID` (Seller chưa bấm `PREPARING`): Buyer hoặc Seller đều có quyền hủy trực tiếp $\rightarrow$ chuyển đơn sang `CANCELLED`, hoàn lại tồn kho và tạo bút toán hoàn trả **100% `total_amount` (`item_subtotal` + `buyer_protection_fee`)** từ Escrow cho Buyer.<br>3. Ở `PREPARING`: Seller có thể hủy trực tiếp; nếu Buyer muốn hủy phải gửi **Yêu cầu hủy đơn** và chờ Seller bấm **Đồng ý** mới hủy đơn & hoàn trả 100% `total_amount`. | `ACT-02`, `ACT-05`, `ACT-06` (`PERM-OR-05A`, `PERM-OR-05B`) | `MVP` |

---

## 6. Phân Hệ 5: Thanh Toán QR Mô Phỏng, Sổ Cái Escrow & Vận Chuyển (Mock Payment, Escrow & Shipping – `FR-PM`, `FR-ES`, `FR-SH`)

| FR ID | Tên Chức Năng | Mô Tả Chi Tiết Yêu Cầu & Kết Quả Đầu Ra | Actor & Quyền | Ưu Tiên |
| :--- | :--- | :--- | :--- | :---: |
| `FR-PM-01` | Khởi tạo phiên Thanh toán QR Mô phỏng | Tạo bản ghi `payments` cho đơn hàng đang `PENDING_PAYMENT` với mã tham chiếu duy nhất (`payment_reference`), số tiền cần trả bằng đúng `total_amount`, thời gian hết hạn `payment_expires_at`, và sinh chuỗi dữ liệu mã QR nội bộ để hiển thị trên màn hình thanh toán Flutter. | `ACT-02` (`PERM-FN-01`) | `MVP` |
| `FR-PM-02` | Xử lý kết quả Thanh toán Mô phỏng | Cung cấp hành động mô phỏng thanh toán thành công/thất bại rõ ràng trên giao diện phục vụ kiểm thử đồ án. Khi thanh toán thành công (trong thời hạn hiệu lực): Backend sử dụng transaction + row lock để chuyển `payment_status` sang `PAID`, chuyển `order_status` sang `PAID`, chống thanh toán trùng 2 lần cho cùng một đơn hàng. | `ACT-02` (`PERM-FN-02`) | `MVP` |
| `FR-ES-01` | Ghi nhận Khoản Giữ Tiền Trung Gian (Escrow Hold) | Ngay trong cùng transaction khi thanh toán thành công (`FR-PM-02`), hệ thống tự động tạo bản ghi bất biến trong `escrow_transactions` (loại `HOLD`, số tiền = `total_amount` gồm `item_subtotal` + `buyer_protection_fee`) và đặt `escrow_status` của đơn hàng thành `HELD`. Số tiền này chưa được cộng vào số dư khả dụng của người bán. | `ACT-06` (`PERM-FN-03`) | `MVP` |
| `FR-SH-01` | Xác nhận chuẩn bị hàng & Cập nhật vận chuyển thủ công | Cho phép người bán xử lý đơn hàng đã thanh toán:<br>1. Bấm xác nhận chuẩn bị hàng (`PAID` $\rightarrow$ `PREPARING`).<br>2. Nhập tên đơn vị vận chuyển, mã vận đơn (`tracking_code`) và xác nhận gửi hàng (`PREPARING` $\rightarrow$ `SHIPPED`, lưu bản ghi `shipments`).<br>3. Cập nhật trạng thái đã giao hàng (`SHIPPED` $\rightarrow$ `DELIVERED`), lúc này Backend tự động ghi nhận `delivered_at = now()` và tính cứng mốc `auto_complete_at` (24 giờ ở Production Mode / 2 phút ở Demo Mode). | `ACT-02` (`PERM-OR-06`, `PERM-OR-07`) | `MVP` |
| `FR-SH-02` | Theo dõi Đơn hàng & Xác nhận Đã Nhận Hàng | Hiển thị timeline tiến trình đơn hàng chi tiết cho cả người mua và người bán. Khi đơn ở trạng thái `DELIVERED` và không có khiếu nại đang mở, người mua có thể bấm **Xác nhận đã nhận hàng** để chuyển đơn sang `COMPLETED` ngay lập tức. | `ACT-02` (`PERM-OR-04`, `PERM-OR-08`) | `MVP` |
| `FR-ES-02` | Tự động Hoàn tất Đơn hàng & Giải ngân 100% Tiền hàng cho Người bán | Khi người mua bấm xác nhận nhận hàng (`FR-SH-02`) HOẶC khi Scheduled Job quét thấy đơn hàng có `order_status = DELIVERED`, `now() >= auto_complete_at` và **không có khiếu nại đang mở (`dispute_status != OPEN`)**:<br>1. Chuyển `order_status` sang `COMPLETED`.<br>2. Chuyển `escrow_status` sang `RELEASED`.<br>3. Ghi bút toán `RELEASE` vào `escrow_transactions` và cộng **100% tiền hàng (`item_subtotal`)** vào ví người bán (`wallet_transactions`), giữ lại `buyer_protection_fee` làm phí bảo vệ của nền tảng (`DEC-04`). Đảm bảo tính lũy đẳng (idempotent), không bao giờ giải ngân 2 lần. | `ACT-06`, `ACT-05` (`PERM-OR-09`, `PERM-FN-04`) | `MVP` |

---

## 7. Phân Hệ 6: Hệ Thống Đấu Giá Theo Phiên (Scheduled Auction System – `FR-AC`)

| FR ID | Tên Chức Năng | Mô Tả Chi Tiết Yêu Cầu & Kết Quả Đầu Ra | Actor & Quyền | Ưu Tiên |
| :--- | :--- | :--- | :--- | :---: |
| `FR-AC-01` | Quản lý Khung giờ Phiên đấu giá (Auction Sessions) | Cho phép Admin tạo, chỉnh sửa, bật/tắt các khung giờ phiên đấu giá hàng ngày (`auction_sessions`). Hệ thống tự động mở phiên (`SCHEDULED` $\rightarrow$ `LIVE`) khi đến giờ `start_time` và hiển thị trên **Auction Hub** (chia theo tab: Sắp diễn ra, Đang diễn ra, Sắp kết thúc, Đã kết thúc, Đang tham gia, Đã thắng). | `ACT-05`, `ACT-06` (`PERM-AC-01`, `PERM-AC-08`) | `MVP` |
| `FR-AC-02` | Đặt giá thầu an toàn đồng thời (Concurrent Bid Engine) | Cho phép người mua đã đăng nhập (`auth()->id() != seller_id`) đặt giá thầu trên phiên đang `LIVE` (`now() < auction_ends_at`). Backend thực thi trong `DB::transaction()` kèm `lockForUpdate()` trên bản ghi đấu giá:<br>- Kiểm tra `bid_amount >= current_highest_bid + min_bid_increment` (hoặc `>= starting_price` nếu là lượt bid đầu tiên).<br>- Lưu vĩnh viễn lượt trả giá vào `auction_bids` (không cho phép rút lại bid).<br>- Cập nhật `current_highest_bid` và `leading_bidder_id`, đồng thời tạo thông báo bị vượt giá (`Outbid`) cho người dẫn đầu trước đó. | `ACT-02` (`PERM-AC-03`) | `MVP` |
| `FR-AC-03` | Gia hạn tự động chống trả giá giây cuối (Anti-Sniping) | Nếu một lượt trả giá hợp lệ được ghi nhận trong khoảng thời gian nhạy cảm cuối phiên (mặc định **2 phút cuối** ở Production Mode / **30 giây cuối** ở Demo Mode trước `auction_ends_at`), Backend tự động cộng thêm thời gian gia hạn (**+2 phút** / **+30 giây**) vào `auction_ends_at` và tăng bộ đếm `extended_count`. | `ACT-06` (`PERM-AC-04`) | `MVP` |
| `FR-AC-04` | Người bán Chốt phiên đấu giá sớm (Seller Early Close) | Cho phép người bán chủ động bấm chốt phiên sớm khi phiên đang `LIVE`, với điều kiện đã có người dẫn đầu hợp lệ và mức giá cao nhất hiện tại đã đạt hoặc vượt giá sàn (`current_highest_bid >= reserve_price`). Ghi nhận audit log và kích hoạt ngay luồng xác định người thắng (`FR-AC-05`). | `ACT-02` (`PERM-AC-05`) | `MVP` |
| `FR-AC-05` | Đóng phiên, Xác định Người thắng & Tự động tạo Đơn hàng | Khi hết thời gian (`now() >= auction_ends_at`) hoặc khi Seller chốt sớm:<br>- Nếu có người trả giá cao nhất và đạt `reserve_price`: đánh dấu phiên là `COMPLETED`, xác định `winner_id` và **tự động tạo Đơn hàng** (trạng thái `PENDING_PAYMENT`, tính `item_subtotal = winning_bid`, cộng `buyer_protection_fee`, miễn phí ship, gán hạn thanh toán `payment_expires_at` = **30 phút** ở Production / **2 phút** ở Demo Mode).<br>- Nếu không có lượt bid nào hoặc chưa đạt `reserve_price`: đóng phiên ở trạng thái không có người thắng (`ENDED_UNSOLD`), cho phép người bán đăng lại. | `ACT-06`, `ACT-05` (`PERM-AC-06`) | `MVP` |
| `FR-AC-06` | Xử lý Đơn hàng Đấu giá Quá hạn Thanh toán (`DEC-02`) | Nếu người thắng đấu giá không hoàn tất thanh toán trước mốc `payment_expires_at`, Scheduled Job tự động chuyển đơn hàng sang trạng thái hết hạn/hủy (`EXPIRED`/`CANCELLED`), ghi nhận vi phạm không thanh toán của người mua, và mở khóa sản phẩm để **Người bán có quyền đăng lại vào phiên đấu giá tiếp theo** (không tự động ép người trả giá cao thứ 2 mua). | `ACT-06`, `ACT-02` (`PERM-AC-07`) | `MVP` |

---

## 8. Phân Hệ 7: Tương Tác, Đánh Giá, Khiếu Nại & Thông Báo (Community, Trust, Disputes & Notifications – `FR-CM`, `FR-RV`, `FR-DP`, `FR-NT`)

| FR ID | Tên Chức Năng | Mô Tả Chi Tiết Yêu Cầu & Kết Quả Đầu Ra | Actor & Quyền | Ưu Tiên |
| :--- | :--- | :--- | :--- | :---: |
| `FR-RV-01` | Đánh giá & Nhận xét Người bán (Ratings & Reviews) | Chỉ cho phép người mua của đơn hàng đã đạt trạng thái `COMPLETED` gửi đánh giá từ **1 đến 5 sao** kèm bình luận văn bản (giới hạn đúng **1 đánh giá duy nhất / 1 đơn hàng**). Hệ thống tự động cập nhật lại điểm sao trung bình (`average_rating`) và tổng số lượt đánh giá (`review_count`) trên hồ sơ người bán. | `ACT-02` (`PERM-CM-03`) | `MVP` |
| `FR-DP-01` | Gửi Khiếu nại & Tự động Khóa Giải ngân (`DEC-03`) | Cho phép người mua mở khiếu nại (`Dispute`) khi đơn hàng đang ở trạng thái **`SHIPPED`** (ví dụ: không nhận được hàng) hoặc **`DELIVERED`** (hàng rách, hư hỏng, sai mô tả, nghi ngờ tính xác thực) trước khi đơn chuyển sang `COMPLETED`. Người mua chọn lý do, nhập mô tả và tải lên hình ảnh bằng chứng (`dispute_evidence`). Ngay khi khiếu nại được tạo, hệ thống chuyển `dispute_status` sang `OPEN` và **khóa ngay lập tức cơ chế tự động hoàn tất/giải ngân Escrow**. | `ACT-02`, `ACT-06` (`PERM-CM-05`, `PERM-CM-06`) | `MVP` |
| `FR-DP-02` | Phản hồi Bằng chứng & Yêu cầu Bổ sung Thông tin | Cho phép người bán gửi giải trình và tải lên bằng chứng đối chứng (ảnh đóng gói, vận đơn). Cho phép Support Staff hoặc Admin chuyển trạng thái khiếu nại sang `REQUEST_MORE_EVIDENCE` để yêu cầu hai bên cung cấp thêm bằng chứng. | `ACT-02`, `ACT-04`, `ACT-05` (`PERM-CM-07`, `PERM-CM-08`) | `MVP` |
| `FR-DP-03` | Phân xử Khiếu nại & Xử lý Tài chính (`DEC-07`) | Chỉ cho phép **Administrator** đưa ra quyết định tài chính cuối cùng (trong `DB::transaction()`):<br>1. `APPROVE_BUYER_REFUND`: Chấp nhận khiếu nại $\rightarrow$ Hoàn trả **100% `total_amount` (`item_subtotal` + `buyer_protection_fee`)** từ Escrow cho Buyer; đơn hàng chuyển sang `REFUNDED`.<br>2. `RELEASE_TO_SELLER` / `REJECT_DISPUTE`: Bác bỏ khiếu nại $\rightarrow$ Giải ngân **100% `item_subtotal`** cho Seller; đơn hàng chuyển sang `COMPLETED`.<br>3. `PARTIAL_REFUND`: Hoàn một phần tiền cho Buyer và giải ngân phần còn lại cho Seller theo số tiền Admin chỉ định (tổng không vượt quá khoản đang giữ).<br>Mọi quyết định đều sinh bút toán bất biến trong `escrow_transactions` / `refunds` / `wallet_transactions` và ghi `audit_logs`. | `ACT-05` (`PERM-CM-09`) | `MVP` |
| `FR-CM-01` | Nhắn tin 1-1 Người mua – Người bán (Polling Chat) | Cho phép người mua khởi tạo hội thoại gắn với sản phẩm hoặc đơn hàng với người bán, gửi/nhận tin nhắn văn bản, xem trạng thái đã đọc (`is_read`), chặn người dùng (`Block`) hoặc báo cáo hội thoại. Sử dụng cơ chế HTTP Polling theo chu kỳ để đồng bộ tin nhắn mới. | `ACT-02` (`PERM-CM-01`, `PERM-CM-02`) | `ENHANCEMENT` |
| `FR-CM-02` | Báo cáo vi phạm & Điểm uy tín (Reports & Trust Score) | Cho phép người dùng gửi báo cáo vi phạm đối với sản phẩm hoặc tài khoản. Hệ thống tính toán chỉ số uy tín của người bán dựa trên điểm đánh giá trung bình, số đơn hoàn tất, tỷ lệ hủy đơn và tỷ lệ bị khiếu nại thành công. | `ACT-02`, `ACT-03`, `ACT-05` (`PERM-CM-10`, `PERM-CM-11`) | `ENHANCEMENT` |
| `FR-NT-01` | Hệ thống Thông báo trong ứng dụng (In-App Notifications) | Tự động tạo và hiển thị thông báo kèm số lượng chưa đọc (`Unread Badge`) cho các sự kiện: sản phẩm được duyệt/từ chối, có tin nhắn mới, có lượt trả giá mới, bị vượt giá (`Outbid`), thắng đấu giá, kết thúc phiên, thanh toán thành công, đơn hàng được gửi/giao/tự động hoàn tất, cập nhật khiếu nại và giải ngân/hoàn tiền. | `ACT-02`..`ACT-06` (`PERM-CM-12`) | `ENHANCEMENT` |

---

## 9. Phân Hệ 8: Quản Trị Hệ Thống, Cấu Hình & Chế Độ Trình Diễn (Admin Dashboard, Settings & Demo Mode – `FR-AD`)

| FR ID | Tên Chức Năng | Mô Tả Chi Tiết Yêu Cầu & Kết Quả Đầu Ra | Actor & Quyền | Ưu Tiên |
| :--- | :--- | :--- | :--- | :---: |
| `FR-AD-01` | Bảng điều khiển Thống kê Tổng quan (Admin Dashboard) | Hiển thị số liệu thời gian thực truy vấn trực tiếp từ PostgreSQL: tổng người dùng (đang hoạt động / bị khóa), tổng sản phẩm, số sản phẩm chờ duyệt, tổng đơn hàng, đơn hoàn tất, phiên đấu giá đang chạy, khiếu nại chờ xử lý, tổng giá trị giao dịch mô phỏng (GMV), tổng số tiền đang giữ trong Escrow và tổng Phí bảo vệ người mua đã thu. | `ACT-03`..`ACT-05` (`PERM-AD-01`) | `MVP` |
| `FR-AD-02` | Quản lý Người dùng & Phát hiện bất thường | Cho phép Admin tìm kiếm, lọc tài khoản theo trạng thái/vai trò, xem lịch sử hoạt động, khóa (`SUSPENDED`/`BANNED`) hoặc mở khóa tài khoản, gán quyền nội bộ và cảnh báo các tài khoản có tỷ lệ khiếu nại cao hoặc hành vi trả giá bất thường. | `ACT-05` (`PERM-US-05`..`PERM-US-07`) | `MVP` |
| `FR-AD-03` | Giám sát Đơn hàng, Thanh toán & Sổ cái Escrow | Cung cấp giao diện tra cứu toàn bộ đơn hàng, lịch sử vận chuyển, phiên thanh toán QR, và sổ cái `escrow_transactions` / `wallet_transactions` (chỉ đọc đối với lịch sử giao dịch, không cho phép sửa trực tiếp số dư ngoài quy trình nghiệp vụ). | `ACT-05` (`PERM-FN-06`, `PERM-FN-07`) | `MVP` |
| `FR-AD-04` | Cấu hình Thông số Nền tảng (Platform Settings) | Cho phép Admin cấu hình động trên giao diện Web các tham số lưu trong `platform_settings`:<br>- Tỷ lệ % Phí bảo vệ người mua (`protection_fee_rate`, mặc định `6%`, trong dải `5% – 8%`).<br>- Phí bảo vệ cố định (`protection_fixed_fee`, mặc định `7.000đ`, trong dải `5.000đ – 10.000đ`).<br>- Thời hạn thanh toán đơn đấu giá (Production: `30 phút` / Demo Mode: `2 phút`).<br>- Thời gian tự động hoàn tất đơn sau khi giao (Production: `24 giờ` / Demo Mode: `2 phút`).<br>- Thời gian gia hạn Anti-sniping (Production: `2 phút` / Demo Mode: `30 giây`). | `ACT-05` (`PERM-AD-02`) | `MVP` |
| `FR-AD-05` | Công cụ Trình diễn Đồ án (Developer Tools – Demo Mode) | Khi `DEMO_MODE=true` ở môi trường local/demo, hiển thị bảng điều khiển **Developer Tools** cho Admin để kích hoạt thủ công (Manual Trigger) hoặc tua nhanh thời gian hết hạn cho các bản ghi demo đối với 3 nhóm Scheduled Jobs: (1) `Force Close Expired Auctions`, (2) `Expire Unpaid Auction Orders`, (3) `Auto Complete Delivered Orders & Release Escrow`. Các nút này bắt buộc gọi đúng Service class của Scheduled Job thật và đảm bảo tính idempotent. | `ACT-05` (`PERM-AD-04`) | `MVP` |
| `FR-AD-06` | Nhật ký Kiểm toán Quản trị (Admin Audit Logs) | Tự động ghi nhận và hiển thị danh sách mọi thao tác quản trị nhạy cảm (duyệt/từ chối sản phẩm, khóa tài khoản, phân xử khiếu nại, đổi cấu hình phí, chạy Demo Job) kèm bộ lọc theo người thực hiện, loại hành động và thời gian. | `ACT-05` (`PERM-AD-03`) | `MVP` |