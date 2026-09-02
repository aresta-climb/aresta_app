// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../aresta_api/proto/generated/indice.pb.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import 'editor_croqui.dart';
import 'firebase/app_logger.dart';
import '../utils/formatador_tamanho.dart';

import 'dataset/modelos/conjunto_dados_croqui.dart';
import 'dataset/armazenamento/gerenciador_prioridade_picos.dart';
import 'dataset/armazenamento/gerenciador_arquivos_locais.dart';
import 'dataset/armazenamento/extrator_assets_preload.dart';
import 'dataset/metadados/extrator_metadados_croqui.dart';
import 'dataset/sessao_online/gerenciador_sessao_online.dart';

export 'dataset/modelos/conjunto_dados_croqui.dart';
export 'dataset/armazenamento/gerenciador_prioridade_picos.dart';
export 'dataset/armazenamento/gerenciador_arquivos_locais.dart';
export 'dataset/armazenamento/extrator_assets_preload.dart';
export 'dataset/metadados/extrator_metadados_croqui.dart';
export 'dataset/sessao_online/gerenciador_sessao_online.dart';

/// Gerenciador central e repositório de dados de escalada do aplicativo.
///
/// Atua como fachada orquestradora para armazenamento local, pré-carregamento,
/// metadados, sessões de exploração online e priorização de picos.
class DatasetRepository {
  final EditorDeCroqui editorDeCroqui;
  AssetBundle? assetBundle;

  final GerenciadorPrioridadePicos gerenciadorPrioridade;
  final GerenciadorArquivosLocais gerenciadorArquivosLocais;
  final ExtratorAssetsPreload extratorAssets;
  final ExtratorMetadadosCroqui extratorMetadados;
  final GerenciadorSessaoOnline gerenciadorSessaoOnline;

  static DatasetRepository? _instance;
  static DatasetRepository? get instance => _instance;

  DatasetRepository({
    required this.editorDeCroqui,
    this.assetBundle,
    GerenciadorPrioridadePicos? gerenciadorPrioridade,
    GerenciadorArquivosLocais? gerenciadorArquivosLocais,
    ExtratorAssetsPreload? extratorAssets,
    ExtratorMetadadosCroqui? extratorMetadados,
    GerenciadorSessaoOnline? gerenciadorSessaoOnline,
  })  : gerenciadorPrioridade =
            gerenciadorPrioridade ?? GerenciadorPrioridadePicos(),
        gerenciadorArquivosLocais =
            gerenciadorArquivosLocais ?? GerenciadorArquivosLocais(),
        extratorAssets = extratorAssets ?? ExtratorAssetsPreload(),
        extratorMetadados = extratorMetadados ?? ExtratorMetadadosCroqui(),
        gerenciadorSessaoOnline =
            gerenciadorSessaoOnline ?? GerenciadorSessaoOnline() {
    _instance = this;
    editorDeCroqui.isExperimentalMode.addListener(_handleModeChange);
    editorDeCroqui.editorUrl.addListener(_handleModeChange);
  }

  void _handleModeChange() {
    debugPrint('[DatasetRepo] Modo alterado detectado. Recarregando índice...');
    init();
  }

  // ===========================================================================
  // SECTION: Estado e Notificadores
  // ===========================================================================

  /// Notifica a interface do usuário sobre mudanças nos picos disponíveis e baixados.
  final ValueNotifier<ConjuntoDadosCroqui?> activeDataset = ValueNotifier(null);

  /// Armazena a estrutura completa do [Indice] em memória.
  final ValueNotifier<Indice?> indiceData = ValueNotifier(null);

  /// Disparo para reiniciar a visualização do carrossel da Home.
  final ValueNotifier<int> homeResetTrigger = ValueNotifier(0);

  // ===========================================================================
  // SECTION: Inicialização e Carregamento
  // ===========================================================================

  Future<void>? _currentInitFuture;

  /// Inicializa o repositório carregando o índice a partir do armazenamento local ou preload.
  Future<void> init() async {
    if (_currentInitFuture != null) {
      return _currentInitFuture;
    }
    _currentInitFuture = _executarInit();
    try {
      await _currentInitFuture;
    } finally {
      _currentInitFuture = null;
    }
  }

  Future<void> _executarInit() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final localIndiceFile = File(editorDeCroqui.indicePath(directory.path));

      if (!await localIndiceFile.exists()) {
        if (!editorDeCroqui.isExperimentalMode.value) {
          await extratorAssets.desempacotarAssetsPreload(
            docsPath: directory.path,
            indicePath: localIndiceFile.path,
            bundle: assetBundle,
          );
        }
      }

