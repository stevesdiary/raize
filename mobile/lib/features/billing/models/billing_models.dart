class SubscriptionPlan {
  final String id;
  final String name;
  final String priceFormatted;
  final String period;
  final String? monthlyEquivalent;
  final String? badge;
  final String? trialBadge;
  final String description;
  final String ctaLabel;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.priceFormatted,
    required this.period,
    this.monthlyEquivalent,
    this.badge,
    this.trialBadge,
    required this.description,
    required this.ctaLabel,
  });
}

class SubscriptionState {
  final String selectedPlanId;
  final List<SubscriptionPlan> plans;
  final bool isLoading;
  final bool isSubscribed;

  const SubscriptionState({
    this.selectedPlanId = 'annual',
    this.plans = const [
      SubscriptionPlan(
        id: 'annual',
        name: 'Annual Athletic Pass',
        priceFormatted: '₦45,000',
        period: '/ year',
        monthlyEquivalent: 'Equivalent to ₦3,750 / month',
        badge: 'BEST VALUE • SAVE 40%',
        trialBadge: '7 DAYS FREE',
        description: 'Zero risk. Auto-renews after 7-day trial.',
        ctaLabel: 'Start 7-Day Free Trial (₦45,000/yr)',
      ),
      SubscriptionPlan(
        id: 'monthly',
        name: 'Monthly Flexible',
        priceFormatted: '₦5,000',
        period: '/ month',
        description: 'Billed monthly. Pause or cancel anytime.',
        ctaLabel: 'Subscribe Monthly (₦5,000/mo)',
      ),
      SubscriptionPlan(
        id: 'coach',
        name: '1-on-1 Certified Coach Tier',
        priceFormatted: '₦25,000',
        period: '/ month',
        badge: 'PREMIUM MENTORSHIP',
        trialBadge: 'LIMITED SPOTS',
        description:
            'Weekly 1-on-1 video call, custom macro calibrations & form audits.',
        ctaLabel: 'Join Coach Tier (₦25,000/mo)',
      ),
    ],
    this.isLoading = false,
    this.isSubscribed = false,
  });

  SubscriptionPlan get selectedPlan =>
      plans.firstWhere((p) => p.id == selectedPlanId, orElse: () => plans.first);

  SubscriptionState copyWith({
    String? selectedPlanId,
    List<SubscriptionPlan>? plans,
    bool? isLoading,
    bool? isSubscribed,
  }) {
    return SubscriptionState(
      selectedPlanId: selectedPlanId ?? this.selectedPlanId,
      plans: plans ?? this.plans,
      isLoading: isLoading ?? this.isLoading,
      isSubscribed: isSubscribed ?? this.isSubscribed,
    );
  }
}

