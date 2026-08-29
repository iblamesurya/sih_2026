import 'package:flutter/material.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  bool _isTelugu = false;

  void _toggleLanguage(bool value) {
    setState(() {
      _isTelugu = value;
    });
    
    // Mocking SharedPreferences change and showing a SnackBar
    final snackBar = SnackBar(
      content: Text(
        _isTelugu 
            ? 'భాష తెలుగుకి మార్చబడింది (Language changed to Telugu)' 
            : 'Language changed to English',
      ),
      backgroundColor: const Color(0xFF171717),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B),
      appBar: AppBar(
        title: const Text('More'),
        backgroundColor: const Color(0xFF171717),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          _buildListTile(
            icon: Icons.language,
            title: 'Language',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'English / తెలుగు',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _isTelugu,
                  onChanged: _toggleLanguage,
                  activeColor: const Color(0xFF00E5FF),
                  inactiveTrackColor: Colors.grey.shade800,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildListTile(
            icon: Icons.person,
            title: 'Farm Profile',
            subtitle: 'John Doe • West Godavari',
          ),
          const SizedBox(height: 8),
          _buildListTile(
            icon: Icons.sync,
            title: 'Offline Sync',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Synced',
                style: TextStyle(color: Colors.green, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildListTile(
            icon: Icons.chat,
            title: 'WhatsApp Expert',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening WhatsApp...')),
              );
            },
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'App Version 1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(color: Colors.grey),
              )
            : null,
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
