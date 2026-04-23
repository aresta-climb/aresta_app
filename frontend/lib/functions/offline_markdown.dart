import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path_provider/path_provider.dart';
import 'package:markdown/markdown.dart' as md;

/// Um widget que renderiza conteúdo Markdown com suporte a imagens offline locais.
/// 
/// Ele resolve automaticamente caminhos de imagem relativos com o diretório
/// 'downloads' local do aplicativo.
class OfflineMarkdown extends StatelessWidget {
  /// A string markdown original a ser renderizada.
  final String data;
  final String cragId;

  const OfflineMarkdown({super.key, required this.data, required this.cragId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Directory>(
      future: getApplicationDocumentsDirectory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final downloadsPath = '${snapshot.data!.path}/downloads/$cragId';
        
        return MarkdownBody(
          data: data,
          extensionSet: md.ExtensionSet.gitHubFlavored,
          imageBuilder: (Uri uri, String? title, String? alt) {
            String path = Uri.decodeFull(uri.toString());
            
            String fileName = '';
            if (uri.pathSegments.isNotEmpty) {
              fileName = Uri.decodeFull(uri.pathSegments.last);
            } else {
              fileName = path.split('/').last;
            }

            File? localFile;
            
            // 1. Tenta mapear a URL do servidor conhecida diretamente para o caminho baixado
            const baseUrl = 'https://acecmg.github.io/kmon_serving/';
            String cleanUrl = Uri.decodeFull(uri.toString());
            if (cleanUrl.startsWith(baseUrl)) {
              final relativePath = cleanUrl.replaceFirst(baseUrl, '');
              final directFile = File('$downloadsPath/$relativePath');
              if (directFile.existsSync()) {
                localFile = directFile;
              }
            }
            
            // 2. Tenta usar o caminho diretamente como um caminho relativo
            if (localFile == null) {
               String cleanPath;
               if (path.startsWith('/')) {
                 cleanPath = path.substring(1);
               } else {
                 cleanPath = path;
               }
               
               final directFile = File('$downloadsPath/$cleanPath');
               if (directFile.existsSync()) {
                 localFile = directFile;
               }
            }

            // 3. Fallback: Procura pelo nome do arquivo recursivamente no diretório de downloads
            if (localFile == null && fileName.isNotEmpty) {
              final searchName = Uri.decodeComponent(fileName).toLowerCase();
              
              String searchBaseName;
              if (searchName.contains('.')) {
                searchBaseName = searchName.substring(0, searchName.lastIndexOf('.'));
              } else {
                searchBaseName = searchName;
              }

              try {
                final downloadsDir = Directory(downloadsPath);
                if (downloadsDir.existsSync()) {
                  final entities = downloadsDir.listSync(recursive: true);
                  for (var entity in entities) {
                    if (entity is File) {
                      final String ePath = entity.path.replaceAll('\\', '/');
                      final String eName = ePath.split('/').last;
                      final String eNameLower = Uri.decodeComponent(eName).toLowerCase();
                      
                      // Correspondência exata
                      if (eNameLower == searchName) {
                        localFile = entity;
                        break;
                      }
                      
                      // Corresponde ao nome base sem extensão (lida com incompatibilidades .webp vs .jpg)
                      String eBaseName;
                      if (eNameLower.contains('.')) {
                        eBaseName = eNameLower.substring(0, eNameLower.lastIndexOf('.'));
                      } else {
                        eBaseName = eNameLower;
                      }
                      
                      if (eBaseName == searchBaseName) {
                        localFile = entity;
                        break;
                      }
                    }
                  }
                }
              } catch (e) {
                // Ignora erros de travessia
              }
            }

            Widget buildZoomableImage(Image imageWidget) {
              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    useSafeArea: false,
                    builder: (context) => Scaffold(
                      backgroundColor: Colors.black,
                      body: Stack(
                        children: [
                          Positioned.fill(
                            child: InteractiveViewer(
                              maxScale: 5.0,
                              child: Image(
                                image: imageWidget.image,
                                fit: BoxFit.contain,
                                errorBuilder: imageWidget.errorBuilder,
                              ),
                            ),
                          ),
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 10,
                            right: 10,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 30),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: imageWidget,
              );
            }

            // Retorna o arquivo local se encontrado
            if (localFile != null && localFile.existsSync()) {
              return buildZoomableImage(Image.file(
                localFile,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.red),
              ));
            }
            
            // Fallback para a rede se for uma URL absoluta (apenas caso não tenha sido baixada)
            if (path.startsWith('http://') || path.startsWith('https://')) {
              return buildZoomableImage(Image.network(
                path,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
              ));
            }
            
            return const Icon(Icons.broken_image, color: Colors.grey);
          },
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(color: Colors.white70, fontSize: 16),
            h1: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            h2: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            h3: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}
