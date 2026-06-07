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

/// Um serviço responsável por sincronizar os dados locais com o backend remoto.
/// 
/// Ele lida com o download do índice mestre na inicialização, verifica atualizações
/// para picos baixados anteriormente e gerencia a sincronização de imagens.
class SyncService {
  final DatasetRepository datasetRepository;
  final http.Client _client;

  SyncService(this.datasetRepository, {http.Client? client})
      : _client = client ?? ZipInterceptorClient();

  /// Sincroniza o índice mestre com o servidor remoto na inicialização do aplicativo.
  /// 
  /// Se um novo índice estiver disponível, ele atualiza o cache local e aciona
  /// uma verificação de atualização em segundo plano para todos os picos baixados. Se o servidor estiver
  /// inacessível, ele reverte para o índice em cache local.
  Future<void> syncOnLaunch({bool auto = true}) async {
    TelemetryService.instance.logSincronizarApp(acao: auto ? 'automatica' : 'manual');
    datasetRepository.syncStatus.value = SyncStatus.updating;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final localIndiceFile = File(datasetRepository.editorDeCroqui.indicePath(directory.path));
      
      final editorDeCroqui = datasetRepository.editorDeCroqui;
      
      // Em modo editor de URL (mas não experimental), não queremos atualizar.
      // MAS, se for experimental, QUEREMOS buscar o índice para saber o que está disponível no ZIP ou Repo remoto.
      if (editorDeCroqui.editorUrl.value != null && 
          !editorDeCroqui.editorUrl.value!.startsWith('aresta-zip') && 
          !editorDeCroqui.isExperimentalMode.value) {
        debugPrint('[SyncService] Modo Editor (não experimental) ativo. Pulando atualizações automáticas.');
        await _loadLocalIndiceAndNotify();
        setUpdatedStatus();
        return;
      }

      String baseUrl = editorDeCroqui.activeBaseUrl;
      debugPrint('Buscando banco de dados em tempo real de $baseUrl/indice.binarypb...');
      
      http.Response? response;
      
      // Tenta buscar o índice com retentativas (para lidar com a falta de internet imediata no boot)
      int retries = 3;
      while (retries > 0) {
        try {
          final request = http.Request('GET', Uri.parse('$baseUrl/indice.binarypb'));
          final streamedResponse = await _client.send(request);
          response = await http.Response.fromStream(streamedResponse);
          break; // Sucesso, sai do loop
        } catch (e) {
          AppLogger.instance.logError('[SyncService] Erro na tentativa de fetch', error: e);
          retries--;
          if (retries > 0) {
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }

      // AUTO-DETECÇÃO: Se falhar e estivermos em modo editor/experimental, tentamos a subpasta /compilado
      if ((response == null || response.statusCode != 200) && editorDeCroqui.editorUrl.value != null && !editorDeCroqui.useCompiladoFolder.value) {
          String altUrl = editorDeCroqui.editorUrl.value!;
          if (!altUrl.contains('://') && !altUrl.startsWith('aresta-zip')) altUrl = 'https://$altUrl';
          if (altUrl.endsWith('/')) altUrl = altUrl.substring(0, altUrl.length - 1);
          altUrl = '$altUrl/compilado';
          
          debugPrint('[SyncService] Tentando auto-detecção em $altUrl/indice.binarypb...');
          try {
            final altRequest = http.Request('GET', Uri.parse('$altUrl/indice.binarypb'));
            final altStreamed = await _client.send(altRequest);
            final altResponse = await http.Response.fromStream(altStreamed);
            
            if (altResponse.statusCode == 200) {
              debugPrint('[SyncService] Subpasta /compilado detectada com sucesso!');
              editorDeCroqui.useCompiladoFolder.value = true;
              response = altResponse;
              // Persiste a mudança para não precisar detectar de novo
              if (editorDeCroqui.isExperimentalMode.value) {
                 await editorDeCroqui.activateExperimental(url: editorDeCroqui.editorUrl.value);
              } else {
                 await editorDeCroqui.connect(editorDeCroqui.editorUrl.value!);
              }
            }
          } catch (e) {
            debugPrint('[SyncService] Falha na detecção de subpasta: $e');
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
        if (oldIndice != null && !datasetRepository.editorDeCroqui.isExperimentalMode.value) {
          await _checkForUpdates(oldIndice, newIndice);
        } else {
          setUpdatedStatus();
        }
        
        // Sobrescreve o índice local com o novo APENAS após as atualizações terminarem.
        // Isso garante que se a atualização falhar ou o app for fechado, o índice antigo
        // será mantido e a verificação ocorrerá novamente na próxima inicialização.
        if (!await localIndiceFile.parent.exists()) {
          await localIndiceFile.parent.create(recursive: true);
        }
        await localIndiceFile.writeAsBytes(responseBytes);
      } else {
        AppLogger.instance.logError('Server returned an error or 304: ${response?.statusCode}');
        await _loadLocalIndiceAndNotify();
        setUpdatedStatus();
      }
    } catch (e) {
      debugPrint('Failed to connect to the server: $e');
      await _loadLocalIndiceAndNotify();
      datasetRepository.syncStatus.value = SyncStatus.error;
    }
  }

  /// Define o status como 'justUpdated' temporariamente antes de voltar para 'updated'.
  void setUpdatedStatus() {
    datasetRepository.syncStatus.value = SyncStatus.justUpdated;
    Future.delayed(const Duration(seconds: 3), () {
      // Só volta para 'updated' se o status não tiver mudado para outra coisa nesse meio tempo
      if (datasetRepository.syncStatus.value == SyncStatus.justUpdated) {
        datasetRepository.syncStatus.value = SyncStatus.updated;
      }
    });
  }

  /// Carrega o índice do armazenamento local e notifica o repositório.
  Future<void> _loadLocalIndiceAndNotify() async {
    final directory = await getApplicationDocumentsDirectory();
    final localIndiceFile = File(datasetRepository.editorDeCroqui.indicePath(directory.path));
    if (await localIndiceFile.exists()) {
      final bytes = await localIndiceFile.readAsBytes();
      final localIndice = Indice.fromBuffer(bytes);
      await datasetRepository.loadIndiceToMemory(localIndice);
    } else {
      datasetRepository.loadEmpty();
    }
  }

  /// Itera por todos os picos baixados e atualiza aqueles cujos checksums mudaram.
  Future<void> _checkForUpdates(Indice oldIndice, Indice newIndice) async {
    debugPrint('Checking for outdated picos...');
    datasetRepository.syncStatus.value = SyncStatus.updating;
    final directory = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory(datasetRepository.editorDeCroqui.downloadsPath(directory.path));
    if (!await downloadsDir.exists()) {
      setUpdatedStatus();
      return;
    }

    for (var newResumo in newIndice.croquis) {
      final picoFile = File('${downloadsDir.path}/${newResumo.id}/${newResumo.id}.binarypb');
      if (await picoFile.exists()) {
        final oldResumoList = oldIndice.croquis.where((c) => c.id == newResumo.id).toList();
        if (oldResumoList.isNotEmpty) {
          final oldResumo = oldResumoList.first;
          if (oldResumo.checksumSha256Croqui != newResumo.checksumSha256Croqui) {
            debugPrint('Pico ${newResumo.id} is outdated. Updating...');
            await _updatePico(newResumo, downloadsDir);
          }
        }
      }
    }
    
    setUpdatedStatus();
    debugPrint('Background update check complete.');
  }

  /// Atualiza um único pico baixando seu novo binarypb e sincronizando suas imagens.
  Future<void> _updatePico(ResumoCroqui newResumo, Directory downloadsDir) async {
    final baseUrl = datasetRepository.editorDeCroqui.activeBaseUrl;
    final url = '$baseUrl/${newResumo.url}';
    final response = await _client.get(Uri.parse(url));

    if (response.statusCode != 200) {
      debugPrint('Failed to download new pico ${newResumo.id}');
      return;
    }

    final newPicoData = Croqui.fromBuffer(response.bodyBytes);
    final picoDir = Directory('${downloadsDir.path}/${newResumo.id}');
    final picoFile = File('${picoDir.path}/${newResumo.id}.binarypb');
    
    Croqui? oldPicoData;
    if (await picoFile.exists()) {
      oldPicoData = Croqui.fromBuffer(await picoFile.readAsBytes());
    }

    if (oldPicoData != null) {
      String baseDir = '';
      int lastSlash = newResumo.url.lastIndexOf('/');
      if (lastSlash != -1) {
        baseDir = newResumo.url.substring(0, lastSlash);
      }

      final newContent = { for (var ext in newPicoData.arquivosExternos) ext.caminho : ext.checksumSha256 };

      for (var oldExt in oldPicoData.arquivosExternos) {
        bool shouldDelete = false;
        if (!newContent.containsKey(oldExt.caminho)) {
          shouldDelete = true;
        } else if (newContent[oldExt.caminho] != oldExt.checksumSha256) {
          shouldDelete = true;
        }

        if (shouldDelete) {
          final oldFile = File('${picoDir.path}/${oldExt.caminho}');
          if (await oldFile.exists()) {
            await oldFile.delete();
            debugPrint('Deleted old file: ${oldExt.caminho}');
          }
        }
      }

      final oldContent = { for (var ext in oldPicoData.arquivosExternos) ext.caminho : ext.checksumSha256 };
      final List<Future<void>> downloadFutures = [];
      for (var newExt in newPicoData.arquivosExternos) {
        if (!oldContent.containsKey(newExt.caminho) || oldContent[newExt.caminho] != newExt.checksumSha256) {
          String localPath = newExt.caminho;
          if (localPath.startsWith('/')) localPath = localPath.substring(1);
          String remotePath = (baseDir.isNotEmpty && !localPath.startsWith(baseDir)) ? '$baseDir/$localPath' : localPath;
          downloadFutures.add(_downloadFile(localPath, remotePath, picoDir));
        }
      }

      if (downloadFutures.isNotEmpty) {
        await Future.wait(downloadFutures);
      }
    }

    if (!await picoDir.exists()) {
      await picoDir.create(recursive: true);
    }
    await picoFile.writeAsBytes(response.bodyBytes);
    
    // Atualiza os metadados (como a imagem de capa) após a sincronização
    final directory = await getApplicationDocumentsDirectory();
    final pData = datasetRepository.activeDataset.value?.availablePicos.firstWhere((p) => p['id'] == newResumo.id, orElse: () => {});
    if (pData != null && pData.isNotEmpty) {
      await datasetRepository.updatePicoMetadata(newResumo.id, pData, directory.path, parsedPico: newPicoData);
    }

    TelemetryService.instance.logAtualizarCroqui(newResumo.id, newResumo.checksumSha256Croqui, newResumo.timestampUpdate.toDateTime().toIso8601String());
    debugPrint('Updated pico ${newResumo.id} successfully.');
  }





  /// Baixa um arquivo do servidor remoto.
  /// 
  /// [localPath]: Caminho usado para salvar o arquivo no celular (ex: `imagens/p1.webp`).
  /// Não deve conter a pasta do pico, pois o [downloadsDir] já aponta para a pasta específica do pico,
  /// evitando assim a criação de subpastas duplicadas.
  /// 
  /// [remotePath]: Caminho usado na URL para pedir o arquivo ao servidor (ex: `br_mg_igarape/imagens/p1.webp`).
  /// Precisa conter o prefixo da pasta do pico para evitar o Erro 404.
  Future<void> _downloadFile(String localPath, String remotePath, Directory downloadsDir) async {
    try {
      final baseUrl = datasetRepository.editorDeCroqui.activeBaseUrl;
      final fileUrl = '$baseUrl/$remotePath';
      debugPrint('Downloading file: $fileUrl');
      final response = await _client.get(Uri.parse(fileUrl));
      if (response.statusCode == 200) {
        final downloadedFile = File('${downloadsDir.path}/$localPath');
        if (!await downloadedFile.parent.exists()) {
          await downloadedFile.parent.create(recursive: true);
        }
        await downloadedFile.writeAsBytes(response.bodyBytes);
      } else {
        debugPrint('Failed to download file $localPath (from $remotePath), status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Exception downloading file $localPath: $e');
    }
  }

  /// Fecha o cliente HTTP subjacente.
  void dispose() {
    _client.close();
  }
}
