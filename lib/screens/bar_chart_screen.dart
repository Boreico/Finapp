import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';
import 'package:finapp/models/transaction.dart';
import 'package:finapp/models/category.dart';

// Creating the Bar Chart widget
class BarChartScreen extends StatefulWidget {
  final Box<Transaction> transactionsBox;
  final Box<Category> categoriesBox;
  final Map<String, double> currencyRates;
  final List<Transaction> spendingsTransaction;
  final List<Transaction> incomeTransaction;
  final List<Transaction> allTransactions;
  final int bottomNavIndex;
  final DateTime startDate;
  final DateTime endDate;
  final int dateRange;
  const BarChartScreen({
    Key? key,
    required this.transactionsBox,
    required this.categoriesBox,
    required this.currencyRates,
    required this.spendingsTransaction,
    required this.incomeTransaction,
    required this.allTransactions,
    required this.bottomNavIndex,
    required this.startDate,
    required this.endDate,
    required this.dateRange,
  }) : super(key: key);

  @override
  BarChartScreenState createState() => BarChartScreenState();
}

// Creating the Bar Chart State
class BarChartScreenState extends State<BarChartScreen> {
  // Declaring the variables
  Map<DateTime, double> uahDays = {};
  Map<DateTime, double> usdDays = {};
  Map<DateTime, double> eurDays = {};

  final int _numberOfRods = 1;

  @override
  // Initializing the state
  void initState() {
    super.initState();
  }

