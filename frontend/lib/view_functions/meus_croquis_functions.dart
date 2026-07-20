import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/dataset_repository.dart';
import '../services/http/sync_service.dart';
import '../theme/app_colors.dart';
import 'common_functions.dart';
import '../navigation/navigation_functions.dart';
import '../services/firebase/telemetry_service.dart';

class OfflineCragCard extends StatelessWidget {
  final Map<String, dynamic> crag;
  final DatasetRepository datasetRepo;
  final SyncService syncService;

  const OfflineCragCard({
    super.key,
    required this.crag,
    required this.datasetRepo,
    required this.syncService,
  });

  String _safeString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final String id = _safeString(crag['id']);
    final String nome = _safeString(crag['nome'], fallback: 'Sem Nome').toUpperCase();
    final String local = _safeString(crag['local'], fallback: 'Local Desconhecido').toUpperCase();
    
    String statsText = '0 setores • 0 vias';
    if (crag['estatisticas'] != null) {
      final stats = crag['estatisticas'];
      final setores = stats['totalSetores'] ?? 0;
      final vias = stats['totalVias'] ?? 0;
      statsText = '$setores setores • $vias vias';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.colors.caveShadow,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60,
                  height: 60,
                  color: context.colors.graniteEdge,
                  child: FutureBuilder<Directory>(
                    future: getApplicationDocumentsDirectory(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final file = File('${snapshot.data!.path}/thumbnails/$id.webp');
                        if (file.existsSync()) {
                          return Image.file(
                            file,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.terrain, color: context.colors.ashGrey),
                          );
                        }
                      }
                      return Icon(Icons.terrain, color: context.colors.ashGrey);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      local,
                      style: TextStyle(
                        color: context.colors.dryMoss,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      statsText,
                      style: TextStyle(
                        color: context.colors.ashGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    TelemetryService.instance.logAcaoCroqui(id, 'abrir_croqui', origem: 'meus_croquis');
                    AppNav.toPico(context, cragId: id);
                    datasetRepo.updatePriorityAfterNavigation(id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC04F34),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ABRIR OFFLINE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildIconButton(
                context,
                icon: Icons.sync,
                onPressed: () async {
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
              ),
              const SizedBox(width: 12),
              _buildIconButton(
                context,
                icon: Icons.delete_outline,
                onPressed: () => _handleDelete(context, id, nome),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(BuildContext context, {required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: context.colors.graniteEdge),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: context.colors.ashGrey, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, String cragId, String nome) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.caveShadow,
        title: const Text('Excluir?', style: TextStyle(color: Colors.white)),
        content: Text('Deseja excluir o guia de $nome?', style: TextStyle(color: context.colors.ashGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCELAR', style: TextStyle(color: context.colors.ashGrey)),
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
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
          SnackBar(
            content: Text(success ? 'Guia excluído.' : 'Erro ao excluir guia.'),
            backgroundColor: success ? context.colors.dryMoss : Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
