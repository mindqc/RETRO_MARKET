# 06. MASTER DESIGN TOKENS & PLATFORM HANDOFF – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P302-DESIGN-TOKENS`
- **Version:** `1.0.0`
- **Status:** `SELF-VERIFIED & READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – UI/UX Design System & High-Fidelity Specification`

---

## Chương 1. Quy Tắc Đặt Tên & Phân Tầng Design Tokens (`Token Naming Convention & Hierarchy`)

Hệ thống Design Tokens của **Retro Market (`izithrift`)** được tổ chức theo cấu trúc phân cấp ngữ nghĩa (`category.domain.role.state`), tách biệt rõ:
1. **Core / Global Tokens:** Giá trị nguyên thủy của bảng màu, font chữ, khoảng cách và bo góc.
2. **Semantic / Contextual Tokens:** Token gắn liền với vai trò giao diện (`bg.mobile.canvas`, `bg.admin.canvas`, `text.primary`) và trạng thái nghiệp vụ (`status.escrow.held`, `status.auction.outbid`, `status.dispute.open`).

---

## Chương 2. Nguồn Chân Lý Duy Nhất Dạng JSON Hợp Lệ (`Valid Parseable Master JSON Tokens`)

Khối JSON dưới đây tuân thủ chuẩn cú pháp nghiêm ngặt 100%, đồng bộ tuyệt đối với `COLOR_SYSTEM.md`, `TYPOGRAPHY.md`, `SPACING_AND_LAYOUT.md` và `COMPONENT_LIBRARY.md`:

