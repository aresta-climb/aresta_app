// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';

import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/navigation/modal_bottom_sheet_page.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/navigation/page_listenable_builder.dart';
import 'package:frontend/pages/gps.dart';
import 'package:frontend/pages/grupo.dart';
import 'package:frontend/pages/indice_escaladas_page.dart';
import 'package:frontend/pages/mapa_global.dart';
import 'package:frontend/pages/mapas_carrossel.dart';
import 'package:frontend/pages/pico.dart';
import 'package:frontend/pages/pico_subpages/apoie_pico_page.dart';
import 'package:frontend/pages/pico_subpages/comunidade_pico_page.dart';
import 'package:frontend/pages/pico_subpages/explorar_local_page.dart';
import 'package:frontend/pages/pico_subpages/setores_page.dart';
import 'package:frontend/pages/setor.dart';
import 'package:frontend/pages/settings.dart';
import 'package:frontend/pages/sobre_time.dart';
import 'package:frontend/pages/via.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/utils/utilitarios_markdown.dart';
import 'package:frontend/utils/categorizacao_pico.dart';
import 'package:frontend/view/function_library/common_functions.dart';
import 'package:frontend/view/function_library/offline_markdown.dart';
import 'package:frontend/view/view_models/mapa_global_view_model.dart';
import 'package:frontend/view/view_models/pico_view_model.dart';
import 'package:frontend/view/view_models/settings_view_model.dart';
import 'package:frontend/widgets/text_carousel_modal_content.dart';

