import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../models/user_address_model.dart';

/// AddressRepository manages customer delivery addresses in address book (M-PF-03, M-PF-04)
class AddressRepository {
  final DioClient dioClient;

  AddressRepository({required this.dioClient});

  /// Lists all saved shipping addresses for current user
  Future<List<UserAddressModel>> listAddresses() async {
    final response = await dioClient.get(ApiEndpoints.addresses);
    final rawList = response.data?['data'];
    if (rawList is List) {
      return rawList
          .map((item) => UserAddressModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Creates a new delivery address
  Future<UserAddressModel> createAddress({
    required String recipientName,
    required String recipientPhone,
    required String provinceCity,
    required String districtWard,
    required String streetAddress,
    bool isDefault = false,
  }) async {
    final response = await dioClient.post(
      ApiEndpoints.addresses,
      data: {
        'recipient_name': recipientName.trim(),
        'recipient_phone': recipientPhone.trim(),
        'province_city': provinceCity.trim(),
        'district_ward': districtWard.trim(),
        'street_address': streetAddress.trim(),
        'is_default': isDefault,
      },
    );
    final data = response.data?['data'] as Map<String, dynamic>;
    return UserAddressModel.fromJson(data);
  }

  /// Updates an existing shipping address
  Future<UserAddressModel> updateAddress({
    required int id,
    required String recipientName,
    required String recipientPhone,
    required String provinceCity,
    required String districtWard,
    required String streetAddress,
    bool isDefault = false,
  }) async {
    final response = await dioClient.put(
      ApiEndpoints.addressDetail(id),
      data: {
        'recipient_name': recipientName.trim(),
        'recipient_phone': recipientPhone.trim(),
        'province_city': provinceCity.trim(),
        'district_ward': districtWard.trim(),
        'street_address': streetAddress.trim(),
        'is_default': isDefault,
      },
    );
    final data = response.data?['data'] as Map<String, dynamic>;
    return UserAddressModel.fromJson(data);
  }

  /// Deletes a shipping address
  Future<bool> deleteAddress(int id) async {
    final response = await dioClient.delete(ApiEndpoints.addressDetail(id));
    return response.data?['success'] == true;
  }
}

/// Riverpod provider for AddressRepository
final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AddressRepository(dioClient: dioClient);
});
