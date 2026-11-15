# 04. UI/UX DESIGN PRINCIPLES – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P301-DESIGN-PRINCIPLES`
- **Version:** `1.1.0`
- **Status:** `DONE`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – UI/UX Design System & High-Fidelity Specification`

---

## Chương 1. Mười Nguyên Tắc Thiết Kế Cốt Lõi Xuyên Suốt Hệ Thống (`10 Core UI/UX Design Principles`)

Mười nguyên tắc dưới đây là "hiến pháp thiết kế" bắt buộc tuân thủ khi xây dựng Design System (`P3-02`, `P3-03`), thiết kế chi tiết 49 màn hình Mobile (`P3-04`, `P3-05`) và 21 màn hình Admin (`P3-06`):

---

### Nguyên Tắc 1: Chân Thực Tạo Niềm Tin – Không Tô Hồng Đồ Cũ (`Radical Condition Transparency`)
- **Vấn đề thực tế giải quyết:** Người mua đồ secondhand sợ nhất là ảnh chụp ảo và giấu giếm khuyết điểm (`BR-PR-03`).
- **Quy tắc thực thi trên UI:**
  1. Tuyệt đối không áp bộ lọc màu vintage lên ảnh sản phẩm.
  2. Trên màn hình Chi tiết sản phẩm (`M-PR-01`) và Phòng đấu giá (`M-AC-03`), thông tin **Tình trạng (`condition`)**, **Mô tả vết xước/lỗi (`defect_info`)** và **Mức độ xác minh (`verification_level`)** phải được đặt trong một khung **"Phiếu Kiểm Định Tình Trạng" (`Condition Inspection Card`)** nằm ngay dưới giá bán (trước cả mô tả chung), kèm tính năng chạm phóng to ảnh (`M-PR-02`) để soi chi tiết lỗi.

---

### Nguyên Tắc 2: Phân Biệt Tức Thì Giữa "Mua Ngay" Và "Đấu Giá" (`Instant Listing-Type Differentiation`)
- **Vấn đề thực tế giải quyết:** Sàn có 2 cơ chế bán hoàn toàn khác nhau (`FIXED_PRICE` và `AUCTION` – `BR-PR-01`). Người dùng không được phép nhầm lẫn giữa giá mua đứt và giá khởi điểm/giá thầu hiện tại.
- **Quy tắc thực thi trên UI:**
  1. **Sản phẩm Giá cố định (`FIXED_PRICE`):** Thẻ vuông vức bo góc chuẩn, nhãn giá tĩnh kèm chữ *"Giá bán"*, thanh hành động dưới đáy có 2 nút `[Thêm vào giỏ]` và `[Mua ngay]`.
  2. **Sản phẩm Đấu giá (`AUCTION`):** Thẻ có dải băng đếm ngược thời gian thực (`⏳ Còn XX:XX`) + icon búa đấu giá `🔨` + số lượt trả giá (`🔥 X bids`), nhãn giá ghi rõ *"Giá cao nhất hiện tại"*, và thanh hành động dưới đáy chỉ có nút `[Đặt giá thầu]` (hoặc `[Chốt phiên sớm]` nếu là Seller).

---

### Nguyên Tắc 3: Hiển Thị Hóa Sự An Toàn Của Dòng Tiền Escrow (`Visible Escrow & Buyer Protection Shield`)
- **Vấn đề thực tế giải quyết:** Làm sao để người mua sẵn sàng trả thêm **Phí bảo vệ người mua (`Buyer Protection Fee` = `5%–8% + 5k–10k`)** và người bán yên tâm giao hàng (`DEC-04`, `DEC-07`)?
- **Quy tắc thực thi trên UI:**
  1. Tại màn hình Checkout (`M-OR-01`), dòng `Buyer Protection Fee` luôn đi kèm hộp thông tin ngắn gọn có biểu tượng Khiên bảo vệ: *"Tiền được giữ trong sổ cái trung gian Escrow – Hoàn lại đủ 100% (gồm cả phí bảo vệ) nếu đơn bị hủy trước khi giao hoặc hàng bị rách/sai mô tả"*.
  2. Ngược lại, trên toàn bộ giao diện của Người bán (`M-SL-03`, `M-SL-06`, `M-SL-08`), luôn hiển thị rõ dòng: **`Tiền hàng bạn thực nhận: 100% giá bán (Miễn phí hoa hồng người bán)`** (`SELLER-UX-01`).

---

### Nguyên Tắc 4: Minh Bạch 4 Trạng Thái Mà Không Gây Quá Tải Nhận Thức (` structured 4-State Clarity`)
- **Vấn đề thực tế giải quyết:** Mỗi đơn hàng vận hành trên 4 máy trạng thái độc lập (`order_status`, `payment_status`, `escrow_status`, `dispute_status` – `ADR-03`).
- **Quy tắc thực thi trên UI:**
  1. Trên màn hình danh sách (`M-OR-02`, `M-SL-05`), chỉ hiển thị **1 Huy hiệu Trạng thái Chính** dễ hiểu nhất với người dùng kèm **1 Huy hiệu phụ cho Tiền Escrow**.
  2. Trên màn hình chi tiết đơn hàng (`M-OR-03`, `M-SL-06`, `A-OR-02`), gom 4 trạng thái vào một **Thẻ Tổng Hợp Trạng Thái Giao Dịch (`Transaction Status Header Card`)** chia làm 2 tầng rõ ràng:
     - *Tầng Vận hành:* Tiến trình đơn hàng (`order_status`) + Tiến trình vận chuyển (`tracking_code`, `auto_complete_at`).
     - *Tầng Bảo vệ Tài chính:* Trạng thái Thanh toán (`payment_status`) + Trạng thái Khoản tiền giữ (`escrow_status`: `ĐANG GIỮ BẢO VỆ` / `ĐÃ GIẢI NGÂN` / `ĐÃ HOÀN TIỀN 100%` / `ĐANG ĐÓNG BĂNG DO KHIẾU NẠI`).

---

### Nguyên Tắc 5: Chuyển Đổi Vai Trò Mua – Bán Mượt Mà, Không Nhầm Lẫn (`Contextual Role Clarity`)
- **Vấn đề thực tế giải quyết:** Một tài khoản vừa Mua vừa Bán (`BR-AC-01`), dễ xảy ra rủi ro người dùng bấm nhầm thao tác hoặc tự mua/tự đấu giá hàng của mình (`BR-AC-02`).
- **Quy tắc thực thi trên UI:**
  1. Không gian **Người mua** (Tab 1, 2, 3, 5) dùng tiêu đề trang nền kem ấm; không gian **Kênh Bán (`Tab 4 – Seller Center`)** dùng Header màu xanh rừng thông trầm đặc trưng để người dùng nhận biết ngay *"Mình đang ở trong Tiệm bán hàng của mình"*.
  2. Khi chủ sản phẩm xem chính bài đăng của mình trên sàn công khai (`M-PR-01`, `M-AC-03`), hệ thống tự động thay thế thanh nút mua/đặt giá bằng thanh công cụ quản lý của chủ tiệm (`Owner Context Bar`).

---

### Nguyên Tắc 6: Tốc Độ Và Sự Chính Xác Trong Tác Vụ Thời Gian Thực (`Time-Critical Precision`)
- **Vấn đề thực tế giải quyết:** Đấu giá tính bằng giây (kèm gia hạn Anti-sniping `BR-AU-04`), hạn thanh toán đơn thắng đấu giá tính bằng phút (`30 phút / 2 phút Demo` – `BR-AU-07`), hạn tự hoàn tất đơn sau khi giao (`24 giờ / 2 phút Demo` – `BR-OR-05`).
- **Quy tắc thực thi trên UI:**
  1. Mọi đồng hồ đếm ngược bắt buộc dùng kiểu số có độ rộng cố định (`tabular-nums`) để con số không bị giật ngang mỗi giây.
  2. Khi thời gian còn lại bước vào ngưỡng khẩn cấp (ví dụ: 2 phút cuối phiên đấu giá hoặc 5 phút cuối hạn thanh toán), hộp đồng hồ tự động chuyển sang tông màu cảnh báo đỏ rượu vang (`Burgundy Alert`) và hiển thị rõ thông báo khi Anti-sniping cộng thêm giờ.

---

### Nguyên Tắc 7: Tối Ưu Thao Tác Nhanh Cho Người Bán Cá Nhân (`Frictionless C2C Selling`)
- **Vấn đề thực tế giải quyết:** Người bán trên sàn C2C không phải nhân viên vận hành chuyên nghiệp; nếu form đăng bài hoặc cập nhật đơn quá phức tạp, họ sẽ bỏ cuộc.
- **Quy tắc thực thi trên UI:**
  1. Form đăng sản phẩm (`M-SL-03`) sử dụng các nút chọn nhanh (`Choice Chips`) cho Tình trạng (`Like New`, `Good`, `Fair`, `Vintage Worn`) và chuyển đổi mượt mà giữa `Fixed Price` và `Auction` ngay trên một màn hình kèm nút `[Lưu nháp]` mọi lúc.
  2. Khi sản phẩm bị `REJECTED` (`DEC-05`), màn hình chỉnh sửa ghim sẵn lý do của Moderator ngay đầu trang để Seller nhìn vào sửa được ngay mà không phải nhớ.

---

### Nguyên Tắc 8: Mật Độ Thông Tin Cao & Phân Quyền Trực Quan Cho Admin (`High-Density, Role-Safe Admin UI`)
- **Vấn đề thực tế giải quyết:** Admin, Moderator và Support Staff cần xử lý nhanh hàng chờ kiểm duyệt, đối soát sổ cái bất biến và phân xử tranh chấp mà không phạm lỗi phân quyền (`03_ACTOR_PERMISSION_MATRIX.md`).
- **Quy tắc thực thi trên UI:**
  1. Các màn hình kiểm duyệt (`A-MD-02`) và xử lý khiếu nại (`A-DP-02`) sử dụng bố cục 2 cột ngang (`Split-View`) để đối chiếu ảnh bằng chứng và thông tin đơn hàng cùng lúc mà không phải cuộn lên xuống nhiều lần.
  2. Thực thi phân quyền ngay trên giao diện: ẩn hoàn toàn cụm nút phán quyết tài chính đối với `Support Staff`, và gắn nhãn `CHỈ ĐỌC (READ-ONLY LEDGER)` rõ ràng trên sổ cái Escrow (`A-ES-01`).

---

### Nguyên Tắc 9: Ưu Tiên Khả Năng Đọc Tiếng Việt Chuẩn Xác Tuyệt Đối (`Vietnamese Typography First – ADR-07`)
- **Vấn đề thực tế giải quyết:** Lỗi hiển thị dấu tiếng Việt trên các bộ font vintage trang trí (`UI-01`, `UI-02`).
- **Quy tắc thực thi trên UI:**
  1. Toàn bộ văn bản tiếng Việt động do người dùng nhập (tên sản phẩm, mô tả lỗi, tin nhắn chat, đánh giá, lý do khiếu nại) bắt buộc hiển thị bằng các bộ font hỗ trợ 100% bảng mã tiếng Việt Unicode NFC (`Fraunces` cho tiêu đề và `Be Vietnam Pro` cho nội dung/nút bấm/giá tiền).
  2. Font display `Wichita Vintage` chỉ được dùng cho Logo thương hiệu `izithrift` và các nhãn trang trí tĩnh đã được kiểm chứng từng ký tự.

---

### Nguyên Tắc 10: Kiến Trúc Chủ Đề Mùa Vụ Tách Lớp (`Modular Seasonal Theming – NFR-UX-02`)
- **Vấn đề thực tế giải quyết:** Giữ được không khí lễ hội Giáng sinh ấm áp khi trình diễn đồ án nhưng chứng minh được kiến trúc phần mềm bền vững có thể vận hành quanh năm.
- **Quy tắc thực thi trên UI:**
  1. Toàn bộ thành phần trang trí mùa lễ hội (Hero Banner Giáng sinh, icon mũ Santa/tất sọc/cành thông nhỏ ở góc thẻ hoặc Empty State) được thiết kế như một **Lớp trang trí phủ ngoài (`Seasonal Accent Layer`)** điều khiển bởi cờ `enableSeasonalChristmasDecor` trong `M-PF-06` (Settings).
  2. Khi tắt cờ này, ứng dụng lập tức trở về giao diện **Warm Editorial Vintage** tiêu chuẩn quanh năm mà không bị lệch bất kỳ một pixel bố cục nào.