import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/http/sync_storage.dart';

void main() {
  late SyncStorage storage;
  late Directory tempDir;

  setUp(() {
    storage = SyncStorage();
    tempDir = Directory.systemTemp.createTempSync('sync_storage_test');
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('SyncStorage - Indice', () {
    test('readLocalIndice retorna null se arquivo nao existe', () async {
      final result = await storage.readLocalIndice('${tempDir.path}/inexistente.binarypb');
      expect(result, isNull);
    });

    test('readLocalIndice retorna Indice quando arquivo existe e eh valido', () async {
      final indice = Indice()..croquis.add(ResumoCroqui()..id = '123');
      final path = '${tempDir.path}/indice.binarypb';
      await File(path).writeAsBytes(indice.writeToBuffer());

      final result = await storage.readLocalIndice(path);
      expect(result, isNotNull);
      expect(result!.croquis.first.id, '123');
    });

    test('writeLocalIndice cria o diretorio pai caso nao exista e escreve o arquivo', () async {
      final path = '${tempDir.path}/subdir/novo_indice.binarypb';
      final indice = Indice()..croquis.add(ResumoCroqui()..id = '321');
      
      await storage.writeLocalIndice(path, indice.writeToBuffer());
      
      final file = File(path);
      expect(await file.exists(), isTrue);
      
      final readIndice = Indice.fromBuffer(await file.readAsBytes());
      expect(readIndice.croquis.first.id, '321');
    });
  });

  group('SyncStorage - ETag', () {
    test('readETag retorna string se existir', () async {
      final path = '${tempDir.path}/file.etag';
      await File(path).writeAsString('my_etag');
      
      final result = await storage.readETag(path);
      expect(result, 'my_etag');
    });

    test('readETag retorna null se nao existir', () async {
      final result = await storage.readETag('${tempDir.path}/none.etag');
      expect(result, isNull);
    });

    test('writeETag escreve string corretamente', () async {
      final path = '${tempDir.path}/write.etag';
      await storage.writeETag(path, 'new_etag');
      
      final content = await File(path).readAsString();
      expect(content, 'new_etag');
    });

    test('deleteETag exclui o arquivo se existir', () async {
      final path = '${tempDir.path}/delete.etag';
      await File(path).writeAsString('to_delete');
      expect(await File(path).exists(), isTrue);
      
      await storage.deleteETag(path);
      expect(await File(path).exists(), isFalse);
    });

    test('deleteETag nao lanca erro se arquivo nao existir', () async {
      final path = '${tempDir.path}/no_delete.etag';
      await expectLater(storage.deleteETag(path), completes);
    });
  });

  group('SyncStorage - readLocalCroqui', () {
    test('readLocalCroqui retorna null se nao existe', () async {
      final result = await storage.readLocalCroqui('${tempDir.path}/nao_existe.binarypb');
      expect(result, isNull);
    });

    test('readLocalCroqui retorna Croqui se arquivo for valido', () async {
      final path = '${tempDir.path}/croqui_valido.binarypb';
      final croqui = Croqui()..arquivosExternos.add(ArquivoExterno()..caminho = 'test');
      await File(path).writeAsBytes(croqui.writeToBuffer());

      final result = await storage.readLocalCroqui(path);
      expect(result, isNotNull);
      expect(result!.arquivosExternos.first.caminho, 'test');
    });
  });

  group('SyncStorage - Operacoes de Arquivo', () {
    test('saveTmpFile salva bytes e cria diretorio pai se necessario', () async {
      final path = '${tempDir.path}/nested/file.tmp';
      await storage.saveTmpFile(path, Uint8List.fromList([1, 2, 3]));
      
      final file = File(path);
      expect(await file.exists(), isTrue);
      expect(await file.readAsBytes(), [1, 2, 3]);
    });

    test('deleteFile deleta arquivo e retorna true', () async {
      final path = '${tempDir.path}/to_delete.txt';
      await File(path).writeAsString('txt');
      
      final result = await storage.deleteFile(path);
      expect(result, isTrue);
      expect(await File(path).exists(), isFalse);
    });

    test('deleteFile retorna false se arquivo nao existir', () async {
      final path = '${tempDir.path}/missing.txt';
      final result = await storage.deleteFile(path);
      expect(result, isFalse);
    });

    test('renameFile renomeia arquivo e retorna true', () async {
      final oldPath = '${tempDir.path}/old.txt';
      final newPath = '${tempDir.path}/new.txt';
      await File(oldPath).writeAsString('txt');
      
      final result = await storage.renameFile(oldPath, newPath);
      expect(result, isTrue);
      expect(await File(oldPath).exists(), isFalse);
      expect(await File(newPath).exists(), isTrue);
    });

    test('renameFile retorna false se arquivo nao existir', () async {
      final oldPath = '${tempDir.path}/old_missing.txt';
      final newPath = '${tempDir.path}/new.txt';
      
      final result = await storage.renameFile(oldPath, newPath);
      expect(result, isFalse);
    });
  });

  group('SyncStorage - validateExistingTmpFile', () {
    test('validateExistingTmpFile retorna false se nao existir', () async {
      final result = await storage.validateExistingTmpFile('${tempDir.path}/nao_existe.tmp', 'hash');
      expect(result, isFalse);
    });

    test('validateExistingTmpFile deleta e retorna false se expectedHash for vazio', () async {
      final path = '${tempDir.path}/empty_hash.tmp';
      await File(path).writeAsBytes([1, 2, 3]);
      
      final result = await storage.validateExistingTmpFile(path, '');
      expect(result, isFalse);
      expect(await File(path).exists(), isFalse);
    });

    test('validateExistingTmpFile retorna true se hash bater', () async {
      final path = '${tempDir.path}/valid.tmp';
      final bytes = [10, 20, 30];
      await File(path).writeAsBytes(bytes);
      final expectedHash = sha256.convert(bytes).toString();
      
      final result = await storage.validateExistingTmpFile(path, expectedHash);
      expect(result, isTrue);
      expect(await File(path).exists(), isTrue); // nao deve ter deletado
    });

    test('validateExistingTmpFile deleta e retorna false se hash nao bater', () async {
      final path = '${tempDir.path}/invalid.tmp';
      final bytes = [10, 20, 30];
      await File(path).writeAsBytes(bytes);
      
      final result = await storage.validateExistingTmpFile(path, 'hash_errado');
      expect(result, isFalse);
      expect(await File(path).exists(), isFalse); // deve ter deletado
    });

  });

  group('SyncStorage - applyAtomicFileUpdates', () {
    test('renomeia arquivos e deleta os que devem ser deletados', () async {
      final tmpFile1 = '${tempDir.path}/file1.tmp';
      final originalFile1 = '${tempDir.path}/file1.txt';
      final tmpFile2 = '${tempDir.path}/file2.tmp'; // Arquivo sem .txt original anterior
      final originalFile2 = '${tempDir.path}/file2.txt';
      
      final toDeletePath = '${tempDir.path}/delete_me.txt';

      // Setup
      await File(originalFile1).writeAsString('old_content');
      await File(tmpFile1).writeAsString('new_content_1');
      await File(tmpFile2).writeAsString('new_content_2');
      await File(toDeletePath).writeAsString('delete_content');

      await storage.applyAtomicFileUpdates(
        filesToDelete: [toDeletePath, '${tempDir.path}/already_missing.txt'],
        filesToRename: {
          tmpFile1: originalFile1,
          tmpFile2: originalFile2,
          '${tempDir.path}/missing.tmp': '${tempDir.path}/missing.txt',
        },
      );

      // Verify renames
      expect(await File(tmpFile1).exists(), isFalse);
      expect(await File(originalFile1).readAsString(), 'new_content_1');
      
      expect(await File(tmpFile2).exists(), isFalse);
      expect(await File(originalFile2).readAsString(), 'new_content_2');

      // Verify deletion
      expect(await File(toDeletePath).exists(), isFalse);
    });
  });
}
