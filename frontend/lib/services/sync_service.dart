import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'zip_interceptor_client.dart';
import 'package:path_provider/path_provider.dart';
import '../aresta_api/proto/generated/indice.pb.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import 'dataset_repository.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:crypto/crypto.dart';

/// Representa o estado de sincronização do aplicativo.
enum SyncStatus { updated, updating, outdated, error, justUpdated }

/// Um serviço responsável por sincronizar os dados locais com o backend remoto.
///
class SyncService {
  final DatasetRepository datasetRepository;
  final http.Client _client;

  /// Notifica os ouvintes sobre o status de sincronização atual.
  final ValueNotifier<SyncStatus> syncStatus = ValueNotifier(
    SyncStatus.updating,
  );

  /// Indica se há algum download de pico em andamento e armazena os IDs dos picos que estão sendo baixados.
  final ValueNotifier<Set<String>> downloadingCrags =
      ValueNotifier<Set<String>>({});

  /// Indica se a última tentativa de sincronização foi automática (true) ou manual (false).
  final ValueNotifier<bool> lastSyncWasAuto = ValueNotifier<bool>(true);

  SyncService({required this.datasetRepository, http.Client? client})
    : _client = client ?? ZipInterceptorClient();

  /// Realiza o download completo de um Crag e seus arquivos associados para o armazenamento local.
  ///
  /// Retorna [true] se as operações de download e salvamento forem bem-sucedidas.
  Future<bool> downloadCrag(Map<String, dynamic> crag) async {
    final String? url = crag['url'];
    final String? id = crag['id'];

    if (url == null || id == null) {
      AppLogger.instance.logError(
        'Tentativa de download do pico falhou: ID ou URL nulos. crag=$crag',
      );
      return false;
    }

    downloadingCrags.value = {...downloadingCrags.value, id};

    try {
      debugPrint('Baixando pico $id de $url...');
      final indice = datasetRepository.indiceData.value;
      if (indice == null) {
        AppLogger.instance.logError(
          'Aviso: Indice é nulo durante o download do pico $id. Usando metadados de fallback (modo editor?).',
        );
      }

      String relativeUrl = url;
      if (relativeUrl.startsWith(
        datasetRepository.editorDeCroqui.activeBaseUrl,
      )) {
        relativeUrl = relativeUrl.substring(
          datasetRepository.editorDeCroqui.activeBaseUrl.length,
        );
        if (relativeUrl.startsWith('/')) relativeUrl = relativeUrl.substring(1);
      }

      final resumo =
          indice?.croquis.firstWhere(
            (r) => r.id == id,
            orElse: () => ResumoCroqui()
              ..id = id
              ..url = relativeUrl
              ..nome = crag['nome'] ?? '',
          ) ??
          (ResumoCroqui()
            ..id = id
            ..url = relativeUrl
            ..nome = crag['nome'] ?? '');

      final directory = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory(
        datasetRepository.editorDeCroqui.downloadsPath(directory.path),
      );

      final success = await downloadOrUpdatePico(resumo, downloadsDir);

      if (success) {
        await datasetRepository.updateDatasetAfterDownload(id);
        TelemetryService.instance.logAcaoExplorar(id, 'baixar');
      }

      return success;
    } catch (e) {
      AppLogger.instance.logError('Error downloading crag $id', error: e);
    } finally {
      // Desmarca como baixando, independentemente de sucesso ou falha
      downloadingCrags.value = {...downloadingCrags.value}..remove(id);
    }
    return false;
  }

