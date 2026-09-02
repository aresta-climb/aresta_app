// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../aresta_api/proto/generated/indice.pb.dart';
import 'sync_storage.dart';

/// Argumentos necessários para instanciar o [downloadIsolateMain].
///
/// Como Isolates não compartilham memória com a Main Isolate (Thread da UI),
/// todos os dados de configuração e a porta de comunicação de mão única
/// ([SendPort]) precisam ser empacotados e serializados nesta classe de entrada.
class DownloadIsolateArgs {
  final Uint8List newResumoBytes;
  final String downloadsDirPath;
  final String baseUrl;
  final SendPort sendPort;
  final Duration timeoutDuration;

  DownloadIsolateArgs({
    required this.newResumoBytes,
    required this.downloadsDirPath,
    required this.baseUrl,
    required this.sendPort,
    this.timeoutDuration = const Duration(seconds: 15),
  });
}

/// Resultado final do processamento empacotado que o Isolate envia para a Main Thread.
///
/// Contém o resumo das operações físicas (arquivos deletados e temporários a renomear)
/// e o novo buffer de dados que o Dart (Main Isolate) usará para atualizar
/// a memória do aplicativo de forma atômica e segura.
class DownloadIsolateResult {
  final List<String> filesToDelete;
  final Map<String, String> filesToRename;
  final Uint8List? newPicoDataBytes;
  final String? error;

  DownloadIsolateResult({
    required this.filesToDelete,
    required this.filesToRename,
    this.newPicoDataBytes,
    this.error,
  });
}

