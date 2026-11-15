# 01. PROJECT CHARTER – RETRO MARKET (izithrift)

- **Document ID:** `DOC-PA01-CHARTER`
- **Version:** `1.1.0 (FINAL APPROVED)`
- **Status:** `DONE`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 01 – Project Discovery & Requirement Analysis`

---

## 1. Tên Dự Án (Project Name)
- **Tên hệ thống / Dự án kỹ thuật:** `RETRO MARKET – Mobile Secondhand C2C Marketplace` `[CONFIRMED]`
- **Tên thương hiệu ứng dụng di động:** `izithrift` `[CONFIRMED]`

## 2. Bối Cảnh Dự Án (Project Background)
Thị trường mua bán đồ đã qua sử dụng (đồ si, đồ secondhand, đồ cổ điển/vintage) có nhu cầu giao dịch cá nhân với cá nhân (C2C) rất lớn. Tuy nhiên, người mua và người bán đồ si thường gặp rào cản khi giao dịch trên các mạng xã hội tự do (dễ bị lừa đảo chuyển khoản trước, không có cơ chế giữ tiền bảo vệ người mua, thiếu quy trình kiểm duyệt tình trạng sản phẩm trước khi đăng) hoặc trên các sàn thương mại điện tử đại trà (thu phí người bán cao khiến họ nản lòng, thiếu cơ chế đấu giá theo phiên cho các món đồ độc bản và giao diện công nghiệp thiếu tính thẩm mỹ hoài cổ).

Dự án **RETRO MARKET (`izithrift`)** được khởi tạo trong khuôn khổ đồ án môn học **Phát triển ứng dụng thương mại di động** `[CONFIRMED]`. Dự án đóng vai trò là một nền tảng trung gian uy tín giúp cộng đồng tự tin mua bán đồ 2hand không sợ scam thông qua kiểm duyệt sản phẩm, mua bán giá cố định, đấu giá trực tuyến theo phiên, thanh toán QR mô phỏng, giữ tiền trung gian (Escrow Ledger) với mô hình **Phí bảo vệ người mua (Buyer Protection Fee)** và giải quyết tranh chấp.

## 3. Tầm Nhìn Sản Phẩm (Product Vision)
Xây dựng một ứng dụng mua sắm C2C trên thiết bị di động kết hợp trang quản trị Web, nơi mọi người dùng đều có thể vừa mua vừa bán những món đồ secondhand/vintage trong một không gian số mang đậm phong cách **Vintage Editorial kết hợp không khí Giáng sinh ấm cúng (Cozy Christmas)**, được bảo chứng bởi quy trình kiểm duyệt trước khi hiển thị và cơ chế giữ tiền trung gian bảo vệ 100% quyền lợi người mua mà không thu phí hoa hồng từ người bán `[CONFIRMED]`.

## 4. Tuyên Bố Vấn Đề (Problem Statement)
Giao dịch đồ secondhand giữa các cá nhân thường đối mặt với 4 vấn đề cốt lõi:
1. **Rủi ro chất lượng và thông tin mập mờ (`PROB-01`):** Sản phẩm đồ si có tính chất "mỗi món một tình trạng" (độ mới, vết xước, lỗi nhỏ, tính xác thực). Nếu không có bước kiểm duyệt bắt buộc và khai báo lỗi (defect) rõ ràng trước khi lên sàn, người mua rất dễ nhận hàng bị rách hoặc không đúng mô tả.
2. **Rủi ro lừa đảo (Scam) & Rào cản phí cho người bán (`PROB-02`):** Người mua chuyển khoản trực tiếp trên mạng xã hội rất dễ bị lừa không gửi hàng. Ngược lại, nếu sàn thu phí hoa hồng của người bán thì người bán sẽ bỏ sang Facebook/Chợ Tốt đăng miễn phí. Cần một mô hình giữ tiền trung gian (Escrow) thu **Phí bảo vệ người mua (Buyer Protection Fee)** hợp lý để người bán nhận về 100% tiền hàng còn người mua được bảo hiểm hoàn tiền 100% nếu có sự cố.
3. **Thiếu cơ chế định giá linh hoạt cho hàng độc bản (`PROB-03`):** Nhiều món đồ cổ điển/hiếm không có mức giá thị trường cố định; người bán cần cơ chế đấu giá theo phiên có kiểm soát thời gian, bước giá và chống trả giá phút chót (anti-sniping).
4. **Trải nghiệm thị giác đại trà (`PROB-04`):** Các sàn TMĐT phổ thông có bố cục dày đặc, không phản ánh được tinh thần hoài niệm, ấm cúng của văn hóa săn đồ si (thrift shopping).

## 5. Định Vị Sản Phẩm (Product Positioning)
- **Phân khúc:** Sàn giao dịch thương mại điện tử C2C ngách (Niche C2C Mobile Marketplace) chuyên biệt cho đồ secondhand, retro và vintage `[CONFIRMED]`.
- **Mô hình doanh thu & Bảo vệ giao dịch:** Miễn phí 100% cho người bán (Seller nhận đủ 100% giá trị món hàng). Thu **Phí bảo vệ người mua (Buyer Protection Fee)** trực tiếp từ người mua (cấu hình mặc định trong khoảng `5% – 8%` giá trị sản phẩm + `5.000đ – 10.000đ` phí cố định) để vận hành cơ chế giữ tiền trung gian Escrow và bảo hiểm hoàn tiền khi hàng lỗi/sai mô tả/không giao hàng `[CONFIRMED]`. Không thu phí vận chuyển trên nền tảng `[CONFIRMED]`.
- **Sự khác biệt cốt lõi:**
  - Khác với các sàn TMĐT đại trà: `izithrift` tích hợp **Hệ thống Đấu giá theo Phiên định kỳ (Scheduled Auction Hub)**, **Quy trình Kiểm duyệt Sản phẩm bắt buộc trước khi hiển thị (Pre-listing Moderation)**, **Mô hình Buyer Protection Fee** và **Ngôn ngữ thiết kế Vintage Editorial + Cozy Christmas** `[CONFIRMED]`.
  - Khác với các đồ án CRUD cơ bản: Hệ thống thực thi đầy đủ **4 State Machine độc lập** cho Đơn hàng – Thanh toán – Khoản giữ tiền (Escrow) – Khiếu nại, cùng sổ cái tài chính bất biến (Append-only Ledger) và xử lý đồng thời (Concurrency Control) ở tầng Backend `[CONFIRMED]`.

## 6. Mục Tiêu Dự Án (Project Objectives)
- **`OBJ-01` (Hoàn thiện nghiệp vụ C2C hai chiều & Guest Access):** Cho phép khách vãng lai (Guest) khám phá sản phẩm/phiên đấu giá và cho phép một tài khoản đăng ký duy nhất thực hiện trọn vẹn cả vai trò Người mua (Buyer) và Người bán (Seller) `[CONFIRMED]`.
- **`OBJ-02` (Đảm bảo chiều sâu 4 trụ cột nghiệp vụ):** Xây dựng hoạt động thực tế ở tầng Backend và Database cho 4 nghiệp vụ trọng tâm: (1) Kiểm duyệt sản phẩm, (2) Đấu giá theo phiên có xử lý đồng thời và anti-sniping, (3) Thanh toán QR mô phỏng kết hợp tính Phí bảo vệ người mua, sổ cái giữ tiền Escrow & tự động hoàn tất đơn, (4) Quản trị toàn diện và xử lý tranh chấp trên Admin Dashboard `[CONFIRMED]`.
- **`OBJ-03` (Chất lượng kỹ thuật & Kiến trúc):** Triển khai kiến trúc Modular Monolith với Backend Laravel 13 (RESTful API + Blade Admin), Database PostgreSQL 18 và Mobile App Flutter theo mẫu MVVM + Repository Pattern, vận hành hoàn toàn trên môi trường Local/Docker `[CONFIRMED]`.
- **`OBJ-04` (Khả năng kiểm thử & Trình diễn đồ án):** Cung cấp chế độ **Demo Mode** (cho phép cấu hình rút ngắn thời gian chờ và kích hoạt Scheduled Jobs thủ công qua Developer Tools) để chứng minh trực tiếp các luồng nghiệp vụ phụ thuộc thời gian trước hội đồng chấm đồ án `[CONFIRMED]`.

## 7. Đối Tượng Người Dùng Mục Tiêu (Target Users)
1. **Khách vãng lai (Guest):** Người dùng mở ứng dụng để xem trang chủ, tìm kiếm, xem chi tiết sản phẩm và theo dõi danh sách phiên đấu giá trước khi quyết định đăng nhập `[CONFIRMED]`.
2. **Người dùng phổ thông (Regular Users – Buyer & Seller):** Những người yêu thích đồ secondhand/vintage muốn tìm mua sản phẩm an toàn (được bảo vệ bởi Escrow), tham gia đấu giá hoặc đăng bán lại các món đồ cá nhân và nhận về 100% giá trị bán `[CONFIRMED]`.
3. **Đội ngũ vận hành nội bộ (Internal Operations):** Bao gồm Quản trị viên hệ thống (Administrator), Kiểm duyệt viên nội dung/sản phẩm (Moderator) và Nhân viên hỗ trợ giải quyết khiếu nại (Support Staff) thao tác trên Web Admin Dashboard `[CONFIRMED]`.

## 8. Các Bên Liên Quan (Stakeholders)
| Mã | Bên liên quan | Vai trò trong dự án | Mối quan tâm chính |
| :--- | :--- | :--- | :--- |
| `STK-01` | Product Owner / Sinh viên thực hiện | Chủ sở hữu sản phẩm, thiết kế hệ thống & lập trình viên chính | Hoàn thành đúng tiến độ, đạt điểm tối đa về độ sâu nghiệp vụ, kiến trúc sạch và demo mượt mà. |
| `STK-02` | Giảng viên hướng dẫn & Hội đồng chấm thi | Đánh giá học thuật & nghiệm thu kỹ thuật | Tính toàn vẹn dữ liệu, xử lý giao dịch/đấu giá thực chất (không làm nút giả), phân quyền bảo mật và UX hoàn chỉnh. |
| `STK-03` | AI Collaborators (Gemini & Antigravity) | Phân tích nghiệp vụ, thiết kế hệ thống & hỗ trợ triển khai code theo task | Tuân thủ đúng tài liệu đặc tả, không tự ý mở rộng phạm vi hoặc phá vỡ kiến trúc đã chốt. |

## 9. Giá Trị Cốt Lõi Mang Lại (Core Value Propositions)
- **Minh bạch tình trạng sản phẩm (`VAL-01`):** Mọi sản phẩm phải khai báo tình trạng (condition), thông tin lỗi (defect), bằng chứng kiểm chứng (authenticity evidence) và vượt qua bước kiểm duyệt của Moderator trước khi tiếp cận người mua `[CONFIRMED]`.
- **Bảo vệ người mua tuyệt đối & Miễn phí người bán (`VAL-02`):** Người bán được đăng bài miễn phí và nhận đủ 100% tiền hàng (`item_subtotal`). Người mua trả thêm một khoản **Phí bảo vệ người mua (Buyer Protection Fee)** để tiền được giữ trong `ESCROW_HELD` và được đảm bảo hoàn tiền nếu hàng rách, sai mô tả hoặc người bán không gửi hàng `[CONFIRMED]`.
- **Trải nghiệm săn đồ & Đấu giá kịch tính (`VAL-03`):** Cung cấp các phiên đấu giá hàng ngày với bộ đếm ngược, lịch sử trả giá minh bạch, cơ chế gia hạn 2 phút cuối (anti-sniping) và quyền chốt sớm có điều kiện `[CONFIRMED]`.
- **Không gian thẩm mỹ cảm xúc (`VAL-04`):** Phong cách thiết kế ấm áp như một tiệm đồ cổ đêm Giáng sinh với bảng màu Warm Cream `#F4EBDD`, Forest Green `#294638`, Burgundy `#873A43`, Muted Gold `#C5A66B` và bộ font chữ có cơ chế fallback tiếng Việt chuẩn xác `[CONFIRMED]`.

