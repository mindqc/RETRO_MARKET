# 02. TYPOGRAPHY SYSTEM SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P302-TYPOGRAPHY`
- **Version:** `1.0.0`
- **Status:** `SELF-VERIFIED & READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – UI/UX Design System & High-Fidelity Specification`
- **Approved Direction Ref:** `ADR-07` (*3-Tier Font Hierarchy & Vietnamese NFC*), `NFR-UX-01`, `UI-DEC-01`

---

## Chương 1. Kiến Trúc Kiểu Chữ 3 Tầng & Giải Pháp Triệt Để Cho Tiếng Việt (`3-Tier Font Architecture & Vietnamese Support`)

Một trong những rủi ro kỹ thuật lớn nhất của các ứng dụng mang phong cách Vintage tại Việt Nam là lỗi **thiếu ký tự dấu tiếng Việt (Missing Glyphs / Tofu)** hoặc **hiện tượng chắp vá chữ cái (Ransom Note Effect)** khi một từ có dấu tổ hợp (`ắ, ặ, ấ, ậ, ể, ễ, ộ, ợ, ự, đ`) bị hệ điều hành tự động thay thế riêng lẻ bằng font mặc định Roboto/Arial.

Để giải quyết triệt để vấn đề này theo đúng `ADR-07` và `NFR-UX-01`, **Retro Market (`izithrift`)** áp dụng kiến trúc phân tầng 3 bộ font rõ ràng:

| Tầng Kiểu Chữ | Tên Font Family Chính Thức | Phạm Vi Sử Dụng Được Phép | Quy Tắc Hỗ Trợ Tiếng Việt & Fallback (`ADR-07`) |
| :--- | :--- | :--- | :--- |
| **Tầng 1: Brand & Controlled Seasonal Display** | **`Wichita Vintage`**<br>*(Fallback: `Fraunces`)* | **Chỉ dùng cực kỳ giới hạn** cho: Logo thương hiệu `izithrift`, tiêu đề tĩnh trên Onboarding/Hero Banner đã được kiểm tra từng ký tự không bị lỗi dấu. | **CẤM TUYỆT ĐỐI** dùng `Wichita Vintage` cho dữ liệu động do người dùng nhập (tên sản phẩm, tên tiệm, bình luận, danh mục động). |
| **Tầng 2: Editorial Serif Headings** | **`Fraunces`**<br>*(Google Fonts – Variable Optical Size)* | Dùng cho toàn bộ **Tiêu đề màn hình (`H1`, `H2`, `H3`)**, **Tên bộ sưu tập**, **Tên sản phẩm trên trang chi tiết (`M-PR-01`, `M-AC-03`)** và **Tên Tiệm bán**. | `Fraunces` là bộ chữ Serif phong cách biên tập cổ điển (Old-style Soft Serif) hỗ trợ **100% bảng mã tiếng Việt Unicode dựng sẵn (NFC)** với đầy đủ dấu thanh và dấu mũ tuyệt đẹp. |
| **Tầng 3: Primary UI, Body & Commerce Numerals** | **`Be Vietnam Pro`**<br>*(Google Fonts – Thiết kế chuyên biệt cho tiếng Việt)* | Dùng cho **100% nội dung giao dịch**: Mô tả sản phẩm, `defect_info`, nhãn trạng thái, nút bấm, form input, tin nhắn chat, bảng dữ liệu Admin, **Giá tiền (`VND`)**, **Đồng hồ đếm ngược**, **Mã đơn hàng**. | Được thiết kế gốc cho tiếng Việt với khoảng cách dấu thanh chuẩn xác, lòng chữ thoáng, đọc cực rõ ở kích thước nhỏ (`12px–14px`) trên cả Flutter và Web. |
| **Tầng Bổ Trợ: Monospace Codes & Timers** | **`JetBrains Mono`** *(hoặc `Be Vietnam Pro` với `fontFeature: tabularFigures`)* | Dùng cho: Mã tham chiếu thanh toán (`payment_reference`), Mã vận đơn (`tracking_code`), Mã bút toán sổ cái (`ETX-...`), JSON Audit Logs (`A-AD-01`). | Đảm bảo độ rộng mỗi ký tự và chữ số bằng nhau tuyệt đối, chống nhảy khung khi đếm ngược từng giây. |

---

## Chương 2. Bảng Quy Chuẩn Các Kiểu Chữ (`Complete Type Scale & Style Specification`)

