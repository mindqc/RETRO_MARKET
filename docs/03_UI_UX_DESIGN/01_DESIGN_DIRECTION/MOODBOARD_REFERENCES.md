# 03. MOODBOARD & BENCHMARK REFERENCES – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P301-MOODBOARD-REF`
- **Version:** `1.1.0`
- **Status:** `DONE`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – UI/UX Design System & High-Fidelity Specification`

---

## Chương 1. Nguyên Tắc Phân Tích Sản Phẩm Tham Khảo (`Benchmarking Methodology`)

Để xây dựng giao diện cho **Retro Market (`izithrift`)**, chúng ta không sao chép rập khuôn bất kỳ ứng dụng nào, mà phân tích học hỏi cách giải quyết bài toán UX/UI từ **6 sản phẩm & trường phái thiết kế hàng đầu** thuộc 5 nhóm danh mục bắt buộc:
1. **Secondhand & Vintage Fashion Marketplace:** *Depop*, *Vestiaire Collective*.
2. **C2C Community Marketplace with Buyer Protection:** *Vinted*, *Mercari*.
3. **Modern High-Trust E-Commerce & Live Bidding:** *Grailed*, *StockX / eBay Live Auctions*.
4. **Editorial / Vintage-Inspired Digital Design:** *Kinfolk Digital / Monocle Shop*.
5. **Contemporary High-Craft Mobile & Admin UI:** *Shopify Polaris / Linear (cho cấu trúc Admin Dashboard)*.

---

## Chương 2. Phân Tích Chi Tiết Từng Sản Phẩm Tham Khảo (`Detailed Benchmark Analysis`)

### 2.1. Nhóm 1 – C2C Secondhand Marketplace & Buyer Protection: **VINTED**
- **Khía cạnh giao diện nên học hỏi (`What to Learn`):**
  1. **Cách minh bạch hóa "Phí Bảo Vệ Người Mua" (`Buyer Protection Fee UI`):** Vinted hiển thị biểu tượng chiếc khiên bảo vệ nhỏ ngay cạnh tổng giá và trình bày cực kỳ rõ ràng bảng tách phí ở bước Checkout (Tiền hàng trả cho người bán vs Phí bảo vệ người mua giữ trong Escrow), kèm cam kết hoàn tiền 100% nếu hàng hư hỏng hoặc không giao.
  2. **Trải nghiệm 1 Tài khoản vừa Mua vừa Bán (`Unified C2C Flow`):** Form đăng bán sản phẩm (`M-SL-03`) được chia thành từng khối rõ ràng (Tải ảnh $\rightarrow$ Mô tả & Tình trạng $\rightarrow$ Chọn giá), giúp người dùng phổ thông đăng bán món đồ cũ trong chưa đầy 2 phút.
  3. **Gắn thẻ sản phẩm ngữ cảnh ở đầu phòng Chat (`M-CM-02`):** Ghim cố định ảnh nhỏ, tên và giá sản phẩm ngay trên đỉnh màn hình chat 1-1 để hai bên không bị nhầm đang hỏi mua món đồ nào.
- **Tại sao phù hợp với Retro Market:** Khớp 100% với quyết định nghiệp vụ `DEC-04` (Miễn phí hoa hồng cho Seller, thu `Buyer Protection Fee` từ Buyer) và `DEC-07` (Hoàn trả 100% `total_amount` khi hủy đơn hoặc thắng khiếu nại).
- **Những yếu tố KHÔNG nên sao chép (`What to Avoid`):**
  - Giao diện của Vinted sử dụng tông màu trắng – xanh ngọc lạnh (`Clinical White & Teal`), mang cảm giác hơi đại trà như một ứng dụng rao vặt thông thường, thiếu hẳn chất ấm cúng (`Cozy`) và cá tính hoài cổ (`Vintage Editorial`) mà `izithrift` hướng tới.

---

### 2.2. Nhóm 2 – Curated Secondhand & Authenticity Trust: **VESTIAIRE COLLECTIVE & GRAILED**
- **Khía cạnh giao diện nên học hỏi (`What to Learn`):**
  1. **Ngôn ngữ biên tập thời trang (`Editorial Typography & Layout`):** Sử dụng font chữ Serif thanh lịch cho tiêu đề bộ sưu tập kết hợp Sans-serif gọn gàng cho thông tin kỹ thuật, biến những món đồ đã qua sử dụng trở nên cao cấp và đáng mơ ước.
  2. **Cách trình bày "Hồ sơ Tình trạng & Vết xước" (`Condition & Defect Disclosure Card`):** Thay vì giấu mô tả lỗi vào đoạn văn dài, Vestiaire tách riêng một khối **"Condition Report"** rõ ràng kèm ảnh chụp cận cảnh vết xước và nhãn xác minh của đội ngũ kiểm duyệt (`MODERATOR_REVIEWED`).
- **Tại sao phù hợp với Retro Market:** Giải quyết trực tiếp quy tắc `BR-PR-03` (bắt buộc khai báo `condition` và `defect_info`, gắn `verification_level` sau khi Moderator duyệt ở `AFW-03`).
- **Những yếu tố KHÔNG nên sao chép (`What to Avoid`):**
  - Không sao chép tông màu đen – trắng lạnh lùng và xa cách của phân khúc xa xỉ phẩm (Luxury High-Fashion), vì `izithrift` cần giữ sự gần gũi, ấm áp và thân thiện với sinh viên cũng như cộng đồng yêu đồ si.

---

### 2.3. Nhóm 3 – Modern E-Commerce & Time-Bounded Bidding: **MERCARI & EBAY MODERN AUCTIONS**
- **Khía cạnh giao diện nên học hỏi (`What to Learn`):**
  1. **Hệ thống Huy hiệu Trạng thái Đấu giá (`Live Bidding Status Pills`):** Phân biệt tức thì bằng màu sắc ngữ nghĩa giữa trạng thái **`ĐANG DẪN ĐẦU (LEADING)`** (Xanh lá trầm) và **`BỊ VƯỢT GIÁ (OUTBID)`** (Đỏ cảnh báo), kết hợp các nút cộng bước giá nhanh (`+50k`, `+100k`) trong Bottom Sheet (`M-AC-04`) giúp người mua đặt giá chỉ bằng 1 chạm khi phiên chỉ còn vài chục giây.
  2. **Timeline Tiến trình Đơn hàng & Đếm ngược Tự hoàn tất (`Order Lifecycle Timeline`):** Hiển thị thanh tiến trình dọc rõ ràng từ lúc `PAID (ESCROW HELD)` $\rightarrow$ `PREPARING` $\rightarrow$ `SHIPPED (kèm mã vận đơn)` $\rightarrow$ `DELIVERED (kèm mốc đếm ngược 24h tự động giải ngân)`.
- **Tại sao phù hợp với Retro Market:** Phục vụ trực tiếp cho cụm màn hình Đấu giá (`M-AC-01..05` – `AF-03`, `AF-04`) và Chi tiết đơn hàng 4 trạng thái (`M-OR-03`, `M-SL-06` – `OF-05..07`).
- **Những yếu tố KHÔNG nên sao chép (`What to Avoid`):**
  - Không sao chép trang chi tiết sản phẩm nhồi nhét hàng chục banner quảng cáo chéo, pop-up vòng quay may mắn hay thông báo nhấp nháy liên tục gây nhiễu loạn thị giác.

---

### 2.4. Nhóm 4 – Editorial & Warm Nostalgic Digital Design: **KINFOLK / MONOCLE DIGITAL ARCHIVE**
- **Khía cạnh giao diện nên học hỏi (`What to Learn`):**
  1. **Nghệ thuật sử dụng nền kem ấm và đường kẻ mảnh (`Warm Paper Tones & Hairline Rules`):** Thay thế các khối hộp đổ bóng đen nặng nề bằng nền màu kem ngà (`Warm Cream`), thẻ màu be sáng (`Soft Beige`) và các đường kẻ phân cách `1px` tinh tế.
  2. **Cách xử lý khoảng trắng (`Generous Breathing Room`):** Giữ khoảng cách hợp lý giữa các nhóm thông tin để tôn vinh vẻ đẹp nguyên bản của ảnh chụp sản phẩm.
- **Tại sao phù hợp với Retro Market:** Đây chính là linh hồn thẩm mỹ của `Direction A (Warm Editorial Archive)` giúp `izithrift` mang đậm chất **Retro & Cozy** mà không cần dùng đến một tấm ảnh nền giấy rách hay họa tiết rườm rà nào.
- **Những yếu tố KHÔNG nên sao chép (`What to Avoid`):**
  - Không sao chép lối thiết kế tạp chí thuần đọc tin tức (chữ quá nhỏ, nút mua hàng bị giấu kỹ). Trên `izithrift`, các nút hành động thương mại (`Thêm vào giỏ`, `Mua ngay`, `Đặt giá thầu`) luôn phải rõ ràng và nằm trong vùng ngón tay cái dễ chạm nhất (`Thumb Zone`).

---

### 2.5. Nhóm 5 – High-Density Operational Admin Web: **SHOPIFY POLARIS (ADMIN) & STRIPE DASHBOARD**
- **Khía cạnh giao diện nên học hỏi (`What to Learn`):**
  1. **Cấu trúc Bảng dữ liệu & Đối soát Sổ cái Tài chính (`Financial Ledger & Transaction Tables`):** Cách Stripe trình bày các dòng bút toán `HOLD`, `RELEASE`, `REFUND` với độ rõ ràng tuyệt đối, căn lề phải cho cột số tiền (`Tabular Right-Aligned Amounts`) và gắn nhãn trạng thái đa chiều.
  2. **Bố cục Phòng Kiểm duyệt & Phân xử 2 Cột (`Split-Pane Inspection Layout`):** Đặt toàn bộ bằng chứng hình ảnh ở cột trái và thông tin đối chiếu + cụm nút ra quyết định ở cột phải (áp dụng cho `A-MD-02` Kiểm duyệt sản phẩm và `A-DP-02` Phòng xử lý tranh chấp).
- **Tại sao phù hợp với Retro Market:** Giúp 21 màn hình Laravel Blade Admin (`A-AU-01`..`A-DT-01`) đạt chuẩn quản trị chuyên nghiệp, xử lý nhanh hàng chờ kiểm duyệt và phân xử khiếu nại chính xác.
- **Những yếu tố KHÔNG nên sao chép (`What to Avoid`):**
  - Không biến Admin Dashboard thành một sản phẩm tách rời hoàn toàn về mặt nhận diện; cần giữ lại bảng màu thương hiệu (Sidebar xanh rừng thông trầm, huy hiệu trạng thái đồng bộ với Mobile App).

---

## Chương 3. Bảng Tổng Hợp Ngôn Ngữ Moodboard (`Visual Moodboard Synthesis Matrix`)

| Thành Phần Thị Giác | Cảm Hứng Tham Chiếu Chính | Cách Chuyển Hóa Vào `izithrift` |
| :--- | :--- | :--- |
| **Bầu không khí & Bảng màu (`Atmosphere & Palette`)** | Tiệm boutique đồ vintage mùa lễ hội + *Kinfolk* | Nền kem ấm dịu mắt, xanh thông trầm tin cậy, đỏ rượu vang ấm áp, vàng đồng cổ điển. |
| **Thẻ Sản phẩm Giá cố định (`Fixed-Price Card`)** | *Vestiaire Collective* + Mác vải quần áo cổ điển | Khung ảnh sạch sẽ, nhãn tình trạng (`condition`) dạng tag nhỏ góc trên, giá bán rõ nét. |
| **Thẻ & Phòng Đấu giá (`Auction Card & Room`)** | Vé đấu giá cổ điển (`Ticket Stub`) + *Mercari / StockX* | Dải đếm ngược nổi bật, huy hiệu `LEADING`/`OUTBID` tương phản cao, Bottom Sheet đặt giá nhanh. |
| **Hộp Tình trạng, Lỗi & Phí Bảo Vệ (`Trust & Escrow Box`)** | *Vinted Buyer Protection* + Phiếu kiểm định lưu trữ | Khung viền mảnh đặc trưng hiển thị rõ `defect_info`, công thức `Buyer Protection Fee` và cam kết hoàn tiền 100%. |
| **Trang Quản trị & Sổ cái (`Admin & Ledger UI`)** | *Stripe Ledger* + *Shopify Admin Split-View* | Bố cục 2 cột kiểm duyệt nhanh, bảng sổ cái Read-Only căn chỉnh số học chuẩn xác. |