<!DOCTYPE html>
<html lang="vi" class="h-full bg-[#F4F5F7]">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>@yield('title', 'Admin Dashboard') | izithrift</title>
    <link rel="icon" type="image/svg+xml" href="{{ asset('images/izithrift-logo.svg') }}">

    <!-- Google Fonts: Be Vietnam Pro -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="h-full font-sans text-[#231F20] antialiased bg-[#F4F5F7] flex overflow-hidden">
    <!-- Sidebar Navigation -->
    @include('admin.partials.sidebar')

    <!-- Main Content Area -->
    <div class="flex-1 flex flex-col min-w-0 overflow-hidden">
        <!-- Topbar -->
        @include('admin.partials.topbar')

        <!-- Page Body -->
        <main class="flex-1 overflow-y-auto p-6 lg:p-8">
            <div class="max-w-7xl mx-auto space-y-6">
                <!-- Session Alerts & Validation Errors -->
                @include('admin.partials.alerts')
                @include('admin.partials.errors')

                <!-- Yield Content -->
                @yield('content')
            </div>
        </main>
    </div>

    @stack('scripts')
</body>
</html>
