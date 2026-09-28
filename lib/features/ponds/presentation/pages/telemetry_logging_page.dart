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

  String _selectedPondId = '1';
  final _phController = TextEditingController(text: '7.85');
  final _doController = TextEditingController(text: '4.8');
  final _salinityController = TextEditingController(text: '18.0');
  final _tempController = TextEditingController(text: '28.5');
  final _ammoniaController = TextEditingController(text: '0.04');
  final _feedController = TextEditingController(text: '25.0');
  final _voiceInputController = TextEditingController();

  String? _detectedTeluguPhrase;

  @override
  void initState() {
    super.initState();
    final ponds = ref.read(pondListProvider);
    if (ponds.isNotEmpty) {
      _selectedPondId = ponds.first['id']?.toString() ?? '1';
    }
  }

  @override
  void dispose() {
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
        _selectedPondId = parsed.pondIndex.toString();
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
    final currentLogs = ref.read(waterLogsProvider);

    final ph = double.tryParse(_phController.text) ?? 7.8;
    final doLevel = double.tryParse(_doController.text) ?? 4.8;
    final ammonia = double.tryParse(_ammoniaController.text) ?? 0.04;
    final salinity = double.tryParse(_salinityController.text) ?? 18.0;
    final temp = double.tryParse(_tempController.text) ?? 28.5;
    final feedKg = double.tryParse(_feedController.text) ?? 25.0;

    // Evaluate water parameters for critical/watch threshold breaches
    final alerts = alertSystem.evaluateParameters(
      ph: ph,
      dissolvedOxygen: doLevel,
      ammonia: ammonia,
    );

    // Update active alerts in state
    ref.read(alertsProvider.notifier).state = alerts;

    // Construct telemetry log
    final newLog = {
      'id': 'log_${DateTime.now().millisecondsSinceEpoch}',
      'pond_id': _selectedPondId,
      'ph': ph,
      'dissolved_oxygen': doLevel,
      'salinity': salinity,
      'temperature': temp,
      'ammonia': ammonia,
      'feed_kg': feedKg,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Update in-memory state so Ponds and Home pages update reactively
    ref.read(waterLogsProvider.notifier).state = [newLog, ...currentLogs];

    // Enqueue mutation for persistent Supabase sync
    await offlineSync.enqueue({
      'type': 'INSERT_WATER_LOG',
      'log_data': newLog,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            alerts.any((a) => a.isUrgent)
                ? 'Logged with Critical Water Quality Warning!'
                : 'Water telemetry logged successfully (Updated & Synced)!',
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
    final ponds = ref.watch(pondListProvider);

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
                          onTap: () {
                            const text = 'చెరువు 2 లో pH 7.8, DO 5.2, feed 25 kg';
                            _voiceInputController.text = text;
                            _parseVoice(text);
                          },
                        ),
                        const SizedBox(width: 8),
                        _VoiceSampleChip(
                          label: 'Pond 1: Salinity 15, Ammonia 0.04',
                          onTap: () {
                            const text = 'Pond 1 lo salinity 15 ppt ammonia 0.04';
                            _voiceInputController.text = text;
                            _parseVoice(text);
                          },
                        ),
                        const SizedBox(width: 8),
                        _VoiceSampleChip(
                          label: 'చెరువు 1: మేత 35 కిలోలు',
                          onTap: () {
                            const text = 'ఉదయం 1వ చెరువులో మేత 35 కిలోలు వేశాము';
                            _voiceInputController.text = text;
                            _parseVoice(text);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Custom Voice / Telugu Text Input Field
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.mic, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _voiceInputController,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: isTelugu
                                  ? 'ఇక్కడ తెలుగులో మాట్లాడండి లేదా టైప్ చేయండి...'
                                  : 'Type or dictate code-mixed Telugu/English...',
                              hintStyle: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                _parseVoice(val);
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                          tooltip: isTelugu ? 'విశ్లేషించండి' : 'Extract Telemetry',
                          onPressed: () {
                            if (_voiceInputController.text.trim().isNotEmpty) {
                              _parseVoice(_voiceInputController.text);
                            }
                          },
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
                        'Parsed: "$_detectedTeluguPhrase"',
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

            // Target Pond Selector Dropdown
            DropdownButtonFormField<String>(
              value: _selectedPondId,
              dropdownColor: AppColors.surfaceElevated,
              style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: isTelugu ? 'సంబంధిత చెరువు' : 'Target Pond',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
              items: ponds.isNotEmpty
                  ? ponds.map((p) {
                      final id = p['id']?.toString() ?? '1';
                      final name = p['name']?.toString() ?? 'Pond $id';
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(name),
                      );
                    }).toList()
                  : const [
                      DropdownMenuItem<String>(
                        value: '1',
                        child: Text('Pond 1'),
                      ),
                      DropdownMenuItem<String>(
                        value: '2',
                        child: Text('Pond 2'),
                      ),
                    ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedPondId = val);
              },
            ),
            const SizedBox(height: 12),

            // Form inputs
            Row(
              children: [
                Expanded(
                  child: _InputField(
                    controller: _phController,
                    label: 'pH Level',
                    hintText: '7.5 - 8.5',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InputField(
                    controller: _doController,
                    label: 'Dissolved Oxygen (mg/L)',
                    hintText: '> 4.0 mg/L',
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
                    controller: _salinityController,
                    label: 'Salinity (ppt)',
                    hintText: '10 - 25 ppt',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InputField(
                    controller: _tempController,
                    label: 'Temperature (°C)',
                    hintText: '26 - 32 °C',
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
                    controller: _ammoniaController,
                    label: 'Ammonia NH3 (mg/L)',
                    hintText: '< 0.1 mg/L',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InputField(
                    controller: _feedController,
                    label: isTelugu ? 'మేత పరిమాణం (kg)' : 'Feed Applied (kg)',
                    hintText: '25.0',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
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