  @override
  // Building the widget
  Widget build(BuildContext context) {
    return Column(
      // Setting crossAxisAlignment to start
      // This will align the widgets to the left
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegend(context),
        Expanded(child: _buildBarChart(context))
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Padding(
        // Setting the padding
        padding: const EdgeInsets.only(top: 20, left: 10),
        child: Column(
          // Setting the crossAxisAlignment to start
          // This will align the widgets to the left
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Транзакції (грн)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            // SizedBox is used to add spacing between widgets
            const SizedBox(height: 8),
            // Building the legend
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Building the legend item (UAH)
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xff4af699),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'UAH',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.background,
                    fontSize: 12,
                  ),
                ),
                // SizedBox is used to add spacing between widgets
                const SizedBox(width: 5),
                // Building the legend item (USD)
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xffff5182),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'USD',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.background,
                    fontSize: 12,
                  ),
                ),
                // SizedBox is used to add spacing between widgets
                const SizedBox(width: 5),
                // Building the legend item (EUR)
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xff845bef),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'EUR',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.background,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            // SizedBox is used to add spacing between widgets
            const SizedBox(height: 14),
          ],
        ));
  }

  // Building the Bar Chart
  Widget _buildBarChart(BuildContext context) {
    // LayoutBuilder is used to get the width of the screen
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
            // Setting the padding
            padding: const EdgeInsets.only(left: 12),
            child: BarChart(BarChartData(
              // Setting the alignment to spaceBetween
              // This will adjust the width of the bars
              alignment: BarChartAlignment.spaceBetween,
              // Setting barGroups using _generateBarData()
              barGroups: _generateBarData(
                  constraints, widget.startDate, widget.endDate)['barGroups'],
              // Setting maxY using _getMaxValue()
              maxY: _getMaxValue(_generateBarData(
                  constraints, widget.startDate, widget.endDate)['barGroups']),
              // Setting titlesData
              titlesData: FlTitlesData(
                show: true,
                // Setting bottomTitles using SideTitles()
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    // Each title will show the date
                    getTitlesWidget: (value, meta) {
                      DateTime barDate = _generateBarData(
                              constraints,
                              widget.startDate,
                              widget.endDate)['filteredDays'][value.toInt()]
                          .key;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text("${barDate.day}"),
                      );
                    },
                  ),
                ),
                leftTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                // Setting topTitles to the month of transaction
                topTitles: AxisTitles(
                    sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    DateTime barDate = _generateBarData(
                            constraints,
                            widget.startDate,
                            widget.endDate)['filteredDays'][value.toInt()]
                        .key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: barDate.month <
                              10 // Adding 0 before month if month is less than 10
                          ? Text("0${barDate.month}")
                          : Text("${barDate.month}"),
                    );
                  },
                )),
              ),
              borderData: FlBorderData(show: false),
            )));
      },
    );
  }

  // Generating the Bar Chart Data
  Map<String, dynamic> _generateBarData(
      BoxConstraints constraints, DateTime startDate, DateTime endDate) {
    List<BarChartGroupData> barGroups = [];
    amount(startDate, endDate);

    // filteredDays will contain the days between startDate and endDate
    var filteredDays = uahDays.entries.where((entry) {
      return entry.key.isAfter(startDate.subtract(const Duration(days: 1))) &&
          entry.key.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    // Calculating the width of the bars
    // 0.5 is the space between two bars
    double barsWidth = constraints.maxWidth /
        (filteredDays.length + (filteredDays.length * 0.5));

    // Each day of filteredDays will have a bar group
    for (final day in filteredDays) {
      BarChartGroupData groupData = generateGroupData(
          barsWidth,
          filteredDays.indexOf(day),
          day.value,
          usdDays[day.key]!,
          eurDays[day.key]!);
      barGroups.add(groupData);
    }
    return {
      'barGroups': barGroups.toList(),
      'filteredDays': filteredDays,
    };
  }

  // Generating the Bar Chart Group Data
  BarChartGroupData generateGroupData(
      double barsWidth, int x, double uah, double usd, double eur) {
    return BarChartGroupData(
        x: x,
        barRods: List.generate(_numberOfRods, (index) {
          return BarChartRodData(
              toY: uah + usd + eur,
              rodStackItems: [
                BarChartRodStackItem(0, uah, const Color(0xff4af699)),
                BarChartRodStackItem(uah, uah + usd, const Color(0xffff5182)),
                BarChartRodStackItem(
                    uah + usd, uah + usd + eur, const Color(0xff845bef)),
              ],
              width: barsWidth,
              // Setting borderRadius to zero to get the flat bar
              borderRadius: BorderRadius.zero);
        }));
  }

  // Generating maps for each currency
  // Each map will contain the date as key and the amount as value
  void amount(DateTime startDate, DateTime endDate) {
    // Clearing the maps to avoid duplicate values
    uahDays.clear();
    usdDays.clear();
    eurDays.clear();
    List<Transaction> transactions;
    // Bottom navigation index is used to determine which transactions type to use
    switch (widget.bottomNavIndex) {
      case 0:
        transactions = widget.allTransactions;
        break;
      case 1:
        transactions = widget.incomeTransaction;
        break;
      case 2:
      default:
        transactions = widget.spendingsTransaction;
        break;
    }
    // Looping through each day between startDate and endDate
    for (final transactionDate
        in List<DateTime>.generate((widget.dateRange), (index) {
      return startDate.add(Duration(days: index));
    })) {
      // daysTransactions will contain all the transactions of a day
      List<Transaction> daysTransactions = transactions.where((transaction) {
        return transaction.date.year == transactionDate.year &&
            transaction.date.month == transactionDate.month &&
            transaction.date.day == transactionDate.day;
      }).toList();
      // Calculating the total amount of each currency
      double uahAll = 0;
      double usdAll = 0;
      double eurAll = 0;
      // Looping through each transaction of a day
      for (final transaction in daysTransactions) {
        // Adding the amount to the total amount of each currency
        if (transaction.currency == '₴') {
          uahAll += transaction.amount;
        }
        if (transaction.currency == r'$') {
          usdAll += convertToSingleCurrency(transaction.amount, r'$');
        }
        if (transaction.currency == '€') {
          eurAll += convertToSingleCurrency(transaction.amount, '€');
        }
      }
      // Setting the total amount of each currency to the date in the map
      uahDays[transactionDate] = uahAll;
      usdDays[transactionDate] = usdAll;
      eurDays[transactionDate] = eurAll;
    }
  }

  // Getting the max value of the chart
  double _getMaxValue(List<BarChartGroupData> barGroups) {
    double maxValue = 0;
    for (final barGroup in barGroups) {
      for (final barRod in barGroup.barRods) {
        if (barRod.toY > maxValue) {
          maxValue = barRod.toY;
        }
      }
    }

    return maxValue;
  }

  // Converting the amount of each currency to UAH
  double convertToSingleCurrency(double amount, String currency) {
    double rate = widget.currencyRates[currency] ?? 1.0;
    return amount * rate;
  }
}
