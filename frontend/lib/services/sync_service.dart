import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../kmon_api/proto/indice.pb.dart';
import '../kmon_api/proto/croqui.pb.dart';
import 'dataset_repository.dart';

/// A service responsible for synchronizing local data with the remote backend.
/// 
/// It handles downloading the master index on launch, checking for updates
/// to previously downloaded crags, and managing the synchronization of images.
class SyncService {
  final DatasetRepository datasetRepository;
  final String _baseUrl = 'https://acecmg.github.io/kmon_serving';
  final http.Client _client = http.Client();

  SyncService(this.datasetRepository);

  /// Synchronizes the master index with the remote server on application launch.
  /// 
  /// If a new index is available, it updates the local cache and triggers
  /// a background update check for all downloaded crags. If the server is 
  /// unreachable, it falls back to the local cached index.
  Future<void> syncOnLaunch() async {
    datasetRepository.syncStatus.value = SyncStatus.updating;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final localIndiceFile = File('${directory.path}/indice.binarypb');

      debugPrint('Fetching live database from $_baseUrl/indice.binarypb...');
      final request = http.Request('GET', Uri.parse('$_baseUrl/indice.binarypb'));
      
      final response = await _client.send(request);

      if (response.statusCode == 200) {
        final responseBytes = await response.stream.toBytes();
        final newIndice = Indice.fromBuffer(responseBytes);
        
        Indice? oldIndice;
        if (await localIndiceFile.exists()) {
          final oldBytes = await localIndiceFile.readAsBytes();
          oldIndice = Indice.fromBuffer(oldBytes);
        }

        // Overwrite the local index with the new one
        await localIndiceFile.writeAsBytes(responseBytes);

        // Notify DatasetRepository that there's a new loaded Indice
        await datasetRepository.loadIndiceToMemory(newIndice);

        // Run background update for previously downloaded picos
        if (oldIndice != null) {
          await _checkForUpdates(oldIndice, newIndice);
        } else {
          datasetRepository.syncStatus.value = SyncStatus.updated;
        }
      } else {
        debugPrint('Server returned an error or 304: ${response.statusCode}');
        await _loadLocalIndiceAndNotify();
        datasetRepository.syncStatus.value = SyncStatus.updated;
      }
    } catch (e) {
      debugPrint('Failed to connect to the server: $e');
      await _loadLocalIndiceAndNotify();
      datasetRepository.syncStatus.value = SyncStatus.error;
    }
  }

  /// Loads the index from local storage and notifies the repository.
  Future<void> _loadLocalIndiceAndNotify() async {
    final directory = await getApplicationDocumentsDirectory();
    final localIndiceFile = File('${directory.path}/indice.binarypb');
    if (await localIndiceFile.exists()) {
      final bytes = await localIndiceFile.readAsBytes();
      final localIndice = Indice.fromBuffer(bytes);
      await datasetRepository.loadIndiceToMemory(localIndice);
    } else {
      datasetRepository.loadEmpty();
    }
  }

  /// Iterates through all downloaded crags and updates those whose checksums have changed.
  Future<void> _checkForUpdates(Indice oldIndice, Indice newIndice) async {
    debugPrint('Checking for outdated picos...');
    datasetRepository.syncStatus.value = SyncStatus.updating;
    final directory = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${directory.path}/downloads');
    if (!await downloadsDir.exists()) {
      datasetRepository.syncStatus.value = SyncStatus.updated;
      return;
    }

    bool updatedAnything = false;
    for (var newResumo in newIndice.croquis) {
      final picoFile = File('${downloadsDir.path}/${newResumo.id}.binarypb');
      if (await picoFile.exists()) {
        final oldResumoList = oldIndice.croquis.where((c) => c.id == newResumo.id).toList();
        if (oldResumoList.isNotEmpty) {
          final oldResumo = oldResumoList.first;
          if (oldResumo.checksumSha256 != newResumo.checksumSha256) {
            debugPrint('Pico ${newResumo.id} is outdated. Updating...');
            await _updatePico(newResumo, downloadsDir);
            updatedAnything = true;
          }
        }
      }
    }
    
    datasetRepository.syncStatus.value = SyncStatus.updated;
    debugPrint('Background update check complete.');
  }

  /// Updates a single crag by downloading its new binarypb and syncing its images.
  Future<void> _updatePico(ResumoCroqui newResumo, Directory downloadsDir) async {
    final url = '$_baseUrl/${newResumo.url}';
    final response = await _client.get(Uri.parse(url));

    if (response.statusCode != 200) {
      debugPrint('Failed to download new pico ${newResumo.id}');
      return;
    }

    final newPicoData = Croqui.fromBuffer(response.bodyBytes);
    final picoFile = File('${downloadsDir.path}/${newResumo.id}.binarypb');
    
    Croqui? oldPicoData;
    if (await picoFile.exists()) {
      oldPicoData = Croqui.fromBuffer(await picoFile.readAsBytes());
    }

    if (oldPicoData != null) {
      final newImages = { for (var ext in newPicoData.arquivosExternos) ext.caminho : ext.checksumSha256 };
      for (var oldExt in oldPicoData.arquivosExternos) {
        bool shouldDelete = false;
        if (!newImages.containsKey(oldExt.caminho)) {
          shouldDelete = true;
        } else if (newImages[oldExt.caminho] != oldExt.checksumSha256) {
          shouldDelete = true;
        }

        if (shouldDelete) {
          final oldImgFile = File('${downloadsDir.path}/${oldExt.caminho}');
          if (await oldImgFile.exists()) {
            await oldImgFile.delete();
            debugPrint('Deleted old image: ${oldExt.caminho}');
          }
        }
      }

      final oldImages = { for (var ext in oldPicoData.arquivosExternos) ext.caminho : ext.checksumSha256 };
      for (var newExt in newPicoData.arquivosExternos) {
        if (!oldImages.containsKey(newExt.caminho) || oldImages[newExt.caminho] != newExt.checksumSha256) {
          await _downloadImage(newExt.caminho, downloadsDir);
        }
      }
    }

    await picoFile.writeAsBytes(response.bodyBytes);
    debugPrint('Updated pico ${newResumo.id} successfully.');
  }

  /// Downloads all external files associated with a given [Croqui].
  Future<void> downloadExternalFilesForCroqui(Croqui newPicoData) async {
    final directory = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${directory.path}/downloads');
    
    for (var ext in newPicoData.arquivosExternos) {
      await _downloadImage(ext.caminho, downloadsDir);
    }
  }

  /// Downloads an image from the remote server.
  Future<void> _downloadImage(String caminho, Directory downloadsDir) async {
    try {
      final imageUrl = '$_baseUrl/$caminho';
      debugPrint('Downloading image: $imageUrl');
      final response = await _client.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final imgFile = File('${downloadsDir.path}/$caminho');
        if (!await imgFile.parent.exists()) {
          await imgFile.parent.create(recursive: true);
        }
        await imgFile.writeAsBytes(response.bodyBytes);
      } else {
        debugPrint('Failed to download image $caminho, status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Exception downloading image $caminho: $e');
    }
  }

  /// Closes the underlying HTTP client.
  void dispose() {
    _client.close();
  }
}