  /// Sincroniza o índice mestre com o servidor remoto na inicialização do aplicativo.
  ///
  /// Se um novo índice estiver disponível, ele atualiza o cache local e aciona
  /// uma verificação de atualização em segundo plano para todos os picos baixados. Se o servidor estiver
  /// inacessível, ele reverte para o índice em cache local.
  /// Retorna uma lista com os nomes dos croquis que falharam na atualização atômica.
  Future<List<String>> syncOnLaunch({bool auto = true}) async {
    lastSyncWasAuto.value = auto;
    TelemetryService.instance.logSincronizarApp(
      acao: auto ? 'automatica' : 'manual',
    );
    syncStatus.value = SyncStatus.updating;
    final List<String> failedPicos = [];

    try {
      final directory = await getApplicationDocumentsDirectory();
      final localIndiceFile = File(
        datasetRepository.editorDeCroqui.indicePath(directory.path),
      );

      final editorDeCroqui = datasetRepository.editorDeCroqui;

      // Em modo editor de URL (mas não experimental), não queremos atualizar.
      // MAS, se for experimental, QUEREMOS buscar o índice para saber o que está disponível no ZIP ou Repo remoto.
      if (editorDeCroqui.editorUrl.value != null &&
          !editorDeCroqui.editorUrl.value!.startsWith('aresta-zip') &&
          !editorDeCroqui.isExperimentalMode.value) {
        debugPrint(
          '[SyncService] Modo Editor (não experimental) ativo. Pulando atualizações automáticas.',
        );
        await _loadLocalIndiceAndNotify();
        setUpdatedStatus();
        return failedPicos;
      }

      String baseUrl = editorDeCroqui.activeBaseUrl;
      debugPrint(
        'Buscando banco de dados em tempo real de $baseUrl/indice.binarypb...',
      );

      http.Response? response;

      // Tenta buscar o índice com retentativas (para lidar com a falta de internet imediata no boot)
      int retries = 3;
      while (retries > 0) {
        try {
          final request = http.Request(
            'GET',
            Uri.parse('$baseUrl/indice.binarypb'),
          );
          final streamedResponse = await _client.send(request);
          response = await http.Response.fromStream(streamedResponse);
          break; // Sucesso, sai do loop
        } catch (e) {
          AppLogger.instance.logError(
            '[SyncService] Erro na tentativa de fetch',
            error: e,
          );
          retries--;
          if (retries > 0) {
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }

      // AUTO-DETECÇÃO: Se falhar e estivermos em modo editor/experimental, tentamos a subpasta /compilado
      if ((response == null || response.statusCode != 200) &&
          editorDeCroqui.editorUrl.value != null &&
          !editorDeCroqui.useCompiladoFolder.value) {
        String altUrl = editorDeCroqui.editorUrl.value!;
        if (!altUrl.contains('://') && !altUrl.startsWith('aresta-zip')) {
          altUrl = 'https://$altUrl';
        }
        if (altUrl.endsWith('/')) {
          altUrl = altUrl.substring(0, altUrl.length - 1);
        }
        altUrl = '$altUrl/compilado';

        debugPrint(
          '[SyncService] Tentando auto-detecção em $altUrl/indice.binarypb...',
        );
        try {
          final altRequest = http.Request(
            'GET',
            Uri.parse('$altUrl/indice.binarypb'),
          );
          final altStreamed = await _client.send(altRequest);
          final altResponse = await http.Response.fromStream(altStreamed);

          if (altResponse.statusCode == 200) {
            debugPrint(
              '[SyncService] Subpasta /compilado detectada com sucesso!',
            );
            editorDeCroqui.useCompiladoFolder.value = true;
            response = altResponse;
            // Persiste a mudança para não precisar detectar de novo
            if (editorDeCroqui.isExperimentalMode.value) {
              await editorDeCroqui.activateExperimental(
                url: editorDeCroqui.editorUrl.value,
              );
            } else {
              await editorDeCroqui.connect(editorDeCroqui.editorUrl.value!);
            }
          }
        } catch (e) {
          AppLogger.instance.logError(
            'Falha na detecção de subpasta',
            error: e,
          );
        }
      }

      if (response != null && response.statusCode == 200) {
        final responseBytes = response.bodyBytes;
        final newIndice = Indice.fromBuffer(responseBytes);

        Indice? oldIndice;
        if (await localIndiceFile.exists()) {
          final oldBytes = await localIndiceFile.readAsBytes();
          oldIndice = Indice.fromBuffer(oldBytes);
        }

        // Notifica o DatasetRepository que há um novo Índice carregado
        // Isso atualiza a UI imediatamente para o usuário ver os picos novos
        await datasetRepository.loadIndiceToMemory(newIndice);

        // Executa atualização em segundo plano para picos baixados anteriormente
        // (Pulamos isso se for experimental, pois o zip é estático)
        if (oldIndice != null &&
            !datasetRepository.editorDeCroqui.isExperimentalMode.value) {
          failedPicos.addAll(await _checkForUpdates(oldIndice, newIndice));
        } else {
          setUpdatedStatus();
        }

        // Sobrescreve o índice local com o novo APENAS após as atualizações terminarem COM SUCESSO.
        // Isso garante que se a atualização falhar ou o app for fechado, o índice antigo
        // será mantido e a verificação ocorrerá novamente na próxima inicialização.
        if (failedPicos.isEmpty) {
          if (!await localIndiceFile.parent.exists()) {
            await localIndiceFile.parent.create(recursive: true);
          }
          await localIndiceFile.writeAsBytes(responseBytes);
        } else {
          AppLogger.instance.logError(
            '[SyncService] Falha na atualização de ${failedPicos.length} picos. O índice não será sobrescrito.',
          );
        }
      } else {
        AppLogger.instance.logError(
          'Server returned an error or 304: ${response?.statusCode}',
        );
        await _loadLocalIndiceAndNotify();
        setUpdatedStatus();
      }
    } catch (e) {
      AppLogger.instance.logError('Failed to connect to the server', error: e);
      await _loadLocalIndiceAndNotify();
      syncStatus.value = SyncStatus.error;
    }
    return failedPicos;
  }

  /// Define o status como 'justUpdated' temporariamente antes de voltar para 'updated'.
  void setUpdatedStatus() {
    syncStatus.value = SyncStatus.justUpdated;
    Future.delayed(const Duration(seconds: 4), () {
      // Só volta para 'updated' se o status não tiver mudado para outra coisa nesse meio tempo
      if (syncStatus.value == SyncStatus.justUpdated) {
        syncStatus.value = SyncStatus.updated;
      }
    });
  }

  /// Carrega o índice do armazenamento local e notifica o repositório.
  Future<void> _loadLocalIndiceAndNotify() async {
    final directory = await getApplicationDocumentsDirectory();
    final localIndiceFile = File(
      datasetRepository.editorDeCroqui.indicePath(directory.path),
    );
    if (await localIndiceFile.exists()) {
      final bytes = await localIndiceFile.readAsBytes();
      final localIndice = Indice.fromBuffer(bytes);
      await datasetRepository.loadIndiceToMemory(localIndice);
    } else {
      datasetRepository.loadEmpty();
    }
  }

  /// Itera por todos os picos baixados e atualiza aqueles cujos checksums mudaram.
  /// Retorna uma lista de nomes de picos que falharam ao atualizar.
  Future<List<String>> _checkForUpdates(
    Indice oldIndice,
    Indice newIndice,
  ) async {
    debugPrint('Checking for outdated picos...');
    syncStatus.value = SyncStatus.updating;
    final directory = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory(
      datasetRepository.editorDeCroqui.downloadsPath(directory.path),
    );
    if (!await downloadsDir.exists()) {
      setUpdatedStatus();
      return [];
    }

    final List<String> failedPicos = [];

    try {
      for (var newResumo in newIndice.croquis) {
        final picoFile = File(
          '${downloadsDir.path}/${newResumo.id}/${newResumo.id}.binarypb',
        );
        if (await picoFile.exists()) {
          final oldResumoList = oldIndice.croquis
              .where((c) => c.id == newResumo.id)
              .toList();
          if (oldResumoList.isNotEmpty) {
            final oldResumo = oldResumoList.first;
            if (oldResumo.checksumSha256Croqui !=
                newResumo.checksumSha256Croqui) {
              debugPrint('Pico ${newResumo.id} is outdated. Updating...');
              final success = await downloadOrUpdatePico(
                newResumo,
                downloadsDir,
              );
              if (!success) {
                failedPicos.add(newResumo.nome);
              }
            }
          }
        }
      }

      if (failedPicos.isNotEmpty) {
        syncStatus.value = SyncStatus.error;
      } else {
        setUpdatedStatus();
      }
    } catch (e) {
      AppLogger.instance.logError(
        'Erro crítico durante atualização de picos',
        error: e,
      );
      syncStatus.value = SyncStatus.error;
    }

    debugPrint('Background update check complete.');
    return failedPicos;
  }

  /// Atualiza ou baixa um pico e sincroniza suas imagens de forma atômica.
  /// Retorna true se o update/download teve sucesso, false caso contrário.
  Future<bool> downloadOrUpdatePico(
    ResumoCroqui newResumo,
    Directory downloadsDir,
  ) async {
    final baseUrl = datasetRepository.editorDeCroqui.activeBaseUrl;
    final url = '$baseUrl/${newResumo.url}';

    try {
      final picoDir = Directory('${downloadsDir.path}/${newResumo.id}');
      final picoFile = File('${picoDir.path}/${newResumo.id}.binarypb');
      final tmpPicoFile = File('${picoDir.path}/${newResumo.id}.binarypb.tmp');

      if (!await picoDir.exists()) {
        await picoDir.create(recursive: true);
      }

      bool isPicoTmpValid = false;
      if (await tmpPicoFile.exists()) {
        if (newResumo.checksumSha256Croqui.isNotEmpty) {
          final stream = tmpPicoFile.openRead();
          final hashResult = await sha256.bind(stream).first;
          if (hashResult.toString() == newResumo.checksumSha256Croqui) {
            isPicoTmpValid = true;
            debugPrint('Resumed existing .tmp croqui for ${newResumo.id}');
          } else {
            await tmpPicoFile.delete();
          }
        } else {
          await tmpPicoFile.delete();
        }
      }

      if (!isPicoTmpValid) {
        final response = await _client.get(Uri.parse(url));

        if (response.statusCode != 200) {
          AppLogger.instance.logError(
            'Failed to download new pico ${newResumo.id}',
          );
          return false;
        }

        final bytes = response.bodyBytes;
        final downloadedHash = sha256.convert(bytes).toString();
        if (newResumo.checksumSha256Croqui.isNotEmpty &&
            downloadedHash != newResumo.checksumSha256Croqui) {
          AppLogger.instance.logError(
            'Hash mismatch for croqui ${newResumo.id}. Expected: ${newResumo.checksumSha256Croqui}, Got: $downloadedHash',
          );
          return false;
        }

        await tmpPicoFile.writeAsBytes(bytes);
      }

      final bytes = await tmpPicoFile.readAsBytes();
      final newPicoData = Croqui.fromBuffer(bytes);

      Croqui? oldPicoData;
      if (await picoFile.exists()) {
        oldPicoData = Croqui.fromBuffer(await picoFile.readAsBytes());
      }

      String baseDir = '';
      int lastSlash = newResumo.url.lastIndexOf('/');
      if (lastSlash != -1) {
        baseDir = newResumo.url.substring(0, lastSlash);
      }

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

      final List<File> filesToDelete = [];
      final List<Future<bool>> downloadFutures = [];
      final List<File> tempFilesToRename = [];
      final List<File> originalFilesToReplace = [];

      // 1. Identificar arquivos para deletar
      if (oldPicoData != null) {
        for (var oldExt in oldPicoData.arquivosExternos) {
          if (!newContent.containsKey(oldExt.caminho)) {
            filesToDelete.add(File('${picoDir.path}/${oldExt.caminho}'));
          }
        }
      }

      // 2. Identificar e disparar downloads
      for (var newExt in newPicoData.arquivosExternos) {
        if (!oldContent.containsKey(newExt.caminho) ||
            oldContent[newExt.caminho] != newExt.checksumSha256) {
          String localPath = newExt.caminho;
          if (localPath.startsWith('/')) localPath = localPath.substring(1);
          String remotePath =
              (baseDir.isNotEmpty && !localPath.startsWith(baseDir))
              ? '$baseDir/$localPath'
              : localPath;

          final expectedHash = newExt.checksumSha256;
          downloadFutures.add(
            _downloadFileAtomic(localPath, remotePath, picoDir, expectedHash),
          );

          tempFilesToRename.add(File('${picoDir.path}/$localPath.tmp'));
          originalFilesToReplace.add(File('${picoDir.path}/$localPath'));
        }
      }

      // Aguarda todos os downloads
      if (downloadFutures.isNotEmpty) {
        final results = await Future.wait(downloadFutures);
        if (results.any((success) => !success)) {
          AppLogger.instance.logError(
            'Falha em um ou mais downloads do croqui ${newResumo.id}. Abortando update atômico.',
          );
          return false;
        }
      }

      // 3. Sucesso absoluto: Renomear .tmp para final
      for (int i = 0; i < tempFilesToRename.length; i++) {
        final tmpFile = tempFilesToRename[i];
        final finalFile = originalFilesToReplace[i];
        if (await finalFile.exists()) {
          await finalFile.delete();
        }
        if (await tmpFile.exists()) {
          await tmpFile.rename(finalFile.path);
        }
      }

      // 4. Executar exclusões pendentes
      for (var file in filesToDelete) {
        if (await file.exists()) {
          await file.delete();
          debugPrint('Deleted old file: ${file.path}');
        }
      }

      // 5. Salvar o master pico.binarypb (movendo o tmp para o final)
      if (await picoFile.exists()) {
        await picoFile.delete();
      }
      if (await tmpPicoFile.exists()) {
        await tmpPicoFile.rename(picoFile.path);
      }

      // Atualiza os metadados (como a imagem de capa) após a sincronização
      final directory = await getApplicationDocumentsDirectory();
      final pData = datasetRepository.activeDataset.value?.availablePicos
          .firstWhere((p) => p['id'] == newResumo.id, orElse: () => {});
      if (pData != null && pData.isNotEmpty) {
        await datasetRepository.updatePicoMetadata(
          newResumo.id,
          pData,
          directory.path,
          parsedPico: newPicoData,
        );
      }

      TelemetryService.instance.logAtualizarCroqui(
        newResumo.id,
        newResumo.checksumSha256Croqui,
        newResumo.timestampUpdate.toDateTime().toIso8601String(),
      );
      debugPrint('Updated pico ${newResumo.id} successfully.');
      return true;
    } catch (e) {
      AppLogger.instance.logError(
        'Erro crítico durante o download do pico ${newResumo.id}',
        error: e,
      );
      return false;
    }
  }

  /// Baixa um arquivo do servidor remoto para um arquivo .tmp e verifica seu hash SHA256.
  Future<bool> _downloadFileAtomic(
    String localPath,
    String remotePath,
    Directory downloadsDir,
    String expectedHash,
  ) async {
    try {
      final tmpFile = File('${downloadsDir.path}/$localPath.tmp');

      // Validação de Resume: se o .tmp já existe, checamos o hash.
      if (await tmpFile.exists()) {
        if (expectedHash.isEmpty) {
          // Se não há hash esperado (ex: modo editor), não podemos assumir que o .tmp está íntegro. Deleta para baixar de novo.
          await tmpFile.delete();
        } else {
          final stream = tmpFile.openRead();
          final hashResult = await sha256.bind(stream).first;
          if (hashResult.toString() == expectedHash) {
            debugPrint('Resumed existing .tmp file $localPath (hash matches).');
            return true; // Already downloaded and valid
          }
          // Hash diferente, deleta o inválido para baixar de novo
          await tmpFile.delete();
        }
      }

      final baseUrl = datasetRepository.editorDeCroqui.activeBaseUrl;
      final fileUrl = '$baseUrl/$remotePath';
      debugPrint('Downloading file: $fileUrl to .tmp');
      final response = await _client.get(Uri.parse(fileUrl));

      if (response.statusCode == 200) {
        if (!await tmpFile.parent.exists()) {
          await tmpFile.parent.create(recursive: true);
        }
        await tmpFile.writeAsBytes(response.bodyBytes);

        // Verifica o hash do novo download se houver um hash esperado
        final stream = tmpFile.openRead();
        final hashResult = await sha256.bind(stream).first;
        if (expectedHash.isEmpty || hashResult.toString() == expectedHash) {
          return true;
        } else {
          AppLogger.instance.logError(
            'Hash mismatch for $localPath. Expected: $expectedHash, Got: $hashResult',
          );
          await tmpFile.delete();
          return false;
        }
      } else {
        AppLogger.instance.logError(
          'Failed to download file $localPath (from $remotePath), status: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      AppLogger.instance.logError(
        'Exception downloading file $localPath',
        error: e,
      );
      return false;
    }
  }

  /// Fecha o cliente HTTP subjacente.
  void dispose() {
    _client.close();
  }
}
