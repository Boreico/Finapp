import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:finapp/models/category.dart';
import 'package:finapp/models/transaction.dart';
import 'package:finapp/customs/custom_app_bar.dart';
import 'dart:ui';

// Create a CategoriesScreen widget
class CategoriesScreen extends StatefulWidget {
  final Box<Category> categoriesBox;
  final Box<Transaction> transactionsBox;
  final VoidCallback onTransactionListChanged;
  const CategoriesScreen(
      {Key? key,
      required this.categoriesBox,
      required this.transactionsBox,
      required this.onTransactionListChanged})
      : super(key: key);

  @override
  CategoriesScreenState createState() => CategoriesScreenState();
}

// Create a CategoriesScreen state
class CategoriesScreenState extends State<CategoriesScreen> {
  // Declating variables
  late List<Category> _categories;
  int _bottomNavIndex = 0;
  bool _isSearchEnabled = false;
  final TextEditingController _searchController = TextEditingController();
  List<Category> _filteredCategories = [];

  final PageController _pageController = PageController();
  bool _categoryIsIncome = false;
  String _categoryName = '';

  @override
  // Initialize the state
  void initState() {
    super.initState();
    _loadCategories(widget.categoriesBox);
  }

  @override
  // Build the CategoriesScreen widget
  Widget build(BuildContext context) {
    return Scaffold(
      // Build the custom app bar
      appBar: CustomAppBar(
        title: 'Категорії',
        isSearchEnabled: _isSearchEnabled,
        searchController: _searchController,
        onSearchChanged: (value) {
          _searchCategories(value);
        },
        onSearchStateChanged: _onSearchStateChanged,
      ),
      // Build the body with a page view
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _bottomNavIndex = index;
          });
        },
        children: [
          _spendingCategoriesPage(),
          _incomeCategoriesPage(),
        ],
      ),
      // Build the bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_upward),
            label: 'Витрати',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_downward),
            label: 'Надходження',
          ),
        ],
      ),
      // Build the floating action button
      floatingActionButton: FloatingActionButton(
        // When the button is pressed, show the category form
        onPressed: () {
          _showCategoryForm(context);
        },
        backgroundColor: Colors.tealAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  // Disposing the page controller
  // to avoid memory leaks
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Method to create a categories list
  void _loadCategories(Box<Category> categoryBox) {
    setState(() {
      _categories = categoryBox.values.toList();
      _filteredCategories = _categories;
    });
  }

  // Single category item widget
  Widget _buildCategoryItem(Category category) {
    return Card(
      color: Theme.of(context).cardColor.withOpacity(0.55),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.all(8),
      // Dismissible widget to delete a category
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          //Dismissible widget
          // This widget allows the user to swipe
          child: Dismissible(
            // Using the category id as a key
            key: ValueKey<String>(category.id),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
                size: 30,
              ),
            ),
            // Dismissing the category
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              final confirmed = await _showDeleteConfirmationDialog(context);
              if (confirmed) {
                _deleteCategory(category);
                return true;
              } else {
                return false;
              }
            },
            // Category item
            child: ListTile(
              leading: const SizedBox(
                width: 60,
                height: 60,
                child: Padding(
                  padding: EdgeInsets.all(6),
                ),
              ),
              title: Text(
                category.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              // Edit category button
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                color: Theme.of(context).colorScheme.background,
                onPressed: () => _showCategoryForm(context, category),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Method to delete a category
  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        // AlertDialog widget to ask the user to confirm the deletion
        return AlertDialog(
          title: const Text('Видалити категорію?'),
          content: const Text(
              'Ви впевнені, що хочете видалити цю категорію? Разом із нею видаляться усі відповідні транзакції.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(false); // Close the dialog without deleting
              },
              child: const Text('Відміна'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(true); // Close the dialog and confirm deletion
              },
              child: const Text('Видалити'),
            ),
          ],
        );
      },
    );
    // If the user confirmed deletion, the result will be true
    // Otherwise it will be false
    return result ?? false;
  }

  // The spendings categories page
  Widget _spendingCategoriesPage() {
    return Column(children: [
      Expanded(
        child: ListView.builder(
          itemCount: _filteredCategories.length,
          itemBuilder: (BuildContext context, int index) {
            if (!_filteredCategories[index].isIncome) {
              return _buildCategoryItem(_filteredCategories[index]);
            } else {
              return Container();
            }
          },
        ),
      ),
    ]);
  }

  // The income categories page
  Widget _incomeCategoriesPage() {
    return Column(children: [
      Expanded(
        child: ListView.builder(
          itemCount: _filteredCategories.length,
          itemBuilder: (BuildContext context, int index) {
            if (_filteredCategories[index].isIncome) {
              return _buildCategoryItem(_filteredCategories[index]);
            } else {
              return Container();
            }
          },
        ),
      ),
    ]);
  }

  // Method switching between the spending and income categories pages
  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Method to show the category form
  Widget _buildCategoryForm(BuildContext context, StateSetter setState,
      BuildContext bottomSheetContext, Category? category) {
    // Container widget to wrap the form
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 24, left: 7, right: 7),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            elevation: 5,
            color: Theme.of(context).cardColor.withOpacity(0.8),
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              // Form widget
              child: SingleChildScrollView(
                // StatefulBuilder widget to rebuild the form when the state changes
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter localSetState) {
                    // The form
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Category name field
                        TextFormField(
                          initialValue: _categoryName,
                          decoration: const InputDecoration(labelText: 'Назва'),
                          onChanged: (value) {
                            localSetState(() {
                              _categoryName = value;
                            });
                          },
                        ),
                        // Switch to select whether the category is income or spending
                        SwitchListTile(
                          title: const Text('Надходження'),
                          value: _categoryIsIncome,
                          onChanged: (bool value) {
                            localSetState(() {
                              _categoryIsIncome = value;
                            });
                          },
                        ),
                        // Save button
                        ElevatedButton(
                          onPressed: () async {
                            // If the category is not null, it means that we are editing an existing category
                            if (category != null) {
                              // Update the transaction with new values from the form
                              final updatedCategory = category.copyWith(
                                id: category.id,
                                name: _categoryName,
                                isIncome: _categoryIsIncome,
                                source: category.source,
                              );
                              await _saveCategory(updatedCategory,
                                  bottomSheetContext, widget.categoriesBox);
                              // If the category is null, it means that we are creating a new category
                            } else {
                              // If the category name is empty, do nothing
                              if (_categoryName.isEmpty) {
                                return;
                              }
                              // Create a new category
                              final newCategory = Category(
                                id: DateTime.now().toString(),
                                name: _categoryName,
                                isIncome: _categoryIsIncome,
                                source: 'user',
                              );
                              await _saveCategory(newCategory,
                                  bottomSheetContext, widget.categoriesBox);
                            }
                          },
                          // The button text depends on whether the category is null or not
                          child: Text(
                            category != null
                                ? 'Редагувати категорію'
                                : 'Додати категорію',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Method to show the category form
  void _showCategoryForm(BuildContext context, [Category? category]) {
    setState(() {
      _categoryIsIncome = category?.isIncome ?? false;
      _categoryName = category?.name ?? '';
    });
    // Show the bottom sheet
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // Return the form
            return GestureDetector(
              onTap: () {},
              // Make the bottom sheet modal and opaque
              // This prevents the bottom sheet from closing
              // If the user taps on the form
              behavior: HitTestBehavior.opaque,
              child: _buildCategoryForm(
                context,
                setState,
                context,
                category,
              ),
            );
          },
        );
      },
    );
  }

  // Method to save the category
  Future<void> _saveCategory(Category category, BuildContext bottomSheetContext,
      Box<Category> categoriesBox) async {
    try {
      await categoriesBox.put(category.id, category);
      setState(() {
        _categories = categoriesBox.values.toList().cast<Category>();
        _filteredCategories = _categories;
        Navigator.of(bottomSheetContext).pop();
      });
    } catch (e) {
      print('Error saving category: $e');
    }
  }

  // Method to delete the category and all transactions associated with it
  void _deleteCategory(Category category) {
    final categoriesBox = widget.categoriesBox;
    final transactionsBox = widget.transactionsBox;

    transactionsBox.values
        .where((transaction) => transaction.categoryId == category.id)
        .toList()
        .forEach((transaction) {
      transactionsBox.delete(transaction.id);
    });
    widget.onTransactionListChanged();
    categoriesBox.delete(category.id);
    setState(() {
      _categories = categoriesBox.values.toList().cast<Category>();
    });
  }

  // This method is updating the filtered categories list when the search query changes
  void _searchCategories(String query) {
    // If the query is empty, return all categories
    if (query.isEmpty) {
      setState(() {
        _filteredCategories = _categories;
      });
      // If the query is not empty, return only categories that contain the query string
    } else {
      List<Category> searchResult = _categories
          .where((category) =>
              category.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      setState(() {
        // Update the filtered categories list with the search result list
        _filteredCategories = searchResult;
      });
    }
  }

  // This method is rebuilding the categories list when the search state changes
  void _onSearchStateChanged(bool isSearchEnabled) {
    setState(() {
      _isSearchEnabled = isSearchEnabled;
      if (!isSearchEnabled) {
        _filteredCategories = _categories;
      }
    });
  }
}
