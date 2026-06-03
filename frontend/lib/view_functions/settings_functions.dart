import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:path_provider/path_provider.dart';
import '../services/dataset_repository.dart';
import '../services/editor_croqui.dart';
import '../view_functions/common_functions.dart';
import '../pages/qr_scanner.dart';
import '../services/sync_service.dart';
import '../services/zip_interceptor_client.dart';

/// Tenta conectar ao repositório do editor validando a URL fornecida.
Future<bool> conectarEditor(
  BuildContext context, 
  DatasetRepository datasetRepo,
  EditorDeCroqui configService, 
  String url,
) async {
  if (url.isEmpty) return false;

  try {
    // Valida se o índice está acessível na subpasta "compilado/" (layout padrão do repo de serving)
    String checkUrl = url;
    if (checkUrl.endsWith('/')) {
      checkUrl = checkUrl.substring(0, checkUrl.length - 1);
    }
    
    final client = ZipInterceptorClient();
    final resolvedUrl = '$checkUrl/compilado';
    final response = await client
        .get(Uri.parse('$resolvedUrl/indice.binarypb'))
        .timeout(const Duration(seconds: 5));
    
    if (response.statusCode == 200) {
      if (url.toLowerCase().endsWith('.croqui.zip') || url.toLowerCase().endsWith('.croqui')) {
        final directory = await getApplicationDocumentsDirectory();
        
        final editedDir = Directory('${directory.path}/edited');
        if (!await editedDir.exists()) {
          await editedDir.create(recursive: true);
        }
        final safeName = 'imported_repo.croqui';
        final savedFile = File('${editedDir.path}/$safeName');
        
        // Busca o binário zip real se for uma URL remota
        if (!url.startsWith('aresta-zip')) {
           final zipResponse = await client.get(Uri.parse(url));
           await savedFile.writeAsBytes(zipResponse.bodyBytes);
        } else {
           // Se já for uma URL aresta-zip local, usamos diretamente
        }
        
        final ghostUrl = url.startsWith('aresta-zip') ? url : 'aresta-zip://${savedFile.path}';
        await configService.activateExperimental(url: ghostUrl, forceResetTimer: true);
        
        final syncService = SyncService(datasetRepo);
        await syncService.syncOnLaunch();
        await datasetRepo.init();
        return true;
      }
      
      await configService.connect(resolvedUrl);
      await datasetRepo.init();
      return true;
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: Não foi possível acessar o índice (Status ${response.statusCode})')),
        );
      }
      return false;
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão: Verifique a URL')),
      );
    }
    return false;
  }
}

/// Permite ao usuário selecionar e importar um arquivo .croqui local.
Future<void> importarArquivoCroqui(BuildContext context, DatasetRepository datasetRepo) async {
  final EditorDeCroqui configService = datasetRepo.editorDeCroqui;
  
  try {
    final fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['croqui'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final directory = await getApplicationDocumentsDirectory();
      
      // Feedback visual de processamento
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Processando arquivo...'), duration: Duration(seconds: 1)),
        );
      }

      final editedDir = Directory('${directory.path}/edited');
      if (!await editedDir.exists()) {
        await editedDir.create(recursive: true);
      }
      final safeName = 'imported_repo.croqui';
      final savedFile = await file.copy('${editedDir.path}/$safeName');
      
      final ghostUrl = 'aresta-zip://${savedFile.path}';
      
      await configService.activateExperimental(url: ghostUrl, forceResetTimer: true);
      
      // Tenta sincronizar o índice usando o interceptor
      final syncService = SyncService(datasetRepo);
      await syncService.syncOnLaunch();
      await datasetRepo.init();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Croqui experimental importado!')),
        );
      }
    }
  } catch (e) {
    debugPrint('[Import] Erro ao selecionar arquivo: $e');
  }
}

/// Exibe o diálogo para inserir a URL do repositório do editor.
void mostrarDialogConexao(BuildContext context, DatasetRepository datasetRepo, {String? titulo}) {
  final EditorDeCroqui configService = datasetRepo.editorDeCroqui;
  // Pré-preenche com a URL atual se existir, caso contrário começa vazio
  final TextEditingController urlController = TextEditingController(text: configService.editorUrl.value ?? '');
  bool isLoading = false;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: nobleBlack,
            title: Text(
              titulo ?? 'Conectar como editor', 
              style: TextStyle(color: beastHide, fontSize: 18),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Insira a URL do repositório experimental para testar novos croquis.',
                  style: TextStyle(color: fishBone),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  style: TextStyle(color: fishBone),
                  decoration: InputDecoration(
                    hintText: 'ex: aresta-climb.github.io/aresta_serving',
                    hintStyle: TextStyle(color: fishBone.withValues(alpha: 0.5), fontSize: 13),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: mossRock),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: beastHide),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.qr_code_scanner, color: beastHide),
                    label: Text('Escanear QR Code', style: TextStyle(color: beastHide)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: beastHide),
                    ),
                    onPressed: () async {
                      final scannedUrl = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const QRScannerPage()),
                      );
                      if (scannedUrl != null && scannedUrl is String) {
                        urlController.text = scannedUrl;
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.file_present, color: beastHide),
                    label: Text('Importar .croqui local', style: TextStyle(color: beastHide)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: beastHide),
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop(); // Fecha o diálogo antes
                      await importarArquivoCroqui(context, datasetRepo);
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (isLoading) {
                    return;
                  }
                  Navigator.of(context).pop();
                },
                child: Text('Cancelar', style: TextStyle(color: fishBone.withValues(alpha: 0.7))),
              ),
              Builder(
                builder: (context) {
                  VoidCallback? onConnect;
                  if (isLoading) {
                    onConnect = null;
                  } else {
                    onConnect = () async {
                      final url = urlController.text.trim();
                      if (url.isEmpty) return;

                      setDialogState(() => isLoading = true);
                      
                      final success = await conectarEditor(context, datasetRepo, configService, url);
                      
                      if (context.mounted) {
                        setDialogState(() => isLoading = false);
                        if (success) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Conectado ao repositório editor!')),
                          );
                        }
                      }
                    };
                  }

                  Widget buttonChild;
                  if (isLoading) {
                    buttonChild = SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(color: nobleBlack, strokeWidth: 2)
                    );
                  } else {
                    buttonChild = Text('Conectar', style: TextStyle(color: nobleBlack, fontWeight: FontWeight.bold));
                  }

                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: beastHide,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: onConnect,
                    child: buttonChild,
                  );
                }
              ),
            ],
          );
        },
      );
    },
  );
}