```json
{
  "meta": {
    "project": "RETRO MARKET",
    "brand": "izithrift",
    "version": "1.0.0",
    "direction": "UI-DEC-01: Warm Editorial Archive + Ticket Stub & Inspection Slip Synthesis"
  },
  "color": {
    "brand": {
      "primary": {
        "default": "#294638",
        "hover": "#1E352A",
        "subtle": "#E3ECE7"
      },
      "secondary": {
        "default": "#873A43",
        "hover": "#6E2D35",
        "subtle": "#F4E5E7"
      },
      "accent": {
        "default": "#C79B4B",
        "subtle": "#F7EFE0"
      }
    },
    "bg": {
      "mobile": {
        "canvas": "#F4EBDD",
        "seller_header": "#294638"
      },
      "admin": {
        "canvas": "#FBF9F5",
        "sidebar": "#294638"
      }
    },
    "surface": {
      "mobile": {
        "card": "#FAF5EC",
        "secondary": "#E7DAC6",
        "elevated": "#FFFDF9"
      },
      "admin": {
        "card": "#FFFFFF",
        "table_header": "#F4EBDD",
        "row_hover": "#FBF9F5"
      }
    },
    "text": {
      "primary": "#302D2A",
      "secondary": "#655E57",
      "tertiary": "#8C837A",
      "disabled": "#ACA399",
      "inverse": "#FAF5EC"
    },
    "border": {
      "default": "#D8CBB8",
      "strong": "#B8A892",
      "hairline": "#E5D9C8",
      "focus": "#294638",
      "error": "#A62B2B"
    },
    "semantic": {
      "success": { "text": "#236343", "bg": "#E3F2EA", "border": "#9ACBB0" },
      "warning": { "text": "#945814", "bg": "#FDF1E1", "border": "#E8C28E" },
      "error": { "text": "#A62B2B", "bg": "#FCE8E8", "border": "#E5A6A6" },
      "info": { "text": "#28557A", "bg": "#E6F0F8", "border": "#A2C4E0" }
    },
    "commerce": {
      "price": "#294638",
      "sold_out": { "text": "#5C5650", "bg": "#E0D8CE" },
      "condition": {
        "like_new": { "text": "#1F5E3B", "bg": "#E1F0E7" },
        "good": { "text": "#2B5B6C", "bg": "#E3EFF3" },
        "fair": { "text": "#8C5A1B", "bg": "#F9EFE0" },
        "vintage_worn": { "text": "#6E473B", "bg": "#EFE6E2" }
      }
    },
    "auction": {
      "live_badge": { "text": "#FAF5EC", "bg": "#873A43" },
      "highest_bid": { "text": "#873A43", "bg": "#F4E5E7" },
      "leading": { "text": "#1F5E3B", "bg": "#DFF0E6" },
      "outbid": { "text": "#A62B2B", "bg": "#FCE6E6" },
      "countdown_normal": { "text": "#302D2A", "bg": "#E7DAC6" },
      "countdown_urgent": { "text": "#FAF5EC", "bg": "#A62B2B" },
      "anti_sniping": { "text": "#7A4B0E", "bg": "#FDECC8" },
      "won": { "text": "#302D2A", "bg": "#EED69F" },
      "ended": { "text": "#655E57", "bg": "#E5DDD2" }
    },
    "transaction": {
      "payment": {
        "pending": { "text": "#945814", "bg": "#FDF1E1" },
        "paid": { "text": "#236343", "bg": "#E3F2EA" },
        "failed": { "text": "#A62B2B", "bg": "#FCE8E8" }
      },
      "escrow": {
        "held": { "text": "#1C5858", "bg": "#DDF0F0" },
        "released": { "text": "#236343", "bg": "#E3F2EA" },
        "refunded": { "text": "#28557A", "bg": "#E4EFF8" }
      },
      "order": {
        "preparing": { "text": "#7A4B0E", "bg": "#FBF0D9" },
        "shipped": { "text": "#28557A", "bg": "#E6F0F8" },
        "completed": { "text": "#236343", "bg": "#E3F2EA" },
        "cancelled": { "text": "#655E57", "bg": "#E6E0D6" }
      },
      "dispute": {
        "open": { "text": "#6A2C5A", "bg": "#F4E4F0" }
      }
    },
    "moderation": {
      "draft": { "text": "#655E57", "bg": "#EAE3D9" },
      "pending": { "text": "#945814", "bg": "#FDF1E1" },
      "approved": { "text": "#236343", "bg": "#E3F2EA" },
      "rejected": { "text": "#A62B2B", "bg": "#FCE8E8" },
      "suspended": { "text": "#FAF5EC", "bg": "#7A1F1F" }
    }
  },
  "typography": {
    "fontFamily": {
      "brandDisplay": "Wichita Vintage",
      "editorialHeading": "Fraunces",
      "primaryBody": "Be Vietnam Pro",
      "monospaceCode": "JetBrains Mono"
    },
    "scale": {
      "displayHero": { "size": 28, "lineHeight": 36, "weight": 700, "family": "Fraunces" },
      "h1": { "size": 24, "lineHeight": 32, "weight": 700, "family": "Fraunces" },
      "h2": { "size": 20, "lineHeight": 28, "weight": 600, "family": "Fraunces" },
      "h3": { "size": 18, "lineHeight": 24, "weight": 600, "family": "Fraunces" },
      "titleSection": { "size": 16, "lineHeight": 24, "weight": 600, "family": "Be Vietnam Pro" },
      "titleCard": { "size": 15, "lineHeight": 20, "weight": 600, "family": "Be Vietnam Pro" },
      "bodyLarge": { "size": 16, "lineHeight": 24, "weight": 400, "family": "Be Vietnam Pro" },
      "bodyMedium": { "size": 14, "lineHeight": 20, "weight": 400, "family": "Be Vietnam Pro" },
      "bodyStrong": { "size": 14, "lineHeight": 20, "weight": 600, "family": "Be Vietnam Pro" },
      "caption": { "size": 12, "lineHeight": 16, "weight": 400, "family": "Be Vietnam Pro" },
      "badgeLabel": { "size": 11, "lineHeight": 14, "weight": 600, "family": "Be Vietnam Pro" },
      "buttonLarge": { "size": 15, "lineHeight": 20, "weight": 600, "family": "Be Vietnam Pro" },
      "buttonSmall": { "size": 13, "lineHeight": 18, "weight": 600, "family": "Be Vietnam Pro" },
      "priceHero": { "size": 24, "lineHeight": 30, "weight": 700, "family": "Be Vietnam Pro", "tabular": true },
      "priceCard": { "size": 16, "lineHeight": 22, "weight": 700, "family": "Be Vietnam Pro", "tabular": true },
      "countdownHero": { "size": 20, "lineHeight": 26, "weight": 700, "family": "JetBrains Mono", "tabular": true }
    }
  },
  "spacing": {
    "0": 0,
    "1": 4,
    "2": 8,
    "3": 12,
    "4": 16,
    "5": 20,
    "6": 24,
    "8": 32,
    "10": 40,
    "12": 48
  },
  "radius": {
    "xs": 4,
    "sm": 8,
    "md": 12,
    "lg": 16,
    "full": 9999
  },
  "borderWidth": {
    "thin": 1.0,
    "focused": 1.5,
    "dashedTicket": 1.5
  },
  "sizing": {
    "touchTargetMin": 48,
    "buttonHeightLarge": 48,
    "buttonHeightMedium": 40,
    "buttonHeightSmall": 32,
    "inputHeight": 48,
    "mobileTopBarHeight": 56,
    "mobileBottomNavHeight": 64,
    "adminSidebarWidth": 260,
    "adminHeaderHeight": 64
  }
}
```

