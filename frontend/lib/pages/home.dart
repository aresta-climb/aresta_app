import 'package:flutter/material.dart';
import '../functions/home_functions.dart';
import '../functions/common_functions.dart';
import '../services/dataset_repository.dart';

/// The landing page of the application.
/// 
/// It displays a dashboard or a summary view of the available data.
/// It relies on the DatasetRepository to provide the latest information fetched from the remote server.
class HomePage extends StatelessWidget {
  final DatasetRepository datasetRepo;
  final Function(int) onSwitchTab;

  const HomePage({
    super.key, 
    required this.datasetRepo,
    required this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nobleBlack,
      // Uses a common app bar style defined in common_functions.dart
      appBar: buildCommonAppBar('Home'),
      
      // ValueListenableBuilder listens to changes in the activeDataset.
      // When the dataset is first fetched (or updated), this builder triggers a rebuild.
      body: ValueListenableBuilder<TopoDataset?>(
        valueListenable: datasetRepo.activeDataset,
        builder: (context, dataset, child) {

          // While the app is booting up or fetching the initial data,
          // we show a loading indicator.
          if (dataset == null) {
            return const Center(
              child: CircularProgressIndicator(color: beastHide),
            );
          }

          // Pass the context and repo to the UI builder to handle logic inside home_functions.dart
          return buildHomeBody(
            context,
            datasetRepo,
            dataset.downloadedPicos, 
            onAddCrag: () => onSwitchTab(2), // 2 is the Browse/Explorar tab
          );
        },
      ),
    );
  }
}
