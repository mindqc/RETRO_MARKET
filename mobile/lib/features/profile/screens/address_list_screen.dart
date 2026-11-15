import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/state_feedback_views.dart';
import '../models/user_address_model.dart';
import '../viewmodels/address_view_model.dart';
import 'add_edit_address_screen.dart';

/// M-PF-03: Address Book List Screen
class AddressListScreen extends ConsumerStatefulWidget {
  const AddressListScreen({super.key});

  @override
  ConsumerState<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends ConsumerState<AddressListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addressViewModelProvider).loadAddresses();
    });
  }

  void _confirmDelete(UserAddressModel address) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa địa chỉ?'),
        content: Text('Bạn có chắc chắn muốn xóa địa chỉ "${address.streetAddress}" khỏi sổ địa chỉ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusDanger),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(addressViewModelProvider).deleteAddress(address.id);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressVm = ref.watch(addressViewModelProvider);
    final addresses = addressVm.addresses;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Sổ địa chỉ nhận hàng'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryTerracotta,
        foregroundColor: AppColors.textLight,
        icon: const Icon(Icons.add),
        label: const Text('Thêm địa chỉ mới'),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEditAddressScreen()),
          );
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryTerracotta,
          onRefresh: () => ref.read(addressViewModelProvider).loadAddresses(),
          child: addressVm.state.isLoading && addresses.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryTerracotta),
                )
              : addresses.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: RetroEmptyStateView(
                          icon: Icons.location_off_outlined,
                          title: 'Chưa có địa chỉ nhận hàng',
                          message: 'Thêm địa chỉ giao nhận để sẵn sàng chốt đơn mua đồ vintage.',
                          actionLabel: 'Thêm địa chỉ ngay',
                          onAction: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AddEditAddressScreen()),
                            );
                          },
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(
                        left: DesignTokens.spaceLg,
                        right: DesignTokens.spaceLg,
                        top: DesignTokens.spaceLg,
                        bottom: 80,
                      ),
                      itemCount: addresses.length,
                      separatorBuilder: (_, _) => const SizedBox(height: DesignTokens.spaceMd),
                      itemBuilder: (context, index) {
                        final item = addresses[index];
                        return _buildAddressCard(item);
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(UserAddressModel address) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: address.isDefault ? AppColors.primaryTerracotta : AppColors.borderWarm,
          width: address.isDefault ? 1.5 : 1.0,
        ),
        boxShadow: DesignTokens.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      address.recipientName,
                      style: AppTypography.headingSmall.copyWith(fontSize: 16),
                    ),
                    const SizedBox(width: DesignTokens.spaceSm),
                    Text(
                      address.recipientPhone,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF0EB),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                    border: Border.all(color: const Color(0xFFF7CFBE)),
                  ),
                  child: Text(
                    'Mặc định',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryTerracotta,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceSm),
          Text(
            address.fullAddress,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textCharcoal),
          ),
          const SizedBox(height: DesignTokens.spaceMd),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: DesignTokens.spaceSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primaryTerracotta),
                label: const Text('Chỉnh sửa'),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AddEditAddressScreen(addressToEdit: address)),
                  );
                },
              ),
              const SizedBox(width: DesignTokens.spaceSm),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.statusDanger),
                label: Text(
                  'Xóa',
                  style: AppTypography.buttonMedium.copyWith(color: AppColors.statusDanger),
                ),
                onPressed: () => _confirmDelete(address),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
