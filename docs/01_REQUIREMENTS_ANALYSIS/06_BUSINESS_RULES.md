# 06. BUSINESS RULES SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-PA05-BR`
- **Version:** `1.1.0 (FINAL APPROVED)`
- **Status:** `DONE`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 01 – Project Discovery & Requirement Analysis`

---

## 1. Nguyên Tắc Thực Thi Quy Tắc Nghiệp Vụ (Business Rule Enforcement Principles)

1. **Thực thi bắt buộc tại Backend & Database (`Server-Side Authority`):** Không bất kỳ quy tắc nghiệp vụ, công thức tính phí hay điều kiện chuyển trạng thái nào được phép chỉ kiểm tra ở phía Flutter. Mọi quy tắc dưới đây phải được cưỡng chế tại tầng **Laravel Service Layer**, **Form Requests**, **Eloquent Policies** và **PostgreSQL Constraints/Transactions**.
2. **Định danh Quy tắc (`BR ID`):** Mỗi quy tắc có mã duy nhất `BR-<NHÓM>-<SỐ>` để ánh xạ trực tiếp vào tài liệu Kiểm thử (`07_TESTING/`) và Ma trận Truy vết (`09_REQUIREMENTS_TRACEABILITY.md`).

---

## 2. Nhóm Quy Tắc Tài Khoản, Định Danh & Chống Tự Giao Dịch (`BR-AC`)

| Mã BR | Tên Quy Tắc | Nội Dung Quy Tắc & Logic Kiểm Tra Bắt Buộc | Liên Kết |
| :--- | :--- | :--- | :--- |
| `BR-AC-01` | Tài khoản C2C hợp nhất (Unified Account) | Mỗi người dùng đăng ký (`Registered User`) chỉ sử dụng một tài khoản duy nhất có cả quyền Mua (Buyer) và quyền Bán (Seller). Hệ thống không tách tài khoản Buyer/Seller riêng biệt. | `FR-AU-01` |
| `BR-AC-02` | Chống tự giao dịch (Anti-Self-Dealing) | Người dùng **tuyệt đối không được phép** thực hiện các hành vi sau trên sản phẩm do chính mình đăng bán (`auth()->id() == product.seller_id`):<br>1. Thêm sản phẩm của mình vào giỏ hàng.<br>2. Tạo đơn hàng mua sản phẩm của mình.<br>3. Đặt giá thầu (`Place Bid`) hoặc theo dõi (`Watch`) phiên đấu giá sản phẩm của mình.<br>4. Tự theo dõi (`Follow`) hoặc tự gửi tin nhắn chat cho chính mình. | `PERM-OR-01`, `PERM-AC-03` |
| `BR-AC-03` | Giới hạn quyền Khách vãng lai (Guest Restriction) | `Guest` (chưa có Sanctum Token hợp lệ) chỉ được phép gọi các API `GET` công khai (Home, Search, Product Detail của sản phẩm `APPROVED`/`SOLD`, Seller Public Profile, Auction Hub). Mọi request thay đổi dữ liệu (`POST`, `PUT`, `DELETE`) hoặc truy cập tài nguyên cá nhân từ `Guest` phải bị chặn với mã `401 Unauthorized` (`DEC-01`). | `FR-AU-05`, `DEC-01` |
| `BR-AC-04` | Chặn tức thời tài khoản bị khóa | Khi tài khoản có trạng thái `SUSPENDED` hoặc `BANNED`, hệ thống thu hồi toàn bộ Sanctum Token hiện có, ẩn tạm thời các sản phẩm `APPROVED` chưa phát sinh đơn hàng của người đó và từ chối mọi API request với mã `403 Forbidden`. | `FR-AU-02`, `FR-AD-02` |

---

## 3. Nhóm Quy Tắc Sản Phẩm & Kiểm Duyệt (`BR-PR`)

| Mã BR | Tên Quy Tắc | Nội Dung Quy Tắc & Logic Kiểm Tra Bắt Buộc | Liên Kết |
| :--- | :--- | :--- | :--- |
| `BR-PR-01` | Một phương thức bán duy nhất | Mỗi sản phẩm tại một thời điểm chỉ thuộc **một** loại hình bán duy nhất: `FIXED_PRICE` (Giá cố định) hoặc `AUCTION` (Đấu giá). Đối với sản phẩm `AUCTION`, số lượng khả dụng (`available_quantity`) luôn cố định bằng `1`. | `FR-SL-01`, `FR-SL-02` |
| `BR-PR-02` | Kiểm duyệt bắt buộc trước khi hiển thị | Mọi sản phẩm tạo mới khi bấm gửi duyệt (hoặc sản phẩm bị `REJECTED` sau khi chỉnh sửa và bấm gửi duyệt lại `Resubmit`) đều phải chuyển vào trạng thái `PENDING_REVIEW`. Chỉ những sản phẩm có trạng thái `APPROVED` mới được xuất hiện trong kết quả tìm kiếm, trang chủ và danh sách khám phá công khai. | `FR-SL-03`, `FR-MD-02` |
| `BR-PR-03` | Minh bạch tình trạng & Không cam kết hàng thật qua ảnh | Bài đăng bắt buộc phải có tối thiểu 1 ảnh thực tế, khai báo tình trạng (`condition`) và mô tả khuyết điểm/lỗi (`defect_info`). Hệ thống không bao giờ tuyên bố bảo đảm 100% hàng chính hãng chỉ dựa trên hình ảnh, mà sử dụng trường mức độ xác minh rõ ràng (`verification_level`: `UNVERIFIED`, `EVIDENCE_PROVIDED`, `MODERATOR_REVIEWED`). | `FR-SL-01`, `FR-MD-02` |
| `BR-PR-04` | Bắt buộc ghi lý do & lưu vết khi Kiểm duyệt (`DEC-05`) | Khi Moderator hoặc Admin từ chối sản phẩm (`REJECTED` – bao gồm cả yêu cầu người bán chỉnh sửa thông tin), trường lý do (`reason`) là bắt buộc. Mọi quyết định (`APPROVED` / `REJECTED` / `HIDDEN`) đều phải tạo bản ghi bất biến trong `product_moderation_logs` (gồm `moderator_id`, `decision`, `reason`, `created_at`). | `FR-MD-02`, `DEC-05` |
| `BR-PR-05` | Khóa chỉnh sửa sản phẩm khi đang giao dịch | Người bán không được phép chỉnh sửa giá, loại hình bán hoặc xóa sản phẩm khi sản phẩm đó: (1) Đang nằm trong phiên đấu giá `LIVE` hoặc đã có người đặt giá thầu, hoặc (2) Đã được đặt mua trong một đơn hàng đang hoạt động (`PENDING_PAYMENT`, `PAID`, `PREPARING`, `SHIPPED`, `DELIVERED`, `DISPUTED`). | `PERM-PR-05` |

---

## 4. Nhóm Quy Tắc Đấu Giá Theo Phiên & Xử Lý Đồng Thời (`BR-AU`)

| Mã BR | Tên Quy Tắc | Nội Dung Quy Tắc & Logic Kiểm Tra Bắt Buộc | Liên Kết |
| :--- | :--- | :--- | :--- |
| `BR-AU-01` | Nguồn thời gian chuẩn duy nhất (Backend Time Authority) | Đồng hồ đếm ngược trên ứng dụng Flutter chỉ mang tính hiển thị trực quan. Việc cho phép hay từ chối một lượt trả giá (`Place Bid`) phụ thuộc 100% vào phép so sánh thời gian thực của máy chủ Backend (`now() >= auction_starts_at` và `now() < auction_ends_at`) và trạng thái phiên `status == LIVE`. | `FR-AC-02` |
| `BR-AU-02` | Công thức giá thầu hợp lệ & Không rút lại Bid | - Lượt trả giá đầu tiên phải thỏa mãn: `bid_amount >= starting_price`.<br>- Các lượt trả giá tiếp theo phải thỏa mãn: `bid_amount >= current_highest_bid + min_bid_increment`.<br>- Mọi lượt trả giá hợp lệ sau khi ghi vào bảng `auction_bids` là **vĩnh viễn**, người mua không được phép thu hồi hoặc sửa lại mức giá đã đặt. | `FR-AC-02` |
| `BR-AU-03` | Khóa dòng chống xung đột trả giá đồng thời (Row-Level Locking) | Mọi thao tác đặt giá thầu (`Place Bid`), chốt phiên sớm (`Close Early`) và đóng phiên tự động (`Close Expired Auction`) bắt buộc phải chạy bên trong `DB::transaction()` và thực hiện `SELECT ... FOR UPDATE` (`lockForUpdate()`) trên dòng bản ghi `auctions` trước khi đọc `current_highest_bid` và `auction_ends_at`. | `FR-AC-02`, `RSK-01` |
| `BR-AU-04` | Quy tắc Gia hạn Chống trả giá giây cuối (Anti-Sniping Rule) | Nếu một lượt trả giá hợp lệ được ghi nhận khi thời gian còn lại của phiên nhỏ hơn hoặc bằng ngưỡng nhạy cảm (`auction_ends_at - now() <= anti_sniping_window`, mặc định **2 phút** ở Production / **30 giây** ở Demo Mode), hệ thống tự động cộng thêm một khoảng thời gian gia hạn (`+2 phút` ở Production / `+30 giây` ở Demo Mode) vào cột `auction_ends_at` và tăng `extended_count += 1`. Quy tắc này áp dụng lặp lại nếu vẫn có lượt trả giá mới trong khung giờ gia hạn. | `FR-AC-03` |
| `BR-AU-05` | Điều kiện Người bán Chốt phiên sớm (`Seller Early Close`) | Người bán chỉ được phép bấm Chốt phiên sớm khi thỏa mãn đồng thời 3 điều kiện:<br>1. Phiên đấu giá đang ở trạng thái `LIVE` (`now() < auction_ends_at`).<br>2. Đã có ít nhất 1 lượt trả giá hợp lệ (`leading_bidder_id IS NOT NULL`).<br>3. Giá cao nhất hiện tại đã đạt hoặc vượt giá sàn (`current_highest_bid >= reserve_price`, nếu sản phẩm có đặt `reserve_price`). | `FR-AC-04` |
| `BR-AU-06` | Xác định Người thắng & Chống tạo Đơn hàng trùng | Khi phiên đấu giá đóng lại (do hết giờ hoặc chốt sớm):<br>- Nếu có `leading_bidder_id` và đạt `reserve_price`: người dẫn đầu trở thành `winner_id`, hệ thống tự động tạo **duy nhất 1 đơn hàng** gắn với `auction_id` (ràng buộc `UNIQUE(auction_id)` trên bảng `orders` để chống tạo đơn trùng khi Scheduled Job chạy lặp).<br>- Nếu không có lượt trả giá nào hoặc `current_highest_bid < reserve_price`: phiên chuyển sang `ENDED_UNSOLD`, không tạo đơn hàng. | `FR-AC-05` |
| `BR-AU-07` | Hạn thanh toán Đơn đấu giá & Chính sách Quá hạn (`DEC-02`) | Người thắng đấu giá phải hoàn tất thanh toán trước mốc `payment_expires_at = order_created_at + auction_payment_deadline` (mặc định **30 phút** ở Production / **2 phút** ở Demo Mode). Nếu quá hạn mà chưa thanh toán (`payment_status == UNPAID`):<br>1. Đơn hàng tự động chuyển sang trạng thái `CANCELLED` (với lý do `PAYMENT_EXPIRED`).<br>2. Phiên đấu giá chuyển sang `WINNER_DEFAULTED`.<br>3. Hệ thống mở khóa để **Người bán có quyền đăng lại sản phẩm vào phiên đấu giá tiếp theo**, tuyệt đối không tự động ép người trả giá cao thứ 2 phải mua. | `FR-AC-06`, `DEC-02` |

---

## 5. Nhóm Quy Tắc Giỏ Hàng, Đơn Hàng, Hủy Đơn & Vận Chuyển (`BR-OR`)

| Mã BR | Tên Quy Tắc | Nội Dung Quy Tắc & Logic Kiểm Tra Bắt Buộc | Liên Kết |
| :--- | :--- | :--- | :--- |
| `BR-OR-01` | Một Người bán trên mỗi Đơn hàng (Single-Seller per Order) | Giỏ hàng có thể chứa sản phẩm `FIXED_PRICE` từ nhiều người bán khác nhau, nhưng mỗi đơn hàng (`orders`) chỉ được phép chứa sản phẩm của **duy nhất một Người bán (`seller_id`)**. Nếu người mua chọn thanh toán sản phẩm của nhiều người bán, hệ thống phải tách thành các thao tác/đơn hàng riêng biệt. Sản phẩm đấu giá (`AUCTION`) không được thêm vào giỏ hàng thông thường. | `FR-CR-01`, `FR-OR-01` |
| `BR-OR-02` | Bắt buộc lưu Bản chụp Sản phẩm (Mandatory Order Snapshot) | Khi khởi tạo đơn hàng, bảng `order_items` bắt buộc phải lưu cứng bản chụp (snapshot) tại thời điểm giao dịch gồm: `product_name_snapshot`, `unit_price_snapshot`, `condition_snapshot`, `defect_snapshot`, và `image_url_snapshot`. Mọi thay đổi về sau trên bảng `products` không được làm thay đổi dữ liệu lịch sử trong `order_items`. | `FR-OR-02` |
| `BR-OR-03` | Giữ chỗ tồn kho & Khóa dòng khi Đặt hàng | Khi tạo đơn hàng `FIXED_PRICE`, Backend phải khóa dòng bản ghi `products` (`lockForUpdate()`), kiểm tra `available_quantity >= requested_quantity` và trừ ngay số lượng `available_quantity`. Nếu đơn hàng sau đó bị hủy (`CANCELLED`), số lượng này mới được cộng trả lại vào `available_quantity`. | `FR-OR-02`, `FR-OR-03` |
| `BR-OR-04` | Quy tắc Hủy đơn hàng theo 3 cấp trạng thái (`DEC-06`) | Quyền hủy đơn hàng được kiểm soát nghiêm ngặt theo `order_status`:<br>1. **`PENDING_PAYMENT`:** Buyer có quyền hủy trực tiếp ngay lập tức (hoặc System tự hủy khi quá hạn `payment_expires_at`).<br>2. **`PAID` (Seller chưa bấm `PREPARING`):** Cả **Buyer** và **Seller** đều có quyền bấm Hủy đơn trực tiếp $\rightarrow$ Đơn chuyển ngay sang `CANCELLED` và kích hoạt hoàn tiền 100% `total_amount` cho Buyer.<br>3. **`PREPARING` (Seller đã xác nhận chuẩn bị hàng):**<br>   - **Seller** có quyền hủy trực tiếp (nếu phát hiện lỗi/hết hàng) $\rightarrow$ Hoàn tiền 100% `total_amount` cho Buyer.<br>   - **Buyer** không được tự hủy trực tiếp mà chỉ được gửi **Yêu cầu hủy đơn (`Request Cancellation`)**. Đơn hàng chỉ chuyển sang `CANCELLED` (và hoàn tiền 100%) nếu **Seller bấm Đồng ý (`Approve Cancellation`)**. Nếu Seller từ chối và chuyển sang `SHIPPED`, đơn tiếp tục luồng giao hàng.<br>4. **Từ `SHIPPED` trở đi (`SHIPPED`, `DELIVERED`, `COMPLETED`):** Cấm mọi thao tác hủy đơn trực tiếp. Nếu có sự cố ở `SHIPPED` hoặc `DELIVERED`, Buyer phải mở Khiếu nại (`Dispute`). | `FR-OR-03`, `DEC-06` |
| `BR-OR-05` | Ghi nhận mốc Tự động Hoàn tất khi Giao hàng (`Fixed Auto-Complete Timestamp`) | Khi Seller cập nhật trạng thái vận chuyển của đơn hàng sang `DELIVERED`, Backend bắt buộc ghi nhận `delivered_at = now()` và tính cứng mốc `auto_complete_at = now() + auto_complete_duration` (mặc định **24 giờ** ở Production Mode / **2 phút** ở Demo Mode) lưu trực tiếp vào bản ghi `orders`. Việc thay đổi cấu hình `platform_settings` sau thời điểm này không làm thay đổi `auto_complete_at` của các đơn đã giao trước đó. | `FR-SH-01`, `FR-ES-02` |

---

## 6. Nhóm Quy Tắc Tài Chính, Phí Bảo Vệ Người Mua & Sổ Cái Escrow (`BR-FN`)

| Mã BR | Tên Quy Tắc | Nội Dung Quy Tắc & Công Thức Tính Toán Bắt Buộc | Liên Kết |
| :--- | :--- | :--- | :--- |
| `BR-FN-01` | Kiểu dữ liệu Tiền tệ & Đơn vị | Mọi cột lưu trữ số tiền trong PostgreSQL 18 bắt buộc sử dụng kiểu `NUMERIC(15, 2)` (tuyệt đối cấm dùng `FLOAT`, `REAL` hoặc `DOUBLE PRECISION`). Đơn vị tiền tệ là `VND`, làm tròn đến hàng đơn vị đồng (`ROUND(..., 0)`). | `CON-03` |
| `BR-FN-02` | Công thức Tính Giá trị Đơn hàng & Phí Bảo Vệ Người Mua (`DEC-04`) | Nền tảng **miễn phí vận chuyển trên app (`shipping_fee = 0`)** và **không thu phí hoa hồng từ người bán (Seller nhận 100% tiền hàng)**. Mọi đơn hàng (cả `FIXED_PRICE` lẫn `AUCTION`) đều áp dụng công thức sau tại thời điểm tạo đơn:<br>1. **Tiền hàng gốc (`item_subtotal`):**<br>   - Với đơn Fixed Price: $\text{item\_subtotal} = \sum (\text{unit\_price\_snapshot} \times \text{quantity})$.<br>   - Với đơn Đấu giá: $\text{item\_subtotal} = \text{winning\_bid\_amount}$.<br>2. **Phí bảo vệ người mua (`buyer_protection_fee`):**<br>   $$\text{buyer\_protection\_fee} = \text{ROUND}(\text{item\_subtotal} \times \text{protection\_fee\_rate}, 0) + \text{protection\_fixed\_fee}$$<br>   *(Trong đó `protection_fee_rate` nằm trong dải `5% – 8%` [mặc định `0.06` tức `6%`] và `protection_fixed_fee` nằm trong dải `5.000đ – 10.000đ` [mặc định `7.000đ`], lấy từ `platform_settings` và lưu snapshot vào đơn hàng)*.<br>3. **Tổng tiền Người mua phải thanh toán (`total_amount`):**<br>   $$\text{total\_amount} = \text{item\_subtotal} + \text{buyer\_protection\_fee}$$ | `FR-OR-01`, `DEC-04` |
| `BR-FN-03` | Chống thanh toán trùng & Khởi tạo Khoản Giữ Tiền (`Escrow Hold`) | Một đơn hàng chỉ được phép có **duy nhất một** giao dịch thanh toán ở trạng thái `PAID`. Ngay khi thanh toán QR mô phỏng thành công:<br>- Khoản tiền giữ trung gian ban đầu phải bằng đúng tổng thanh toán của người mua: $\text{escrow\_held\_amount} = \text{total\_amount}$.<br>- Hệ thống tạo bút toán `HOLD` trong `escrow_transactions` và đặt `escrow_status = HELD`. Tiền đang giữ trong `HELD` không được phép tính vào số dư khả dụng (`available_balance`) của người bán. | `FR-PM-02`, `FR-ES-01` |
| `BR-FN-04` | Điều kiện & Công thức Giải ngân cho Người bán (`Escrow Release`) | Hệ thống chỉ được phép giải ngân tiền cho Người bán khi thỏa mãn đồng thời 3 điều kiện:<br>1. `escrow_status == HELD` và `payment_status == PAID`.<br>2. **Không có khiếu nại đang mở (`dispute_status != OPEN` và `dispute_status != NEED_MORE_INFO`)**.<br>3. Một trong ba sự kiện hợp lệ xảy ra: (a) Buyer bấm xác nhận nhận hàng (`Confirm Delivery`) khi đơn đang `DELIVERED`, hoặc (b) Hệ thống tự động hoàn tất khi `order_status == DELIVERED` và `now() >= auto_complete_at`, hoặc (c) Admin ra phán quyết `RELEASE_TO_SELLER` / `REJECT_DISPUTE`.<br>**Công thức phân bổ khi Giải ngân hoàn tất:**<br>- **Số tiền cộng vào Ví khả dụng của Seller (`seller_payout_amount`):** Bằng đúng **100% tiền hàng (`item_subtotal`)** (`DEC-04`).<br>- **Doanh thu phí bảo vệ của Nền tảng (`platform_fee_retained`):** Bằng đúng **`buyer_protection_fee`**. | `FR-ES-02`, `DEC-04` |
| `BR-FN-05` | Công thức Hoàn tiền 100% cho Người mua (`Full Refund Rule – DEC-07`) | Khi đơn hàng đã thanh toán (`escrow_status == HELD`) bị hủy hợp lệ ở bước `PAID` / `PREPARING` (`BR-OR-04`) HOẶC khi Admin ra phán quyết chấp nhận khiếu nại hoàn tiền toàn bộ (`APPROVE_BUYER_REFUND`):<br>- **Số tiền hoàn trả cho Buyer (`buyer_refund_amount`):** Bằng đúng **100% `total_amount` (bao gồm cả `item_subtotal` + `buyer_protection_fee`)** (`DEC-07`).<br>- Người bán nhận `0đ` và nền tảng không giữ lại `buyer_protection_fee` trong trường hợp hoàn tiền 100% này nhằm đảm bảo cam kết bảo vệ người mua tuyệt đối. | `FR-OR-03`, `FR-DP-03`, `DEC-07` |
| `BR-FN-06` | Công thức Hoàn tiền Một phần (`Partial Refund Rule`) | Khi Admin phân xử khiếu nại theo phương án `PARTIAL_REFUND` (người mua giữ lại món hàng nhưng được hoàn một phần tiền do lỗi nhỏ):<br>- Admin chỉ định số tiền hoàn cho người mua `partial_refund_amount` thỏa mãn: $0 < \text{partial\_refund\_amount} < \text{item\_subtotal}$.<br>- Số tiền giải ngân cho người bán: $\text{seller\_release\_amount} = \text{item\_subtotal} - \text{partial\_refund\_amount}$.<br>- Khoản `buyer_protection_fee` được giữ lại cho nền tảng vì giao dịch vẫn hoàn tất một phần. Tổng các bút toán ra phải khớp tuyệt đối với khoản `HOLD` ban đầu: $\text{partial\_refund\_amount} + \text{seller\_release\_amount} + \text{buyer\_protection\_fee} = \text{total\_amount}$. | `FR-DP-03` |
| `BR-FN-07` | Sổ cái Bất biến (Append-Only Immutable Ledger) | Các bảng `escrow_transactions`, `wallet_transactions` và `refunds` hoạt động theo nguyên tắc **Append-Only**:<br>- Tuyệt đối **cấm thực hiện câu lệnh `UPDATE` hoặc `DELETE`** làm thay đổi số tiền/trạng thái của các dòng bút toán lịch sử đã ghi nhận (ngay cả đối với Admin).<br>- Mọi biến động giữ tiền (`HOLD`), giải ngân (`RELEASE`), hoàn tiền (`REFUND`) đều phải tạo thành một dòng bản ghi mới có mã tham chiếu duy nhất (`transaction_reference`) nằm trong `DB::transaction()`. | `PERM-FN-07` |

---

## 7. Nhóm Quy Tắc Khiếu Nại, Đánh Giá & Kiểm Toán Quản Trị (`BR-DP`, `BR-RV`, `BR-AD`)

| Mã BR | Tên Quy Tắc | Nội Dung Quy Tắc & Logic Kiểm Tra Bắt Buộc | Liên Kết |
| :--- | :--- | :--- | :--- |
| `BR-DP-01` | Khung thời gian hợp lệ để mở Khiếu nại (`Dispute Window – DEC-03`) | Người mua chỉ được phép mở khiếu nại (`Dispute`) khi đơn hàng đang ở trạng thái **`SHIPPED`** hoặc **`DELIVERED`**, đã thanh toán (`escrow_status == HELD`) và **chưa chuyển sang `COMPLETED`** (`DEC-03`). Mỗi đơn hàng chỉ có tối đa 1 hồ sơ khiếu nại đang hoạt động tại một thời điểm. | `FR-DP-01`, `DEC-03` |
| `BR-DP-02` | Cơ chế Khóa cứng Giải ngân khi có Khiếu nại (`Escrow Freeze Rule`) | Ngay giây phút hồ sơ khiếu nại được tạo (`dispute_status = OPEN`), hệ thống phải khóa cứng việc giải ngân của đơn hàng đó. Mọi tiến trình Scheduled Job tự động hoàn tất đơn (`Auto Complete Delivered Orders`) hoặc nút `Confirm Delivery` đều bị vô hiệu hóa đối với đơn hàng đang có `dispute_status IN ('OPEN', 'NEED_MORE_INFO')`. Chỉ có phán quyết của **Administrator** (`ACT-05`) mới có thể mở khóa và xử lý khoản tiền này. | `FR-DP-01`, `FR-DP-03` |
| `BR-RV-01` | Điều kiện Đánh giá Người bán (One Verified Review per Completed Order) | Chỉ người mua của đơn hàng đã đạt trạng thái **`COMPLETED`** mới được gửi đánh giá (1–5 sao kèm nhận xét). Hệ thống áp dụng ràng buộc `UNIQUE(order_id)` trên bảng `reviews` để đảm bảo mỗi đơn hàng hoàn tất chỉ tạo ra tối đa 1 đánh giá duy nhất. Đơn hàng bị `CANCELLED` hoặc `REFUNDED` hoàn toàn không được phép đánh giá. | `FR-RV-01` |
| `BR-AD-01` | Tính Lũy đẳng của Scheduled Jobs & Demo Mode Triggers (`Idempotency Rule`) | Toàn bộ 8 tác vụ định kỳ của hệ thống (và các nút bấm trong **Developer Tools** khi `DEMO_MODE=true`) bắt buộc phải có tính **lũy đẳng (idempotent)**: nếu cùng một job được kích hoạt 2 hoặc 10 lần liên tiếp, kết quả trạng thái và số bút toán tài chính sinh ra phải giống hệt như chạy 1 lần duy nhất (không bao giờ tạo 2 đơn hàng cho cùng 1 phiên đấu giá, không bao giờ giải ngân 2 lần cho cùng 1 đơn hàng). | `FR-AD-05`, `UC-AD-02` |
| `BR-AD-02` | Bắt buộc lưu Nhật ký Kiểm toán (`Mandatory Admin Audit Trail`) | Mọi hành động của `Moderator`, `Support Staff` và `Administrator` làm thay đổi dữ liệu hệ thống (duyệt/từ chối sản phẩm, khóa/mở khóa tài khoản, phân xử khiếu nại, cập nhật `platform_settings`, chạy Demo Job) đều phải được ghi tự động vào bảng `audit_logs` trong cùng transaction với hành động đó. | `FR-AD-06` |

---

## 8. Quy Định Về 4 Vòng Đời Trạng Thái Độc Lập (The 4 Independent State Machines)

Theo kiến trúc cốt lõi của dự án, trạng thái của một giao dịch **không được gộp chung vào một cột**, mà được điều khiển bởi 4 máy trạng thái (State Machines) riêng biệt trên bảng `orders` (cùng 2 máy trạng thái cho `products` và `auctions`):

### 8.1. Vòng đời Sản phẩm (`product.status`)
- `DRAFT` $\rightarrow$ `PENDING_REVIEW` (Seller bấm gửi duyệt).
- `PENDING_REVIEW` $\rightarrow$ `APPROVED` (Moderator/Admin duyệt) | `REJECTED` (Moderator/Admin từ chối kèm lý do – `DEC-05`).
- `REJECTED` $\rightarrow$ `PENDING_REVIEW` (Seller sửa thông tin và bấm gửi duyệt lại `Resubmit`).
- `APPROVED` $\rightarrow$ `SOLD` (Khi bán hết số lượng hoặc phiên đấu giá hoàn tất thanh toán) | `HIDDEN` (Seller tự ẩn hoặc Moderator/Admin gỡ bài).
- `SOLD` / `HIDDEN` $\rightarrow$ `ARCHIVED` (Lưu trữ lịch sử).
- *Chuyển ngược hợp lệ khi hủy đơn:* `SOLD` $\rightarrow$ `APPROVED` (Khi đơn hàng Fixed Price bị hủy hoặc khi người thắng đấu giá quá hạn thanh toán 30 phút và Seller đăng lại – `DEC-02`).

### 8.2. Vòng đời Phiên Đấu giá của Sản phẩm (`auction.status`)
- `SCHEDULED` (Đã được duyệt và gắn vào khung giờ phiên) $\rightarrow$ `LIVE` (Khi đến giờ bắt đầu phiên).
- `LIVE` $\rightarrow$ `COMPLETED` (Khi hết giờ `now() >= auction_ends_at` hoặc Seller chốt sớm `Close Early` mà có người dẫn đầu đạt `reserve_price`).
- `LIVE` $\rightarrow$ `ENDED_UNSOLD` (Khi hết giờ mà không có ai trả giá hoặc chưa đạt `reserve_price`).
- `LIVE` / `SCHEDULED` $\rightarrow$ `CANCELLED` (Admin hủy phiên do phát hiện gian lận).
- `COMPLETED` $\rightarrow$ `WINNER_DEFAULTED` (Khi người thắng không thanh toán đơn hàng đấu giá trong thời hạn `payment_expires_at` – `DEC-02`).

### 8.3. Vòng đời Đơn hàng (`order.order_status`)
- `PENDING_PAYMENT` $\rightarrow$ `PAID` (Khi thanh toán QR mô phỏng thành công) | `CANCELLED` (Buyer tự hủy hoặc quá hạn `payment_expires_at`).
- `PAID` $\rightarrow$ `PREPARING` (Seller xác nhận chuẩn bị hàng) | `CANCELLED` (Buyer hoặc Seller bấm hủy trực tiếp trước khi chuẩn bị hàng – `DEC-06`).
- `PREPARING` $\rightarrow$ `SHIPPED` (Seller nhập mã vận đơn và gửi hàng) | `CANCELLED` (Seller tự hủy hoặc Seller bấm đồng ý yêu cầu hủy của Buyer – `DEC-06`).
- `SHIPPED` $\rightarrow$ `DELIVERED` (Seller cập nhật đã giao hàng tới nơi, hệ thống ghi nhận `delivered_at` và `auto_complete_at`) | `REFUNDED` (Nếu Buyer mở khiếu nại không nhận được hàng ngay ở bước `SHIPPED` và được Admin duyệt hoàn tiền 100% – `DEC-03`).
- `DELIVERED` $\rightarrow$ `COMPLETED` (Buyer bấm xác nhận nhận hàng, hoặc quá 24h `now() >= auto_complete_at` không có khiếu nại, hoặc Admin bác bỏ khiếu nại / xử lý `PARTIAL_REFUND`) | `REFUNDED` (Admin duyệt hoàn tiền 100% `APPROVE_BUYER_REFUND`).

### 8.4. Vòng đời Thanh toán (`order.payment_status` & `payments.status`)
- `UNPAID` $\rightarrow$ `PAID` (Khi giao dịch Mock QR Payment thành công) | `EXPIRED` / `FAILED` (Khi phiên thanh toán hết hạn hoặc thất bại).

### 8.5. Vòng đời Khoản Giữ Tiền Trung Gian (`order.escrow_status`)
- `NONE` (Khi đơn mới tạo ở `PENDING_PAYMENT`) $\rightarrow$ `HELD` (Ngay khi `payment_status` chuyển sang `PAID`, giữ đủ 100% `total_amount`).
- `HELD` $\rightarrow$ `RELEASED` (Khi đơn chuyển sang `COMPLETED`, giải ngân 100% `item_subtotal` cho Seller).
- `HELD` $\rightarrow$ `REFUNDED` (Khi đơn `PAID`/`PREPARING` bị hủy hợp lệ hoặc khi Admin phán quyết `APPROVE_BUYER_REFUND`, hoàn trả 100% `total_amount` cho Buyer – `DEC-07`).
- `HELD` $\rightarrow$ `PARTIALLY_REFUNDED` (Khi Admin phán quyết `PARTIAL_REFUND`, chia khoản tiền giữ cho cả Buyer và Seller theo `BR-FN-06`).

### 8.6. Vòng đời Khiếu nại (`order.dispute_status` & `disputes.status`)
- `NONE` (Mặc định không có tranh chấp) $\rightarrow$ `OPEN` (Khi Buyer gửi khiếu nại ở trạng thái `SHIPPED` hoặc `DELIVERED` – lập tức khóa giải ngân Escrow).
- `OPEN` $\rightarrow$ `NEED_MORE_INFO` (Support Staff hoặc Admin yêu cầu bổ sung bằng chứng `REQUEST_MORE_EVIDENCE`).
- `NEED_MORE_INFO` $\rightarrow$ `OPEN` (Khi Buyer/Seller tải thêm bằng chứng).
- `OPEN` / `NEED_MORE_INFO` $\rightarrow$ `RESOLVED_REFUND` (Admin chọn `APPROVE_BUYER_REFUND`) | `RESOLVED_RELEASE` (Admin chọn `RELEASE_TO_SELLER` hoặc `REJECT_DISPUTE`) | `RESOLVED_PARTIAL` (Admin chọn `PARTIAL_REFUND`).