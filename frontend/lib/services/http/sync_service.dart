import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'zip_interceptor_client.dart';
import 'package:path_provider/path_provider.dart';
import '../../aresta_api/proto/generated/indice.pb.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../dataset_repository.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/constants/network_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:isolate';
import 'sync_storage.dart';
import 'sync_network.dart';
import 'sync_isolate.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:frontend/services/firebase/remote_config_service.dart';

/// Classe auxiliar que agrega todas as operações de disco (.tmp -> renomeio, deleções)
/// e atualizações de estado em memória (metadados).
/// Utilizada para garantir que **nenhuma** alteração seja efetivada se houver falhas parciais.
class _SyncUpdates {
  final List<String> filesToDelete = [];
  final Map<String, String> filesToRename = {};
  final Map<String, Croqui> metadataToUpdate = {};
  final List<String> failedPicos = [];
  bool hasErrors = false;

  /// Combina as operações pendentes de outro [other] com este agregador.
  void merge(_SyncUpdates other) {
    filesToDelete.addAll(other.filesToDelete);
    filesToRename.addAll(other.filesToRename);
    metadataToUpdate.addAll(other.metadataToUpdate);
    failedPicos.addAll(other.failedPicos);
    if (other.hasErrors) hasErrors = true;
  }
}

/// Representa o estado de sincronização do aplicativo.
enum SyncStatus {
  updated,
  updating,
  outdated,
  error,
  justUpdated,
  noNewUpdates,
  offline,
}

/// Um serviço responsável por sincronizar os dados locais com o backend remoto.
///
class SyncService {
  static String? baseUrlOverride;
  final DatasetRepository datasetRepository;
  final SyncStorage _storage;
  final SyncNetwork _network;

  /// Notifica os ouvintes sobre o status de sincronização atual.
  final ValueNotifier<SyncStatus> syncStatus = ValueNotifier(
    SyncStatus.updating,
  );

  /// Indica se há algum download de pico em andamento e armazena os IDs dos picos que estão sendo baixados,
  /// juntamente com a porcentagem de progresso (0.0 a 1.0).
  final ValueNotifier<Map<String, double>> downloadingCrags =
      ValueNotifier<Map<String, double>>({});

  /// Controla qual croqui (Pico) está ativamente renderizado na tela (Main Thread/UI).
  ///
  /// O ciclo de vida do mapa (initState/dispose) deve definir este ID.
  /// Serve como um "lock" reativo: o [SyncService] lerá esta variável de forma
  /// síncrona na Event Loop após o término do download no Isolate. Se o ID
  /// do pico baixado for igual a este, a atualização atômica de arquivos
  /// não deve ser aplicada instantaneamente, evitando _crashs_ de leitura.
  final ValueNotifier<String?> pico_aberto_id = ValueNotifier<String?>(null);

  /// Se uma atualização atômica for impedida pelo fato de o pico alvo
  /// estar aberto na tela (ver [pico_aberto_id]), seu ID será injetado
  /// nesta variável. A interface de mapa a ouve e projeta um Popup
  /// de bloqueio, exigindo do usuário a recarga manual via [commitPendenciasAtomaticas].
  final ValueNotifier<String?> recarga_pendente_pico_id =
      ValueNotifier<String?>(null);

  /// Guarda atualizações atômicas deferidas pela UI
  final Map<String, _SyncUpdates> _pendenciasAtomicas = {};

  /// Aplica manualmente as pendências atômicas para um croqui específico.
  Future<void> commitPendenciasAtomaticas(String id) async {
    final updates = _pendenciasAtomicas.remove(id);
    if (updates != null) {
      if (updates.filesToDelete.isNotEmpty ||
          updates.filesToRename.isNotEmpty) {
        await _storage.applyAtomicFileUpdates(
          filesToDelete: updates.filesToDelete,
          filesToRename: updates.filesToRename,
        );
      }
      for (final entry in updates.metadataToUpdate.entries) {
        await _updatePicoMetadata(entry.key, entry.value);
      }
      await datasetRepository.updateDatasetAfterDownload(id);
    }

    if (recarga_pendente_pico_id.value == id) {
      recarga_pendente_pico_id.value = null;
    }
  }

