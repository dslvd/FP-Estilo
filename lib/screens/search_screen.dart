import 'package:flutter/material.dart';

/// Plant species search. Wired to a plant API in a later step.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plant Search')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: TextField(
          decoration: InputDecoration(
            labelText: 'Search plant name',
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ),
    );
  }
}
