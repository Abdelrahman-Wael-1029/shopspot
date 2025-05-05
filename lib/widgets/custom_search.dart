import 'package:flutter/material.dart';

class CustomSearch extends StatelessWidget {
  const CustomSearch({
    super.key,
    required this.onPressed,
    required this.searchController,
    this.onChanged,
    this.hintText,
  });

  final String? hintText;
  final Function(String)? onChanged;
  final TextEditingController searchController;
  final Function() onPressed;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        controller: searchController,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onPressed,
                )
              : null,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
