import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/base_view_model.dart';
import '../models/user_address_model.dart';
import '../repositories/address_repository.dart';

/// AddressViewModel manages customer address book operations (M-PF-03, M-PF-04)
class AddressViewModel extends BaseViewModel<List<UserAddressModel>> {
  final AddressRepository addressRepository;

  List<UserAddressModel> _addresses = [];

  AddressViewModel({required this.addressRepository});

  List<UserAddressModel> get addresses => _addresses;

  UserAddressModel? get defaultAddress {
    try {
      return _addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  /// Loads list of saved delivery addresses
  Future<void> loadAddresses() async {
    await runCatching(
      () async {
        _addresses = await addressRepository.listAddresses();
        return _addresses;
      },
      isEmpty: (list) => list.isEmpty,
      emptyMessage: 'Bạn chưa có địa chỉ nhận hàng nào.',
    );
  }

  /// Adds a new delivery address and maintains single default address invariant
  Future<UserAddressModel?> createAddress({
    required String recipientName,
    required String recipientPhone,
    required String provinceCity,
    required String districtWard,
    required String streetAddress,
    bool isDefault = false,
  }) async {
    UserAddressModel? created;
    await runCatching(() async {
      created = await addressRepository.createAddress(
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        provinceCity: provinceCity,
        districtWard: districtWard,
        streetAddress: streetAddress,
        isDefault: isDefault,
      );

      if (isDefault) {
        _addresses = _addresses.map((a) => a.copyWith(isDefault: false)).toList();
      }
      _addresses.add(created!);
      return _addresses;
    });
    return created;
  }

  /// Updates an existing address
  Future<UserAddressModel?> updateAddress({
    required int id,
    required String recipientName,
    required String recipientPhone,
    required String provinceCity,
    required String districtWard,
    required String streetAddress,
    bool isDefault = false,
  }) async {
    UserAddressModel? updated;
    await runCatching(() async {
      updated = await addressRepository.updateAddress(
        id: id,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        provinceCity: provinceCity,
        districtWard: districtWard,
        streetAddress: streetAddress,
        isDefault: isDefault,
      );

      _addresses = _addresses.map((a) {
        if (a.id == id) {
          return updated!;
        } else if (isDefault) {
          return a.copyWith(isDefault: false);
        }
        return a;
      }).toList();

      return _addresses;
    });
    return updated;
  }

  /// Removes an address from the address book
  Future<bool> deleteAddress(int id) async {
    bool deleted = false;
    await runCatching(() async {
      deleted = await addressRepository.deleteAddress(id);
      if (deleted) {
        _addresses.removeWhere((a) => a.id == id);
      }
      return _addresses;
    });
    return deleted;
  }
}

/// Riverpod provider for AddressViewModel
final addressViewModelProvider = ChangeNotifierProvider<AddressViewModel>((ref) {
  final addressRepo = ref.watch(addressRepositoryProvider);
  return AddressViewModel(addressRepository: addressRepo);
});