  /// Indica se a última tentativa de sincronização foi automática (true) ou manual (false).
  final ValueNotifier<bool> lastSyncWasAuto = ValueNotifier<bool>(true);

  final RemoteConfigService? remoteConfigService;

  @visibleForTesting
  Future<void> Function(
    void Function(DownloadIsolateArgs),
    DownloadIsolateArgs,
  )?
  mockIsolateSpawn;

  SyncService({
    required this.datasetRepository,
    http.Client? client,
    SyncStorage? storage,
    SyncNetwork? network,
    this.remoteConfigService,
  }) : _storage = storage ?? SyncStorage(),
       _network = network ?? SyncNetwork(client ?? ZipInterceptorClient()) {
    pico_aberto_id.addListener(() {
      final currentOpenId = pico_aberto_id.value;
      final idsToCommit = _pendenciasAtomicas.keys
          .where((id) => id != currentOpenId)
          .toList();
      for (final id in idsToCommit) {
        commitPendenciasAtomaticas(id);
      }
    });
  }

  int? _cachedBuildNumber;

  /// Verifica se a versão atual do app está abaixo da `softMinVersion`.
  /// Quando isso acontece, as rotinas de rede do SyncService são bloqueadas.
  Future<bool> isNetworkDisabled() async {
    final remoteConfig = remoteConfigService ?? RemoteConfigService.instance;
    final softMinVersion = remoteConfig.softMinVersion;
    if (softMinVersion <= 0) return false;

    if (_cachedBuildNumber == null) {
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        _cachedBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
      } catch (_) {
        _cachedBuildNumber = 0;
      }
    }

