import 'package:flutter/material.dart';
import '../services/dataset_repository.dart';
import '../services/http/sync_service.dart';
import '../theme/app_colors.dart';
import '../view_functions/meus_croquis_functions.dart';

class MeusCroquisPage extends StatelessWidget {
  final DatasetRepository datasetRepo;
  final SyncService syncService;

  const MeusCroquisPage({
    super.key,
    required this.datasetRepo,
    required this.syncService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.homeBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MEUS CROQUIS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ARMAZENAMENTO OFFLINE',
                    style: TextStyle(
                      color: context.colors.textOlive,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<TopoDataset?>(
                valueListenable: datasetRepo.activeDataset,
                builder: (context, dataset, _) {
                  if (dataset == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final downloadedCrags = dataset.downloadedPicos;

                  if (downloadedCrags.isEmpty) {
                    return Center(
                      child: Text(
                        'Nenhum croqui salvo offline ainda.',
                        style: TextStyle(color: context.colors.textGrey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: downloadedCrags.length,
                    itemBuilder: (context, index) {
                      final crag = downloadedCrags[index];
                      return OfflineCragCard(
                        crag: crag,
                        datasetRepo: datasetRepo,
                        syncService: syncService,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
