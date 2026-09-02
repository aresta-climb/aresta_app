// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../services/dataset_repository.dart';
import '../utils/dataset_resolver.dart';
import '../services/firebase/app_logger.dart';
import 'navigation_functions.dart';
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

          return pageContent;
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
