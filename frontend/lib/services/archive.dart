import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import '../aresta_api/proto/generated/indice.pb.dart';

/// Serviço responsável por lidar com arquivos .croqui (ZIP ofuscados).
class ArchiveService {
  /// Inverte o primeiro byte do arquivo (XOR 0xFF) para ofuscar/desofuscar o cabeçalho ZIP.
  static Future<void> _toggleXOR(File file) async {
    final raf = await file.open(mode: FileMode.append);
    try {
      await raf.setPosition(0);
      final buffer = await raf.read(1);
      if (buffer.isNotEmpty) {
        final byteConsertado = buffer[0] ^ 0xFF;
        await raf.setPosition(0);
        await raf.writeByte(byteConsertado);
        await raf.flush();
      }
    } finally {
      await raf.close();
    }
  }

  /// Processa a importação de um arquivo .croqui (ZIP ofuscado)
  static Future<bool> processCroquiImport(File zipFile, String docsPath) async {
    try {
      final destinationDir = '$docsPath/editor/experimental';
      final editedDir = '$docsPath/edited';
      
      await Directory(destinationDir).create(recursive: true);
      await Directory(editedDir).create(recursive: true);

      final oldIndice = File('$destinationDir/indice.binarypb');
      if (await oldIndice.exists()) {
        await oldIndice.delete();
      }

      // Tenta extrair. O extractCroqui lida com a ofuscação internamente.
      final picoFolder = await extractCroqui(zipFile, destinationDir, onlyIndice: true);
      
      if (picoFolder != null) {
        String id;
        if (picoFolder == 'indice_only_success') {
          id = 'experimental_pico';
        } else {
          id = picoFolder;
        }

        // Salva o arquivo original (ofuscado) na pasta /edited/
        await zipFile.copy('$editedDir/$id.croqui');

        final existingIndice = File('$destinationDir/indice.binarypb');
        if (!await existingIndice.exists()) {
          await createTemporaryIndice(
            destinationDir, 
            id, 
            id.replaceAll('_', ' ').toUpperCase(), 
            '$id/$id.binarypb'
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.instance.logError('[ArchiveService] Erro no processamento', error: e);
      return false;
    }
  }

  /// Extrai um arquivo .croqui (ZIP ofuscado).
  static Future<String?> extractCroqui(File zipFile, String rootDir, {bool onlyIndice = false}) async {
    // 1. DESOFUSCAR CABEÇALHO (XOR INPLACE)
    await _toggleXOR(zipFile);

    try {
      final bytes = zipFile.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      String? picoFolderName;
      final downloadsDir = '$rootDir/downloads';
      bool foundIndice = false;

      for (final file in archive) {
        String fullPath = file.name;
        if (!fullPath.contains('compilado/')) continue;

        final int index = fullPath.indexOf('compilado/');
        if (index == -1) continue;

        String filename = fullPath.substring(index + 'compilado/'.length);
        if (filename.isEmpty) continue;

        if (filename == 'indice.binarypb' || filename == 'indice.yaml') {
          final data = file.content as List<int>;
          final outFile = File('$rootDir/$filename');
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(data);
          foundIndice = true;
          continue;
        }

        if (onlyIndice) continue;

        if (file.isFile) {
          final data = file.content as List<int>;
          String outFilename = filename;
          
          if (filename.endsWith('.binarypb') && filename.contains('/')) {
            final folder = filename.split('/').first;
            picoFolderName = folder;
            outFilename = '$folder/$folder.binarypb';
          }
          
          final outFile = File('$downloadsDir/$outFilename');
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(data);
        }
      }
      
      if (onlyIndice) {
        if (foundIndice) {
          if (picoFolderName != null) {
            return picoFolderName;
          } else {
            return 'experimental_pico';
          }
        } else {
          return null;
        }
      }
      return picoFolderName;
    } catch (e) {
      AppLogger.instance.logError('[ArchiveService] Erro ao extrair croqui', error: e);
      return null;
    } finally {
      // 2. RE-OFUSCAR CABEÇALHO (XOR INPLACE)
      await _toggleXOR(zipFile);
    }
  }

  static Future<void> createTemporaryIndice(String rootDir, String picoId, String picoName, String relativeUrl) async {
    final resumo = ResumoCroqui()
      ..id = picoId
      ..nome = picoName
      ..url = 'downloads/$relativeUrl'
      ..checksumSha256Croqui = 'experimental_mode';

    final indice = Indice()..croquis.add(resumo);
    final file = File('$rootDir/indice.binarypb');
    await file.writeAsBytes(indice.writeToBuffer());
  }
}
