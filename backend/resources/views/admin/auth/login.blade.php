<!DOCTYPE html>
<html lang="vi" class="h-full bg-[#F4EBDD]">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>Đăng nhập Quản trị | izithrift</title>

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700&family=Fraunces:opsz,wght@9..144,600;9..144,700;9..144,900&display=swap" rel="stylesheet">

    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="h-full font-sans antialiased bg-[#F4EBDD] flex items-center justify-center p-4">
    <div class="max-w-md w-full">
        <!-- Logo and Brand -->
        <div class="text-center mb-8">
            <div class="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-[#2D5A3C] shadow-lg mb-4">
                <span class="text-white font-serif font-black text-3xl">i</span>
            </div>
            <h1 class="font-serif text-3xl font-extrabold text-[#1F2937] tracking-tight">izithrift</h1>
            <p class="mt-2 text-sm text-[#84664C] font-medium">Hệ thống Quản trị & Điều hành Sàn Đấu giá</p>
        </div>

        <!-- Login Card -->
        <div class="bg-white rounded-2xl shadow-xl border border-[#E8E2D9] p-8">
            <div class="mb-6">
                <h2 class="font-serif text-xl font-bold text-[#1F2937]">Đăng nhập nhân sự</h2>
                <p class="text-xs text-gray-500 mt-1">Truy cập dành riêng cho Admin, Moderator và Support Staff</p>
            </div>

            <!-- Flash Alerts -->
            @if (session('success'))
                <div class="mb-5 p-3.5 bg-emerald-50 border-l-4 border-emerald-600 rounded-r text-emerald-900 text-xs font-medium">
                    {{ session('success') }}
                </div>
            @endif

            @if ($errors->any())
                <div class="mb-5 p-3.5 bg-rose-50 border-l-4 border-rose-600 rounded-r text-rose-900 text-xs font-medium">
                    @if ($errors->has('email'))
                        {{ $errors->first('email') }}
                    @else
                        {{ $errors->first() }}
                    @endif
                </div>
            @endif

            <!-- Form -->
            <form method="POST" action="{{ route('admin.login.submit') }}" class="space-y-5">
                @csrf

                <div>
                    <label for="email" class="block text-xs font-semibold uppercase tracking-wider text-[#5E5852] mb-1.5">
                        Email công vụ
                    </label>
                    <input type="email"
                           id="email"
                           name="email"
                           value="{{ old('email') }}"
                           required
                           autofocus
                           autocomplete="username"
                           placeholder="staff@izithrift.internal"
                           class="w-full px-3.5 py-2.5 rounded-lg border border-[#D5CBC1] focus:ring-2 focus:ring-[#C85A32] focus:border-[#C85A32] text-sm text-[#1F2937] placeholder-gray-400 transition-colors bg-[#FCFAF7]">
                </div>

                <div>
                    <label for="password" class="block text-xs font-semibold uppercase tracking-wider text-[#5E5852] mb-1.5">
                        Mật khẩu
                    </label>
                    <input type="password"
                           id="password"
                           name="password"
                           required
                           autocomplete="current-password"
                           placeholder="••••••••••••"
                           class="w-full px-3.5 py-2.5 rounded-lg border border-[#D5CBC1] focus:ring-2 focus:ring-[#C85A32] focus:border-[#C85A32] text-sm text-[#1F2937] placeholder-gray-400 transition-colors bg-[#FCFAF7]">
                </div>

                <div class="flex items-center justify-between text-xs">
                    <label class="flex items-center text-[#5E5852] cursor-pointer">
                        <input type="checkbox" name="remember" class="rounded border-[#D5CBC1] text-[#C85A32] focus:ring-[#C85A32]">
                        <span class="ml-2 font-medium">Ghi nhớ phiên làm việc</span>
                    </label>
                    <span class="text-gray-400">IP Audit Enabled</span>
                </div>

                <button type="submit"
                        class="w-full py-3 px-4 rounded-lg bg-[#C85A32] hover:bg-[#B04C27] text-white text-sm font-semibold tracking-wide shadow-md transition-colors focus:outline-hidden focus:ring-2 focus:ring-offset-2 focus:ring-[#C85A32]">
                    Đăng nhập Hệ thống
                </button>
            </form>

            <div class="mt-6 pt-6 border-t border-gray-100 text-center">
                <p class="text-[11px] text-gray-400">
                    Bảo mật 3 lớp RBAC &bull; Mọi hành vi đăng nhập đều được ghi nhật ký bất biến.
                </p>
            </div>
        </div>

        <div class="mt-6 text-center text-xs text-[#84664C]">
            &copy; 2026 Retro Market (izithrift) &bull; Phase 08 Admin Foundation
        </div>
    </div>
</body>
</html>
