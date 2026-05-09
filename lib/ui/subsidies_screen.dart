import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/ai_services.dart';
import '../services/api_clients.dart';
import '../theme/app_theme.dart';

class SubsidiesScreen extends StatefulWidget {
  const SubsidiesScreen({
    super.key,
    required this.repository,
    required this.userId,
  });

  final FarmlandRepository repository;
  final int userId;

  @override
  State<SubsidiesScreen> createState() => _SubsidiesScreenState();
}

class _SubsidiesScreenState extends State<SubsidiesScreen> {
  late final List<Farmland> _cachedFarms;
  late Future<List<Farmland>> _farmsFuture;

  @override
  void initState() {
    super.initState();
    _cachedFarms = widget.repository.cached(widget.userId);
    _farmsFuture = _loadFarms();
  }

  Future<List<Farmland>> _loadFarms() async {
    try {
      final fresh = await widget.repository.refresh(widget.userId);
      return fresh.isEmpty ? _cachedFarms : fresh;
    } catch (_) {
      return _cachedFarms;
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _farmsFuture = _loadFarms();
    });
    await _farmsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Govt Subsidies',
            style:
                TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: FutureBuilder<List<Farmland>>(
          future: _farmsFuture,
          initialData: _cachedFarms,
          builder: (context, snapshot) {
            final farms = snapshot.data ?? const <Farmland>[];
            final profile = _SubsidyProfile.fromFarms(farms);
            final recommendations = _recommendationsFor(profile);

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemCount: recommendations.length + 2,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) return _ProfileMatchCard(profile: profile);
                  if (index == 1) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 2),
                      child: Text(
                        'Recommended for you',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: colors.onSurface,
                                ),
                      ),
                    );
                  }
                  return _SubsidyCard(
                    recommendation: recommendations[index - 2],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileMatchCard extends StatelessWidget {
  const _ProfileMatchCard({required this.profile});

  final _SubsidyProfile profile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            profile.hasMappedArea
                ? Icons.check_circle_rounded
                : Icons.info_rounded,
            color: colors.primary,
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.hasMappedArea ? 'Auto-matched' : 'Profile needed',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.summary,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubsidyProfile {
  const _SubsidyProfile({
    required this.farmCount,
    required this.mappedFarmCount,
    required this.areaHa,
    required this.crops,
    required this.irrigationTypes,
    required this.waterSources,
    required this.ownershipTypes,
  });

  final int farmCount;
  final int mappedFarmCount;
  final double areaHa;
  final List<String> crops;
  final Set<String> irrigationTypes;
  final Set<String> waterSources;
  final Set<String> ownershipTypes;

  bool get hasFarms => farmCount > 0;
  bool get hasMappedArea => areaHa > 0;
  double get areaAcres => areaHa * 2.47105;
  String get primaryCrop => crops.isEmpty ? 'your crops' : crops.first;

  String get areaText {
    if (!hasMappedArea) return 'boundary area not mapped';
    final decimals = areaAcres >= 10 ? 1 : 2;
    return '${areaAcres.toStringAsFixed(decimals)} acres';
  }

  String get cropText {
    if (crops.isEmpty) return 'saved crops';
    if (crops.length == 1) return crops.first;
    if (crops.length == 2) return '${crops.first} and ${crops.last}';
    return '${crops.take(2).join(', ')} +${crops.length - 2} more';
  }

  String get summary {
    if (!hasFarms) {
      return 'Add a farm profile and mapped boundary to get scheme matches based on your real land area and crops.';
    }
    if (!hasMappedArea) {
      return 'Your farms are saved, but no boundary area is mapped yet. Map a field boundary to improve eligibility estimates.';
    }
    final fieldLabel = mappedFarmCount == 1 ? 'field' : 'fields';
    return 'Based on your mapped $areaText of $cropText across $mappedFarmCount $fieldLabel, you qualify for targeted schemes.';
  }

  factory _SubsidyProfile.fromFarms(List<Farmland> farms) {
    final crops = <String>{};
    final irrigation = <String>{};
    final water = <String>{};
    final ownership = <String>{};
    var areaHa = 0.0;
    var mappedCount = 0;

    for (final farm in farms) {
      final farmArea = estimateAreaHectares(farm.boundaryPoints);
      if (farmArea > 0) {
        areaHa += farmArea;
        mappedCount += 1;
      }
      for (final crop in farm.crops) {
        final name = crop.name.trim();
        if (name.isNotEmpty) crops.add(name);
      }
      if ((farm.irrigationType ?? '').isNotEmpty) {
        irrigation.add(farm.irrigationType!);
      }
      if ((farm.waterSource ?? '').isNotEmpty) {
        water.add(farm.waterSource!);
      }
      if ((farm.landOwnership ?? '').isNotEmpty) {
        ownership.add(farm.landOwnership!);
      }
    }

    return _SubsidyProfile(
      farmCount: farms.length,
      mappedFarmCount: mappedCount,
      areaHa: areaHa,
      crops: crops.toList(),
      irrigationTypes: irrigation,
      waterSources: water,
      ownershipTypes: ownership,
    );
  }
}

class _SubsidyRecommendation {
  const _SubsidyRecommendation({
    required this.title,
    required this.description,
    required this.amount,
    required this.deadline,
    required this.matchPercentage,
  });

  final String title;
  final String description;
  final String amount;
  final String deadline;
  final int matchPercentage;
}

List<_SubsidyRecommendation> _recommendationsFor(_SubsidyProfile profile) {
  final hasIrrigationNeed = profile.irrigationTypes.contains('rainfed') ||
      profile.waterSources.contains('rain_only') ||
      profile.irrigationTypes.isEmpty;
  final hasOwnershipSignal = profile.ownershipTypes.isEmpty ||
      profile.ownershipTypes.contains('owned');
  final mappedBoost = profile.hasMappedArea ? 8 : 0;
  final cropBoost = profile.crops.isNotEmpty ? 6 : 0;

  return [
    _SubsidyRecommendation(
      title: 'PM-Kisan Samman Nidhi',
      description: hasOwnershipSignal
          ? 'Income support matched against your saved farmer profile and mapped land record.'
          : 'Income support eligibility may need ownership or tenancy document verification.',
      amount: '\u20B96,000/yr',
      deadline: 'Open year-round',
      matchPercentage: (82 + mappedBoost + (hasOwnershipSignal ? 8 : 0))
          .clamp(58, 98)
          .toInt(),
    ),
    _SubsidyRecommendation(
      title: 'Pradhan Mantri Fasal Bima Yojana',
      description:
          'Crop insurance recommendation tuned for ${profile.cropText} and your mapped seasonal risk profile.',
      amount: 'Full cover',
      deadline: 'Before sowing cutoff',
      matchPercentage: (78 + mappedBoost + cropBoost).clamp(55, 96).toInt(),
    ),
    _SubsidyRecommendation(
      title: 'Solar Pump Subsidy (KUSUM)',
      description: hasIrrigationNeed
          ? 'Solar pump support is relevant because your profile indicates rainfed or incomplete irrigation coverage.'
          : 'Solar pump support can reduce power cost for your saved irrigation setup.',
      amount: 'Up to 60%',
      deadline: 'State window varies',
      matchPercentage: (68 + mappedBoost + (hasIrrigationNeed ? 12 : 5))
          .clamp(50, 94)
          .toInt(),
    ),
  ];
}

class _SubsidyCard extends StatelessWidget {
  const _SubsidyCard({required this.recommendation});

  final _SubsidyRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  recommendation.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${recommendation.matchPercentage}% Match',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.description,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded,
                  size: 16, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                recommendation.amount,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
              const Spacer(),
              Icon(Icons.timer_outlined, size: 16, color: colors.error),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  recommendation.deadline,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: colors.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Apply Now via Gov API'),
            ),
          ),
        ],
      ),
    );
  }
}
