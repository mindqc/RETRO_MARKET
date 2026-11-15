/// Standardized Error Codes mapped from RETRO MARKET Backend API
enum ErrorCodeEnum {
  unauthenticated('UNAUTHENTICATED'),
  invalidCredentials('INVALID_CREDENTIALS'),
  invalidCurrentPassword('INVALID_CURRENT_PASSWORD'),
  accountSuspended('ACCOUNT_SUSPENDED'),
  selfTransactionForbidden('SELF_TRANSACTION_FORBIDDEN'),
  rolePermissionDenied('ROLE_PERMISSION_DENIED'),
  resourceNotAvailable('RESOURCE_NOT_AVAILABLE'),
  auctionOutbidConflict('AUCTION_OUTBID_CONFLICT'),
  productOutOfStock('PRODUCT_OUT_OF_STOCK'),
  invalidStateTransition('INVALID_STATE_TRANSITION'),
  validationError('VALIDATION_ERROR'),
  tooManyRequests('TOO_MANY_REQUESTS'),
  networkError('NETWORK_ERROR'),
  unknownError('UNKNOWN_ERROR');

  final String code;
  const ErrorCodeEnum(this.code);

  /// Resolves string error code into ErrorCodeEnum
  static ErrorCodeEnum fromCode(String? rawCode) {
    if (rawCode == null || rawCode.isEmpty) {
      return ErrorCodeEnum.unknownError;
    }
    final normalized = rawCode.toUpperCase().trim();
    for (final value in ErrorCodeEnum.values) {
      if (value.code == normalized) {
        return value;
      }
    }
    return ErrorCodeEnum.unknownError;
  }
}