---

## Chương 3. Hướng Dẫn Chuyển Giao Thực Thi Cho Hai Nền Tảng (`Platform Implementation Handoff`)

### 3.1. Tổ Chức Theme & Widget Trên Flutter (`Mobile App Architecture Handoff`)
Khi bước vào giai đoạn lập trình Flutter (Phase 07), toàn bộ Design Tokens trên được ánh xạ vào thư mục `lib/core/theme/`:
1. **`app_colors.dart`:** Khai báo các hằng số `Color(0xFF...)` khớp chính xác 1:1 với nhánh `color` trong JSON.
2. **`app_typography.dart`:** Cấu hình `TextTheme` sử dụng `google_fonts` cho `Fraunces`, `Be Vietnam Pro`, `JetBrains Mono` và font asset cục bộ `Wichita Vintage`, bật sẵn `FontFeature.tabularFigures()` cho toàn bộ kiểu chữ số tiền và đồng hồ đếm ngược.
3. **`app_theme.dart`:** Xây dựng `ThemeData` với `scaffoldBackgroundColor: AppColors.bgMobileCanvas` (`#F4EBDD`), `cardTheme`, `inputDecorationTheme`, `elevatedButtonTheme`, và một `ThemeExtension<SeasonalTheme>` chứa cờ `enableSeasonalChristmasDecor` (`NFR-UX-02`).
4. **Thư viện Shared Widgets (`lib/core/widgets/`):** Đóng gói các Component trong `COMPONENT_LIBRARY.md` thành các widget dùng chung (`IzithriftButton`, `IzithriftProductCard`, `IzithriftAuctionTicketCard`, `ConditionInspectionSlip`, `TransactionFourStateHeader`, `EscrowFeeBreakdownSlip`).

### 3.2. Tổ Chức CSS Variables & Blade Components Trên Laravel 13 (`Admin Web Handoff`)
Khi bước vào giai đoạn xây dựng Admin Dashboard (Phase 06 & Phase 12), các token được ánh xạ vào:
1. **`resources/css/admin-tokens.css`:** Khai báo toàn bộ biến `:root { --color-brand-primary: #294638; --color-bg-admin-canvas: #FBF9F5; --color-escrow-held-bg: #DDF0F0; ... }`.
2. **Thư viện Reusable Blade Components (`resources/views/components/admin/`):**
   - `<x-admin.layout>` (Khung Sidebar `#294638` lọc menu theo Role RBAC + Main Canvas `#FBF9F5`).
   - `<x-admin.metric-card>` (Thẻ KPI).
   - `<x-admin.status-badge type="escrow|order|payment|dispute|mod" :status="$status" />`.
   - `<x-admin.dispute-verdict-panel :dispute="$dispute" />` (Tự động kiểm tra `@can('resolve', $dispute)` để chỉ hiển thị cho Administrator).