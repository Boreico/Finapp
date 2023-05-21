import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:finapp/models/category.dart';
import 'package:finapp/bankings/monobank_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finapp/screens/categories_screen.dart';
import 'package:finapp/models/transaction.dart';

// Creating widget for the settings screen
class SettingsScreen extends StatefulWidget {
  final MonobankApi monobankApi;
  final Box<Category> categoriesBox;
  final Box<Transaction> transactionsBox;
  final VoidCallback onTransactionListChanged;
  const SettingsScreen({
    Key? key,
    required this.monobankApi,
    required this.categoriesBox,
    required this.transactionsBox,
    required this.onTransactionListChanged,
  }) : super(key: key);

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

// Creating state for the settings screen
class SettingsScreenState extends State<SettingsScreen> {
  // Funtion for getting currency conversion enabled value from shared preferences
  Future<bool> getCurrencyConversionEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('currencyConversionEnabled') ?? true;
  }

  // Function for setting currency conversion enabled value to shared preferences
  Future<void> setCurrencyConversionEnabled(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('currencyConversionEnabled', value);
  }

  // Function that navigates to the categories screen
  void _navigateToCategoriesScreen(BuildContext context) {
    // Setting navigation to the categories screen
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CategoriesScreen(
          categoriesBox: widget.categoriesBox,
          transactionsBox: widget.transactionsBox,
          onTransactionListChanged: widget.onTransactionListChanged,
        ),
        // Setting the transition animation
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Begin defines where the animation starts from
          const begin = Offset(0.0, 1.0);
          // End defines where the animation ends
          const end = Offset.zero;
          // Tween defines the transition animation
          final tween = Tween(begin: begin, end: end);
          // Offset animation defines the animation type
          final offsetAnimation = animation.drive(tween);
          // Returning the child with the animation
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  // Building the settings screen
  Widget build(BuildContext context) {
    // Getting the currency conversion provider from the context
    final currencyConversionProvider = CurrencyConversionProvider.of(context);
    bool currencyConversionEnabled =
        currencyConversionProvider?.currencyConversionEnabled ?? true;
    // Returning the settings screen
    return Scaffold(
        // Setting the app bar
        appBar: AppBar(
          title: const Text('Налаштування'),
        ),
        // Setting the body
        // The body is a ListView widget that contains the settings
        body: ListView(
          children: [
            // Creating a switch list tile for the currency conversion
            SwitchListTile(
              title: const Text('Конвертація валют'),
              value: currencyConversionEnabled,
              onChanged: (bool value) {
                setState(() {
                  // Updating the currency conversion enabled value in the currency conversion provider
                  // This will update the currency conversion enabled value in all the widgets in the app
                  currencyConversionProvider
                      ?.onCurrencyConversionEnabledChanged(value);
                  // The currency conversion enabled value is set to the value
                  currencyConversionEnabled = value;
                  // The currency conversion enabled value is set to shared preferences
                  setCurrencyConversionEnabled(value);
                });
              },
            ),
            // Creating a list tile for the categories
            Column(
              children: <Widget>[
                ListTile(
                  title: const Text('Категорії'),
                  onTap: () => _navigateToCategoriesScreen(context),
                ),
              ],
            ),
          ],
        ));
  }
}

// Creating widget for the currency conversion provider
// This widget is used to provide the currency conversion enabled value to all the widgets in the app
class CurrencyConversionProvider extends InheritedWidget {
  // Declaring variable for currency conversion enabled value
  final bool currencyConversionEnabled;
  // Declaring function for changing the currency conversion enabled value
  // This function is used to change the currency conversion enabled value in the settings screen
  final Function(bool) onCurrencyConversionEnabledChanged;

  const CurrencyConversionProvider({
    Key? key,
    required this.currencyConversionEnabled,
    required this.onCurrencyConversionEnabledChanged,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  // Method for checking if the widget should be updated
  bool updateShouldNotify(CurrencyConversionProvider oldWidget) {
    return currencyConversionEnabled != oldWidget.currencyConversionEnabled;
  }

  // Method for getting the currency conversion provider
  // This method allows us to access the currency conversion provider from any widget in the app
  static CurrencyConversionProvider? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CurrencyConversionProvider>();
  }
}
