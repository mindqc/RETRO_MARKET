<!DOCTYPE html>
<html lang="vi" class="h-full bg-[#F4F5F7]">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>Đăng nhập Quản trị | izithrift</title>

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="h-full font-sans antialiased bg-[#F4F5F7] text-[#1E2421] flex items-center justify-center p-4">
    <div class="max-w-md w-full">
        <!-- Logo and Brand -->
        <div class="text-center mb-7">
            <div class="inline-flex items-center justify-center mb-3">
                @include('partials.izithrift-logo', ['size' => 48, 'showWordmark' => true])
            </div>
            <p class="mt-1.5 text-sm text-[#64706A] font-medium">Hệ thống Quản trị &amp; Điều hành Sàn Đồ Si &amp; Đấu giá</p>
        </div>

        <!-- Login Card -->
        <div class="bg-white rounded-2xl shadow-lg shadow-[#174D38]/5 border border-[#E2E6E9] p-8">
            <div class="mb-6">
                <h2 class="text-xl font-bold text-[#174D38] tracking-tight">Đăng nhập nhân sự</h2>
                <p class="text-xs text-[#64706A] mt-1">Truy cập dành riêng cho Admin, Moderator và Support Staff</p>
            </div>

            <!-- Flash Alerts -->
            @if (session('success'))
                <div class="mb-5 p-3.5 bg-emerald-50 border-l-4 border-[#174D38] rounded-r text-emerald-900 text-xs font-medium">
                    {{ session('success') }}
                </div>
            @endif

            @if ($errors->any())
                <div class="mb-5 p-3.5 bg-rose-50 border-l-4 border-[#C65335] rounded-r text-rose-900 text-xs font-medium">
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
                    <label for="email" class="block text-xs font-semibold uppercase tracking-wider text-[#4B5752] mb-1.5">
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
                           class="w-full px-3.5 py-2.5 rounded-xl border border-[#D8DFE3] focus:ring-2 focus:ring-[#174D38] focus:border-[#174D38] text-sm text-[#1E2421] placeholder-gray-400 transition-colors bg-[#F9FAFB]">
                </div>

                <div>
                    <label for="password" class="block text-xs font-semibold uppercase tracking-wider text-[#4B5752] mb-1.5">
                        Mật khẩu
                    </label>
                    <input type="password"
                           id="password"
                           name="password"
                           required
                           autocomplete="current-password"
                           placeholder="••••••••••••"
                           class="w-full px-3.5 py-2.5 rounded-xl border border-[#D8DFE3] focus:ring-2 focus:ring-[#174D38] focus:border-[#174D38] text-sm text-[#1E2421] placeholder-gray-400 transition-colors bg-[#F9FAFB]">
                </div>

                <div class="flex items-center justify-between text-xs">
                    <label class="flex items-center text-[#4B5752] cursor-pointer">
                        <input type="checkbox" name="remember" class="rounded border-[#D8DFE3] text-[#174D38] focus:ring-[#174D38]">
                        <span class="ml-2 font-medium">Ghi nhớ phiên làm việc</span>
                    </label>
                    <span class="text-[#8B9792]">IP Audit Enabled</span>
                </div>

                <button type="submit"
                        class="w-full py-3 px-4 rounded-xl bg-[#C65335] hover:bg-[#AE4529] text-white text-sm font-semibold tracking-wide shadow-md shadow-[#C65335]/20 transition-colors focus:outline-hidden focus:ring-2 focus:ring-offset-2 focus:ring-[#C65335] cursor-pointer">
                    Đăng nhập Hệ thống
                </button>
            </form>

            <div class="mt-6 pt-6 border-t border-[#EDF0F2] text-center">
                <p class="text-[11px] text-[#8B9792]">
                    Bảo mật 3 lớp RBAC &bull; Mọi hành vi đăng nhập đều được ghi nhật ký bất biến.
                </p>
            </div>
        </div>

        <div class="mt-6 text-center text-xs text-[#64706A]">
            &copy; 2026 izithrift (Retro Market) &bull; Admin Control Panel
        </div>
    </div>
</body>
</html>
