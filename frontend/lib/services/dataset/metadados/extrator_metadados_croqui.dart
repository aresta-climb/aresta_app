// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import '../../../aresta_api/proto/generated/croqui.pb.dart';
import '../../firebase/app_logger.dart';

/// Responsável por extrair caminhos de capas, processar seções markdown de croquis
/// e resolver recursivamente arquivos de imagem no sistema de arquivos.
class ExtratorMetadadosCroqui {
  /// Atualiza o caminho da imagem de capa (`capaPath`) e o nó `data` dentro do mapa [picoData].
  Future<void> atualizarMetadadosPico({
    required String id,
    required Map<String, dynamic> picoData,
    required String downloadsPath,
    required String baseUrl,
    Croqui? parsedCroqui,
  }) async {
    try {
      Croqui croqui;
      if (parsedCroqui != null) {
        croqui = parsedCroqui;
      } else {
        final picoFile = File('$downloadsPath/$id/$id.binarypb');
        if (!picoFile.existsSync()) {
          return;
        }
        croqui = Croqui.fromBuffer(await picoFile.readAsBytes());
      }

      if (croqui.picos.isNotEmpty) {
        picoData['data'] = {'pico': croqui.picos.first, 'croqui': croqui};
      }

      String baseDir = '';
      final String? url = picoData['url'];
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
        String fullPath = '$downloadsPath/$id/$capaPath';
        File imgFile = File(fullPath);

        if (!imgFile.existsSync()) {
          if (capaPath.contains('/')) {
            final fileName = capaPath.split('/').last;
            final directFile = File('$downloadsPath/$id/$fileName');
            if (directFile.existsSync()) {
              imgFile = directFile;
            } else {
              final File? foundFile = buscarImagemRecursivamente(
                '$downloadsPath/$id',
                fileName,
              );
              if (foundFile != null) {
                imgFile = foundFile;
              }
            }
          } else {
            final File? foundFile = buscarImagemRecursivamente(
              '$downloadsPath/$id',
              capaPath,
            );
            if (foundFile != null) {
              imgFile = foundFile;
            }
          }
        }

        if (imgFile.existsSync()) {
          AppLogger.instance.logInfo(
            '[ExtratorMetadados] Imagem de capa encontrada para $id em: ${imgFile.path}',
          );
          picoData['capaPath'] = imgFile.path;
        } else {
          AppLogger.instance.logInfo(
            '[ExtratorMetadados] Imagem de capa NÃO encontrada para $id em: $fullPath',
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Erro ao extrair metadados e capa do pico $id',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Busca uma imagem recursivamente dentro de um diretório ignorando case e sufixos de extensão.
  File? buscarImagemRecursivamente(String rootPath, String fileName) {
    try {
      final dir = Directory(rootPath);
      if (!dir.existsSync()) return null;

      final searchName = Uri.decodeComponent(fileName).toLowerCase();
      String searchBaseName = searchName;
      if (searchName.contains('.')) {
        searchBaseName = searchName.substring(0, searchName.lastIndexOf('.'));
      }

      final entities = dir.listSync(recursive: true);
      for (var entity in entities) {
        if (entity is File) {
          final String ePath = entity.path.replaceAll('\\', '/');
          final String eName = ePath.split('/').last;
          final String eNameLower = Uri.decodeComponent(eName).toLowerCase();

          if (eNameLower == searchName) return entity;

          String eBaseName = eNameLower;
          if (eNameLower.contains('.')) {
            eBaseName = eNameLower.substring(0, eNameLower.lastIndexOf('.'));
          }

          if (eBaseName == searchBaseName) return entity;
        }
      }
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Erro na busca recursiva de imagem',
        error: e,
        stackTrace: stackTrace,
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
