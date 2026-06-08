import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'zip_interceptor_client.dart';
import 'package:path_provider/path_provider.dart';
import '../../aresta_api/proto/generated/indice.pb.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../dataset_repository.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'sync_storage.dart';
import 'sync_network.dart';

/// Representa o estado de sincronização do aplicativo.
enum SyncStatus { updated, updating, outdated, error, justUpdated }

/// Um serviço responsável por sincronizar os dados locais com o backend remoto.
///
class SyncService {
  final DatasetRepository datasetRepository;
  final SyncStorage _storage;
  final SyncNetwork _network;

  /// Notifica os ouvintes sobre o status de sincronização atual.
  final ValueNotifier<SyncStatus> syncStatus = ValueNotifier(
    SyncStatus.updating,
  );

  /// Indica se há algum download de pico em andamento e armazena os IDs dos picos que estão sendo baixados.
  final ValueNotifier<Set<String>> downloadingCrags =
      ValueNotifier<Set<String>>({});

  /// Indica se a última tentativa de sincronização foi automática (true) ou manual (false).
  final ValueNotifier<bool> lastSyncWasAuto = ValueNotifier<bool>(true);

  SyncService({
    required this.datasetRepository,
    http.Client? client,
    SyncStorage? storage,
    SyncNetwork? network,
  }) : _storage = storage ?? SyncStorage(),
       _network = network ?? SyncNetwork(client ?? ZipInterceptorClient());

