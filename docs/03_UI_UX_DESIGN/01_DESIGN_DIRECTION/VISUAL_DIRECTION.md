# 02. VISUAL DIRECTION EXPLORATION & RECOMMENDATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P301-VISUAL-DIRECTION`
- **Version:** `1.1.0`
- **Status:** `DONE`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – UI/UX Design System & High-Fidelity Specification`

---

## Chương 1. Phân Tích 3 Hướng Thiết Kế Thị Giác Độc Lập (`3 Distinct Visual Directions`)

Dưới đây là 3 hướng tiếp cận ngôn ngữ thị giác khác biệt toàn diện về **cấu trúc bố cục (Layout Architecture)**, **mật độ khoảng trắng (Whitespace)**, **hệ thống kiểu chữ (Typography)**, **ngôn ngữ thẻ sản phẩm (Product Card)** và **triết lý Component**:

---

### HƯỚNG 1: `DIRECTION A – "WARM EDITORIAL ARCHIVE"` (Biên Tập Tạp Chí Ấm Áp & Tiệm Đồ Tuyển Chọn)

1. **Tên hướng thiết kế:** **Warm Editorial Archive** *(Tạp chí Biên tập Ấm áp & Lưu trữ Tuyển chọn)*.
2. **Ý tưởng chủ đạo (`Core Concept`):** Lấy cảm hứng từ các tạp chí thời trang & phong cách sống thập niên 1970–1990 (như *Kinfolk*, *Brutus*, *Fudge*) kết hợp với không gian một tiệm boutique đồ secondhand ấm cúng vào mùa lễ hội cuối năm. Giao diện đối xử với mỗi món đồ cũ như một "tác phẩm có câu chuyện", nhưng được đặt trong một lưới thương mại điện tử hiện đại, gọn gàng và chuẩn xác.
3. **Cảm xúc & Trải nghiệm thương hiệu (`Brand Mood`):** Ấm áp (`Cozy`), đáng tin cậy (`Trustworthy`), tinh tế (`Curated`), hoài cổ vừa đủ (`Nostalgic Touch`) mà vẫn thanh lịch, dễ chịu khi lướt hàng giờ liền.
4. **Đặc trưng thị giác (`Visual Characteristics`):**
   - Sự kết hợp giữa **khoảng trắng ấm (Warm Whitespace)** và các **đường kẻ phân tách mảnh sắc nét (`1px Warm Hairline Borders`)** gợi nhớ bố cục tạp chí in ấn cao cấp nhưng được tối ưu cho màn hình cảm ứng.
   - Các góc bo mềm mại vừa phải (`8px – 12px` cho thẻ và nút, `16px` cho Bottom Sheet), không quá nhọn gây cảm giác cứng nhắc và không quá tròn trịa kiểu hoạt hình.
   - Đổ bóng cực nhẹ và ấm (`Soft Diffused Warm Shadows`), ưu tiên phân tách lớp bằng sắc độ nền (`Surface Elevation by Tone`) kết hợp viền mảnh.
5. **Định hướng màu sắc (`Color Mood`):**
   - **Nền chủ đạo:** Tông kem giấy ấm áp và màu be cát nhạt tạo cảm giác êm dịu cho mắt, tránh hoàn toàn màu trắng xanh chói gắt của màn hình kỹ thuật số.
   - **Điểm nhấn thương hiệu & Hành động:** Xanh rừng thông trầm (`Deep Forest Pine`) mang lại cảm giác an tâm, vững chãi (rất hợp với cơ chế bảo vệ Escrow) và Đỏ rượu vang ấm (`Warm Burgundy / Berry`) dùng cho các điểm nhấn cảm xúc, đấu giá khẩn cấp và mùa lễ hội.
   - **Điểm nhấn phụ:** Vàng đồng cổ điển (`Antique Brass / Gold`) dành riêng cho huy hiệu uy tín, người dẫn đầu đấu giá và xác minh chất lượng.
   - **Văn bản:** Xám than củi đậm (`Deep Warm Charcoal`) thay vì đen tuyền tuyệt đối, tạo cảm giác chữ in trên giấy mịn.
6. **Định hướng kiểu chữ (`Typography Direction`):**
   - **Tiêu đề (`Headings`):** Kiểu chữ Serif biên tập có độ tương phản nét thanh nét đậm vừa phải, nét cong mềm mại mang hơi thở hoài cổ (Soft Contemporary Editorial Serif), hỗ trợ đầy đủ 100% dấu tiếng Việt.
   - **Thân bài, Giá tiền & Điều khiển (`Body & UI Controls`):** Kiểu chữ Sans-serif hiện đại, lòng chữ rộng, chiều cao chữ thường (`x-height`) lớn, hỗ trợ kiểu số đồng đều (`Tabular Numerals`) để hiển thị giá tiền `VND` và đồng hồ đếm ngược không bị nhảy chữ.
7. **Định hướng hình ảnh (`Image & Photography Direction`):**
   - Ảnh sản phẩm giữ nguyên màu gốc 100%, đặt trong khung tỷ lệ chuẩn (`4:5` cho thời trang/đồ đứng hoặc `1:1` cho lưới đồng nhất) với viền mảnh tinh tế.
   - Banner bộ sưu tập sử dụng ánh sáng vàng ấm tự nhiên, bố cục chụp phẳng (`Flat-lay`) hoặc chụp chi tiết chất liệu (vải len, da thuộc, kim loại đồng hồ).
8. **Thiết kế Thẻ sản phẩm (`Product Card Direction`):**
   - **Cấu trúc:** Khung thẻ màu kem sáng nổi trên nền kem ấm, có viền mảnh `1px`. Phần ảnh chiếm 70% chiều cao thẻ, góc trên bên trái ảnh gắn **Nhãn Loại hình & Tình trạng** thiết kế như một chiếc mác vải nhỏ (`Garment Tag Badge`).
   - **Phân biệt Fixed Price vs Auction:**
     - Thẻ `Fixed Price`: Hiển thị Giá cố định đậm nét + Tình trạng (`Good` / `Like New`) + Tên tiệm & sao.
     - Thẻ `Auction`: Có một dải băng mỏng màu đỏ rượu vang hoặc xanh đậm ngay chân ảnh hiển thị **Đồng hồ đếm ngược trực tiếp (`⏳ 04:12`) + Số lượt trả giá (`🔥 8 bids`)**, bên dưới là *Giá cao nhất hiện tại*.
9. **Định hướng Điều hướng (`Navigation Direction`):**
   - **Bottom Navigation 5 Tab** có nền kem ấm đặc, phân tách với nội dung bằng đường kẻ mảnh phía trên; tab đang chọn được tô điểm bằng viên thuốc nhỏ (pill indicator) màu xanh trầm hoặc đỏ ấm.
   - **Top Utility Bar** gọn gàng với thanh tìm kiếm bo góc nhẹ như một ô mục lục và 3 icon tiện ích (`Giỏ hàng`, `Chat`, `Thông báo`) có badge đếm rõ ràng.
10. **Định hướng Biểu tượng (`Iconography Direction`):**
    - Icon nét mảnh vừa phải (`1.75px – 2px stroke`), đầu nét bo tròn nhẹ (`Rounded Caps & Joins`), mang cảm giác thân thiện, thủ công tinh tế. Khi được chọn (`Active State`), icon chuyển sang dạng tô đặc (`Duotone / Filled`) ấm áp.
11. **Định hướng Component (`Component Styling Direction`):**
    - **Nút bấm (`Buttons`):** Nút chính đặc màu xanh rừng thông hoặc đỏ rượu vang với chữ sáng rõ; nút phụ có nền be nhạt kèm viền mảnh.
    - **Hộp thông tin Tình trạng & Phí bảo vệ (`Defect & Escrow Info Boxes`):** Thiết kế giống như một **"Phiếu kiểm định chất lượng" (`Inspection Slip Card`)** với viền nét đứt hoặc viền kép mảnh ở góc, giúp làm nổi bật thông tin `defect_info` và bảng tính `Buyer Protection Fee` một cách tự nhiên, đúng chất đồ secondhand.
12. **Cách áp dụng vào Mobile App (`izithrift`):**
    - Phát huy tối đa cảm xúc ấm cúng trên `M-HM-01` (Trang chủ), `M-PR-01` (Chi tiết sản phẩm) và `M-AC-03` (Phòng đấu giá). Bố cục 2 cột thoáng đãng giúp ảnh đồ cũ không bị cảm giác chật chội, rẻ tiền.
13. **Cách áp dụng vào Admin Dashboard (`Laravel Blade`):**
    - Giảm tỷ lệ màu kem đậm xuống thành nền trắng ngà sáng (`Light Warm Ivory`) cho vùng bảng dữ liệu để mắt quản trị viên không bị mỏi khi đọc hàng trăm dòng đơn hàng và sổ cái Escrow; giữ màu xanh rừng thông trầm cho Left Sidebar để đồng bộ nhận diện thương hiệu với Mobile App.
14. **Ưu điểm (`Pros`):**
    - Cân bằng hoàn hảo giữa chất **Vintage/Cozy** và tính **Thương mại điện tử hiện đại**.
    - Tạo dựng **niềm tin rất cao (`High Trust`)**: món đồ cũ đặt trong khung biên tập sạch sẽ nhìn có giá trị hơn hẳn.
    - Dễ dàng bật/tắt lớp trang trí mùa lễ hội Giáng sinh (`enableSeasonalChristmasDecor`) mà không làm hỏng cấu trúc gốc.
15. **Hạn chế & Rủi ro UX (`Cons & UX Risks`):**
    - Nếu chọn độ tương phản giữa nền kem và thẻ sản phẩm quá gần nhau, giao diện trên các màn hình điện thoại giá rẻ có thể bị nhạt nhòa (cần kiểm soát chặt độ lệch sáng tối giữa `Background` và `Card Surface`).
16. **Mức độ phù hợp với Retro Market:** **Rất cao (9.5 / 10)**.

---

### HƯỚNG 2: `DIRECTION B – "BOLD RETRO POP & TICKET STUB"` (Cửa Hiệu Retro Sôi Động Thập Niên 70–80 & Vé Đấu Giá)

1. **Tên hướng thiết kế:** **Bold Retro Pop & Ticket Stub** *(Phong cách Neo-Brutalist Retro & Cuống vé Đấu giá)*.
2. **Ý tưởng chủ đạo (`Core Concept`):** Lấy cảm hứng từ poster quảng cáo thập niên 1970–1980, văn hóa chợ phiên cuối tuần (flea market), nhãn dán (stickers) và những chiếc vé vào cửa có răng cưa. Giao diện sử dụng đường viền đậm (`Thick Dark Outlines`), đổ bóng khối cứng (`Hard Offset Shadows`) và các khối màu tương phản mạnh.
3. **Cảm xúc & Trải nghiệm thương hiệu (`Brand Mood`):** Năng động (`Energetic`), cá tính mạnh (`Playful & Edgy`), trẻ trung (Gen-Z streetwear thrift), kích thích cảm giác săn lùng đồ độc lạ.
4. **Đặc trưng thị giác (`Visual Characteristics`):**
   - Mọi thẻ sản phẩm, nút bấm và ô nhập liệu đều có **viền đen/nâu đậm dày `2px`** kèm **bóng cứng lệch góc `3px–4px` (`Hard Drop Shadow`)** không làm mờ (Neo-brutalist retro style).
   - Sử dụng hình dạng cuống vé có khuyết bán nguyệt hai bên (`Perforated Ticket Shape`) cho các thẻ phiên đấu giá và biên lai thanh toán.
5. **Định hướng màu sắc (`Color Mood`):**
   - Bảng màu rực rỡ, độ bão hòa cao hơn: Cam cháy (`Burnt Orange`), Vàng mù tạt (`Mustard Yellow`), Xanh cổ vịt (`Retro Teal`), Đỏ gạch và Kem đậm, kết hợp viền đen than sắc cạnh.
6. **Định hướng kiểu chữ (`Typography Direction`):**
   - Tiêu đề sử dụng kiểu chữ Sans-serif nét dày, bo tròn hoặc chữ Display đậm chất poster thập niên 70 (`Chunky Retro Display`).
   - Giá tiền và nhãn trạng thái dùng kiểu chữ Monospace (chữ máy đánh chữ / hóa đơn in nhiệt).
7. **Định hướng hình ảnh (`Image & Photography Direction`):**
   - Ảnh sản phẩm đóng trong khung viền đen dày như những tấm ảnh Polaroid hoặc thẻ bài sưu tầm (trading cards), các nhãn giảm giá/đấu giá dán đè lên góc ảnh dạng sticker nghiêng nhẹ.
8. **Thiết kế Thẻ sản phẩm (`Product Card Direction`):**
   - Thẻ dạng hộp viền đậm `2px`. Với hàng đấu giá, thẻ được cắt khuyết hai bên hông giống tấm vé đấu giá, phần chân vé tách rời bằng đường kẻ nét đứt đậm chứa nút `[Đặt giá]`.
9. **Định hướng Điều hướng (`Navigation Direction`):**
   - Thanh Bottom Navigation dạng hộp nổi (`Floating Boxed Bar`) cách đáy màn hình `12px`, có viền đậm `2px` và bóng cứng; các nút tab khi bấm vào có hiệu ứng lún xuống (`Push-down Button Effect`).
10. **Định hướng Biểu tượng (`Iconography Direction`):**
    - Icon nét dày (`2.25px – 2.5px`), hình khối kỷ hà rõ rệt, kết hợp các huy hiệu hình ngôi sao nhiều cánh (starburst badges).
11. **Định hướng Component (`Component Styling Direction`):**
    - Nút bấm, hộp thoại và bộ lọc đều mang phong cách hộp cứng có viền đậm; các nhãn trạng thái đơn hàng trông giống như con dấu đóng mực (`Rubber Stamp Badges`).
12. **Cách áp dụng vào Mobile App (`izithrift`):**
    - Tạo ấn tượng thị giác rất mạnh ngay từ cái nhìn đầu tiên ở màn hình Onboarding, Trang chủ và Sàn Đấu Giá (`Auction Hub`).
13. **Cách áp dụng vào Admin Dashboard (`Laravel Blade`):**
    - Rất khó áp dụng nguyên bản lên Admin Dashboard: nếu bảng dữ liệu 20 cột của Admin cũng dùng viền dày `2px` và bóng cứng thì màn hình quản trị sẽ cực kỳ nặng nề và rối mắt (bắt buộc phải làm dịu đi rất nhiều ở bản Web).
14. **Ưu điểm (`Pros`):**
    - Cá tính thị giác độc đáo, bắt mắt, tạo sự phấn khích cao trong các phiên đấu giá ngắn hạn.
15. **Hạn chế & Rủi ro UX (`Cons & UX Risks`):**
    - **Mệt mỏi thị giác (`Visual Fatigue`):** Viền dày `2px` + bóng cứng lặp lại trên 49 màn hình khiến giao diện bị chật chội, làm giảm diện tích hiển thị ảnh sản phẩm và gây rối mắt ở các màn hình nhiều thông tin chữ như Chi tiết đơn hàng 4 trạng thái (`M-OR-03`), Sổ cái Escrow (`M-SL-08`) và Phòng khiếu nại (`M-DP-03`).
    - Giảm cảm giác "an toàn tài chính" nghiêm túc khi người mua giao dịch các món đồ vintage đắt tiền (đồng hồ cổ, túi hiệu secondhand).
16. **Mức độ phù hợp với Retro Market:** **Trung bình – Khá (7.0 / 10)** *(Chỉ hợp với một số thành phần điểm nhấn như Vé đấu giá, không hợp làm hệ thống chủ đạo toàn sàn)*.

---

### HƯỚNG 3: `DIRECTION C – "NOSTALGIC ANALOG CATALOG"` (Sổ Mục Lục Lưu Trữ Cổ Điển & Thẻ Thư Viện)

1. **Tên hướng thiết kế:** **Nostalgic Analog Catalog** *(Mục lục Lưu trữ Cổ điển & Thẻ Hồ sơ Thư viện)*.
2. **Ý tưởng chủ đạo (`Core Concept`):** Lấy cảm hứng từ hệ thống thẻ mục lục thư viện xưa (library index cards), sổ kế toán cổ điển (vintage ledger books) và phiếu biên nhận bưu điện. Giao diện tập trung vào cấu trúc bảng biểu, các đường kẻ ngang dọc chia ô rõ ràng và kiểu chữ máy đánh chữ/công báo.
3. **Cảm xúc & Trải nghiệm thương hiệu (`Brand Mood`):** Hoài niệm sâu sắc (`Deeply Nostalgic`), ngăn nắp kiểu lưu trữ (`Archival & Methodical`), trầm tĩnh và nghiêm cẩn.
4. **Đặc trưng thị giác (`Visual Characteristics`):**
   - Hầu như không bo góc (`0px – 4px Sharp/Micro Corners`), các khối thông tin được chia thành từng ô lưới (`Grid Cells`) ngăn cách bằng đường kẻ mảnh liên tục như một tờ phiếu kiểm kê.
   - Sử dụng các tab lồi lên ở cạnh trên của thẻ giống như bìa hồ sơ phân loại (`Folder Tab Headers`).
5. **Định hướng màu sắc (`Color Mood`):**
   - Tông màu trầm và cổ điển: Nâu sepia nhạt, Xám đá phiến (`Slate Grey`), Xanh mực bút máy (`Fountain Pen Ink Blue`), Đỏ gạch trầm và Giấy ngà đậm.
6. **Định hướng kiểu chữ (`Typography Direction`):**
   - Kết hợp giữa chữ Serif cổ điển (`Old-style Serif`) và chữ Monospace (`Typewriter / Archival Mono`) cho toàn bộ nhãn thông tin, mã sản phẩm, ngày giờ và giá tiền.
7. **Định hướng hình ảnh (`Image & Photography Direction`):**
   - Ảnh sản phẩm đặt trong khung vuông vức có lề trắng bao quanh như ảnh dán vào hồ sơ lưu trữ, kèm dòng chú thích mã số (`ITEM #PRD-204`) bên dưới.
