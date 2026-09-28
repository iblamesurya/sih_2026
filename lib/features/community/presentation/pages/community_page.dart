import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/app_providers.dart';

/// Community & Farmer Knowledge Exchange Forum Page (/community).
class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Biosecurity',
    'Feed Management',
    'Market Trends',
    'Water Quality',
  ];

  late List<Map<String, dynamic>> _discussions;

  @override
  void initState() {
    super.initState();
    _discussions = [
      {
        'id': 'd1',
        'title': 'Bhimavaram Area WSSV Alert & Biosecurity Precautions',
        'teluguTitle': 'భీమవరం ప్రాంతంలో తెల్లమచ్చ వ్యాధి హెచ్చరిక మరియు జాగ్రత్తలు',
        'author': 'Ramesh Naidu (Field Expert)',
        'time': '2 hours ago',
        'replies': 14,
        'category': 'Biosecurity',
        'body': 'Recent rainfall in West Godavari has caused salinity drops and sudden temperature fluctuations. Several ponds in Bhimavaram tested positive for WSSV. Disinfect all netting and test DO twice nightly.',
        'comments': [
          'Thanks for the alert! Increased aeration in Pond 2 immediately.',
          'Salinity dropped from 18 to 11 ppt after yesterday’s downpour.',
        ],
      },
      {
        'id': 'd2',
        'title': 'Optimizing FCR during high summer temperatures (>34°C)',
        'teluguTitle': 'ఎండ కాలంలో మేత వాడకం (FCR) తగ్గింపు సూచనలు',
        'author': 'Dr. K. Srinivas Rao (Aquaculturist)',
        'time': 'Yesterday',
        'replies': 29,
        'category': 'Feed Management',
        'body': 'When water temperature crosses 32°C, shrimp metabolism changes. Reduce afternoon 11 AM feed by 15% and monitor check trays after 90 minutes to prevent bottom decay.',
        'comments': [
          'Using Feed AI check tray feedback has reduced waste significantly.',
        ],
      },
      {
        'id': 'd3',
        'title': 'Current Nellore Mandi procurement price for 30 count vannamei',
        'teluguTitle': 'నెల్లూరు మార్కెట్‌లో 30 కౌంట్ రొయ్యల తాజా ధరలు',
        'author': 'Venkatesh P.',
        'time': '2 days ago',
        'replies': 42,
        'category': 'Market Trends',
        'body': 'Processors in Nellore quoting ₹385/kg for 30 count spot cash. 40 count is at ₹310/kg. Anyone getting better rates with direct plant delivery?',
        'comments': [
          'Kakinada port rates are ₹390/kg for export grade A quality.',
        ],
      },
      {
        'id': 'd4',
        'title': 'High morning ammonia (0.08 ppm) control in low salinity borewell water',
        'teluguTitle': 'బోరు నీటి చెరువుల్లో ఉదయం అమోనియా నివారణ చర్యలు',
        'author': 'Satyanarayana Raju',
        'time': '3 days ago',
        'replies': 8,
        'category': 'Water Quality',
        'body': 'Alkalinity is 140 ppm, but TAN is spiking at dawn. Applied zeolite 50 kg/acre and added sugarcane molasses for C:N ratio rebalancing.',
        'comments': [
          'Ensure continuous aeration before applying probiotic molasses fermentation.',
        ],
      },
    ];
  }

  void _showAskQuestionModal() {
    final locale = ref.read(currentLocaleProvider);
    final isTelugu = locale.languageCode == 'te';
    final user = ref.read(currentUserProvider);
    final authorName = user?['phone'] != null
        ? 'Farmer (${user!['phone']})'
        : (isTelugu ? 'రైతు మిత్రుడు' : 'Local Aqua Farmer');

    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String category = 'Biosecurity';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                          isTelugu ? 'కమ్యూనిటీలో ప్రశ్న అడగండి' : 'Ask Aqua Community',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
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
                    const SizedBox(height: 16),

                    // Category selection
                    Text(
                      isTelugu ? 'విభాగం' : 'Category',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: category,
                      dropdownColor: AppColors.surfaceElevated,
                      style: GoogleFonts.outfit(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                      items: _categories.where((c) => c != 'All').map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => category = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Title
                    Text(
                      isTelugu ? 'ప్రశ్న శీర్షిక' : 'Question Title',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      style: GoogleFonts.outfit(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: isTelugu
                            ? 'ఉదా: తెల్లమచ్చ వ్యాధి లక్షణాలు మరియు నివారణ...'
                            : 'e.g., Sudden drop in dissolved oxygen during overcast...',
                        hintStyle: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Description
                    Text(
                      isTelugu ? 'వివరాలు' : 'Details / Observations',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: bodyCtrl,
                      maxLines: 3,
                      style: GoogleFonts.outfit(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: isTelugu
                            ? 'మీ సమస్య వివరాలు, పారామితులు ఇక్కడ వ్రాయండి...'
                            : 'Provide water parameters, DOC, and behavior details...',
                        hintStyle: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.background,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final title = titleCtrl.text.trim();
                          if (title.isEmpty) return;

                          final newPost = {
                            'id': 'd_${DateTime.now().millisecondsSinceEpoch}',
                            'title': title,
                            'teluguTitle': title,
                            'author': authorName,
                            'time': isTelugu ? 'ఇప్పుడే' : 'Just now',
                            'replies': 0,
                            'category': category,
                            'body': bodyCtrl.text.trim(),
                            'comments': <String>[],
                          };

                          setState(() {
                            _discussions.insert(0, newPost);
                          });

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isTelugu
                                    ? 'ప్రశ్న విజయవంతంగా పోస్ట్ చేయబడింది!'
                                    : 'Question posted to aquaculture network!',
                                style: GoogleFonts.outfit(color: Colors.white),
                              ),
                              backgroundColor: AppColors.secondary,
                            ),
                          );
                        },
                        child: Text(
                          isTelugu ? 'ప్రశ్న పంపండి' : 'Post to Community',
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

  void _showDiscussionDetail(Map<String, dynamic> item) {
    final locale = ref.read(currentLocaleProvider);
    final isTelugu = locale.languageCode == 'te';
    final replyCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDetailState) {
            final comments = (item['comments'] as List<dynamic>?) ?? [];
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item['category'] as String,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isTelugu ? (item['teluguTitle'] ?? item['title']) : item['title'],
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          item['author'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${item['time']}',
                          style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (item['body'] != null && (item['body'] as String).isNotEmpty) ...[
                      Text(
                        item['body'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Divider(color: AppColors.cardBorder),
                    const SizedBox(height: 8),

                    // Comments section
                    Text(
                      isTelugu ? 'సమాధానాలు (${comments.length})' : 'Responses (${comments.length})',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (comments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          isTelugu
                            ? 'ఇంకా సమాధానాలు లేవు. మొదటి సమాధానం ఇవ్వండి!'
                            : 'No replies yet. Be the first to answer!',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      ...comments.map((c) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Text(
                              c.toString(),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )),

                    const SizedBox(height: 12),
                    // Quick reply row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: replyCtrl,
                            style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: isTelugu ? 'సమాధానం రాయండి...' : 'Write an answer...',
                              hintStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.textTertiary),
                              filled: true,
                              fillColor: AppColors.surfaceElevated,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.cardBorder),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send, color: AppColors.primary),
                          onPressed: () {
                            final replyText = replyCtrl.text.trim();
                            if (replyText.isNotEmpty) {
                              setDetailState(() {
                                comments.add(replyText);
                              });
                              setState(() {
                                item['replies'] = (item['replies'] as int) + 1;
                              });
                              replyCtrl.clear();
                            }
                          },
                        ),
                      ],
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

    final filteredDiscussions = _selectedCategory == 'All'
        ? _discussions
        : _discussions.where((d) => d['category'] == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          isTelugu ? 'రైతుల కమ్యూనిటీ ఫోరమ్' : 'Aquaculture Community',
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
        icon: const Icon(Icons.edit),
        label: Text(
          isTelugu ? 'ప్రశ్న అడగండి' : 'Ask Question',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        onPressed: _showAskQuestionModal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Community Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF171717), Color(0xFF1C132E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.forum, color: Color(0xFFCE93D8), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTelugu ? 'ఆంధ్రప్రదేశ్ ఆక్వా రైతుల వేదిక' : 'Andhra Shrimp Farmers Network',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        isTelugu
                            ? 'తాజా మార్కెట్ సమాచారం, వ్యాధి జాగ్రత్తలు పంచుకోండి'
                            : 'Connect with local farmers, share feed tips and disease alerts',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    backgroundColor: AppColors.surface,
                    checkmarkColor: AppColors.primary,
                    labelStyle: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.cardBorder,
                    ),
                    onSelected: (val) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isTelugu ? 'చర్చలు' : 'Discussions (${filteredDiscussions.length})',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_selectedCategory != 'All')
                TextButton(
                  onPressed: () => setState(() => _selectedCategory = 'All'),
                  child: Text(
                    isTelugu ? 'అన్నీ చూపించు' : 'Clear filter',
                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          ...filteredDiscussions.map((d) => InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _showDiscussionDetail(d),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              d['category'] as String,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Text(
                            d['time'] as String,
                            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isTelugu ? (d['teluguTitle'] ?? d['title']) as String : d['title'] as String,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            d['author'] as String,
                            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.comment, size: 12, color: AppColors.textTertiary),
                              const SizedBox(width: 4),
                              Text(
                                '${d['replies']}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
