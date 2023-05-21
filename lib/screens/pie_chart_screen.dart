import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';
import 'package:finapp/models/transaction.dart';
import 'package:finapp/models/category.dart';

// Creating the Pie Chart widget
class PieChartScreen extends StatefulWidget {
  final Box<Transaction> transactionsBox;
  final Box<Category> categoriesBox;
  final Map<String, double> currencyRates;
  final List<Transaction> spendingsTransaction;
  final List<Transaction> incomeTransaction;
  final List<Transaction> allTransactions;
  final int bottomNavIndex;
  const PieChartScreen(
      {Key? key,
      required this.transactionsBox,
      required this.categoriesBox,
      required this.currencyRates,
      required this.spendingsTransaction,
      required this.incomeTransaction,
      required this.allTransactions,
      required this.bottomNavIndex})
      : super(key: key);

  @override
  PieChartScreenState createState() => PieChartScreenState();
}

// Creating the Pie Chart State
class PieChartScreenState extends State<PieChartScreen> {
  // Declaring the variables
  List<Transaction> _transactions = [];
  List<Category> _categories = [];

  List<List> data = [];

  String? _touchedCategoryId;

  @override
  // Initializing the state
  void initState() {
    super.initState();
    // Getting the transactions and categories from the Hive box
    _transactions = widget.transactionsBox.values.toList();
    _categories = widget.categoriesBox.values.toList();
  }

  @override
  // Building the widget
  Widget build(BuildContext context) {
    return Column(
      // Setting the alignment to center
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Creating the Pie Chart
        // Expanded widget is used to take the full available height
        Expanded(
          child: PieChart(
            _generatePieChartData(),
            swapAnimationDuration: const Duration(milliseconds: 300),
            // Ease animation starts slowly, speeds up and then slows down again
            swapAnimationCurve: Curves.ease,
          ),
        ),
        // Creating the legend
        Padding(
            padding: const EdgeInsets.all(16.0),
            // If the category is touched, display the category name
            // Otherwise, display the default text
            child: Text(
              _getCategoryName() != ''
                  ? 'Категорія ${_getCategoryName()}'
                  : 'Торкніться сектора для відображення категорії',
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            )),
      ],
    );
  }

  // Generating the pie chart data
  PieChartData _generatePieChartData() {
    Map<String, double> data = _processTransactionData();
    List<String> categoryIds = data.keys.toList();

    return PieChartData(
      // Setting the pie chart sections
      sections: data.entries
          .map(
            (entry) => PieChartSectionData(
              value: entry.value,
              // Setting the color of the pie chart sections
              // The color is based on category and is generated dynamically
              color: Colors.primaries[_categories
                  .indexWhere((category) => category.id == entry.key)],
              title: '${format(entry.value)}%',
              // Radius of the pie chart sections
              // If the category is touched, increase the radius
              radius: _touchedCategoryId == entry.key ? 80 : 70,
            ),
          )
          .toList(),
      // Setting touch data
      pieTouchData: PieTouchData(touchCallback: (event, pieTouchResponse) {
        setState(() {
          // If a user touches area outside the pie chart, set the touched category id to null
          if (pieTouchResponse == null ||
              pieTouchResponse.touchedSection == null||
              pieTouchResponse.touchedSection!.touchedSectionIndex == -1) {
            _touchedCategoryId = null;
          // Otherwise, set the touched category id to the category id of the touched section
          } else {
            _touchedCategoryId = categoryIds[
                pieTouchResponse.touchedSection!.touchedSectionIndex];
          }
        });
      }),
    );
  }

  // Getting the category name
  String _getCategoryName() {
    // If the touched category id is null, return empty string
    if (_touchedCategoryId == null) {
      return '';
    }
    // Otherwise, return the name of the category with the touched category id
    Category? category =
        _categories.firstWhere((category) => category.id == _touchedCategoryId);

    return category.name;
  }
  // Processing the transaction data
  // The method returns a map of category id and the total amount of transactions for that category
  Map<String, double> _processTransactionData() {
    List<Transaction> transactions = [];
    // Bottom navigation index is used to determine which transactions type to use
    switch (widget.bottomNavIndex) {
      case 0:
        transactions = widget.allTransactions;
        break;
      case 1:
        transactions = widget.incomeTransaction;
        break;
      case 2:
        transactions = widget.spendingsTransaction;
        break;
    }
    double totalTransactions = 0;
    Map<String, double> transactionsMap = {};
    // Looping through the transactions
    for (final transaction in transactions) {
      // Getting the category of the transaction
      Category? category =
          _categories.firstWhere((c) => c.id == transaction.categoryId);
      // Converting the transaction amount to the default currency
      double convertedAmount =
          convertToSingleCurrency(transaction.amount, transaction.currency);
      // Adding the converted amount to the total transactions
      totalTransactions += convertedAmount;
      // If the transactions map already contains the category id, add the converted amount to the existing amount
      if (transactionsMap.containsKey(category.id)) {
        transactionsMap[category.id] =
            transactionsMap[category.id]! + convertedAmount;
      // Otherwise, add the category id and the converted amount to the transactions map
      } else {
        transactionsMap[category.id] = convertedAmount;
      }
    }

    // Converting the transactions map to percentage
    transactionsMap = transactionsMap
        .map((key, value) => MapEntry(key, (value / totalTransactions) * 100));

    return transactionsMap;
  }

  // Method to convert the transaction amount to the default currency
  double convertToSingleCurrency(double amount, String currency) {
    double rate = widget.currencyRates[currency] ?? 1.0;
    return amount * rate;
  }

  // Method to format the amount to two decimal places
  String format(double n) {
    return n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2);
  }
}