## 10. Năng Lực Sản Phẩm Cấp Cao (High-Level Product Capabilities)
1. **Quản lý định danh & Hồ sơ đa vai trò:** Cho phép Guest duyệt nội dung công khai; Đăng ký, đăng nhập (Sanctum token), quản lý hồ sơ cá nhân, hồ sơ người bán, sổ địa chỉ nhận hàng `[CONFIRMED]`.
2. **Khám phá & Tìm kiếm chuyên sâu:** Trang chủ theo chủ đề Giáng sinh, tìm kiếm theo từ khóa/thương hiệu/danh mục, lọc theo tình trạng/khoảng giá/loại hình bán và sắp xếp linh hoạt `[CONFIRMED]`.
3. **Kênh Người bán (Seller Center) & Kiểm duyệt (Moderation):** Tạo sản phẩm bán giá cố định hoặc đấu giá, lưu nháp, gửi duyệt, chỉnh sửa khi bị từ chối (`REJECTED` kèm lý do chi tiết), theo dõi doanh thu và sổ cái ví `[CONFIRMED]`.
4. **Hệ thống Đấu giá theo Phiên (Auction Hub):** Quản lý khung giờ phiên, đặt giá thầu (bidding) an toàn đồng thời, gia hạn chống sniping, chốt phiên sớm, tự động tạo đơn hàng cho người thắng và cho phép người bán đăng lại nếu người thắng không thanh toán đúng hạn `[CONFIRMED]`.
5. **Giỏ hàng, Đơn hàng & Vận chuyển thủ công:** Giỏ hàng tách đơn theo từng người bán, tính toán minh bạch Giá sản phẩm + Phí bảo vệ người mua (không thu phí vận chuyển trên app), lưu snapshot thông tin sản phẩm lúc đặt, cập nhật mã vận đơn thủ công và theo dõi tiến trình giao nhận `[CONFIRMED]`.
6. **Thanh toán QR Giả lập & Sổ cái Escrow:** Sinh mã QR nội bộ chứa mã tham chiếu thanh toán, giả lập kết quả thanh toán, quản lý bút toán giữ tiền/giải ngân/hoàn tiền bất biến và tự động hoàn tất đơn sau 24 giờ kể từ lúc giao hàng `[CONFIRMED]`.
7. **Tương tác, Uy tín & Giải quyết tranh chấp:** Chat 1-1 người mua – người bán, đánh giá 1–5 sao sau khi hoàn tất đơn, gửi khiếu nại kèm bằng chứng ngay từ trạng thái `SHIPPED` hoặc `DELIVERED` (khóa tự động giải ngân) và phân xử bởi Admin `[CONFIRMED]`.
8. **Quản trị Hệ thống Toàn diện (Admin Dashboard):** 14 module quản trị trên giao diện Laravel Blade kèm bộ công cụ Developer Tools phục vụ chạy Demo Mode và truy vết Audit Logs `[CONFIRMED]`.

