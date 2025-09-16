import 'package:artbeat_core/src/screens/order_review_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderDetails Validation', () {
    test('should create valid gift order details', () {
      final orderDetails = OrderDetails(
        type: TransactionType.gift,
        title: 'Gift Purchase',
        description: 'A gift for an artist',
        originalAmount: 25,
        metadata: {
          'recipientId': 'user123',
          'giftType': 'premium',
          'message': 'Happy creating!',
        },
      );

      expect(orderDetails.type, TransactionType.gift);
      expect(orderDetails.title, 'Gift Purchase');
      expect(orderDetails.originalAmount, 25.0);
      expect(orderDetails.metadata['recipientId'], 'user123');
    });

    test('should throw error for gift without recipientId', () {
      expect(() {
        OrderDetails(
          type: TransactionType.gift,
          title: 'Gift Purchase',
          description: 'A gift for an artist',
          originalAmount: 25,
          metadata: {'giftType': 'premium', 'message': 'Happy creating!'},
        );
      }, throwsArgumentError);
    });

    test('should throw error for gift without giftType', () {
      expect(() {
        OrderDetails(
          type: TransactionType.gift,
          title: 'Gift Purchase',
          description: 'A gift for an artist',
          originalAmount: 25,
          metadata: {'recipientId': 'user123', 'message': 'Happy creating!'},
        );
      }, throwsArgumentError);
    });

    test('should create valid subscription order details', () {
      final orderDetails = OrderDetails(
        type: TransactionType.subscription,
        title: 'Monthly Subscription',
        description: 'Premium monthly subscription',
        originalAmount: 9.99,
        metadata: {'tier': 'premium', 'billingCycle': 'monthly'},
      );

      expect(orderDetails.type, TransactionType.subscription);
      expect(orderDetails.metadata['tier'], 'premium');
      expect(orderDetails.metadata['billingCycle'], 'monthly');
    });

    test('should throw error for subscription without tier', () {
      expect(() {
        OrderDetails(
          type: TransactionType.subscription,
          title: 'Monthly Subscription',
          description: 'Premium monthly subscription',
          originalAmount: 9.99,
          metadata: {'billingCycle': 'monthly'},
        );
      }, throwsArgumentError);
    });

    test('should throw error for subscription without billingCycle', () {
      expect(() {
        OrderDetails(
          type: TransactionType.subscription,
          title: 'Monthly Subscription',
          description: 'Premium monthly subscription',
          originalAmount: 9.99,
          metadata: {'tier': 'premium'},
        );
      }, throwsArgumentError);
    });

    test('should create valid advertisement order details', () {
      final orderDetails = OrderDetails(
        type: TransactionType.advertisement,
        title: 'Ad Campaign',
        description: 'Promote your art',
        originalAmount: 50,
        metadata: {'adType': 'banner', 'duration': 30},
      );

      expect(orderDetails.type, TransactionType.advertisement);
      expect(orderDetails.metadata['adType'], 'banner');
      expect(orderDetails.metadata['duration'], 30);
    });

    test('should throw error for advertisement without adType', () {
      expect(() {
        OrderDetails(
          type: TransactionType.advertisement,
          title: 'Ad Campaign',
          description: 'Promote your art',
          originalAmount: 50,
          metadata: {'duration': 30},
        );
      }, throwsArgumentError);
    });

    test('should create valid sponsorship order details', () {
      final orderDetails = OrderDetails(
        type: TransactionType.sponsorship,
        title: 'Artist Sponsorship',
        description: 'Support local artists',
        originalAmount: 100,
        metadata: {
          'artistId': 'artist123',
          'sponsorshipType': 'gold',
          'duration': 90,
          'benefits': ['Logo on website', 'Social media mention'],
        },
      );

      expect(orderDetails.type, TransactionType.sponsorship);
      expect(orderDetails.metadata['artistId'], 'artist123');
      expect(orderDetails.metadata['sponsorshipType'], 'gold');
    });

    test('should create valid commission order details', () {
      final orderDetails = OrderDetails(
        type: TransactionType.commission,
        title: 'Custom Artwork',
        description: 'Commission a custom piece',
        originalAmount: 200,
        metadata: {
          'artistId': 'artist123',
          'commissionType': 'portrait',
          'description': 'A beautiful portrait of my family',
        },
      );

      expect(orderDetails.type, TransactionType.commission);
      expect(orderDetails.metadata['artistId'], 'artist123');
      expect(orderDetails.metadata['commissionType'], 'portrait');
    });

    test('should throw error for empty title', () {
      expect(() {
        OrderDetails(
          type: TransactionType.gift,
          title: '',
          description: 'A gift for an artist',
          originalAmount: 25,
          metadata: {'recipientId': 'user123', 'giftType': 'premium'},
        );
      }, throwsArgumentError);
    });

    test('should throw error for negative amount', () {
      expect(() {
        OrderDetails(
          type: TransactionType.gift,
          title: 'Gift Purchase',
          description: 'A gift for an artist',
          originalAmount: -10,
          metadata: {'recipientId': 'user123', 'giftType': 'premium'},
        );
      }, throwsArgumentError);
    });

    test('should make metadata unmodifiable', () {
      final orderDetails = OrderDetails(
        type: TransactionType.gift,
        title: 'Gift Purchase',
        description: 'A gift for an artist',
        originalAmount: 25,
        metadata: {'recipientId': 'user123', 'giftType': 'premium'},
      );

      expect(() {
        (orderDetails.metadata as dynamic).addAll({'newKey': 'newValue'});
      }, throwsUnsupportedError);
    });
  });
}
