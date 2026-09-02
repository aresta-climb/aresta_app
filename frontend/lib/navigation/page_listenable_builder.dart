// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../services/dataset_repository.dart';
import '../utils/dataset_resolver.dart';
import '../services/firebase/app_logger.dart';
import 'navigation_functions.dart';
import '../theme/app_colors.dart';
import '../view_functions/common_functions.dart';
import '../main.dart';

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
  )
  builder;

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

        // 1. Tenta encontrar o crag nos picos baixados
        Map<String, dynamic>? cragData;
        try {
          final crag = topoDataset.downloadedPicos.firstWhere(
            (p) => p['id'] == cragId,
          );
          cragData = crag['data'] as Map<String, dynamic>?;
        } catch (_) {}

        // 2. Se não estiver baixado, tenta resolver da sessão online ativa
        if (cragData == null) {
          final croquiOnline =
              datasetRepo.gerenciadorSessaoOnline.obterCroquiOnline(cragId);
          if (croquiOnline != null && croquiOnline.picos.isNotEmpty) {
            cragData = {
              'pico': croquiOnline.picos.first,
              'croqui': croquiOnline,
            };
          }
        }

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

        try {
          final res = DatasetResolver.resolve(
            pico: pico,
            grupoNome: grupoNome,
            setorNome: setorNome,
            escaladaNome: escaladaNome,
          );

          final pageContent = builder(
            context,
            pico,
            croqui,
            res.setor,
            res.grupo,
            res.escalada,
          );

          final treeWrapper = context
              .findAncestorWidgetOfExactType<TreeNavigationWrapper>();
          final syncService = treeWrapper?.syncService;

          if (syncService == null) return pageContent;

          return ValueListenableBuilder<String?>(
            valueListenable: syncService.recarga_pendente_pico_id,
            builder: (context, pendingId, child) {
              final isExperimental =
                  datasetRepo.editorDeCroqui.isExperimentalMode.value;
              if (pendingId == cragId && !isExperimental) {
                return Stack(
                  children: [
                    IgnorePointer(child: child!),
                    Container(
                      color: Colors.black.withValues(alpha: 0.8),
                      child: Center(
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: context.colors.caveShadow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: context.colors.graniteEdge,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 8),
                                    const Icon(
                                      Icons.history,
                                      size: 48,
                                      color: AppColors.brandColor,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Croqui Atualizado',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: context.colors.chalkWhite,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Uma nova versão deste croqui foi instalada em segundo plano. Recarregue a página para acessar as novidades.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: context.colors.ashGrey,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          syncService.commitPendenciasAtomaticas(
                                            cragId,
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.brandColor,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text(
                                          'RECARREGAR',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  top: -12,
                                  right: -12,
                                  child: buildFeedbackButton(
                                    context,
                                    color: context.colors.chalkWhite,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return child!;
            },
            child: pageContent,
          );
        } catch (e, st) {
          AppLogger.instance.logError(
            'Exception while resolving node in PageListenableBuilder: $e\nStacktrace:\n$st',
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && AppNav.canGoBack(context)) {
              AppNav.back(context);
            }
          });
          return const Scaffold();
        }
      },
    );
  }
}
