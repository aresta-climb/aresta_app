// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../services/dataset_repository.dart';
import '../services/http/sync_service.dart';
import '../theme/app_colors.dart';
import '../widgets/provedor_imagem_aresta.dart';
import '../navigation/navigation_functions.dart';
import '../services/firebase/telemetry_service.dart';
import '../services/firebase/registro_primeira_visita.dart';

/// Card interativo para exibição de um croqui baixado na aba Meus Croquis.
///
/// Aceita diretamente a entidade [Croqui] do Protobuf ou o modelo legado [ResumoPico],
/// extraindo nome, localização e estatísticas de setores e escaladas.
class OfflineCragCard extends StatelessWidget {
  final dynamic crag;
  final DatasetRepository datasetRepo;
  final SyncService syncService;

  const OfflineCragCard({
    super.key,
    required this.crag,
    required this.datasetRepo,
    required this.syncService,
  });

  @override
  Widget build(BuildContext context) {
    final String id;
    final String nome;
    final String local;
    String statsText = '0 setores • 0 escaladas';

    if (crag is Croqui) {
      final Croqui c = crag as Croqui;
      id = c.id;
      final nomeFonte = c.nome.isNotEmpty
          ? c.nome
          : (c.picos.isNotEmpty ? c.picos.first.nome : '');
      nome = (nomeFonte.isEmpty ? 'Sem Nome' : nomeFonte).toUpperCase();
      final localFonte = c.picos.isNotEmpty && c.picos.first.estado.isNotEmpty
          ? c.picos.first.estado
          : '';
      local = (localFonte.isEmpty ? 'Local Desconhecido' : localFonte).toUpperCase();

      if (c.picos.isNotEmpty && c.picos.first.hasPrecomputados()) {
        final stats = c.picos.first.precomputados;
        statsText = '${stats.totalSetores} setores • ${stats.totalEscaladas} escaladas';
      }
    } else {
      id = crag.id?.toString() ?? '';
      final nomeFonte = crag.nome?.toString() ?? '';
      nome = (nomeFonte.isEmpty ? 'Sem Nome' : nomeFonte).toUpperCase();
      final localFonte = crag.local?.toString() ?? '';
      local = (localFonte.isEmpty ? 'Local Desconhecido' : localFonte).toUpperCase();

      if (crag.estatisticas != null) {
        final stats = crag.estatisticas!;
        final setores = stats.totalSetores;
        final vias = stats.totalVias;
        statsText = '$setores setores • $vias escaladas';
      }
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
              // Miniatura unificada com downsampling para 300px via ProvedorImagemAresta
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60,
                  height: 60,
                  color: context.colors.graniteEdge,
                  child: FutureBuilder<ImageProvider?>(
                    future: ProvedorImagemAresta.resolver(
                      picoId: id,
                      caminho: 'thumbnails/$id.webp',
                      larguraAlvo: 300,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(color: context.colors.graniteEdge);
                      }
                      if (snapshot.hasData && snapshot.data != null) {
                        return Image(
                          image: snapshot.data!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.terrain,
                            color: context.colors.ashGrey,
                          ),
                        );
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
                  onPressed: () async {
                    final primeiraVisita = await RegistroPrimeiraVisita.instancia
                        .registrarEVerificarPrimeiraVisita(id);
                    TelemetryService.instance.logAcaoCroqui(
                      id,
                      'abrir_croqui',
                      origem: 'meus_croquis',
                      modoAcesso: 'offline',
                      primeiraVisita: primeiraVisita,
                    );

                    Croqui? croqui;
                    if (crag is Croqui) {
                      croqui = crag as Croqui;
                    } else if (crag is ResumoPico && (crag as ResumoPico).croqui != null) {
                      croqui = (crag as ResumoPico).croqui;
                    } else {
                      croqui = await datasetRepo.getCroqui(id);
                    }

                    if (!context.mounted) return;

                    if (croqui != null && croqui.picos.isNotEmpty) {
                      datasetRepo.gerenciadorSessaoOnline
                          .registrarCroquiOnline(id, croqui);
                      datasetRepo.indexarMidiasDoCroqui(id, croqui);

                      AppNav.toPico(
                        context,
                        pico: croqui.picos.first,
                        croqui: croqui,
                        cragId: id,
                      );
                      datasetRepo.updatePriorityAfterNavigation(id);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Erro ao abrir o guia offline.'),
                        ),
                      );
                    }
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
                icon: Icons.delete_outline,
                onPressed: () => _handleDelete(context, id, nome),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
  }) {
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

  Future<void> _handleDelete(
    BuildContext context,
    String cragId,
    String nome,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.caveShadow,
        title: const Text('Excluir?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Deseja excluir o guia de $nome?',
          style: TextStyle(color: context.colors.ashGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'CANCELAR',
              style: TextStyle(color: context.colors.ashGrey),
            ),
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
              content: Text(
                success ? 'Guia excluído.' : 'Erro ao excluir guia.',
              ),
              backgroundColor: success
                  ? context.colors.dryMoss
                  : Theme.of(context).colorScheme.error,
            ),
          );
      }
    }
  }
}
