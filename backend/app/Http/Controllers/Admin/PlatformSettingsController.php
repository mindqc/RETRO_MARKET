<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\PlatformSetting;
use App\Services\Governance\PlatformConfigService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class PlatformSettingsController extends Controller
{
    public function __construct(
        protected PlatformConfigService $platformConfigService
    ) {}

    /**
     * Display Platform Settings (Screen A-ST-01).
     */
    public function index(Request $request): View
    {
        if (!$request->user()?->isAdmin()) {
            abort(403, 'Chỉ Quản trị viên (Admin) mới có quyền truy cập cấu hình nền tảng.');
        }

        $allSettings = PlatformSetting::with('updater')->orderBy('key')->get()->keyBy('key');

        $groups = [
            'fees' => [
                'title' => 'Biểu phí Sàn & Doanh thu (DEC-04)',
                'description' => 'Tham số tính Phí bảo vệ người mua, Phí vận chuyển và Tỷ lệ hoa hồng người bán.',
                'keys' => [
                    'protection_fee_rate',
                    'protection_fixed_fee',
                    'shipping_fee_default',
                    'seller_commission_rate',
                ],
            ],
            'auctions' => [
                'title' => 'Cơ chế Đấu giá & Chống Bắn tỉa Anti-Sniping (BR-AU-04)',
                'description' => 'Khung giờ kích hoạt và thời lượng gia hạn phiên đấu giá tự động khi có giá đặt phút chót.',
                'keys' => [
                    'anti_sniping_trigger_window_production_sec',
                    'anti_sniping_extend_duration_production_sec',
                    'anti_sniping_trigger_window_demo_sec',
                    'anti_sniping_extend_duration_demo_sec',
                ],
            ],
            'timers' => [
                'title' => 'Hạn Thanh toán Đấu giá & Tự động Giải ngân Escrow (BR-OR-05 / ADR-05)',
                'description' => 'Thời gian hết hạn thanh toán cho người thắng đấu giá và thời gian tự động hoàn tất đơn sau khi giao.',
                'keys' => [
                    'auction_payment_window_production_sec',
                    'auction_payment_window_demo_sec',
                    'auto_complete_window_production_sec',
                    'auto_complete_window_demo_sec',
                ],
            ],
        ];

        return view('admin.settings.index', compact('allSettings', 'groups'));
    }

    /**
     * Update platform settings (Admin only, DEC-08-02).
     */
    public function update(Request $request): RedirectResponse
    {
        if (!$request->user()?->isAdmin()) {
            abort(403, 'Chỉ Quản trị viên (Admin) mới có quyền cập nhật cấu hình nền tảng.');
        }

        $validated = $request->validate([
            'settings' => 'required|array',
            'reason' => 'required|string|min:5|max:1000',
        ], [
            'settings.required' => 'Vui lòng cung cấp tham số cần cập nhật.',
            'reason.required' => 'Vui lòng nhập lý do điều chỉnh cấu hình (bắt buộc).',
            'reason.min' => 'Lý do điều chỉnh cấu hình phải có ít nhất 5 ký tự.',
        ]);

        try {
            $updatedCount = 0;
            foreach ($validated['settings'] as $key => $val) {
                // If setting value is different, update it
                $current = PlatformSetting::find($key);
                if ($current && (string) $current->value !== (string) $val) {
                    $this->platformConfigService->updateSetting(
                        $request->user(),
                        $key,
                        $val,
                        $validated['reason']
                    );
                    $updatedCount++;
                }
            }

            return redirect()->route('admin.settings.index')
                ->with('success', "Đã cập nhật thành công {$updatedCount} tham số cấu hình nền tảng.");
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', $e->getMessage())
                ->withInput();
        }
    }
}
