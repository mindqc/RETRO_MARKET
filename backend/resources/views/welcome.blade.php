<!DOCTYPE html>
<html lang="vi" class="scroll-smooth">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>izithrift — Sàn Đồ Si, Vintage & Đấu Giá Tuyển Chọn</title>
    <meta name="description" content="izithrift — Nền tảng mua bán đồ secondhand, vintage tuyển chọn và đấu giá trực tuyến an toàn với cơ chế ký quỹ minh bạch.">
    <link rel="icon" type="image/svg+xml" href="{{ asset('images/izithrift-logo.svg') }}">

    <!-- Google Fonts: Be Vietnam Pro -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="bg-[#F4F5F7] text-[#231F20] font-sans antialiased selection:bg-[#174D38] selection:text-white">

    <!-- ===================================================================== -->
    <!-- 1. STANDARDIZED GLOBAL STICKY HEADER                                  -->
    <!-- ===================================================================== -->
    <header class="sticky top-0 z-40 bg-white/95 backdrop-blur-md border-b border-[#E5E7EB]">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center gap-3 sm:gap-5">
            <!-- Brand Logo + Wordmark -->
            <a href="#top" class="shrink-0 flex items-center">
                @include('partials.izithrift-logo', ['size' => 34, 'dark' => false])
            </a>

            <!-- Desktop Navigation -->
            <nav class="hidden lg:flex items-center gap-1 ml-2">
                <a href="#auctions" class="px-3 py-2 text-sm font-semibold text-[#231F20] hover:text-[#174D38] rounded-lg hover:bg-[#F4F5F7] transition">Đấu giá</a>
                <a href="#new-arrivals" class="px-3 py-2 text-sm font-semibold text-[#231F20] hover:text-[#174D38] rounded-lg hover:bg-[#F4F5F7] transition">Hàng mới</a>
                <a href="#nearby-stores" class="px-3 py-2 text-sm font-semibold text-[#231F20] hover:text-[#174D38] rounded-lg hover:bg-[#F4F5F7] transition">Tiệm gần bạn</a>
                <a href="#secondhand-feed" class="px-3 py-2 text-sm font-semibold text-[#231F20] hover:text-[#174D38] rounded-lg hover:bg-[#F4F5F7] transition">Pass đồ 2hand</a>
            </nav>

            <!-- Flexible Search Input -->
            <div class="flex-1 max-w-md ml-auto">
                <label class="relative block">
                    <span class="sr-only">Tìm kiếm đồ si</span>
                    <svg class="w-4 h-4 text-[#6B7280] absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-4.35-4.35m0 0A7.5 7.5 0 104.5 4.5a7.5 7.5 0 0012.15 12.15z"/>
                    </svg>
                    <input id="globalSearchInput"
                           type="search"
                           placeholder="Tìm áo khoác 90s, túi da, máy ảnh film..."
                           class="w-full pl-10 pr-4 py-2 text-sm bg-[#F4F5F7] border border-[#E5E7EB] rounded-full text-[#231F20] placeholder-[#6B7280] focus:outline-none focus:bg-white focus:border-[#174D38] transition">
                </label>
            </div>

            <!-- Action Controls -->
            <div class="flex items-center gap-1.5 sm:gap-2 shrink-0">
                <!-- Sell CTA Button -->
                <button type="button"
                        onclick="openSellModal()"
                        class="hidden sm:inline-flex items-center gap-1.5 px-4 py-2 rounded-full bg-[#C65335] hover:bg-[#A94227] text-white text-xs sm:text-sm font-bold shadow-xs transition cursor-pointer">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 4v16m8-8H4"/>
                    </svg>
                    Đăng bán
                </button>

                <!-- Notifications Button -->
                <button type="button"
                        onclick="toggleNotificationsToast()"
                        aria-label="Thông báo"
                        class="relative p-2 rounded-full text-[#231F20] hover:bg-[#F4F5F7] transition cursor-pointer">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>
                    </svg>
                    <span class="absolute top-1 right-1 w-4 h-4 rounded-full bg-[#C65335] text-white text-[10px] font-extrabold flex items-center justify-center">2</span>
                </button>

                <!-- Cart Button -->
                <button type="button"
                        onclick="toggleCartDrawer(true)"
                        aria-label="Giỏ hàng"
                        class="relative p-2 rounded-full text-[#231F20] hover:bg-[#F4F5F7] transition cursor-pointer">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"/>
                    </svg>
                    <span id="cartCountBadge" class="hidden absolute top-1 right-1 min-w-4 h-4 px-1 rounded-full bg-[#C65335] text-white text-[10px] font-extrabold flex items-center justify-center">0</span>
                </button>

                <!-- Admin Portal Link -->
                <a href="{{ route('admin.login') }}"
                   class="hidden md:inline-flex items-center px-3 py-1.5 rounded-full border border-[#E5E7EB] text-xs font-semibold text-[#174D38] hover:border-[#174D38] hover:bg-[#E7F2EC] transition">
                    Quản trị
                </a>
            </div>
        </div>
    </header>

    <main id="top" class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8 space-y-10">

        <!-- ================================================================= -->
        <!-- 2. SEASONAL CURATED HERO BANNER (COZY VINTAGE CHRISTMAS)          -->
        <!-- ================================================================= -->
        <section class="relative overflow-hidden rounded-3xl bg-gradient-to-br from-[#102E22] via-[#174D38] to-[#21664B] text-white shadow-lg">
            <!-- Subtle winter ambient accents -->
            <div class="pointer-events-none absolute -right-14 -top-14 w-64 h-64 rounded-full bg-[#D6AE55]/15 blur-2xl"></div>
            <div class="pointer-events-none absolute left-1/3 -bottom-20 w-72 h-72 rounded-full bg-[#C65335]/15 blur-3xl"></div>

            <div class="relative grid lg:grid-cols-12 gap-6 p-6 sm:p-10 items-center">
                <div class="lg:col-span-7 space-y-4">
                    <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#F8EED6] text-[#3E3022] text-xs font-bold tracking-wide">
                        <span>❄️</span>
                        <span>BỘ SƯU TẬP MÙA ĐÔNG &bull; IZITHRIFT</span>
                    </div>

                    <h1 class="text-3xl sm:text-4xl lg:text-5xl font-extrabold leading-tight tracking-tight">
                        Săn Đồ Vintage Tuyển Chọn,<br>
                        <span class="text-[#D6AE55]">Đấu Giá Minh Bạch</span>
                    </h1>

                    <p class="text-sm sm:text-base text-white/85 max-w-xl leading-relaxed">
                        Khám phá hàng nghìn món đồ secondhand độc bản từ cộng đồng người bán uy tín gần bạn. Kiểm duyệt 100% trước khi lên kệ và bảo vệ giao dịch bằng cơ chế Ký quỹ (Escrow).
                    </p>

                    <div class="flex flex-wrap items-center gap-3 pt-1">
                        <a href="#secondhand-feed"
                           class="inline-flex items-center gap-2 px-5 py-3 rounded-full bg-[#C65335] hover:bg-[#A94227] text-white text-sm font-bold shadow-sm transition">
                            Khám phá ngay
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M13 7l5 5m0 0l-5 5m5-5H6"/>
                            </svg>
                        </a>
                        <a href="#auctions"
                           class="inline-flex items-center gap-2 px-5 py-3 rounded-full bg-white/12 hover:bg-white/20 border border-white/25 text-white text-sm font-bold transition">
                            Sàn đấu giá trực tiếp
                        </a>
                        <button type="button"
                                onclick="openSellModal()"
                                class="sm:hidden inline-flex items-center gap-1.5 px-4 py-3 rounded-full bg-[#D6AE55] text-[#231F20] text-sm font-bold cursor-pointer">
                            + Đăng bán
                        </button>
                    </div>
                </div>

                <!-- Right Highlight Curated Vintage Cards -->
                <div class="lg:col-span-5 grid grid-cols-2 gap-3.5">
                    <div class="bg-white/10 backdrop-blur-sm border border-white/20 rounded-2xl p-2.5">
                        <div class="aspect-[4/5] rounded-xl overflow-hidden bg-[#102E22]">
                            <img src="{{ asset('images/products/vintage_varsity_jacket.jpg') }}"
                                 alt="Áo khoác Varsity len 90s"
                                 class="w-full h-full object-cover">
                        </div>
                        <div class="mt-2 px-1">
                            <p class="text-xs font-bold truncate">Varsity Len 90s</p>
                            <p class="text-xs font-extrabold text-[#D6AE55] tabular-nums">420.000đ</p>
                        </div>
                    </div>
                    <div class="bg-white/10 backdrop-blur-sm border border-white/20 rounded-2xl p-2.5 translate-y-3">
                        <div class="aspect-[4/5] rounded-xl overflow-hidden bg-[#102E22]">
                            <img src="{{ asset('images/products/vintage_film_camera.jpg') }}"
                                 alt="Máy ảnh film 35mm cổ điển"
                                 class="w-full h-full object-cover">
                        </div>
                        <div class="mt-2 px-1">
                            <p class="text-xs font-bold truncate">Máy Ảnh Film 35mm</p>
                            <p class="text-xs font-extrabold text-[#D6AE55] tabular-nums">1.250.000đ</p>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- ================================================================= -->
        <!-- 3. CATEGORY SHORTCUTS                                             -->
        <!-- ================================================================= -->
        <section aria-label="Danh mục nổi bật">
            <div class="flex items-center justify-between mb-4">
                <div>
                    <h2 class="text-lg sm:text-xl font-extrabold text-[#231F20]">Danh mục tuyển chọn</h2>
                    <p class="text-xs sm:text-sm text-[#6B7280]">Lọc nhanh món đồ secondhand đúng gu của bạn</p>
                </div>
                <button type="button" onclick="selectCategory('Tất cả')" class="text-xs sm:text-sm font-bold text-[#174D38] hover:underline cursor-pointer">
                    Xem tất cả →
                </button>
            </div>
            <div id="categoryFilterBar" class="flex gap-2.5 overflow-x-auto pb-2 izi-carousel">
                <!-- Rendered via JS -->
            </div>
        </section>

        <!-- ================================================================= -->
        <!-- 4. FEATURED AUCTIONS — HORIZONTAL CAROUSEL WITH LIVE COUNTDOWN    -->
        <!-- ================================================================= -->
        <section id="auctions" class="rounded-3xl bg-[#174D38] text-white p-5 sm:p-7 shadow-md">
            <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-5">
                <div>
                    <div class="inline-flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-[#D6AE55]">
                        <span class="w-2 h-2 rounded-full bg-[#C65335] animate-pulse"></span>
                        Sàn Đấu Giá Vintage • Chống Sniping +2 phút
                    </div>
                    <h2 class="text-xl sm:text-2xl font-extrabold mt-1">Đấu giá nổi bật</h2>
                    <p class="text-xs sm:text-sm text-white/80">Săn món đồ độc đáo với mức giá của bạn.</p>
                </div>
                <button type="button"
                        onclick="openSellModal('AUCTION')"
                        class="self-start sm:self-auto inline-flex items-center gap-1.5 px-4 py-2 rounded-full bg-[#D6AE55] hover:bg-[#c49c44] text-[#231F20] text-xs sm:text-sm font-extrabold transition cursor-pointer">
                    + Tạo phiên đấu giá
                </button>
            </div>

            <div id="auctionCarousel" class="flex gap-4 overflow-x-auto pb-3 snap-x snap-mandatory izi-carousel">
                <!-- Populated dynamically with real ticking timers -->
            </div>
        </section>

        <!-- ================================================================= -->
        <!-- 5. NEW ARRIVALS — HORIZONTAL PRODUCT CAROUSEL                     -->
        <!-- ================================================================= -->
        <section id="new-arrivals">
            <div class="flex items-center justify-between mb-4">
                <div>
                    <h2 class="text-lg sm:text-xl font-extrabold text-[#231F20]">Hàng mới lên kệ</h2>
                    <p class="text-xs sm:text-sm text-[#6B7280]">Những món đồ si vừa vượt qua vòng kiểm duyệt chất lượng</p>
                </div>
                <a href="#secondhand-feed" class="text-xs sm:text-sm font-bold text-[#174D38] hover:underline">Xem thêm →</a>
            </div>
            <div id="newArrivalsCarousel" class="flex gap-4 overflow-x-auto pb-3 snap-x snap-mandatory izi-carousel">
                <!-- Populated dynamically -->
            </div>
        </section>

        <!-- ================================================================= -->
        <!-- 6. NEARBY POPULAR SECONDHAND STORES + PASS ĐỒ 2HAND GRID          -->
        <!-- ================================================================= -->
        <section id="nearby-stores" class="space-y-5">
            <div class="flex flex-col sm:flex-row sm:items-end justify-between gap-2">
                <div>
                    <h2 class="text-lg sm:text-xl font-extrabold text-[#231F20]">Tiệm đồ si được yêu thích gần bạn</h2>
                    <p class="text-xs sm:text-sm text-[#6B7280]">Đồ secondhand đã duyệt từ các tiệm uy tín quanh khu vực của bạn</p>
                </div>
                <span id="gridResultCount" class="text-xs font-bold text-[#174D38] bg-[#E7F2EC] px-3 py-1 rounded-full self-start sm:self-auto">
                    8 sản phẩm nổi bật
                </span>
            </div>

            <!-- Compact Nearby Trusted Stores Strip -->
            <div class="flex gap-3 overflow-x-auto pb-1 izi-carousel">
                @foreach ([
                    ['name' => 'Tiệm Cổ Điển Sài Gòn', 'dist' => '1,2 km', 'rating' => '4.9'],
                    ['name' => 'Analog Film & Thrift', 'dist' => '2,4 km', 'rating' => '4.8'],
                    ['name' => 'Tiệm Giày Si Quận 3', 'dist' => '3,5 km', 'rating' => '4.9'],
                    ['name' => 'Kho Denim 90s Bình Thạnh', 'dist' => '4,8 km', 'rating' => '4.7'],
                ] as $shop)
                    <div class="shrink-0 inline-flex items-center gap-2.5 bg-white border border-[#E5E7EB] rounded-full px-3.5 py-2 shadow-2xs">
                        <span class="w-8 h-8 rounded-full bg-[#E7F2EC] text-[#174D38] font-extrabold text-xs flex items-center justify-center">
                            {{ mb_substr($shop['name'], 0, 1) }}
                        </span>
                        <div class="leading-tight">
                            <p class="text-xs font-bold text-[#231F20] flex items-center gap-1">
                                {{ $shop['name'] }}
                                <span class="text-[#174D38]" title="Shop uy tín">✓</span>
                            </p>
                            <p class="text-[11px] text-[#6B7280] font-medium">★ {{ $shop['rating'] }} &bull; {{ $shop['dist'] }}</p>
                        </div>
                    </div>
                @endforeach
            </div>

            <!-- Responsive 2-to-4 Column Secondhand Marketplace Grid -->
            <div id="secondhand-feed" class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3.5 sm:gap-5">
                <!-- Populated dynamically -->
            </div>
        </section>

    </main>

    <!-- ===================================================================== -->
    <!-- FOOTER                                                                -->
    <!-- ===================================================================== -->
    <footer class="mt-12 bg-white border-t border-[#E5E7EB]">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div class="space-y-1.5">
                @include('partials.izithrift-logo', ['size' => 30, 'dark' => false])
                <p class="text-xs text-[#6B7280] max-w-md">
                    Nền tảng mua bán đồ secondhand & đấu giá vintage minh bạch. Mọi bài đăng mới đều qua kiểm duyệt trước khi hiển thị.
                </p>
            </div>
            <div class="flex flex-wrap items-center gap-4 text-xs font-semibold text-[#6B7280]">
                <a href="#auctions" class="hover:text-[#174D38]">Đấu giá</a>
                <a href="#secondhand-feed" class="hover:text-[#174D38]">Pass đồ 2hand</a>
                <a href="{{ route('admin.login') }}" class="text-[#174D38] hover:underline">Cổng Quản trị Admin</a>
            </div>
        </div>
    </footer>

    <!-- ===================================================================== -->
    <!-- SLIDE-OVER CART DRAWER                                                -->
    <!-- ===================================================================== -->
    <div id="cartDrawerBackdrop" onclick="toggleCartDrawer(false)" class="hidden fixed inset-0 z-50 bg-black/40 backdrop-blur-[1px]"></div>
    <aside id="cartDrawer" class="hidden fixed top-0 right-0 z-50 h-full w-full max-w-md bg-white shadow-2xl flex flex-col">
        <div class="px-5 py-4 border-b border-[#E5E7EB] flex items-center justify-between">
            <h3 class="text-base font-extrabold text-[#231F20]">Giỏ hàng của bạn</h3>
            <button type="button" onclick="toggleCartDrawer(false)" class="p-1.5 rounded-full hover:bg-[#F4F5F7] text-[#6B7280] cursor-pointer">✕</button>
        </div>
        <div id="cartItemsContainer" class="flex-1 overflow-y-auto p-5 space-y-3"></div>
        <div class="p-5 border-t border-[#E5E7EB] bg-[#F4F5F7] space-y-3">
            <div class="flex items-center justify-between text-sm">
                <span class="font-semibold text-[#6B7280]">Tạm tính</span>
                <span id="cartTotalValue" class="text-lg font-extrabold text-[#C65335] tabular-nums">0đ</span>
            </div>
            <button type="button" onclick="checkoutDemoCart()" class="w-full py-3 rounded-full bg-[#C65335] hover:bg-[#A94227] text-white font-bold text-sm transition cursor-pointer">
                Tiến hành thanh toán ký quỹ
            </button>
        </div>
    </aside>

    <!-- ===================================================================== -->
    <!-- SELL / CREATE LISTING & AUCTION MODAL                                 -->
    <!-- ===================================================================== -->
    <div id="sellModal" class="hidden fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-[1px]">
        <div class="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl space-y-4">
            <div class="flex items-start justify-between">
                <div>
                    <h3 class="text-lg font-extrabold text-[#231F20]">Đăng bài lên izithrift</h3>
                    <p class="text-xs text-[#6B7280] mt-0.5">Chọn hình thức đăng bán phù hợp với món đồ của bạn.</p>
                </div>
                <button type="button" onclick="closeSellModal()" class="p-1.5 rounded-full hover:bg-[#F4F5F7] text-[#6B7280] cursor-pointer">✕</button>
            </div>

            <div class="space-y-3">
                <button type="button" onclick="submitDemoModerationNotice('FIXED_PRICE')"
                        class="w-full text-left p-4 rounded-2xl border border-[#E5E7EB] hover:border-[#174D38] hover:bg-[#E7F2EC]/40 transition flex items-start gap-3.5 cursor-pointer">
                    <span class="w-11 h-11 rounded-xl bg-[#E7F2EC] text-[#174D38] flex items-center justify-center shrink-0 font-bold text-lg">🏷️</span>
                    <span>
                        <span class="block text-sm font-extrabold text-[#231F20]">Đăng bán sản phẩm</span>
                        <span class="block text-xs text-[#6B7280] mt-0.5">Đăng món đồ với giá cố định. Người mua có thể đặt mua ngay.</span>
                    </span>
                </button>

                <button type="button" onclick="submitDemoModerationNotice('AUCTION')"
                        class="w-full text-left p-4 rounded-2xl border border-[#E5E7EB] hover:border-[#C65335] hover:bg-[#FBEDE9]/40 transition flex items-start gap-3.5 cursor-pointer">
                    <span class="w-11 h-11 rounded-xl bg-[#FBEDE9] text-[#C65335] flex items-center justify-center shrink-0 font-bold text-lg">🔨</span>
                    <span>
                        <span class="block text-sm font-extrabold text-[#231F20]">Tạo phiên đấu giá</span>
                        <span class="block text-xs text-[#6B7280] mt-0.5">Tạo phiên đấu giá với giá khởi điểm và thời gian tham gia.</span>
                    </span>
                </button>
            </div>

            <div id="sellModerationBanner" class="hidden p-3.5 rounded-xl bg-[#F8EED6] border border-[#E7D29D] text-xs font-semibold text-[#3E3022]">
                ✓ Đã gửi bài đăng. Bài đăng của bạn đang chờ duyệt.
            </div>
        </div>
    </div>

    <!-- Toast Banner -->
    <div id="iziToast" class="hidden fixed bottom-5 left-1/2 -translate-x-1/2 z-50 px-5 py-3 rounded-full bg-[#174D38] text-white text-xs sm:text-sm font-semibold shadow-xl"></div>

    <script>
        const PRODUCTS = [
            { id: 9101, title: 'Áo Khoác Varsity Len Cổ Điển 90s', price: 420000, conditionPct: '95%', category: 'Áo khoác', distance: '1,2 km', seller: 'Tiệm Cổ Điển Sài Gòn', image: "{{ asset('images/products/vintage_varsity_jacket.jpg') }}" },
            { id: 9102, title: 'Quần Denim Selvedge Nhật Bản Vintage', price: 380000, conditionPct: '90%', category: 'Quần', distance: '2,1 km', seller: 'Kho Denim 90s', image: "{{ asset('images/products/vintage_denim_jeans.jpg') }}" },
            { id: 9103, title: 'Túi Đeo Chéo Da Bò Sáp Thủ Công', price: 540000, conditionPct: '95%', category: 'Túi & Giày', distance: '1,8 km', seller: 'Tiệm Giày Si Quận 3', image: "{{ asset('images/products/vintage_leather_bag.jpg') }}" },
            { id: 9104, title: 'Máy Ảnh Film 35mm Kèm Ống Kính 50mm', price: 1250000, conditionPct: '85%', category: 'Đồ cổ', distance: '2,4 km', seller: 'Analog Film & Thrift', image: "{{ asset('images/products/vintage_film_camera.jpg') }}" },
            { id: 9105, title: 'Áo Sơ Mi Flannel Caro Mùa Đông', price: 240000, conditionPct: '90%', category: 'Áo khoác', distance: '3,5 km', seller: 'Tiệm Cổ Điển Sài Gòn', image: "{{ asset('images/products/vintage_flannel_shirt.jpg') }}" },
            { id: 9106, title: 'Cardigan Len Vặn Thừng Retro Kem', price: 295000, conditionPct: '95%', category: 'Áo khoác', distance: '1,5 km', seller: 'Len Mùa Đông Thrift', image: "{{ asset('images/products/vintage_knit_cardigan.jpg') }}" },
            { id: 9107, title: 'Đồng Hồ Cơ Lên Cót Tay Nhật Bản', price: 1180000, conditionPct: '85%', category: 'Phụ kiện', distance: '4,2 km', seller: 'Analog Film & Thrift', image: "{{ asset('images/products/vintage_mechanical_watch.jpg') }}" },
            { id: 9108, title: 'Giày Sneakers Retro Da Lộn Phối Kem', price: 650000, conditionPct: '90%', category: 'Túi & Giày', distance: '3,5 km', seller: 'Tiệm Giày Si Quận 3', image: "{{ asset('images/products/vintage_retro_sneakers.jpg') }}" },
        ];

        const nowMs = Date.now();
        const AUCTIONS = [
            { id: 8101, title: 'Máy Ảnh Film 35mm Nhật Bản Bản Hiếm', currentBid: 1350000, startPrice: 900000, bids: 14, status: 'ENDING_SOON', endsAt: nowMs + 11 * 60 * 1000, image: "{{ asset('images/products/vintage_film_camera.jpg') }}" },
            { id: 8102, title: 'Áo Khoác Varsity Len Thêu Tay 1994', currentBid: 520000, startPrice: 350000, bids: 9, status: 'LIVE', endsAt: nowMs + 78 * 60 * 1000, image: "{{ asset('images/products/vintage_varsity_jacket.jpg') }}" },
            { id: 8103, title: 'Đồng Hồ Cơ Vintage Mặt Men Cổ Điển', currentBid: 1290000, startPrice: 850000, bids: 18, status: 'LIVE', endsAt: nowMs + 145 * 60 * 1000, image: "{{ asset('images/products/vintage_mechanical_watch.jpg') }}" },
            { id: 8104, title: 'Túi Da Bò Vintage Khóa Đồng Nguyên Bản', currentBid: 480000, startPrice: 480000, bids: 21, status: 'UPCOMING', endsAt: nowMs + 210 * 60 * 1000, image: "{{ asset('images/products/vintage_leather_bag.jpg') }}" },
        ];

        const CATEGORIES = ['Tất cả', 'Áo khoác', 'Quần', 'Túi & Giày', 'Đồ cổ', 'Phụ kiện'];
        let selectedCategory = 'Tất cả';
        let searchQuery = '';
        let cart = [];

        const formatVnd = (n) => new Intl.NumberFormat('vi-VN').format(n) + 'đ';

        function showToast(msg) {
            const el = document.getElementById('iziToast');
            el.textContent = msg;
            el.classList.remove('hidden');
            clearTimeout(window._iziToastTimer);
            window._iziToastTimer = setTimeout(() => el.classList.add('hidden'), 2800);
        }

        function renderCategories() {
            const bar = document.getElementById('categoryFilterBar');
            bar.innerHTML = CATEGORIES.map(cat => {
                const active = cat === selectedCategory;
                return `<button type="button" onclick="selectCategory('${cat}')"
                    class="shrink-0 px-4 py-2 rounded-full text-xs sm:text-sm font-bold border transition cursor-pointer ${
                        active
                            ? 'bg-[#174D38] text-white border-[#174D38] shadow-xs'
                            : 'bg-white text-[#231F20] border-[#E5E7EB] hover:border-[#174D38]'
                    }">${cat}</button>`;
            }).join('');
        }

        function selectCategory(cat) {
            selectedCategory = cat;
            renderCategories();
            renderDiscoveryGrid();
        }

        function renderAuctions() {
            const container = document.getElementById('auctionCarousel');
            container.innerHTML = AUCTIONS.map(a => {
                const badge = a.status === 'ENDING_SOON'
                    ? '<span class="px-2.5 py-0.5 rounded-full text-[10.5px] font-extrabold bg-[#C65335] text-white">⚡ Sắp kết thúc</span>'
                    : a.status === 'UPCOMING'
                        ? '<span class="px-2.5 py-0.5 rounded-full text-[10.5px] font-extrabold bg-[#D6AE55] text-[#231F20]">⏰ Sắp mở</span>'
                        : '<span class="px-2.5 py-0.5 rounded-full text-[10.5px] font-extrabold bg-[#C65335] text-white">● Đang diễn ra</span>';
                const ctaLabel = a.status === 'UPCOMING' ? 'Giữ chỗ tham gia' : 'Đấu giá ngay';
                return `
                    <article class="snap-start shrink-0 w-[265px] sm:w-[290px] bg-white text-[#231F20] rounded-2xl overflow-hidden shadow-md border border-white/15 flex flex-col">
                        <div class="relative aspect-[4/3] bg-[#F4F5F7] overflow-hidden">
                            <img src="${a.image}" alt="${a.title}" class="w-full h-full object-cover">
                            <div class="absolute top-2.5 left-2.5">${badge}</div>
                            <div class="absolute bottom-2.5 right-2.5 px-2.5 py-1 rounded-lg bg-[#231F20]/85 text-[#F8EED6] text-xs font-extrabold tabular-nums" data-countdown="${a.endsAt}">--:--:--</div>
                        </div>
                        <div class="p-3.5 flex-1 flex flex-col justify-between gap-3">
                            <div>
                                <h3 class="text-sm font-bold line-clamp-2 leading-snug">${a.title}</h3>
                                <div class="mt-2 flex items-baseline justify-between">
                                    <div>
                                        <p class="text-[11px] text-[#6B7280]">${a.status === 'UPCOMING' ? 'Giá khởi điểm' : 'Giá cao nhất'}</p>
                                        <p class="text-base font-extrabold text-[#C65335] tabular-nums">${formatVnd(a.currentBid)}</p>
                                    </div>
                                    <span class="text-[11px] font-bold text-[#174D38] bg-[#E7F2EC] px-2 py-0.5 rounded-full">${a.bids} ${a.status === 'UPCOMING' ? 'giữ chỗ' : 'lượt bid'}</span>
                                </div>
                            </div>
                            <button type="button" onclick="handleAuctionAction(${a.id})"
                                    class="w-full py-2.5 rounded-full bg-[#C65335] hover:bg-[#A94227] text-white text-xs font-extrabold transition cursor-pointer">
                                ${ctaLabel}
                            </button>
                        </div>
                    </article>
                `;
            }).join('');
            tickCountdowns();
        }

        function handleAuctionAction(auctionId) {
            const a = AUCTIONS.find(x => x.id === auctionId);
            if (!a) return;
            if (a.status === 'UPCOMING') {
                a.bids += 1;
                showToast('✓ Đã đăng ký giữ chỗ tham gia phiên "' + a.title + '"!');
            } else {
                a.currentBid += 20000;
                a.bids += 1;
                showToast('🎉 Đã đặt giá nhanh ' + formatVnd(a.currentBid) + ' cho "' + a.title + '"!');
            }
            renderAuctions();
        }

        function tickCountdowns() {
            const els = document.querySelectorAll('[data-countdown]');
            const now = Date.now();
            els.forEach(el => {
                const diff = Math.max(0, Math.floor((Number(el.dataset.countdown) - now) / 1000));
                const h = String(Math.floor(diff / 3600)).padStart(2, '0');
                const m = String(Math.floor((diff % 3600) / 60)).padStart(2, '0');
                const s = String(diff % 60).padStart(2, '0');
                el.textContent = `${h}:${m}:${s}`;
            });
        }

        function renderNewArrivals() {
            const container = document.getElementById('newArrivalsCarousel');
            container.innerHTML = PRODUCTS.slice(0, 6).map(p => `
                <article class="snap-start shrink-0 w-[205px] sm:w-[228px] bg-white rounded-2xl border border-[#E5E7EB] overflow-hidden shadow-2xs hover:shadow-md transition flex flex-col">
                    <div class="relative aspect-[4/5] bg-[#F4F5F7] overflow-hidden">
                        <img src="${p.image}" alt="${p.title}" class="w-full h-full object-cover hover:scale-105 transition duration-300">
                        <span class="absolute top-2.5 left-2.5 px-2 py-0.5 rounded-full text-[10.5px] font-extrabold bg-[#F8EED6] text-[#3E3022] border border-[#E7D29D]">${p.conditionPct}</span>
                    </div>
                    <div class="p-3 flex-1 flex flex-col justify-between gap-2">
                        <div>
                            <p class="text-[11px] font-semibold text-[#174D38]">${p.category}</p>
                            <h3 class="text-xs sm:text-sm font-bold text-[#231F20] line-clamp-2 mt-0.5">${p.title}</h3>
                        </div>
                        <div class="flex items-center justify-between pt-1">
                            <span class="text-sm font-extrabold text-[#C65335] tabular-nums">${formatVnd(p.price)}</span>
                            <button type="button" onclick="addToCart(${p.id})" class="px-2.5 py-1 rounded-full bg-[#E7F2EC] hover:bg-[#174D38] text-[#174D38] hover:text-white text-[11px] font-bold transition cursor-pointer">+ Giỏ</button>
                        </div>
                    </div>
                </article>
            `).join('');
        }

        function renderDiscoveryGrid() {
            const grid = document.getElementById('secondhand-feed');
            const filtered = PRODUCTS.filter(p => {
                const matchCat = selectedCategory === 'Tất cả' || p.category === selectedCategory;
                const q = searchQuery.trim().toLowerCase();
                const matchQuery = !q || p.title.toLowerCase().includes(q) || p.seller.toLowerCase().includes(q) || p.category.toLowerCase().includes(q);
                return matchCat && matchQuery;
            });

            document.getElementById('gridResultCount').textContent = `${filtered.length} sản phẩm đã duyệt`;

            if (filtered.length === 0) {
                grid.innerHTML = `<div class="col-span-full bg-white border border-[#E5E7EB] rounded-2xl p-10 text-center">
                    <p class="text-sm font-bold text-[#231F20]">Không tìm thấy sản phẩm phù hợp</p>
                    <p class="text-xs text-[#6B7280] mt-1">Thử chọn danh mục khác hoặc xoá từ khóa tìm kiếm.</p>
                </div>`;
                return;
            }

            grid.innerHTML = filtered.map(p => `
                <article class="bg-white rounded-2xl border border-[#E5E7EB] overflow-hidden shadow-2xs hover:shadow-md transition flex flex-col">
                    <div class="relative aspect-[4/5] bg-[#F4F5F7] overflow-hidden">
                        <img src="${p.image}" alt="${p.title}" class="w-full h-full object-cover hover:scale-105 transition duration-300">
                        <span class="absolute top-2.5 left-2.5 px-2 py-0.5 rounded-full text-[10.5px] font-extrabold bg-[#F8EED6] text-[#3E3022] border border-[#E7D29D]">Mới ${p.conditionPct}</span>
                        <span class="absolute bottom-2.5 left-2.5 px-2 py-0.5 rounded-full text-[10.5px] font-bold bg-white/90 text-[#174D38]">📍 ${p.distance}</span>
                    </div>
                    <div class="p-3 sm:p-3.5 flex-1 flex flex-col justify-between gap-2.5">
                        <div>
                            <div class="flex items-center justify-between gap-1">
                                <span class="text-[11px] font-semibold text-[#174D38]">${p.category}</span>
                                <span class="text-[10.5px] text-[#6B7280] truncate">${p.seller}</span>
                            </div>
                            <h3 class="text-xs sm:text-sm font-bold text-[#231F20] line-clamp-2 mt-1 leading-snug">${p.title}</h3>
                        </div>
                        <div class="flex items-center justify-between gap-2 pt-1 border-t border-[#EDF0F4]">
                            <span class="text-sm sm:text-base font-extrabold text-[#C65335] tabular-nums">${formatVnd(p.price)}</span>
                            <button type="button" onclick="addToCart(${p.id})"
                                    class="px-3 py-1.5 rounded-full bg-[#174D38] hover:bg-[#103828] text-white text-[11px] font-bold transition cursor-pointer">
                                Thêm giỏ
                            </button>
                        </div>
                    </div>
                </article>
            `).join('');
        }

        function addToCart(productId) {
            const p = PRODUCTS.find(x => x.id === productId);
            if (!p) return;
            if (!cart.some(c => c.id === p.id)) {
                cart.push(p);
                updateCartUI();
                showToast('✓ Đã thêm "' + p.title + '" vào giỏ hàng');
            } else {
                showToast('Món đồ độc bản này đã có trong giỏ hàng của bạn');
            }
        }

        function removeFromCart(productId) {
            cart = cart.filter(c => c.id !== productId);
            updateCartUI();
        }

        function updateCartUI() {
            const badge = document.getElementById('cartCountBadge');
            badge.textContent = cart.length;
            badge.classList.toggle('hidden', cart.length === 0);

            const container = document.getElementById('cartItemsContainer');
            if (cart.length === 0) {
                container.innerHTML = `<div class="text-center py-12 text-xs text-[#6B7280]">Giỏ hàng trống. Hãy chọn món đồ vintage bạn ưng ý nhé!</div>`;
            } else {
                container.innerHTML = cart.map(item => `
                    <div class="flex items-center gap-3 p-3 rounded-2xl border border-[#E5E7EB]">
                        <img src="${item.image}" alt="${item.title}" class="w-16 h-16 rounded-xl object-cover shrink-0">
                        <div class="flex-1 min-w-0">
                            <p class="text-xs font-bold text-[#231F20] truncate">${item.title}</p>
                            <p class="text-[11px] text-[#6B7280]">${item.seller} &bull; ${item.conditionPct}</p>
                            <p class="text-sm font-extrabold text-[#C65335] mt-0.5 tabular-nums">${formatVnd(item.price)}</p>
                        </div>
                        <button type="button" onclick="removeFromCart(${item.id})" class="text-xs text-[#6B7280] hover:text-[#C65335] font-bold px-2 py-1 cursor-pointer">Xóa</button>
                    </div>
                `).join('');
            }
            const total = cart.reduce((sum, i) => sum + i.price, 0);
            document.getElementById('cartTotalValue').textContent = formatVnd(total);
        }

        function toggleCartDrawer(open) {
            document.getElementById('cartDrawerBackdrop').classList.toggle('hidden', !open);
            document.getElementById('cartDrawer').classList.toggle('hidden', !open);
        }

        function checkoutDemoCart() {
            if (cart.length === 0) {
                showToast('Vui lòng thêm ít nhất 1 món đồ vào giỏ hàng.');
                return;
            }
            cart = [];
            updateCartUI();
            toggleCartDrawer(false);
            showToast('✓ Đã tạo phiên thanh toán ký quỹ thành công trên ứng dụng izithrift!');
        }

        function openSellModal() {
            document.getElementById('sellModerationBanner').classList.add('hidden');
            document.getElementById('sellModal').classList.remove('hidden');
        }

        function closeSellModal() {
            document.getElementById('sellModal').classList.add('hidden');
        }

        function submitDemoModerationNotice() {
            document.getElementById('sellModerationBanner').classList.remove('hidden');
            showToast('Đã gửi bài đăng. Bài đăng của bạn đang chờ duyệt.');
        }

        function toggleNotificationsToast() {
            showToast('🔔 2 thông báo mới: Phiên đấu giá Máy ảnh Film 35mm sắp kết thúc!');
        }

        document.getElementById('globalSearchInput').addEventListener('input', (e) => {
            searchQuery = e.target.value;
            renderDiscoveryGrid();
        });

        renderCategories();
        renderAuctions();
        renderNewArrivals();
        renderDiscoveryGrid();
        updateCartUI();
        setInterval(tickCountdowns, 1000);
    </script>
</body>
</html>
