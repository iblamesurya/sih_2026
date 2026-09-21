import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/prawndoc_ai_service.dart';
import '../../../../core/services/subscription_service.dart';

/// PrawnDoc AI Vision Disease Diagnostic Page (Tab 3).
class PrawnDocPage extends ConsumerStatefulWidget {
  const PrawnDocPage({super.key});

  @override
  ConsumerState<PrawnDocPage> createState() => _PrawnDocPageState();
}

class _PrawnDocPageState extends ConsumerState<PrawnDocPage> {
  final _notesController = TextEditingController();

  final String _selectedPond = '1';
  String _selectedSampleDisease = 'White Spot Syndrome Virus (WSSV)';
  bool _isAnalyzing = false;
  DiagnosticResult? _diagnosisResult;

  final Map<String, List<int>> _sampleImages = {
    'White Spot Syndrome Virus (WSSV)': List.generate(100, (i) => (i * 7) % 256),
    'Acute Hepatopancreatic Necrosis (AHPND)': List.generate(100, (i) => (i * 13) % 256),
    'Enterocytozoon hepatopenaei (EHP)': List.generate(100, (i) => (i * 19) % 256),
    'White Feces Syndrome (WFS)': List.generate(100, (i) => (i * 23) % 256),
    'Black Gill Disease': List.generate(100, (i) => (i * 31) % 256),
    'Infectious Myonecrosis Virus (IMNV)': List.generate(100, (i) => (i * 37) % 256),
    'Healthy Specimen': List.generate(100, (i) => (i * 41) % 256),
  };

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _runDiagnosis() async {
    setState(() => _isAnalyzing = true);

    final prawnDocService = ref.read(prawnDocAiProvider);
    final subscriptionTier = ref.read(currentSubscriptionTierProvider);
    final imageBytes = Uint8List.fromList(
      _sampleImages[_selectedSampleDisease] ?? [0xFF, 0xD8, 0xFF, 0xE0, 0x00],
    );

    final scans = ref.read(diseaseScansProvider);
    try {
      final result = await prawnDocService.analyzeShrimpImage(
        imageBytes: imageBytes,
        farmerNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        ph: 7.8,
        dissolvedOxygen: 4.5,
        salinity: 18.0,
        ammonia: 0.04,
        temperature: 28.5,
        currentScansToday: scans.length,
        isPro: subscriptionTier == SubscriptionTier.pro,
      );

      setState(() {
        _diagnosisResult = result;
        _isAnalyzing = false;
      });

      // Record to scans provider
      ref.read(diseaseScansProvider.notifier).state = [
        {
          'disease': result.diseaseName,
          'severity': result.severity,
          'confidence': result.confidence,
          'description': result.description,
          'scanned_at': DateTime.now().toIso8601String(),
        },
        ...scans,
      ];
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Diagnostic scan failed: $e'),
            backgroundColor: AppColors.alertUrgent,
          ),
        );
      }
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
          isTelugu ? 'రొయ్య డాక్టర్ AI (PrawnDoc)' : 'PrawnDoc Vision AI',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Scan Capture Hero Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTelugu ? 'రొయ్యల నమూనా చిత్రం' : 'Specimen Image Upload',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '768px • EXIF Strip',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Specimen Selector Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedSampleDisease,
                  dropdownColor: AppColors.surfaceElevated,
                  style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: isTelugu ? 'నమూనా లక్షణాలు' : 'Sample Pathology Preset',
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  items: _sampleImages.keys
                      .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSampleDisease = val);
                  },
                ),
                const SizedBox(height: 12),

                // Farmer observations note input
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: isTelugu ? 'రైతు గమనికలు / లక్షణాలు' : 'Farmer Clinical Observations',
                    hintText: 'e.g. Lethargic swimming on pond surface, empty gut, white spots',
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Water Parameter RAG Preview Strip
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBase,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RAG Context: Pond $_selectedPond',
                        style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AppColors.primary),
                      ),
                      Text(
                        'DO 4.5 • pH 7.8 • NH3 0.04 • 28.5°C',
                        style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Scan / Diagnose Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isAnalyzing ? null : _runDiagnosis,
                    icon: _isAnalyzing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                          )
                        : const Icon(Icons.biotech, size: 20),
                    label: Text(
                      _isAnalyzing
                          ? (isTelugu ? 'విశ్లేషిస్తోంది...' : 'Analyzing Pathology...')
                          : (isTelugu ? 'వ్యాధిని విశ్లేషించండి' : 'Run PrawnDoc Diagnosis'),
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
          const SizedBox(height: 20),

          // Diagnostic Results Display Card
          if (_diagnosisResult != null) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _diagnosisResult!.disease == ShrimpDisease.healthy
                      ? AppColors.secondary
                      : AppColors.alertUrgent,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _diagnosisResult!.diseaseName,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (_diagnosisResult!.severity == 'high' || _diagnosisResult!.severity == 'critical'
                                  ? AppColors.alertUrgent
                                  : AppColors.secondary)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _diagnosisResult!.severity == 'high' || _diagnosisResult!.severity == 'critical'
                                ? AppColors.alertUrgent
                                : AppColors.secondary,
                          ),
                        ),
                        child: Text(
                          '${(_diagnosisResult!.confidence * 100).toStringAsFixed(0)}% Confidence',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _diagnosisResult!.severity == 'high' || _diagnosisResult!.severity == 'critical'
                                ? AppColors.alertUrgent
                                : AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _diagnosisResult!.description,
                    style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Immediate Action Steps
                  Text(
                    isTelugu ? 'తక్షణ చర్యలు' : 'Immediate Recommended Actions',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 14, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _diagnosisResult!.immediateAction,
                            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Biosecurity & Telugu Recommendation
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTelugu ? 'తెలుగు సలహా:' : 'Pathology Telugu Advisory:',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.alertWatch,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _diagnosisResult!.teluguSummary,
                          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
