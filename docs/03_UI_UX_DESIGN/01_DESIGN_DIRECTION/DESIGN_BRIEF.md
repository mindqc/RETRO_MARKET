# 01. DESIGN BRIEF – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P301-DESIGN-BRIEF`
- **Version:** `1.1.0`
- **Status:** `DONE`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – UI/UX Design System & High-Fidelity Specification`

---

## Chương 1. Kiểm Chứng Nguồn Dữ Liệu Đầu Vào (`Source of Truth Verification`)

Toàn bộ định hướng thiết kế trong tài liệu này được xây dựng dựa trên 20 tài liệu đã được phê duyệt (`DONE`) từ Phase 01 và Phase 02:
1. **Nhóm Phân tích Yêu cầu (`docs/01_REQUIREMENTS_ANALYSIS/`):** Từ `01_PROJECT_CHARTER.md` đến `10_PHASE_01_SIGN_OFF.md` (51 Functional Requirements, 61 Permissions, 24 Use Cases, 33 Business Rules, 18 Non-Functional Requirements, 7 Business Decisions `DEC-01..07`, 8 Architecture Decisions `ADR-01..08`).
2. **Nhóm Luồng Hệ thống & UX (`docs/02_SYSTEM_FLOWS/`):** `SITEMAP.md` (`NAV-DEC-01..03`), `BUYER_FLOW.md` (`BF-01..12`), `SELLER_FLOW.md` (`SF-01..12`), `AUCTION_FLOW.md` (`AF-01..10`), `ORDER_PAYMENT_FLOW.md` (`OF-01..10`), `ADMIN_FLOW.md` (`AFW-01..10`), `SCREEN_INVENTORY.md` (49 màn hình Mobile `M-*` + 21 màn hình Admin `A-*`), và bộ Wireframes (`MOBILE_WIREFRAMES.md`, `ADMIN_WIREFRAMES.md`).

*(Trạng thái truy cập tài liệu: Đầy đủ 100%, không thiếu file nào).*

---

## Chương 2. Bản Chất Sản Phẩm & Bài Toán Thiết Kế Cốt Lõi (`The Core Design Challenge`)

### 2.1. Định Vị Thương Hiệu `izithrift` (`Confirmed Brand Positioning`)
**Retro Market (`izithrift`)** là nền tảng thương mại điện tử C2C hiện đại chuyên mua bán và đấu giá đồ đã qua sử dụng (secondhand, vintage, retro). Bản chất thiết kế của `izithrift` nằm ở điểm giao thoa giữa hai thái cực:
- **Cảm xúc (`Emotional Layer`):** Hoài cổ, ấm cúng, có gu thẩm mỹ biên tập (`Vintage`, `Retro`, `Nostalgic`, `Cozy`), gợi cảm giác bước vào một tiệm đồ tuyển chọn (curated thrift boutique) chứ không phải một bãi đồ cũ lộn xộn.
- **Công năng (`Functional Layer`):** Tốc độ, minh bạch, sắc nét và đáng tin cậy của một ứng dụng thương mại điện tử hiện đại (`Modern E-Commerce Usability`), nơi người dùng phải ra quyết định tài chính, đặt giá thầu theo giây và kiểm tra từng vết xước trên sản phẩm.

### 2.2. Năm Thách Thức Thực Tế Giao Diện Phải Giải Quyết (`Key UX/UI Challenges`)

| STT | Thách Thức Nghiệp Vụ Đặc Thù Của Retro Market | Yêu Cầu Đặt Ra Cho Thiết Kế UI/UX |
| :-: | :--- | :--- |
| 01 | **Nỗi sợ bị lừa hoặc nhận hàng rách/khác ảnh khi mua đồ cũ (`Trust Deficit in C2C Secondhand`)** | Giao diện không được dùng bộ lọc màu vintage làm biến dạng màu thật của ảnh sản phẩm. Khu vực khai báo tình trạng (`condition`), lỗi/vết xước (`defect_info`), mức độ xác minh (`verification_level`) và huy hiệu giữ tiền **`ESCROW HELD`** phải nổi bật như một "chứng thư bảo đảm" (`BR-PR-03`, `DEC-04`). |
| 02 | **Một tài khoản duy nhất vừa là Buyer vừa là Seller (`Unified Account Context – BR-AC-01`)** | Người dùng chuyển qua lại giữa đi mua hàng (Tab 1, 2, 3, 5) và bán hàng (Tab 4 `Kênh Bán`) mà không đổi tài khoản. Ngôn ngữ thị giác phải tạo sự phân biệt ngữ cảnh tinh tế để người dùng không bao giờ nhầm lẫn giữa *"Đơn tôi đi mua"* (`M-OR-03`) và *"Đơn khách mua của tôi"* (`M-SL-06`) (`NAV-DEC-02`). |
| 03 | **Hai cơ chế mua bán vận hành song song: Giá cố định (`FIXED_PRICE`) vs Đấu giá theo phiên (`AUCTION`)** | Ngay từ lưới sản phẩm (`Product Card`) cho đến trang chi tiết (`M-PR-01` vs `M-AC-03`), người dùng phải phân biệt được ngay trong 1 giây đâu là món đồ mua đứt ngay và đâu là món đồ đang đếm ngược đấu giá (`BR-PR-01`). |
| 04 | **Độ phức tạp của 4 Vòng đời Trạng thái Độc lập & Công thức Phí Bảo Vệ Người Mua (`ADR-03`, `DEC-04..07`)** | Một đơn hàng có đồng thời `order_status`, `payment_status`, `escrow_status` và `dispute_status`. Nếu trình bày không khéo, màn hình chi tiết đơn hàng sẽ biến thành một bảng log kỹ thuật rối rắm. Thiết kế phải gom nhóm 4 trạng thái này thành hệ thống huy hiệu trực quan, đồng thời giải thích rõ vì sao Buyer trả `total_amount` (`item_subtotal + buyer_protection_fee`, `ship = 0đ`) còn Seller nhận đủ `100% item_subtotal`. |
| 05 | **Hiển thị Tiếng Việt có dấu kép & Tương thích Đa nền tảng (`Flutter Mobile + Laravel Blade Admin`)** | Tiếng Việt có hệ thống dấu thanh và dấu mũ phức tạp (`ắ, ặ, ể, ễ, ộ, ợ, ự...`). Nhiều font chữ retro/vintage phương Tây bị lỗi thiếu glyph gây hiện tượng chắp vá chữ cái (`Ransom Note effect`). Ngoài ra, Admin Dashboard trên Web cần mật độ thông tin cao để kiểm duyệt ảnh, đối soát sổ cái Escrow Read-Only và phân xử tranh chấp. |

---

## Chương 3. Ranh Giới Thẩm Mỹ: Những Gì Nên Làm Và Cấm Lạm Dụng (`Aesthetic Guardrails`)

Để đảm bảo giao diện vừa có cá tính **Retro/Cozy** vừa giữ trọn **Modern Usability**, dự án thiết lập ranh giới thẩm mỹ nghiêm ngặt:

| Khía Cạnh | NÊN LÀM (`DOs – Modern Retro Marketplace`) | CẤM LẠM DỤNG (`DON'Ts – Anti-Patterns`) |
| :--- | :--- | :--- |
| **Bề mặt & Nền (`Surfaces`)** | Sử dụng sắc độ màu nền ấm áp (kem ngà, giấy sáng mịn, be nhạt) tạo cảm giác dịu mắt và sang trọng thông qua mã màu thuần (`Solid Warm Tones`). | **Cấm** phủ texture giấy ố vàng, vết rách, vết cà phê loang hoặc họa tiết báo cũ đè lên dưới văn bản và ảnh sản phẩm làm giảm độ tương phản. |
| **Trang trí (`Ornamentation`)** | Sử dụng đường kẻ mảnh (`1px Hairline Divider`), khung viền bo góc vừa phải, tem nhãn trạng thái gọn gàng lấy cảm hứng từ mác quần áo cổ điển (woven garment tags) hoặc vé đấu giá. | **Cấm** dùng hoa văn dây leo rườm rà, khung ảnh kiểu cổ vật thế kỷ 18, con dấu sáp niêm phong hoặc tem thư che khuất thông tin giá bán. |
| **Kiểu chữ (`Typography`)** | Dùng chữ có chân mang hơi hướng biên tập hiện đại (`Editorial Serif`) cho tiêu đề ngắn, kết hợp chữ không chân nhân văn (`Humanist/Geometric Sans-serif`) cực kỳ dễ đọc cho toàn bộ thân bài, số tiền và nút bấm. | **Cấm** dùng font viết tay (script/handwriting), font pixel, hoặc font retro biến dạng mạnh cho mô tả sản phẩm, giá tiền, đồng hồ đếm ngược và bảng số liệu. |
| **Hình ảnh (`Imagery`)** | Giữ nguyên độ trung thực màu sắc (`100% Color Accuracy`) của ảnh chụp món đồ secondhand để người mua đánh giá đúng độ mới và vết xước (`defect_info`). | **Cấm** áp bộ lọc màu Sepia, đen trắng, hạt nhiễu (heavy film grain) hoặc làm mờ viền (vignette) lên ảnh sản phẩm người bán đăng tải. |
| **Chủ đề Mùa vụ (`Seasonal Layer`)** | Tích hợp điểm nhấn mùa lễ hội (như sắc xanh thông trầm, đỏ rượu vang ấm, vàng đồng cổ và banner/icon tinh tế) dưới dạng lớp cấu hình có thể bật/tắt (`enableSeasonalChristmasDecor` – `NFR-UX-02`). | **Cấm** hiệu ứng tuyết rơi bay khắp màn hình che nút đặt giá thầu, hoặc biến toàn bộ ứng dụng thành thiệp Giáng sinh lòe loẹt không dùng được quanh năm. |