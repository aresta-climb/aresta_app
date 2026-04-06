import 'package:flutter/material.dart';
import '../functions/browse_functions.dart';

class BrowsePage extends StatelessWidget {
  const BrowsePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> availableCrags = getAvailableCrags();

    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: buildBrowseAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildBrowseSectionTitle('Picos Disponíveis'),
            const SizedBox(height: 20),
            ...availableCrags.map((crag) => buildCragListItem(crag)),
          ],
        ),
      ),
    );
  }
}
