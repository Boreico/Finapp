import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:finapp/models/transaction.dart';
import 'package:finapp/models/category.dart';
import 'package:finapp/screens/bar_chart_screen.dart';
import 'package:finapp/screens/pie_chart_screen.dart';

// Setting the available chart types
enum DashboardChartType { pieChart, barChart }

// Creating a stateful widget
class DashboardScreen extends StatefulWidget {
  final Box<Transaction> transactionsBox;
  final Box<Category> categoriesBox;

  final Map<String, double> currencyRates;
  const DashboardScreen(
      {Key? key,
      required this.transactionsBox,
      required this.categoriesBox,
      required this.currencyRates})
      : super(key: key);

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

// Creating a state
class DashboardScreenState extends State<DashboardScreen> {
  // Declaring variables with default values
  late PageController _pageController;

  DashboardChartType _chartSelected = DashboardChartType.pieChart;

  int _bottomNavIndex = 0;

  int _selectedIndex = 0;
  static List<Widget> _screens = [];
  List<Transaction> _transactions = [];
  List<Category> _categories = [];

  List<List> data = [];

  int _shift = 0;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  DateTime _firstDate = DateTime(2022, 1);
  // The last date is set to tomorrow to include the current day when setting the date range
  final DateTime _lastDate = DateTime.now().add(const Duration(days: 1));
  int _dateRange = 7;

  @override
  // Initializing the state
  void initState() {
    super.initState();
    // Getting the transactions and categories from the Hive box
    _transactions = widget.transactionsBox.values.toList();
    _categories = widget.categoriesBox.values.toList();
    // Initializing the page controller
    _pageController = PageController(initialPage: _chartSelected.index);
    // Setting the _firstDate, the date of the oldest transaction
    // Subtracting the time from the date to set it to 00:00:00
    _firstDate = _transactions
        .reduce((oldest, current) {
          return oldest.date.isBefore(current.date) ? oldest : current;
        })
        .date;
    _firstDate  =_firstDate.subtract(Duration(
        hours: _firstDate.hour,
        minutes: _firstDate.minute,
        seconds: _firstDate.second,
        milliseconds: _firstDate.millisecond));
    // Setting the _endDate, the date of the newest transaction
    _endDate = _transactions
        .reduce((oldest, current) {
          return oldest.date.isAfter(current.date) ? oldest : current;
        })
        .date
        .add(const Duration(days: 1));
    // Setting the _startDate and the _dateRange
    if (_endDate.difference(_firstDate).inDays < 7) {
      // _startDate is the first day of date range
      _startDate = _endDate.subtract(
          Duration(seconds: _endDate.difference(_firstDate).inSeconds));
      // _dateRange is the number of days between the _startDate and the _endDate
      _dateRange = _endDate.difference(_firstDate).inDays;
    } else {
      _startDate = _endDate.subtract(const Duration(days: 7));
      _dateRange = 7;
    }
    // Setting the _shift, the number of days between the _firstDate and the _startDate
    // It indicates the slider position
    _shift = _startDate.difference(_firstDate).inDays;
  }

