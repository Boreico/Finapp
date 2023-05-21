import 'package:flutter/material.dart';

// Creating a custom app bar class that implements PreferredSizeWidget
// This is done to suit the needs of the appBar property of the Scaffold widget
class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool isSearchEnabled;
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final ValueChanged<bool> onSearchStateChanged;

  const CustomAppBar({Key? key, 
    required this.title,
    required this.isSearchEnabled,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchStateChanged,
  }) : super(key: key);

  @override
  // PreferredSizeWidget requires the preferredSize property to be implemented
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  CustomAppBarState createState() => CustomAppBarState();
}
// Creating a state class for the custom app bar
class CustomAppBarState extends State<CustomAppBar> {

  @override
  // Building the custom app bar
  Widget build(BuildContext context) {
    // Using AnimatedCrossFade to animate between the normal app bar and the search app bar
    return AnimatedCrossFade(
      crossFadeState: widget.isSearchEnabled
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 300),
      // Normal app bar
      firstChild: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              widget.onSearchStateChanged(true);
            },
          ),
        ],
      ),
      // Search app bar
      secondChild: AppBar(
        leading: BackButton(
          onPressed: () {
            widget.onSearchStateChanged(false);
            widget.searchController.clear();
          },
        ),
        title: TextField(
          controller: widget.searchController,
          onChanged: widget.onSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Пошук',
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
