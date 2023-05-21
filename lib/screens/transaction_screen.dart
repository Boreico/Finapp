import 'package:finapp/models/category.dart';
import 'package:flutter/material.dart';
import 'package:finapp/models/transaction.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:finapp/screens/settings_screen.dart';
import 'package:finapp/customs/custom_expansion_tile.dart';
import 'package:finapp/bankings/monobank_api.dart';
import 'package:finapp/customs/custom_app_bar.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'dart:ui';

// Creating transaction screen widget
class TransactionsScreen extends StatefulWidget {
  final MonobankApi monobankApi;
  final Box<Transaction> transactionsBox;
  final Box<Category> categoriesBox;
  final Map<String, double> currencyRates;
  final VoidCallback onTransactionListChanged;

  const TransactionsScreen(
      {Key? key,
      required this.monobankApi,
      required this.transactionsBox,
      required this.categoriesBox,
      required this.currencyRates,
      required this.onTransactionListChanged})
      : super(key: key);

  @override
  TransactionsScreenState createState() => TransactionsScreenState();
}

// Creating transaction screen state
class TransactionsScreenState extends State<TransactionsScreen> {
  // Defining variables
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];

  final List<String> _supportedCurrencies = ['₴', r'$', '€'];

  bool _isSearchEnabled = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _transactionAmountController =
      TextEditingController();

  List<Category> _categories = [];
  late String _transactionCategoryId;

  bool currencyConversionEnabled = true;

  bool _transactionAmountControllerInitialized = false;
  String _previousTransactionId = '';

  bool _transactionIsIncome = false;
  String _transactionTitle = '';
  double _transactionAmount = 0.0;
  DateTime _transactionDate = DateTime.now();
  String _transactionDescription = '';
  String _transactionCurrency = '₴';

  @override
  // Initializing state
  void initState() {
    super.initState();
    // Loading transactions and categories from Hive
    _loadTransactions(widget.transactionsBox);
    _loadCategories(widget.categoriesBox);
    // Setting up amount controller listener
    _transactionAmountController.text = _transactionAmount.toStringAsFixed(2);
  }

  @override
  // Disposing amount controller
  // This is done to prevent memory leaks
  void dispose() {
    _transactionAmountController.dispose();
    super.dispose();
  }

  @override
  // Building transaction screen widget
  Widget build(BuildContext context) {
    return Builder(builder: (BuildContext context) {
      // Getting currency conversion provider
      final currencyConversionProvider = CurrencyConversionProvider.of(context);
      currencyConversionEnabled =
          currencyConversionProvider?.currencyConversionEnabled ?? true;
      // Grouping transactions by date
      final groupedTransactions =
          _groupTransactionsByRange(_filteredTransactions);
      // Building transaction screen
      return Scaffold(
        // Adding app bar
        // See lib/customs/custom_app_bar.dart
        appBar: CustomAppBar(
          title: 'Транзакції',
          isSearchEnabled: _isSearchEnabled,
          searchController: _searchController,
          onSearchChanged: (value) {
            _searchTransactions(value);
          },
          onSearchStateChanged: _onSearchStateChanged,
        ),
        // If there are no transactions, show message
        body: _transactions.isEmpty
            ? Center(
                child: Text(
                  'Немає транзакцій, додайте першу',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              )
            :
            // Otherwise show transactions list
            Column(
                children: [
                  Expanded(
                    child: ListView(
                      // Adding list view
                      children: groupedTransactions
                          .entries // Children are grouped transactions
                          .expand(
                            (entry) => [
                              if (entry.value.isEmpty)
                                Container()
                              else // If there are no transactions, show empty container
                                _buildDateHeader(
                                    entry.key), // Otherwise show date header
                              ...entry.value
                                  .map((transaction) => _buildTransactionItem(
                                      transaction)) // And transaction item
                                  .toList(),
                            ],
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
        // Adding floating action button
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Showing transaction form
            _showTransactionForm(context);
          },
          backgroundColor: Colors.tealAccent,
          child: const Icon(Icons.add),
        ),
      );
    });
  }

  // Widget of transaction item
  Widget _buildTransactionItem(Transaction transaction) {
    // Getting transaction category
    Category? category =
        _categories.firstWhere((c) => c.id == transaction.categoryId);
    // Getting category name
    String categoryName = category.name;
    // Formatting transaction date
    String formattedDate =
        DateFormat('HH:mm dd-MM-yyyy').format(transaction.date);
    // Building transaction item
    return Card(
      // Setting card color to be transparent
      color: Theme.of(context).cardColor.withOpacity(0.55),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.all(8),
      // Adding custom expansion tile
      // See lib/customs/custom_expansion_tile.dart
      child: CustomExpansionTile(
        transactionsBox: widget.transactionsBox,
        transactionId: transaction.id,
        onTransactionListChanged: widget.onTransactionListChanged,
        title: ListTile(
          leading: Container(
            width: 60,
            height: 60,
            // Adding colored box with transaction amount
            // Red for expenses, green for incomes
            decoration: BoxDecoration(
              color: transaction.isIncome ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: FittedBox(
                child: Text(
                    '${transaction.currency}${format(transaction.amount)}'),
              ),
            ),
          ),
          title: Text(
            transaction.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          subtitle: Text(
            formattedDate,
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            color: Theme.of(context).colorScheme.background,
            onPressed: () => _showTransactionForm(context, transaction),
          ),
        ),
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Категорія: $categoryName'),
                Text('Опис: ${transaction.description}'),
              ],
            ),
          )
        ],
        onDelete: (id) {
          setState(() {
            _filteredTransactions
                .removeWhere((transaction) => transaction.id == id);
          });
        },
      ),
    );
  }

  // Building date header
  Widget _buildDateHeader(String headerText) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      child: Text(headerText,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey)),
    );
  }

  // Building transaction form
  Widget _buildAddTransactionForm(
      BuildContext context,
      StateSetter setState,
      BuildContext bottomSheetContext,
      Transaction? transaction,
      bool currencyConversionEnabled) {
    // Setting up transaction amount controller
    return Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 24, left: 7, right: 7),
        child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Material(
                    elevation: 5,
                    color: Theme.of(context).cardColor.withOpacity(0.8),
                    child: WillPopScope(
                      onWillPop: () async {
                        _transactionAmountController.text = '';
                        _transactionAmountControllerInitialized = false;
                        _previousTransactionId = '';

                        return true;
                      },
                      // Creating bottom sheet
                      child: Container(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                          left: 16,
                          right: 16,
                          top: 16,
                        ),
                        // Adding form
                        child: SingleChildScrollView(
                          child: StatefulBuilder(
                            builder: (BuildContext context,
                                StateSetter localSetState) {
                              // Updating transaction amount controller
                              // All this if statements are needed to set up amount controller
                              if (transaction != null) {
                                if (_previousTransactionId != transaction.id) {
                                  _transactionAmountControllerInitialized =
                                      false;
                                  _previousTransactionId = transaction.id;
                                }
                                if (!_transactionAmountControllerInitialized) {
                                  _transactionAmount = transaction.amount;
                                  _transactionAmountController.text =
                                      _transactionAmount.toStringAsFixed(2);
                                  _transactionAmountControllerInitialized =
                                      true;
                                }
                              } else if (_previousTransactionId.isNotEmpty) {
                                _transactionAmount = 0.0;
                                _transactionAmountController.text = '0.0';
                                _transactionAmountControllerInitialized = false;
                                _previousTransactionId = '';
                              }
                              return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // The childern is field of the form
                                    // Name field
                                    TextFormField(
                                      initialValue: _transactionTitle,
                                      decoration: const InputDecoration(
                                          labelText: 'Назва'),
                                      onChanged: (value) {
                                        localSetState(() {
                                          _transactionTitle = value;
                                        });
                                      },
                                    ),
                                    // Selecting is transaction income or expense
                                    SwitchListTile(
                                      title: const Text('Надходження'),
                                      value: _transactionIsIncome,
                                      onChanged: (bool value) {
                                        localSetState(() {
                                          _transactionIsIncome = value;
                                          _transactionCategoryId = _categories
                                              .firstWhere((category) =>
                                                  category.isIncome == value)
                                              .id;
                                        });
                                      },
                                    ),
                                    // Amount field with currency selection
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: <Widget>[
                                        // Using Flexible to adjast width of the field
                                        Flexible(
                                          // Currency field (smaller)
                                          flex: 1,
                                          child:
                                              DropdownButtonFormField<String>(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            dropdownColor: Theme.of(context)
                                                .cardColor
                                                .withOpacity(0.95),
                                            value: _transactionCurrency,
                                            onChanged: (String? value) {
                                              if (value != null &&
                                                  value !=
                                                      _transactionCurrency) {
                                                setState(() {
                                                  double previousRate = widget
                                                          .currencyRates[
                                                      _transactionCurrency]!;
                                                  double newRate = widget
                                                      .currencyRates[value]!;
                                                  // Converting transaction amount if currency conversion enabled
                                                  if (currencyConversionEnabled) {
                                                    _transactionAmount =
                                                        _transactionAmount *
                                                            (previousRate /
                                                                newRate);
                                                    _transactionAmountController
                                                            .text =
                                                        _transactionAmount
                                                            .toStringAsFixed(2);
                                                    _transactionCurrency =
                                                        value;
                                                  }
                                                });
                                              }
                                            },
                                            items: _supportedCurrencies
                                                .map<DropdownMenuItem<String>>(
                                                    (String currency) {
                                              return DropdownMenuItem<String>(
                                                value: currency,
                                                child: Container(
                                                  color: Colors.transparent,
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 8),
                                                  child: Center(
                                                    child: Text(currency),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                        Flexible(
                                          // Amount field (bigger)
                                          flex: 6,
                                          child: TextFormField(
                                            controller:
                                                _transactionAmountController,
                                            decoration: const InputDecoration(
                                              labelText: 'Сума',
                                              contentPadding:
                                                  EdgeInsets.all(5.0),
                                            ),
                                            keyboardType: const TextInputType
                                                    .numberWithOptions(
                                                decimal: true),
                                            onChanged: (value) {
                                              localSetState(() {
                                                _transactionAmount =
                                                    double.tryParse(value) ??
                                                        0.0;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Description field
                                    TextFormField(
                                      initialValue: _transactionDescription,
                                      decoration: const InputDecoration(
                                          labelText: 'Опис'),
                                      onChanged: (value) {
                                        localSetState(() {
                                          _transactionDescription = value;
                                        });
                                      },
                                    ),
                                    // Date and time selection
                                    TextButton(
                                      onPressed: () async {
                                        await _showDateTimePicker(
                                            localSetState, _transactionDate,
                                            (DateTime? pickedDate) {
                                          if (pickedDate != null) {
                                            _transactionDate = pickedDate;
                                          }
                                        });
                                      },
                                      // Displaying transaction date
                                      child: Text(
                                        DateFormat('HH:mm dd-MM-yyyy')
                                            .format(_transactionDate),
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    // Selecting transaction category
                                    DropdownButton<String>(
                                      borderRadius: BorderRadius.circular(15),
                                      dropdownColor: Theme.of(context)
                                          .cardColor
                                          .withOpacity(0.95),
                                      value: _transactionCategoryId.isNotEmpty
                                          ? _transactionCategoryId
                                          : null,
                                      hint: const Text('Вибрати категорію'),
                                      onChanged: (value) {
                                        localSetState(() {
                                          _transactionCategoryId =
                                              value.toString();
                                        });
                                      },
                                      items: _categories
                                          .where((category) => _transactionIsIncome
                                              ? category.isIncome == true
                                              : category.isIncome ==
                                                  false) // Filter categories based on _transactionIsIncome value
                                          .map((category) =>
                                              DropdownMenuItem<String>(
                                                alignment: Alignment.center,
                                                value: category.id,
                                                child: Text(category.name),
                                              ))
                                          .toList(),
                                    ),
                                    // Save button
                                    ElevatedButton(
                                      onPressed: () async {
                                        // If transaction is not null, then we are editing existing transaction
                                        if (transaction != null) {
                                          // Update the transaction with new values from the form
                                          final updatedTransaction =
                                              transaction.copyWith(
                                            id: transaction.id,
                                            title: _transactionTitle,
                                            amount: _transactionAmount,
                                            date: _transactionDate,
                                            categoryId: _transactionCategoryId,
                                            description:
                                                _transactionDescription,
                                            isIncome: _transactionIsIncome,
                                            currency: _transactionCurrency,
                                          );
                                          await _saveTransaction(
                                              updatedTransaction,
                                              bottomSheetContext,
                                              widget.transactionsBox);
                                          // If transaction is null, then we are adding new transaction
                                        } else {
                                          // If any of the required fields is empty, then do not save transaction
                                          if (_transactionTitle.isEmpty ||
                                              _transactionAmount <= 0 ||
                                              _transactionCategoryId.isEmpty) {
                                            return;
                                          }
                                          // Creating new transaction
                                          final newTransaction = Transaction(
                                            id: DateTime.now().toString(),
                                            title: _transactionTitle,
                                            amount: _transactionAmount,
                                            date: _transactionDate,
                                            categoryId: _transactionCategoryId,
                                            description:
                                                _transactionDescription,
                                            isIncome: _transactionIsIncome,
                                            currency: _transactionCurrency,
                                          );
                                          await _saveTransaction(
                                              newTransaction,
                                              bottomSheetContext,
                                              widget.transactionsBox);
                                          _transactionAmountController.clear();
                                          widget.onTransactionListChanged();
                                        }
                                      },
                                      // Displaying different text on the button based on transaction value
                                      child: Text(
                                        transaction != null
                                            ? 'Оновити транзакцію'
                                            : 'Додати транзакцію',
                                      ),
                                    ),
                                  ]);
                            },
                          ),
                        ),
                      ),
                    )))));
  }

  // Method to show transaction form
  void _showTransactionForm(BuildContext context, [Transaction? transaction]) {
    // Set initial values for the form fields
    // If transaction is not null, then we are editing an existing transaction
    setState(() {
      _transactionIsIncome = transaction?.isIncome ?? false;
      _transactionCategoryId = transaction?.categoryId ??
          _categories
              .firstWhere(
                  (category) => category.isIncome == _transactionIsIncome)
              .id;
      _transactionTitle = transaction?.title ?? '';
      _transactionAmount = transaction?.amount ?? 0.0;
      _transactionDate = transaction?.date ?? DateTime.now();
      _transactionDescription = transaction?.description ?? '';
      _transactionCurrency =
          transaction?.currency ?? _supportedCurrencies.first;
    });
    // Show the bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // Return the form widget
            return GestureDetector(
              onTap: () {},
              // Make the bottom sheet modal and opaque
              // This prevents the bottom sheet from closing
              // If the user taps on the form
              behavior: HitTestBehavior.opaque,
              child: _buildAddTransactionForm(context, setState, context,
                  transaction, currencyConversionEnabled),
            );
          },
        );
      },
    );
  }

  // Method to load transactions from the database
  Future<void> _loadTransactions(Box<Transaction> transactionBox) async {
    List<Transaction> loadedTransactions = transactionBox.values.toList();
    loadedTransactions.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _transactions = loadedTransactions;
      _filteredTransactions = _transactions;
    });
  }

  // Method to load categories from the database
  void _loadCategories(Box<Category> categoryBox) {
    setState(() {
      _categories = categoryBox.values.toList();
      _transactionCategoryId = _categories.first.id;
    });
  }

  // Method to show date and time picker
  // And update the transaction date
  Future<void> _showDateTimePicker(StateSetter localSetState,
      DateTime transactionDate, Function(DateTime) onDateChanged) async {
    // Choosing date
    final pickedDate = await showRoundedDatePicker(
      context: context,
      height: 350,
      theme: ThemeData(
        primaryColor: ThemeData.dark().scaffoldBackgroundColor.withOpacity(0.95),
        dialogBackgroundColor: ThemeData.dark().cardColor.withOpacity(0.95),
        colorScheme: const ColorScheme.dark(
          primary: Colors.tealAccent,
        ),
      ),

      initialDate: transactionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    // If no date is picked, return
    if (pickedDate == null) return;

    // Choosing time
    // ignore: use_build_context_synchronously
    final pickedTime = await showRoundedTimePicker(
      context: context,
      theme: ThemeData(
        primaryColor: ThemeData.dark().scaffoldBackgroundColor.withOpacity(0.95),
        dialogBackgroundColor: ThemeData.dark().cardColor.withOpacity(0.95),
        colorScheme: const ColorScheme.dark(
          primary: Colors.tealAccent,
        ),
      ),
      initialTime: TimeOfDay.fromDateTime(transactionDate),
    );

    // If no time is picked, return
    if (pickedTime == null) return;

    // Combine the date and time
    final newDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
        pickedTime.hour, pickedTime.minute);

    // Update the transaction date
    localSetState(() {
      transactionDate = newDate;
    });
    onDateChanged(newDate);
  }

  // Method to save a transaction to the database
  Future<void> _saveTransaction(Transaction transaction,
      BuildContext bottomSheetContext, Box<Transaction> transactionBox) async {
    try {
      await transactionBox.put(transaction.id, transaction);
      setState(() {
        // Update the transactions list
        _transactions = transactionBox.values.toList();
        _transactions.sort((a, b) => b.date.compareTo(a.date));
        _filteredTransactions = _transactions;
        // Close the bottom sheet
        Navigator.of(bottomSheetContext).pop();
      });
    } catch (e) {
      print('Error saving transaction: $e');
    }
  }

  // Method to search within the transactions list
  void _searchTransactions(String query) {
    // If the query string is empty, return the original list
    if (query.isEmpty) {
      setState(() {
        _filteredTransactions = _transactions;
      });
      // Otherwise, search within the list
    } else {
      // Filter the transactions list based on the query string
      List<Transaction> searchResult = _transactions
          .where(
              (transaction) => // Search by title, description, date, or category name
                  transaction.title
                      .toLowerCase()
                      .contains(query.toLowerCase()) ||
                  transaction.description
                      .toLowerCase()
                      .contains(query.toLowerCase()) ||
                  transaction.date.toString().contains(query) ||
                  _categories
                      .firstWhere((c) => c.id == transaction.categoryId)
                      .name
                      .toLowerCase()
                      .contains(query.toLowerCase()))
          .toList();
      setState(() {
        // Update the filtered transactions list with the search result
        _filteredTransactions = searchResult;
      });
    }
  }

  // Method to group transactions by date range
  Map<String, List<Transaction>> _groupTransactionsByRange(
      List<Transaction> transactions) {
    // Get the current dates by with the transactions will be grouped
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final oneWeekAgo = today.subtract(const Duration(days: 7));
    final oneMonthAgo = today.subtract(const Duration(days: 30));

    // Create a map to store the grouped transactions
    final rangeGroups = {
      'Сьогодні': <Transaction>[],
      'Минулі 7 днів': <Transaction>[],
      'Минулі 30 днів': <Transaction>[],
      'Більше 30 днів тому': <Transaction>[],
    };

    // Sort the transactions by date
    transactions.sort((a, b) => b.date.compareTo(a.date));

    // Group the transactions by date range
    for (final transaction in transactions) {
      final date = transaction.date;
      // Add the transaction to the corresponding date range
      if (date.isAtSameMomentAs(today) || date.isAfter(today)) {
        rangeGroups['Сьогодні']!.add(transaction);
      } else if (date.isAfter(oneWeekAgo)) {
        rangeGroups['Минулі 7 днів']!.add(transaction);
      } else if (date.isAfter(oneMonthAgo)) {
        rangeGroups['Минулі 30 днів']!.add(transaction);
      } else {
        rangeGroups['Більше 30 днів тому']!.add(transaction);
      }
    }
    // Return the grouped transactions
    return rangeGroups;
  }

  // This method is rebuilding the categories list when the search state changes
  void _onSearchStateChanged(bool isSearchEnabled) {
    setState(() {
      _isSearchEnabled = isSearchEnabled;
      if (!isSearchEnabled) {
        _filteredTransactions = _transactions;
      }
    });
  }

  // Method to format the currency
  String format(double n) {
    return n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2);
  }
}
