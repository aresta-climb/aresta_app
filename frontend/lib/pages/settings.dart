import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../view_functions/common_functions.dart';
import '../view_functions/settings_functions.dart';
import '../services/dataset_repository.dart';
import '../services/editor_croqui.dart';
import '../theme/theme_controller.dart';
/// Página de Configurações do aplicativo.
class SettingsPage extends StatefulWidget {
  final DatasetRepository datasetRepo;

  const SettingsPage({super.key, required this.datasetRepo});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _clickCount = 0;

  @override
  Widget build(BuildContext context) {
    final EditorDeCroqui configService = widget.datasetRepo.editorDeCroqui;

    return Column(
      children: [
        buildCommonAppBar(context, 'Configurações'),
        Expanded(
          child: ValueListenableBuilder<bool>(
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
                        cardColor = obsidianBrown;
                        statusIcon = Icons.science;
                        statusLabel = 'Modo Experimental Ativo';
                        description = 'O aplicativo está em modo de teste. Os dados são carregados de uma fonte externa ou local e mantidos isolados.';
                        buttonBgColor = Colors.blueGrey.shade700;
                        buttonText = 'Voltar para oficial';
                        buttonTextColor = Colors.white;
                      } else {
                        cardColor = slateStone;
                        statusIcon = Icons.verified;
                        statusLabel = 'Modo Oficial Ativo';
                        description = 'O aplicativo está conectado ao repositório oficial da Aresta Climb.';
                        buttonBgColor = beastHide;
                        buttonText = 'Conectar como editor';
                        buttonTextColor = nobleBlack;
                      }

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildThemeSelectionCard(context),
                          const SizedBox(height: 16),
                          Card(
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
                                          setState(() {
                                            _clickCount++;
                                            if (_clickCount >= 7) {
                                              configService.setDevMode(true);
                                              _clickCount = 0;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Modo Desenvolvedor Ativado! 🛠️')),
                                              );
                                            }
                                          });
                                        },
                                        child: Icon(statusIcon, color: fishBone),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        statusLabel,
                                        style: TextStyle(
                                          color: fishBone,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    description,
                                    style: TextStyle(color: fishBone),
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
                                        style: TextStyle(color: beastHide, fontFamily: 'monospace'),
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
                                            await configService.disconnect();
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Voltando ao repositório oficial...')),
                                              );
                                            }
                                          } else {
                                            mostrarDialogConexao(context, widget.datasetRepo);
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
                                                    side: BorderSide(color: beastHide, width: 1.2),
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                  icon: Icon(Icons.history_rounded, color: beastHide, size: 18),
                                                  label: Text(
                                                    'Reativar modo experimental',
                                                    style: TextStyle(
                                                      color: beastHide, 
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                  onPressed: () async {
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
                                                backgroundColor: nobleBlack,
                                                title: const Text('Nuke It?', style: TextStyle(color: Colors.red)),
                                                content: Text(
                                                  'Isso apagará permanentemente todo o índice experimental e todos os picos baixados nesse modo. Deseja continuar?',
                                                  style: TextStyle(color: fishBone),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, false),
                                                    child: Text('Cancelar', style: TextStyle(color: fishBone)),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, true),
                                                    child: const Text('APAGAR TUDO', style: TextStyle(color: Colors.red)),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true) {
                                              await configService.nukeExperimentalData();
                                              widget.datasetRepo.loadEmpty(); 
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
                          ),
                          const SizedBox(height: 16),
                          FutureBuilder<PackageInfo>(
                            future: PackageInfo.fromPlatform(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final version = snapshot.data!.version;
                                final buildNumber = snapshot.data!.buildNumber;
                                return _buildAppVersionCard(context, version, buildNumber);
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelectionCard(BuildContext context) {
    return Card(
      color: slateStone,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette, color: fishBone),
                const SizedBox(width: 8),
                Text(
                  'Aparência (Tema)',
                  style: TextStyle(
                    color: fishBone,
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
                      child: _buildThemeOption(
                        title: 'Claro',
                        icon: Icons.light_mode,
                        isSelected: currentMode == ThemeMode.light,
                        onTap: () => ThemeController().setThemeMode(ThemeMode.light),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildThemeOption(
                        title: 'Escuro',
                        icon: Icons.dark_mode,
                        isSelected: currentMode == ThemeMode.dark,
                        onTap: () => ThemeController().setThemeMode(ThemeMode.dark),
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

  Widget _buildThemeOption({
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
          color: isSelected ? beastHide.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? beastHide : weatheredIron,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? beastHide : fishBone),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? beastHide : fishBone,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppVersionCard(BuildContext context, String version, String buildNumber) {
    return Card(
      color: slateStone,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: fishBone),
            const SizedBox(width: 8),
            Text(
              'Versão do Aplicativo',
              style: TextStyle(
                color: fishBone,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              version,
              style: TextStyle(
                color: beastHide,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

