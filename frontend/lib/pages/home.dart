import 'package:flutter/material.dart';
import '../functions/home_functions.dart';
import '../functions/common_functions.dart';
import '../services/dataset_repository.dart';
import '../services/sync_service.dart';

/// The landing page of the application.
/// 
/// It displays a dashboard of recently downloaded crags and provides 
/// access to all available guides.
class HomePage extends StatelessWidget {
  final DatasetRepository datasetRepo;
  final SyncService syncService;
  final Function(int) onSwitchTab;

  const HomePage({
    super.key, 
    required this.datasetRepo,
    required this.syncService,
    required this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nobleBlack,
      // The AppBar now only contains the title and the manual sync button
      appBar: buildCommonAppBar(
        'Home', 
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: nobleBlack),
            onPressed: () => syncService.syncOnLaunch(),
            tooltip: 'Verificar atualizações',
          ),
        ],
      ),
      
      // ValueListenableBuilder listens to changes in the activeDataset.
      body: ValueListenableBuilder<TopoDataset?>(
        valueListenable: datasetRepo.activeDataset,
        builder: (context, dataset, child) {
          if (dataset == null) {
            return const Center(
              child: CircularProgressIndicator(color: beastHide),
            );
          }

          return buildHomeBody(
            context,
            datasetRepo,
            dataset.downloadedPicos, 
            onAddCrag: () => onSwitchTab(2),
          );
        },
      ),
    );
  }
}
