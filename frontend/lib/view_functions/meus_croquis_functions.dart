// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../data/dtos/card_croqui_dto.dart';
import '../theme/app_colors.dart';
import '../widgets/provedor_imagem_aresta.dart';

/// Card interativo para exibição de um croqui baixado na aba Meus Croquis a partir de [CardCroquiDTO] (Dumb UI).
///
/// Não contém regras de negócio ou de persistência de dados, apenas renderiza visualmente
/// as informações já preparadas e delega ações do usuário via callbacks.
class OfflineCragCard extends StatelessWidget {
  final CardCroquiDTO dados;
  final VoidCallback onAbrir;
  final VoidCallback onExcluir;

  const OfflineCragCard({
    super.key,
    required this.dados,
    required this.onAbrir,
    required this.onExcluir,
  });

  /// Construtor de conveniência que recebe diretamente a entidade [Croqui] e mapeia para [CardCroquiDTO].
  factory OfflineCragCard.deCroqui({
    Key? key,
    required Croqui crag,
    required VoidCallback onAbrir,
    required VoidCallback onExcluir,
  }) {
    return OfflineCragCard(
      key: key,
      dados: mapearCroquiParaCard(crag),
      datasetRepo: datasetRepo,
      syncService: syncService,
      croquiOriginal: crag,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String id = dados.id;
    final String nome = dados.titulo;
    final String local = dados.localizacao;
    final String statsText = dados.textoEstatisticas;

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
                      caminho: dados.caminhoMiniatura,
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

                    Croqui? croqui =
                        croquiOriginal ?? await datasetRepo.getCroqui(id);

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