## 11. Ràng Buộc Dự Án (Project Constraints)
- **`CON-01` (Ràng buộc Hạ tầng & Chi phí):** Toàn bộ hệ thống (Backend, Database, File Storage) bắt buộc chạy self-hosted trên môi trường Local / Docker Compose; không sử dụng dịch vụ đám mây trả phí `[CONFIRMED]`.
- **`CON-02` (Ràng buộc Pháp lý & Tài chính):** Đây là đồ án đại học; tuyệt đối không kết nối tài khoản ngân hàng thực, không lưu ký tiền thật và không cam kết bảo đảm hàng chính hãng 100% chỉ qua hình ảnh `[CONFIRMED]`.
- **`CON-03` (Ràng buộc Công nghệ Cố định):** Bắt buộc sử dụng Flutter (MVVM + Provider + go_router + Dio), Laravel 13 (PHP 8.3+), PostgreSQL 18 và Laravel Blade cho Admin `[CONFIRMED]`.
- **`CON-04` (Ràng buộc Quy trình Phát triển):** Phát triển tuần tự (Sequential Development) kết hợp lát cắt dọc (Vertical Slice) theo từng gói công việc được kiểm soát `[CONFIRMED]`.

## 12. Tiêu Chí Thành Công (Success Criteria)
1. Thực thi trơn tru 3 kịch bản tích hợp đầu-cuối (End-to-End Scenarios): **(A) Mua bán giá cố định, thu Phí bảo vệ người mua & giải ngân 100% tiền hàng cho người bán**, **(B) Đấu giá cạnh tranh, vượt giá & tạo đơn tự động**, và **(C) Khiếu nại (ở trạng thái `SHIPPED` hoặc `DELIVERED`) khóa giải ngân & hoàn tiền bởi Admin** `[CONFIRMED]`.
2. Đảm bảo tính đúng đắn dữ liệu dưới các trường hợp biên: 2 người trả giá đồng thời, bấm thanh toán 2 lần, Scheduled Job chạy lặp nhiều lần (idempotent) không sinh giao dịch trùng `[CONFIRMED]`.
3. Hiển thị chuẩn xác giao diện chủ đề Vintage Editorial + Cozy Christmas trên ứng dụng di động `izithrift`, không lỗi vỡ glyph tiếng Việt và có đầy đủ trạng thái Loading, Empty, Error, Success `[CONFIRMED]`.
4. Có thể khởi chạy độc lập trên máy chấm thi thông qua tài liệu hướng dẫn cài đặt và bộ dữ liệu mẫu (Laravel Seeders) phong phú `[CONFIRMED]`.

