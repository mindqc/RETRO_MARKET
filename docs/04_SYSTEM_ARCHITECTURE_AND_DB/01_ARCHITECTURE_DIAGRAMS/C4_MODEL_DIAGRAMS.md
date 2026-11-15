# 02. C4 MODEL ARCHITECTURE DIAGRAMS – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P401B-C4-MODELS`
- **Version:** `1.0.0`
- **Status:** `SELF-VERIFIED & READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Phase:** `Phase 04 – System Architecture, Database Design & API Specification`

*(Tài liệu này sử dụng cú pháp `Mermaid` chuẩn để phác họa Mô hình C4 từ cấp độ Ngữ cảnh đến cấp độ Component nghiệp vụ cốt lõi).*

---

## 1. C4 Level 1: System Context Diagram (`Sơ đồ Ngữ cảnh Hệ thống`)

Mô tả sự tương tác ở góc nhìn vĩ mô giữa các nhóm người dùng (Actors) và hệ thống Retro Market, cũng như sự phụ thuộc vào các hệ thống bên ngoài.

```mermaid
flowchart TB
    %% Định dạng style giả lập C4 Model
    classDef person fill:#08427b,color:#fff,stroke:#052e56,stroke-width:2px,rx:8px,ry:8px;
    classDef system fill:#1168bd,color:#fff,stroke:#0b4884,stroke-width:2px,rx:8px,ry:8px;
    classDef external_system fill:#999999,color:#fff,stroke:#6b6b6b,stroke-width:2px,rx:8px,ry:8px;

    %% Actors
    Buyer["Người mua (Buyer)\n[Person]\nTìm kiếm đồ si, đặt giá thầu, thanh toán và theo dõi đơn."]:::person
    Seller["Người bán (Seller)\n[Person]\nĐăng bán sản phẩm, đóng gói hàng và nhận giải ngân."]:::person
    Admin["Quản trị viên (Admin/Mod/Support)\n[Person]\nKiểm duyệt sản phẩm, xử lý khiếu nại, giám sát sổ cái Escrow."]:::person

    %% Core System
    RetroMarket["Retro Market (izithrift)\n[Software System]\nNền tảng TMĐT C2C mua bán đồ secondhand và đấu giá theo phiên, tích hợp giữ tiền Escrow."]:::system

    %% External Systems
    Mailpit["Hệ thống Email (Mailpit)\n[External System]\nNhận/Gửi email khôi phục mật khẩu (Local Test)."]:::external_system
    Storage["Hệ thống Lưu trữ (Local/S3)\n[External System]\nLưu trữ hình ảnh sản phẩm và bằng chứng khiếu nại."]:::external_system

    %% Relationships
    Buyer -- "Xem sản phẩm, Mua hàng,\nĐặt giá thầu, Thanh toán QR" --> RetroMarket
    Seller -- "Đăng sản phẩm, Xử lý đơn,\nGiải trình khiếu nại" --> RetroMarket
    Admin -- "Quản trị hệ thống, Kiểm duyệt,\nPhân xử dòng tiền" --> RetroMarket

    RetroMarket -- "Gửi mã Reset Password" --> Mailpit
    RetroMarket -- "Lưu/Tải file ảnh (<=5MB)" --> Storage
