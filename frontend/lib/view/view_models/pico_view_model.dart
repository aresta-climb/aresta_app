// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../services/dataset_repository.dart';
import '../../services/http/sync_service.dart';
import '../../services/http/servico_download_segundo_plano.dart';
import '../../utils/categorizacao_pico.dart';
import '../function_library/pico_functions.dart';

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
    iniciarPollingOnlineSeNecessario();
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

  /// Subtítulo consolidado com estado, total de setores e distribuição de modalidades.
  String get subtitulo {
    final int setoresCount = totalSetores;
    int totalVias = 0;
    int totalBoulders = 0;
    int totalEsportivas = 0;
    int totalMoveis = 0;
    int totalMultiplasEnfiadas = 0;
    int totalHighlines = 0;

    void processarEscaladas(Iterable<Escalada> escaladas) {
      for (final escalada in escaladas) {
        totalVias++;
        switch (escalada.whichTipo()) {
          case Escalada_Tipo.boulder:
            totalBoulders++;
            break;
          case Escalada_Tipo.viaEsportiva:
            totalEsportivas++;
            break;
          case Escalada_Tipo.viaMovel:
            totalMoveis++;
            break;
          case Escalada_Tipo.viaMultiplasEnfiadas:
            totalMultiplasEnfiadas++;
            break;
          case Escalada_Tipo.highline:
            totalHighlines++;
            break;
          default:
            break;
        }
      }
    }

    for (final sg in pico.setoresOuGrupos) {
      if (sg.whichTipo() == SetorOuGrupo_Tipo.setor) {
        processarEscaladas(sg.setor.conteudo.escaladas);
      } else if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo) {
        for (final s in sg.grupo.conteudo.setores) {
          processarEscaladas(s.conteudo.escaladas);
        }
      }
    }

    String statsText = '';
    if (totalVias > 0) {
      final List<String> modalidades = [];
      if (totalEsportivas > 0) modalidades.add('$totalEsportivas esportivas');
      if (totalBoulders > 0) modalidades.add('$totalBoulders boulders');
      if (totalMoveis > 0) modalidades.add('$totalMoveis móveis');
      if (totalMultiplasEnfiadas > 0) {
        modalidades.add('$totalMultiplasEnfiadas múltiplas enfiadas');
      }
      if (totalHighlines > 0) modalidades.add('$totalHighlines highlines');

      statsText = ' • $totalVias escaladas';
      if (modalidades.isNotEmpty) {
        statsText += ' (${modalidades.join(', ')})';
      }
    }

    return '${pico.estado.toUpperCase()} • $setoresCount SETORES$statsText';
  }

  /// Inicia polling de verificação ETag caso o pico não esteja baixado e possua URL.
  void iniciarPollingOnlineSeNecessario() {
    final dataset = datasetRepo.activeDataset.value;
    if (!_isInitiallyDownloaded && dataset != null) {
      try {
        final picoItem = dataset.picosDisponiveis.firstWhere(
          (p) => p.id == cragId,
        );
        final url = picoItem.url;
        if (url.isNotEmpty) {
          _servicoCroquiOnline.iniciarPollingEtag(
            cragId,
            url,
            aoAtualizar: (picoId, croquiAtualizado) {
              datasetRepo.notificarAtualizacaoSessaoOnline(picoId);
              final isExperimental =
                  datasetRepo.editorDeCroqui.isExperimentalMode.value;
              if (isExperimental) {
                datasetRepo.editorDeCroqui.dispararPulsoRecarregamento();
              } else {
                datasetRepo.notificarCroquiOnlineAtualizadoNaUI(
                  pico.nome.isNotEmpty ? pico.nome : picoId,
                );
              }
              notifyListeners();
            },
          );
        }
      } catch (_) {}
    }
  }

  /// Cancela o polling online ativo para este pico.
  void cancelarPolling() {
    _servicoCroquiOnline.cancelarPolling(cragId);
  }

  /// Avalia se a navegação de retorno deve ser interceptada com modal de confirmação.
  bool deveInterceptarSaida({required bool staysInSameCroqui}) {
    if (staysInSameCroqui) {
      return false;
    }
    if (isDownloaded) {
      return false;
    }
    return true;
  }

  /// Inicia o download do croqui em segundo plano via [ServicoDownloadSegundoPlano].
  Future<bool> baixarPico({required SyncService? syncService}) async {
    final indice = datasetRepo.indiceData.value;
    if (indice == null) return false;

    final resumos = indice.croquis.where((r) => r.id == cragId).toList();
    if (resumos.isEmpty) return false;

    if (syncService == null) return false;
    final servicoDownload = ServicoDownloadSegundoPlano(syncService: syncService);
    final sucesso = await servicoDownload.executarDownload(resumos.first);

    if (sucesso) {
      cancelarPolling();
      _isInitiallyDownloaded = true;
      notifyListeners();
    }
    return sucesso;
  }

  /// Exclui o pico do armazenamento local e preserva em memória na sessão online.
  Future<bool> excluirPico() async {
    datasetRepo.gerenciadorSessaoOnline.registrarCroquiOnline(cragId, croqui);
    final sucesso = await datasetRepo.deleteCrag(cragId);
    notifyListeners();
    return sucesso;
  }
}
