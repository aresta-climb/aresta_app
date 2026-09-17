// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../services/dataset_repository.dart';
import '../services/editor_croqui.dart';
import '../services/firebase/app_logger.dart';
import '../services/firebase/remote_config_service.dart';
import 'imagem_arquivo_aresta.dart';

/// Provedor unificado e em camadas para resolução de imagens do ecossistema Aresta.
///
/// Ordem de precedência:
/// 1. Armazenamento local permanente (`/downloads/<picoId>/...` ou `$docsDir/thumbnails/...`)
/// 2. Cache temporário volátil do sistema operacional (`/temp_cache/<picoId>/<caminho>.<hash>`)
/// 3. Streaming remoto da CDN HTTP com gravação atômica em disco temporário.
class ProvedorImagemAresta {
  const ProvedorImagemAresta._();

  /// Registro em memória de downloads ativos para evitar requisições redundantes simultâneas.
  static final Map<String, Future<ImageProvider?>> _downloadsEmAndamento = {};

  /// Resolve e entrega a instância de [ImageProvider] apropriada para a mídia indicada.
  ///
  /// O [checksumSha256] é opcional; quando omitido ou nulo, o provedor tenta
  /// auto-resolvê-lo consultando a tabela de dispersão do [DatasetRepository].
  ///
  /// Se [larguraAlvo] ou [alturaAlvo] forem especificados, o [ImageProvider] resultante
  /// será encapsulado por um [ResizeImage] via [ResizeImage.resizeIfNeeded] para garantir
  /// que a decodificação do bitmap na memória RAM seja otimizada e caiba no orçamento de memória.
  static Future<ImageProvider?> resolver({
    required String picoId,
    required String caminho,
    String? checksumSha256,
    String? baseUrl,
    String? caminhoDownloads,
    String? caminhoCacheVolatil,
    DatasetRepository? datasetRepository,
    http.Client? clienteHttp,
    int? larguraAlvo,
    int? alturaAlvo,
  }) async {
    try {
      if (picoId.trim().isEmpty || caminho.trim().isEmpty) return null;

      ImageProvider? provedorBase;

      String cleanPath = caminho.trim().replaceAll(r'\', '/');
      final uriCaminho = Uri.tryParse(cleanPath);
      final pathSemQuery = (uriCaminho != null && uriCaminho.path.isNotEmpty)
          ? uriCaminho.path
          : cleanPath;

      // Identifica se a mídia solicitada é uma miniatura (thumbnail) do pico, aceitando
      // rotas canônicas (thumbnails/<picoId>.webp) ou legadas (/imagens/thumbnail.webp).
      final bool ehThumbnail = cleanPath.startsWith('thumbnails/') ||
          cleanPath.contains('/thumbnails/') ||
          pathSemQuery.endsWith('/thumbnail.webp') ||
          pathSemQuery == 'thumbnail.webp' ||
          pathSemQuery.endsWith('/$picoId.webp') ||
          pathSemQuery == '$picoId.webp' ||
          (picoId.isNotEmpty && pathSemQuery.contains('thumbnail'));

      if (ehThumbnail) {
        cleanPath = 'thumbnails/$picoId.webp';
      } else {
        while (cleanPath.startsWith('./')) {
          cleanPath = cleanPath.substring(2);
        }
        while (cleanPath.startsWith('/')) {
          cleanPath = cleanPath.substring(1);
        }
      }

      // Auto-resolução do checksum SHA-256 via parâmetro de URL ou DatasetRepository se não fornecido
      String? hashEfetivo = checksumSha256;
      if (hashEfetivo == null || hashEfetivo.isEmpty) {
        if (uriCaminho != null && uriCaminho.queryParameters.containsKey('v')) {
          final v = uriCaminho.queryParameters['v'];
          if (v != null && v.isNotEmpty) {
            hashEfetivo = v;
          }
        }
      }

      if (hashEfetivo == null || hashEfetivo.isEmpty) {
        try {
          final repo = datasetRepository ?? DatasetRepository.instance;
          if (repo != null) {
            hashEfetivo = repo.obterSha256DaMidia(picoId, cleanPath);
            if (hashEfetivo == null && ehThumbnail) {
              hashEfetivo = repo.obterSha256DaMidia(picoId, 'thumbnails/$picoId.webp');
            }
          }
        } catch (_) {}
      }

      // 1. Armazenamento Local Permanente (/downloads ou thumbnails permanentes)
      String downloadsRoot = caminhoDownloads ?? '';
      String docsDirPath = '';
      if (downloadsRoot.isEmpty) {
        final docsDir = await getApplicationDocumentsDirectory();
        docsDirPath = docsDir.path;
        final editor = EditorDeCroqui.instance;
        downloadsRoot = editor.downloadsPath(docsDir.path);
      } else {
        docsDirPath = downloadsRoot;
      }

      if (ehThumbnail) {
        final thumbDocs = File('$docsDirPath/thumbnails/$picoId.webp');
        if (thumbDocs.existsSync()) {
          provedorBase = ImagemArquivoAresta(thumbDocs, checksumSha256: hashEfetivo);
        } else {
          final thumbDownloads = File('$downloadsRoot/thumbnails/$picoId.webp');
          if (thumbDownloads.existsSync()) {
            provedorBase = ImagemArquivoAresta(thumbDownloads, checksumSha256: hashEfetivo);
          }
        }
      }

      final downloadsPicoPath = '$downloadsRoot/$picoId';
      if (provedorBase == null) {
        File? localFile = _buscarArquivoNoDiretorio(downloadsPicoPath, caminho);
        if (localFile != null && localFile.existsSync()) {
          provedorBase = ImagemArquivoAresta(localFile, checksumSha256: hashEfetivo);
        }
      }

      // 2. Cache Temporário Volátil (/temp_cache)
      String cacheRoot = caminhoCacheVolatil ?? '';
      if (cacheRoot.isEmpty) {
        final tempDir = await getTemporaryDirectory();
        cacheRoot = '${tempDir.path}/temp_cache';
      }

      String caminhoLocalCache = cleanPath;
      if (caminhoLocalCache.startsWith('http://') || caminhoLocalCache.startsWith('https://')) {
        final uri = Uri.tryParse(caminhoLocalCache);
        if (uri != null) {
          caminhoLocalCache = uri.path;
          while (caminhoLocalCache.startsWith('/')) {
            caminhoLocalCache = caminhoLocalCache.substring(1);
          }
        }
      }

      final String caminhoDestinoCache = ehThumbnail
          ? '$cacheRoot/thumbnails/$picoId.webp${hashEfetivo != null && hashEfetivo.isNotEmpty ? '.$hashEfetivo' : ''}'
          : '$cacheRoot/$picoId/$caminhoLocalCache${hashEfetivo != null && hashEfetivo.isNotEmpty ? '.$hashEfetivo' : ''}';

      if (provedorBase == null) {
        if (hashEfetivo != null && hashEfetivo.isNotEmpty) {
          final arquivoCacheHash = File(caminhoDestinoCache);
          if (arquivoCacheHash.existsSync()) {
            provedorBase = ImagemArquivoAresta(arquivoCacheHash, checksumSha256: hashEfetivo);
          }
        }

        if (provedorBase == null) {
          final cachePicoPath = '$cacheRoot/$picoId';
          File? cacheFile = _buscarArquivoNoDiretorio(cachePicoPath, caminho);
          if (cacheFile != null && cacheFile.existsSync()) {
            provedorBase = ImagemArquivoAresta(cacheFile, checksumSha256: hashEfetivo);
          }
        }
      }

      // 3. Streaming Remoto / CDN com Gravação Atômica no Cache Volátil
      if (provedorBase == null) {
        String serverBase = baseUrl ?? '';
        if (serverBase.isEmpty) {
          if (caminho.startsWith('http://') || caminho.startsWith('https://')) {
            final uri = Uri.tryParse(caminho);
            if (uri != null) {
              final segments = uri.pathSegments;
              if (segments.isNotEmpty && segments.first.startsWith('v')) {
                serverBase = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}/${segments.first}';
              } else {
                serverBase = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
              }
            }
          }
          if (serverBase.isEmpty) {
            try {
              serverBase = EditorDeCroqui.instance.activeBaseUrl;
            } catch (_) {
              serverBase = RemoteConfigService.instance.officialServerUrl;
            }
          }
        }

        String urlFinal;
        if (ehThumbnail) {
          // Garante rota canônica na CDN (/thumbnails/<picoId>.webp)
          urlFinal = '$serverBase/thumbnails/$picoId.webp';
        } else if (caminho.startsWith('http://') || caminho.startsWith('https://')) {
          urlFinal = caminho;
        } else {
          String remotePath = cleanPath;
          String baseDir = _obterBaseDirDoIndice(picoId);
          if (baseDir.isNotEmpty &&
              !remotePath.startsWith(baseDir) &&
              !remotePath.startsWith('picos/')) {
            remotePath = '$baseDir/$cleanPath';
          }
          urlFinal = '$serverBase/$remotePath';
        }

        // Se o hash for ausente ou nulo, recorre ao NetworkImage sem persistir em disco
        if (hashEfetivo == null || hashEfetivo.isEmpty) {
          AppLogger.instance.logError(
            'Checksum SHA-256 ausente ou nulo para mídia remota $picoId em $caminho. Recorrendo a NetworkImage sem cache volátil.',
            stackTrace: StackTrace.current,
          );
          provedorBase = NetworkImage(urlFinal);
        } else {
          final uri = Uri.parse(urlFinal);
          final queryParams = Map<String, String>.from(uri.queryParameters);
          queryParams['v'] = hashEfetivo;
          urlFinal = uri.replace(queryParameters: queryParams).toString();

          final chaveDownload = caminhoDestinoCache;
          if (_downloadsEmAndamento.containsKey(chaveDownload)) {
            provedorBase = await _downloadsEmAndamento[chaveDownload];
          } else {
            final futureDownload = _baixarESalvarNoCache(
              urlFinal: urlFinal,
              caminhoDestino: caminhoDestinoCache,
              hashEsperado: hashEfetivo,
              clienteHttp: clienteHttp,
            );
            _downloadsEmAndamento[chaveDownload] = futureDownload;
            try {
              provedorBase = await futureDownload;
            } finally {
              _downloadsEmAndamento.remove(chaveDownload);
            }
          }
        }
      }

      if (provedorBase != null && (larguraAlvo != null || alturaAlvo != null)) {
        return ResizeImage.resizeIfNeeded(larguraAlvo, alturaAlvo, provedorBase);
      }

      return provedorBase;
    } catch (e, stackTrace) {
      if (AppLogger.isFalhaConexaoOuTimeout(e)) {
        AppLogger.instance.logAviso(
          'Falha de conexão ao resolver provedor de imagem para $picoId em $caminho: $e',
        );
      } else {
        AppLogger.instance.logError(
          'Erro ao resolver provedor de imagem para $picoId em $caminho',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
    return null;
  }

  /// Pré-carrega uma imagem diretamente para o armazenamento local ou cache em disco (`temp_cache`),
  /// sem decodificar o bitmap para a memória RAM e sem registrá-la no [ImageCache] do Flutter.
  ///
  /// Possui três propriedades garantidas:
  /// 1. **Idempotente**: Se o arquivo já existe no disco (`/downloads` ou `/temp_cache`), retorna
  ///    o [File] imediatamente sem nenhuma requisição de rede.
  /// 2. **Deduplicado**: Aproveita o mapa interno [_downloadsEmAndamento] para reutilizar conexões HTTP
  ///    ativas caso múltiplas rotinas solicitem a mesma mídia simultaneamente.
  /// 3. **Leve**: Grava os bytes compactados brutos diretamente no disco via I/O de arquivo. Não chama
  ///    `precacheImage`, não cria texturas e não consome memória de vídeo ou processamento de GPU.
  ///
  /// Retorna a referência ao [File] salvo em disco em caso de sucesso, ou `null` se houver falha
  /// de conexão ou dados inválidos.
  static Future<File?> preCarregarNoDisco({
    required String picoId,
    required String caminho,
    String? checksumSha256,
    String? baseUrl,
    String? caminhoDownloads,
    String? caminhoCacheVolatil,
    DatasetRepository? datasetRepository,
    http.Client? clienteHttp,
  }) async {
    if (picoId.trim().isEmpty || caminho.trim().isEmpty) return null;

    final provedor = await resolver(
      picoId: picoId,
      caminho: caminho,
      checksumSha256: checksumSha256,
      baseUrl: baseUrl,
      caminhoDownloads: caminhoDownloads,
      caminhoCacheVolatil: caminhoCacheVolatil,
      datasetRepository: datasetRepository,
      clienteHttp: clienteHttp,
    );

    if (provedor is ImagemArquivoAresta) {
      return provedor.arquivo;
    } else if (provedor is FileImage) {
      return provedor.file;
    }
    return null;
  }

  /// Realiza o download atômico da imagem remota e persiste no cache volátil.
  static Future<ImageProvider?> _baixarESalvarNoCache({
    required String urlFinal,
    required String caminhoDestino,
    required String hashEsperado,
    http.Client? clienteHttp,
  }) async {
    final client = clienteHttp ?? http.Client();
    final bool deveFecharCliente = clienteHttp == null;
    try {
      final response = await client.get(Uri.parse(urlFinal));
      if (response.statusCode == 200) {
        final arquivoDestino = File(caminhoDestino);
        await arquivoDestino.parent.create(recursive: true);
        final arquivoTmp = File('$caminhoDestino.tmp');
        await arquivoTmp.writeAsBytes(response.bodyBytes, flush: true);
        await arquivoTmp.rename(caminhoDestino);

        // Expurga versões anteriores do mesmo arquivo com hashes divergentes
        _expurgarVersoesAntigas(caminhoDestino);

        return ImagemArquivoAresta(File(caminhoDestino), checksumSha256: hashEsperado);
      } else {
        AppLogger.instance.logAviso('HTTP ${response.statusCode} ao baixar imagem $urlFinal');
      }
    } catch (e, stackTrace) {
      if (AppLogger.isFalhaConexaoOuTimeout(e)) {
        AppLogger.instance.logAviso(
          'Falha de conexão ao baixar e persistir imagem em cache volátil: $urlFinal ($e)',
        );
      } else {
        AppLogger.instance.logError(
          'Falha ao baixar e persistir imagem em cache volátil: $urlFinal',
          error: e,
          stackTrace: stackTrace,
        );
      }
    } finally {
      if (deveFecharCliente) {
        client.close();
      }
    }
    return null;
  }

  /// Expurga arquivos de versões anteriores da mesma mídia que possuam hashes divergentes.
  ///
  /// No cache volátil (`temp_cache`), os arquivos seguem o padrão `<nome_original>.<hash>`,
  /// como por exemplo `capa.png.a1b2c3d4` ou `pico_baú.webp.e5f6g7h8`.
  /// Quando uma nova versão da mesma mídia é baixada com um novo hash, esta rotina localiza
  /// e deleta do mesmo diretório quaisquer arquivos irmãos que possuam o mesmo `<nome_original>`
  /// mas com hash anterior divergente, prevenindo o acúmulo desnecessário de cache em disco.
  static void _expurgarVersoesAntigas(String caminhoArquivoSalvo) {
    try {
      final arquivoRecemSalvo = File(caminhoArquivoSalvo);
      final diretorioPai = arquivoRecemSalvo.parent;
      if (!diretorioPai.existsSync()) return;

      // Extrai o nome do arquivo recém-salvo (ex: "capa.png.novoHash123")
      final nomeArquivoRecemSalvo =
          arquivoRecemSalvo.path.replaceAll(r'\', '/').split('/').last;

      // O último ponto separa o nome original da mídia do hash anexado
      // Exemplo: "capa.png.novoHash123" -> nomeOriginal: "capa.png"
      final indiceUltimoPonto = nomeArquivoRecemSalvo.lastIndexOf('.');
      if (indiceUltimoPonto == -1) return;

      final nomeOriginalDaMidia =
          nomeArquivoRecemSalvo.substring(0, indiceUltimoPonto);
      final prefixoVersoesIrmas = '$nomeOriginalDaMidia.';

      // Varre o diretório pai procurando arquivos da mesma mídia com hashes antigos
      for (final entidade in diretorioPai.listSync()) {
        if (entidade is! File) continue;

        final nomeArquivoIrmao =
            entidade.path.replaceAll(r'\', '/').split('/').last;

        final ehMesmaMidia = nomeArquivoIrmao.startsWith(prefixoVersoesIrmas);
        final ehVersaoDiferente = nomeArquivoIrmao != nomeArquivoRecemSalvo;

        if (ehMesmaMidia && ehVersaoDiferente) {
          try {
            entidade.deleteSync();
          } catch (e) {
            AppLogger.instance.logAviso(
              'Falha ao deletar versão antiga de imagem em cache (${entidade.path}): $e',
            );
          }
        }
      }
    } catch (e) {
      AppLogger.instance.logAviso(
        'Erro ao expurgar versões antigas para ($caminhoArquivoSalvo): $e',
      );
    }
  }


  /// Recupera o diretório base do pico a partir do índice carregado em memória.
  static String _obterBaseDirDoIndice(String picoId) {
    try {
      final repo = DatasetRepository.instance;
      if (repo != null) {
        final indice = repo.indiceData.value;
        if (indice != null) {
          final match = indice.croquis.where((r) => r.id == picoId);
          if (match.isNotEmpty) {
            final caminhoRelativo = match.first.caminhoRelativo;
            final lastSlash = caminhoRelativo.lastIndexOf('/');
            if (lastSlash != -1) {
              return caminhoRelativo.substring(0, lastSlash);
            }
          }
        }
      }
    } catch (_) {}
    return 'picos/$picoId';
  }

  /// Busca um arquivo em um diretório através de caminho direto ou busca recursiva.
  static File? _buscarArquivoNoDiretorio(String rootDir, String path) {
    if (!Directory(rootDir).existsSync()) return null;

    final baseUrl = '${RemoteConfigService.instance.officialServerUrl}/';
    String cleanUrl = Uri.decodeFull(path);
    if (cleanUrl.startsWith(baseUrl)) {
      final relativePath = cleanUrl.replaceFirst(baseUrl, '');
      final directFile = File('$rootDir/$relativePath');
      if (directFile.existsSync()) return directFile;
    }

    String cleanPath = path.trim().replaceAll(r'\', '/');
    while (cleanPath.startsWith('./')) {
      cleanPath = cleanPath.substring(2);
    }
    while (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }
    final directFile = File('$rootDir/$cleanPath');
    if (directFile.existsSync()) return directFile;

    String fileName = cleanPath.split('/').last;
    if (fileName.isNotEmpty) {
      final searchName = Uri.decodeComponent(fileName).toLowerCase();
      String searchBaseName = searchName.contains('.')
          ? searchName.substring(0, searchName.lastIndexOf('.'))
          : searchName;

      try {
        final dir = Directory(rootDir);
        final entities = dir.listSync(recursive: true);
        for (var entity in entities) {
          if (entity is File) {
            final String ePath = entity.path.replaceAll('\\', '/');
            final String eName = ePath.split('/').last;
            final String eNameLower = Uri.decodeComponent(eName).toLowerCase();

            if (eNameLower == searchName) return entity;

            String eBaseName = eNameLower.contains('.')
                ? eNameLower.substring(0, eNameLower.lastIndexOf('.'))
                : eNameLower;

            if (eBaseName == searchBaseName) return entity;
          }
        }
      } catch (_) {}
    }
    return null;
  }
}
