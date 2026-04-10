import 'package:flutter/material.dart';
import '../functions/browse_functions.dart';
import '../functions/common_functions.dart';
import '../services/dataset_repository.dart';

/// A page that allows users to explore and search for available crags (picos).
/// 
/// It displays a list of crags fetched from the [DatasetRepository] and 
/// provides a search bar for filtering by name or location.
class BrowsePage extends StatefulWidget {
  final DatasetRepository datasetRepo;

  const BrowsePage({super.key, required this.datasetRepo});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  /// The current text entered in the search bar.
  String _searchQuery = '';

  /// Triggers the download of a crag's binary data (.binarypb).
  /// 
  /// Shows a SnackBar during the process and another one to indicate 
  /// success or failure upon completion.
  void _handleDownload(Map<String, dynamic> crag) async {
    final name = safeString(crag['nome'], fallback: 'Pico');
    
    // Show a SnackBar to provide feedback to the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Baixando $name...')),
    );

    // Perform the actual download via the repository.
    // The file is saved to the app's local documents directory.
    final success = await widget.datasetRepo.downloadCrag(crag);

    if (mounted) {
      // Update the user with the result
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '$name baixado com sucesso!' : 'Falha ao baixar $name'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: buildCommonAppBar('Explorar Locais'),

      // ValueListenableBuilder automatically rebuilds this part of the UI
      // whenever the dataset in the repository changes (after the initial fetch).
      body: ValueListenableBuilder<TopoDataset?>(
        valueListenable: widget.datasetRepo.activeDataset,
        builder: (context, dataset, child) {
          // While the repository is still initializing/fetching, show a spinner.
          if (dataset == null) {
            return const Center(
              child: CircularProgressIndicator(color: beastHide),
            );
          }

          final allCrags = dataset.availablePicos;

          /* Filter the list locally based on the user's search query.
           We check both the name and the location.
           safeString is used to prevent crashes if a field is unexpectedly null. */
          final filteredCrags = allCrags.where((crag) {
            final name = safeString(crag['nome']).toLowerCase();
            final location = safeString(crag['local']).toLowerCase();
            final query = _searchQuery.toLowerCase();

            return name.contains(query) || location.contains(query);
          }).toList();

          // We pass the filteredCrags directly to buildBrowseBody.
          return buildBrowseBody(
            context,
            filteredCrags,
            onSearchChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            onDownload: _handleDownload,
          );
        },
      ),
    );
  }
}
