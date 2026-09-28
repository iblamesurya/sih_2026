import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/prawndoc_ai_service.dart';
import '../../../../core/services/subscription_service.dart';

/// PrawnDoc AI Vision Disease Diagnostic Page (Tab 3).
/// Supports live Camera capture, Photo Library selection, and sample presets.
class PrawnDocPage extends ConsumerStatefulWidget {
  const PrawnDocPage({super.key});

  @override
  ConsumerState<PrawnDocPage> createState() => _PrawnDocPageState();
}

class _PrawnDocPageState extends ConsumerState<PrawnDocPage> {
  final _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _selectedPondId;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isAnalyzing = false;
  DiagnosticResult? _diagnosisResult;

  // Preset sample specimens for testing without a live shrimp
  final Map<String, List<int>> _sampleImages = {
    'White Spot Syndrome (WSSV)': List.generate(100, (i) => (i * 7) % 256),
    'AHPND / Early Mortality': List.generate(100, (i) => (i * 13) % 256),
    'EHP Microsporidian Parasite': List.generate(100, (i) => (i * 19) % 256),
    'White Feces Syndrome (WFS)': List.generate(100, (i) => (i * 23) % 256),
    'Black Gill Disease': List.generate(100, (i) => (i * 31) % 256),
    'Infectious Myonecrosis (IMNV)': List.generate(100, (i) => (i * 37) % 256),
    'Healthy Specimen (No Lesions)': List.generate(100, (i) => (i * 41) % 256),
  };

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = file.name;
          _diagnosisResult = null; // Reset previous result on new image
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to access camera/gallery: $e'),
            backgroundColor: AppColors.alertUrgent,
          ),
        );
      }
    }
  }

  void _loadSamplePreset(String key) {
    final bytes = Uint8List.fromList(_sampleImages[key] ?? [0xFF, 0xD8, 0xFF, 0xE0]);
    setState(() {
      _selectedImageBytes = bytes;
      _selectedImageName = 'Preset: $key';
      _diagnosisResult = null;
    });
  }

  Future<void> _runDiagnosis() async {
    if (_selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take a photo or select an image first!'),
          backgroundColor: AppColors.alertWatch,
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    final prawnDocService = ref.read(prawnDocAiProvider);
    final subscriptionTier = ref.read(currentSubscriptionTierProvider);
    final scans = ref.read(diseaseScansProvider);
    final waterLogs = ref.read(waterLogsProvider);

    // Extract real RAG telemetry from selected pond if available
    double ph = 7.85;
    double dissolvedOxygen = 4.8;
    double salinity = 18.0;
    double ammonia = 0.04;
    double temperature = 28.5;

    if (_selectedPondId != null) {
      final pondLogs = waterLogs.where((l) => l['pond_id']?.toString() == _selectedPondId).toList();
      if (pondLogs.isNotEmpty) {
        final latest = pondLogs.first;
        ph = (latest['ph'] as num?)?.toDouble() ?? ph;
        dissolvedOxygen = (latest['dissolved_oxygen'] as num?)?.toDouble() ?? dissolvedOxygen;
        salinity = (latest['salinity'] as num?)?.toDouble() ?? salinity;
        ammonia = (latest['ammonia'] as num?)?.toDouble() ?? ammonia;
        temperature = (latest['temperature'] as num?)?.toDouble() ?? temperature;
      }
    }

    try {
      final result = await prawnDocService.analyzeShrimpImage(
        imageBytes: _selectedImageBytes!,
        farmerNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        ph: ph,
        dissolvedOxygen: dissolvedOxygen,
        salinity: salinity,
        ammonia: ammonia,
        temperature: temperature,
        currentScansToday: scans.length,
        isPro: subscriptionTier == SubscriptionTier.pro,
      );

      setState(() {
        _diagnosisResult = result;
        _isAnalyzing = false;
      });

      // Record to scans provider and offline queue
      final scanRecord = {
        'id': 'scan_${DateTime.now().millisecondsSinceEpoch}',
        'pond_id': _selectedPondId ?? 'unassigned',
        'disease': result.diseaseName,
        'severity': result.severity,
        'confidence': result.confidence,
        'description': result.description,
        'immediate_action': result.immediateAction,
        'telugu_summary': result.teluguSummary,
        'scanned_at': DateTime.now().toIso8601String(),
      };

      ref.read(diseaseScansProvider.notifier).state = [scanRecord, ...scans];

      final offlineSync = ref.read(offlineSyncProvider);
      await offlineSync.enqueue({
        'type': 'INSERT_DISEASE_SCAN',
        'scan_data': scanRecord,
      });
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
    final ponds = ref.watch(pondListProvider);

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
          // Image Capture Section
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
                        'Multimodal Gemini 2.5 Vision',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Image Preview or Placeholder
                if (_selectedImageBytes != null)
                  Container(
                    width: double.infinity,
                    height: 200,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _selectedImageBytes!.length > 500
                                ? Image.memory(
                                    _selectedImageBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 200,
                                  )
                                : Container(
                                    color: AppColors.surfaceElevated,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.biotech, size: 48, color: AppColors.primary),
                                          const SizedBox(height: 8),
                                          Text(
                                            _selectedImageName ?? 'Sample Specimen Loaded',
                                            style: GoogleFonts.spaceGrotesk(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            radius: 16,
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 16, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _selectedImageBytes = null;
                                  _selectedImageName = null;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder, style: BorderStyle.solid),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.camera_alt_outlined, size: 40, color: AppColors.textTertiary),
                        const SizedBox(height: 8),
                        Text(
                          isTelugu ? 'ఫోటో తీయండి లేదా గ్యాలరీ నుండి ఎంచుకోండి' : 'Capture shrimp photo or select from gallery',
                          style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                // Camera & Gallery Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.background,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: Text(
                          isTelugu ? 'కెమెరా' : 'Take Photo',
                          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevated,
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppColors.cardBorder),
                          ),
                        ),
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library, size: 18),
                        label: Text(
                          isTelugu ? 'గ్యాలరీ' : 'Choose Gallery',
                          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Sample Preset Dropdown for Fast Testing
                DropdownButtonFormField<String>(
                  value: null,
                  hint: Text(
                    isTelugu ? 'లేదా పరీక్ష కోసం నమూనాను ఎంచుకోండి' : 'Or load sample pathology preset for testing',
                    style: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 12),
                  ),
                  dropdownColor: AppColors.surfaceElevated,
                  style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  items: _sampleImages.keys
                      .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) _loadSamplePreset(val);
                  },
                ),
                const SizedBox(height: 14),

                // Target Pond Selector for RAG context
                DropdownButtonFormField<String>(
                  value: _selectedPondId,
                  hint: Text(
                    isTelugu ? 'చెరువును ఎంచుకోండి (RAG కోసం)' : 'Select Pond for Water RAG Context',
                    style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  dropdownColor: AppColors.surfaceElevated,
                  style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: isTelugu ? 'సంబంధిత చెరువు' : 'Target Pond',
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('General Aquaculture Default (Optimal)'),
                    ),
                    ...ponds.map((p) {
                      final id = p['id']?.toString() ?? '1';
                      final name = p['name']?.toString() ?? 'Pond $id';
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(name),
                      );
                    }),
                  ],
                  onChanged: (val) => setState(() => _selectedPondId = val),
                ),
                const SizedBox(height: 12),

                // Farmer observations note input
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: isTelugu ? 'రైతు గమనికలు / లక్షణాలు' : 'Clinical Observations / Notes',
                    hintText: 'e.g. Lethargic swimming on pond surface, empty gut, white spots on carapace',
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
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
