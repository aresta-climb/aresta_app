import 'package:flutter/material.dart';
import '../kmon_api/proto/croqui.pb.dart';
import '../functions/common_functions.dart';
import '../functions/pico_functions.dart';
import '../services/dataset_repository.dart';

/// A page that displays detailed information about a specific pico.
///
/// It presents the pico's description and lists all sectors contained within it.
class PicoDetailsPage extends StatelessWidget {
  final Pico pico;
  final Croqui croqui;
  final String cragId;
  final DatasetRepository datasetRepo;

  const PicoDetailsPage({
    super.key, 
    required this.pico,
    required this.croqui,
    required this.cragId,
    required this.datasetRepo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: buildCommonAppBar(
        pico.nome,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: nobleBlack),
            tooltip: 'Excluir guia',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: nobleBlack,
                  title: const Text('Excluir?', style: TextStyle(color: beastHide)),
                  content: Text('Deseja excluir o guia de ${pico.nome}?', style: const TextStyle(color: fishBone)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('CANCELAR', style: TextStyle(color: fishBone)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('EXCLUIR', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                final success = await datasetRepo.deleteCrag(cragId);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Guia excluído com sucesso.' : 'Erro ao excluir guia.'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: buildPicoBody(context, pico, croqui, cragId),
      bottomNavigationBar: buildSecondaryBottomNav(context),
    );
  }
}