/// Ponto de entrada (Entrypoint) estático para o Isolate de download em background.
///
/// Esta função roda em uma thread computacional apartada (Background Isolate),
/// totalmente isolada do Event Loop principal (Main Isolate) onde a UI funciona.
///
/// **Fluxo de Trabalho**:
/// 1. Baixa o arquivo principal (`.binarypb`) como um `.tmp` e valida o seu Hash.
/// 2. Lê os arquivos antigos e novos para definir um Diff (arquivos a deletar vs a baixar).
/// 3. Inicia downloads atômicos dos arquivos de mídia (`.tmp`) paralelamente.
/// 4. Emite mensagens do tipo [double] periodicamente via `args.sendPort` com o progresso de 0.0 a 1.0.
/// 5. Ao finalizar (ou falhar), envia um objeto [DownloadIsolateResult] de volta à Thread principal.
///
/// **Ausência de Race Conditions**:
/// Como este método apenas baixa para `.tmp` e não faz o `rename` dos arquivos originais,
/// ele nunca interfere na leitura em disco que o App possa estar fazendo na Thread principal.
Future<void> downloadIsolateMain(DownloadIsolateArgs args) async {
  final client = http.Client();
  try {
    final storage = SyncStorage();
    final newResumo = ResumoCroqui.fromBuffer(args.newResumoBytes);
    final id = newResumo.id;
    final url = '${args.baseUrl}/${newResumo.caminhoRelativo}';
    final picoDirPath = '${args.downloadsDirPath}/$id';
    final picoFilePath = '$picoDirPath/$id.binarypb';
    final tmpPicoFilePath = '$picoDirPath/$id.binarypb.tmp';

    // Helper for atomic download
    Future<bool> downloadAtomic(
      String fileUrl,
      String tmpPath,
      String expectedHash,
    ) async {
      try {
        final isTmpValid = await storage.validateExistingTmpFile(
          tmpPath,
          expectedHash,
        );
        if (isTmpValid) return true;
        final cacheBustingUrl = fileUrl.contains('?')
            ? '$fileUrl&v=$expectedHash'
            : '$fileUrl?v=$expectedHash';
        final response = await client
            .get(Uri.parse(cacheBustingUrl))
            .timeout(args.timeoutDuration);
        if (response.statusCode != 200) return false;
        await storage.saveTmpFile(tmpPath, response.bodyBytes);
        return await storage.validateExistingTmpFile(tmpPath, expectedHash);
      } catch (_) {
        return false;
      }
    }

    // Progresso inicial de 5% para início do download do arquivo principal
    args.sendPort.send(0.05);

    final mainFileSuccess = await downloadAtomic(
      url,
      tmpPicoFilePath,
      newResumo.checksumSha256Croqui,
    );
    if (!mainFileSuccess) {
      args.sendPort.send(
        DownloadIsolateResult(
          filesToDelete: [],
          filesToRename: {},
          error: 'Falha ao baixar binarypb de $url',
        ),
      );
      return;
    }

    final newPicoData = await storage.readLocalCroqui(tmpPicoFilePath);
    if (newPicoData == null) {
      args.sendPort.send(
        DownloadIsolateResult(
          filesToDelete: [],
          filesToRename: {},
          error: 'Falha ao ler novo binarypb',
        ),
      );
      return;
    }

    final oldPicoData = await storage.readLocalCroqui(picoFilePath);

    final newContent = {
      for (var ext in newPicoData.arquivosExternos)
        ext.caminho: ext.checksumSha256,
    };
    final oldContent = oldPicoData != null
        ? {
            for (var ext in oldPicoData.arquivosExternos)
              ext.caminho: ext.checksumSha256,
          }
        : <String, String>{};

    final List<String> filesToDelete = [];
    if (oldPicoData != null) {
      for (var oldExt in oldPicoData.arquivosExternos) {
        if (!newContent.containsKey(oldExt.caminho)) {
          filesToDelete.add('$picoDirPath/${oldExt.caminho}');
        }
      }
    } else {
      final dir = Directory(picoDirPath);
      if (await dir.exists()) {
        await for (var entity in dir.list(recursive: true)) {
          if (entity is File) {
            final filePath = entity.path;
            if (filePath.endsWith('.binarypb') ||
                filePath.endsWith('.binarypb.tmp')) {
              continue;
            }
            bool isNeeded = false;
            for (var key in newContent.keys) {
              if (filePath
                  .replaceAll('\\', '/')
                  .endsWith(key.replaceAll('\\', '/'))) {
                isNeeded = true;
                break;
              }
            }
            if (!isNeeded) filesToDelete.add(filePath);
          }
        }
      }
    }

    final baseDir = newResumo.caminhoRelativo.lastIndexOf('/') != -1
        ? newResumo.caminhoRelativo.substring(
            0,
            newResumo.caminhoRelativo.lastIndexOf('/'),
          )
        : '';

    final Map<String, String> filesToRename = {};
    filesToRename[tmpPicoFilePath] = picoFilePath;

    final int totalFiles = newPicoData.arquivosExternos.length;
    int processedFiles = 0;

    if (totalFiles == 0) {
      args.sendPort.send(1.0);
    }

    final List<Future<bool>> downloadFutures = [];
    for (var newExt in newPicoData.arquivosExternos) {
      String localPath = newExt.caminho;
      if (localPath.startsWith('/')) localPath = localPath.substring(1);

      bool needsDownload = false;
      if (oldContent.containsKey(newExt.caminho)) {
        needsDownload = oldContent[newExt.caminho] != newExt.checksumSha256;
      } else {
        final existingFileValid = await storage.validateExistingTmpFile(
          '$picoDirPath/$localPath',
          newExt.checksumSha256,
        );
        needsDownload = !existingFileValid;
      }

      if (needsDownload) {
        String remotePath =
            (baseDir.isNotEmpty && !localPath.startsWith(baseDir))
            ? '$baseDir/$localPath'
            : localPath;
        downloadFutures.add(
          downloadAtomic(
            '${args.baseUrl}/$remotePath',
            '$picoDirPath/$localPath.tmp',
            newExt.checksumSha256,
          ).then((success) {
            if (success) {
              filesToRename['$picoDirPath/$localPath.tmp'] =
                  '$picoDirPath/$localPath';
            }
            processedFiles++;
            args.sendPort.send(0.05 + (0.95 * (processedFiles / totalFiles)));
            return success;
          }).catchError((_) {
            processedFiles++;
            args.sendPort.send(0.05 + (0.95 * (processedFiles / totalFiles)));
            return false;
          }),
        );
      } else {
        processedFiles++;
        args.sendPort.send(0.05 + (0.95 * (processedFiles / totalFiles)));
      }
    }

    if (downloadFutures.isNotEmpty) {
      final results = await Future.wait(downloadFutures);
      if (results.any((success) => !success)) {
        args.sendPort.send(
          DownloadIsolateResult(
            filesToDelete: [],
            filesToRename: {},
            error: 'Falha em downloads de imagens',
          ),
        );
        return;
      }
    }

    args.sendPort.send(
      DownloadIsolateResult(
        filesToDelete: filesToDelete,
        filesToRename: filesToRename,
        newPicoDataBytes: newPicoData.writeToBuffer(),
      ),
    );
  } catch (e) {
    args.sendPort.send(
      DownloadIsolateResult(
        filesToDelete: [],
        filesToRename: {},
        error: e.toString(),
      ),
    );
  } finally {
    client.close();
  }
}
