// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
  final List<String> picosAtualizadosComSucesso = [];
  bool hasErrors = false;

  /// Combina as operações pendentes de outro [other] com este agregador.
  void merge(_SyncUpdates other) {
    filesToDelete.addAll(other.filesToDelete);
    filesToRename.addAll(other.filesToRename);
    metadataToUpdate.addAll(other.metadataToUpdate);
    failedPicos.addAll(other.failedPicos);
    picosAtualizadosComSucesso.addAll(other.picosAtualizadosComSucesso);
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
  final ValueNotifier<String?> picoAbertoId = ValueNotifier<String?>(null);

  /// Se uma atualização atômica for impedida pelo fato de o pico alvo
  /// estar aberto na tela (ver [picoAbertoId]), seu ID será injetado
  /// nesta variável. A interface de mapa a ouve e projeta um Popup
  /// de bloqueio, exigindo do usuário a recarga manual via [commitPendenciasAtomaticas].
  final ValueNotifier<String?> recargaPendentePicoId =
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

    if (recargaPendentePicoId.value == id) {
      recargaPendentePicoId.value = null;
    }
  }

  /// Indica se a última tentativa de sincronização foi automática (true) ou manual (false).
  final ValueNotifier<bool> lastSyncWasAuto = ValueNotifier<bool>(true);

  /// Quantidade de croquis armazenados localmente que foram atualizados com sucesso
  /// na última sincronização. Permite que a interface decida se deve notificar o usuário
  /// na abertura do app sem emitir avisos caso apenas o catálogo/índice remoto tenha mudado.
  final ValueNotifier<int> quantidadeCroquisBaixadosAtualizadosNoUltimoSync =
      ValueNotifier<int>(0);

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
       _network = network ?? SyncNetwork(client ?? http.Client()) {
    picoAbertoId.addListener(() {
      final currentOpenId = picoAbertoId.value;
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
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '[SyncService] Falha ao verificar versão da base de dados',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Confirma que a migração foi bem sucedida, gravando a nova versão em cache
  /// para não bloquear o app nos próximos inícios.
  Future<void> confirmMigrationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cached_data_version', NetworkConstants.kDataVersion);
    AppLogger.instance.logInfo(
      '[SyncService] Nova versão de dados registrada com sucesso: ${NetworkConstants.kDataVersion}',
    );
  }

  /// Executa o fluxo completo e unificado de migração da base de dados:
  /// 1. Sincroniza o novo catálogo/índice remoto (`syncIndex(auto: false)`).
  /// 2. Rebaixa silenciosamente os croquis que o usuário já havia baixado localmente.
  /// 3. Confirma a conclusão da migração gravando `cached_data_version`.
  ///
  /// Retorna [true] se a migração for concluída com sucesso, ou [false] em caso de falha de rede/erros.
  Future<bool> executarMigracao({bool rebaixarCroquisSalvos = true}) async {
    try {
      final falhas = await syncIndex(auto: false);
      if (falhas.isNotEmpty ||
          syncStatus.value == SyncStatus.error ||
          syncStatus.value == SyncStatus.offline) {
        AppLogger.instance.logError(
          '[SyncService] Falha ao sincronizar índice durante a migração',
          stackTrace: StackTrace.current,
        );
        return false;
      }

      if (rebaixarCroquisSalvos) {
        final picosSalvos =
            datasetRepository.activeDataset.value?.downloadedPicos ?? [];
        final indice = datasetRepository.indiceData.value;

        if (indice != null && picosSalvos.isNotEmpty) {
          AppLogger.instance.logInfo(
            '[SyncService] Rebaixando ${picosSalvos.length} croquis salvos...',
          );
          for (final pico in picosSalvos) {
            final String id = pico.id;
            final resumos = indice.croquis.where((r) => r.id == id).toList();
            if (resumos.isNotEmpty) {
              await downloadCrag(resumos.first);
            }
          }
        }
      }

      await confirmMigrationComplete();
      AppLogger.instance.logInfo('[SyncService] Migração executada com sucesso.');
      return true;
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '[SyncService] Erro inesperado ao executar migração',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Realiza o download completo de um Crag e seus arquivos associados para o armazenamento local.
  ///
  /// Retorna [true] se as operações de download e salvamento forem bem-sucedidas.
  Future<bool> downloadCrag(ResumoCroqui resumo) async {
    final String id = resumo.id;
    final String url = resumo.caminhoRelativo;

    if (await isNetworkDisabled()) {
      AppLogger.instance.logAviso(
        'Download abortado: O aplicativo está em uma versão descontinuada.',
      );
      return false;
    }

    if (url.isEmpty || id.isEmpty) {
      AppLogger.instance.logError(
        'Tentativa de download do pico falhou: ID ou URL vazios. id=$id',
        stackTrace: StackTrace.current,
      );
      return false;
    }
    downloadingCrags.value = {...downloadingCrags.value, id: 0.0};
    try {
      AppLogger.instance.logInfo('Baixando pico $id de $url...');

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
        AppLogger.instance.logAviso(
          '🛑 [SyncService] Tentativa 1 de download de $id falhou. Forçando atualização do índice ignorando o cache...',
        );
        await syncIndex(auto: false, forceBypassCache: true);

        final currentIndice = datasetRepository.indiceData.value;
        if (currentIndice != null) {
          final updatedResumoList = currentIndice.croquis
              .where((c) => c.id == id)
              .toList();
          if (updatedResumoList.isNotEmpty) {
            AppLogger.instance.logInfo(
              '[SyncService] Tentando download novamente com o índice atualizado para $id...',
            );
            updates = await _downloadOrUpdatePico(
              updatedResumoList.first,
              downloadsDir,
            );
            success = !updates.hasErrors;
          }
        }

        if (!success) {
          AppLogger.instance.logFalhaSyncOuDownload(
            'Falha definitiva no download do croqui $id',
            stackTrace: StackTrace.current,
          );
        }
      }

      if (success) {
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
        TelemetryService.instance.logAcaoExplorar(id, 'baixar');
      }

      return success;
    } catch (e, stack) {
      AppLogger.instance.logFalhaSyncOuDownload(
        'Erro ao baixar croqui $id',
        error: e,
        stackTrace: stack,
      );
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
      AppLogger.instance.logAviso(
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
    quantidadeCroquisBaixadosAtualizadosNoUltimoSync.value = 0;
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
        AppLogger.instance.logError(
          '[SyncService] URL base vazia. Sincronização cancelada.',
          stackTrace: StackTrace.current,
        );
        await _loadLocalIndiceAndNotify(localIndicePath);
        setUpdatedStatus();
        return failedPicos;
      }

      AppLogger.instance.logInfo(
        'Buscando banco de dados em tempo real de $baseUrl/indice.binarypb...',
      );

      final localEtag = await _storage.readETag(localEtagPath);
      AppLogger.instance.logInfo(
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
          }

          final croquiUpdates = await _checkForUpdates(oldIndice, newIndice);
          globalUpdates.merge(croquiUpdates);

          if (globalUpdates.failedPicos.isNotEmpty) {
            failedPicos.addAll(globalUpdates.failedPicos);
          }

          if (failedPicos.isEmpty && !globalUpdates.hasErrors) {
            // Sucesso total. Efetivar todas as alterações pendentes de uma vez só (Atomic Global Updates).
            // Isso previne que o aplicativo fique com dados e arquivos em estados inconsistentes caso
            // o índice mestre falhe ao ser baixado ou processado.
            if (globalUpdates.filesToRename.isNotEmpty) {
              AppLogger.instance.logInfo(
                '🔄 [SyncService] Arquivos atualizados/renomeados no syncIndex (${globalUpdates.filesToRename.length}):',
              );
              for (final entrada in globalUpdates.filesToRename.entries) {
                AppLogger.instance.logInfo('   • ${entrada.key} -> ${entrada.value}');
              }
            }
            if (globalUpdates.filesToDelete.isNotEmpty) {
              AppLogger.instance.logInfo(
                '🗑️ [SyncService] Arquivos removidos no syncIndex (${globalUpdates.filesToDelete.length}):',
              );
              for (final arquivo in globalUpdates.filesToDelete) {
                AppLogger.instance.logInfo('   • $arquivo');
              }
            }

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
            quantidadeCroquisBaixadosAtualizadosNoUltimoSync.value =
                globalUpdates.picosAtualizadosComSucesso.length;
            setUpdatedStatus();
          } else {
            AppLogger.instance.logError(
              '[SyncService] Falha na atualização de ${failedPicos.length} picos ou nas thumbnails. O índice não será sobrescrito.',
              stackTrace: StackTrace.current,
            );
            if (!forceBypassCache) {
              AppLogger.instance.logAviso(
                '[SyncService] Falha na atualização de picos possivelmente devido a cache stale. Tentando novamente forçando bypass de cache...',
              );
              final fallbackFailedPicos = await syncIndex(
                auto: auto,
                forceBypassCache: true,
              );
              failedPicos.clear();
              failedPicos.addAll(fallbackFailedPicos);
            } else {
              AppLogger.instance.logError(
                '[SyncService] Falha definitiva na sincronização após tentativa de bypass de cache.',
                stackTrace: StackTrace.current,
              );
              syncStatus.value = SyncStatus.error;
              TelemetryService.instance.logResultadoSincronizacao('erro');
            }
          }
        case IndiceUnchanged():
          AppLogger.instance.logInfo(
            '[SyncService] Índice 304 Not Modified - Nenhuma atualização necessária.',
          );
          if (datasetRepository.activeDataset.value == null) {
            await _loadLocalIndiceAndNotify(localIndicePath);
          }
          quantidadeCroquisBaixadosAtualizadosNoUltimoSync.value = 0;
          setUpdatedStatus(noNewUpdates: true);
      }
    } catch (e, stack) {
      AppLogger.instance.logFalhaSyncOuDownload(
        'Falha ao sincronizar o índice com o servidor',
        error: e,
        stackTrace: stack,
      );
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
    AppLogger.instance.logInfo('Checking for outdated picos...');
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
            '${downloadsDir.path}/${newResumo.id}/compilado.binarypb';
        final legacyPicoFilePath =
            '${downloadsDir.path}/${newResumo.id}/${newResumo.id}.binarypb';
        if (await File(picoFilePath).exists() ||
            await File(legacyPicoFilePath).exists()) {
          bool needsUpdate = false;

          if (oldIndice == null) {
            // Fallback de Breaking Change: o indice local antigo estava corrompido ou era ilegível.
            // Para garantir que o usuário não fique com picos velhos "presos" sem o novo formato,
            // forçamos o update de todos os picos que estiverem presentes no armazenamento local.
            needsUpdate = true;
          } else {
            final oldResumoList = oldIndice.croquis
                .where((c) => c.id == newResumo.id)
                .toList();

            if (oldResumoList.isNotEmpty) {
              final oldResumo = oldResumoList.first;
              needsUpdate =
                  oldResumo.checksumSha256Croqui !=
                  newResumo.checksumSha256Croqui;
            } else {
              // Pico existe no disco mas não estava no índice antigo. Pode ter sido um download incompleto.
              needsUpdate = true;
            }
          }

          if (needsUpdate) {
            AppLogger.instance.logInfo(
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
              updates.picosAtualizadosComSucesso.add(newResumo.id);
              updates.merge(picoUpdates);
            }
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Erro crítico durante atualização de picos',
        error: e,
        stackTrace: stackTrace,
      );
      updates.hasErrors = true;
    }

    AppLogger.instance.logInfo('Background update check complete.');
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
        AppLogger.instance.logInfo('Baixando ${downloadTasks.length} thumbnails...');
        final results = await Future.wait(downloadTasks);
        if (results.any((success) => !success)) {
          updates.hasErrors = true;
        }
      }
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Erro ao sincronizar thumbnails globais',
        error: e,
        stackTrace: stackTrace,
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
        stackTrace: StackTrace.current,
      );
      updates.hasErrors = true;
      return updates;
    }

    final latestResumo = latestResumoList.first;

    final baseUrl =
        baseUrlOverride ?? datasetRepository.editorDeCroqui.activeBaseUrl;
    final id = latestResumo.id;

    if (baseUrl.isEmpty) {
      AppLogger.instance.logError(
        'Base URL vazia ao tentar baixar croqui $id.',
        stackTrace: StackTrace.current,
      );
      updates.hasErrors = true;
      return updates;
    }
    try {
      final receivePort = ReceivePort();

      String? tempCacheDirPath;
      try {
        final tempDir = await getTemporaryDirectory();
        tempCacheDirPath = '${tempDir.path}/temp_cache';
      } catch (_) {}

      final args = DownloadIsolateArgs(
        newResumoBytes: latestResumo.writeToBuffer(),
        downloadsDirPath: downloadsDir.path,
        baseUrl: baseUrl,
        sendPort: receivePort.sendPort,
        tempCacheDirPath: tempCacheDirPath,
      );

      AppLogger.instance.logInfo('[SyncService] Iniciando download do croqui $id a partir de: $baseUrl');
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
            tratarErroDownloadIsolate(id, message);
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
          AppLogger.instance.logInfo('Updated pico $id successfully (pending atomic apply).');
          return updates;
        }
      }
      return updates;
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Erro crítico durante o download do pico $id',
        error: e,
        stackTrace: stackTrace,
      );
      updates.hasErrors = true;
      return updates;
    } finally {
      downloadingCrags.value = {...downloadingCrags.value}..remove(id);
    }
  }

  /// Trata o erro emitido pelo isolate de download em background, repassando ao [AppLogger].
  ///
  /// Reconstitui fielmente o [StackTrace] a partir de [DownloadIsolateResult.rastreamentoPilha]
  /// utilizando [StackTrace.fromString], garantindo que relatórios do Firebase Crashlytics
  /// apontem com precisão para as linhas do [sync_isolate.dart] onde ocorreu a falha,
  /// em vez de herdar acidentalmente a pilha de execução da thread da UI (Main Isolate).
  @visibleForTesting
  void tratarErroDownloadIsolate(String id, DownloadIsolateResult message) {
    final StackTrace stackTrace = message.rastreamentoPilha != null
        ? StackTrace.fromString(message.rastreamentoPilha!)
        : StackTrace.current;
    AppLogger.instance.logFalhaSyncOuDownload(
      'Erro no isolate de download do pico $id: ${message.error}',
      error: message.error,
      stackTrace: stackTrace,
    );
  }

  /// Atualiza os campos de metadados de informações resumidas do Pico
  /// (como bounding boxes ou pin maps) disponíveis diretamente na listagem do dataset.
  Future<void> _updatePicoMetadata(String id, Croqui newPicoData) async {
    final directory = await getApplicationDocumentsDirectory();
    final picos = datasetRepository.activeDataset.value?.availablePicos;
    if (picos == null) return;

    for (var p in picos) {
      if (p.id == id) {
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
        AppLogger.instance.logInfo('Resumed existing .tmp file for $fileUrl (hash matches).');
        return true;
      }

      // Furador de cache (Cache-Busting) para CDNs (Cloudflare/GitHub Pages)
      // Como os arquivos mantêm o mesmo nome ao serem atualizados, a CDN pode servir cache velho.
      // Adicionando `?v=hash`, forçamos a CDN a buscar a versão mais recente.
      final cacheBustingUrl = fileUrl.contains('?')
          ? '$fileUrl&v=$expectedHash'
          : '$fileUrl?v=$expectedHash';

      AppLogger.instance.logInfo('Downloading file: $cacheBustingUrl to .tmp');
      final bytes = await _network.downloadFile(cacheBustingUrl);

      if (bytes == null) {
        AppLogger.instance.logError(
          'Failed to download $fileUrl (null returned)',
          stackTrace: StackTrace.current,
        );
        return false;
      }

      await _storage.saveTmpFile(tmpFilePath, bytes);

      if (!await _storage.validateExistingTmpFile(tmpFilePath, expectedHash)) {
        AppLogger.instance.logError(
          'Hash mismatch for $fileUrl.',
          stackTrace: StackTrace.current,
        );
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Exception downloading file $fileUrl',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Fecha o HttpClient da dependência de rede, liberando recursos.
  void dispose() {
    _network.client.close();
  }
}