      if (await localIndiceFile.exists()) {
        final bytes = await localIndiceFile.readAsBytes();
        final localIndice = Indice.fromBuffer(bytes);
        indiceData.value = localIndice;
        await loadIndiceToMemory(localIndice);
      } else {
        loadEmpty();
      }
    } catch (e) {
      AppLogger.instance.logError(
        '[DatasetRepo] Erro na inicialização',
        error: e,
      );
      loadEmpty();
    }
  }

  /// Converte os resumos de [Indice] em estruturas mapeadas para a interface.
  Future<void> loadIndiceToMemory(Indice indice) async {
    indiceData.value = indice;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final docsPath = directory.path;
      final downloadsPath = editorDeCroqui.downloadsPath(docsPath);
      final List<String> priorityList =
          await gerenciadorPrioridade.obterListaPrioridade(docsPath);

      final List<Map<String, dynamic>> parsedPicos = [];
      final List<Map<String, dynamic>> downloaded = [];

      for (var resumo in indice.croquis) {
        try {
          String locationText = 'Local Desconhecido';
          final List<String> urlParts = resumo.caminhoRelativo.split('/');
          if (urlParts.length >= 2) {
            String folderName = urlParts[urlParts.length - 2];
            locationText = folderName
                .replaceAll('_', ' ')
                .split(' ')
                .map((word) {
                  if (word.isEmpty) return word;
                  return word[0].toUpperCase() +
                      word.substring(1).toLowerCase();
                })
                .join(' ');
          }

          String thumbnailUrl = '';
          final url = resumo.caminhoRelativo;
          final lastSlash = url.lastIndexOf('/');
          final baseUrl = editorDeCroqui.activeBaseUrl;
          if (lastSlash != -1) {
            final baseDir = url.substring(0, lastSlash);
            thumbnailUrl = '$baseUrl/$baseDir/imagens/thumbnail.webp';
          } else {
            thumbnailUrl = '$baseUrl/imagens/thumbnail.webp';
          }

          final String picoId = resumo.id;
          final bool isStored = await gerenciadorArquivosLocais
              .verificarPicoBaixado(downloadsPath, picoId);

          int? tamanhoBytes;
          // TODO(proto): restaurar leitura quando tamanho_download_bytes for adicionado ao indice.proto upstream
          // if (resumo.hasPrecomputados() && resumo.precomputados.hasTamanhoDownloadBytes()) {
          //   tamanhoBytes = resumo.precomputados.tamanhoDownloadBytes.toInt();
          // }

          final Map<String, dynamic> picoMap = {
            'nome': resumo.nome,
            'local': locationText,
            'descricao': resumo.descricao,
            'id': picoId,
            'url': '${editorDeCroqui.activeBaseUrl}/${resumo.caminhoRelativo}',
            'checksum': resumo.checksumSha256Croqui,
            'thumbnailUrl': thumbnailUrl,
            'isDownloaded': isStored,
            'tamanhoBytes': tamanhoBytes,
            'tamanhoFormatado': FormatadorTamanho.formatarBytes(tamanhoBytes),
            'dataUpdate': resumo.hasTimestampUpdate()
                ? resumo.timestampUpdate.toDateTime().toIso8601String()
                : null,
            if (resumo.hasLocalizacao())
              'latitude': resumo.localizacao.latitude / 10000000.0,
            if (resumo.hasLocalizacao())
              'longitude': resumo.localizacao.longitude / 10000000.0,
            if (resumo.hasPrecomputados())
              'estatisticas': {
                'totalVias': resumo.precomputados.totalEscaladas,
                'totalSetores': resumo.precomputados.totalSetores,
                'totalEsportivas': resumo.precomputados.totalEsportivas,
                'totalMoveis': resumo.precomputados.totalMoveis,
                'totalBoulders': resumo.precomputados.totalBoulders,
                'totalMultiplasEnfiadas':
                    resumo.precomputados.totalMultiplasEnfiadas,
                'totalHighlines': resumo.precomputados.totalHighlines,
                'tamanhoDownloadBytes': ?tamanhoBytes,
              },
          };

          parsedPicos.add(picoMap);
          if (isStored) {
            downloaded.add(picoMap);
          }
        } catch (itemEx) {
          AppLogger.instance.logError(
            'Erro ao processar pico individual ${resumo.id}',
            error: itemEx,
          );
        }
      }

      final ordenados =
          gerenciadorPrioridade.ordenarPorPrioridade(downloaded, priorityList);

      await Future.wait(
        ordenados.map((picoData) async {
          try {
            await extratorMetadados.atualizarMetadadosPico(
              id: picoData['id'],
              picoData: picoData,
              downloadsPath: downloadsPath,
              baseUrl: editorDeCroqui.activeBaseUrl,
            );
          } catch (e) {
            AppLogger.instance.logError(
              'Erro ao atualizar metadados do pico ${picoData['id']}',
              error: e,
            );
          }
        }),
      );

      activeDataset.value = ConjuntoDadosCroqui(
        picosDisponiveis: parsedPicos,
        picosBaixados: ordenados,
      );
    } catch (e) {
      AppLogger.instance.logError(
        'Erro crítico em loadIndiceToMemory',
        error: e,
      );
      if (activeDataset.value == null) {
        loadEmpty();
      }
    }
  }

  /// Limpa os dados em memória definindo listas vazias.
  void loadEmpty() {
    activeDataset.value = ConjuntoDadosCroqui.vazio();
  }

  /// Atualiza o conjunto de dados após a conclusão de um download.
  Future<void> updateDatasetAfterDownload(String id) async {
    await _refreshActiveDataset();
  }

  // ===========================================================================
  // SECTION: Prioridade e Navegação
  // ===========================================================================

  /// Atualiza a prioridade do [id] após a navegação do usuário.
  Future<void> updatePriorityAfterNavigation(String id) async {
    final directory = await getApplicationDocumentsDirectory();
    await gerenciadorPrioridade.atualizarPrioridade(directory.path, id);

    if (activeDataset.value != null) {
      final docsPath = directory.path;
      final downloadsPath = editorDeCroqui.downloadsPath(docsPath);
      final List<String> priorityList =
          await gerenciadorPrioridade.obterListaPrioridade(docsPath);

      final List<Map<String, dynamic>> baixados = [];
      for (var pico in activeDataset.value!.picosDisponiveis) {
        if (await gerenciadorArquivosLocais.verificarPicoBaixado(
            downloadsPath, pico['id'])) {
          baixados.add(pico);
        }
      }

      final ordenados =
          gerenciadorPrioridade.ordenarPorPrioridade(baixados, priorityList);

      activeDataset.value = ConjuntoDadosCroqui(
        picosDisponiveis: activeDataset.value!.picosDisponiveis,
        picosBaixados: ordenados,
      );
    }
  }

  // ===========================================================================
  // SECTION: Consulta de Croqui (Híbrido: Local ou Sessão Online)
  // ===========================================================================

  /// Recupera o [Croqui] completo de um pico (seja local ou da sessão online ativa).
  Future<Croqui?> getCroqui(String id) async {
    final directory = await getApplicationDocumentsDirectory();
    final downloadsPath = editorDeCroqui.downloadsPath(directory.path);

    // 1. Tenta carregar do disco permanente (/downloads)
    final localCroqui =
        await gerenciadorArquivosLocais.carregarCroqui(downloadsPath, id);
    if (localCroqui != null) {
      return localCroqui;
    }

    // 2. Se não estiver no disco permanente, consulta a sessão online ativa
    return gerenciadorSessaoOnline.obterCroquiOnline(id);
  }

  /// Exclui um pico do armazenamento permanente e atualiza a interface.
  Future<bool> deleteCrag(String id) async {
    final directory = await getApplicationDocumentsDirectory();
    final downloadsPath = editorDeCroqui.downloadsPath(directory.path);

    // Se o croqui existia localmente, preserva em memória na sessão online
    // para permitir transição suave caso o usuário esteja navegando nele.
    final localCroqui =
        await gerenciadorArquivosLocais.carregarCroqui(downloadsPath, id);
    if (localCroqui != null) {
      gerenciadorSessaoOnline.registrarCroquiOnline(id, localCroqui);
    }

    final sucesso =
        await gerenciadorArquivosLocais.excluirPico(downloadsPath, id);
    if (sucesso) {
      await _refreshActiveDataset();
    }
    return sucesso;
  }

  /// Reavalia o estado de download dos picos e emite novo estado para a UI.
  Future<void> _refreshActiveDataset() async {
    if (activeDataset.value == null) return;

    final currentAvailable = activeDataset.value!.picosDisponiveis;
    final directory = await getApplicationDocumentsDirectory();
    final docsPath = directory.path;
    final downloadsPath = editorDeCroqui.downloadsPath(docsPath);

    final List<Map<String, dynamic>> updatedDownloaded = [];
    for (var pico in currentAvailable) {
      final String picoId = pico['id']?.toString() ?? '';
      final bool isStored = await gerenciadorArquivosLocais
          .verificarPicoBaixado(downloadsPath, picoId);

      pico['isDownloaded'] = isStored;
      if (isStored) {
        updatedDownloaded.add(pico);
      }
    }

    final List<String> priorityList =
        await gerenciadorPrioridade.obterListaPrioridade(docsPath);
    final ordenados = gerenciadorPrioridade.ordenarPorPrioridade(
        updatedDownloaded, priorityList);

    await Future.wait(
      ordenados.map((p) => extratorMetadados.atualizarMetadadosPico(
            id: p['id'],
            picoData: p,
            downloadsPath: downloadsPath,
            baseUrl: editorDeCroqui.activeBaseUrl,
          )),
    );

    activeDataset.value = ConjuntoDadosCroqui(
      picosDisponiveis: currentAvailable,
      picosBaixados: ordenados,
    );
  }

  /// Auxiliar para compatibilidade legada ao atualizar metadados.
  Future<void> updatePicoMetadata(
    String id,
    Map<String, dynamic> picoData,
    String docsPath, {
    Croqui? parsedPico,
  }) async {
    final downloadsPath = editorDeCroqui.downloadsPath(docsPath);
    await extratorMetadados.atualizarMetadadosPico(
      id: id,
      picoData: picoData,
      downloadsPath: downloadsPath,
      baseUrl: editorDeCroqui.activeBaseUrl,
      parsedCroqui: parsedPico,
    );
  }

  /// Dispara a notificação de reset visual na página Home.
  void triggerHomeReset() {
    homeResetTrigger.value++;
  }
}
