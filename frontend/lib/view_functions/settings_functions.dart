import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:path_provider/path_provider.dart';
import '../services/dataset_repository.dart';
import '../services/editor_croqui.dart';
import '../view_functions/common_functions.dart';
import '../pages/qr_scanner.dart';
import '../services/http/sync_service.dart';
import '../services/http/zip_interceptor_client.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../theme/theme_controller.dart';
import '../theme/app_colors.dart';

/// Normaliza a URL do editor, garantindo scheme correto e removendo formatações espúrias (ex: de QR Codes).
@visibleForTesting
String normalizeEditorUrl(String rawUrl) {
  String checkUrl = rawUrl.trim();
  if (checkUrl.isEmpty) return checkUrl;
  
  final lowerUrl = checkUrl.toLowerCase();
  if (!lowerUrl.startsWith('http://') && !lowerUrl.startsWith('https://') && !lowerUrl.startsWith('aresta-zip://')) {
    if (lowerUrl.startsWith('192.168.') || lowerUrl.startsWith('10.') || lowerUrl.startsWith('127.') || lowerUrl.startsWith('localhost')) {
      checkUrl = 'http://$checkUrl';
    } else {
      checkUrl = 'https://$checkUrl';
    }
  }
  
  if (checkUrl.endsWith('/')) {
    checkUrl = checkUrl.substring(0, checkUrl.length - 1);
  }
  
  return checkUrl;
}

/// Tenta conectar ao repositório do editor validando a URL fornecida.
Future<bool> conectarEditor(
  BuildContext context, 
  DatasetRepository datasetRepo,
  EditorDeCroqui configService, 
  String url,
) async {
  if (url.isEmpty) return false;

  try {
    // Valida se o índice está acessível na URL fornecida
    String checkUrl = normalizeEditorUrl(url);
    
    if (checkUrl.toLowerCase().endsWith('.zip')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aviso: Arquivos .zip não são mais suportados. Use .croqui')),
        );
      }
      return false;
    }
    
    final client = ZipInterceptorClient();
    
    // Se for um arquivo Croqui, precisamos baixar o arquivo inteiro primeiro
    if (checkUrl.toLowerCase().endsWith('.croqui')) {
      final directory = await getApplicationDocumentsDirectory();
      final editedDir = Directory('${directory.path}/edited');
      if (!await editedDir.exists()) {
        await editedDir.create(recursive: true);
      }
      
      final safeName = 'imported_repo.croqui';
      final savedFile = File('${editedDir.path}/$safeName');
      
      // Busca o binário zip real se for uma URL remota
      if (!checkUrl.startsWith('aresta-zip')) {
         // Opcional: mostrar um SnackBar de "Baixando croqui..." aqui seria bom
         final zipResponse = await client.get(Uri.parse(checkUrl)).timeout(const Duration(seconds: 30));
         if (zipResponse.statusCode != 200) {
           throw Exception('Falha ao baixar arquivo .croqui (Status ${zipResponse.statusCode})');
         }
         await savedFile.writeAsBytes(zipResponse.bodyBytes);
      }
      
      final ghostUrl = checkUrl.startsWith('aresta-zip') ? checkUrl : Uri.file(savedFile.path).toString().replaceFirst('file://', 'aresta-zip://');
      
      // Agora validamos se o zip que baixamos tem um índice válido dentro dele!
      final zipTestResponse = await client.get(Uri.parse('$ghostUrl/indice.binarypb')).timeout(const Duration(seconds: 5));
      if (zipTestResponse.statusCode != 200) {
         throw Exception('O arquivo .croqui baixado é inválido ou está corrompido.');
      }
      
      await configService.activateExperimental(url: ghostUrl, forceResetTimer: false);
      
      final syncService = SyncService(datasetRepository: datasetRepo);
      await syncService.syncIndex();
      await datasetRepo.init();
      TelemetryService.instance.logAcaoConfiguracoes('conectar_editor_zip');
      return true;
    } else {
      // Se não for ZIP, é um repositório web normal. Validamos o índice remoto.
      final resolvedUrl = checkUrl;
      final response = await client
          .get(Uri.parse('$resolvedUrl/indice.binarypb'))
          .timeout(const Duration(seconds: 5));
          
      if (response.statusCode == 200) {
        
        await configService.activateExperimental(url: resolvedUrl, forceResetTimer: false);
        final syncService = SyncService(datasetRepository: datasetRepo);
        await syncService.syncIndex();
        await datasetRepo.init();
        TelemetryService.instance.logAcaoConfiguracoes('conectar_editor_url');
        return true;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: Não foi possível acessar o índice (Status ${response.statusCode})')),
          );
        }
        return false;
      }
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
      type: fp.FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      if (!path.toLowerCase().endsWith('.croqui')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aviso: O arquivo selecionado não tem a extensão .croqui')),
          );
        }
        return;
      }
      final file = File(path);
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
      
      final ghostUrl = Uri.file(savedFile.path).toString().replaceFirst('file://', 'aresta-zip://');
      
      // Valida se o croqui que importamos é válido e pode ser lido
      final client = ZipInterceptorClient();
      final zipTestResponse = await client.get(Uri.parse('$ghostUrl/indice.binarypb')).timeout(const Duration(seconds: 5));
      if (zipTestResponse.statusCode != 200) {
         if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Erro: O arquivo .croqui importado não é válido ou está corrompido.')),
           );
         }
         return;
      }
      
      await configService.activateExperimental(url: ghostUrl, forceResetTimer: false);
      
      // Tenta sincronizar o índice usando o interceptor
      final syncService = SyncService(datasetRepository: datasetRepo);
      await syncService.syncIndex();
      await datasetRepo.init();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Croqui experimental importado!')),
        );
        TelemetryService.instance.logAcaoConfiguracoes('importar_arquivo_croqui');
      }
    }
  } catch (e) {
    debugPrint('[Import] Erro ao selecionar arquivo: $e');
  }
}