    return _cachedBuildNumber! < softMinVersion;
  }

  /// Verifica se houve mudança na versão da base de dados.
  /// Retorna [true] se o cache local estiver numa versão antiga e o app
  /// precisar entrar no modo de Migração (baixar novo índice).
  Future<bool> checkNeedsMigration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedVersion = prefs.getInt('cached_data_version') ?? 0;
      return NetworkConstants.kDataVersion > cachedVersion;
    } catch (e) {
      AppLogger.instance.logError(
        '[SyncService] Falha ao verificar versão da base de dados',
        error: e,
      );
      return false;
    }
  }

  /// Confirma que a migração foi bem sucedida, gravando a nova versão em cache
  /// para não bloquear o app nos próximos inícios.
  Future<void> confirmMigrationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cached_data_version', NetworkConstants.kDataVersion);
    debugPrint(
      '[SyncService] Nova versão de dados registrada com sucesso: ${NetworkConstants.kDataVersion}',
    );
  }

  /// Realiza o download completo de um Crag e seus arquivos associados para o armazenamento local.
  ///
  /// Retorna [true] se as operações de download e salvamento forem bem-sucedidas.
  Future<bool> downloadCrag(ResumoCroqui resumo) async {
    final String id = resumo.id;
    final String url = resumo.caminhoRelativo;

    if (await isNetworkDisabled()) {
      AppLogger.instance.logError(
        'Download abortado: O aplicativo está em uma versão descontinuada.',
      );
      return false;
    }

    if (url.isEmpty || id.isEmpty) {
      AppLogger.instance.logError(
        'Tentativa de download do pico falhou: ID ou URL vazios. id=$id',
      );
      return false;
    }
    downloadingCrags.value = {...downloadingCrags.value, id: 0.0};
    try {
      debugPrint('Baixando pico $id de $url...');

      // Garanta que temos o indice local sincronizado com o remoto antes de
      // baixar o pico pra não ter erros de checksum após os downloads.
      await syncIndex(auto: false);

      final directory = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory(
        datasetRepository.editorDeCroqui.downloadsPath(directory.path),
      );

      _SyncUpdates updates = await _downloadOrUpdatePico(resumo, downloadsDir);
      bool success = !updates.hasErrors;

      if (!success) {
        // Se falhou, pode ser devido a um Hash Mismatch (nosso índice local está obsoleto
        // e a CDN buscou um arquivo novo). Vamos forçar uma atualização do índice e tentar de novo.
        debugPrint(
          'Download falhou. Forçando atualização do índice ignorando o cache...',
        );
        await syncIndex(auto: false, forceBypassCache: true);

        final currentIndice = datasetRepository.indiceData.value;
        if (currentIndice != null) {
          final updatedResumoList = currentIndice.croquis
              .where((c) => c.id == id)
              .toList();
          if (updatedResumoList.isNotEmpty) {
            debugPrint(
              'Tentando download novamente com o índice atualizado...',
            );
            updates = await _downloadOrUpdatePico(
              updatedResumoList.first,
              downloadsDir,
            );
            success = !updates.hasErrors;
          }
        }
      }

      if (success) {
        if (pico_aberto_id.value == id) {
          _pendenciasAtomicas[id] = updates;
          recarga_pendente_pico_id.value = id;
          debugPrint(
            'Download manual retido em pendência porque croqui $id está aberto.',
          );
        } else {
          if (updates.filesToDelete.isNotEmpty ||
              updates.filesToRename.isNotEmpty) {
            await _storage.applyAtomicFileUpdates(
              filesToDelete: updates.filesToDelete,
              filesToRename: updates.filesToRename,
            );
          }
          for (final entry in updates.metadataToUpdate.entries) {
            await _updatePicoMetadata(entry.key, entry.value);
          }
          await datasetRepository.updateDatasetAfterDownload(id);
        }
        TelemetryService.instance.logAcaoExplorar(id, 'baixar');
      }

      return success;
    } catch (e) {
      AppLogger.instance.logError('Error downloading crag $id', error: e);
    } finally {
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
  Future<List<String>> syncIndex({
    bool auto = true,
    bool forceBypassCache = false,
  }) async {
    if (await isNetworkDisabled()) {
      debugPrint(
        '[SyncService] Sincronização em background abortada: App descontinuado.',
      );
      await _loadLocalIndiceAndNotify(
        datasetRepository.editorDeCroqui.indicePath(
          (await getApplicationDocumentsDirectory()).path,
        ),
      );
      syncStatus.value = SyncStatus.outdated;
      return [];
    }

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

      final baseUrl = baseUrlOverride ?? editorDeCroqui.activeBaseUrl;

      if (baseUrl.isEmpty) {
        debugPrint(
          '[SyncService] URL base vazia. Sincronização ignorada, carregando local...',
        );
        await _loadLocalIndiceAndNotify(localIndicePath);
        setUpdatedStatus();
        return failedPicos;
      }

      debugPrint(
        'Buscando banco de dados em tempo real de $baseUrl/indice.binarypb...',
      );

      final localEtag = await _storage.readETag(localEtagPath);
      debugPrint(
        '[SyncService] 🔍 ETag Local sendo enviado na requisição: $localEtag',
      );
      final result = await _network.fetchIndiceWithRetries(
        baseUrl,
        localEtag,
        forceBypassCache: forceBypassCache,
      );

      if (result == null) {
        await _loadLocalIndiceAndNotify(localIndicePath);
        syncStatus.value = SyncStatus.offline;
        TelemetryService.instance.logResultadoSincronizacao('erro');
        return failedPicos;
      }

      switch (result) {
        case IndiceUpdated():
          final responseBytes = result.rawBytes;
          final newIndice = result.newIndice;
          final oldIndice = await _storage.readLocalIndice(localIndicePath);

          await datasetRepository.loadIndiceToMemory(newIndice);

          final globalUpdates = _SyncUpdates();

          if (!editorDeCroqui.isExperimentalMode.value) {
            final thumbUpdates = await _syncThumbnails(
              oldIndice,
              newIndice,
              baseUrl,
            );
            globalUpdates.merge(thumbUpdates);

            final croquiUpdates = await _checkForUpdates(oldIndice, newIndice);
            globalUpdates.merge(croquiUpdates);
          } else {
            setUpdatedStatus();
          }

          if (globalUpdates.failedPicos.isNotEmpty) {
            failedPicos.addAll(globalUpdates.failedPicos);
          }

          if (failedPicos.isEmpty && !globalUpdates.hasErrors) {
            // Sucesso total. Efetivar todas as alterações pendentes de uma vez só (Atomic Global Updates).
            // Isso previne que o aplicativo fique com dados e arquivos em estados inconsistentes caso
            // o índice mestre falhe ao ser baixado ou processado.
            if (globalUpdates.filesToDelete.isNotEmpty ||
                globalUpdates.filesToRename.isNotEmpty) {
              await _storage.applyAtomicFileUpdates(
                filesToDelete: globalUpdates.filesToDelete,
                filesToRename: globalUpdates.filesToRename,
              );
            }

            // Atualiza os metadados do aplicativo na RAM de forma segura após as operações de disco.
            for (final entry in globalUpdates.metadataToUpdate.entries) {
              await _updatePicoMetadata(entry.key, entry.value);
            }

            await _persistNewIndice(
              localIndicePath,
              localEtagPath,
              responseBytes,
              result.newEtag,
            );
            setUpdatedStatus();
          } else {
            AppLogger.instance.logError(
              '[SyncService] Falha na atualização de ${failedPicos.length} picos ou nas thumbnails. O índice não será sobrescrito.',
            );
            if (!forceBypassCache) {
              debugPrint(
                '[SyncService] Falha na atualização de picos possivelmente devido a cache stale. Tentando novamente forçando bypass de cache...',
              );
              final fallbackFailedPicos = await syncIndex(
                auto: auto,
                forceBypassCache: true,
              );
              failedPicos.clear();
              failedPicos.addAll(fallbackFailedPicos);
            } else {
              syncStatus.value = SyncStatus.error;
              TelemetryService.instance.logResultadoSincronizacao('erro');
            }
          }
        case IndiceUnchanged():
          debugPrint(
            '[SyncService] Índice 304 Not Modified - Nenhuma atualização necessária.',
          );
          if (datasetRepository.activeDataset.value == null) {
            await _loadLocalIndiceAndNotify(localIndicePath);
          }
          setUpdatedStatus(noNewUpdates: true);
      }
    } catch (e) {
      AppLogger.instance.logError('Failed to connect to the server', error: e);
      final directory = await getApplicationDocumentsDirectory();
      await _loadLocalIndiceAndNotify(
        datasetRepository.editorDeCroqui.indicePath(directory.path),
      );
      syncStatus.value = SyncStatus.error;
      TelemetryService.instance.logResultadoSincronizacao('erro');
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
  void setUpdatedStatus({bool noNewUpdates = false}) {
    syncStatus.value = noNewUpdates
        ? SyncStatus.noNewUpdates
        : SyncStatus.justUpdated;
    TelemetryService.instance.logResultadoSincronizacao(
      noNewUpdates ? 'sem_atualizacoes' : 'sucesso',
    );
    Future.delayed(const Duration(seconds: 4), () {
      if (syncStatus.value == SyncStatus.justUpdated ||
          syncStatus.value == SyncStatus.noNewUpdates) {
        syncStatus.value = SyncStatus.updated;
      }
    });
  }

  /// Compara o índice baixado (`newIndice`) com o antigo (`oldIndice`) para identificar
  /// quais Croquis já armazenados localmente sofreram alterações (baseado no sha256).
  /// Caso alterações sejam detectadas, os baixa novamente de forma transparente.
  Future<_SyncUpdates> _checkForUpdates(
    Indice? oldIndice,
    Indice newIndice,
  ) async {
    final updates = _SyncUpdates();
    debugPrint('Checking for outdated picos...');
    syncStatus.value = SyncStatus.updating;
    final directory = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory(
      datasetRepository.editorDeCroqui.downloadsPath(directory.path),
    );

    if (!await downloadsDir.exists()) {
      setUpdatedStatus();
      return updates;
    }

    try {
      for (var newResumo in newIndice.croquis) {
        final picoFilePath =
            '${downloadsDir.path}/${newResumo.id}/${newResumo.id}.binarypb';
        if (await File(picoFilePath).exists()) {
          bool needsUpdate = false;
          print('DEBUG: Checking pico ${newResumo.id}');

          if (oldIndice == null) {
            // Fallback de Breaking Change: o indice local antigo estava corrompido ou era ilegível.
            // Para garantir que o usuário não fique com picos velhos "presos" sem o novo formato,
            // forçamos o update de todos os picos que estiverem presentes no armazenamento local.
            needsUpdate = true;
          } else {
            final oldResumoList = oldIndice.croquis
                .where((c) => c.id == newResumo.id)
                .toList();

            print('DEBUG: oldResumoList is not empty for ${newResumo.id}');
            if (oldResumoList.isNotEmpty) {
              final oldResumo = oldResumoList.first;
              needsUpdate =
                  oldResumo.checksumSha256Croqui !=
                  newResumo.checksumSha256Croqui;
              print(
                'DEBUG: needsUpdate=$needsUpdate old=${oldResumo.checksumSha256Croqui} new=${newResumo.checksumSha256Croqui}',
              );
            } else {
              // Pico existe no disco mas não estava no índice antigo. Pode ter sido um download incompleto.
              needsUpdate = true;
            }
          }

          print('DEBUG: needsUpdate flag is $needsUpdate');
          if (needsUpdate) {
            debugPrint(
              'Pico ${newResumo.id} requires update (outdated or fallback). Updating...',
            );
            final picoUpdates = await _downloadOrUpdatePico(
              newResumo,
              downloadsDir,
            );
            if (picoUpdates.hasErrors) {
              updates.failedPicos.add(newResumo.nome);
              updates.hasErrors = true;
            } else {
              if (pico_aberto_id.value == newResumo.id) {
                _pendenciasAtomicas[newResumo.id] = picoUpdates;
                recarga_pendente_pico_id.value = newResumo.id;
                debugPrint(
                  'Sincronização em background do croqui ${newResumo.id} retida em pendência (aberto).',
                );
              } else {
                updates.merge(picoUpdates);
              }
            }
          }
        }
      }
    } catch (e) {
      AppLogger.instance.logError(
        'Erro crítico durante atualização de picos',
        error: e,
      );
      updates.hasErrors = true;
    }

    debugPrint('Background update check complete.');
    return updates;
  }

  /// Sincroniza as thumbnails globais para a tela "Explorar".
  /// Baixa as thumbnails de todos os picos do índice caso elas sejam novas ou tenham mudado.
  Future<_SyncUpdates> _syncThumbnails(
    Indice? oldIndice,
    Indice newIndice,
    String baseUrl,
  ) async {
    final updates = _SyncUpdates();
    try {
      final directory = await getApplicationDocumentsDirectory();
      final thumbnailsDir = Directory('${directory.path}/thumbnails');
      if (!await thumbnailsDir.exists()) {
        await thumbnailsDir.create(recursive: true);
      }

      final Map<String, String> oldHashes = {};
      final Set<String> oldIds = {};
      if (oldIndice != null) {
        for (var c in oldIndice.croquis) {
          oldIds.add(c.id);
          if (c.checksumSha256Thumbnail.isNotEmpty) {
            oldHashes[c.id] = c.checksumSha256Thumbnail;
          }
        }
      }

      final Set<String> newIdsWithThumbs = newIndice.croquis
          .where((c) => c.checksumSha256Thumbnail.isNotEmpty)
          .map((c) => c.id)
          .toSet();

      for (var oldId in oldIds) {
        if (!newIdsWithThumbs.contains(oldId)) {
          final thumbPath = '${thumbnailsDir.path}/$oldId.webp';
          if (await File(thumbPath).exists()) {
            updates.filesToDelete.add(thumbPath);
          }
        }
      }

      final List<Future<bool>> downloadTasks = [];

      for (var newResumo in newIndice.croquis) {
        if (newResumo.checksumSha256Thumbnail.isEmpty) continue;

        final id = newResumo.id;
        final newHash = newResumo.checksumSha256Thumbnail;
        final oldHash = oldHashes[id];

        final thumbPath = '${thumbnailsDir.path}/$id.webp';
        final thumbFile = File(thumbPath);

        bool needsDownload = false;

        if (oldHash != newHash) {
          needsDownload = true;
        } else if (!await thumbFile.exists()) {
          // Se o hash é o mesmo, mas o arquivo não está no disco, baixe novamente.
          needsDownload = true;
        }

        if (needsDownload) {
          final url = '$baseUrl/thumbnails/$id.webp';
          final tmpPath = '$thumbPath.tmp';

          downloadTasks.add(
            _downloadFileAtomic(url, tmpPath, newHash).then((success) {
              if (success) {
                updates.filesToRename[tmpPath] = thumbPath;
              }
              return success;
            }),
          );
        }
      }

      // Aguarda todos os downloads de thumbnails completarem paralelamente
      if (downloadTasks.isNotEmpty) {
        debugPrint('Baixando ${downloadTasks.length} thumbnails...');
        final results = await Future.wait(downloadTasks);
        if (results.any((success) => !success)) {
          updates.hasErrors = true;
        }
      }
    } catch (e) {
      AppLogger.instance.logError(
        'Erro ao sincronizar thumbnails globais',
        error: e,
      );
      updates.hasErrors = true;
    }
    return updates;
  }

  /// Atualiza ou baixa um pico e sincroniza suas imagens de forma atômica.
  /// Retorna _SyncUpdates com as alterações pendentes. Se houver erro, retorna _SyncUpdates com hasErrors=true.
  /// NOTA: Essa função deve ser chamada após garantir que o índice já está atualizado.
  Future<_SyncUpdates> _downloadOrUpdatePico(
    ResumoCroqui newResumo,
    Directory downloadsDir,
  ) async {
    final updates = _SyncUpdates();
    final currentIndice = datasetRepository.indiceData.value;
    if (currentIndice == null) {
      updates.hasErrors = true;
      return updates;
    }

    final latestResumoList = currentIndice.croquis
        .where((c) => c.id == newResumo.id)
        .toList();
    if (latestResumoList.isEmpty) {
      AppLogger.instance.logError(
        'Croqui ${newResumo.id} não foi encontrado no índice atualizado.',
      );
      updates.hasErrors = true;
      return updates;
    }

    final latestResumo = latestResumoList.first;

    final baseUrl =
        baseUrlOverride ?? datasetRepository.editorDeCroqui.activeBaseUrl;
    final id = latestResumo.id;
    try {
      final receivePort = ReceivePort();

      final args = DownloadIsolateArgs(
        newResumoBytes: latestResumo.writeToBuffer(),
        downloadsDirPath: downloadsDir.path,
        baseUrl: baseUrl,
        sendPort: receivePort.sendPort,
      );

      print('DEBUG: mockIsolateSpawn is not null! \'\'');
      if (mockIsolateSpawn != null) {
        await mockIsolateSpawn!(downloadIsolateMain, args);
      } else {
        await Isolate.spawn(downloadIsolateMain, args);
      }

      await for (final message in receivePort) {
        if (message is double) {
          downloadingCrags.value = {...downloadingCrags.value, id: message};
        } else if (message is DownloadIsolateResult) {
          receivePort.close();

          if (message.error != null) {
            AppLogger.instance.logError(
              'Erro no isolate de download do pico $id: ${message.error}',
            );
            updates.hasErrors = true;
            return updates;
          }

          updates.filesToDelete.addAll(message.filesToDelete);
          updates.filesToRename.addAll(message.filesToRename);

          if (message.newPicoDataBytes != null) {
            final newPicoData = Croqui.fromBuffer(message.newPicoDataBytes!);
            updates.metadataToUpdate[id] = newPicoData;
          }

          TelemetryService.instance.logAtualizarCroqui(
            id,
            latestResumo.checksumSha256Croqui,
            latestResumo.timestampUpdate.toDateTime().toIso8601String(),
          );
          debugPrint('Updated pico $id successfully (pending atomic apply).');
          return updates;
        }
      }
      return updates;
    } catch (e) {
      AppLogger.instance.logError(
        'Erro crítico durante o download do pico $id',
        error: e,
      );
      updates.hasErrors = true;
      return updates;
    } finally {
      downloadingCrags.value = {...downloadingCrags.value}..remove(id);
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

    final filesToDelete = await _identifyFilesToDelete(
      oldPicoData,
      newContent,
      picoDirPath,
    );
    final baseDir = _extractBaseDir(newResumo.caminhoRelativo);

    final List<Future<bool>> downloadFutures = [];
    final Map<String, String> filesToRename = {};

    for (var newExt in newPicoData.arquivosExternos) {
      String localPath = newExt.caminho;
      if (localPath.startsWith('/')) localPath = localPath.substring(1);

      bool needsDownload = false;
      if (oldContent.containsKey(newExt.caminho)) {
        // Caminho feliz: sabemos o hash antigo e comparamos direto com o novo.
        needsDownload = oldContent[newExt.caminho] != newExt.checksumSha256;
      } else {
        // Fallback de Breaking Change: o oldPicoData não foi lido (retornou null),
        // então não sabemos se a imagem no disco é a versão velha ou a nova.
        // Para economizar banda e não rebaixar tudo, validamos o hash do arquivo
        // que já está no disco. validateExistingTmpFile já deleta o arquivo se o hash não bater.
        final existingFileValid = await _storage.validateExistingTmpFile(
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
  ///
  /// Caso o `oldPicoData` seja nulo (ex: devido a um breaking change no schema do Protobuf
  /// que tornou o arquivo antigo ilegível), a rotina entra num fallback que varre ativamente
  /// a pasta do pico, apagando qualquer arquivo que não esteja declarado no `newContent`.
  Future<List<String>> _identifyFilesToDelete(
    Croqui? oldPicoData,
    Map<String, String> newContent,
    String picoDirPath,
  ) async {
    final List<String> filesToDelete = [];
    if (oldPicoData != null) {
      // Caminho feliz: temos a lista exata do que existia antes.
      for (var oldExt in oldPicoData.arquivosExternos) {
        if (!newContent.containsKey(oldExt.caminho)) {
          filesToDelete.add('$picoDirPath/${oldExt.caminho}');
        }
      }
    } else {
      // Fallback de Breaking Change: não sabemos o que existia, então vasculhamos a pasta
      // em busca de arquivos órfãos (arquivos que não fazem mais parte do novo croqui).
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
              // Ensure we match the relative path accurately
              if (filePath
                  .replaceAll('\\', '/')
                  .endsWith(key.replaceAll('\\', '/'))) {
                isNeeded = true;
                break;
              }
            }
            if (!isNeeded) {
              filesToDelete.add(filePath);
            }
          }
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

      // Furador de cache (Cache-Busting) para CDNs (Cloudflare/GitHub Pages)
      // Como os arquivos mantêm o mesmo nome ao serem atualizados, a CDN pode servir cache velho.
      // Adicionando `?v=hash`, forçamos a CDN a buscar a versão mais recente.
      final cacheBustingUrl = fileUrl.contains('?')
          ? '$fileUrl&v=$expectedHash'
          : '$fileUrl?v=$expectedHash';

      debugPrint('Downloading file: $cacheBustingUrl to .tmp');
      final bytes = await _network.downloadFile(cacheBustingUrl);

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
