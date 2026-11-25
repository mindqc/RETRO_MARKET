import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:izithrift/features/cart/models/payment_session_model.dart';
import 'package:izithrift/features/cart/screens/mock_qr_payment_screen.dart';
import 'package:izithrift/features/cart/screens/payment_success_screen.dart';
import 'package:izithrift/features/cart/screens/payment_failure_screen.dart';

void main() {
  group('Batch 1 QR Payment Targeted Smoke Tests (A - E)', () {
    // A. Place order -> QR screen displays generated QR.
    testWidgets(
      'Smoke Test A: MockQrPaymentScreen displays generated QR via QrImageView',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final session = PaymentSessionModel(
          paymentId: 101,
          paymentCode: 'PAY-2026-TEST01',
          orderId: 501,
          orderCode: 'ORD-2026-TEST01',
          amount: 350000.0,
          qrPayload: 'IZITHRIFT_QR|ORD-2026-TEST01|350000.00',
          transferContent: 'RETRO MARKET ORD-2026-TEST01',
          paymentStatus: 'PENDING',
          orderStatus: 'PENDING_PAYMENT',
          escrowStatus: 'PENDING',
          paymentExpiresAt: DateTime.now().add(const Duration(minutes: 30)),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: MockQrPaymentScreen(
                paymentId: 101,
                initialSession: session,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify QR visual container and QrImageView
        expect(find.byType(QrImageView), findsOneWidget);
        expect(find.text('350.000đ'), findsOneWidget);
        expect(find.text('PAY-2026-TEST01'), findsOneWidget);
      },
    );

    // B. QR screen clearly states demo-only.
    testWidgets(
      'Smoke Test B: MockQrPaymentScreen clearly states demo-only and no fictitious bank',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final session = PaymentSessionModel(
          paymentId: 101,
          paymentCode: 'PAY-2026-TEST01',
          orderId: 501,
          orderCode: 'ORD-2026-TEST01',
          amount: 350000.0,
          qrPayload: 'IZITHRIFT_QR|ORD-2026-TEST01|350000.00',
          transferContent: 'RETRO MARKET ORD-2026-TEST01',
          paymentStatus: 'PENDING',
          orderStatus: 'PENDING_PAYMENT',
          escrowStatus: 'PENDING',
          paymentExpiresAt: DateTime.now().add(const Duration(minutes: 30)),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: MockQrPaymentScreen(
                paymentId: 101,
                initialSession: session,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify explicit demo notice
        expect(
          find.text(
            'QR mô phỏng RETRO MARKET. Không phải VietQR và không dùng để chuyển khoản thật.',
          ),
          findsOneWidget,
        );
        expect(
          find.text('CHẾ ĐỘ TRÌNH DIỄN • THANH TOÁN MÔ PHỎNG'),
          findsOneWidget,
        );

        // Verify fictitious beneficiary bank info is NOT present
        expect(find.textContaining('VietinBank'), findsNothing);
        expect(find.textContaining('10988776655'), findsNothing);
        expect(find.textContaining('IZITHRIFT ESCROW TRUST'), findsNothing);
      },
    );

    // C. Simulate success -> Order PAID, Escrow HELD.
    testWidgets(
      'Smoke Test C: PaymentSuccessScreen displays Order PAID and Escrow HELD status',
      (tester) async {
        final successSession = PaymentSessionModel(
          paymentId: 101,
          paymentCode: 'PAY-2026-TEST01',
          orderId: 501,
          orderCode: 'ORD-2026-TEST01',
          amount: 350000.0,
          paymentStatus: 'PAID',
          orderStatus: 'PAID',
          escrowStatus: 'HELD',
          paidAt: DateTime.now(),
          paymentExpiresAt: DateTime.now().add(const Duration(minutes: 30)),
          transferContent: 'RETRO MARKET ORD-2026-TEST01',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: PaymentSuccessScreen(paymentId: 101, session: successSession),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Thanh toán thành công!'), findsOneWidget);
        expect(
          find.text('Khoản thanh toán đã được ghi nhận và giữ trong Escrow.'),
          findsOneWidget,
        );
        expect(
          find.text('Đã thanh toán'),
          findsOneWidget,
        ); // StatusPillBadge for PAID
        expect(
          find.text('Đang giữ ký quỹ'),
          findsOneWidget,
        ); // StatusPillBadge for HELD
      },
    );

    // D. Simulate failure -> display failure reason.
    testWidgets(
      'Smoke Test D: PaymentFailureScreen displays failure reason from backend',
      (tester) async {
        final failureSession = PaymentSessionModel(
          paymentId: 101,
          paymentCode: 'PAY-2026-OLD',
          orderId: 501,
          orderCode: 'ORD-2026-TEST01',
          amount: 350000.0,
          paymentStatus: 'FAILED',
          orderStatus: 'PENDING_PAYMENT',
          escrowStatus: 'PENDING',
          failureReason:
              'Giao dịch bị từ chối bởi ngân hàng mô phỏng do lỗi kết nối.',
          paymentExpiresAt: DateTime.now().add(const Duration(minutes: 30)),
          transferContent: 'RETRO MARKET ORD-2026-TEST01',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: PaymentFailureScreen(paymentId: 101, session: failureSession),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Thanh toán chưa thành công'), findsOneWidget);
        expect(
          find.text(
            'Giao dịch bị từ chối bởi ngân hàng mô phỏng do lỗi kết nối.',
          ),
          findsOneWidget,
        );
      },
    );

    // E. Retry -> use new_payment.id, not failed_payment.id.
    testWidgets(
      'Smoke Test E: Retry button presents fresh payment session info (new_payment.id)',
      (tester) async {
        // Backend failure response shape parsed into PaymentSessionModel with retrySession
        final failureSessionWithRetry = PaymentSessionModel.fromJson({
          'failed_payment': {
            'id': 101,
            'payment_reference': 'PAY-2026-FAILED-101',
            'order_id': 501,
            'amount': 350000.0,
            'status': 'FAILED',
            'failure_reason': 'Mô phỏng thanh toán thất bại.',
          },
          'new_payment': {
            'id': 202,
            'payment_reference': 'PAY-2026-NEW-202',
            'order_id': 501,
            'amount': 350000.0,
            'status': 'PENDING',
            'qr_payload': 'IZITHRIFT_QR|ORD-2026-TEST01|350000.00',
          },
          'order': {
            'id': 501,
            'order_code': 'ORD-2026-TEST01',
            'total_amount': 350000.0,
            'order_status': 'PENDING_PAYMENT',
            'escrow_status': 'PENDING',
          },
        });

        expect(failureSessionWithRetry.paymentId, 101);
        expect(failureSessionWithRetry.retrySession, isNotNull);
        expect(failureSessionWithRetry.retrySession!.paymentId, 202);
        expect(
          failureSessionWithRetry.retrySession!.paymentCode,
          'PAY-2026-NEW-202',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: PaymentFailureScreen(
              paymentId: 101,
              session: failureSessionWithRetry,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Button label must indicate creating new code
        expect(find.text('Tạo mã thanh toán mới'), findsOneWidget);
        // New payment reference must be rendered
        expect(find.text('Phiên mới: PAY-2026-NEW-202'), findsOneWidget);
      },
    );
  });
}
