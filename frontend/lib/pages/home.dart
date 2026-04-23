import 'package:flutter/material.dart';
import '../functions/home_functions.dart';
import '../functions/common_functions.dart';
import '../services/dataset_repository.dart';
import '../services/sync_service.dart';

/// A página inicial do aplicativo.
/// 
/// Ela exibe um painel (dashboard) de picos baixados recentemente e fornece
/// acesso a todos os guias disponíveis.
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
      // O AppBar agora contém apenas o título e o botão de sincronização manual
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
      
      // ValueListenableBuilder escuta as alterações no activeDataset.
      body: ValueListenableBuilder<TopoDataset?>(
        valueListenable: datasetRepo.activeDataset,
        builder: (context, dataset, child) {
          if (dataset == null) {
            return const Center(
              child: CircularProgressIndicator(color: beastHide),
            );
          }

          return ValueListenableBuilder<Set<String>>(
            valueListenable: datasetRepo.downloadingCrags,
            builder: (context, downloadingCrags, child) {
              return buildHomeBody(
                context,
                datasetRepo,
                dataset.downloadedPicos,
                downloadingCrags,
                onAddCrag: () => onSwitchTab(2),
              );
            },
          );
        },
      ),
    );
  }
}
