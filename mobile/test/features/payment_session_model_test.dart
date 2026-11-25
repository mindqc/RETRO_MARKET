import 'package:flutter_test/flutter_test.dart';
import 'package:izithrift/features/cart/models/payment_session_model.dart';

void main() {
  group('PaymentSessionModel.fromJson', () {
    test('parses the failed payment and the new retry payment separately', () {
      final session = PaymentSessionModel.fromJson({
        'failed_payment': {
          'id': 41,
          'payment_reference': 'PAY-OLD',
          'order_id': 12,
          'amount': 125000,
          'qr_payload': 'RETRO_MARKET_DEMO|PAYMENT:41',
          'status': 'FAILED',
          'failure_reason': 'Demo bank rejected the transaction',
          'expires_at': '2026-11-18T10:30:00+07:00',
        },
        'new_payment': {
          'id': 42,
          'payment_reference': 'PAY-NEW',
          'order_id': 12,
          'amount': 125000,
          'qr_payload': 'RETRO_MARKET_DEMO|PAYMENT:42',
          'status': 'PENDING',
          'expires_at': '2026-11-18T10:45:00+07:00',
        },
        'order': {
          'id': 12,
          'order_code': 'ORD-12',
          'total_amount': 125000,
          'order_status': 'PENDING_PAYMENT',
          'escrow_status': 'PENDING',
        },
      });

      expect(session.paymentId, 41);
      expect(session.paymentStatus, 'FAILED');
      expect(session.failureReason, 'Demo bank rejected the transaction');
      expect(session.retrySession, isNotNull);
      expect(session.retrySession!.paymentId, 42);
      expect(session.retrySession!.paymentCode, 'PAY-NEW');
      expect(session.retrySession!.paymentStatus, 'PENDING');
      expect(session.retrySession!.orderId, 12);
      expect(
        session.retrySession!.qrDisplayData,
        'RETRO_MARKET_DEMO|PAYMENT:42',
      );
    });

    test(
      'does not fabricate a VietQR URL when the backend omits QR payload',
      () {
        final session = PaymentSessionModel.fromJson({
          'payment': {
            'id': 9,
            'payment_reference': 'PAY-9',
            'order_id': 3,
            'amount': 99000,
            'status': 'PENDING',
          },
          'order': {
            'id': 3,
            'order_code': 'ORD-3',
            'total_amount': 99000,
            'order_status': 'PENDING_PAYMENT',
            'escrow_status': 'PENDING',
          },
        });

        expect(session.qrCodeUrl, isNull);
        expect(session.qrDisplayData, contains('RETRO_MARKET_DEMO'));
        expect(session.qrDisplayData, contains('PAYMENT:9'));
      },
    );

    test('normalizes escrow held status', () {
      final session = PaymentSessionModel.fromJson({
        'payment': {
          'id': 10,
          'payment_reference': 'PAY-10',
          'order_id': 4,
          'amount': 50000,
          'status': 'PAID',
        },
        'order': {
          'id': 4,
          'order_code': 'ORD-4',
          'total_amount': 50000,
          'order_status': 'PAID',
          'escrow_status': 'ESCROW_HELD',
        },
      });

      expect(session.escrowStatus, 'HELD');
    });
  });
}
