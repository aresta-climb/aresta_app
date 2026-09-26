// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0
import '../../../aresta_api/proto/generated/croqui.pb.dart';
import '../../../widgets/provedor_imagem_aresta.dart';
import '../../dataset_repository.dart';
import '../../firebase/app_logger.dart';

/// Responsável por extrair caminhos de capas, processar seções markdown de croquis
/// e resolver mídias delegando centralizadamente ao [DatasetRepository] e [ProvedorImagemAresta].
class ExtratorMetadadosCroqui {
  /// Repositório de croquis opcional injetado.
  final DatasetRepository? repository;

  /// Cria uma instância do extrator com suporte a injeção de dependência.
  ExtratorMetadadosCroqui({this.repository});

  /// Carrega os dados do croqui e o caminho da imagem de capa para um [ResumoPico].
  ///
  /// Prioriza [parsedCroqui] caso já fornecido. Caso contrário, delega a resolução completa
  /// de quatro etapas (RAM, permanente, volátil e CDN remoto) exclusivamente ao
  /// [DatasetRepository.getCroqui] e a imagem de capa ao [ProvedorImagemAresta].
  Future<ResumoPico> carregarMetadadosLocais({
    required ResumoPico pico,
    required String downloadsPath,
    required String baseUrl,
    Croqui? parsedCroqui,
    DatasetRepository? repositoryOverride,
  }) async {
    try {
      Croqui? croqui = parsedCroqui;
      if (croqui == null) {
        final repo = repositoryOverride ?? repository ?? DatasetRepository.instance;
        croqui = await repo?.getCroqui(pico.id);
        if (croqui == null) {
          return pico;
        }
      }

      final capaPath = await _resolverCapaPath(
        croqui: croqui,
        url: pico.url,
        downloadsPath: downloadsPath,
        id: pico.id,
        baseUrl: baseUrl,
        datasetRepository: repositoryOverride ?? repository ?? DatasetRepository.instance,
      );

      return pico.copyWith(
        croqui: croqui,
        pico: croqui.picos.isNotEmpty ? croqui.picos.first : null,
        capaPath: capaPath,
      );
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Erro ao carregar metadados locais do pico ${pico.id}',
        error: e,
        stackTrace: stackTrace,
      );
      return pico;
    }
  }

  /// Atualiza o caminho da imagem de capa (`capaPath`) e o nó `data` dentro do mapa [picoData].
  /// Mantido para compatibilidade com fluxos existentes do catálogo.
  Future<void> atualizarMetadadosPico({
    required String id,
    required Map<String, dynamic> picoData,
    required String downloadsPath,
    required String baseUrl,
    Croqui? parsedCroqui,
    DatasetRepository? repositoryOverride,
  }) async {
    try {
      Croqui? croqui = parsedCroqui;
      if (croqui == null) {
        final repo = repositoryOverride ?? repository ?? DatasetRepository.instance;
        croqui = await repo?.getCroqui(id);
        if (croqui == null) return;
      }

      if (croqui.picos.isNotEmpty) {
        picoData['data'] = {'pico': croqui.picos.first, 'croqui': croqui};
      }

      final capaPath = await _resolverCapaPath(
        croqui: croqui,
        url: picoData['url']?.toString(),
        downloadsPath: downloadsPath,
        id: id,
        baseUrl: baseUrl,
        datasetRepository: repositoryOverride ?? repository ?? DatasetRepository.instance,
      );

      if (capaPath != null) {
        picoData['capaPath'] = capaPath;
      }
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Erro ao extrair metadados e capa do pico $id',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<String?> _resolverCapaPath({
    required Croqui croqui,
    required String? url,
    required String downloadsPath,
    required String id,
    required String baseUrl,
    DatasetRepository? datasetRepository,
  }) async {
    String baseDir = '';
    if (url != null && url.startsWith(baseUrl)) {
      String relative = url.substring(baseUrl.length);
      if (relative.startsWith('/')) relative = relative.substring(1);
      int lastSlash = relative.lastIndexOf('/');
      if (lastSlash != -1) {
        baseDir = relative.substring(0, lastSlash);
      }
    }

    String? capaPath;
    if (croqui.hasCaminhoThumbnail() && croqui.caminhoThumbnail.isNotEmpty) {
      capaPath = croqui.caminhoThumbnail;
    } else {
      capaPath = extrairCapaPathFromMarkdown(croqui, baseDir);
    }

    if (capaPath != null) {
      final arquivo = await ProvedorImagemAresta.preCarregarNoDisco(
        picoId: id,
        caminho: capaPath,
        baseUrl: baseUrl,
        caminhoDownloads: downloadsPath,
        datasetRepository: datasetRepository,
      );

      if (arquivo != null && await arquivo.exists()) {
        AppLogger.instance.logInfo(
          '[ExtratorMetadados] Imagem de capa encontrada para $id em: ${arquivo.path}',
        );
        return arquivo.path;
      }

      AppLogger.instance.logInfo(
        '[ExtratorMetadados] Imagem de capa NÃO encontrada para $id em: $capaPath',
      );
    }
    return null;
  }

  /// Extrai o caminho da primeira imagem encontrada em uma seção textual de botão intitulado "capa".
  String? extrairCapaPathFromMarkdown(Croqui croqui, String baseDir) {
    try {
      final capaBotao = croqui.botoes.firstWhere(
        (b) =>
            b.texto.toLowerCase().contains('capa') &&
            b.hasDestino() &&
            b.destino.hasSecaoTextual(),
        orElse: () => Botao(),
      );

      if (capaBotao.hasDestino() && capaBotao.destino.hasSecaoTextual()) {
        final capaMd = capaBotao.destino.secaoTextual;
        if (capaMd.hasConteudo() && capaMd.conteudo.isNotEmpty) {
          final RegExp regex = RegExp(r'!\[.*?\]\((.*?)\)');
          final match = regex.firstMatch(capaMd.conteudo);
          if (match != null && match.groupCount >= 1) {
            String path = match.group(1)!;
            if (!path.startsWith('http')) {
              if (path.startsWith('./')) path = path.substring(2);
              if (path.startsWith('/')) path = path.substring(1);
              if (baseDir.isNotEmpty) {
                if (!path.startsWith(baseDir)) {
                  return '$baseDir/$path';
                } else {
                  return path;
                }
              } else {
                return path;
              }
            }
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Erro ao extrair capa do markdown',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return null;
  }
}
