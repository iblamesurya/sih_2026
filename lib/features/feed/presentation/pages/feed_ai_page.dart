import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/feed_ai_service.dart';

/// Feed AI Bio-Energetics & 4-Meal Planning Page (Tab 2).
class FeedAiPage extends ConsumerStatefulWidget {
  const FeedAiPage({super.key});

  @override
  ConsumerState<FeedAiPage> createState() => _FeedAiPageState();
}

class _FeedAiPageState extends ConsumerState<FeedAiPage> {
  final _densityController = TextEditingController(text: '50');
  final _areaController = TextEditingController(text: '1.0');
  final _abwController = TextEditingController(text: '18.5');
  final _docController = TextEditingController(text: '65');

  double _survivalRate = 0.85;
  double _temperature = 28.5;
  double _trayAdjustment = 0.0; // -0.20 to +0.10

  DailyFeedPlan? _feedPlan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _calculateFeed();
      }
    });
  }

  @override
  void dispose() {
    _densityController.dispose();
    _areaController.dispose();
    _abwController.dispose();
    _docController.dispose();
    super.dispose();
  }

  void _calculateFeed() {
    final feedService = ref.read(feedAiServiceProvider);

    final density = double.tryParse(_densityController.text) ?? 50.0;
    final areaHa = double.tryParse(_areaController.text) ?? 1.0;
    final abw = double.tryParse(_abwController.text) ?? 18.5;
    final doc = int.tryParse(_docController.text) ?? 65;

    final plan = feedService.calculateDailyFeed(
      density: density,
      areaHa: areaHa,
      survivalRate: _survivalRate,
      abw: abw,
      doc: doc,
      temperature: _temperature,
      trayAdjustment: _trayAdjustment,
    );

    setState(() {
      _feedPlan = plan;
    });

    ref.read(activeFeedPlanProvider.notifier).state = plan;
  }

  Future<void> _logFeedRation() async {
    if (_feedPlan == null) return;
    final offlineSync = ref.read(offlineSyncProvider);

    final mutation = {
      'type': 'INSERT_FEED_PLAN',
      'biomass_kg': _feedPlan!.biomassKg,
      'daily_feed_kg': _feedPlan!.adjustedDailyFeedKg,
      'meal1_kg': _feedPlan!.meal1Kg,
      'meal2_kg': _feedPlan!.meal2Kg,
      'meal3_kg': _feedPlan!.meal3Kg,
      'meal4_kg': _feedPlan!.meal4Kg,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await offlineSync.enqueue(mutation);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Daily Feed Plan (${_feedPlan!.adjustedDailyFeedKg.toStringAsFixed(1)} kg) queued/saved successfully!',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(currentLocaleProvider);
    final isTelugu = locale.languageCode == 'te';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          isTelugu ? 'ఫీడ్ AI బయో-ఎనర్జెటిక్స్' : 'Feed AI Bio-Energetics',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _calculateFeed,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bio-energetics Input Form Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTelugu ? 'చెరువు బయోమాస్ & పారామితులు' : 'Biomass & Environmental Inputs',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _FeedInput(
                        controller: _densityController,
                        label: isTelugu ? 'సాంద్రత (PL/m²)' : 'Density (PL/m²)',
                        onChanged: (_) => _calculateFeed(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FeedInput(
                        controller: _areaController,
                        label: isTelugu ? 'విస్తీర్ణం (Ha)' : 'Area (Ha)',
                        onChanged: (_) => _calculateFeed(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _FeedInput(
                        controller: _abwController,
                        label: isTelugu ? 'సగటు బరువు (ABW g)' : 'ABW (g)',
                        onChanged: (_) => _calculateFeed(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FeedInput(
                        controller: _docController,
                        label: isTelugu ? 'రోజులు (DOC)' : 'DOC (Days)',
                        onChanged: (_) => _calculateFeed(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Survival Rate Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTelugu ? 'జీవిత రేటు (Survival Rate)' : 'Estimated Survival Rate',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      '${(_survivalRate * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _survivalRate,
                  min: 0.50,
                  max: 1.00,
                  divisions: 20,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => _survivalRate = val);
                    _calculateFeed();
                  },
                ),

                // Water Temperature Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTelugu ? 'నీటి ఉష్ణోగ్రత (°C)' : 'Water Temperature (°C)',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      '${_temperature.toStringAsFixed(1)}°C',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.alertWatch,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _temperature,
                  min: 20.0,
                  max: 36.0,
                  divisions: 32,
                  activeColor: AppColors.alertWatch,
                  onChanged: (val) {
                    setState(() => _temperature = val);
                    _calculateFeed();
                  },
                ),

                // Check-Tray Adjustment Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTelugu ? 'చెక్-ట్రే సర్దుబాటు' : 'Check-Tray Consumption Feedback',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      '${(_trayAdjustment * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _trayAdjustment >= 0 ? AppColors.secondary : AppColors.alertUrgent,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _trayAdjustment,
                  min: -0.20,
                  max: 0.10,
                  divisions: 30,
                  activeColor: _trayAdjustment >= 0 ? AppColors.secondary : AppColors.alertUrgent,
                  onChanged: (val) {
                    setState(() => _trayAdjustment = val);
                    _calculateFeed();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Feed Calculation Summary Hero Card
          if (_feedPlan != null) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF171717), Color(0xFF0F2B20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTelugu ? 'మొత్తం రోజువారీ మేత' : 'Target Daily Ration',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _feedPlan!.adjustedDailyFeedKg.toStringAsFixed(2),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'kg / day',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Est. Biomass',
                            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textTertiary),
                          ),
                          Text(
                            '${_feedPlan!.biomassKg.toStringAsFixed(0)} kg',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Feeding Rate: ${(_feedPlan!.feedingRate * 100).toStringAsFixed(2)}%',
                            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Temp Factor: ${_feedPlan!.tempFactor.toStringAsFixed(2)}x',
                        style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      Text(
                        'Tray Factor: ${_feedPlan!.trayFactor.toStringAsFixed(2)}x',
                        style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      Text(
                        'Base Feed: ${_feedPlan!.baseDailyFeedKg.toStringAsFixed(1)} kg',
                        style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4-Meal Daily Schedule Breakdown
            Text(
              isTelugu ? 'రోజువారీ 4-సార్ల మేత విభజన' : '4-Meal Daily Allocation Schedule',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            ..._feedPlan!.mealSchedule.map((meal) => Container(
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '#${meal.mealNumber}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTelugu ? meal.teluguLabel : 'Meal ${meal.mealNumber} (${meal.mealTime})',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${(meal.percentShare * 100).toStringAsFixed(0)}% of daily ration',
                              style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${meal.feedKg.toStringAsFixed(2)} kg',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _logFeedRation,
              icon: const Icon(Icons.check, size: 20),
              label: Text(
                isTelugu ? 'ఈ మేత ప్లాన్‌ను లాగ్ చేయండి' : 'Apply & Save Today\'s Feed Plan',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _FeedInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  const _FeedInput({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceElevated,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
          ),
        ),
      ],
    );
  }
}