8. **Thiết kế Thẻ sản phẩm (`Product Card Direction`):**
   - Thẻ sản phẩm thiết kế như một **Thẻ mục lục (`Index Card`)**: phía trên là mã số & tình trạng, giữa là ảnh, dưới là bảng thông số 2 cột (Giá | Tiệm bán).
9. **Định hướng Điều hướng (`Navigation Direction`):**
   - Thanh điều hướng mô phỏng các ngăn kéo phân loại hoặc dải phân trang cổ điển, ít sử dụng các thành phần nổi hiện đại.
10. **Định hướng Biểu tượng (`Iconography Direction`):**
    - Icon nét mảnh sắc cạnh (`Sharp Geometric/Technical Line Icons`), hạn chế bo tròn.
11. **Định hướng Component (`Component Styling Direction`):**
    - Các bảng kê chi phí (`Checkout Preview`), sổ cái Ví (`M-SL-08`) và lịch sử trả giá (`M-AC-04`) trông giống hệt một cuốn sổ cái kế toán thực thụ.
12. **Cách áp dụng vào Mobile App (`izithrift`):**
    - Rất hợp với các màn hình tra cứu hồ sơ tình trạng đồ cũ, biên lai Escrow và lịch sử kiểm duyệt, nhưng lại làm cho Trang chủ và Khám phá mất đi sự mềm mại, tươi mới của một ứng dụng mua sắm hàng ngày.
