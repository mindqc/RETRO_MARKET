@if ($errors->any())
    <div class="mb-6 p-4 bg-rose-50 border-l-4 border-rose-600 rounded-r shadow-xs text-rose-900 text-sm">
        <div class="flex items-center mb-2 font-semibold text-rose-800">
            <svg class="w-5 h-5 mr-2 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            <span>Đã xảy ra lỗi, vui lòng kiểm tra lại:</span>
        </div>
        <ul class="list-disc list-inside space-y-1 ml-5">
            @foreach ($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
@endif
