import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../kmon_api/proto/indice.pb.dart';
import '../kmon_api/proto/croqui.pb.dart';
import 'dataset_repository.dart';

/// Um serviço responsável por sincronizar os dados locais com o backend remoto.
/// 
/// Ele lida com o download do índice mestre na inicialização, verifica atualizações
/// para picos baixados anteriormente e gerencia a sincronização de imagens.
class SyncService {
  final DatasetRepository datasetRepository;
  final String _baseUrl = 'https://acecmg.github.io/kmon_serving';
  final http.Client _client = http.Client();

  SyncService(this.datasetRepository);

  /// Sincroniza o índice mestre com o servidor remoto na inicialização do aplicativo.
  /// 
  /// Se um novo índice estiver disponível, ele atualiza o cache local e aciona
  /// uma verificação de atualização em segundo plano para todos os picos baixados. Se o servidor estiver
  /// inacessível, ele reverte para o índice em cache local.
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

        // Sobrescreve o índice local com o novo
        await localIndiceFile.writeAsBytes(responseBytes);

        // Notifica o DatasetRepository que há um novo Índice carregado
        await datasetRepository.loadIndiceToMemory(newIndice);

        // Executa atualização em segundo plano para picos baixados anteriormente
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

  /// Carrega o índice do armazenamento local e notifica o repositório.
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

  /// Itera por todos os picos baixados e atualiza aqueles cujos checksums mudaram.
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
      final picoFile = File('${downloadsDir.path}/${newResumo.id}/${newResumo.id}.binarypb');
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

  /// Atualiza um único pico baixando seu novo binarypb e sincronizando suas imagens.
  Future<void> _updatePico(ResumoCroqui newResumo, Directory downloadsDir) async {
    final url = '$_baseUrl/${newResumo.url}';
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

      final newImages = { for (var ext in newPicoData.arquivosExternos) ext.caminho : ext.checksumSha256 };
      final newMarkdownImages = _extractMarkdownImages(newPicoData, baseDir);
      for (var path in newMarkdownImages) {
        newImages[path] = 'markdown_image'; // Evita a exclusão
      }

      for (var oldExt in oldPicoData.arquivosExternos) {
        bool shouldDelete = false;
        if (!newImages.containsKey(oldExt.caminho)) {
          shouldDelete = true;
        } else if (newImages[oldExt.caminho] != oldExt.checksumSha256 && newImages[oldExt.caminho] != 'markdown_image') {
          shouldDelete = true;
        }

        if (shouldDelete) {
          final oldImgFile = File('${picoDir.path}/${oldExt.caminho}');
          if (await oldImgFile.exists()) {
            await oldImgFile.delete();
            debugPrint('Deleted old image: ${oldExt.caminho}');
          }
        }
      }

      final oldMarkdownImages = _extractMarkdownImages(oldPicoData, baseDir);
      for (var path in oldMarkdownImages) {
        if (!newMarkdownImages.contains(path) && !newImages.containsKey(path)) {
          final oldImgFile = File('${picoDir.path}/$path');
          if (await oldImgFile.exists()) {
            await oldImgFile.delete();
            debugPrint('Deleted old markdown image: $path');
          }
        }
      }

      final oldImages = { for (var ext in oldPicoData.arquivosExternos) ext.caminho : ext.checksumSha256 };
      for (var newExt in newPicoData.arquivosExternos) {
        if (!oldImages.containsKey(newExt.caminho) || oldImages[newExt.caminho] != newExt.checksumSha256) {
          await _downloadImage(newExt.caminho, picoDir);
        }
      }

      for (var path in newMarkdownImages) {
        if (!oldMarkdownImages.contains(path)) {
          await _downloadImage(path, picoDir);
        }
      }
    }

    if (!await picoDir.exists()) {
      await picoDir.create(recursive: true);
    }
    await picoFile.writeAsBytes(response.bodyBytes);
    debugPrint('Updated pico ${newResumo.id} successfully.');
  }

  /// Baixa todos os arquivos externos associados a um determinado [Croqui].
  Future<void> downloadExternalFilesForCroqui(Croqui newPicoData, String picoId) async {
    final directory = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${directory.path}/downloads/$picoId');
    
    for (var ext in newPicoData.arquivosExternos) {
      await _downloadImage(ext.caminho, downloadsDir);
    }

    final newMarkdownImages = _extractMarkdownImages(newPicoData, '');
    for (var path in newMarkdownImages) {
      await _downloadImage(path, downloadsDir);
    }
  }

  Set<String> _extractMarkdownImages(Croqui croqui, String baseDir) {
    final Set<String> images = {};
    try {
      final jsonStr = jsonEncode(croqui.toProto3Json());
      final RegExp regex = RegExp(r'!\[.*?\]\((.*?)\)');
      final matches = regex.allMatches(jsonStr);
      for (final match in matches) {
        if (match.groupCount >= 1) {
          String path = match.group(1)!;
          if (!path.startsWith('http://') && !path.startsWith('https://')) {
            if (path.startsWith('./')) path = path.substring(2);
            if (path.startsWith('/')) path = path.substring(1);
            
            if (baseDir.isNotEmpty) {
              images.add('$baseDir/$path');
            } else {
              images.add(path);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing markdown images: $e');
    }
    return images;
  }

  /// Baixa uma imagem do servidor remoto.
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

  /// Fecha o cliente HTTP subjacente.
  void dispose() {
    _client.close();
  }
}
