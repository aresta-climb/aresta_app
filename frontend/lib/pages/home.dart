import 'package:flutter/material.dart';
import '../view_functions/home_functions.dart';
import '../services/dataset_repository.dart';
import '../services/http/sync_service.dart';
import '../theme/app_colors.dart';
import '../view_functions/common_functions.dart';

/// A página inicial do aplicativo (nova versão).
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
      backgroundColor: context.colors.deepBasalt,
      body: SafeArea(
        child: RefreshIndicator(
          color: context.colors.dryMoss,
          backgroundColor: context.colors.caveShadow,
          onRefresh: () async {
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

            if (context.mounted) {
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  const SnackBar(content: Text('Verificando atualizações...')),
                );
            }

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
                message = 'Croquis atualizados com sucesso!';
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
          child: buildHomeBody(context, syncService, onSwitchTab),
        ),
      ),
    );
  }
}
