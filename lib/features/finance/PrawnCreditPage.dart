import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import 'models/finance_models.dart';
import 'widgets/ExpenseForm.dart';
import 'widgets/HarvestCard.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeStarterFinanceDataIfEmpty();
      }
    });
  }

  void _initializeStarterFinanceDataIfEmpty() {
    final currentExpenses = ref.read(expensesProvider);
    final currentHarvests = ref.read(harvestsProvider);

    if (currentExpenses.isEmpty && currentHarvests.isEmpty) {
      // Seed initial realistic aquaculture ledger data
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
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addExpense(Expense newExpense) {
    final currentExpenses = ref.read(expensesProvider);
    ref.read(expensesProvider.notifier).state = [newExpense, ...currentExpenses];

    // Enqueue to offline sync
    final offlineSync = ref.read(offlineSyncProvider);
    offlineSync.enqueue({
      'type': 'INSERT_EXPENSE',
      'expense_data': newExpense.toJson(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Expense logged successfully! / ఖర్చు దాఖలైంది', style: GoogleFonts.outfit()),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final expenses = ref.watch(expensesProvider);
    final harvests = ref.watch(harvestsProvider);

    final totalExpenses = expenses.fold(0.0, (sum, item) => sum + item.amount);
    final totalRevenue = harvests.fold(0.0, (sum, item) => sum + item.totalRevenue);
    final netProfit = totalRevenue - totalExpenses;

    // Dynamic credit score calculation based on real financial ratio
    final fcrScore = harvests.isNotEmpty && harvests.every((h) => h.fcr <= 1.4) ? 95 : 80;
    final profitRatio = totalRevenue > 0 ? (netProfit / totalRevenue).clamp(0.0, 1.0) : 0.25;
    final calculatedScore = (600 + (profitRatio * 200) + (fcrScore * 0.9)).round().clamp(300, 900);

    final creditScore = PrawnCreditScore(
      score: calculatedScore,
      tier: calculatedScore >= 750 ? 'Tier-1 Elite' : (calculatedScore >= 650 ? 'Tier-2 Preferred' : 'Tier-3 Standard'),
      maxCreditLimit: calculatedScore >= 750 ? 500000 : (calculatedScore >= 650 ? 300000 : 150000),
      monthlyInterestRate: calculatedScore >= 750 ? 1.05 : 1.25,
      riskLevel: calculatedScore >= 750 ? 'Low' : 'Moderate',
      scoreFactors: {
        'FCR Biomass Efficiency': fcrScore,
        'Telemetry & Water Consistency': 92,
        'Profit Margin Sustainability': (profitRatio * 100).round().clamp(50, 98),
        'Disease Free Harvest Record': 94,
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
                _buildCreditTab(currencyFormatter, creditScore),
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
          ExpenseForm.showModal(context, onSave: _addExpense);
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

  Widget _buildCreditTab(NumberFormat currencyFormatter, PrawnCreditScore creditScore) {
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
              const SizedBox(height: 16),
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
                                    SnackBar(
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
