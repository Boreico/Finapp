import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:finapp/models/transaction.dart';
import 'dart:ui';

// Create a custom ExpansionTile widget
class CustomExpansionTile extends StatefulWidget {
  final Box<Transaction> transactionsBox;
  final Widget title;
  final List<Widget> children;
  final double iconSize;
  final String transactionId;
  final Function(String) onDelete;
  final VoidCallback onTransactionListChanged;

  const CustomExpansionTile({
    Key? key,
    required this.title,
    required this.children,
    this.iconSize = 40.0,
    required this.transactionId,
    required this.onDelete,
    required this.transactionsBox,
    required this.onTransactionListChanged,
  }) : super(key: key);

  @override
  CustomExpansionTileState createState() => CustomExpansionTileState();
}

// Create a corresponding State class
class CustomExpansionTileState extends State<CustomExpansionTile>
    with SingleTickerProviderStateMixin {
  // Declare variables
  bool _isExpanded = false;
  late Animation<double> _iconTurns;
  late AnimationController _controller;

  List<Transaction> transactions = [];
  List<Transaction> _filteredTransactions = [];

  @override
  // Initialize the state
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _iconTurns = _controller.drive(Tween<double>(
      begin: 0,
      end: 0.5,
    ));
  }

  // Dispose of the animation controller
  // to prevent memory leaks
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  // Building the widget
  Widget build(BuildContext context) {
    // Return a ClipRRect widget with a BackdropFilter
    // This will blur the background
    return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            //Dismissible widget
            // This widget allows the user to swipe
            child: Dismissible(
              // Set the key to the transaction id
              key: ValueKey<String>(widget.transactionId),
              background: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.red,
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              direction: DismissDirection.endToStart,
              // Show a dialog to confirm the deletion
              confirmDismiss: (direction) async {
                final confirmed = await _showDeleteConfirmationDialog(context);
                if (confirmed) {
                  deleteTransaction(widget.transactionId);
                  return true;
                } else {
                  return false;
                }
              },
              // The child is the content of the tile
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    onTap: _handleTap,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 0.0),
                    title: widget.title,
                    trailing: RotationTransition(
                      turns: _iconTurns,
                      child: Icon(
                        Icons.expand_more,
                        size: widget.iconSize,
                      ),
                    ),
                  ),
                  // Use AnimatedCrossFade to animate the children
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild:
                        Container(), // Empty container when not expanded
                    // The second child is the column of children
                    secondChild: Align(
                      alignment: Alignment.center,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.children,
                      ),
                    ),
                  ),
                ],
              ),
            )));
  }

  // Handle the tap event
  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  // Show a dialog to confirm the deletion
  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Видалити транзакцію?'),
          content: const Text('Ви впевнені, що хочете видалити цю транзакцію?'),
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
    // If the result is null, then the dialog was dismissed
    return result ?? false;
  }

  // Method to delete a transaction
  void deleteTransaction(String id) async {
    final transactionBox = widget.transactionsBox;
    transactionBox.delete(id);
    widget.onDelete(id);
    widget.onTransactionListChanged();
    _loadTransactions(transactionBox);
  }

  // Method to load transactions from the database
  Future<void> _loadTransactions(Box<Transaction> transactionBox) async {
    List<Transaction> loadedTransactions = transactionBox.values.toList();
    loadedTransactions.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      transactions = loadedTransactions;
      _filteredTransactions = transactions;
    });
  }
}
