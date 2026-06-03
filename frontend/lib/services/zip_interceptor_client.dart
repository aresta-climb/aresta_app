import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

class ZipInterceptorClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.scheme == 'aresta-zip') {
      try {
        final pathStr = request.url.path; // ex: /caminho/para/repo.croqui/compilado/indice.binarypb
        
        // Encontra onde o .croqui ou .zip termina para separar o caminho do arquivo do caminho interno do zip
        int splitIndex = pathStr.indexOf('.croqui');
        if (splitIndex == -1) {
          splitIndex = pathStr.indexOf('.zip');
        }

        if (splitIndex != -1) {
          final extensionLength = pathStr.substring(splitIndex).startsWith('.croqui') ? 7 : 4;
          final zipFilePath = Uri.decodeComponent(pathStr.substring(0, splitIndex + extensionLength));
          
          // Correção para caminhos absolutos no Windows se necessário (ex: /C:/...)
          String actualZipPath = zipFilePath;
          if (Platform.isWindows && actualZipPath.startsWith('/') && actualZipPath.length > 2 && actualZipPath[2] == ':') {
             actualZipPath = actualZipPath.substring(1);
          }

          final internalPath = Uri.decodeComponent(pathStr.substring(splitIndex + extensionLength));
          
          String cleanInternalPath = internalPath;
          if (cleanInternalPath.startsWith('/')) {
            cleanInternalPath = cleanInternalPath.substring(1);
          }
          
          // No modo experimental, os arquivos geralmente estão dentro de "compilado/"
          if (!cleanInternalPath.startsWith('compilado/') && cleanInternalPath.isNotEmpty) {
             cleanInternalPath = 'compilado/$cleanInternalPath';
          }

          final zipFile = File(actualZipPath);
          if (zipFile.existsSync()) {
            final bytes = zipFile.readAsBytesSync();
            if (bytes.isNotEmpty && zipFilePath.endsWith('.croqui')) {
              // Desofusca o cabeçalho
              bytes[0] = bytes[0] ^ 0xFF;
            }
            
            final archive = ZipDecoder().decodeBytes(bytes);
            
            // Mapeia o arquivo solicitado
            for (final file in archive) {
               if (file.name == cleanInternalPath) {
                  final data = file.content as List<int>;
                  return http.StreamedResponse(
                    Stream.value(data),
                    200,
                  );
               }
            }
            
            // Se não for encontrado, retorna 404
            return http.StreamedResponse(Stream.empty(), 404);
          }
        }
        
        return http.StreamedResponse(Stream.empty(), 404);
      } catch (e) {
        return http.StreamedResponse(Stream.empty(), 500);
      }
    }

    return _inner.send(request);
  }
}
