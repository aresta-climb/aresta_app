import 'package:flutter/material.dart';
import '../functions/home_functions.dart';
import '../functions/common_functions.dart';
import '../services/dataset_repository.dart';

class HomePage extends StatelessWidget {
  final DatasetRepository datasetRepo;

  // Require the repo in the constructor
  const HomePage({super.key, required this.datasetRepo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: buildCommonAppBar('Home'),
      body: ValueListenableBuilder<TopoDataset?>(
        valueListenable: datasetRepo.activeDataset,
        builder: (context, dataset, child) {

          // While the app is booting up and reading the local files for the first time, now there's a progress indicator for prettiness
          if (dataset == null) {
            return const Center(
              child: CircularProgressIndicator(color: beastHide),
            );
          }

          // Since TopoDataset now has availablePicos, we just hand it straight over to the UI builder.
          return buildHomeBody(dataset.availablePicos);
        },
      ),
    );
  }
}