Toàn bộ kích thước tuân thủ thang đo chuẩn (`Base = 16px`), áp dụng thống nhất giữa Flutter (`TextStyle`) và Laravel Blade (`CSS Classes`):

### 2.1. Display & Editorial Heading Styles (Nhóm Tiêu Đề)

| Token Name | Font Family | Size (`px`/`sp`) | Weight | Line Height | Letter Spacing | Ngữ Cảnh Sử Dụng Thực Tế |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| `type.brand.logo` | `Wichita Vintage` | `28px` | `400 (Regular)` | `32px (1.14)` | `+0.5px` | Logo chữ `izithrift` trên Top App Bar (`M-HM-01`), màn hình Splash (`M-AU-01`) và Sidebar Admin. |
| `type.display.hero` | `Fraunces` | `28px` | `700 (Bold)` | `36px (1.28)` | `-0.3px` | Tiêu đề lớn trên Christmas Hero Banner (`M-HM-01`) và màn hình Onboarding (`M-AU-02`). |
| `type.heading.h1` | `Fraunces` | `24px` | `700 (Bold)` | `32px (1.33)` | `-0.2px` | Tiêu đề chính của màn hình độc lập (Login, Register, Seller Dashboard, Admin Page Title). |
| `type.heading.h2` | `Fraunces` | `20px` | `600 (SemiBold)` | `28px (1.40)` | `-0.1px` | Tên sản phẩm trên trang Chi tiết (`M-PR-01`, `M-AC-03`), Tiêu đề các khu vực lớn trên Trang chủ. |
| `type.heading.h3` | `Fraunces` | `18px` | `600 (SemiBold)` | `24px (1.33)` | `0px` | Tiêu đề của `Bottom Sheet`, `Dialog`, `Modal` và tiêu đề khối thẻ (`Card Header`). |

---

### 2.2. Title, Body, Label & Button Styles (Nhóm Nội Dung & Điều Khiển Giao Diện)

| Token Name | Font Family | Size (`px`/`sp`) | Weight | Line Height | Letter Spacing | Ngữ Cảnh Sử Dụng Thực Tế |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| `type.title.card` | `Be Vietnam Pro` | `15px` | `600 (SemiBold)` | `20px (1.33)` | `0px` | Tên sản phẩm trên lưới thẻ 2 cột (`Product Card`, `Auction Card` – giới hạn tối đa 2 dòng `maxLines: 2`, `ellipsis`). |
| `type.title.section` | `Be Vietnam Pro` | `16px` | `600 (SemiBold)` | `24px (1.50)` | `0px` | Tiêu đề nhóm thông tin trong Chi tiết đơn hàng, Phiếu kiểm định tình trạng (`Condition Slip`) và Form đăng bán. |
| `type.body.large` | `Be Vietnam Pro` | `16px` | `400 (Regular)` | `24px (1.50)` | `0px` | Văn bản nhập trong ô Input Field, nội dung tin nhắn Chat (`M-CM-02`) và bài mô tả chi tiết sản phẩm. |
| `type.body.medium` | `Be Vietnam Pro` | `14px` | `400 (Regular)` | `20px (1.43)` | `0px` | Văn bản thân bài tiêu chuẩn: mô tả lỗi (`defect_info`), nhận xét đánh giá (`Reviews`), lý do khiếu nại và dòng dữ liệu bảng Admin. |
| `type.body.medium.strong` | `Be Vietnam Pro` | `14px` | `600 (SemiBold)` | `20px (1.43)` | `0px` | Nhấn mạnh từ khóa quan trọng trong câu, tên người bán trên thẻ, tên trường trong bảng tóm tắt phí. |
| `type.caption.default` | `Be Vietnam Pro` | `12px` | `400 (Regular)` | `16px (1.33)` | `+0.1px` | Chú thích phụ, thời gian đăng bài, hướng dẫn dưới ô input (`Helper Text`) và thông báo lỗi validation. |
| `type.label.badge` | `Be Vietnam Pro` | `11px` | `600 (SemiBold)` | `14px (1.27)` | `+0.3px` | Chữ bên trong toàn bộ các huy hiệu trạng thái (`Status Badge`, `Condition Badge`, `LEADING / OUTBID Badge`). |
| `type.button.large` | `Be Vietnam Pro` | `15px` | `600 (SemiBold)` | `20px (1.33)` | `+0.2px` | Chữ trên các nút hành động chính (`Primary / Secondary / Destructive Button` cao `48px`). |
| `type.button.small` | `Be Vietnam Pro` | `13px` | `600 (SemiBold)` | `18px (1.38)` | `+0.1px` | Chữ trên các nút hành động nhỏ trong thẻ, chip cộng bước giá nhanh (`+50k`) và nút thao tác bảng Admin. |

