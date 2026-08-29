import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import 'models/finance_models.dart';
import 'widgets/ExpenseForm.dart';
import 'widgets/HarvestCard.dart';

class PrawnCreditPage extends StatefulWidget {
  const PrawnCreditPage({super.key});

  @override
  State<PrawnCreditPage> createState() => _PrawnCreditPageState();
}

class _PrawnCreditPageState extends State<PrawnCreditPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock initial dataset
  final List<Expense> _expenses = [
    Expense(
      id: 'exp_1',
      category: ExpenseCategory.feed,
      amount: 145000,
      date: DateTime.now().subtract(const Duration(days: 2)),
      pondId: 'p_1',
      pondName: 'Pond 1 (Vannamei)',
      supplier: 'CP Feeds India',
      notes: 'Grow-out feed starter 500kg',
    ),
    Expense(
      id: 'exp_2',
      category: ExpenseCategory.seedPL,
      amount: 68000,
      date: DateTime.now().subtract(const Duration(days: 45)),
      pondId: 'p_1',
      pondName: 'Pond 1 (Vannamei)',
      supplier: 'Apex Hatcheries Nellore',
      notes: '100,000 PL15 certified SPF seed',
    ),
    Expense(
      id: 'exp_3',
      category: ExpenseCategory.powerFuel,
      amount: 32000,
      date: DateTime.now().subtract(const Duration(days: 10)),
      pondId: 'p_2',
      pondName: 'Pond 2 (Monodon)',
      supplier: 'APSPDCL / Local Diesel',
      notes: 'Aerator power bill & backup diesel generator',
    ),
    Expense(
      id: 'exp_4',
      category: ExpenseCategory.probioticsChemicals,
      amount: 18500,
      date: DateTime.now().subtract(const Duration(days: 5)),
      pondId: 'p_1',
      pondName: 'Pond 1 (Vannamei)',
      supplier: 'AquaBio Care',
      notes: 'Soil & Water Probiotics + Minerals',
    ),
  ];

  final List<HarvestRecord> _harvests = [
    HarvestRecord(
      id: 'har_1',
      date: DateTime.now().subtract(const Duration(days: 12)),
      pondId: 'p_1',
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
      pondId: 'p_2',
      pondName: 'Pond 2 (Monodon)',
      harvestType: 'Complete',
      biomassKg: 4100,
      countPerKg: 30,
      pricePerKg: 520,
      fcr: 1.35,
      buyerName: 'Coastal Seafoods Pvt Ltd',
    ),
  ];

  final PrawnCreditScore _creditScore = PrawnCreditScore(
    score: 785,
    tier: 'Tier-1 Elite',
    maxCreditLimit: 350000,
    monthlyInterestRate: 1.1,
    riskLevel: 'Low',
    scoreFactors: {
      'FCR Efficiency (1.25 - 1.35)': 94,
      'Water Parameter Logging': 90,
      'Harvest Profit Consistency': 88,
      'Disease Free Crop Record': 96,
    },
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double get _totalExpenses => _expenses.fold(0.0, (sum, item) => sum + item.amount);
  double get _totalRevenue => _harvests.fold(0.0, (sum, item) => sum + item.totalRevenue);
  double get _netProfit => _totalRevenue - _totalExpenses;

  void _addExpense(Expense newExpense) {
    setState(() {
      _expenses.insert(0, newExpense);
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
          _buildSummaryHeader(currencyFormatter),

          // Tab Bar Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExpensesTab(currencyFormatter),
                _buildHarvestsTab(currencyFormatter),
                _buildCreditTab(currencyFormatter),
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

  Widget _buildSummaryHeader(NumberFormat currencyFormatter) {
    final isProfit = _netProfit >= 0;
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
              amount: currencyFormatter.format(_totalRevenue),
              color: AppColors.secondary,
              icon: Icons.trending_up,
            ),
          ),
          const SizedBox(width: 8),
          // Total Expenses
          Expanded(
            child: _SummaryCard(
              title: 'Expenses / ఖర్చులు',
              amount: currencyFormatter.format(_totalExpenses),
              color: AppColors.alertUrgent,
              icon: Icons.trending_down,
            ),
          ),
          const SizedBox(width: 8),
          // Net Profit
          Expanded(
            child: _SummaryCard(
              title: 'Net Profit / లాభం',
              amount: currencyFormatter.format(_netProfit),
              color: profitColor,
              icon: isProfit ? Icons.account_balance : Icons.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesTab(NumberFormat currencyFormatter) {
    final dateFormatter = DateFormat('dd MMM');

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
                '${_expenses.length} Records',
                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ..._expenses.map((exp) {
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
                  color: exp.category.color.withOpacity(0.15),
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

  Widget _buildHarvestsTab(NumberFormat currencyFormatter) {
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
              'Total: ${_harvests.fold(0.0, (s, i) => s + i.biomassKg).toStringAsFixed(0)} kg',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ..._harvests.map((h) => HarvestCard(
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

  Widget _buildCreditTab(NumberFormat currencyFormatter) {
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
            border: Border.all(color: AppColors.primary.withOpacity(0.4)),
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
                            '${_creditScore.score}',
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
                      color: AppColors.secondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.secondary),
                    ),
                    child: Text(
                      _creditScore.tier,
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
                value: _creditScore.score / 900,
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
                          'Pre-Approved Micro-Loan Limit',
                          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          currencyFormatter.format(_creditScore.maxCreditLimit),
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
                              'Pre-approved credit of ₹3,50,000 with NABARD/SBI Partner Banks at 1.1% monthly interest. Would you like to submit your crop history?',
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

        ..._creditScore.scoreFactors.entries.map((e) {
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