/// Constrói e resolve a página ([Widget]) correspondente a um nó ([NavNode]) da árvore de navegação.
///
/// Encapsula o mapeamento de nós para páginas de destino, utilizando o [PageListenableBuilder]
/// para garantir a reatividade a hot-reloads e sincronizações em segundo plano dos croquis.
Widget construirPaginaParaNo({
  required NavNode node,
  required DatasetRepository datasetRepo,
  required SyncService syncService,
}) {
  if (node is PicoNode ||
      node is SetoresNode ||
      node is IndiceEscaladasNode ||
      node is ExplorarLocalNode ||
      node is ComunidadePicoNode ||
      node is ApoiePicoNode ||
      node is SetorNode ||
      node is GrupoNode ||
      node is ViaNode ||
      node is TextNode ||
      node is TextCarouselNode ||
      node is MapasCarrosselNode) {
    String cragId = '';
    String? setorNome;
    String? grupoNome;
    String? escaladaNome;

    if (node is PicoContextNode) cragId = node.cragId;
    if (node is TextNode) cragId = node.cragId;
    if (node is TextCarouselNode) cragId = node.cragId;
    if (node is MapasCarrosselNode) cragId = node.cragId;

    if (node is SetorNode) {
      setorNome = node.setorNome;
      grupoNome = node.grupoNome;
    }
    if (node is ViaNode) {
      escaladaNome = node.escaladaNome;
      setorNome = node.setorNome;
      grupoNome = node.grupoNome;
    }
    if (node is GrupoNode) grupoNome = node.grupoNome;

    return PageListenableBuilder(
      cragId: cragId,
      datasetRepo: datasetRepo,
      setorNome: setorNome,
      grupoNome: grupoNome,
      escaladaNome: escaladaNome,
      builder: (context, pico, croqui, setor, grupo, escalada) {
        if (node is PicoNode) {
          Setor? returnToSetor;
          if (node.returnToSetorNome != null) {
            try {
              returnToSetor = pico.setoresOuGrupos
                  .where(
                    (sg) =>
                        sg.whichTipo() == SetorOuGrupo_Tipo.setor &&
                        sg.setor.hasConteudo(),
                  )
                  .map((sg) => sg.setor.conteudo)
                  .firstWhere((s) => s.nome == node.returnToSetorNome);
            } catch (_) {}
          }
          return PicoDetailsPage(
            viewModel: PicoViewModel(
              datasetRepo: datasetRepo,
              pico: pico,
              croqui: croqui,
              cragId: cragId,
            ),
            scrollToMapaGeral: node.scrollToMapaGeral,
            returnToSetor: returnToSetor,
          );
        } else if (node is SetoresNode) {
          return SetoresPage(pico: pico, cragId: cragId);
        } else if (node is IndiceEscaladasNode) {
          return IndiceEscaladasPage(
            pico: pico,
            croqui: croqui,
            cragId: cragId,
          );
        } else if (node is ExplorarLocalNode) {
          return ExplorarLocalPage(
            pico: pico,
            cragId: cragId,
            categories: PicoCategorizedData(croqui),
          );
        } else if (node is ComunidadePicoNode) {
          return ComunidadePicoPage(
            pico: pico,
            cragId: cragId,
            categories: PicoCategorizedData(croqui),
          );
        } else if (node is ApoiePicoNode) {
          return ApoiePicoPage(
            pico: pico,
            cragId: cragId,
            categories: PicoCategorizedData(croqui),
          );
        } else if (node is MapasCarrosselNode) {
          return MapasCarrosselPage(
            pico: pico,
            cragId: cragId,
            mapas: node.mapas,
            initialIndex: node.initialIndex,
            imageProviderOverride: node.imageProviderOverride,
          );
        } else if (node is SetorNode) {
          Escalada? scrollToEscalada;
          if (node.scrollToEscaladaNome != null && setor != null) {
            try {
              scrollToEscalada = setor.escaladas.firstWhere((e) {
                if (e.hasViaEsportiva()) {
                  return e.viaEsportiva.nome == node.scrollToEscaladaNome;
                }
                if (e.hasViaMovel()) {
                  return e.viaMovel.nome == node.scrollToEscaladaNome;
                }
                if (e.hasBoulder()) {
                  return e.boulder.nome == node.scrollToEscaladaNome;
                }
                if (e.hasViaMultiplasEnfiadas()) {
                  return e.viaMultiplasEnfiadas.nome ==
                      node.scrollToEscaladaNome;
                }
                if (e.hasHighline()) {
                  return e.highline.nome == node.scrollToEscaladaNome;
                }
                return false;
              });
            } catch (_) {}
          }
          if (setor != null) {
            return SetorPage(
              setor: setor,
              grupoContext: grupo,
              cragId: cragId,
              scrollToEscalada: scrollToEscalada,
            );
          } else {
            return const Scaffold();
          }
        } else if (node is GrupoNode) {
          return GrupoPage(grupo: grupo!, cragId: cragId);
        } else if (node is ViaNode) {
          return ViaPage(
            pico: pico,
            escalada: escalada!,
            setor: setor,
            grupo: grupo,
            cragId: cragId,
          );
        }
        return const Scaffold();
      },
    );
  }

  if (node is MapaGlobalNode) {
    return MapaGlobalPage(
      viewModel: MapaGlobalViewModel(
        datasetRepo: datasetRepo,
        syncService: syncService,
        picosIniciais: node.crags,
      ),
    );
  }

  if (node is GPSNode) {
    return const GPSPage();
  }

  if (node is SettingsNode) {
    return SettingsPage(
      viewModel: SettingsViewModel(
        datasetRepo: datasetRepo,
        editorDeCroqui: datasetRepo.editorDeCroqui,
      ),
    );
  }

  if (node is SobreTimeNode) {
    return const SobreTimePage();
  }

  return const Center(child: Text('Unknown Node'));
}

/// Constrói uma página de bottom sheet modal declarativa ([Page]) para nós modais da árvore.
///
/// Trata nós do tipo [TextNode] (documentos de texto e avisos em Markdown) e [TextCarouselNode]
/// (carrosséis deslizantes de modais informativos). Retorna `null` se o nó não for modal.
Page? construirPaginaModalParaNo(NavNode node) {
  if (node is TextNode) {
    return ModalBottomSheetPage(
      key: ValueKey(node.toString()),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            final bottomPadding = MediaQuery.of(context).padding.bottom;
            return ListView(
              controller: scrollController,
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: 20 + bottomPadding,
              ),
              children: [
                Column(
                  children: [
                    Center(
                      child: Container(
                        width: 32,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.brandColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (node.icon != null) ...[
                                Icon(
                                  node.icon,
                                  color: AppColors.brandColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  node.title.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        buildFeedbackButton(context, color: Colors.white),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final content = MarkdownUtils.cleanModalContent(
                      node.content,
                      node.title,
                    );
                    return OfflineMarkdown(
                      data: content,
                      cragId: node.cragId,
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  if (node is TextCarouselNode) {
    return ModalBottomSheetPage(
      key: ValueKey(node.toString()),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return TextCarouselModalContent(
              node: node,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  return null;
}
