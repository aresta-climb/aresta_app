import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../../aresta_api/proto/generated/indice.pb.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';

/// Gerencia o armazenamento local de arquivos para sincronização,
/// ocultando os detalhes de I/O do SyncService.
class SyncStorage {
  /// Lê o arquivo de índice mestre do armazenamento local.
  /// 
  /// Retorna o objeto [Indice] populado se o arquivo existir, 
  /// caso contrário, retorna nulo.
  Future<Indice?> readLocalIndice(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      return Indice.fromBuffer(bytes);
    }
    return null;
  }

  /// Salva os bytes do índice no arquivo local especificado, 
  /// criando a estrutura de diretórios caso necessário.
  Future<void> writeLocalIndice(String filePath, Uint8List bytes) async {
    final file = File(filePath);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsBytes(bytes);
  }

  /// Lê o conteúdo do ETag em cache do arquivo local.
  /// 
  /// Usado para cache condicional HTTP. Retorna nulo se o arquivo não existir.
  Future<String?> readETag(String etagPath) async {
    final file = File(etagPath);
    if (await file.exists()) {
      return await file.readAsString();
    }
    return null;
  }

  /// Grava o valor do ETag no arquivo especificado.
  Future<void> writeETag(String etagPath, String etag) async {
    final file = File(etagPath);
    await file.writeAsString(etag);
  }

  /// Remove o arquivo local que armazena o ETag, se ele existir.
  Future<void> deleteETag(String etagPath) async {
    final file = File(etagPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Lê um arquivo `.binarypb` de um Croqui específico.
  /// 
  /// Retorna o objeto [Croqui] se o arquivo existir, nulo caso contrário.
  Future<Croqui?> readLocalCroqui(String croquiPath) async {
    final file = File(croquiPath);
    if (await file.exists()) {
      return Croqui.fromBuffer(await file.readAsBytes());
    }
    return null;
  }

  /// Salva bytes crus em um arquivo temporário.
  ///
  /// Garante que o diretório pai existe antes de iniciar a gravação.
  Future<void> saveTmpFile(String tmpPath, Uint8List bytes) async {
    final file = File(tmpPath);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsBytes(bytes);
  }

  /// Deleta um arquivo e retorna se a operação apagou um arquivo que existia.
  Future<bool> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  /// Renomeia um arquivo de [oldPath] para [newPath].
  ///
  /// Retorna verdadeiro se a renomeação for bem-sucedida.
  Future<bool> renameFile(String oldPath, String newPath) async {
    final file = File(oldPath);
    if (await file.exists()) {
      await file.rename(newPath);
      return true;
    }
    return false;
  }

  /// Verifica se um arquivo `.tmp` existente é válido baseado num hash SHA-256 esperado.
  ///
  /// Se [expectedSha256Hash] for vazio ou se o hash do arquivo não bater, o arquivo é deletado
  /// e o método retorna `false`. Se o hash bater perfeitamente, retorna `true`.
  Future<bool> validateExistingTmpFile(String tmpPath, String expectedSha256Hash) async {
    final file = File(tmpPath);
    if (!await file.exists()) return false;
    
    if (expectedSha256Hash.isEmpty) {
      await file.delete();
      return false;
    }

    final stream = file.openRead();
    final hashResult = await sha256.bind(stream).first;
    if (hashResult.toString() == expectedSha256Hash) {
      return true;
    } else {
      await file.delete();
      return false;
    }
  }


  /// Aplica a deleção e o rename atômico de arquivos de forma robusta e unificada.
  ///
  /// [filesToRename] é um mapa onde a chave (key) é o caminho temporário original
  /// e o valor (value) é o caminho final do arquivo atualizado.
  Future<void> applyAtomicFileUpdates({
    required List<String> filesToDelete,
    required Map<String, String> filesToRename,
  }) async {
    // 1. Substituir os originais pelos temporários
    for (var entry in filesToRename.entries) {
      final tmpFile = File(entry.key);
      final finalFile = File(entry.value);
      
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      if (await tmpFile.exists()) {
        await tmpFile.rename(finalFile.path);
      }
    }

    // 2. Deletar os arquivos não mais utilizados
    for (var path in filesToDelete) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted old file: $path');
      }
    }
  }
}
