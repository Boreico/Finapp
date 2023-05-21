import 'package:finapp/screens/transaction_screen.dart';
import 'package:flutter/material.dart';
import 'package:finapp/bankings/monobank_api.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finapp/models/transaction.dart';
import 'package:finapp/models/category.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:finapp/screens/dashboard_screen.dart';
import 'package:finapp/screens/settings_screen.dart';
import 'package:finapp/screens/notifications_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finapp/customs/currency_conversion_storage.dart';

// Creating default categories for the first run
Future<void> _loadDefaultCategories(Box<Category> categoriesBox) async {
  final defaultCategories = [
    Category(id: '1', name: 'Продукти', isIncome: false, source: 'user'),
    Category(id: '2', name: 'Податки', isIncome: false, source: 'user'),
    Category(id: '3', name: 'Розваги', isIncome: false, source: 'user'),
    Category(id: '4', name: 'Одяг', isIncome: false, source: 'user'),
    Category(id: '5', name: 'Транспорт', isIncome: false, source: 'user'),
    Category(id: '6', name: 'Інше', isIncome: false, source: 'user'),
    Category(id: '7', name: 'Зарплата', isIncome: true, source: 'user'),
    Category(id: '8', name: 'Подарунок', isIncome: true, source: 'user'),
    Category(id: '9', name: 'Позика', isIncome: true, source: 'user'),
  ];
  for (final category in defaultCategories) {
    await categoriesBox.put(category.id, category);
  }
}

// Main function
void main() async {
  // Initializing Hive and registering adapters
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(CategoryAdapter());

  // Opening boxes
  final transactionBox = await Hive.openBox<Transaction>('transactions');
  final categoriesBox = await Hive.openBox<Category>('categories');

  // Checking if it's the first run
  final prefs = await SharedPreferences.getInstance();
  final isFirstRun = prefs.getBool('isFirstRun') ?? true;

  // Loading default categories if it's the first run
  if (isFirstRun) {
    await _loadDefaultCategories(categoriesBox);
    await prefs.setBool('isFirstRun', false);
  }

  // Fetching exchange rates
  Map<String, double> currencyRates = await fetchExchangeRates();
  ValueNotifier<bool> userHasTransactionsNotifier =
      ValueNotifier<bool>(transactionBox.isNotEmpty);
  // Running the app
  runApp(MyApp(
      transactionsBox: transactionBox,
      categoriesBox: categoriesBox,
      currencyRates: currencyRates,
      hasTransactionsNotifier: userHasTransactionsNotifier));
}

// Fetching exchange rates from Monobank API
MonobankApi monobankApi = MonobankApi();
final Map<String, double> _currencyRates = {'₴': 1};

Future<Map<String, double>> fetchExchangeRates() async {
  try {
    List rates = await monobankApi.fetchExchangeRates();
    _currencyRates[r'$'] = rates[0]['rateSell'];
    _currencyRates['€'] = rates[1]['rateSell'];

    // Saving the rates to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('rate_usd', _currencyRates[r'$']!);
    await prefs.setDouble('rate_eur', _currencyRates['€']!);

    return _currencyRates;
  } catch (e) {
    print("Error fetching exchange rates: $e");

    // Loading the rates from SharedPreferences if fetching failed
    final prefs = await SharedPreferences.getInstance();
    _currencyRates[r'$'] = prefs.getDouble('rate_usd') ?? 1.0;
    _currencyRates['€'] = prefs.getDouble('rate_eur') ?? 1.0;

    return _currencyRates;
  }
}

// Main app widget
class MyApp extends StatefulWidget {
  final Box<Transaction> transactionsBox;
  final Box<Category> categoriesBox;
  final Map<String, double> currencyRates;
  final ValueNotifier<bool> hasTransactionsNotifier;
  const MyApp(
      {Key? key,
      required this.transactionsBox,
      required this.categoriesBox,
      required this.currencyRates,
      required this.hasTransactionsNotifier})
      : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

// Main app state
class MyAppState extends State<MyApp> {
  // Initializing variables
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  bool _currencyConversionEnabled = true;

  // The _screens getter returns a list of screens
  List<Widget> get _screens {
    // If the user has transactions, the dashboard and settings screens are added to the list
    if (widget.hasTransactionsNotifier.value) {
      return [
        TransactionsScreen(
          monobankApi: monobankApi,
          transactionsBox: widget.transactionsBox,
          categoriesBox: widget.categoriesBox,
          currencyRates: widget.currencyRates,
          onTransactionListChanged: _onTransactionListChanged,
        ),
        DashboardScreen(
          transactionsBox: widget.transactionsBox,
          categoriesBox: widget.categoriesBox,
          currencyRates: widget.currencyRates,
        ),
        SettingsScreen(
          monobankApi: monobankApi,
          categoriesBox: widget.categoriesBox,
          transactionsBox: widget.transactionsBox,
          onTransactionListChanged: _onTransactionListChanged,
        ),
        NotificationsScreen(monobankApi: monobankApi),
      ];
    } else {
      // If the user has no transactions, only the transactions screen is added to the list
      return [
        TransactionsScreen(
          monobankApi: monobankApi,
          transactionsBox: widget.transactionsBox,
          categoriesBox: widget.categoriesBox,
          currencyRates: widget.currencyRates,
          onTransactionListChanged: _onTransactionListChanged,
        ),
      ];
    }
  }

  // Defining the animation for the bottom navigation bar
  void _onItemTapped(int index) {
    // Preventing the user from swiping to other screens if there are no transactions
    if (!widget.hasTransactionsNotifier.value && index > 0) {
      return;
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Defining the method for loading currency conversion enabled state
  Future<void> _loadCurrencyConversionEnabled() async {
    bool enabled = await getCurrencyConversionEnabled();
    setState(() {
      _currencyConversionEnabled = enabled;
    });
  }

  // Defining the method for changing currency conversion enabled state
  void _onCurrencyConversionEnabledChanged(bool value) {
    setState(() {
      _currencyConversionEnabled = value;
      setCurrencyConversionEnabled(value);
    });
  }

  // Defining the method for changing the transaction list
  void _onTransactionListChanged() {
    setState(() {
      widget.hasTransactionsNotifier.value = widget.transactionsBox.isNotEmpty;
    });
  }

  @override
  // Initializing the state the currency conversion enabled state
  void initState() {
    super.initState();
    _loadCurrencyConversionEnabled();
  }

  @override
  // Disposing the page controller
  // This prevents memory leaks
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  // Building the app
  Widget build(BuildContext context) {
    // Wrapping the app in CurrencyConversionProvider
    return CurrencyConversionProvider(
      currencyConversionEnabled: _currencyConversionEnabled,
      onCurrencyConversionEnabledChanged: _onCurrencyConversionEnabledChanged,
      child: MaterialApp(
        // Defining the app's localization
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('uk', 'UA'),
        ],
        // Defining the app's theme
        title: 'Finapp',
        // Defining the app's theme
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.white,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        // Creating the app's home screen
        home: Scaffold(
          // Using PageView to switch between screens
          body: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: _screens),
          // Defining the bottom navigation bar
          bottomNavigationBar: SizedBox(
            height: 60,
            child: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.list),
                  label: 'Транзакції',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Статистика',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Налаштування',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications),
                  label: 'Повідомлення',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.tealAccent,
              onTap: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}