13. **Cách áp dụng vào Admin Dashboard (`Laravel Blade`):**
    - Khá phù hợp với các màn hình tra cứu dữ liệu dày đặc như `A-ES-01` (Escrow Ledger Monitor) và `A-AD-01` (Audit Logs).
14. **Ưu điểm (`Pros`):**
    - Trình bày thông tin thông số kỹ thuật, mã đơn hàng, biên lai và sổ cái cực kỳ rõ ràng, có trật tự cao.
15. **Hạn chế & Rủi ro UX (`Cons & UX Risks`):**
    - **Quá khô khan và nặng tính "hồ sơ giấy tờ" (`Too Rigid & Bureaucratic`):** Thiếu sự ấm cúng (`Cozy`) và niềm vui mua sắm thời trang/đồ decor secondhand.
    - Góc vuông sắc cạnh và quá nhiều đường kẻ chia ô làm giao diện Mobile trông giống phần mềm kiểm kho hơn là một sàn C2C hiện đại.
16. **Mức độ phù hợp với Retro Market:** **Trung bình (6.5 / 10)** *(Chỉ nên mượn ý tưởng trình bày phiếu kiểm định & sổ cái, không nên dùng làm phong cách toàn ứng dụng)*.

---

## Chương 2. Ma Trận So Sánh & Khuyến Nghị Hướng Thiết Kế Chủ Đạo (`Comparison & Final Recommendation`)