```

---

## 2. C4 Level 2: Container Diagram (`Sơ đồ Container`)

Phóng to vào bên trong hệ thống `Retro Market` để thấy các ứng dụng (Containers), kho lưu trữ dữ liệu và các giao thức giao tiếp (REST API, Web, SQL).

```mermaid
flowchart TB
    classDef person fill:#08427b,color:#fff,stroke:#052e56,stroke-width:2px,rx:8px,ry:8px;
    classDef container fill:#438dd5,color:#fff,stroke:#2e6295,stroke-width:2px,rx:8px,ry:8px;
    classDef database fill:#2e6295,color:#fff,stroke:#1168bd,stroke-width:2px,rx:8px,ry:8px;

    BuyerSeller["Người dùng (Buyer/Seller)\n[Person]"]:::person
    AdminUser["Quản trị viên nội bộ\n[Person]"]:::person

    subgraph RetroMarket System [Retro Market System]
        direction TB
        MobileApp["Mobile Application\n[Container: Flutter]\nCung cấp giao diện High-Fidelity cho người mua & bán (Android/iOS)."]:::container
        AdminWeb["Admin Dashboard\n[Container: Laravel Blade]\nGiao diện Web quản trị nội bộ SSR (Server-Side Rendering)."]:::container
        ApiApp["Backend Application API\n[Container: Laravel 11/13 + PHP]\nXử lý Business Logic, Validation, Authentication & Phân quyền."]:::container
        Worker["Background Queue Worker\n[Container: Laravel Horizon/Worker]\nThực thi các Job tự động (Đóng phiên, Hủy đơn, Giải ngân)."]:::container
        
        DB[("PostgreSQL Database\n[Container: PostgreSQL 18]\nLưu trữ toàn bộ dữ liệu giao dịch chuẩn ACID, hỗ trợ Khóa dòng (Row Lock).")]:::database
        Cache[("Redis Cache/Queue\n[Container: Redis 7]\nMessage broker cho Job Queue và bộ nhớ đệm cấu hình nền tảng.")]:::database
    end

    BuyerSeller -- "Sử dụng (HTTPS/REST)" --> MobileApp
    AdminUser -- "Xem & Thao tác (HTTPS)" --> AdminWeb

    MobileApp -- "Gửi API Requests (JSON)" --> ApiApp
    AdminWeb -- "Sử dụng trực tiếp Service Layer (Internal)" --> ApiApp

    ApiApp -- "Đọc/Ghi dữ liệu nguyên tử (SQL)" --> DB
    ApiApp -- "Đẩy Jobs & Ghi Cache" --> Cache

    Worker -- "Lấy Jobs xử lý" --> Cache
    Worker -- "Cập nhật trạng thái (SQL)" --> DB
```

---

## 3. C4 Level 3: Component Diagram (`Sơ đồ Component Trọng Tâm`)

Phóng to vào `Backend Application API` để thấy cách luồng dữ liệu (Data Flow) và Khóa bi quan (`Pessimistic Locking`) được áp dụng trong 2 tiến trình phức tạp nhất: **Đấu giá (Auction)** và **Giữ tiền Escrow (Transaction)**.

```mermaid
flowchart TB
    classDef component fill:#85bbf0,color:#000,stroke:#5b93c7,stroke-width:2px,rx:8px,ry:8px;
    classDef database fill:#2e6295,color:#fff,stroke:#1168bd,stroke-width:2px,rx:8px,ry:8px;

    MobileClient["Mobile API Client\n(Flutter Dio)"]:::component
    CronTrigger["Laravel Scheduler\n(cron)"]:::component

    subgraph Laravel Backend [Laravel Backend Application]
        direction TB
        
        %% Controllers
        AuctionCtrl["Auction Controller\n[Component: API]\nTiếp nhận request đặt giá thầu."]:::component
        EscrowCtrl["Escrow/Order Controller\n[Component: API]\nTiếp nhận thanh toán/nhận hàng."]:::component

        %% Services
        AuctionService["Auction Service\n[Component: Business Logic]\nXử lý Anti-Sniping, Đặt giá, Đóng phiên."]:::component
        EscrowService["Escrow/Ledger Service\n[Component: Business Logic]\nXử lý công thức phí, Cân bằng sổ cái."]:::component

        %% DB Layer / Repositories implied within Eloquent
        DBFacade["DB Transaction Manager\n[Component: Eloquent ORM]\nQuản lý BEGIN, COMMIT, ROLLBACK & lockForUpdate()."]:::component
    end

    Postgres[("PostgreSQL DB (Bảng auctions, orders, escrow_transactions)")]:::database

    %% Luồng Đấu giá
    MobileClient -- "POST /auctions/{id}/bids" --> AuctionCtrl
    AuctionCtrl -- "Gọi hàm placeBid()" --> AuctionService
    AuctionService -- "Yêu cầu Khóa dòng (FOR UPDATE)" --> DBFacade
    
    %% Luồng Scheduler / Jobs
    CronTrigger -- "Kích hoạt CloseExpiredAuctionsJob" --> AuctionService

    %% Luồng Escrow
    MobileClient -- "POST /payments/{id}/simulate-success" --> EscrowCtrl
    EscrowCtrl -- "Gọi hàm holdEscrow()" --> EscrowService
    EscrowService -- "Yêu cầu Khóa dòng & Ghi Sổ cái" --> DBFacade

    %% DB Interaction
    DBFacade -- "Thực thi SQL Transactions (Bảo toàn ACID)" --> Postgres
```