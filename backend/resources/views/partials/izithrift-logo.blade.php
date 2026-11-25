@php
    $size = $size ?? 34;
    $dark = $dark ?? false;
    $showTagline = $showTagline ?? false;
    $tagline = $tagline ?? 'Đồ si tuyển chọn';
@endphp

<span class="inline-flex items-center gap-2.5 select-none">
    <img src="{{ asset('images/izithrift-logo.svg') }}"
         alt="izithrift"
         width="{{ $size }}"
         height="{{ $size }}"
         class="shrink-0 rounded-xl shadow-xs"
         style="width: {{ $size }}px; height: {{ $size }}px;">
    <span class="flex flex-col leading-none">
        <span class="inline-flex items-baseline font-extrabold tracking-tight {{ $dark ? 'text-white' : 'text-[#174D38]' }}"
              style="font-size: {{ max(17, intval($size * 0.6)) }}px;">
            izithrift<span class="inline-block w-1.5 h-1.5 rounded-full bg-[#C65335] ml-0.5"></span>
        </span>
        @if ($showTagline)
            <span class="text-[10.5px] font-semibold tracking-wide mt-0.5 {{ $dark ? 'text-[#D6AE55]' : 'text-[#6B7280]' }}">
                {{ $tagline }}
            </span>
        @endif
    </span>
</span>
