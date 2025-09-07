import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_ads/src/services/payment_history_service.dart';
import 'package:artbeat_ads/src/models/payment_history_model.dart';

import 'payment_history_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  QueryDocumentSnapshot,
  Query,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PaymentHistoryService Tests', () {
    late PaymentHistoryService paymentService;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late MockDocumentReference<Map<String, dynamic>> mockDocRef;
    late MockQuery<Map<String, dynamic>> mockQuery;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();

      when(
        mockFirestore.collection('payment_history'),
      ).thenReturn(mockCollection);

      paymentService = PaymentHistoryService(firestore: mockFirestore);
    });

    group('Payment Recording Tests', () {
      test('should record payment successfully', () async {
        when(mockCollection.add(any)).thenAnswer((_) async => mockDocRef);

        await paymentService.recordPayment(
          userId: 'test-user-id',
          adId: 'test-ad-id',
          adTitle: 'Test Ad Campaign',
          amount: 99.99,
          paymentMethod: PaymentMethod.card,
        );

        verify(mockCollection.add(any)).called(1);
      });

      test('should record payment with all optional parameters', () async {
        when(mockCollection.add(any)).thenAnswer((_) async => mockDocRef);

        await paymentService.recordPayment(
          userId: 'test-user-id',
          adId: 'test-ad-id',
          adTitle: 'Test Ad Campaign',
          amount: 149.99,
          currency: 'EUR',
          paymentMethod: PaymentMethod.paypal,
          status: PaymentStatus.completed,
          stripePaymentIntentId: 'pi_test_123',
          metadata: {'campaign_type': 'premium'},
        );

        verify(mockCollection.add(any)).called(1);
      });

      test('should handle payment recording errors', () async {
        when(mockCollection.add(any)).thenThrow(Exception('Database error'));

        expect(
          () => paymentService.recordPayment(
            userId: 'test-user-id',
            adId: 'test-ad-id',
            adTitle: 'Test Ad Campaign',
            amount: 99.99,
            paymentMethod: PaymentMethod.card,
          ),
          throwsException,
        );
      });
    });

    group('Payment Status Update Tests', () {
      test('should update payment status successfully', () async {
        when(mockCollection.doc('payment-id')).thenReturn(mockDocRef);
        when(mockDocRef.update(any)).thenAnswer((_) async => {});

        await paymentService.updatePaymentStatus(
          paymentId: 'payment-id',
          status: PaymentStatus.completed,
        );

        verify(mockDocRef.update(any)).called(1);
      });

      test('should update payment status with failure reason', () async {
        when(mockCollection.doc('payment-id')).thenReturn(mockDocRef);
        when(mockDocRef.update(any)).thenAnswer((_) async => {});

        await paymentService.updatePaymentStatus(
          paymentId: 'payment-id',
          status: PaymentStatus.failed,
          failureReason: 'Insufficient funds',
        );

        verify(mockDocRef.update(any)).called(1);
      });

      test('should update payment status with receipt URL', () async {
        when(mockCollection.doc('payment-id')).thenReturn(mockDocRef);
        when(mockDocRef.update(any)).thenAnswer((_) async => {});

        await paymentService.updatePaymentStatus(
          paymentId: 'payment-id',
          status: PaymentStatus.completed,
          receiptUrl: 'https://example.com/receipt.pdf',
        );

        verify(mockDocRef.update(any)).called(1);
      });

      test('should handle payment status update errors', () async {
        when(mockCollection.doc('payment-id')).thenReturn(mockDocRef);
        when(mockDocRef.update(any)).thenThrow(Exception('Update failed'));

        expect(
          () => paymentService.updatePaymentStatus(
            paymentId: 'payment-id',
            status: PaymentStatus.completed,
          ),
          throwsException,
        );
      });
    });

    group('Refund Recording Tests', () {
      test('should record refund successfully', () async {
        when(mockCollection.doc('payment-id')).thenReturn(mockDocRef);
        when(mockDocRef.update(any)).thenAnswer((_) async => {});

        await paymentService.recordRefund(
          paymentId: 'payment-id',
          refundAmount: 50.0,
          refundReason: 'Customer request',
        );

        verify(mockDocRef.update(any)).called(1);
      });

      test('should handle refund recording errors', () async {
        when(mockCollection.doc('payment-id')).thenReturn(mockDocRef);
        when(mockDocRef.update(any)).thenThrow(Exception('Refund failed'));

        expect(
          () => paymentService.recordRefund(
            paymentId: 'payment-id',
            refundAmount: 50.0,
            refundReason: 'Customer request',
          ),
          throwsException,
        );
      });
    });

    group('Payment Retrieval Tests', () {
      test('should get user payment history', () async {
        final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
        final mockDocSnapshot =
            MockQueryDocumentSnapshot<Map<String, dynamic>>();

        final testPayment = PaymentHistoryModel(
          id: 'payment-id',
          userId: 'test-user-id',
          adId: 'test-ad-id',
          adTitle: 'Test Ad',
          amount: 99.99,
          currency: 'USD',
          paymentMethod: PaymentMethod.card,
          status: PaymentStatus.completed,
          transactionDate: DateTime.now(),
        );

        when(
          mockCollection.where('userId', isEqualTo: 'test-user-id'),
        ).thenReturn(mockQuery);
        when(
          mockQuery.orderBy('transactionDate', descending: true),
        ).thenReturn(mockQuery);
        when(mockQuery.limit(50)).thenReturn(mockQuery);
        when(
          mockQuery.snapshots(),
        ).thenAnswer((_) => Stream.value(mockQuerySnapshot));
        when(mockQuerySnapshot.docs).thenReturn([mockDocSnapshot]);
        when(mockDocSnapshot.data()).thenReturn(testPayment.toFirestore());
        when(mockDocSnapshot.id).thenReturn('payment-id');

        final stream = paymentService.getUserPaymentHistory(
          userId: 'test-user-id',
        );
        final payments = await stream.first;

        expect(payments, hasLength(1));
        expect(payments.first.userId, equals('test-user-id'));
      });

      test('should get user payment history with filters', () async {
        final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();

        when(
          mockCollection.where('userId', isEqualTo: 'test-user-id'),
        ).thenReturn(mockQuery);
        when(
          mockQuery.where('status', isEqualTo: PaymentStatus.completed.value),
        ).thenReturn(mockQuery);
        when(
          mockQuery.where(
            'transactionDate',
            isGreaterThanOrEqualTo: anyNamed('isGreaterThanOrEqualTo'),
          ),
        ).thenReturn(mockQuery);
        when(
          mockQuery.where(
            'transactionDate',
            isLessThanOrEqualTo: anyNamed('isLessThanOrEqualTo'),
          ),
        ).thenReturn(mockQuery);
        when(
          mockQuery.orderBy('transactionDate', descending: true),
        ).thenReturn(mockQuery);
        when(mockQuery.limit(25)).thenReturn(mockQuery);
        when(
          mockQuery.snapshots(),
        ).thenAnswer((_) => Stream.value(mockQuerySnapshot));
        when(mockQuerySnapshot.docs).thenReturn([]);

        final stream = paymentService.getUserPaymentHistory(
          userId: 'test-user-id',
          limit: 25,
          statusFilter: PaymentStatus.completed,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );

        final payments = await stream.first;
        expect(payments, isEmpty);
      });

      test('should handle payment history errors gracefully', () async {
        when(
          mockCollection.where('userId', isEqualTo: 'test-user-id'),
        ).thenThrow(Exception('Query error'));

        final stream = paymentService.getUserPaymentHistory(
          userId: 'test-user-id',
        );
        final payments = await stream.first;

        expect(payments, isEmpty);
      });

      test('should get payment by ID', () async {
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
        final testPayment = PaymentHistoryModel(
          id: 'payment-id',
          userId: 'test-user-id',
          adId: 'test-ad-id',
          adTitle: 'Test Ad',
          amount: 99.99,
          currency: 'USD',
          paymentMethod: PaymentMethod.card,
          status: PaymentStatus.completed,
          transactionDate: DateTime.now(),
        );

        when(mockCollection.doc('payment-id')).thenReturn(mockDocRef);
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(testPayment.toFirestore());
        when(mockDocSnapshot.id).thenReturn('payment-id');

        final payment = await paymentService.getPaymentById('payment-id');

        expect(payment, isNotNull);
        expect(payment!.id, equals('payment-id'));
      });

      test('should return null for non-existent payment', () async {
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

        when(mockCollection.doc('non-existent-id')).thenReturn(mockDocRef);
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(false);

        final payment = await paymentService.getPaymentById('non-existent-id');

        expect(payment, isNull);
      });
    });

    group('Revenue Calculation Tests', () {
      test('should calculate total revenue correctly', () async {
        final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
        final mockDocs = [
          MockQueryDocumentSnapshot<Map<String, dynamic>>(),
          MockQueryDocumentSnapshot<Map<String, dynamic>>(),
        ];

        when(
          mockCollection.where('userId', isEqualTo: 'test-user-id'),
        ).thenReturn(mockQuery);
        when(
          mockQuery.where('status', isEqualTo: PaymentStatus.completed.value),
        ).thenReturn(mockQuery);
        when(
          mockQuery.where('currency', isEqualTo: 'USD'),
        ).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(mockDocs);

        // Mock payment data
        when(
          mockDocs[0].data(),
        ).thenReturn({'amount': 100.0, 'refundAmount': 0.0});
        when(
          mockDocs[1].data(),
        ).thenReturn({'amount': 50.0, 'refundAmount': 10.0});

        final revenue = await paymentService.getUserTotalRevenue(
          userId: 'test-user-id',
        );

        expect(revenue, equals(140.0)); // 100 + (50 - 10)
      });

      test('should handle revenue calculation with date filters', () async {
        final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();

        when(
          mockCollection.where('userId', isEqualTo: 'test-user-id'),
        ).thenReturn(mockQuery);
        when(
          mockQuery.where('status', isEqualTo: PaymentStatus.completed.value),
        ).thenReturn(mockQuery);
        when(
          mockQuery.where('currency', isEqualTo: 'USD'),
        ).thenReturn(mockQuery);
        when(
          mockQuery.where(
            'transactionDate',
            isGreaterThanOrEqualTo: anyNamed('isGreaterThanOrEqualTo'),
          ),
        ).thenReturn(mockQuery);
        when(
          mockQuery.where(
            'transactionDate',
            isLessThanOrEqualTo: anyNamed('isLessThanOrEqualTo'),
          ),
        ).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]);

        final revenue = await paymentService.getUserTotalRevenue(
          userId: 'test-user-id',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );

        expect(revenue, equals(0.0));
      });

      test('should handle revenue calculation errors', () async {
        when(
          mockCollection.where('userId', isEqualTo: 'test-user-id'),
        ).thenThrow(Exception('Query error'));

        final revenue = await paymentService.getUserTotalRevenue(
          userId: 'test-user-id',
        );

        expect(revenue, equals(0.0));
      });
    });

    group('Payment Statistics Tests', () {
      test('should calculate payment statistics correctly', () async {
        final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
        final mockDocs = [
          MockQueryDocumentSnapshot<Map<String, dynamic>>(),
          MockQueryDocumentSnapshot<Map<String, dynamic>>(),
          MockQueryDocumentSnapshot<Map<String, dynamic>>(),
        ];

        when(
          mockCollection.where('userId', isEqualTo: 'test-user-id'),
        ).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(mockDocs);

        // Mock different payment statuses
        final payments = [
          PaymentHistoryModel(
            id: 'payment-1',
            userId: 'test-user-id',
            adId: 'ad-1',
            adTitle: 'Ad 1',
            amount: 100.0,
            currency: 'USD',
            paymentMethod: PaymentMethod.card,
            status: PaymentStatus.completed,
            transactionDate: DateTime.now(),
          ),
          PaymentHistoryModel(
            id: 'payment-2',
            userId: 'test-user-id',
            adId: 'ad-2',
            adTitle: 'Ad 2',
            amount: 50.0,
            currency: 'USD',
            paymentMethod: PaymentMethod.paypal,
            status: PaymentStatus.failed,
            transactionDate: DateTime.now(),
          ),
          PaymentHistoryModel(
            id: 'payment-3',
            userId: 'test-user-id',
            adId: 'ad-3',
            adTitle: 'Ad 3',
            amount: 75.0,
            currency: 'USD',
            paymentMethod: PaymentMethod.card,
            status: PaymentStatus.refunded,
            transactionDate: DateTime.now(),
            refundAmount: 75.0,
          ),
        ];

        for (int i = 0; i < mockDocs.length; i++) {
          when(mockDocs[i].data()).thenReturn(payments[i].toFirestore());
          when(mockDocs[i].id).thenReturn(payments[i].id);
        }

        final stats = await paymentService.getUserPaymentStats(
          userId: 'test-user-id',
        );

        expect(stats['totalPayments'], equals(3));
        expect(stats['successfulPayments'], equals(1));
        expect(stats['failedPayments'], equals(1));
        expect(stats['refundedPayments'], equals(1));
        expect(stats['totalAmount'], equals(225.0));
        expect(stats['refundedAmount'], equals(75.0));
        expect(stats['netRevenue'], equals(150.0));
        expect(stats['successRate'], closeTo(33.33, 0.1));
      });

      test('should handle empty payment statistics', () async {
        final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();

        when(
          mockCollection.where('userId', isEqualTo: 'test-user-id'),
        ).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]);

        final stats = await paymentService.getUserPaymentStats(
          userId: 'test-user-id',
        );

        expect(stats['totalPayments'], equals(0));
        expect(stats['successfulPayments'], equals(0));
        expect(stats['failedPayments'], equals(0));
        expect(stats['refundedPayments'], equals(0));
        expect(stats['totalAmount'], equals(0.0));
        expect(stats['refundedAmount'], equals(0.0));
        expect(stats['netRevenue'], equals(0.0));
        expect(stats['successRate'], equals(0.0));
      });

      test('should handle payment statistics errors', () async {
        when(
          mockCollection.where('userId', isEqualTo: 'test-user-id'),
        ).thenThrow(Exception('Query error'));

        final stats = await paymentService.getUserPaymentStats(
          userId: 'test-user-id',
        );

        expect(stats, isEmpty);
      });
    });

    group('Monthly Summary Tests', () {
      test('should generate monthly payment summary', () async {
        final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();

        when(
          mockCollection.where('userId', isEqualTo: 'test-user-id'),
        ).thenReturn(mockQuery);
        when(
          mockQuery.where(
            'transactionDate',
            isGreaterThanOrEqualTo: anyNamed('isGreaterThanOrEqualTo'),
          ),
        ).thenReturn(mockQuery);
        when(
          mockQuery.where(
            'transactionDate',
            isLessThanOrEqualTo: anyNamed('isLessThanOrEqualTo'),
          ),
        ).thenReturn(mockQuery);
        when(mockQuery.orderBy('transactionDate')).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]);

        final summary = await paymentService.getMonthlyPaymentSummary(
          userId: 'test-user-id',
          monthsBack: 3,
        );

        expect(summary, hasLength(3));
        for (final month in summary) {
          expect(month['month'], isA<String>());
          expect(month['totalAmount'], equals(0.0));
          expect(month['totalPayments'], equals(0));
          expect(month['successfulPayments'], equals(0));
          expect(month['refundedAmount'], equals(0.0));
        }
      });

      test('should handle monthly summary errors', () async {
        when(
          mockCollection.where('userId', isEqualTo: 'test-user-id'),
        ).thenThrow(Exception('Query error'));

        final summary = await paymentService.getMonthlyPaymentSummary(
          userId: 'test-user-id',
          monthsBack: 3,
        );

        expect(summary, isEmpty);
      });
    });

    group('Payment Search Tests', () {
      test('should search payments by ad title', () async {
        final mockTitleQuery = MockQuerySnapshot<Map<String, dynamic>>();
        final mockIntentQuery = MockQuerySnapshot<Map<String, dynamic>>();

        when(
          mockCollection.where('userId', isEqualTo: 'test-user-id'),
        ).thenReturn(mockQuery);
        when(
          mockQuery.where('adTitle', isGreaterThanOrEqualTo: 'Test'),
        ).thenReturn(mockQuery);
        when(
          mockQuery.where('adTitle', isLessThan: 'Testz'),
        ).thenReturn(mockQuery);
        when(mockQuery.limit(20)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockTitleQuery);
        when(mockTitleQuery.docs).thenReturn([]);

        // Mock intent ID search
        when(
          mockCollection.where('userId', isEqualTo: 'test-user-id'),
        ).thenReturn(mockQuery);
        when(
          mockQuery.where('stripePaymentIntentId', isEqualTo: 'Test'),
        ).thenReturn(mockQuery);
        when(mockQuery.limit(20)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockIntentQuery);
        when(mockIntentQuery.docs).thenReturn([]);

        final results = await paymentService.searchPayments(
          userId: 'test-user-id',
          searchTerm: 'Test',
        );

        expect(results, isEmpty);
      });

      test('should handle search errors gracefully', () async {
        when(
          mockCollection.where('userId', isEqualTo: 'test-user-id'),
        ).thenThrow(Exception('Search error'));

        final results = await paymentService.searchPayments(
          userId: 'test-user-id',
          searchTerm: 'Test',
        );

        expect(results, isEmpty);
      });
    });

    group('Receipt Generation Tests', () {
      test('should generate receipt URL', () async {
        final receiptUrl = await paymentService.generateReceipt('payment-id');

        // Should return a placeholder receipt URL
        expect(
          receiptUrl,
          'https://receipts.artbeat.com/receipt/payment-id.pdf',
        );
      });
    });

    group('Notification Tests', () {
      test('should notify listeners on payment operations', () async {
        var notificationCount = 0;
        paymentService.addListener(() => notificationCount++);

        when(mockCollection.add(any)).thenAnswer((_) async => mockDocRef);

        await paymentService.recordPayment(
          userId: 'test-user-id',
          adId: 'test-ad-id',
          adTitle: 'Test Ad',
          amount: 99.99,
          paymentMethod: PaymentMethod.card,
        );

        expect(notificationCount, equals(1));
      });

      test('should notify listeners on status updates', () async {
        var notificationCount = 0;
        paymentService.addListener(() => notificationCount++);

        when(mockCollection.doc('payment-id')).thenReturn(mockDocRef);
        when(mockDocRef.update(any)).thenAnswer((_) async => {});

        await paymentService.updatePaymentStatus(
          paymentId: 'payment-id',
          status: PaymentStatus.completed,
        );

        expect(notificationCount, equals(1));
      });

      test('should notify listeners on refunds', () async {
        var notificationCount = 0;
        paymentService.addListener(() => notificationCount++);

        when(mockCollection.doc('payment-id')).thenReturn(mockDocRef);
        when(mockDocRef.update(any)).thenAnswer((_) async => {});

        await paymentService.recordRefund(
          paymentId: 'payment-id',
          refundAmount: 50.0,
          refundReason: 'Customer request',
        );

        expect(notificationCount, equals(1));
      });
    });
  });
}
