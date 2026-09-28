// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import 'card_croqui_view_model.dart';
import '../../navigation/navigation_functions.dart';
import '../../services/dataset_repository.dart';
import '../../services/firebase/registro_primeira_visita.dart';
import '../../services/firebase/telemetry_service.dart';
import '../../services/http/sync_service.dart';
import '../../theme/app_colors.dart';
import '../common_functions.dart';

/// Modelo de apresentação para a tela [MeusCroquisPage] (MVVM).
///
/// Observa as atualizações do [DatasetRepository] e expõe a lista de croquis
/// offline já transformados no modelo passivo [CardCroquiViewModel], mantendo a UI
/// livre de regras de negócio e acoplamento com Protobuf.
class MeusCroquisViewModel extends ChangeNotifier {
  /// Repositório de dados locais e catálogo de croquis.
  final DatasetRepository datasetRepo;

  /// Serviço de sincronização e download de dados.
  final SyncService syncService;

  MeusCroquisViewModel({
    required this.datasetRepo,
    required this.syncService,
  }) {
    datasetRepo.activeDataset.addListener(_aoAtualizarDataset);
  }

  void _aoAtualizarDataset() {
    notifyListeners();
  }

  @override
  void dispose() {
    datasetRepo.activeDataset.removeListener(_aoAtualizarDataset);
    super.dispose();
  }

  /// Retorna a lista de croquis salvos offline mapeados como [CardCroquiViewModel].
  List<CardCroquiViewModel> get croquisSalvos {
    final dataset = datasetRepo.activeDataset.value;
    if (dataset == null) return const [];
    if (dataset.croquisBaixados.isNotEmpty) {
      return dataset.croquisBaixados.map(mapearCroquiParaCard).toList();
    }
    return dataset.picosBaixados.map((pico) {
      final stats = pico.estatisticas;
      final textoStats = stats != null
          ? '${stats.totalSetores} setores • ${stats.totalVias} escaladas'
          : '';
      return CardCroquiViewModel(
        id: pico.id,
        titulo: pico.nome,
        localizacao: pico.local,
        textoEstatisticas: textoStats,
        caminhoMiniatura: pico.thumbnailUrl,
        salvoOffline: true,
      );
    }).toList();
  }

  /// Indica se não há nenhum croqui salvo offline.
  bool get estaVazio => croquisSalvos.isEmpty;

  /// Dispara a rotina de sincronização manual dos croquis salvos.
  Future<void> sincronizarManual(BuildContext context) async {
    await handleManualSync(context, datasetRepo, syncService);
  }

  /// Carrega o croqui salvo offline e realiza a navegação para os detalhes do pico.
  Future<void> abrirCroqui(BuildContext context, String cragId, {Croqui? croquiPrecarregado}) async {
    final primeiraVisita =
        await RegistroPrimeiraVisita.instancia.registrarEVerificarPrimeiraVisita(cragId);

    TelemetryService.instance.logAcaoCroqui(
      cragId,
      'abrir_croqui',
      origem: 'meus_croquis',
      modoAcesso: 'offline',
      primeiraVisita: primeiraVisita,
    );

    Croqui? croqui = croquiPrecarregado ?? await datasetRepo.getCroqui(cragId);

    if (!context.mounted) return;

    if (croqui != null && croqui.picos.isNotEmpty) {
      datasetRepo.gerenciadorSessaoOnline.registrarCroquiOnline(cragId, croqui);
      datasetRepo.indexarMidiasDoCroqui(cragId, croqui);

      AppNav.toPico(
        context,
        pico: croqui.picos.first,
        croqui: croqui,
        cragId: cragId,
      );
      datasetRepo.updatePriorityAfterNavigation(cragId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao abrir o guia offline.'),
        ),
      );
    }
  }

  /// Exibe diálogo de confirmação de exclusão e remove o croqui localmente se confirmado.
  Future<void> excluirCroqui(BuildContext context, String cragId, String nome) async {
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