### 2.1. Bảng So Sánh Đa Tiêu Chí Giữa 3 Hướng Thiết Kế

| Tiêu Chí Đánh Giá | Direction A: Warm Editorial Archive | Direction B: Bold Retro Pop & Ticket | Direction C: Nostalgic Analog Catalog |
| :--- | :---: | :---: | :---: |
| **1. Cảm xúc thương hiệu (`Vintage + Cozy + Modern`)** | **Xuất sắc (9.5/10)** – Ấm cúng, tinh tế, chuẩn gu tiệm đồ si tuyển chọn | Khá (7.5/10) – Năng động nhưng hơi ồn ào, thiếu độ ấm trầm | Trung bình (6.0/10) – Hoài cổ nhưng hơi lạnh và khô khan |
| **2. Độ tin cậy khi mua đồ cũ & Giao dịch Escrow (`Trust`)** | **Xuất sắc (9.5/10)** – Sạch sẽ, chuyên nghiệp, tôn trọng ảnh thật sản phẩm | Trung bình (6.5/10) – Phong cách hoạt hình/sticker dễ làm giảm cảm giác an toàn tài chính | Tốt (8.5/10) – Nghiêm túc như hồ sơ lưu trữ |
| **3. Khả năng đọc Tiếng Việt & Mật độ thông tin (`Readability`)** | **Xuất sắc (9.5/10)** – Phân cấp Serif/Sans-serif thoáng đãng, không mỏi mắt | Trung bình (6.5/10) – Viền dày 2px chiếm nhiều diện tích màn hình nhỏ | Khá (7.5/10) – Nhiều đường kẻ ô dễ gây ngợp khi chữ tiếng Việt dài |
| **4. Tính đồng nhất giữa Flutter Mobile & Laravel Blade Admin** | **Xuất sắc (9.5/10)** – Chuyển đổi mượt mà từ Mobile sang Web Admin | Kém (5.5/10) – Không thể áp dụng viền dày/bóng cứng lên bảng Admin lớn | Tốt (8.0/10) – Hợp với bảng biểu nhưng kém hấp dẫn trên Mobile |
| **5. Khả năng tích hợp & tách lớp mùa vụ Giáng sinh (`NFR-UX-02`)** | **Xuất sắc (10/10)** – Bảng màu xanh thông/đỏ rượu vang/kem ấm hòa quyện tự nhiên | Trung bình (6.5/10) – Dễ bị xung đột màu sắc lòe loẹt | Trung bình (6.0/10) – Khó lồng ghép không khí lễ hội ấm áp |
| **6. Khả năng triển khai kỹ thuật bằng Flutter & CSS Blade** | **Rất thuận lợi (9.0/10)** – Chuẩn hóa dễ dàng bằng `ThemeData` & CSS Tokens | Trung bình (7.0/10) – Phức tạp khi cắt hình răng cưa trên mọi màn hình | Thuận lợi (8.0/10) |
| **TỔNG ĐIỂM ĐÁNH GIÁ** | **9.5 / 10 (KHUYẾN NGHỊ CHỦ ĐẠO)** | **6.8 / 10** | **7.0 / 10** |

