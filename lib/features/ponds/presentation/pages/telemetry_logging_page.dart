import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/app_providers.dart';

/// Quick Log & Telugu Voice Telemetry Entry Page (/quick-log).
class TelemetryLoggingPage extends ConsumerStatefulWidget {
  const TelemetryLoggingPage({super.key});

  @override
  ConsumerState<TelemetryLoggingPage> createState() => _TelemetryLoggingPageState();
}

class _TelemetryLoggingPageState extends ConsumerState<TelemetryLoggingPage> {
  final _formKey = GlobalKey<FormState>();

  final _pondController = TextEditingController(text: '1');
  final _phController = TextEditingController();
  final _doController = TextEditingController();
  final _salinityController = TextEditingController();
  final _tempController = TextEditingController();
  final _ammoniaController = TextEditingController();
  final _feedController = TextEditingController();
  final _voiceInputController = TextEditingController();

  String? _detectedTeluguPhrase;

  @override
  void dispose() {
    _pondController.dispose();
    _phController.dispose();
    _doController.dispose();
    _salinityController.dispose();
    _tempController.dispose();
    _ammoniaController.dispose();
    _feedController.dispose();
    _voiceInputController.dispose();
    super.dispose();
  }

  void _parseVoice(String transcript) {
    final nluService = ref.read(teluguVoiceNluProvider);
    final parsed = nluService.parseVoiceInput(transcript);

    setState(() {
      _detectedTeluguPhrase = transcript;
      if (parsed.pondIndex != null) {
        _pondController.text = parsed.pondIndex.toString();
      }
      if (parsed.ph != null) {
        _phController.text = parsed.ph.toString();
      }
      if (parsed.doLevel != null) {
        _doController.text = parsed.doLevel.toString();
      }
      if (parsed.salinity != null) {
        _salinityController.text = parsed.salinity.toString();
      }
      if (parsed.temperature != null) {
        _tempController.text = parsed.temperature.toString();
      }
      if (parsed.ammonia != null) {
        _ammoniaController.text = parsed.ammonia.toString();
      }
      if (parsed.feedKg != null) {
        _feedController.text = parsed.feedKg.toString();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Telugu Voice Parsed: ${parsed.toString()}',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  Future<void> _submitTelemetry() async {
    final alertSystem = ref.read(alertSystemProvider);
    final offlineSync = ref.read(offlineSyncProvider);

    final ph = double.tryParse(_phController.text);
    final doLevel = double.tryParse(_doController.text);
    final ammonia = double.tryParse(_ammoniaController.text);

    // Evaluate water parameters
    final alerts = alertSystem.evaluateParameters(
      ph: ph,
      dissolvedOxygen: doLevel,
      ammonia: ammonia,
    );

    // Update alerts in state
    ref.read(alertsProvider.notifier).state = alerts;

    // Enqueue mutation
    final mutation = {
      'type': 'INSERT_WATER_LOG',
      'pond_id': _pondController.text,
      'ph': ph,
      'dissolved_oxygen': doLevel,
      'salinity': double.tryParse(_salinityController.text),
      'temperature': double.tryParse(_tempController.text),
      'ammonia': ammonia,
      'feed_kg': double.tryParse(_feedController.text),
      'timestamp': DateTime.now().toIso8601String(),
    };

    await offlineSync.enqueue(mutation);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            alerts.any((a) => a.isUrgent)
                ? 'Logged with Critical Water Quality Warning!'
                : 'Water telemetry logged successfully (Synced/Queued)!',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: alerts.any((a) => a.isUrgent)
              ? AppColors.alertUrgent
              : AppColors.secondary,
        ),
      );
      Navigator.of(context).pop();
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
          isTelugu ? 'నీటి రీడింగ్ లాగ్ (వాయిస్)' : 'Quick Water Telemetry Log',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Voice Input Hero Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF171717), Color(0xFF0D252F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTelugu ? 'తెలుగు వాయిస్ లాగింగ్' : 'Telugu Voice NLU Assistant',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              isTelugu
                                  ? 'ఉదా: "చెరువు 2 లో pH 7.8, DO 5.2, మేత 25 kg"'
                                  : 'Speak in Telugu or mixed English naturally',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Quick test utterance chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _VoiceSampleChip(
                          label: 'చెరువు 2: pH 7.8, DO 5.2',
                          onTap: () => _parseVoice('చెరువు 2 లో pH 7.8, DO 5.2, feed 25 kg'),
                        ),
                        const SizedBox(width: 8),
                        _VoiceSampleChip(
                          label: 'Pond 1: Salinity 15, Ammonia 0.04',
                          onTap: () => _parseVoice('Pond 1 lo salinity 15 ppt ammonia 0.04'),
                        ),
                        const SizedBox(width: 8),
                        _VoiceSampleChip(
                          label: 'చెరువు 3: మేత 35 కిలోలు',
                          onTap: () => _parseVoice('ఉదయం 3వ చెరువులో మేత 35 కిలోలు వేశాము'),
                        ),
                      ],
                    ),
                  ),

                  if (_detectedTeluguPhrase != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBase,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        'Voice Input: "$_detectedTeluguPhrase"',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              isTelugu ? 'పారామితుల వివరాలు' : 'Telemetry Parameters',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Form inputs
            Row(
              children: [
                Expanded(
                  child: _InputField(
                    controller: _pondController,
                    label: isTelugu ? 'చెరువు నంబర్' : 'Pond #',
                    hintText: '1, 2, 3...',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InputField(
                    controller: _phController,
                    label: 'pH Level',
                    hintText: '7.5 - 8.5',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _InputField(
                    controller: _doController,
                    label: 'Dissolved Oxygen (mg/L)',
                    hintText: '> 4.0 mg/L',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InputField(
                    controller: _salinityController,
                    label: 'Salinity (ppt)',
                    hintText: '10 - 25 ppt',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _InputField(
                    controller: _tempController,
                    label: 'Temperature (°C)',
                    hintText: '26 - 32 °C',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InputField(
                    controller: _ammoniaController,
                    label: 'Ammonia NH3 (mg/L)',
                    hintText: '< 0.1 mg/L',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _InputField(
              controller: _feedController,
              label: isTelugu ? 'మేత పరిమాణం (kg)' : 'Feed Applied (kg)',
              hintText: '25.0',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _submitTelemetry,
              child: Text(
                isTelugu ? 'లాగ్ సేవ్ చేయండి' : 'Save Telemetry Log',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _VoiceSampleChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _VoiceSampleChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      backgroundColor: AppColors.surfaceElevated,
      side: const BorderSide(color: AppColors.cardBorder),
      label: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textPrimary),
      ),
      onPressed: onTap,
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.outfit(fontSize: 13, color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
