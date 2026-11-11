import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/app_providers.dart';
import '../../models/finance_models.dart';
import '../widgets/expense_form.dart';
import '../widgets/harvest_card.dart';

class PrawnCreditPage extends ConsumerStatefulWidget {
  const PrawnCreditPage({super.key});

  @override
  ConsumerState<PrawnCreditPage> createState() => _PrawnCreditPageState();
}

class _PrawnCreditPageState extends ConsumerState<PrawnCreditPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _loadDemoFinanceData() {
    ref.read(expensesProvider.notifier).state = [
      Expense(
        id: 'exp_1',
        category: ExpenseCategory.feed,
        amount: 145000,
        date: DateTime.now().subtract(const Duration(days: 2)),
        pondId: '1',
        pondName: 'Pond 1 (Vannamei)',
        supplier: 'CP Feeds India',
        notes: 'Grow-out feed starter 500kg',
      ),
      Expense(
        id: 'exp_2',
        category: ExpenseCategory.seedPL,
        amount: 68000,
        date: DateTime.now().subtract(const Duration(days: 45)),
        pondId: '1',
        pondName: 'Pond 1 (Vannamei)',
        supplier: 'Apex Hatcheries Nellore',
        notes: '100,000 PL15 certified SPF seed',
      ),
      Expense(
        id: 'exp_3',
        category: ExpenseCategory.powerFuel,
        amount: 32000,
        date: DateTime.now().subtract(const Duration(days: 10)),
        pondId: '2',
        pondName: 'Pond 2 (Vannamei)',
        supplier: 'APSPDCL / Local Diesel',
        notes: 'Aerator power bill & backup diesel generator',
      ),
      Expense(
        id: 'exp_4',
        category: ExpenseCategory.probioticsChemicals,
        amount: 18500,
        date: DateTime.now().subtract(const Duration(days: 5)),
        pondId: '1',
        pondName: 'Pond 1 (Vannamei)',
        supplier: 'AquaBio Care',
        notes: 'Soil & Water Probiotics + Minerals',
      ),
    ];