## 13. Rủi Ro Chính Của Dự Án & Biện Pháp Giảm Thiểu (Major Project Risks)
| Mã rủi ro | Mô tả rủi ro | Mức độ | Biện pháp giảm thiểu (Mitigation) |
| :--- | :--- | :--- | :--- |
| `RSK-01` | **Xung đột dữ liệu đồng thời (Race Condition)** khi nhiều người cùng đặt mua sản phẩm số lượng 1 hoặc cùng trả giá đấu giá ở giây cuối. | Cao | Bắt buộc sử dụng Database Transaction kết hợp Row-Level Locking (`SELECT ... FOR UPDATE`) tại tầng Laravel Service cho mọi thao tác đặt giá, trừ tồn kho và giải ngân `[CONFIRMED]`. |
| `RSK-02` | **Sai lệch trạng thái đơn hàng & bút toán Phí bảo vệ người mua** nếu gộp chung trạng thái hoặc tính sai số tiền giải ngân/hoàn trả. | Cao | Tách biệt 4 State Machine độc lập (`order`, `payment`, `escrow`, `dispute`); lưu tách biệt `item_subtotal`, `buyer_protection_fee`, `total_amount` trong đơn hàng và thiết kế sổ cái Append-only `[CONFIRMED]`. |
| `RSK-03` | **Không thể trình diễn các tính năng phụ thuộc thời gian** (đợi 24 giờ tự động hoàn tất đơn, đợi 30 phút hủy đơn đấu giá) trong buổi bảo vệ đồ án ngắn. | Cao | Xây dựng chế độ **Demo Mode** với thời gian cấu hình rút ngắn và trang **Developer Tools (Manual Job Trigger)** trên Admin gọi trực tiếp vào logic Scheduled Job `[CONFIRMED]`. |
| `RSK-04` | **Lỗi hiển thị ký tự tiếng Việt (Ransom Note effect)** khi sử dụng font trang trí `Wichita Vintage`. | Trung bình | Kiểm tra bộ glyph tiếng Việt NFC/NFD ở Phase 03; chỉ dùng `Wichita Vintage` cho logo/nhãn đã kiểm chứng, dùng `Fraunces` cho tiêu đề tiếng Việt động và `Be Vietnam Pro` cho nội dung `[CONFIRMED]`. |
| `RSK-05` | **Quá tải phạm vi (Scope Creep)** khiến các tính năng cốt lõi chưa hoàn chỉnh đã sa đà vào tính năng phụ. | Trung bình | Khóa chặt ranh giới MVP (Ưu tiên Moderation, Order/Escrow, Auction, Admin) trước khi làm nhóm Nâng cấp (Chat polling, Follow, Wishlist, Notification) `[CONFIRMED]`. |