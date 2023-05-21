// imort required packages
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:meta/meta.dart';


// Define a TypeAdapter indentifier for Hive
part 'transaction.g.dart';

// Define a Transaction data model
@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3) 
  final DateTime date;

  @HiveField(5)
  final String categoryId;

  @HiveField(6)
  final String description;

  @HiveField(7)
  final bool isIncome;

  @HiveField(8)
  final String currency;

  // Define a constructor
  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.description,
    this.isIncome = false,
    required this.currency,
});
  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    String? categoryId,
    String? description,
    bool? isIncome,
    String? currency,

  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      isIncome: isIncome ?? this.isIncome,
      currency: currency ?? this.currency,
    );
  }
}
