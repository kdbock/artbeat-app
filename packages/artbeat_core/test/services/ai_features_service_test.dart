import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_core/src/services/ai_features_service.dart';
import 'package:artbeat_core/src/models/subscription_tier.dart';

void main() {
  group('AIFeaturesService', () {
    test('isFeatureAvailable returns correct availability for free tier', () {
      final aiService = AIFeaturesService();
      expect(
        aiService.isFeatureAvailable(
          AIFeaturesService.smartCropping,
          SubscriptionTier.free,
        ),
        false,
      );
      expect(
        aiService.isFeatureAvailable(
          AIFeaturesService.autoTagging,
          SubscriptionTier.free,
        ),
        true,
      );
      expect(
        aiService.isFeatureAvailable(
          AIFeaturesService.performanceInsights,
          SubscriptionTier.free,
        ),
        false,
      );
    });

    test(
      'isFeatureAvailable returns correct availability for creator tier',
      () {
        final aiService = AIFeaturesService();
        expect(
          aiService.isFeatureAvailable(
            AIFeaturesService.smartCropping,
            SubscriptionTier.creator,
          ),
          true,
        );
        expect(
          aiService.isFeatureAvailable(
            AIFeaturesService.contentRecommendations,
            SubscriptionTier.creator,
          ),
          true,
        );
        expect(
          aiService.isFeatureAvailable(
            AIFeaturesService.performanceInsights,
            SubscriptionTier.creator,
          ),
          false,
        );
      },
    );

    test(
      'isFeatureAvailable returns correct availability for enterprise tier',
      () {
        final aiService = AIFeaturesService();
        expect(
          aiService.isFeatureAvailable(
            AIFeaturesService.smartCropping,
            SubscriptionTier.enterprise,
          ),
          true,
        );
        expect(
          aiService.isFeatureAvailable(
            AIFeaturesService.contentRecommendations,
            SubscriptionTier.enterprise,
          ),
          true,
        );
        expect(
          aiService.isFeatureAvailable(
            AIFeaturesService.performanceInsights,
            SubscriptionTier.enterprise,
          ),
          true,
        );
      },
    );

    test('getFeatureCreditCost returns correct costs', () {
      final aiService = AIFeaturesService();
      expect(
        aiService.getFeatureCreditCost(AIFeaturesService.smartCropping),
        1,
      );
      expect(
        aiService.getFeatureCreditCost(AIFeaturesService.backgroundRemoval),
        2,
      );
      expect(aiService.getFeatureCreditCost(AIFeaturesService.autoTagging), 1);
    });
  });
}
