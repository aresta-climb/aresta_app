// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../services/dataset_repository.dart';
import '../utils/pico_categorization.dart';
import 'pico_functions.dart';

/// Modelo de apresentação e gerenciador de estado para a tela [PicoDetailsPage] (MVVM).
///
/// Encapsula a formatação estatística do pico (setores, modalidades, contagem de vias),
/// o ciclo de vida do polling de atualizações online (ETag), a interceptação de saída
/// para picos não salvos offline e operações de download/exclusão.
class PicoViewModel extends ChangeNotifier {
  /// Dados do pico obtidos a partir do croqui.
  final Pico pico;

  /// Objeto completo do croqui.
  final Croqui croqui;

  /// Identificador único do pico/crag.
  final String cragId;

  /// Repositório de dados com dataset ativo e gerenciamento de armazenamento.
  final DatasetRepository datasetRepo;

  final ServicoCroquiOnline _servicoCroquiOnline;
  final PicoCategorizedData _categorias;
  bool _isInitiallyDownloaded;

  PicoViewModel({
    required this.pico,
    required this.croqui,
    required this.cragId,
    required this.datasetRepo,
    ServicoCroquiOnline? servicoCroquiOnline,
  })  : _categorias = PicoCategorizedData(croqui),
        _servicoCroquiOnline = servicoCroquiOnline ??
            ServicoCroquiOnline(
              sessaoOnline: datasetRepo.gerenciadorSessaoOnline,
              verificarPicoBaixado: (id) => datasetRepo.isPicoDownloaded(id),
            ),
        _isInitiallyDownloaded = datasetRepo.isPicoDownloaded(cragId) {
    datasetRepo.activeDataset.addListener(_verificarStatusDownload);
  }

  void _verificarStatusDownload() {
    final baixado = datasetRepo.isPicoDownloaded(cragId);
    if (baixado) {
      _servicoCroquiOnline.cancelarPolling(cragId);
      if (!_isInitiallyDownloaded) {
        _isInitiallyDownloaded = true;
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    datasetRepo.activeDataset.removeListener(_verificarStatusDownload);
    _servicoCroquiOnline.cancelarPolling(cragId);
    _servicoCroquiOnline.dispose();
    super.dispose();
  }

  /// Indica se o pico está atualmente salvo no armazenamento offline.
  bool get isDownloaded => datasetRepo.isPicoDownloaded(cragId);

  /// Indica se o pico já estava baixado no momento em que a tela foi aberta.
  bool get isInitiallyDownloaded => _isInitiallyDownloaded;

  /// Categorias extraídas dos botões do croqui (regras, créditos, etc.).
  PicoCategorizedData get categorias => _categorias;

  /// Lista de regras extraídas do croqui.
  List<Botao> get regras => _categorias.regras;

  /// Lista de botões de créditos e agradecimentos.
  List<Botao> get creditos => _categorias.creditos;

  /// Tamanho formatado em bytes vindo do catálogo disponível.
  String get tamanhoFormatado {
    final dataset = datasetRepo.activeDataset.value;
    ResumoPico? picoItem;
    try {
      picoItem = dataset?.picosDisponiveis.firstWhere((p) => p.id == cragId);
    } catch (_) {}
    return picoItem?.tamanhoFormatado ?? 'Offline';
  }

  /// Quantidade total de setores somando setores avulsos e setores dentro de grupos.
  int get totalSetores {
    int count = 0;
    for (final sg in pico.setoresOuGrupos) {
      if (sg.whichTipo() == SetorOuGrupo_Tipo.setor) {
        count++;
      } else if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo) {
        count += sg.grupo.conteudo.setores.length;
      }
    }
    return count;
  }

  /// Texto de dica do botão de pesquisa na barra superior.
  String get tooltipBusca {
    if (isPicoBoulderArea(pico)) {
      return 'Buscar boulder';
    }
    return 'Buscar via';
  }

  /// Data e hora formatada da última sincronização ou atualização do croqui.
  String get textoUltimaAtualizacao {
    final data = datasetRepo.obterDataAtualizacaoCroqui(cragId);
    return formatarTextoUltimaAtualizacao(data);
  }
}
