import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../dataset_repository.dart';
import 'ambient_p2p_service.dart';

class P2PTransferManager {
  static final P2PTransferManager instance = P2PTransferManager._internal();

  P2PTransferManager._internal();

  // Escuta os chunks recebidos
  StreamSubscription? _dataSubscription;

  // Mapa para reconstruir arquivos sendo recebidos
  // Formato: { "cragId": { "totalChunks": 10, "chunks": {0: "...", 1: "..."} } }
  final Map<String, _ReceivingFile> _receivingFiles = {};

  void init() {
    // Registra listener no AmbientP2PService
    _dataSubscription = AmbientP2PService.instance.nearbyService.dataReceivedSubscription(callback: handleDataReceived);
  }

  @visibleForTesting
  void handleDataReceived(dynamic data) {
    try {
      final Map<String, dynamic> payload = jsonDecode(data['message']);
      
      if (payload['type'] == 'P2P_TRANSFER_REQUEST') {
        _handleTransferRequest(data['senderDeviceId'] ?? 'unknown', payload['cragId']);
      } else if (payload['type'] == 'P2P_FILE_CHUNK') {
        _handleChunkReceived(payload);
      }
    } catch (e) {
      // Ignora pacotes de outras naturezas (ex: AVAILABLE_CRAGS)
    }
  }

  Future<void> requestCragFromPeer(String cragId) async {
    // Acha qual peer conectado tem esse cragId
    // Em um cenário real, se tiver vários, pega o primeiro
    // Como a UI sabe qual peer tem? O AmbientP2PService só diz que ALGUÉM tem.
    // Vamos fazer um broadcast de request. Quem tiver, manda.
    final requestMsg = jsonEncode({
      'type': 'P2P_TRANSFER_REQUEST',
      'cragId': cragId
    });

    for (var deviceId in AmbientP2PService.instance.connectedDevices.keys) {
      AmbientP2PService.instance.nearbyService.sendMessage(deviceId, requestMsg);
    }
  }

  Future<void> _handleTransferRequest(String requesterDeviceId, String cragId) async {
    // 1. Checa se nós temos o cragId Oficial e se estamos no modo oficial
    final isExperimental = DatasetRepository.instance!.editorDeCroqui.isExperimentalMode.value;
    if (isExperimental) return;
    
    final downloaded = DatasetRepository.instance!.activeDataset.value?.downloadedPicos ?? [];
    if (!downloaded.any((d) => d['id'] == cragId)) return; // Não temos

    // 2. Empacota a pasta do pico oficial em um zip
    final docsDir = await getApplicationDocumentsDirectory();
    final downloadsPath = DatasetRepository.instance!.editorDeCroqui.downloadsPath(docsDir.path);
    final cragDir = Directory(p.join(downloadsPath, cragId));
    
    if (!cragDir.existsSync()) return;

    var encoder = ZipFileEncoder();
    final tempZipPath = p.join(Directory.systemTemp.path, 'p2p_export_\$cragId.croqui');
    encoder.create(tempZipPath);
    encoder.addDirectory(cragDir, includeDirName: false);
    encoder.close();

    final zipBytes = await File(tempZipPath).readAsBytes();
    
    // 3. Envia em chunks (128 KB)
    final chunkSize = 128 * 1024; 
    final base64Data = base64Encode(zipBytes);
    final totalChunks = (base64Data.length / chunkSize).ceil();

    for (int i = 0; i < totalChunks; i++) {
      final start = i * chunkSize;
      final end = (start + chunkSize < base64Data.length) ? start + chunkSize : base64Data.length;
      final chunkStr = base64Data.substring(start, end);

      final chunkMsg = jsonEncode({
        'type': 'P2P_FILE_CHUNK',
        'cragId': cragId,
        'index': i,
        'total': totalChunks,
        'data': chunkStr,
      });

      AmbientP2PService.instance.nearbyService.sendMessage(requesterDeviceId, chunkMsg);
      // Pequeno delay para não entupir a Platform Channel bridge
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Limpa temp
    File(tempZipPath).deleteSync();
  }

  void _handleChunkReceived(Map<String, dynamic> payload) async {
    final cragId = payload['cragId'] as String;
    final index = payload['index'] as int;
    final total = payload['total'] as int;
    final data = payload['data'] as String;

    if (!_receivingFiles.containsKey(cragId)) {
      _receivingFiles[cragId] = _ReceivingFile(total);
    }

    final receiving = _receivingFiles[cragId]!;
    receiving.chunks[index] = data;

    // TODO: Emitir progresso para a UI (LinearProgressIndicator)
    // Progress: receiving.chunks.length / total

    if (receiving.chunks.length == total) {
      // Arquivo recebido completamente!
      await _assembleAndExtractCrag(cragId, receiving);
      _receivingFiles.remove(cragId);
    }
  }

  Future<void> _assembleAndExtractCrag(String cragId, _ReceivingFile receiving) async {
    // 1. Junta os chunks em base64 e decodifica
    final buffer = StringBuffer();
    for (int i = 0; i < receiving.totalChunks; i++) {
      buffer.write(receiving.chunks[i]);
    }
    final zipBytes = base64Decode(buffer.toString());

    // 2. Extrai na pasta oficial (Downloads)
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final docsDir = await getApplicationDocumentsDirectory();
    final downloadsPath = DatasetRepository.instance!.editorDeCroqui.downloadsPath(docsDir.path);
    final targetDir = Directory(p.join(downloadsPath, cragId));
    
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        File(p.join(targetDir.path, filename))
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory(p.join(targetDir.path, filename)).createSync(recursive: true);
      }
    }

    // TODO: Adicionar lógica para garantir que bate com o Índice Oficial
    // Por enquanto, apenas atualiza o banco local do DatasetRepository recarregando o índice
    await DatasetRepository.instance!.init();
  }

  void dispose() {
    _dataSubscription?.cancel();
  }
}

class _ReceivingFile {
  final int totalChunks;
  final Map<int, String> chunks = {};
  _ReceivingFile(this.totalChunks);
}
