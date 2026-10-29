// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../services/repositorio_dataset.dart';
import '../utils/consulta_dataset.dart';
import '../services/firebase/app_logger.dart';
import 'funcoes_navegacao.dart';

/// Provedor em árvore de widgets que compartilha a instância indexada de
/// [DatasetResolver] para todas as páginas e sub-componentes de um mesmo croqui.
class _ProvedorResolverCroqui extends InheritedWidget {
  final DatasetResolver resolvedor;

  const _ProvedorResolverCroqui({
    required this.resolvedor,
    required super.child,
  });

  @override
  bool updateShouldNotify(_ProvedorResolverCroqui oldWidget) =>
      !identical(resolvedor, oldWidget.resolvedor);
}

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

  /// Recupera a instância compartilhada de [DatasetResolver] associada à
  /// hierarquia de página do croqui atual, se disponível no [context].
  static DatasetResolver? resolverOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ProvedorResolverCroqui>()
        ?.resolvedor;
  }

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

        // 1. Tenta encontrar o pico nos picos baixados
        Pico? pico;
        Croqui? croqui;
        bool estaMarcadoBaixado = false;
        try {
          final crag = topoDataset.downloadedPicos.firstWhere(
            (p) => p.id == cragId,
          );
          estaMarcadoBaixado = true;
          pico = crag.pico;
          croqui = crag.croqui;
        } catch (_) {}

        // 1.1 Se não encontrou pico ou croqui em downloadedPicos, tenta em croquisBaixados
        if (pico == null || croqui == null) {
          try {
            final croquiBaixado = topoDataset.croquisBaixados.firstWhere(
              (c) => c.id == cragId,
            );
            if (croquiBaixado.picos.isNotEmpty) {
              pico = croquiBaixado.picos.first;
              croqui = croquiBaixado;
            }
          } catch (_) {}
        }

        // 2. Se não estiver baixado, tenta resolver da sessão online ativa
        if (pico == null || croqui == null) {
          final croquiOnline =
              datasetRepo.gerenciadorSessaoOnline.obterCroquiOnline(cragId);
          if (croquiOnline != null && croquiOnline.picos.isNotEmpty) {
            pico = croquiOnline.picos.first;
            croqui = croquiOnline;
          }
        }

        // 2.1 Se o pico consta como baixado mas ainda não foi carregado em memória (lazy loading),
        // dispara o carregamento sob demanda via getCroqui.
        if ((pico == null || croqui == null) && estaMarcadoBaixado) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final carregado = await datasetRepo.getCroqui(
              cragId,
              indiceJaSincronizado: true,
            );
            if ((carregado == null || carregado.picos.isEmpty) &&
                context.mounted &&
                AppNav.canGoBack(context)) {
              AppNav.back(context);
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (pico == null || croqui == null) {
          // O pico foi apagado do dataset
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && AppNav.canGoBack(context)) {
              AppNav.back(context);
            }
          });
          return const Scaffold();
        }

        try {
          final picoResolvido = pico;
          final croquiResolvido = croqui;
          final resolvedor = DatasetResolver(
            pico: picoResolvido,
            croqui: croquiResolvido,
          );
          final res = DatasetResolver.resolve(
            pico: picoResolvido,
            grupoNome: grupoNome,
            setorNome: setorNome,
            escaladaNome: escaladaNome,
          );

          return _ProvedorResolverCroqui(
            resolvedor: resolvedor,
            child: Builder(
              builder: (innerContext) => builder(
                innerContext,
                picoResolvido,
                croquiResolvido,
                res.setor,
                res.grupo,
                res.escalada,
              ),
            ),
          );
        } catch (e, st) {
          AppLogger.instance.logError(
            'Exception while resolving node in PageListenableBuilder',
            error: e,
            stackTrace: st,
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