---

## Chương 3. Chuẩn Hóa Kiểu Số Thương Mại Điện Tử & Đấu Giá (`Specialized Commerce & Numeric Typography`)

Trong giao dịch mua bán và đấu giá, các con số mang tính quyết định tài chính. Hệ thống bắt buộc kích hoạt thuộc tính **`font-variant-numeric: tabular-nums`** (`FontFeature.tabularFigures()` trong Flutter) cho 7 kiểu dữ liệu số sau:

| Token Name | Font Family & Feature | Size & Weight | Quy Tắc Định Dạng Hiển Thị Chuẩn (`Formatting Rules`) |
| :--- | :--- | :---: | :--- |
| `type.numeric.price.hero` | `Be Vietnam Pro`<br>+ `tabular-nums` | `24px` \| `700 (Bold)` | Hiển thị **Giá bán chính** trên `M-PR-01`, **Giá cao nhất hiện tại** trên `M-AC-03` và **Tổng thanh toán (`total_amount`)** trên `M-OR-01` / `M-PM-01`. Định dạng phân tách hàng nghìn bằng dấu chấm: **`643.000 VNĐ`** (hoặc **`643.000đ`** trên thẻ nhỏ). |
| `type.numeric.price.card` | `Be Vietnam Pro`<br>+ `tabular-nums` | `16px` \| `700 (Bold)` | Hiển thị giá trên lưới `Product Card` và `Auction Card` (`M-HM-01`, `M-DS-02`, `M-AC-01`). |
| `type.numeric.ledger` | `Be Vietnam Pro`<br>+ `tabular-nums` | `14px` \| `600 (SemiBold)` | Hiển thị các dòng tiền trong Bảng kê `Checkout Preview` (`item_subtotal`, `buyer_protection_fee`), Sổ cái Ví (`M-SL-08`) và Bảng đối soát Escrow của Admin (`A-ES-01`). **Bắt buộc căn lề phải (`Right-Aligned`)** trong các bảng kế toán. |
| `type.numeric.countdown.hero` | `JetBrains Mono`<br>*(hoặc `Be Vietnam Pro` Tabular)* | `20px` \| `700 (Bold)` | Hiển thị **Đồng hồ đếm ngược Phiên đấu giá (`M-AC-03`)** và **Hạn thanh toán 30 phút (`M-PM-01`, `M-AC-02`)** theo định dạng cố định 2 chữ số: **`HH : MM : SS`** (ví dụ: `00 : 29 : 45`). Không bao giờ bị rung lắc ngang khi số giây nhảy. |
| `type.numeric.countdown.card` | `Be Vietnam Pro`<br>+ `tabular-nums` | `12px` \| `600 (SemiBold)` | Đồng hồ đếm ngược thu gọn trên thẻ đấu giá ngoài danh sách (`⏳ 08:42`). |
| `type.code.identifier` | `JetBrains Mono` | `13px` \| `500 (Medium)` | Hiển thị **Mã đơn hàng (`#ORD-2026-0891`)**, **Mã tham chiếu thanh toán (`PAY-REF-99281`)**, **Mã vận đơn (`GHN8829104`)** và **Mã bút toán Escrow (`ETX-2026-104`)** để dễ đọc và sao chép. |
| `type.numeric.timestamp` | `Be Vietnam Pro`<br>+ `tabular-nums` | `12px` \| `400 (Regular)` | Hiển thị ngày giờ chuẩn Việt Nam: **`DD/MM/YYYY HH:mm`** (hoặc `HH:mm:ss` đối với lịch sử đặt giá đấu giá `auction_bids` và `audit_logs`). |

---

## Chương 4. Quy Trình Kiểm Thử Chuỗi Tiếng Việt Mẫu (`Vietnamese Glyph Verification String`)

Trước khi đưa bất kỳ màn hình nào vào nghiệm thu (`QA-03`), phải kiểm tra hiển thị chuỗi văn bản tiếng Việt chứa đầy đủ nguyên âm có dấu kép sau trên cả `Fraunces` và `Be Vietnam Pro`:
> *"Tiệm đồ si ấm áp đêm Giáng sinh: Chiếc đồng hồ cổ điển & áo khoác dạ tuyệt đẹp, giữ tiền bảo vệ người mua chuẩn xác 100% (check tiếng việt)."*