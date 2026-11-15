# 01. REST API ARCHITECTURAL GUIDELINES & DATA CONTRACTS – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P404A-REST-API-GUIDELINES`
- **Version:** `1.0.0 (COMPLETE REST API CONTRACT SPECIFICATION)`
- **Status:** `SELF-VERIFIED & READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 04 – System Architecture, Database Design & API Specification`
- **Compliance Ref:** `ADR-01..08`, `DEC-01..07`, `NFR-PER-01..03`, `NFR-SEC-01..05`

---

## Chương 1. Quy Chuẩn Giao Thức, Định Tuyến & Xác Thực (`Protocol, Versioning & Authentication`)

### 1.1. Base URL & API Versioning (`ADR-02`)
Hệ thống phân tách rõ ràng giữa RESTful JSON API phục vụ ứng dụng di động Flutter (`izithrift`) và hệ thống định tuyến Web Server-Side Rendering (SSR) phục vụ Laravel Blade Admin Dashboard:
- **Mobile REST API Base URL:** `/api/v1` (Mọi request bắt buộc đính kèm header `Accept: application/json`).
- **Admin Web SSR Base URL:** `/admin` (Xử lý qua Web Session + CSRF Protection `VerifyCsrfToken`).

### 1.2. Cơ Chế Xác Thực & Bảo Mật Token (`Laravel Sanctum – NFR-SEC-01..02`)
- **Guest Access (`DEC-01`):** Các endpoint khám phá công khai (`GET /api/v1/home`, `GET /api/v1/products`, `GET /api/v1/auctions`, `GET /api/v1/sellers/{id}`) cho phép truy cập không cần Bearer Token. Nếu người dùng đã đăng nhập và gửi kèm Token hợp lệ vào các endpoint này, Backend sẽ tự động bổ sung các trường ngữ cảnh cá nhân (`is_favorited`, `is_watching`, `is_leading_bidder`, `is_owner`).
- **Authenticated Access (`auth:sanctum` + `EnsureUserIsActive` Middleware):**
  - Header bắt buộc: `Authorization: Bearer <plainTextToken>`.
  - Middleware `EnsureUserIsActive` kiểm tra `users.status === 'ACTIVE'` trên mỗi request. Nếu tài khoản vừa bị Admin chuyển sang `'SUSPENDED'` hoặc `'BANNED'` (`BR-AC-04`), API lập tức thu hồi token và trả về mã `403 Forbidden` với `error_code: "ACCOUNT_SUSPENDED"`.

---

## Chương 2. Cấu Trúc JSON Envelope Chuẩn Hóa (`Standardized JSON Response Envelope`)

Để ứng dụng Flutter (`Dio` Interceptor & Data Models) parse dữ liệu đồng nhất 100% trên mọi màn hình, toàn bộ phản hồi từ `/api/v1/*` bắt buộc tuân thủ cấu trúc JSON Envelope dưới đây:

### 2.1. Phản Hồi Thành Công Đơn Bản Ghi (`200 OK` / `201 Created`)
```json
{
  "success": true,
  "message": "Đặt giá thầu thành công.",
  "server_time": "2026-11-14T20:41:12+07:00",
  "data": {
    "auction_id": 108,
    "current_highest_bid": 900000,
    "minimum_next_bid": 950000,
    "leading_bidder_id": 15,
    "auction_ends_at": "2026-11-14T22:02:00+07:00",
    "extended_count": 1,
    "triggered_anti_sniping": true
  }
}
```
*(Lưu ý quan trọng theo `BR-AU-01`: Mọi response của API đều trả kèm trường `server_time` chuẩn ISO-8601 để Mobile App tính độ lệch đồng hồ `clock_skew = server_time - device_time`, đảm bảo mọi đồng hồ đếm ngược Đấu giá và Hạn thanh toán 30 phút chính xác tuyệt đối đến từng giây).*

### 2.2. Phản Hồi Danh Sách Có Phân Trang (`Paginated Collection Response`)
```json
{
  "success": true,
  "message": "Lấy danh sách sản phẩm thành công.",
  "server_time": "2026-11-14T20:41:12+07:00",
  "data": [
    {
      "id": 204,
      "product_code": "PRD-2026-0204",
      "title": "Áo Khoác Dạ Tweed Cổ Điển Mùa Đông",
      "listing_type": "FIXED_PRICE",
      "condition": "GOOD",
      "price": 450000,
      "available_quantity": 1,
      "primary_image_url": "http://localhost:8000/storage/products/204/main.jpg",
      "seller": {
        "id": 8,
        "display_name": "Tiệm Đồ Si Nhà Gấu",
        "average_rating": 4.9,
        "trust_score": 98.0
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total": 48,
    "last_page": 3,
    "has_more_pages": true
  }
}
```

