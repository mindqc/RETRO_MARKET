import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/user_address_model.dart';
import '../viewmodels/address_view_model.dart';

/// M-PF-04: Add / Edit Shipping Address Screen
class AddEditAddressScreen extends ConsumerStatefulWidget {
  final UserAddressModel? addressToEdit;

  const AddEditAddressScreen({super.key, this.addressToEdit});

  @override
  ConsumerState<AddEditAddressScreen> createState() =>
      _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();
  final _streetController = TextEditingController();

  bool _isDefault = false;
  bool _isSubmitting = false;
  ApiException? _lastApiException;

  bool get _isEditMode => widget.addressToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final addr = widget.addressToEdit!;
      _nameController.text = addr.recipientName;
      _phoneController.text = addr.recipientPhone;
      _provinceController.text = addr.provinceCity;
      _districtController.text = addr.districtWard;
      _streetController.text = addr.streetAddress;
      _isDefault = addr.isDefault;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  /// Validates standard 10-digit Vietnamese mobile phone number
  String? _validateVietnamesePhone(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại người nhận.';
    }
    final normalized = val.trim().replaceAll(' ', '').replaceAll('.', '');
    final regex = RegExp(r'^(03|05|07|08|09)[0-9]{8}$');
    if (!regex.hasMatch(normalized)) {
      return 'Số điện thoại không hợp lệ (Phải gồm 10 số bắt đầu bằng 03, 05, 07, 08, 09).';
    }
    return null;
  }

  Future<void> _submitAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _lastApiException = null;
    });

    final addressVm = ref.read(addressViewModelProvider);
    final normalizedPhone =
        _phoneController.text.trim().replaceAll(' ', '').replaceAll('.', '');

    try {
      if (_isEditMode) {
        await addressVm.updateAddress(
          id: widget.addressToEdit!.id,
          recipientName: _nameController.text.trim(),
          recipientPhone: normalizedPhone,
          provinceCity: _provinceController.text.trim(),
          districtWard: _districtController.text.trim(),
          streetAddress: _streetController.text.trim(),
          isDefault: _isDefault,
        );
      } else {
        await addressVm.createAddress(
          recipientName: _nameController.text.trim(),
          recipientPhone: normalizedPhone,
          provinceCity: _provinceController.text.trim(),
          districtWard: _districtController.text.trim(),
          streetAddress: _streetController.text.trim(),
          isDefault: _isDefault,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.pineDeep,
            content: Text(
              _isEditMode
                  ? 'Cập nhật địa chỉ thành công!'
                  : 'Thêm địa chỉ mới thành công!',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException) {
        setState(() => _lastApiException = e);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.priceCrimson,
            content: Text('Không thể lưu địa chỉ: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        title: Text(_isEditMode ? 'Chỉnh sửa địa chỉ' : 'Thêm địa chỉ mới'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_lastApiException != null) ...[
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.spaceMd),
                    decoration: BoxDecoration(
                      color: AppColors.priceCrimsonSoft,
                      borderRadius: DesignTokens.borderRadiusMd,
                      border: Border.all(color: AppColors.priceCrimsonBorder),
                    ),
                    child: Text(
                      _lastApiException!.message,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.priceCrimson,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceLg),
                ],

                Container(
                  padding: const EdgeInsets.all(DesignTokens.spaceLg),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: DesignTokens.borderRadiusBanner,
                    border: Border.all(color: AppColors.borderWarm),
                    boxShadow: DesignTokens.cardElevation,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recipient Name
                      Text('Tên người nhận', style: AppTypography.labelMedium),
                      const SizedBox(height: DesignTokens.spaceXs),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Họ và tên người nhận hàng',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Vui lòng nhập tên người nhận.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: DesignTokens.spaceLg),

                      // Recipient Phone
                      Text('Số điện thoại', style: AppTypography.labelMedium),
                      const SizedBox(height: DesignTokens.spaceXs),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '0901234567',
                          prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        ),
                        validator: _validateVietnamesePhone,
                      ),
                      const SizedBox(height: DesignTokens.spaceLg),

                      // Province / City
                      Text(
                        'Tỉnh / Thành phố',
                        style: AppTypography.labelMedium,
                      ),
                      const SizedBox(height: DesignTokens.spaceXs),
                      TextFormField(
                        controller: _provinceController,
                        decoration: const InputDecoration(
                          hintText:
                              'Ví dụ: TP. Hồ Chí Minh, Hà Nội, Đà Nẵng...',
                          prefixIcon: Icon(Icons.map_outlined, size: 20),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Vui lòng nhập Tỉnh/Thành phố.'
                            : null,
                      ),
                      const SizedBox(height: DesignTokens.spaceLg),

                      // District / Ward
                      Text(
                        'Quận / Huyện, Phường / Xã',
                        style: AppTypography.labelMedium,
                      ),
                      const SizedBox(height: DesignTokens.spaceXs),
                      TextFormField(
                        controller: _districtController,
                        decoration: const InputDecoration(
                          hintText: 'Ví dụ: Phường Bến Nghé, Quận 1',
                          prefixIcon:
                              Icon(Icons.location_city_outlined, size: 20),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Vui lòng nhập Quận/Huyện, Phường/Xã.'
                            : null,
                      ),
                      const SizedBox(height: DesignTokens.spaceLg),

                      // Street Address
                      Text(
                        'Địa chỉ chi tiết (Số nhà, tên đường, tòa nhà)',
                        style: AppTypography.labelMedium,
                      ),
                      const SizedBox(height: DesignTokens.spaceXs),
                      TextFormField(
                        controller: _streetController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Ví dụ: Số 45 Lê Duẩn, Chung cư X...',
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Vui lòng nhập số nhà, tên đường.'
                            : null,
                      ),
                      const SizedBox(height: DesignTokens.spaceLg),

                      // Default Switch
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spaceMd,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWarm,
                          borderRadius: DesignTokens.borderRadiusMd,
                          border: Border.all(color: AppColors.borderWarm),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Đặt làm địa chỉ mặc định',
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Tự động chọn khi thanh toán đơn mua',
                                    style: AppTypography.caption,
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isDefault,
                              activeColor: AppColors.ctaTerracotta,
                              onChanged: (val) =>
                                  setState(() => _isDefault = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spaceXl),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitAddress,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textLight,
                                  ),
                                )
                              : Text(
                                  _isEditMode ? 'Lưu cập nhật' : 'Thêm địa chỉ',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
