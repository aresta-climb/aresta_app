import 'package:flutter/material.dart';
import '../services/dataset_repository.dart';
import '../services/http/sync_service.dart';
import '../theme/app_colors.dart';
import '../view_functions/meus_croquis_functions.dart';
import '../view_functions/common_functions.dart';

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
      backgroundColor: context.colors.deepBasalt,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MEUS CROQUIS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ARMAZENAMENTO OFFLINE',
                          style: TextStyle(
                            color: context.colors.dryMoss,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.sync, color: context.colors.ashGrey),
                        onPressed: () async {
                          final dataset = datasetRepo.activeDataset.value;
                          final hasDownloaded = dataset != null && dataset.downloadedPicos.isNotEmpty;

                          if (!hasDownloaded) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                ..clearSnackBars()
                                ..showSnackBar(
                                  SnackBar(
                                    content: const Text('Nenhum croqui baixado para atualizar.'),
                                    backgroundColor: context.colors.ashGrey,
                                  ),
                                );
                            }
                            return;
                          }

                          if (await syncService.isNetworkDisabled()) {
                            if (context.mounted) {
                              showDeprecatedAppVersionSnackBar(context);
                            }
                            return;
                          }
                          ScaffoldMessenger.of(context)
                            ..clearSnackBars()
                            ..showSnackBar(
                              const SnackBar(content: Text('Verificando atualizações...')),
                            );
                          
                          final failed = await syncService.syncIndex(auto: false);
                          
                          if (context.mounted) {
                            final status = syncService.syncStatus.value;
                            String message = '';
                            Color bgColor = context.colors.dryMoss;

                            if (failed.isNotEmpty) {
                              message = 'Concluído com falhas: ${failed.join(', ')}';
                              bgColor = Theme.of(context).colorScheme.error;
                            } else if (status == SyncStatus.noNewUpdates || status == SyncStatus.updated) {
                              message = 'Nenhum croqui precisava ser atualizado.';
                              bgColor = context.colors.ashGrey;
                            } else {
                              message = 'Croquis foram atualizados!';
                              bgColor = context.colors.dryMoss;
                            }

                            ScaffoldMessenger.of(context)
                              ..clearSnackBars()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  backgroundColor: bgColor,
                                ),
                              );
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      buildFeedbackButton(context, color: context.colors.ashGrey),
                    ],
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
                        style: TextStyle(color: context.colors.ashGrey),
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
