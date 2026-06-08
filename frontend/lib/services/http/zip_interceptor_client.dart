import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

class ZipInterceptorClient extends http.BaseClient {
  final http.Client _inner;

  ZipInterceptorClient([http.Client? inner]) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.scheme == 'aresta-zip') {
      try {
        final pathStr = request.url.path; // ex: /caminho/para/repo.croqui/compilado/indice.binarypb
        
        int splitIndex = pathStr.indexOf('.croqui');
        int extensionLength = 7;
        bool isCroqui = true;

        if (splitIndex == -1) {
          splitIndex = pathStr.indexOf('.zip');
          extensionLength = 4;
          isCroqui = false;
        }

        if (splitIndex != -1) {
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
            if (bytes.isNotEmpty && isCroqui) {
              // Desofusca o cabeçalho apenas se for .croqui
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
