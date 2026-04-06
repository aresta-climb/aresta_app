import 'package:flutter/material.dart';
import '../functions/browse_functions.dart';
import '../functions/common_functions.dart';

class BrowsePage extends StatelessWidget {
  const BrowsePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> availableCrags = getAvailableCrags();

    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: buildCommonAppBar('Explorar Locais'),
      body: buildBrowseBody(availableCrags),
    );
  }
}
