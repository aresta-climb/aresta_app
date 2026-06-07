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
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../theme/theme_controller.dart';
import '../theme/app_colors.dart';
import '../pages/terms_of_use.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
    if (!checkUrl.startsWith('http://') && !checkUrl.startsWith('https://')) {
      checkUrl = 'https://$checkUrl';
    }
    if (checkUrl.endsWith('/')) {
      checkUrl = checkUrl.substring(0, checkUrl.length - 1);
    }
    
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
      
      configService.useCompiladoFolder.value = false;
      await configService.activateExperimental(url: ghostUrl, forceResetTimer: true);
      
      final syncService = SyncService(datasetRepository: datasetRepo);
      await syncService.syncOnLaunch();
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
        configService.useCompiladoFolder.value = false;
        
        await configService.activateExperimental(url: resolvedUrl, forceResetTimer: true);
        final syncService = SyncService(datasetRepository: datasetRepo);
        await syncService.syncOnLaunch();
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
      type: fp.FileType.custom,
      allowedExtensions: ['croqui'],
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
      
      configService.useCompiladoFolder.value = false;
      await configService.activateExperimental(url: ghostUrl, forceResetTimer: true);
      
      // Tenta sincronizar o índice usando o interceptor
      final syncService = SyncService(datasetRepository: datasetRepo);
      await syncService.syncOnLaunch();
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
  // Pré-preenche com a URL atual se existir, caso contrário começa vazio
  final TextEditingController urlController = TextEditingController(text: configService.editorUrl.value ?? '');
  bool isLoading = false;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).dialogTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
            title: Text(
              titulo ?? 'Conectar como editor', 
              style: TextStyle(color: beastHide, fontSize: 18),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                Text(
                  'Insira a URL do repositório experimental para testar novos croquis.',
                  style: TextStyle(color: fishBone, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlController,
                  style: TextStyle(color: fishBone, fontSize: 14),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.qr_code_scanner, color: beastHide),
                    label: Text('Escanear QR Code', style: TextStyle(color: beastHide)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: beastHide),
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
          final isEditor = activeUrl != null || isExperimental;

          return ValueListenableBuilder<bool>(
            valueListenable: configService.isDevModeEnabled,
            builder: (context, isDevMode, _) {
              Color cardColor;
              IconData statusIcon;
              String statusLabel;
              String description;
              Color buttonBgColor;
              String buttonText;
              Color buttonTextColor;

              if (isEditor) {
                cardColor = AppColors.light.obsidianBrown;
                statusIcon = Icons.science;
                statusLabel = 'Modo Experimental Ativo';
                description = 'O aplicativo está em modo de teste. Os dados são carregados de uma fonte externa ou local e mantidos isolados.';
                buttonBgColor = Colors.blueGrey.shade700;
                buttonText = 'Voltar para oficial';
                buttonTextColor = Colors.white;
              } else {
                cardColor = AppColors.light.slateStone;
                statusIcon = Icons.verified;
                statusLabel = 'Modo Oficial Ativo';
                description = 'O aplicativo está conectado ao repositório oficial da Aresta Climb.';
                buttonBgColor = AppColors.light.beastHide;
                buttonText = 'Conectar como editor';
                buttonTextColor = AppColors.light.nobleBlack;
              }

              return Card(
                color: cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            child: Icon(statusIcon, color: AppColors.light.fishBone),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: AppColors.light.fishBone,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(color: AppColors.light.fishBone),
                      ),
                      if (activeUrl != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            activeUrl,
                            style: TextStyle(color: AppColors.light.beastHide, fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                      if (isDevMode || isEditor) ...[
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonBgColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () async {
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
                            child: Text(
                              buttonText,
                              style: TextStyle(
                                color: buttonTextColor,
                                fontWeight: FontWeight.bold,
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
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: AppColors.light.beastHide, width: 1.2),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: Icon(Icons.history_rounded, color: AppColors.light.beastHide, size: 18),
                                      label: Text(
                                        'Reativar modo experimental',
                                        style: TextStyle(
                                          color: AppColors.light.beastHide, 
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      onPressed: () async {
                                        TelemetryService.instance.logAcaoConfiguracoes('reativar_experimental');
                                        await configService.activateExperimental();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Reativando dados experimentais locais...')),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        if (isEditor) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.delete_forever, color: Colors.red),
                              label: const Text(
                                'LIMPAR DADOS EXPERIMENTAIS',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: AppColors.light.nobleBlack,
                                    title: const Text('Nuke It?', style: TextStyle(color: Colors.red)),
                                    content: Text(
                                      'Isso apagará permanentemente todo o índice experimental e todos os picos baixados nesse modo. Deseja continuar?',
                                      style: TextStyle(color: AppColors.light.fishBone),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text('Cancelar', style: TextStyle(color: AppColors.light.fishBone)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('APAGAR TUDO', style: TextStyle(color: Colors.red)),
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
                                      const SnackBar(content: Text('Ambiente experimental limpo com sucesso.')),
                                    );
                                  }
                                }
                              },
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
    color: AppColors.light.slateStone,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette, color: AppColors.light.fishBone),
              const SizedBox(width: 8),
              Text(
                'Aparência (Tema)',
                style: TextStyle(
                  color: AppColors.light.fishBone,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController().themeMode,
            builder: (context, currentMode, _) {
              return Row(
                children: [
                  Expanded(
                    child: buildThemeOption(
                      title: 'Claro',
                      icon: Icons.light_mode,
                      isSelected: currentMode == ThemeMode.light,
                      onTap: () {
                        TelemetryService.instance.logAcaoConfiguracoes('tema_claro');
                        ThemeController().setThemeMode(ThemeMode.light);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: buildThemeOption(
                      title: 'Escuro',
                      icon: Icons.dark_mode,
                      isSelected: currentMode == ThemeMode.dark,
                      onTap: () {
                        TelemetryService.instance.logAcaoConfiguracoes('tema_escuro');
                        ThemeController().setThemeMode(ThemeMode.dark);
                      },
                    ),
                  ),
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
  required String title,
  required IconData icon,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.light.beastHide.withValues(alpha: 0.2) : Colors.transparent,
        border: Border.all(
          color: isSelected ? AppColors.light.beastHide : AppColors.light.weatheredIron,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: isSelected ? AppColors.light.beastHide : AppColors.light.fishBone),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? AppColors.light.beastHide : AppColors.light.fishBone,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildAppVersionCard(BuildContext context) {
  return FutureBuilder<PackageInfo>(
    future: PackageInfo.fromPlatform(),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        final version = snapshot.data!.version;
        return Card(
          color: AppColors.light.slateStone,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.light.fishBone),
                const SizedBox(width: 8),
                Text(
                  'Versão do app',
                  style: TextStyle(
                    color: AppColors.light.fishBone,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  version,
                  style: TextStyle(
                    color: AppColors.light.beastHide,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    },
  );
}

Widget buildLegalLinks(BuildContext context) {
  return TextButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TermsOfUsePage(
            onAccepted: () {},
            showAcceptButton: false,
          ),
        ),
      );
    },
    style: TextButton.styleFrom(
      foregroundColor: AppColors.light.fishBone.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: const Text(
      'Termos de Uso e Privacidade',
      style: TextStyle(
        fontSize: 12, 
        decoration: TextDecoration.underline,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

