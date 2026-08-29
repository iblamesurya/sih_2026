import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_guard/features/finance/models/finance_models.dart';

void main() {
  group('Expense Model Tests', () {
    test('Expense model serializes to and from JSON cleanly', () {
      final now = DateTime.now();
      final expense = Expense(
        id: 'exp_100',
        category: ExpenseCategory.feed,
        amount: 25000.50,
        date: now,
        pondId: 'p_1',
        pondName: 'Pond 1',
        supplier: 'CP Feeds',
        notes: 'Starter pellet',
      );

      final json = expense.toJson();
      expect(json['id'], equals('exp_100'));
      expect(json['category'], equals('feed'));
      expect(json['amount'], equals(25000.50));
      expect(json['pondName'], equals('Pond 1'));

      final restored = Expense.fromJson(json);
      expect(restored.id, equals(expense.id));
      expect(restored.category, equals(ExpenseCategory.feed));
      expect(restored.amount, equals(25000.50));
      expect(restored.supplier, equals('CP Feeds'));
    });

    test('ExpenseCategory enum properties return valid colors and titles', () {
      for (final cat in ExpenseCategory.values) {
        expect(cat.displayName.isNotEmpty, isTrue);
        expect(cat.color, isNotNull);
        expect(cat.icon, isNotNull);
      }
    });
  });

  group('HarvestRecord Model Tests', () {
    test('HarvestRecord computes total revenue correctly', () {
      final harvest = HarvestRecord(
        id: 'har_50',
        date: DateTime.now(),
        pondId: 'p_2',
        pondName: 'Pond 2',
        harvestType: 'Complete',
        biomassKg: 3000.0,
        countPerKg: 40,
        pricePerKg: 400.0,
        fcr: 1.3,
        buyerName: 'Ocean Fresh',
      );

      expect(harvest.totalRevenue, equals(1200000.0)); // 3000 * 400
    });

    test('HarvestRecord JSON round-trip works', () {
      final harvest = HarvestRecord(
        id: 'har_50',
        date: DateTime.now(),
        pondId: 'p_2',
        pondName: 'Pond 2',
        harvestType: 'Partial',
        biomassKg: 1500.0,
        countPerKg: 50,
        pricePerKg: 350.0,
        fcr: 1.2,
      );

      final json = harvest.toJson();
      final restored = HarvestRecord.fromJson(json);

      expect(restored.id, equals('har_50'));
      expect(restored.biomassKg, equals(1500.0));
      expect(restored.pricePerKg, equals(350.0));
      expect(restored.totalRevenue, equals(525000.0));
    });
  });

  group('Financial Calculations Tests', () {
    test('Net profit calculation equals Total Revenue - Total Expenses', () {
      final expenses = [
        Expense(
          id: '1',
          category: ExpenseCategory.feed,
          amount: 100000,
          date: DateTime.now(),
          pondId: 'p1',
          pondName: 'P1',
        ),
        Expense(
          id: '2',
          category: ExpenseCategory.seedPL,
          amount: 50000,
          date: DateTime.now(),
          pondId: 'p1',
          pondName: 'P1',
        ),
      ];

      final harvests = [
        HarvestRecord(
          id: 'h1',
          date: DateTime.now(),
          pondId: 'p1',
          pondName: 'P1',
          harvestType: 'Complete',
          biomassKg: 1000,
          countPerKg: 40,
          pricePerKg: 400,
          fcr: 1.25,
        ),
      ];

      final totalExpenses = expenses.fold(0.0, (sum, item) => sum + item.amount);
      final totalRevenue = harvests.fold(0.0, (sum, item) => sum + item.totalRevenue);
      final netProfit = totalRevenue - totalExpenses;

      expect(totalExpenses, equals(150000.0));
      expect(totalRevenue, equals(400000.0));
      expect(netProfit, equals(250000.0));
    });
  });
}
