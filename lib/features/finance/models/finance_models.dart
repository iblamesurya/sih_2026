import 'package:flutter/material.dart';

enum ExpenseCategory {
  feed,
  seedPL,
  powerFuel,
  probioticsChemicals,
  labor,
  equipment,
  other;

  String get displayName {
    switch (this) {
      case ExpenseCategory.feed:
        return 'Feed (దాణా)';
      case ExpenseCategory.seedPL:
        return 'Seed / PL (సీడ్)';
      case ExpenseCategory.powerFuel:
        return 'Power & Fuel (విద్యుత్/డీజిల్)';
      case ExpenseCategory.probioticsChemicals:
        return 'Probiotics & Chemicals (మందులు)';
      case ExpenseCategory.labor:
        return 'Labor (కూలీలు)';
      case ExpenseCategory.equipment:
        return 'Equipment & Repairs (పరికరాలు)';
      case ExpenseCategory.other:
        return 'Other (ఇతర)';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.feed:
        return Icons.restaurant;
      case ExpenseCategory.seedPL:
        return Icons.water_drop;
      case ExpenseCategory.powerFuel:
        return Icons.electric_bolt;
      case ExpenseCategory.probioticsChemicals:
        return Icons.science;
      case ExpenseCategory.labor:
        return Icons.people;
      case ExpenseCategory.equipment:
        return Icons.build;
      case ExpenseCategory.other:
        return Icons.category;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.feed:
        return const Color(0xFF00E5FF);
      case ExpenseCategory.seedPL:
        return const Color(0xFF10B981);
      case ExpenseCategory.powerFuel:
        return const Color(0xFFE5B05C);
      case ExpenseCategory.probioticsChemicals:
        return const Color(0xFF9C27B0);
      case ExpenseCategory.labor:
        return const Color(0xFF5C9EE5);
      case ExpenseCategory.equipment:
        return const Color(0xFFFF9800);
      case ExpenseCategory.other:
        return const Color(0xFF9E9E9E);
    }
  }
}

class Expense {
  final String id;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final String pondId;
  final String pondName;
  final String? supplier;
  final String? notes;

  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.pondId,
    required this.pondName,
    this.supplier,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'amount': amount,
        'date': date.toIso8601String(),
        'pondId': pondId,
        'pondName': pondName,
        'supplier': supplier,
        'notes': notes,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        category: ExpenseCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => ExpenseCategory.other,
        ),
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        pondId: json['pondId'] as String,
        pondName: json['pondName'] as String,
        supplier: json['supplier'] as String?,
        notes: json['notes'] as String?,
      );
}

class HarvestRecord {
  final String id;
  final DateTime date;
  final String pondId;
  final String pondName;
  final String harvestType; // 'Partial' or 'Complete'
  final double biomassKg;
  final int countPerKg;
  final double pricePerKg;
  final double fcr;
  final String? buyerName;

  HarvestRecord({
    required this.id,
    required this.date,
    required this.pondId,
    required this.pondName,
    required this.harvestType,
    required this.biomassKg,
    required this.countPerKg,
    required this.pricePerKg,
    required this.fcr,
    this.buyerName,
  });

  double get totalRevenue => biomassKg * pricePerKg;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'pondId': pondId,
        'pondName': pondName,
        'harvestType': harvestType,
        'biomassKg': biomassKg,
        'countPerKg': countPerKg,
        'pricePerKg': pricePerKg,
        'fcr': fcr,
        'buyerName': buyerName,
      };

  factory HarvestRecord.fromJson(Map<String, dynamic> json) => HarvestRecord(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        pondId: json['pondId'] as String,
        pondName: json['pondName'] as String,
        harvestType: json['harvestType'] as String,
        biomassKg: (json['biomassKg'] as num).toDouble(),
        countPerKg: (json['countPerKg'] as num).toInt(),
        pricePerKg: (json['pricePerKg'] as num).toDouble(),
        fcr: (json['fcr'] as num).toDouble(),
        buyerName: json['buyerName'] as String?,
      );
}

class PrawnCreditScore {
  final int score; // 300 to 900
  final String tier; // 'Tier-1 Elite', 'Tier-2 Preferred', 'Tier-3 Basic'
  final double maxCreditLimit; // e.g. 350000.0
  final double monthlyInterestRate; // e.g. 1.1%
  final String riskLevel; // 'Low', 'Moderate', 'High'
  final Map<String, int> scoreFactors; // e.g. {'FCR Efficiency': 85, 'Water Log Consistency': 92, 'Yield Predictability': 88}

  PrawnCreditScore({
    required this.score,
    required this.tier,
    required this.maxCreditLimit,
    required this.monthlyInterestRate,
    required this.riskLevel,
    required this.scoreFactors,
  });
}