### 2.3. Phản Hồi Lỗi Chuẩn Hóa (`Standard Error Response – 4xx / 5xx`)
```json
{
  "success": false,
  "error_code": "AUCTION_OUTBID_CONFLICT",
  "message": "Vừa có người mua khác đặt mức giá 900.000đ trước bạn vài giây! Mức giá hợp lệ tối thiểu hiện tại là 950.000 VNĐ.",
  "server_time": "2026-11-14T20:41:15+07:00",
  "errors": {
    "bid_amount": [
      "Mức giá đặt phải lớn hơn hoặc bằng 950.000 VNĐ."
    ]
  },
  "latest_state": {
    "current_highest_bid": 900000,
    "minimum_next_bid": 950000,
    "auction_ends_at": "2026-11-14T22:02:00+07:00"
  }
}
```

---

## Chương 3. Bảng Mã Trạng Thái HTTP & Từ Điển Mã Lỗi Nghiệp Vụ (`HTTP Status & Domain Error Codes`)

| HTTP Status | Domain `error_code` | Ngữ Cảnh Nghiệp Vụ & Cách Xử Lý Trên UI Flutter (`izithrift`) |
| :---: | :--- | :--- |
| `401` | `UNAUTHENTICATED` | Chưa đăng nhập hoặc Token hết hạn $\rightarrow$ Chuyển hướng tới `M-AU-03 (/login?redirect=...)` (`DEC-01`). |
| `403` | `ACCOUNT_SUSPENDED` | Tài khoản bị khóa (`SUSPENDED` / `BANNED` – `BR-AC-04`) $\rightarrow$ Xóa token và hiển thị hộp cảnh báo lý do khóa. |
| `403` | `SELF_TRANSACTION_FORBIDDEN` | Chủ tiệm tự mua hàng, tự đặt giá thầu, tự đánh giá hoặc tự theo dõi chính mình (`BR-AC-02`). |
| `403` | `ROLE_PERMISSION_DENIED` | Người dùng hoặc nhân sự nội bộ gọi API/Route vượt quá quyền trong `03_ACTOR_PERMISSION_MATRIX.md`. |
| `404` | `RESOURCE_NOT_AVAILABLE` | Sản phẩm không tồn tại hoặc đang ở trạng thái `DRAFT`, `PENDING_REVIEW`, `REJECTED`, `HIDDEN`. |
| `409` | `AUCTION_OUTBID_CONFLICT` | Xung đột đồng thời khi 2 người cùng đặt giá thầu (`lockForUpdate()` – `AF-03`) $\rightarrow$ Cập nhật ngay `latest_state` trên Bottom Sheet `M-AC-04`. |
| `409` | `PRODUCT_OUT_OF_STOCK` | Món đồ vừa được người mua khác đặt mua trước vài mili-giây (`OF-02`) $\rightarrow$ Báo hết hàng và đưa về Giỏ hàng. |
| `409` | `INVALID_STATE_TRANSITION` | Thao tác không hợp lệ với trạng thái hiện tại (ví dụ: bấm Hủy đơn khi đã `SHIPPED`, hoặc giải ngân đơn đang có `DISPUTE_OPEN`). |
| `422` | `VALIDATION_ERROR` | Dữ liệu form không hợp lệ (thiếu `defect_info`, `min_price > max_price`, thiếu `reason` khi Reject/Dispute, file ảnh `> 5MB`). |
| `429` | `TOO_MANY_REQUESTS` | Vượt ngưỡng Rate Limit (`NFR-SEC-04`) $\rightarrow$ Hiển thị thời gian chờ `Retry-After`. |

---

## Chương 4. Quy Tắc Bảo Mật Dữ Liệu Đầu Vào, Tiền Tệ & Bất Đồng Bộ (`Security, Currency & Polling Rules`)

1. **Zero Client-Side Price Trust (`NFR-SEC-03`):**
   - Các API tạo đơn hàng (`POST /api/v1/orders`) và xem trước phí (`POST /api/v1/checkout/preview`) **chỉ nhận danh sách `product_id` và `quantity`**. Backend tự truy vấn `products.price` và `platform_settings` để tính `item_subtotal`, `shipping_fee (0đ)`, `buyer_protection_fee` và `total_amount` (`DEC-04`). Mọi giá tiền do Client gửi lên đều bị bỏ qua.
2. **Kiểm soát Tải Tệp Tin Đa Phương Tiện (`Multipart Upload Security – NFR-SEC-05`):**
   - Áp dụng cho ảnh sản phẩm (`M-SL-03`), ảnh bằng chứng khiếu nại (`M-DP-01`, `M-DP-03`) và avatar (`M-PF-02`): Chỉ chấp nhận MIME types `image/jpeg`, `image/png`, `image/webp`; dung lượng mỗi ảnh `<= 5120 KB (5MB)`; tự động đổi tên file thành UUID ngẫu nhiên khi lưu trữ.
3. **Cấu hình Rate Limiting (`NFR-SEC-04`):**
   - Nhóm Auth (`login`, `register`, `forgot-password`): Tối đa **5 requests / phút / IP**.
   - Nhóm Giao dịch nhạy cảm (`place-bid`, `checkout`, `simulate-payment`): Tối đa **30 requests / phút / User**.
   - Nhóm HTTP Polling (`GET /conversations/{id}/messages`, `GET /auctions/{id}`): Tối đa **60 requests / phút / User** (Chu kỳ chuẩn trên Flutter là `3–5 giây/lần` khi màn hình đang active – `ADR-08`).