  /// Realiza o download completo de um Crag e seus arquivos associados para o armazenamento local.
  ///
  /// Retorna [true] se as operações de download e salvamento forem bem-sucedidas.
  Future<bool> downloadCrag(ResumoCroqui resumo) async {
    final String id = resumo.id;
    final String url = resumo.url;

    if (url.isEmpty || id.isEmpty) {
      AppLogger.instance.logError(
        'Tentativa de download do pico falhou: ID ou URL vazios. id=$id',
      );
      return false;
    }

    downloadingCrags.value = {...downloadingCrags.value, id};

    try {
      debugPrint('Baixando pico $id de $url...');

      // Garanta que temos o indice local sincronizado com o remoto antes de
      // baixar o pico pra não ter erros de checksum após os downloads.
      await syncIndex(auto: false);

      final directory = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory(
        datasetRepository.editorDeCroqui.downloadsPath(directory.path),
      );

      final success = await _downloadOrUpdatePico(resumo, downloadsDir);

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

  /// Sincroniza o índice mestre com o servidor remoto.
  ///
  /// Se um novo índice estiver disponível, ele atualiza o cache local e aciona
  /// uma verificação de atualização em segundo plano para todos os picos baixados. Se o servidor estiver
  /// inacessível, ele reverte para o índice em cache local.
  /// Retorna uma lista com os nomes dos croquis que falharam na atualização atômica.
  Future<List<String>> syncIndex({bool auto = true}) async {
    lastSyncWasAuto.value = auto;
    TelemetryService.instance.logSincronizarApp(
      acao: auto ? 'automatica' : 'manual',
    );
    syncStatus.value = SyncStatus.updating;
    final List<String> failedPicos = [];

    try {
      final directory = await getApplicationDocumentsDirectory();
      final editorDeCroqui = datasetRepository.editorDeCroqui;
      final localIndicePath = editorDeCroqui.indicePath(directory.path);
      final localEtagPath = '$localIndicePath.etag';

      final baseUrl = editorDeCroqui.activeBaseUrl;
      debugPrint(
        'Buscando banco de dados em tempo real de $baseUrl/indice.binarypb...',
      );

      final localEtag = await _storage.readETag(localEtagPath);
      final result = await _network.fetchIndiceWithRetries(baseUrl, localEtag);

      if (result == null) {
        await _loadLocalIndiceAndNotify(localIndicePath);
        setUpdatedStatus();
        return failedPicos;
      }

      switch (result) {
        case IndiceUpdated():
          final responseBytes = result.rawBytes;
          final newIndice = result.newIndice;
          final oldIndice = await _storage.readLocalIndice(localIndicePath);

          await datasetRepository.loadIndiceToMemory(newIndice);

          if (oldIndice != null && !editorDeCroqui.isExperimentalMode.value) {
            failedPicos.addAll(await _checkForUpdates(oldIndice, newIndice));
          } else {
            setUpdatedStatus();
          }

          if (failedPicos.isEmpty) {
            await _persistNewIndice(
              localIndicePath,
              localEtagPath,
              responseBytes,
              result.newEtag,
            );
          } else {
            AppLogger.instance.logError(
              '[SyncService] Falha na atualização de ${failedPicos.length} picos. O índice não será sobrescrito.',
            );
          }
        case IndiceUnchanged():
          debugPrint(
            '[SyncService] Índice 304 Not Modified - Nenhuma atualização necessária.',
          );
          if (datasetRepository.activeDataset.value == null) {
            await _loadLocalIndiceAndNotify(localIndicePath);
          }
          setUpdatedStatus();
      }
    } catch (e) {
      AppLogger.instance.logError('Failed to connect to the server', error: e);
      final directory = await getApplicationDocumentsDirectory();
      await _loadLocalIndiceAndNotify(
        datasetRepository.editorDeCroqui.indicePath(directory.path),
      );
      syncStatus.value = SyncStatus.error;
    }
    return failedPicos;
  }

  /// Grava o novo índice baixado em disco, garantindo que o arquivo `.etag`
  /// seja mantido atualizado para habilitar cache HTTP (304 Not Modified).
  Future<void> _persistNewIndice(
    String localIndicePath,
    String localEtagPath,
    Uint8List responseBytes,
    String? newEtag,
  ) async {
    await _storage.writeLocalIndice(localIndicePath, responseBytes);
    if (newEtag != null) {
      await _storage.writeETag(localEtagPath, newEtag);
    } else {
      await _storage.deleteETag(localEtagPath);
    }
  }

  /// Carrega o arquivo `indice.binarypb` salvo localmente na memória,
  /// inicializando a visualização de mapas. Se falhar, limpa o repositório.
  Future<void> _loadLocalIndiceAndNotify(String localIndicePath) async {
    final localIndice = await _storage.readLocalIndice(localIndicePath);
    if (localIndice != null) {
      await datasetRepository.loadIndiceToMemory(localIndice);
    } else {
      datasetRepository.loadEmpty();
    }
  }

  /// Troca o status da sincronização para recém-atualizado e agenda a transição
  /// automática para "concluído/atualizado" após alguns segundos.
  void setUpdatedStatus() {
    syncStatus.value = SyncStatus.justUpdated;
    Future.delayed(const Duration(seconds: 4), () {
      if (syncStatus.value == SyncStatus.justUpdated) {
        syncStatus.value = SyncStatus.updated;
      }
    });
  }

  /// Compara o índice baixado (`newIndice`) com o antigo (`oldIndice`) para identificar
  /// quais Croquis já armazenados localmente sofreram alterações (baseado no sha256).
  /// Caso alterações sejam detectadas, os baixa novamente de forma transparente.
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
        final picoFilePath =
            '${downloadsDir.path}/${newResumo.id}/${newResumo.id}.binarypb';
        if (await File(picoFilePath).exists()) {
          final oldResumoList = oldIndice.croquis
              .where((c) => c.id == newResumo.id)
              .toList();
          if (oldResumoList.isNotEmpty) {
            final oldResumo = oldResumoList.first;
            if (oldResumo.checksumSha256Croqui !=
                newResumo.checksumSha256Croqui) {
              debugPrint('Pico ${newResumo.id} is outdated. Updating...');
              final success = await _downloadOrUpdatePico(
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
  /// NOTA: Essa função deve ser chamada após garantir que o índice já está atualizado.
  Future<bool> _downloadOrUpdatePico(
    ResumoCroqui newResumo,
    Directory downloadsDir,
  ) async {
    final currentIndice = datasetRepository.indiceData.value;
    if (currentIndice == null) return false;

    final latestResumoList = currentIndice.croquis
        .where((c) => c.id == newResumo.id)
        .toList();
    if (latestResumoList.isEmpty) {
      AppLogger.instance.logError(
        'Croqui ${newResumo.id} não foi encontrado no índice atualizado.',
      );
      return false;
    }

    final latestResumo = latestResumoList.first;

    final baseUrl = datasetRepository.editorDeCroqui.activeBaseUrl;
    final url = '$baseUrl/${latestResumo.url}';
    final id = latestResumo.id;

    try {
      final picoDirPath = '${downloadsDir.path}/$id';
      final picoFilePath = '$picoDirPath/$id.binarypb';
      final tmpPicoFilePath = '$picoDirPath/$id.binarypb.tmp';

      // 1. Processar arquivo principal do Pico (.binarypb)
      final mainFileSuccess = await _downloadFileAtomic(
        url,
        tmpPicoFilePath,
        latestResumo.checksumSha256Croqui,
      );
      if (!mainFileSuccess) return false;

      final newPicoData = await _storage.readLocalCroqui(tmpPicoFilePath);
      if (newPicoData == null) return false;

      final oldPicoData = await _storage.readLocalCroqui(picoFilePath);

      // 2. Sincronizar arquivos externos (imagens)
      final syncResult = await _syncExternalFiles(
        newPicoData: newPicoData,
        oldPicoData: oldPicoData,
        newResumo: latestResumo,
        picoDirPath: picoDirPath,
        baseUrl: baseUrl,
      );

      if (syncResult == null) return false;

      // 3. Efetivar alteração do arquivo principal e arquivos externos
      await _storage.applyAtomicFileUpdates(
        filesToDelete: syncResult.filesToDelete,
        filesToRename: {
          tmpPicoFilePath: picoFilePath,
          ...syncResult.filesToRename,
        },
      );

      await _updatePicoMetadata(id, newPicoData);

      TelemetryService.instance.logAtualizarCroqui(
        id,
        latestResumo.checksumSha256Croqui,
        latestResumo.timestampUpdate.toDateTime().toIso8601String(),
      );
      debugPrint('Updated pico $id successfully.');
      return true;
    } catch (e) {
      AppLogger.instance.logError(
        'Erro crítico durante o download do pico $id',
        error: e,
      );
      return false;
    }
  }

  /// Gerencia de maneira concorrente a sincronização das imagens externas
  /// associadas ao croqui, baixando as que faltam/mudaram e montando a lista
  /// de quais antigas deverão ser removidas.
  Future<({List<String> filesToDelete, Map<String, String> filesToRename})?>
  _syncExternalFiles({
    required Croqui newPicoData,
    required Croqui? oldPicoData,
    required ResumoCroqui newResumo,
    required String picoDirPath,
    required String baseUrl,
  }) async {
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

    final filesToDelete = _identifyFilesToDelete(
      oldPicoData,
      newContent,
      picoDirPath,
    );
    final baseDir = _extractBaseDir(newResumo.url);

    final List<Future<bool>> downloadFutures = [];
    final Map<String, String> filesToRename = {};

    for (var newExt in newPicoData.arquivosExternos) {
      if (!oldContent.containsKey(newExt.caminho) ||
          oldContent[newExt.caminho] != newExt.checksumSha256) {
        String localPath = newExt.caminho;
        if (localPath.startsWith('/')) localPath = localPath.substring(1);
        String remotePath =
            (baseDir.isNotEmpty && !localPath.startsWith(baseDir))
            ? '$baseDir/$localPath'
            : localPath;

        downloadFutures.add(
          _downloadFileAtomic(
            '$baseUrl/$remotePath',
            '$picoDirPath/$localPath.tmp',
            newExt.checksumSha256,
          ),
        );

        filesToRename['$picoDirPath/$localPath.tmp'] =
            '$picoDirPath/$localPath';
      }
    }

    if (downloadFutures.isNotEmpty) {
      final results = await Future.wait(downloadFutures);
      if (results.any((success) => !success)) {
        AppLogger.instance.logError(
          'Falha em downloads do croqui ${newResumo.id}. Abortando update.',
        );
        return null;
      }
    }

    return (filesToDelete: filesToDelete, filesToRename: filesToRename);
  }

  /// Cruza a lista de caminhos do arquivo novo vs o antigo para retornar a lista de
  /// arquivos descontinuados que precisam ser apagados do cache no fim do processo.
  List<String> _identifyFilesToDelete(
    Croqui? oldPicoData,
    Map<String, String> newContent,
    String picoDirPath,
  ) {
    final List<String> filesToDelete = [];
    if (oldPicoData != null) {
      for (var oldExt in oldPicoData.arquivosExternos) {
        if (!newContent.containsKey(oldExt.caminho)) {
          filesToDelete.add('$picoDirPath/${oldExt.caminho}');
        }
      }
    }
    return filesToDelete;
  }

  /// Pega a URL do arquivo pai (`indice.binarypb` ou do pico) e extrai
  /// apenas a parte pertencente ao diretório base.
  String _extractBaseDir(String url) {
    int lastSlash = url.lastIndexOf('/');
    return (lastSlash != -1) ? url.substring(0, lastSlash) : '';
  }

  /// Atualiza os campos de metadados de informações resumidas do Pico
  /// (como bounding boxes ou pin maps) disponíveis diretamente na listagem do dataset.
  Future<void> _updatePicoMetadata(String id, Croqui newPicoData) async {
    final directory = await getApplicationDocumentsDirectory();
    final picos = datasetRepository.activeDataset.value?.availablePicos;
    if (picos == null) return;

    for (var p in picos) {
      if (p['id'] == id) {
        await datasetRepository.updatePicoMetadata(
          id,
          p,
          directory.path,
          parsedPico: newPicoData,
        );
        break;
      }
    }
  }

  /// Realiza o download atômico de um arquivo, validando seu hash logo
  /// após salvar no disco em formato `.tmp`.
  Future<bool> _downloadFileAtomic(
    String fileUrl,
    String tmpFilePath,
    String expectedHash,
  ) async {
    try {
      final isTmpValid = await _storage.validateExistingTmpFile(
        tmpFilePath,
        expectedHash,
      );

      if (isTmpValid) {
        debugPrint('Resumed existing .tmp file for $fileUrl (hash matches).');
        return true;
      }

      debugPrint('Downloading file: $fileUrl to .tmp');
      final bytes = await _network.downloadFile(fileUrl);

      if (bytes == null) {
        AppLogger.instance.logError(
          'Failed to download $fileUrl (null returned)',
        );
        return false;
      }

      await _storage.saveTmpFile(tmpFilePath, bytes);

      if (!await _storage.validateExistingTmpFile(tmpFilePath, expectedHash)) {
        AppLogger.instance.logError('Hash mismatch for $fileUrl.');
        return false;
      }

      return true;
    } catch (e) {
      AppLogger.instance.logError(
        'Exception downloading file $fileUrl',
        error: e,
      );
      return false;
    }
  }

  /// Fecha o HttpClient da dependência de rede, liberando recursos.
  void dispose() {
    _network.client.close();
  }
}
