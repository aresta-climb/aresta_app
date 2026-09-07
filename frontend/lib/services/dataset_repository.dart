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
    AppLogger.instance.logInfo('[DatasetRepo] Modo alterado detectado. Recarregando índice...');
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

  /// Notificador reativo emitindo o nome ou identificador de um croqui online que acabou de ser atualizado para exibição na UI.
  final ValueNotifier<String?> notificadorCroquiAtualizado = ValueNotifier(null);

  /// Emite notificação para a interface exibir aviso amigável de que um croqui online foi atualizado.
  void notificarCroquiOnlineAtualizadoNaUI(String nomeOuId) {
    notificadorCroquiAtualizado.value = nomeOuId;
  }

  /// Notifica a interface do usuário e re-indexa mídias quando um croqui em sessão online é atualizado.
  ///
  /// Garante que novos hashes SHA-256 sejam conhecidos pelo provedor de imagem e que o
  /// [PageListenableBuilder] reconstrua as páginas ativas com a versão mais recente em memória.
  void notificarAtualizacaoSessaoOnline(String picoId) {
    final croquiOnline = gerenciadorSessaoOnline.obterCroquiOnline(picoId);
    if (croquiOnline != null) {
      indexarMidiasDoCroqui(picoId, croquiOnline);
    }
    if (activeDataset.value != null) {
      activeDataset.value = ConjuntoDadosCroqui(
        picosDisponiveis: activeDataset.value!.picosDisponiveis,
        picosBaixados: activeDataset.value!.picosBaixados,
      );
    }
  }

  /// Tabela de dispersão interna indexando caminhos de mídias por pico: [picoId] -> {[caminho] -> [checksumSha256]}.
  final Map<String, Map<String, String>> _tabelaSha256PorPico = {};

  /// Indexa os arquivos externos de um [Croqui] para consultas O(1) de checksum SHA-256.
  void indexarMidiasDoCroqui(String picoId, Croqui croqui) {
    if (picoId.isEmpty) return;
    final mapaPico = _tabelaSha256PorPico.putIfAbsent(picoId, () => {});
    for (final ext in croqui.arquivosExternos) {
      if (ext.hasChecksumSha256() && ext.checksumSha256.isNotEmpty) {
        String limpo = ext.caminho.trim().replaceAll(r'\', '/');
        while (limpo.startsWith('./')) {
          limpo = limpo.substring(2);
        }
        while (limpo.startsWith('/')) {
          limpo = limpo.substring(1);
        }
        mapaPico[limpo] = ext.checksumSha256;
        mapaPico[ext.caminho] = ext.checksumSha256;
        mapaPico['./$limpo'] = ext.checksumSha256;
        mapaPico['/$limpo'] = ext.checksumSha256;
        final barraInvertida = limpo.replaceAll('/', r'\');
        mapaPico[barraInvertida] = ext.checksumSha256;
        mapaPico[r'.\' + barraInvertida] = ext.checksumSha256;

        final nomeArquivo = limpo.split('/').last;
        if (nomeArquivo.isNotEmpty) {
          mapaPico[nomeArquivo] = ext.checksumSha256;
        }
      }
    }
  }

  /// Retorna o checksum SHA-256 pré-indexado O(1) para uma mídia de croqui ou thumbnail.
  ///
  /// Caso o pico esteja em uma sessão online ativa e ainda não indexado,
  /// o croqui online é consultado e indexado dinamicamente.
  String? obterSha256DaMidia(String picoId, String caminho) {
    if (picoId.isEmpty || caminho.isEmpty) return null;

    final mapaPico = _tabelaSha256PorPico[picoId];
    String caminhoLimpo = caminho.trim().replaceAll(r'\', '/');
    while (caminhoLimpo.startsWith('./')) {
      caminhoLimpo = caminhoLimpo.substring(2);
    }
    while (caminhoLimpo.startsWith('/')) {
      caminhoLimpo = caminhoLimpo.substring(1);
    }

    if (mapaPico != null) {
      if (mapaPico.containsKey(caminhoLimpo)) {
        return mapaPico[caminhoLimpo];
      }
      final nomeArquivo = caminhoLimpo.split('/').last;
      if (nomeArquivo.isNotEmpty && mapaPico.containsKey(nomeArquivo)) {
        return mapaPico[nomeArquivo];
      }
    }

    // Fallback: Consulta o índice em memória para thumbnails
    final indice = indiceData.value;
    if (indice != null) {
      for (final r in indice.croquis) {
        if (r.id == picoId &&
            r.hasChecksumSha256Thumbnail() &&
            r.checksumSha256Thumbnail.isNotEmpty) {
          final thumbHash = r.checksumSha256Thumbnail;
          final mapa = _tabelaSha256PorPico.putIfAbsent(picoId, () => {});
          mapa['thumbnails/$picoId.webp'] = thumbHash;
          mapa['$picoId.webp'] = thumbHash;
          mapa['thumbnail.webp'] = thumbHash;

          if (caminhoLimpo.contains('thumbnail') ||
              caminhoLimpo.endsWith('$picoId.webp')) {
            return thumbHash;
          }
        }
      }
    }

    // Fallback: Sessão online ativa
    final croquiOnline = gerenciadorSessaoOnline.obterCroquiOnline(picoId);
    if (croquiOnline != null) {
      indexarMidiasDoCroqui(picoId, croquiOnline);
      final mapaOnline = _tabelaSha256PorPico[picoId];
      if (mapaOnline != null) {
        if (mapaOnline.containsKey(caminhoLimpo)) {
          return mapaOnline[caminhoLimpo];
        }
        final nomeArquivo = caminhoLimpo.split('/').last;
        if (nomeArquivo.isNotEmpty && mapaOnline.containsKey(nomeArquivo)) {
          return mapaOnline[nomeArquivo];
        }
      }
    }

    return null;
  }

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
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '[DatasetRepo] Erro na inicialização',
        error: e,
        stackTrace: stackTrace,
      );
      loadEmpty();
    }
  }

  /// Converte os resumos de [Indice] em estruturas mapeadas para a interface.
  Future<void> loadIndiceToMemory(Indice indice) async {
    indiceData.value = indice;
    for (var resumo in indice.croquis) {
      if (resumo.hasChecksumSha256Thumbnail() &&
          resumo.checksumSha256Thumbnail.isNotEmpty) {
        final mapaPico = _tabelaSha256PorPico.putIfAbsent(resumo.id, () => {});
        final thumbHash = resumo.checksumSha256Thumbnail;
        mapaPico['thumbnails/${resumo.id}.webp'] = thumbHash;
        mapaPico['${resumo.id}.webp'] = thumbHash;
        mapaPico['thumbnail.webp'] = thumbHash;
      }
    }
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
          if (resumo.hasPrecomputados() &&
              resumo.precomputados.hasTamanhoDownloadBytes()) {
            tamanhoBytes = resumo.precomputados.tamanhoDownloadBytes.toInt();
          }

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
        } catch (itemEx, stackTrace) {
          AppLogger.instance.logError(
            'Erro ao processar pico individual ${resumo.id}',
            error: itemEx,
            stackTrace: stackTrace,
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
          } catch (e, stackTrace) {
            AppLogger.instance.logError(
              'Erro ao atualizar metadados do pico ${picoData['id']}',
              error: e,
              stackTrace: stackTrace,
            );
          }
        }),
      );

      for (final picoData in ordenados) {
        final croqui = picoData['data']?['croqui'];
        if (croqui is Croqui) {
          indexarMidiasDoCroqui(picoData['id'] as String, croqui);
        }
      }

      activeDataset.value = ConjuntoDadosCroqui(
        picosDisponiveis: parsedPicos,
        picosBaixados: ordenados,
      );

    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Erro crítico em loadIndiceToMemory',
        error: e,
        stackTrace: stackTrace,
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
    gerenciadorSessaoOnline.removerSessao(id);
    await _refreshActiveDataset();
  }

  /// Retorna se o pico com [picoId] está baixado no armazenamento local.
  bool isPicoDownloaded(String picoId) {
    return activeDataset.value?.picosBaixados.any((p) => p['id'] == picoId) ?? false;
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
      indexarMidiasDoCroqui(id, localCroqui);
      return localCroqui;
    }

    // 2. Se não estiver no disco permanente, consulta a sessão online ativa
    final online = gerenciadorSessaoOnline.obterCroquiOnline(id);
    if (online != null) {
      indexarMidiasDoCroqui(id, online);
    }
    return online;
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