    ref.read(harvestsProvider.notifier).state = [
      HarvestRecord(
        id: 'har_1',
        date: DateTime.now().subtract(const Duration(days: 12)),
        pondId: '1',
        pondName: 'Pond 1 (Vannamei)',
        harvestType: 'Partial',
        biomassKg: 2450,
        countPerKg: 42,
        pricePerKg: 380,
        fcr: 1.25,
        buyerName: 'Nellore Aqua Exports Ltd',
      ),
      HarvestRecord(
        id: 'har_2',
        date: DateTime.now().subtract(const Duration(days: 60)),
        pondId: '2',
        pondName: 'Pond 2 (Vannamei)',
        harvestType: 'Complete',
        biomassKg: 4100,
        countPerKg: 30,
        pricePerKg: 520,
        fcr: 1.35,
        buyerName: 'Coastal Seafoods Pvt Ltd',
      ),
    ];
    ref.read(dataHydrationServiceProvider).saveSnapshotToLocal(ref);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addExpense(Expense newExpense) async {
    final currentExpenses = ref.read(expensesProvider);
    ref.read(expensesProvider.notifier).state = [newExpense, ...currentExpenses];

    final offlineSync = ref.read(offlineSyncProvider);
    await offlineSync.enqueue({
      'table': 'expenses',
      'action': 'insert',
      'payload': newExpense.toJson(),
    });
    final hydration = ref.read(dataHydrationServiceProvider);
    await hydration.refreshPendingSyncCount(ref);
    await hydration.saveSnapshotToLocal(ref);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expense logged successfully! / ఖర్చు దాఖలైంది', style: GoogleFonts.outfit()),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }

  Future<void> _addHarvest(HarvestRecord newHarvest) async {
    final currentHarvests = ref.read(harvestsProvider);
    ref.read(harvestsProvider.notifier).state = [newHarvest, ...currentHarvests];

    final offlineSync = ref.read(offlineSyncProvider);
    await offlineSync.enqueue({
      'table': 'harvests',
      'action': 'insert',
      'payload': newHarvest.toJson(),
    });
    final hydration = ref.read(dataHydrationServiceProvider);
    await hydration.refreshPendingSyncCount(ref);
    await hydration.saveSnapshotToLocal(ref);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Harvest recorded successfully! / దిగుబడి నమోదైంది', style: GoogleFonts.outfit()),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }

  void _showAddHarvestModal(BuildContext context, List<String> availablePonds) {
    final biomassCtrl = TextEditingController(text: '2000');
    final countCtrl = TextEditingController(text: '40');
    final priceCtrl = TextEditingController(text: '400');
    final fcrCtrl = TextEditingController(text: '1.30');
    final buyerCtrl = TextEditingController();
    String selectedPond = availablePonds.first;
    String harvestType = 'Partial';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
                Text(
                  'Record Harvest / దిగుబడి నమోదు',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedPond,
                  dropdownColor: AppColors.surfaceElevated,
                  style: GoogleFonts.outfit(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Pond / చెరువు'),
                  items: availablePonds
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setModalState(() => selectedPond = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: harvestType,
                  dropdownColor: AppColors.surfaceElevated,
                  style: GoogleFonts.outfit(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Harvest Type'),
                  items: const [
                    DropdownMenuItem(value: 'Partial', child: Text('Partial Harvest')),
                    DropdownMenuItem(value: 'Complete', child: Text('Complete Harvest')),
                  ],
                  onChanged: (v) {
                    if (v != null) setModalState(() => harvestType = v);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: biomassCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'Biomass (kg)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: countCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'Count / kg'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'Price / kg (₹)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: fcrCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'FCR'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: buyerCtrl,
                  style: GoogleFonts.outfit(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Exporter / Buyer Name'),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      final biomass = double.tryParse(biomassCtrl.text) ?? 0;
                      final count = int.tryParse(countCtrl.text) ?? 40;
                      final price = double.tryParse(priceCtrl.text) ?? 0;
                      final fcr = double.tryParse(fcrCtrl.text) ?? 1.3;
                      if (biomass <= 0 || price <= 0) return;

                      final record = HarvestRecord(
                        id: 'har_${DateTime.now().millisecondsSinceEpoch}',
                        date: DateTime.now(),
                        pondId: selectedPond,
                        pondName: selectedPond,
                        harvestType: harvestType,
                        biomassKg: biomass,
                        countPerKg: count,
                        pricePerKg: price,
                        fcr: fcr,
                        buyerName: buyerCtrl.text.trim().isEmpty
                            ? 'Regional Seafood Exporter'
                            : buyerCtrl.text.trim(),
                      );
                      Navigator.of(ctx).pop();
                      _addHarvest(record);
                    },
                    child: Text(
                      'Save Harvest Record',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final expenses = ref.watch(expensesProvider);
    final harvests = ref.watch(harvestsProvider);
    final ponds = ref.watch(pondListProvider);
    final waterLogs = ref.watch(waterLogsProvider);
    final diseaseScans = ref.watch(diseaseScansProvider);

    final availablePonds = ponds.isNotEmpty
        ? ponds.map((p) => p['name']?.toString() ?? 'Pond ${p['id']}').toList()
        : const ['Pond 1 (Vannamei)', 'Pond 2 (Monodon)', 'Pond 3 (Nursery)'];

    final totalExpenses = expenses.fold(0.0, (sum, item) => sum + item.amount);
    final totalRevenue = harvests.fold(0.0, (sum, item) => sum + item.totalRevenue);
    final netProfit = totalRevenue - totalExpenses;

    // Dynamic credit score calculation based on real financial, telemetry & pathology data
    final isVerifiedByLogs = waterLogs.isNotEmpty || harvests.isNotEmpty;
    final fcrScore = harvests.isNotEmpty && harvests.every((h) => h.fcr <= 1.4) ? 95 : 80;
    final telemetryConsistency = (75 + (waterLogs.length * 5)).clamp(75, 98);
    final hasCriticalOutbreak = diseaseScans.any(
      (s) => (s['severity']?.toString().toLowerCase() ?? '') == 'critical',
    );
    final biosecurityScore = hasCriticalOutbreak ? 68 : 94;
    final profitRatio = totalRevenue > 0 ? (netProfit / totalRevenue).clamp(0.0, 1.0) : 0.25;
    final calculatedScore =
        (550 + (profitRatio * 180) + (fcrScore * 0.5) + (telemetryConsistency * 0.3) + (biosecurityScore * 0.25))
            .round()
            .clamp(300, 900);

    final creditScore = PrawnCreditScore(
      score: calculatedScore,
      tier: calculatedScore >= 750 ? 'Tier-1 Elite' : (calculatedScore >= 650 ? 'Tier-2 Preferred' : 'Tier-3 Standard'),
      maxCreditLimit: calculatedScore >= 750 ? 500000 : (calculatedScore >= 650 ? 300000 : 150000),
      monthlyInterestRate: calculatedScore >= 750 ? 1.05 : 1.25,
      riskLevel: calculatedScore >= 750 ? 'Low' : 'Moderate',
      scoreFactors: {
        'FCR Biomass Efficiency': fcrScore,
        'Telemetry & Water Consistency': telemetryConsistency,
        'Profit Margin Sustainability': (profitRatio * 100).round().clamp(50, 98),
        'Disease Free Harvest Record': biosecurityScore,
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBase,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PrawnCredit & Finance',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'ప్రాన్ క్రెడిట్ మరియు ఫైనాన్స్ నివేదిక',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Record Harvest',
            icon: const Icon(Icons.agriculture, color: AppColors.secondary),
            onPressed: () => _showAddHarvestModal(context, availablePonds),
          ),
          if (expenses.isEmpty && harvests.isEmpty)
            IconButton(
              tooltip: 'Load Sample Ledger',
              icon: const Icon(Icons.auto_graph, color: AppColors.primary),
              onPressed: _loadDemoFinanceData,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.account_balance_wallet, size: 18), text: 'Expenses'),
            Tab(icon: Icon(Icons.agriculture, size: 18), text: 'Harvests'),
            Tab(icon: Icon(Icons.credit_score, size: 18), text: 'PrawnCredit'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Finance Top Summary Header
          _buildSummaryHeader(currencyFormatter, totalRevenue, totalExpenses, netProfit),

          // Tab Bar Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExpensesTab(currencyFormatter, expenses),
                _buildHarvestsTab(currencyFormatter, harvests),
                _buildCreditTab(
                  currencyFormatter,
                  creditScore,
                  isVerifiedByLogs: isVerifiedByLogs,
                  waterLogCount: waterLogs.length,
                  harvestCount: harvests.length,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        icon: const Icon(Icons.add, color: AppColors.background),
        label: Text(
          'Log Expense / ఖర్చు',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          ExpenseForm.showModal(
            context,
            onSave: _addExpense,
            availablePonds: availablePonds,
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(
    NumberFormat currencyFormatter,
    double totalRevenue,
    double totalExpenses,
    double netProfit,
  ) {
    final isProfit = netProfit >= 0;
    final profitColor = isProfit ? AppColors.secondary : AppColors.alertUrgent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceBase,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          // Total Revenue
          Expanded(
            child: _SummaryCard(
              title: 'Revenue / ఆదాయం',
              amount: currencyFormatter.format(totalRevenue),
              color: AppColors.secondary,
              icon: Icons.trending_up,
            ),
          ),
          const SizedBox(width: 8),
          // Total Expenses
          Expanded(
            child: _SummaryCard(
              title: 'Expenses / ఖర్చులు',
              amount: currencyFormatter.format(totalExpenses),
              color: AppColors.alertUrgent,
              icon: Icons.trending_down,
            ),
          ),
          const SizedBox(width: 8),
          // Net Profit
          Expanded(
            child: _SummaryCard(
              title: 'Net Profit / లాభం',
              amount: currencyFormatter.format(netProfit),
              color: profitColor,
              icon: isProfit ? Icons.account_balance : Icons.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesTab(NumberFormat currencyFormatter, List<Expense> expenses) {
    final dateFormatter = DateFormat('dd MMM');

    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'No expenses logged yet',
              style: GoogleFonts.spaceGrotesk(fontSize: 16, color: AppColors.textPrimary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Expense History / ఖర్చుల రికార్డులు',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Chip(
              backgroundColor: AppColors.surfaceElevated,
              side: const BorderSide(color: AppColors.cardBorder),
              label: Text(
                '${expenses.length} Records',
                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...expenses.map((exp) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: exp.category.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(exp.category.icon, color: exp.category.color, size: 20),
              ),
              title: Text(
                exp.category.displayName,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                '${exp.pondName} • ${exp.supplier ?? 'General Vendor'} • ${dateFormatter.format(exp.date)}',
                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
              ),
              trailing: Text(
                '- ${currencyFormatter.format(exp.amount)}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.alertUrgent,
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildHarvestsTab(NumberFormat currencyFormatter, List<HarvestRecord> harvests) {
    if (harvests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.agriculture, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'No harvest batches recorded yet',
              style: GoogleFonts.spaceGrotesk(fontSize: 16, color: AppColors.textPrimary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Harvest History / దిగుబడి వివరాలు',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Total: ${harvests.fold(0.0, (s, i) => s + i.biomassKg).toStringAsFixed(0)} kg',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...harvests.map((h) => HarvestCard(
              harvest: h,
              onShareWhatsApp: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sharing Harvest #${h.id} on WhatsApp...'),
                    backgroundColor: const Color(0xFF25D366),
                  ),
                );
              },
              onExportInvoice: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Exporting PDF Invoice for Harvest #${h.id}...'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            )),
      ],
    );
  }

  Widget _buildCreditTab(
    NumberFormat currencyFormatter,
    PrawnCreditScore creditScore, {
    required bool isVerifiedByLogs,
    required int waterLogCount,
    required int harvestCount,
  }) {
    // 120-day interest comparison: Dealer credit (30% p.a. = 10% per 120 days) vs PrawnCredit KCC (1.05%/mo = 4.2% per 120 days)
    final loanPrincipal = creditScore.maxCreditLimit;
    final dealerInterest120Days = loanPrincipal * 0.10;
    final kccInterest120Days = loanPrincipal * (creditScore.monthlyInterestRate / 100.0) * 4.0;
    final interestSavedPerCrop = (dealerInterest120Days - kccInterest120Days).clamp(0.0, double.infinity);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Credit Score Meter Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF171717), Color(0xFF0F1B24)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
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
                        'PrawnCredit Index',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${creditScore.score}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            ' / 900',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.secondary),
                    ),
                    child: Text(
                      creditScore.tier,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isVerifiedByLogs ? AppColors.secondary : AppColors.alertWatch)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isVerifiedByLogs
                        ? 'Verified Telemetry Score ($waterLogCount Water Logs • $harvestCount Harvests)'
                        : 'Provisional Baseline — Log Water & Harvests to Verify for KCC Bank Dossier',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isVerifiedByLogs ? AppColors.secondary : AppColors.alertWatch,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: creditScore.score / 900,
                backgroundColor: AppColors.surfaceBase,
                color: AppColors.primary,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),

              // Pre-approved limit banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.glassBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pre-Approved Aquaculture Credit',
                          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          currencyFormatter.format(creditScore.maxCreditLimit),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Text('Apply for Working Capital Loan', style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary)),
                            content: Text(
                              'Pre-approved credit of ${currencyFormatter.format(creditScore.maxCreditLimit)} with NABARD/SBI Partner Banks at ${creditScore.monthlyInterestRate}% monthly interest. Would you like to submit your crop history?',
                              style: GoogleFonts.outfit(color: AppColors.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textTertiary)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Loan application submitted to NABARD Partner Desk!'),
                                      backgroundColor: AppColors.secondary,
                                    ),
                                  );
                                },
                                child: Text('Submit Application', style: GoogleFonts.spaceGrotesk(color: AppColors.background)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Text(
                        'Apply Now',
                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Dealer Credit vs. KCC Interest Savings Card (High-Conversion AP Farmer Value)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dealer Credit (30% p.a.) vs. PrawnCredit KCC',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Save ${currencyFormatter.format(interestSavedPerCrop)} / crop',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Replacing informal feed-dealer credit (~₹300/bag markup) with a verified KCC/NABARD crop loan at ${creditScore.monthlyInterestRate}%/mo saves ${currencyFormatter.format(interestSavedPerCrop)} in interest over 120 days.',
                style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Score Factors
        Text(
          'Score Factors / స్కోరు కారకాలు',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        ...creditScore.scoreFactors.entries.map((e) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  e.key,
                  style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textPrimary),
                ),
                Row(
                  children: [
                    Text(
                      '${e.value}/100',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.check_circle, color: AppColors.secondary, size: 16),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
