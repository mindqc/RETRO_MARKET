@if (session('success'))
    <div class="mb-6 flex items-center p-4 bg-emerald-50 border-l-4 border-emerald-600 rounded-r shadow-xs text-emerald-900 text-sm">
        <svg class="w-5 h-5 mr-3 text-emerald-600 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
        </svg>
        <span>{{ session('success') }}</span>
    </div>
@endif

@if (session('error'))
    <div class="mb-6 flex items-center p-4 bg-rose-50 border-l-4 border-rose-600 rounded-r shadow-xs text-rose-900 text-sm">
        <svg class="w-5 h-5 mr-3 text-rose-600 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
        </svg>
        <span>{{ session('error') }}</span>
    </div>
@endif

@if (session('warning'))
    <div class="mb-6 flex items-center p-4 bg-amber-50 border-l-4 border-amber-600 rounded-r shadow-xs text-amber-900 text-sm">
        <svg class="w-5 h-5 mr-3 text-amber-600 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
        </svg>
        <span>{{ session('warning') }}</span>
    </div>
@endif
