import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../aresta_api/proto/generated/croqui.pbenum.dart';
import '../services/dataset_repository.dart';
import 'navigation_functions.dart';

/// Um builder reativo que escuta as atualizações do `DatasetRepository` e
/// redesenha a página atual com os dados mais recentes do croqui.
/// Ideal para o Hot Reload do modo experimental.
class PageListenableBuilder extends StatelessWidget {
  final String cragId;
  final String? setorNome;
  final String? grupoNome;
  final String? escaladaNome;
  final DatasetRepository datasetRepo;
  final Widget Function(
    BuildContext context,
    Pico pico,
    Croqui croqui,
    Setor? setor,
    Grupo? grupo,
    Escalada? escalada,
  ) builder;

  const PageListenableBuilder({
    super.key,
    required this.cragId,
    required this.datasetRepo,
    this.setorNome,
    this.grupoNome,
    this.escaladaNome,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TopoDataset?>(
      valueListenable: datasetRepo.activeDataset,
      builder: (context, topoDataset, child) {
        if (topoDataset == null) {
          // Fallback se o dataset for zerado repentinamente
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Encontra o crag nos picos baixados
        Map<String, dynamic>? cragData;
        try {
          final crag = topoDataset.downloadedPicos.firstWhere((p) => p['id'] == cragId);
          cragData = crag['data'] as Map<String, dynamic>?;
        } catch (_) {}

        if (cragData == null) {
          // O pico foi apagado do dataset
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && AppNav.canGoBack(context)) {
              AppNav.back(context);
            }
          });
          return const Scaffold();
        }

        final pico = cragData['pico'] as Pico;
        final croqui = cragData['croqui'] as Croqui;

        Setor? matchedSetor;
        if (setorNome != null) {
          try {
            matchedSetor = pico.setoresOuGrupos
                .where((sg) => sg.whichTipo() == SetorOuGrupo_Tipo.setor && sg.setor.hasConteudo())
                .map((sg) => sg.setor.conteudo)
                .firstWhere((s) => s.nome == setorNome);
          } catch (_) {
            // Setor apagado ou renomeado
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted && AppNav.canGoBack(context)) {
                AppNav.back(context);
              }
            });
            return const Scaffold();
          }
        }

        Grupo? matchedGrupo;
        if (grupoNome != null) {
          try {
            matchedGrupo = pico.setoresOuGrupos
                .where((sg) => sg.whichTipo() == SetorOuGrupo_Tipo.grupo && sg.grupo.hasConteudo())
                .map((sg) => sg.grupo.conteudo)
                .firstWhere((g) => g.nome == grupoNome);
          } catch (_) {
            // Grupo apagado ou renomeado
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted && AppNav.canGoBack(context)) {
                AppNav.back(context);
              }
            });
            return const Scaffold();
          }
        }

        Escalada? matchedEscalada;
        if (escaladaNome != null) {
          try {
            if (matchedSetor != null) {
              matchedEscalada = matchedSetor.escaladas.firstWhere((e) {
                if (e.hasViaEsportiva()) return e.viaEsportiva.nome == escaladaNome;
                if (e.hasViaMovel()) return e.viaMovel.nome == escaladaNome;
                if (e.hasBoulder()) return e.boulder.nome == escaladaNome;
                if (e.hasViaMultiplasEnfiadas()) return e.viaMultiplasEnfiadas.nome == escaladaNome;
                if (e.hasHighline()) return e.highline.nome == escaladaNome;
                return false;
              });
            } else if (matchedGrupo != null) {
              // Escaladas podem estar em grupos? Não, escaladas estão em setores, mas para garantir,
              // normalmente iteramos se for o caso. Pela estrutura, Escalada fica em Setor.
              // Vamos assumir que escalada requer setorNome.
            }
          } catch (_) {
            // Via apagada ou renomeada
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted && AppNav.canGoBack(context)) {
                AppNav.back(context);
              }
            });
            return const Scaffold();
          }
        }

        return builder(context, pico, croqui, matchedSetor, matchedGrupo, matchedEscalada);
      },
    );
  }
}