/// Exibe o diálogo para inserir a URL do repositório do editor.
void mostrarDialogConexao(BuildContext context, DatasetRepository datasetRepo, {String? titulo}) {
  final EditorDeCroqui configService = datasetRepo.editorDeCroqui;
  // Inicia vazio, pois a URL atual já é exibida na interface de configurações
  final TextEditingController urlController = TextEditingController();
  bool isLoading = false;
  final brandColor = const Color(0xFFC04F34);

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: context.colors.caveShadow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: context.colors.graniteEdge),
            ),
            title: Column(
              children: [
                Icon(Icons.link, color: brandColor, size: 32),
                const SizedBox(height: 8),
                Text(
                  titulo ?? 'Conectar Editor', 
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                Text(
                  'Insira a URL do repositório experimental para testar novos croquis.',
                  style: TextStyle(color: context.colors.ashGrey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    hintText: 'ex: serving.arestaclimb.com/v4',
                    hintStyle: TextStyle(color: context.colors.ashGrey.withValues(alpha: 0.5), fontSize: 13),
                    filled: true,
                    fillColor: context.colors.deepBasalt,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: context.colors.graniteEdge),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: brandColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.qr_code_scanner, color: brandColor, size: 20),
                    label: Text('ESCANEAR QR CODE', style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: brandColor.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      TelemetryService.instance.logAcaoConfiguracoes('abrir_qr_scanner');
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
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.file_present, color: context.colors.ashGrey, size: 20),
                    label: Text('IMPORTAR .CROQUI', style: TextStyle(color: context.colors.ashGrey, fontWeight: FontWeight.bold, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.colors.graniteEdge),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop(); // Fecha o diálogo antes
                      await importarArquivoCroqui(context, datasetRepo);
                    },
                  ),
                ),
              ],
            ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8, right: 8),
                child: TextButton(
                  onPressed: () {
                    if (isLoading) {
                      return;
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text('CANCELAR', style: TextStyle(color: context.colors.ashGrey, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
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
                    buttonChild = const SizedBox(
                      height: 16, 
                      width: 16, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    );
                  } else {
                    buttonChild = const Text('CONECTAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12));
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8, right: 8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: onConnect,
                      child: buttonChild,
                    ),
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


Widget buildEditorCard({
  required BuildContext context,
  required DatasetRepository datasetRepo,
  required int clickCount,
  required Function(int) onSetClickCount,
}) {
  final configService = datasetRepo.editorDeCroqui;

  return ValueListenableBuilder<bool>(
    valueListenable: configService.isExperimentalMode,
    builder: (context, isExperimental, _) {
      return ValueListenableBuilder<String?>(
        valueListenable: configService.editorUrl,
        builder: (context, activeUrl, _) {
          final isEditor = isExperimental;

          return ValueListenableBuilder<bool>(
            valueListenable: configService.isDevModeEnabled,
            builder: (context, isDevMode, _) {
              IconData statusIcon;
              String statusLabel;
              String description;
              String buttonText;

              if (isEditor) {
                statusIcon = Icons.science;
                statusLabel = 'MODO EXPERIMENTAL';
                description = 'O aplicativo está em modo de teste e isolado da base oficial.';
                buttonText = 'VOLTAR PARA OFICIAL';
              } else {
                statusIcon = Icons.verified;
                statusLabel = 'MODO OFICIAL';
                description = 'Conectado ao repositório oficial da Aresta Climb.';
                buttonText = 'CONECTAR COMO EDITOR';
              }

              return Card(
                elevation: 0,
                color: context.colors.caveShadow,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (isDevMode || isEditor) return;
                              onSetClickCount(clickCount + 1);
                              if (clickCount + 1 >= 7) {
                                configService.setDevMode(true);
                                onSetClickCount(0);
                                TelemetryService.instance.logAcaoConfiguracoes('ativar_modo_desenvolvedor');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Modo Desenvolvedor Ativado! 🛠️')),
                                );
                              }
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: context.colors.graniteEdge,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(statusIcon, color: context.colors.ashGrey, size: 24),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statusLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  style: TextStyle(
                                    color: context.colors.ashGrey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (isExperimental && activeUrl != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.colors.deepBasalt,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.colors.graniteEdge),
                          ),
                          child: Text(
                            activeUrl,
                            style: TextStyle(
                              color: context.colors.ashGrey,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      if (isDevMode || isEditor) ...[
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () async {
                            if (isEditor) {
                              TelemetryService.instance.logAcaoConfiguracoes('desconectar_editor');
                              await configService.disconnect();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Voltando ao repositório oficial...')),
                                );
                              }
                            } else {
                              mostrarDialogConexao(context, datasetRepo);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC04F34),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              buttonText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        if (!isEditor) 
                          FutureBuilder<bool>(
                            future: configService.hasExperimentalData(),
                            builder: (context, snapshot) {
                              if (snapshot.data == true) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: GestureDetector(
                                    onTap: () async {
                                      TelemetryService.instance.logAcaoConfiguracoes('reativar_experimental');
                                      await configService.activateExperimental();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Reativando dados experimentais locais...')),
                                        );
                                      }
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        border: Border.all(color: context.colors.graniteEdge),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.history_rounded, color: context.colors.ashGrey, size: 18),
                                          const SizedBox(width: 8),
                                          Text(
                                            'REATIVAR MODO EXPERIMENTAL',
                                            style: TextStyle(
                                              color: context.colors.ashGrey,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        if (isEditor) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: context.colors.caveShadow,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: const Text('Apagar Tudo?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  content: Text(
                                    'Isso apagará permanentemente todo o índice experimental e todos os picos baixados nesse modo. Deseja continuar?',
                                    style: TextStyle(color: context.colors.ashGrey),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text('CANCELAR', style: TextStyle(color: context.colors.ashGrey, fontWeight: FontWeight.bold)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('APAGAR TUDO', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                TelemetryService.instance.logAcaoConfiguracoes('limpar_dados_experimentais');
                                await configService.nukeExperimentalData();
                                datasetRepo.loadEmpty(); 
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Ambiente experimental limpo.')),
                                  );
                                }
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_forever, color: Colors.red.withValues(alpha: 0.8), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'LIMPAR DADOS EXPERIMENTAIS',
                                    style: TextStyle(
                                      color: Colors.red.withValues(alpha: 0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              showDeprecatedAppVersionSnackBar(context);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.orange.withValues(alpha: 0.8), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'TESTAR ALERTA DE OBSOLESCÊNCIA',
                                    style: TextStyle(
                                      color: Colors.orange.withValues(alpha: 0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

Widget buildThemeSelectionCard(BuildContext context) {
  return Card(
    elevation: 0,
    color: context.colors.caveShadow,
    margin: const EdgeInsets.only(bottom: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.colors.graniteEdge,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.palette, color: context.colors.ashGrey, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'APARÊNCIA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Personalize o tema do aplicativo.',
                      style: TextStyle(
                        color: context.colors.ashGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController().themeMode,
            builder: (context, currentMode, _) {
              final isManual = currentMode != ThemeMode.system;
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Escolher tema manualmente',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Switch(
                        value: isManual,
                        onChanged: (value) {
                          if (value) {
                            ThemeController().setThemeMode(ThemeMode.dark);
                          } else {
                            ThemeController().setThemeMode(ThemeMode.system);
                          }
                        },
                        activeThumbColor: Colors.white,
                        activeTrackColor: Colors.white.withValues(alpha: 0.5),
                        inactiveThumbColor: context.colors.ashGrey,
                        inactiveTrackColor: context.colors.graniteEdge,
                      ),
                    ],
                  ),
                  if (isManual) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        /* Expanded(
                          child: buildThemeOption(
                            context: context,
                            title: 'CLARO',
                            icon: Icons.light_mode,
                            isSelected: currentMode == ThemeMode.light,
                            onTap: () {
                              TelemetryService.instance.logAcaoConfiguracoes('tema_claro');
                              ThemeController().setThemeMode(ThemeMode.light);
                            },
                          ),
                        ),
                        const SizedBox(width: 12), */
                        Expanded(
                          child: buildThemeOption(
                            context: context,
                            title: 'ESCURO',
                            icon: Icons.dark_mode,
                            isSelected: currentMode == ThemeMode.dark,
                            onTap: () {
                              TelemetryService.instance.logAcaoConfiguracoes('tema_escuro');
                              ThemeController().setThemeMode(ThemeMode.dark);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

Widget buildThemeOption({
  required BuildContext context,
  required String title,
  required IconData icon,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
        border: Border.all(
          color: isSelected ? Colors.white : context.colors.graniteEdge,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: isSelected ? Colors.white : context.colors.ashGrey, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : context.colors.ashGrey,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ),
  );
}

/*
Widget buildLegalLinks(BuildContext context) {
  return Center(
    child: TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: () => showTermsBottomSheet(context),
      child: Text(
        'Termos de Uso e Privacidade',
        style: TextStyle(
          color: context.colors.ashGrey,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
*/

