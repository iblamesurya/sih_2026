import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../../../core/widgets/error_view.dart';

/// Live Andhra Pradesh Shrimp Mandi Prices & Bio-Economic Harvest Optimizer (/market-prices).
class MandiPricesPage extends ConsumerStatefulWidget {
  const MandiPricesPage({super.key});

  @override
  ConsumerState<MandiPricesPage> createState() => _MandiPricesPageState();
}

class _MandiPricesPageState extends ConsumerState<MandiPricesPage> {
  String _selectedDistrict = 'All Hubs';
  double _optimizerBiomassKg = 2200.0;
  double _optimizerCurrentAbwG = 18.5; // ~54 count
  int _optimizerDoc = 65;
  bool _hasSoftShellPenalty = false; // 7% exporter deduction if >5% soft/loose shell
  bool _isLoadingPrices = false;

  Future<void> _refreshRates() async {
    setState(() => _isLoadingPrices = true);
    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted) {
      setState(() => _isLoadingPrices = false);
    }
  }

  static const double _feedPricePerKgInr = 92.0; // Standard AP CP/Avanti finisher feed ₹/kg

  static const List<String> _districts = [
    'All Hubs',
    'Bhimavaram (West Godavari)',
    'Nellore (Gudur / Kavali)',
    'Kaikaluru (Kolleru / Eluru)',
    'Kakinada & Amalapuram',
    'Machilipatnam (Krishna)',
    'Ongole & Bapatla',
  ];

  /// Maps ABW in grams to standard commercial shrimp count per kg and typical AP farmgate price.
  double _priceForAbw(double abwGrams, List<Map<String, dynamic>> prices) {
    final count = (1000.0 / abwGrams.clamp(5.0, 50.0)).round();
    String bracket;
    if (count <= 32) {
      bracket = '30c';
    } else if (count <= 43) {
      bracket = '40c';
    } else if (count <= 55) {
      bracket = '50c';
    } else if (count <= 65) {
      bracket = '60c';
    } else if (count <= 75) {
      bracket = '70c';
    } else if (count <= 88) {
      bracket = '80c';
    } else {
      bracket = '100c';
    }

    final matching = prices.where((p) => p['count_size'] == bracket).toList();
    if (matching.isNotEmpty) {
      final sum = matching.fold<double>(
        0.0,
        (acc, item) => acc + ((item['price_per_kg'] as num?)?.toDouble() ?? 300.0),
      );
      return sum / matching.length;
    }

    switch (bracket) {
      case '30c':
        return 390.0;
      case '40c':
        return 335.0;
      case '50c':
        return 295.0;
      case '60c':
        return 265.0;
      case '70c':
        return 248.0;
      case '80c':
        return 230.0;
      default:
        return 205.0;
    }
  }

  void _showReportPriceModal(bool isTelugu) {
    String district = 'Bhimavaram (West Godavari)';
    String countSize = '40c';
    String species = 'L. vannamei';
    final priceCtrl = TextEditingController(text: '340');
    final buyerCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isTelugu
                              ? 'నేటి మండి ధరను నమోదు చేయండి'
                              : 'Report Local Mandi / Plant Rate',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: district,
                      dropdownColor: AppColors.surfaceElevated,
                      style: GoogleFonts.outfit(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: isTelugu ? 'మార్కెట్ హబ్ / జిల్లా' : 'Market Hub / District',
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: _districts
                          .where((d) => d != 'All Hubs')
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => district = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: countSize,
                            dropdownColor: AppColors.surfaceElevated,
                            style: GoogleFonts.outfit(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              labelText: isTelugu ? 'కౌంట్ సైజు' : 'Count Size',
                              filled: true,
                              fillColor: AppColors.surfaceElevated,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: const ['20c', '30c', '40c', '50c', '60c', '70c', '80c', '100c']
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => countSize = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.spaceGrotesk(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              labelText: isTelugu ? 'ధర (₹/kg)' : 'Rate (₹/kg)',
                              filled: true,
                              fillColor: AppColors.surfaceElevated,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: buyerCtrl,
                      style: GoogleFonts.outfit(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: isTelugu
                            ? 'కొనుగోలుదారు / ప్లాంట్ పేరు (ఐచ్ఛికం)'
                            : 'Processor / Buyer Name (Optional)',
                        hintText: 'e.g. Devi Sea Foods / Local Dealer',
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.background,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final priceVal = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                          if (priceVal <= 0) return;

                          final newQuote = <String, dynamic>{
                            'id': 'mp_${DateTime.now().millisecondsSinceEpoch}',
                            'district': district,
                            'species': species,
                            'count_size': countSize,
                            'price_per_kg': priceVal,
                            'change_24h': 5.0,
                            'buyer': buyerCtrl.text.trim().isNotEmpty
                                ? buyerCtrl.text.trim()
                                : 'Farmer Verified Quote',
                            'recorded_date': 'Just now',
                          };

                          final current = List<Map<String, dynamic>>.from(
                            ref.read(marketPricesProvider),
                          );
                          current.insert(0, newQuote);
                          ref.read(marketPricesProvider.notifier).state = current;

                          final hydration = ref.read(dataHydrationServiceProvider);
                          await ref.read(farmDataRepositoryProvider).saveMarketPrice({
                            'district': district,
                            'species': species,
                            'count_size': countSize,
                            'price_per_kg': priceVal,
                          });
                          await hydration.refreshPendingSyncCount(ref);
                          await hydration.saveSnapshotToLocal(ref);

                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isTelugu
                                      ? 'మండి ధర విజయవంతంగా అప్‌డేట్ చేయబడింది!'
                                      : 'Mandi rate published & queued for sync!',
                                ),
                                backgroundColor: AppColors.secondary,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.publish, size: 18),
                        label: Text(
                          isTelugu ? 'ధరను ప్రచురించండి' : 'Publish Verified Rate',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(currentLocaleProvider);
    final isTelugu = locale.languageCode == 'te';
    final allPrices = ref.watch(marketPricesProvider);
    final ponds = ref.watch(pondListProvider);
    final feedService = ref.watch(feedAiServiceProvider);
    final subscriptionTier = ref.watch(currentSubscriptionTierProvider);
    final isPro = subscriptionTier == SubscriptionTier.pro;

    final filteredPrices = _selectedDistrict == 'All Hubs'
        ? allPrices
        : allPrices.where((p) => p['district'] == _selectedDistrict).toList();

    // Dynamic daily feed ration & cost computed via FeedAIService bio-energetic finisher curve
    final feedingRate = feedService.calculateBioEnergeticFeedingRate(
      doc: _optimizerDoc,
      abwGrams: _optimizerCurrentAbwG,
    );
    final dailyFeedKg = _optimizerBiomassKg * feedingRate;
    final dynamicDailyFeedCostRs = dailyFeedKg * _feedPricePerKgInr;

    // Bio-economic Harvest Now vs. Hold 7 Days calculation (with soft-shell exporter deduction)
    final currentCount = (1000.0 / _optimizerCurrentAbwG.clamp(5.0, 50.0)).round();
    final baseCurrentPricePerKg = _priceForAbw(_optimizerCurrentAbwG, allPrices);
    final effectiveCurrentPricePerKg =
        _hasSoftShellPenalty ? baseCurrentPricePerKg * 0.93 : baseCurrentPricePerKg;
    final currentGrossRevenue = _optimizerBiomassKg * effectiveCurrentPricePerKg;

    // 7-day projection: +1.6g ABW growth (0.23 g/day ADG), 98.5% survival, and shell hardening
    final projectedAbw7d = _optimizerCurrentAbwG + 1.6;
    final projectedCount7d = (1000.0 / projectedAbw7d).round();
    final projectedBiomassKg7d =
        _optimizerBiomassKg * (projectedAbw7d / _optimizerCurrentAbwG) * 0.985;
    final projectedPricePerKg7d = _priceForAbw(projectedAbw7d, allPrices);
    final sevenDayFeedCost = dynamicDailyFeedCostRs * 7.0;
    final projectedNetRevenue7d =
        (projectedBiomassKg7d * projectedPricePerKg7d) - sevenDayFeedCost;
    final netHoldAdvantage = projectedNetRevenue7d - currentGrossRevenue;
    final shouldHold = netHoldAdvantage > 0 || _hasSoftShellPenalty;
    final pendingSync = ref.watch(pendingSyncCountProvider);
    final isOffline = pendingSync > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          isTelugu ? 'లైవ్ రొయ్యల మండి ధరలు' : 'Live AP Shrimp Mandi Rates',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        onPressed: () => _showReportPriceModal(isTelugu),
        icon: const Icon(Icons.add_chart),
        label: Text(
          isTelugu ? 'ధర నమోదు' : 'Report Rate',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          if (isOffline)
            OfflineStatusBar(
              isOffline: true,
              isTelugu: isTelugu,
              onSyncNow: _refreshRates,
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshRates,
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
          // Bio-Economic Harvest Timing Optimizer Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF171717), Color(0xFF0E241E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: shouldHold
                    ? AppColors.secondary.withValues(alpha: 0.5)
                    : AppColors.alertWatch.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_graph, color: AppColors.secondary, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isTelugu
                            ? 'హార్వెస్ట్ టైమింగ్ ఆప్టిమైజర్ (ఇప్పుడే పట్టాలా vs 7 రోజులు ఆగాలా?)'
                            : 'Harvest Timing Optimizer (Harvest Today vs. Hold 7 Days)',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (ponds.isNotEmpty) ...[
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: ponds.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final p = ponds[idx];
                        final name = (p['name'] ?? 'Pond ${idx + 1}').toString();
                        final abw = ((p['abw'] as num?)?.toDouble() ?? 18.5).clamp(8.0, 35.0);
                        return ActionChip(
                          backgroundColor: AppColors.surfaceElevated,
                          label: Text(
                            '$name (${abw.toStringAsFixed(1)}g)',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              color: AppColors.primary,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _optimizerCurrentAbwG = abw;
                              _optimizerDoc = (p['doc'] as num?)?.toInt() ?? 65;
                              final area = (p['areaHa'] as num?)?.toDouble() ?? 1.0;
                              final density =
                                  (p['stockingDensity'] as num?)?.toDouble() ?? 50.0;
                              _optimizerBiomassKg = feedService
                                  .calculateBiomass(
                                    density: density,
                                    areaHa: area,
                                    survivalRate: 0.85,
                                    abw: abw,
                                  )
                                  .clamp(500.0, 12000.0);
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTelugu
                          ? 'ప్రస్తుత రొయ్య బరువు (ABW): ${_optimizerCurrentAbwG.toStringAsFixed(1)}g (~${currentCount}c)'
                          : 'Current ABW: ${_optimizerCurrentAbwG.toStringAsFixed(1)}g (~${currentCount}c)',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      '₹${effectiveCurrentPricePerKg.toStringAsFixed(0)}/kg',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _optimizerCurrentAbwG.clamp(8.0, 35.0),
                  min: 8.0,
                  max: 35.0,
                  divisions: 54,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _optimizerCurrentAbwG = val),
                ),

                // Pre-Harvest Check-Tray Shell Hardness / Loose-Shell Penalty Switch
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _hasSoftShellPenalty
                        ? AppColors.alertUrgent.withValues(alpha: 0.12)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _hasSoftShellPenalty
                          ? AppColors.alertUrgent
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _hasSoftShellPenalty ? Icons.warning_amber : Icons.verified_user,
                        size: 16,
                        color: _hasSoftShellPenalty
                            ? AppColors.alertUrgent
                            : AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isTelugu
                              ? (_hasSoftShellPenalty
                                  ? 'లూజ్ షెల్ / మెత్తని గుల్ల (>5%): 7% ఫ్యాక్టరీ కోత వర్తిస్తుంది'
                                  : 'గట్టి గుల్ల (Export Grade A): 0% ధర కోత')
                              : (_hasSoftShellPenalty
                                  ? 'Post-Molt Soft Shell (>5%): -7% Exporter Deduction'
                                  : 'Hard Shell (Export Grade A): 0% Factory Penalty'),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: _hasSoftShellPenalty
                                ? AppColors.alertUrgent
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Switch(
                        value: _hasSoftShellPenalty,
                        activeThumbColor: AppColors.alertUrgent,
                        onChanged: (v) => setState(() => _hasSoftShellPenalty = v),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isTelugu ? 'నేడు పడితే ఆదాయం:' : 'Harvest Today Value:',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '₹${currentGrossRevenue.toStringAsFixed(0)} (${currentCount}c @ ₹${effectiveCurrentPricePerKg.toStringAsFixed(0)})',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isTelugu ? '7 రోజుల తర్వాత నికర విలువ:' : 'Hold 7 Days Net Value:',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '₹${projectedNetRevenue7d.toStringAsFixed(0)} (${projectedCount7d}c @ ₹${projectedPricePerKg7d.toStringAsFixed(0)})',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isTelugu
                            ? 'డైనమిక్ మేత ఖర్చు: ${dailyFeedKg.toStringAsFixed(0)} kg/day (₹${dynamicDailyFeedCostRs.toStringAsFixed(0)}/day @ ₹92/kg)'
                            : 'Bio-Energetic Feed Burn: ${dailyFeedKg.toStringAsFixed(0)} kg/day (₹${dynamicDailyFeedCostRs.toStringAsFixed(0)}/day @ ₹92/kg)',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const Divider(height: 16, color: AppColors.cardBorder),
                      Row(
                        children: [
                          Icon(
                            shouldHold ? Icons.trending_up : Icons.warning_amber_rounded,
                            color: shouldHold ? AppColors.secondary : AppColors.alertWatch,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _hasSoftShellPenalty
                                  ? (isTelugu
                                      ? 'సిఫార్సు: ఇప్పుడే పట్టవద్దు! డోలమైట్ & ఖనిజాలు వేసి 5-7 రోజులు ఆగితే గుల్ల గట్టిపడి +₹${netHoldAdvantage.toStringAsFixed(0)} అదనపు లాభం వస్తుంది.'
                                      : 'RECOMMENDATION: Hold 5–7 days & dose Dolomite/Minerals. Hardening shell + count jump recovers +₹${netHoldAdvantage.toStringAsFixed(0)} net gain!')
                                  : (shouldHold
                                      ? (isTelugu
                                          ? 'సిఫార్సు: 7 రోజులు ఆగితే కౌంట్ జంప్ వల్ల నికర లాభం +₹${netHoldAdvantage.toStringAsFixed(0)} పెరుగుతుంది (మేత ఖర్చు ₹${sevenDayFeedCost.toStringAsFixed(0)} పోను).'
                                          : 'RECOMMENDATION: Hold 7 days for next count bracket (+₹${netHoldAdvantage.toStringAsFixed(0)} net gain after ₹${sevenDayFeedCost.toStringAsFixed(0)} feed cost).')
                                      : (isTelugu
                                          ? 'సిఫార్సు: ఇప్పుడే హార్వెస్ట్ చేయండి. మేత ఖర్చు కంటే ధర పెరుగుదల తక్కువగా ఉంది.'
                                          : 'RECOMMENDATION: Harvest now. Feed cost over next 7 days outweighs count bracket gain.')),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: shouldHold ? AppColors.secondary : AppColors.alertWatch,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!isPro) ...[
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () => context.push('/upgrade'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.bolt, size: 16, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    isTelugu
                                        ? 'ప్రో పంట పాస్ (₹999): ఫ్యాక్టరీ డైరెక్ట్ బుకింగ్ & SMS ధరల అలర్ట్స్ పొందండి'
                                        : 'Get Pro Crop Pass (₹999): Unlock Direct Plant Alerts & Zero-Commission Booking',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Hub Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _districts.map((hub) {
                final selected = _selectedDistrict == hub;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: selected,
                    label: Text(hub),
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    backgroundColor: AppColors.surface,
                    checkmarkColor: AppColors.primary,
                    labelStyle: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.cardBorder,
                    ),
                    onSelected: (_) => setState(() => _selectedDistrict = hub),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Price Cards List
          if (_isLoadingPrices) ...[
            const MandiPriceSkeleton(),
            const MandiPriceSkeleton(),
            const MandiPriceSkeleton(),
            const MandiPriceSkeleton(),
          ] else if (filteredPrices.isEmpty) ...[
            AppErrorView(
              isCompact: true,
              errorType: AppErrorType.offline,
              isTelugu: isTelugu,
              title: 'No Regional Mandi Prices Recorded',
              teluguTitle: 'మండి ధరలు లభించలేదు',
              message: 'Pull down to refresh or reload default Andhra Pradesh market rates.',
              teluguMessage: 'రిఫ్రెష్ చేయడానికి క్రిందికి లాగండి లేదా డిఫాల్ట్ ధరలను రీలోడ్ చేయండి.',
              onRetry: () {
                ref.read(marketPricesProvider.notifier).state = defaultAndhraMandiPrices();
              },
            ),
          ] else ...filteredPrices.map((item) {
            final countSize = (item['count_size'] ?? '40c').toString();
            final price = ((item['price_per_kg'] as num?) ?? 330).toDouble();
            final change = ((item['change_24h'] as num?) ?? 0).toDouble();
            final district = (item['district'] ?? 'Bhimavaram').toString();
            final species = (item['species'] ?? 'L. vannamei').toString();
            final buyer = (item['buyer'] ?? 'Export Processing Plant').toString();
            final recordedDate = (item['recorded_date'] ?? 'Today').toString();

            final isUp = change > 0;
            final isDown = change < 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Center(
                      child: Text(
                        countSize,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          district,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$species • $buyer',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          recordedDate,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${price.toStringAsFixed(0)}/kg',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isUp
                              ? AppColors.secondary.withValues(alpha: 0.15)
                              : isDown
                                  ? AppColors.alertUrgent.withValues(alpha: 0.15)
                                  : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isUp
                              ? '+₹${change.toStringAsFixed(0)}'
                              : isDown
                                  ? '-₹${change.abs().toStringAsFixed(0)}'
                                  : 'Stable',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isUp
                                ? AppColors.secondary
                                : isDown
                                    ? AppColors.alertUrgent
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 70),
        ],
      ),
    ),
  ),
],
),
);
}
}
