import 'package:flutter/material.dart';
import '../functions/browse_functions.dart';
import '../functions/common_functions.dart';
import '../services/dataset_repository.dart';

class BrowsePage extends StatefulWidget {
  final DatasetRepository datasetRepo;

  // Require it in the constructor
  const BrowsePage({super.key, required this.datasetRepo});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: buildCommonAppBar('Explorar Locais'),

      // Listen to the live dataset from the repository
      body: ValueListenableBuilder<TopoDataset?>(
        valueListenable: widget.datasetRepo.activeDataset,
        builder: (context, dataset, child) {

          // While the app is booting up and reading the local files for the first time, now there's a progress indicator for prettiness
          if (dataset == null) {
            return const Center(
              child: CircularProgressIndicator(color: beastHide),
            );
          }

          final allCrags = dataset.availablePicos;

          // Filter the list based on the search query
          // Using safeString to prevent crashes if a field is unexpectedly null
          final filteredCrags = allCrags.where((crag) {
            final name = safeString(crag['nome']).toLowerCase();
            final location = safeString(crag['local']).toLowerCase();
            final query = _searchQuery.toLowerCase();

            return name.contains(query) || location.contains(query);
          }).toList();

          // Safely map the dynamic Protobuf data to the Map<String, String> format of the UI
          final List<Map<String, String>> typedFilteredCrags = filteredCrags.map((crag) {
            return {
              'nome': safeString(crag['nome']),
              'local': safeString(crag['local']),
              'vias': safeString(crag['vias']),
            };
          }).toList();

          return buildBrowseBody(
            context,
            typedFilteredCrags,
            onSearchChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          );
        },
      ),
    );
  }
}