  // Dispose of the page controller
  // To avoid memory leaks
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Building the widget
  @override
  Widget build(BuildContext context) {
    // Creating a list of transactions for the selected date range
    // The list contains 3 lists:
    // 1. List of spendings transactions
    // 2. List of income transactions
    // 3. List of all transactions
    List data = _processTransactionData();
    // Setting the _screens list
    _screens = [
      BarChartScreen(
          transactionsBox: widget.transactionsBox,
          categoriesBox: widget.categoriesBox,
          currencyRates: widget.currencyRates,
          spendingsTransaction: data[0],
          incomeTransaction: data[1],
          allTransactions: data[2],
          bottomNavIndex: _bottomNavIndex,
          startDate: _startDate,
          endDate: _endDate,
          dateRange: _dateRange),
      PieChartScreen(
          transactionsBox: widget.transactionsBox,
          categoriesBox: widget.categoriesBox,
          currencyRates: widget.currencyRates,
          spendingsTransaction: data[0],
          incomeTransaction: data[1],
          allTransactions: data[2],
          bottomNavIndex: _bottomNavIndex),
    ];
    // Building the widget
    return Scaffold(
      // Setting the app bar with the date button and the chart dropdown button
      appBar: AppBar(
        title: const Text('Статистика'),
        actions: [dateButton(), _buildChartDropdownButton()],
      ),
      // If the date range is less than 2 days
      // Display the message
      body: _endDate.difference(_firstDate).inHours <= 24
          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Статистика доступна після більше ніж доби різниці між датами транзакцій',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  )),
            ])
          // Otherwise display the charts
          : _buildSelectedChart(),
    );
  }

  // Building the button to choose the chart type
  // It is located on the app bar
  Widget _buildChartDropdownButton() {
    return PopupMenuButton<DashboardChartType>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      onSelected: _setSelectedChart,
      icon: const Icon(Icons.more_vert),
      itemBuilder: (BuildContext context) =>
          <PopupMenuEntry<DashboardChartType>>[
        const PopupMenuItem<DashboardChartType>(
          value: DashboardChartType.pieChart,
          child: Text('Категоріальний аналіз транзакцій'),
        ),
        const PopupMenuItem<DashboardChartType>(
          value: DashboardChartType.barChart,
          child: Text('Гістограми транзакцій'),
        ),
      ],
    );
  }

  // Method to set the selected chart
  void _setSelectedChart(DashboardChartType selectedChart) {
    setState(() {
      _chartSelected = selectedChart;
      _pageController.animateToPage(
        _chartSelected.index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    });
  }

  // Building the date button
  // It is the text button which shows the selected date range
  // And opens the date range picker
  Widget dateButton() {
    return TextButton(
      onPressed: () async {
        DateTimeRange? result = await showDateRangePicker(
            context: context,
            firstDate: _firstDate,
            lastDate: _lastDate,
            initialDateRange: DateTimeRange(start: _startDate, end: _endDate));
        if (result != null) {
          setState(() {
            // Updating the values of the date range
            _startDate = result.start;
            _endDate = result.end;
            _shift = _startDate.difference(_firstDate).inDays;
            _dateRange = _endDate.difference(_startDate).inDays;
          });
        }
      },
      child: Text(
        [
          DateFormat('dd-MM-yyyy').format(_startDate),
          '-',
          DateFormat('dd-MM-yyyy').format(_endDate)
        ].join(''),
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Building the selected chart
  // By using the PageView
  Widget _buildSelectedChart() {
    return Column(
      children: [
        Expanded(
          child: SizedBox(
            height: 300,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              scrollDirection: Axis.vertical,
              children: _screens,
            ),
          ),
        ),
        daysShift(),
        bottomNavBar(),
      ],
    );
  }

  // Building the bottom navigation bar
  // It is used to switch between transactions types used to generate the chart:
  // 1. All transactions
  // 2. Income transactions
  // 3. Spendings transactions
  Widget bottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _bottomNavIndex,
      selectedItemColor: Colors.tealAccent,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.compare_arrows),
          label: 'Загальний',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.arrow_upward),
          label: 'Надходження',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.arrow_downward),
          label: 'Витрати',
        ),
      ],
      onTap: (int index) {
        setState(() {
          _bottomNavIndex = index;
        });
      },
    );
  }

  // Building the slider to shift the date range
  Widget daysShift() {
    // totalDays - the number of days between the first transaction the tomorrow
    int totalDays = _lastDate.difference(_firstDate).inDays;
    _dateRange = _endDate.difference(_startDate).inDays;
    return Column(
      children: [
        Slider(
          value: _shift.toDouble(),
          min: 0,
          max: totalDays - _dateRange.toDouble(),
          onChanged: (value) {
            setState(() {
              _shift = value.toInt();
              _startDate = _firstDate.add(Duration(days: value.toInt()));
              _endDate = _startDate.add(Duration(days: _dateRange));
            });
          },
        ),
      ],
    );
  }

  // Method that splits the transactions into 3 lists:
  // 1. Spendings transactions
  // 2. Income transactions
  // 3. All transactions
  List<List<Transaction>> _processTransactionData() {
    List<Transaction> spendingsData = [];
    List<Transaction> incomeData = [];
    List<Transaction> allTransactionsData = [];
    for (final transaction in _transactions.where(
        (t) => t.date.isAfter(_startDate) && t.date.isBefore(_endDate))) {
      if (transaction.isIncome) {
        incomeData.add(transaction);
      } else {
        spendingsData.add(transaction);
      }
      allTransactionsData.add(transaction);
    }

    return [spendingsData, incomeData, allTransactionsData];
  }

  // Method that converts the amount of money to the chosen currency
  double convertToSingleCurrency(double amount, String currency) {
    double rate = widget.currencyRates[currency] ?? 1.0;
    return amount * rate;
  }
}