---

### 2.2. Đề Xuất Chiến Lược Kết Hợp Tinh Hoa (`Recommended Hybrid Synthesis`)

Với vai trò Senior UI/UX Designer & Art Director, tôi khuyến nghị chọn **`DIRECTION A – "WARM EDITORIAL ARCHIVE"` làm ngôn ngữ thiết kế chủ đạo (85% toàn hệ thống)**, đồng thời **chắt lọc có chọn lọc 2 chi tiết đắt giá nhất từ Direction B và Direction C (15%)** để tạo nên bản sắc độc nhất cho **Retro Market (`izithrift`)**:

1. **Lấy từ `Direction A (Warm Editorial Archive)` làm Nền tảng Cốt lõi (85%):**
   - Toàn bộ cấu trúc lưới thoáng đãng, bề mặt nền kem ấm (`Warm Cream`) và thẻ be sáng (`Soft Beige`), màu chủ đạo Xanh rừng thông trầm (`Forest Green`) & Đỏ rượu vang ấm (`Burgundy`), điểm nhấn Vàng đồng cổ (`Antique Gold`), bo góc mềm mại (`8px–12px`) và hệ thống phân cấp chữ Editorial Serif + Modern Sans-serif.
2. **Mượn từ `Direction B (Bold Retro Pop)` chi tiết "Thẻ Vé Đấu Giá" (`Auction Ticket Motif` – 8%):**
   - Áp dụng thiết kế **cuống vé tinh tế (có đường kẻ nét đứt ngang và khuyết nhẹ hai bên hông)** dành riêng cho **Thẻ Phiên Đấu Giá (`Auction Card`)** và **Bảng Giá Phòng Đấu Giá (`M-AC-03`)**. Điều này giúp người dùng phân biệt tức thì đâu là hàng Đấu giá theo phiên và đâu là hàng Giá cố định (`Fixed Price`) chỉ bằng hình dáng khối mà không cần đọc chữ!
3. **Mượn từ `Direction C (Nostalgic Analog Catalog)` chi tiết "Phiếu Kiểm Định & Sổ Cái" (`Inspection Slip & Ledger Motif` – 7%):**
   - Áp dụng bố cục **Phiếu kiểm định chất lượng (`Inspection Slip`)** cho khu vực khai báo `condition` + `defect_info` trên trang Chi tiết sản phẩm (`M-PR-01`) và bố cục **Biên lai Sổ cái (`Escrow Receipt Slip`)** cho bảng tính `Buyer Protection Fee` (`M-OR-01`) cùng biên lai `ESCROW HELD` (`M-PM-02`). Chi tiết này biến các thông tin khô khan về lỗi sản phẩm và phí bảo vệ thành một trải nghiệm kiểm chứng đầy tin cậy.

---

## Chương 3. Quyết Định Cần Product Owner Phê Duyệt (`Product Owner Decisions Required`)

*(Xem danh sách tổng hợp các quyết định cần phê duyệt ở cuối báo cáo P3-01).*