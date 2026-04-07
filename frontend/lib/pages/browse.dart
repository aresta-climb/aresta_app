import 'package:flutter/material.dart';
import '../functions/browse_functions.dart';
import '../functions/common_functions.dart';

class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  String _searchQuery = '';
  final List<Map<String, String>> _allCrags = getAvailableCrags();

  @override
  Widget build(BuildContext context) {
    // Filter the list based on the search query
    final List<Map<String, String>> filteredCrags = _allCrags.where((crag) {
      final name = crag['name']?.toLowerCase() ?? '';
      final location = crag['location']?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || location.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: buildCommonAppBar('Explorar Locais'),
      body: buildBrowseBody(
        context,
        filteredCrags,
        onSearchChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }
}
