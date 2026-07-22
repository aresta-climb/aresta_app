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
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      failed.isEmpty 
                        ? 'Tudo atualizado!' 
                        : 'Concluído com falhas: ${failed.join(', ')}'
                    ),
                    backgroundColor: failed.isEmpty ? context.colors.dryMoss : Theme.of(context).colorScheme.error,
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
