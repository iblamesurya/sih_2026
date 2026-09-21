import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/app_providers.dart';

/// Profile & Farm Setup Configuration Page (/profile-setup).
class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  ConsumerState<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  final _nameController = TextEditingController(text: 'Surya Tummala');
  final _phoneController = TextEditingController(text: '9876543210');
  final _farmNameController = TextEditingController(text: 'Sri Sai Aquaculture Farms');
  final _districtController = TextEditingController(text: 'West Godavari');

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _farmNameController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    ref.read(currentUserProvider.notifier).state = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
    };
    ref.read(currentFarmProvider.notifier).state = {
      'farmName': _farmNameController.text.trim(),
      'district': _districtController.text.trim(),
    };

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Farm profile saved successfully!'),
        backgroundColor: AppColors.secondary,
      ),
    );
    Navigator.of(context).pop();
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
          isTelugu ? 'రైతు ప్రొఫైల్ సెట్టింగ్‌లు' : 'Profile & Farm Setup',
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
          _ProfileField(
            controller: _nameController,
            label: isTelugu ? 'రైతు పేరు' : 'Farmer Name',
          ),
          const SizedBox(height: 12),
          _ProfileField(
            controller: _phoneController,
            label: isTelugu ? 'మొబైల్ నంబర్' : 'Phone Number (+91)',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _ProfileField(
            controller: _farmNameController,
            label: isTelugu ? 'ఫార్మ్ పేరు' : 'Farm Name',
          ),
          const SizedBox(height: 12),
          _ProfileField(
            controller: _districtController,
            label: isTelugu ? 'జిల్లా / ప్రాంతం' : 'District / Region',
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _saveProfile,
            child: Text(
              isTelugu ? 'భద్రపరచండి' : 'Save Farm Settings',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;

  const _ProfileField({
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
          ),
        ),
      ],
    );
  }
}
