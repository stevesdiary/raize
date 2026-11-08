import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../models/billing_models.dart';

class BillingNotifier extends Notifier<SubscriptionState> {
  @override
  SubscriptionState build() {
    return const SubscriptionState();
  }

  void selectPlan(String planId) {
    state = state.copyWith(selectedPlanId: planId);
  }

  Future<bool> initializePaystackCheckout({bool syncBackend = false}) async {
    state = state.copyWith(isLoading: true);

    if (!syncBackend) {
      state = state.copyWith(isLoading: false, isSubscribed: true);
      return true;
    }

    try {
      final dio = ref.read(apiClientProvider).client;
      final payload = {
        'planId': state.selectedPlanId,
        'plan': state.selectedPlanId,
        'callbackUrl': 'https://raize.fit/billing/verify',
      };

      final response = await dio.post(ApiEndpoints.paystackInitialize, data: payload);
      final success = response.statusCode == 200 || response.statusCode == 201;
      state = state.copyWith(isLoading: false, isSubscribed: success);
      return success;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> cancelSubscription({bool syncBackend = false}) async {
    state = state.copyWith(isLoading: true);

    if (syncBackend) {
      try {
        final dio = ref.read(apiClientProvider).client;
        await dio.post(ApiEndpoints.billingSubscriptionCancel);
      } catch (_) {
        // Fallback to local state cancellation
      }
    }

    state = state.copyWith(isLoading: false, isSubscribed: false);
    return true;
  }
}

final billingProvider =
    NotifierProvider<BillingNotifier, SubscriptionState>(BillingNotifier.new);

