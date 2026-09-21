import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/subscription_service.dart';

/// Modal dialog / page to register a new aquaculture pond (/add-pond).
class AddPondModal extends ConsumerStatefulWidget {
  const AddPondModal({super.key});

  @override
  ConsumerState<AddPondModal> createState() => _AddPondModalState();
}

class _AddPondModalState extends ConsumerState<AddPondModal> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _areaController = TextEditingController(text: '1.0');
  final _densityController = TextEditingController(text: '50');
  final _docController = TextEditingController(text: '1');
  final _abwController = TextEditingController(text: '0.02');

  String _selectedSpecies = 'Litopenaeus vannamei';

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _densityController.dispose();
    _docController.dispose();
    _abwController.dispose();
    super.dispose();
  }

  Future<void> _savePond() async {
    if (!_formKey.currentState!.validate()) return;

    final subService = ref.read(subscriptionServiceProvider);
    final tier = ref.read(currentSubscriptionTierProvider);
    final currentPonds = ref.read(pondListProvider);

    final quota = subService.checkPondQuota(
      currentPondCount: currentPonds.length,
      isPro: tier == SubscriptionTier.pro,
    );

    if (!quota.isAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            quota.upgradePrompt ?? 'Free tier pond limit reached (Max 3 ponds). Please upgrade to Pro!',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: AppColors.alertUrgent,
        ),
      );
      return;
    }

    final newPond = {
      'id': 'pond_${DateTime.now().millisecondsSinceEpoch}',
      'name': _nameController.text.trim().isEmpty ? 'Pond ${currentPonds.length + 1}' : _nameController.text.trim(),
      'areaHa': double.tryParse(_areaController.text) ?? 1.0,
      'stockingDensity': int.tryParse(_densityController.text) ?? 50,
      'doc': int.tryParse(_docController.text) ?? 1,
      'species': _selectedSpecies,
      'initialAbw': double.tryParse(_abwController.text) ?? 0.02,
      'status': 'Optimal',
      'created_at': DateTime.now().toIso8601String(),
    };

    ref.read(pondListProvider.notifier).state = [...currentPonds, newPond];

    final offlineSync = ref.read(offlineSyncProvider);
    await offlineSync.enqueue({
      'type': 'INSERT_POND',
      'pond_data': newPond,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pond "${newPond['name']}" created successfully!'),
          backgroundColor: AppColors.secondary,
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
          isTelugu ? 'కొత్త చెరువును నమోదు చేయండి' : 'Add Aquaculture Pond',
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
            TextFormField(
              controller: _nameController,
              style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: isTelugu ? 'చెరువు పేరు / నంబర్' : 'Pond Identifier / Name',
                hintText: 'e.g. Pond 1, South Pond',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: _selectedSpecies,
              dropdownColor: AppColors.surfaceElevated,
              style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: isTelugu ? 'రొయ్యల రకం' : 'Shrimp Species',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Litopenaeus vannamei',
                  child: Text('L. vannamei (Whiteleg Shrimp / వెనామి)'),
                ),
                DropdownMenuItem(
                  value: 'Penaeus monodon',
                  child: Text('P. monodon (Black Tiger / బ్లాక్ టైగర్)'),
                ),
                DropdownMenuItem(
                  value: 'Macrobrachium rosenbergii',
                  child: Text('M. rosenbergii (Scampi / స్కాంపీ)'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedSpecies = val);
              },
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _areaController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: isTelugu ? 'విస్తీర్ణం (హెక్టార్లు)' : 'Water Area (Ha)',
                      hintText: '1.0',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _densityController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: isTelugu ? 'సాంద్రత (PL/m²)' : 'Stocking Density',
                      hintText: '50',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _docController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: isTelugu ? 'ప్రస్తుత DOC (రోజు)' : 'Current DOC (Days)',
                      hintText: '1',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _abwController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: isTelugu ? 'ప్రారంభ బరువు (g)' : 'Initial ABW (g)',
                      hintText: '0.02',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _savePond,
              child: Text(
                isTelugu ? 'చెరువును భద్రపరచండి' : 'Create Pond',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
