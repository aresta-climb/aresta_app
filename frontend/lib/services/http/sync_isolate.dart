import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../aresta_api/proto/generated/indice.pb.dart';
import 'sync_storage.dart';

class DownloadIsolateArgs {
  final Uint8List newResumoBytes;
  final String downloadsDirPath;
  final String baseUrl;
  final SendPort sendPort;

  DownloadIsolateArgs({
    required this.newResumoBytes,
    required this.downloadsDirPath,
    required this.baseUrl,
    required this.sendPort,
  });
}

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

Future<void> downloadIsolateMain(DownloadIsolateArgs args) async {
  try {
    final client = http.Client();
    final storage = SyncStorage();
    final newResumo = ResumoCroqui.fromBuffer(args.newResumoBytes);
    final id = newResumo.id;
    final url = '${args.baseUrl}/${newResumo.caminhoRelativo}';
    final picoDirPath = '${args.downloadsDirPath}/$id';
    final picoFilePath = '$picoDirPath/$id.binarypb';
    final tmpPicoFilePath = '$picoDirPath/$id.binarypb.tmp';

    // Helper for atomic download
    Future<bool> downloadAtomic(String fileUrl, String tmpPath, String expectedHash) async {
      final isTmpValid = await storage.validateExistingTmpFile(tmpPath, expectedHash);
      if (isTmpValid) return true;
      final cacheBustingUrl = fileUrl.contains('?') ? '$fileUrl&v=$expectedHash' : '$fileUrl?v=$expectedHash';
      final response = await client.get(Uri.parse(cacheBustingUrl));
      if (response.statusCode != 200) return false;
      await storage.saveTmpFile(tmpPath, response.bodyBytes);
      return await storage.validateExistingTmpFile(tmpPath, expectedHash);
    }

    // 1% progress for starting/downloading main file
    args.sendPort.send(0.01);

    final mainFileSuccess = await downloadAtomic(url, tmpPicoFilePath, newResumo.checksumSha256Croqui);
    if (!mainFileSuccess) {
      args.sendPort.send(DownloadIsolateResult(filesToDelete: [], filesToRename: {}, error: 'Falha ao baixar binarypb'));
      return;
    }

    final newPicoData = await storage.readLocalCroqui(tmpPicoFilePath);
    if (newPicoData == null) {
      args.sendPort.send(DownloadIsolateResult(filesToDelete: [], filesToRename: {}, error: 'Falha ao ler novo binarypb'));
      return;
    }

    final oldPicoData = await storage.readLocalCroqui(picoFilePath);

    final newContent = {for (var ext in newPicoData.arquivosExternos) ext.caminho: ext.checksumSha256};
    final oldContent = oldPicoData != null ? {for (var ext in oldPicoData.arquivosExternos) ext.caminho: ext.checksumSha256} : <String, String>{};

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
            if (filePath.endsWith('.binarypb') || filePath.endsWith('.binarypb.tmp')) continue;
            bool isNeeded = false;
            for (var key in newContent.keys) {
              if (filePath.replaceAll('\\', '/').endsWith(key.replaceAll('\\', '/'))) {
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
        ? newResumo.caminhoRelativo.substring(0, newResumo.caminhoRelativo.lastIndexOf('/')) 
        : '';

    final Map<String, String> filesToRename = {};
    filesToRename[tmpPicoFilePath] = picoFilePath;

    final int totalFiles = newPicoData.arquivosExternos.length;
    int completedFiles = 0;

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
        final existingFileValid = await storage.validateExistingTmpFile('$picoDirPath/$localPath', newExt.checksumSha256);
        needsDownload = !existingFileValid;
      }

      if (needsDownload) {
        String remotePath = (baseDir.isNotEmpty && !localPath.startsWith(baseDir)) ? '$baseDir/$localPath' : localPath;
        downloadFutures.add(
          downloadAtomic('${args.baseUrl}/$remotePath', '$picoDirPath/$localPath.tmp', newExt.checksumSha256).then((success) {
            if (success) {
              filesToRename['$picoDirPath/$localPath.tmp'] = '$picoDirPath/$localPath';
            }
            completedFiles++;
            args.sendPort.send(0.01 + (0.99 * (completedFiles / totalFiles)));
            return success;
          })
        );
      } else {
        completedFiles++;
        args.sendPort.send(0.01 + (0.99 * (completedFiles / totalFiles)));
      }
    }

    if (downloadFutures.isNotEmpty) {
      final results = await Future.wait(downloadFutures);
      if (results.any((success) => !success)) {
        args.sendPort.send(DownloadIsolateResult(filesToDelete: [], filesToRename: {}, error: 'Falha em downloads de imagens'));
        return;
      }
    }

    args.sendPort.send(DownloadIsolateResult(
      filesToDelete: filesToDelete,
      filesToRename: filesToRename,
      newPicoDataBytes: newPicoData.writeToBuffer(),
    ));

  } catch (e) {
    args.sendPort.send(DownloadIsolateResult(filesToDelete: [], filesToRename: {}, error: e.toString()));
  }
}
