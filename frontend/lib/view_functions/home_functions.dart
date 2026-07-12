import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/dataset_repository.dart';
import '../widgets/global_search.dart';
import '../services/http/sync_service.dart';
import 'common_functions.dart';
import '../navigation/navigation_functions.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';

/// Uma paleta de cores usada para o fundo dos cartões (cards) de pico.
final List<Color> cardPalette = [
  leatherWork,
  slateStone,
  mossRock,
  clayEarth,
  weatheredIron,
];

/// Navega para a página de detalhes de um pico selecionado.
/// 
/// Ele primeiro mostra um indicador de carregamento enquanto busca os dados completos do Croqui.
void handlePicoSelection(BuildContext context, DatasetRepository datasetRepo, Map<String, dynamic> pico, {String source = 'home'}) async {
  final id = pico['id'];
  if (id == null) return;
  
  TelemetryService.instance.logAcaoCroqui(id, 'abrir_croqui', origem: source);

  // Mostra indicador de carregamento
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(child: CircularProgressIndicator(color: beastHide)),
  );

  final croqui = await datasetRepo.getCroqui(id);

  if (!context.mounted) return;
  
  Navigator.of(context, rootNavigator: true).pop(); // Remove indicador de carregamento

  if (croqui != null && croqui.picos.isNotEmpty) {
    // Navega para a página do pico através da árvore de navegação
    AppNav.toPico(
      context,
      pico: croqui.picos.first,
      croqui: croqui,
      cragId: id,
    );
    
    // Atualiza a ordem e reseta o carrossel em background
    Future.delayed(const Duration(milliseconds: 300), () {
      datasetRepo.updatePriorityAfterNavigation(id);
      datasetRepo.triggerHomeReset();
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erro ao abrir o guia.')),
    );
  }
}

/// Constrói o corpo rolável principal da página inicial (Home).
/// 
/// Exibe um carrossel de picos baixados recentemente e uma lista suspensa
/// de todos os guias disponíveis.
Widget buildHomeBody(
  BuildContext context,
  DatasetRepository datasetRepo,
  SyncService syncService,
  List<Map<String, dynamic>> downloadedPicos,
  ValueListenable<Map<String, double>> downloadingCragsListenable, {
  required VoidCallback onAddCrag,
}) {
  return Container(
    width: double.infinity,
    height: double.infinity,
    // Transformando a cor de fundo em um gradiente para ficar mais bonito
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          nobleBlack, // Cor de fundo principal
          obsidianBrown, // Transições do escuro para um marrom terra
        ],
      ),
    ),
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), // Garante que sempre role/tenha o efeito de rebote
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          GlobalSearch(
            datasetRepo: datasetRepo,
            downloadedPicos: downloadedPicos,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20), // Reduced top padding from 40 to 20 since search section is above
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Guias Recentes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: fishBone,
                  ),
                ),
                ValueListenableBuilder<SyncStatus>(
                  valueListenable: syncService.syncStatus,
                  builder: (context, status, child) {
                    if (status == SyncStatus.updating) {
                      return const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    return buildSyncBadge(status);
                  },
                ),
              ],
            ),
          ),
          // O carrossel agora lida internamente com o limite de 4 cartões
          buildPicosCarousel(
            downloadedPicos, 
            downloadingCragsListenable,
            onAddCrag: onAddCrag,
            onPicoSelect: (pico) => handlePicoSelection(context, datasetRepo, pico),
          ),
          if (downloadedPicos.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildAllGuidesDropdown(
              downloadedPicos, 
              downloadingCragsListenable,
              onAddCrag: onAddCrag, 
              onPicoSelect: (pico) => handlePicoSelection(context, datasetRepo, pico),
            ),
          ],
          const SizedBox(height: 100), // Espaço extra na parte inferior para garantir que tudo seja rolável
        ],
      ),
    ),
  );
}

/// Constrói um emblema (badge) de status de sincronização.
Widget buildSyncBadge(SyncStatus status) {
  String text;
  Color color;
  IconData icon;

  switch (status) {
    case SyncStatus.updated:
      text = 'Atualizados';
      color = Colors.green.shade800;
      icon = Icons.check_circle;
      break;
    case SyncStatus.updating:
      text = 'Atualizando...';
      color = Colors.blue.shade800;
      icon = Icons.sync;
      break;
    case SyncStatus.outdated:
      text = 'Desatualizado';
      color = Colors.orange.shade800;
      icon = Icons.warning;
      break;
    case SyncStatus.offline:
      text = 'Sem conexão';
      color = Colors.brown.shade800;
      icon = Icons.cloud_off;
      break;
    case SyncStatus.error:
      text = 'Erro ao atualizar';
      color = Colors.red.shade800;
      icon = Icons.error;
      break;
    case SyncStatus.justUpdated:
      text = 'Foram atualizados!';
      color = Colors.blue.shade600;
      icon = Icons.cloud_done;
      break;
    case SyncStatus.noNewUpdates:
      text = 'Sem atualizações';
      color = Colors.teal.shade600;
      icon = Icons.check_circle_outline;
      break;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

/// Constrói uma lista expansível mostrando todos os guias baixados.
Widget _buildAllGuidesDropdown(
  List<Map<String, dynamic>> picos,
  ValueListenable<Map<String, double>> downloadingCrags, {
  required VoidCallback onAddCrag,
  required Function(Map<String, dynamic>) onPicoSelect,
}) {
  return Theme(
    data: ThemeData(
      dividerColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    ),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 24),
      iconColor: fishBone,
      collapsedIconColor: fishBone,
      title: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: fishBone.withValues(alpha: 0.1), width: 1),
          ),
        ),
        child: Text(
          'Todos os guias baixados',
          style: TextStyle(
            color: fishBone,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      backgroundColor: Colors.black.withValues(alpha: 0.3), // Mais escuro que o fundo quando expandido para dar ênfase
      collapsedBackgroundColor: Colors.transparent,
      children: [
        ...picos.map((pico) {
          return ValueListenableBuilder<Map<String, double>>(
            valueListenable: downloadingCrags,
            builder: (context, downloadingMap, child) {
              final isDownloading = downloadingMap.containsKey(pico['id']);
              
              Widget trailingIcon;
              if (isDownloading) {
                trailingIcon = SizedBox(
                  width: 60,
                  child: LinearProgressIndicator(
                    value: downloadingMap[pico['id']],
                    color: fishBone,
                    backgroundColor: fishBone.withValues(alpha: 0.2),
                  ),
                );
              } else {
                trailingIcon = Icon(Icons.chevron_right, color: fishBone, size: 18);
              }
              
              Color titleColor;
              if (isDownloading) {
                titleColor = fishBone.withValues(alpha: 0.5);
              } else {
                titleColor = fishBone;
              }

              VoidCallback? onTapCallback;
              if (isDownloading) {
                onTapCallback = null;
              } else {
                onTapCallback = () => onPicoSelect(pico);
              }

              return Material(
                type: MaterialType.transparency,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 32),
                  title: Text(
                    safeString(pico['nome']),
                    style: TextStyle(
                      color: titleColor, 
                      fontSize: 15
                    ),
                  ),
                  trailing: trailingIcon,
                  onTap: onTapCallback,
                ),
              );
            },
          );
        }),
        Material(
          type: MaterialType.transparency,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 32),
            leading: Icon(Icons.add_circle_outline, color: beastHide, size: 20),
            title: Text(
              'Adicionar novo local',
              style: TextStyle(
                color: beastHide,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            onTap: onAddCrag,
          ),
        ),
      ],
    ),
  );
}

/// Um cabeçalho estilizado para seções.
Widget buildSectionHeader(String title) {
  return Padding(
    // Preenchimento (padding) no texto para dar algum espaço
    padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: fishBone, // Texto claro para visibilidade
      ),
    ),
  );
}

/// Constrói um carrossel horizontal de cartões de picos.
/// Limitado aos 4 picos mais recentes.
/// Permite loop infinito se houver exatamente 4 itens.
Widget buildPicosCarousel(
  List<Map<String, dynamic>> allPicos,
  ValueListenable<Map<String, double>> downloadingCrags, {
  required VoidCallback onAddCrag,
  required Function(Map<String, dynamic>) onPicoSelect,
}) {
  if (allPicos.isEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Text(
              'Nenhum guia baixado ainda.',
              style: TextStyle(color: fishBone, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            Builder(builder: (context) {
              return ElevatedButton.icon(
                onPressed: onAddCrag,
                icon: const Icon(Icons.search),
                label: const Text('Explorar guias'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  foregroundColor: beastHide,
                  side: BorderSide(color: beastHide),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // LIMITADOR: Pega no máximo 4 cartões para o carrossel para evitar acúmulo de informações
  final List<Map<String, dynamic>> picosToShow = allPicos.take(4).toList();
  final int count = picosToShow.length;
  final bool shouldLoop = count >= 4;

  // Configurações do PageView baseadas no loop
  int? itemCount;
  double viewportFraction;
  int initialPage;
  if (shouldLoop) {
    itemCount = null;
    viewportFraction = 0.85;
    initialPage = count * 100;
  } else {
    itemCount = count;
    viewportFraction = 0.9;
    initialPage = 0;
  }

  // Física de rolagem
  ScrollPhysics scrollPhysics;
  if (count > 1) {
    scrollPhysics = const BouncingScrollPhysics();
  } else {
    scrollPhysics = const NeverScrollableScrollPhysics();
  }

  return Column(
    children: [
      SizedBox(
        height: 350,
        child: PageView.builder(
          itemCount: itemCount,
          controller: PageController(
            viewportFraction: viewportFraction,
            initialPage: initialPage,
            keepPage: false,
          ),
          physics: scrollPhysics,
          itemBuilder: (context, index) {
            int actualIndex;
            if (shouldLoop) {
              actualIndex = index % count;
            } else {
              actualIndex = index;
            }

            final Color cardColor = cardPalette[actualIndex % cardPalette.length];
            
            double rightPadding;
            if (!shouldLoop && actualIndex == count - 1) {
              rightPadding = 0.0;
            } else {
              rightPadding = 10.0;
            }

            final pico = picosToShow[actualIndex];

            return ValueListenableBuilder<Map<String, double>>(
              valueListenable: downloadingCrags,
              builder: (context, downloadingMap, child) {
                final isDownloading = downloadingMap.containsKey(pico['id']);

                VoidCallback? onTapCallback;
                if (isDownloading) {
                  onTapCallback = null;
                } else {
                  onTapCallback = () => onPicoSelect(pico);
                }
                
                double cardOpacity;
                if (isDownloading) {
                  cardOpacity = 0.6;
                } else {
                  cardOpacity = 1.0;
                }

                return GestureDetector(
                  onTap: onTapCallback,
                  child: Opacity(
                    opacity: cardOpacity,
                    child: buildPicoCard(pico, rightPadding, cardColor, isDownloading, onPicoSelect),
                  ),
                );
              },
            );
          },
        ),
      ),
      if (count > 1)
        buildFooterInstructions('Deslize para ver seus downloads'),
    ],
  );
}

/// Constrói um cartão individual para um pico no carrossel.
Widget buildPicoCard(Map<String, dynamic> pico, double rightPadding, Color cardColor, bool isDownloading, Function(Map<String, dynamic>) onPicoSelect) {
  final String? capaPath = pico['capaPath'];
  final bool hasCapa = capaPath != null && File(capaPath).existsSync();
  
  Color contentColor;
  if (hasCapa) {
    contentColor = Colors.white;
  } else {
    contentColor = nobleBlack;
  }

  if (capaPath != null && !hasCapa) {
    debugPrint('Cover image path set but file not found: $capaPath');
  } else if (hasCapa) {
    // debugPrint('Rendering card with cover: $capaPath');
  }

  Color containerColor;
  if (hasCapa) {
    containerColor = Colors.black;
  } else {
    containerColor = cardColor;
  }

  return Padding(
    padding: EdgeInsets.only(left: 10, right: rightPadding, top: 20, bottom: 20),
    child: Container(
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Imagem de Fundo com Blur
            if (hasCapa)
              Positioned.fill(
                child: Image.file(
                  File(capaPath),
                  fit: BoxFit.cover,
                  color: Colors.black.withValues(alpha: 0.4),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            
            // Efeito de Blur para suavizar o fundo e destacar o texto (Glassmorphism)
            if (hasCapa)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.1),
                  ),
                ),
              ),

            // Gradiente duplo para legibilidade no topo e base
            if (hasCapa)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 0.7, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      String nome;
                      if (pico['nome'] != null) {
                        nome = pico['nome'];
                      } else {
                        nome = 'Sem Nome';
                      }
                      
                      List<Shadow>? shadows;
                      if (hasCapa) {
                        shadows = [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          )
                        ];
                      }
                      
                      return Text(
                        nome,
                        style: TextStyle(
                          color: contentColor,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                          height: 1.1,
                          shadows: shadows,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      String local;
                      if (pico['local'] != null) {
                        local = pico['local'];
                      } else {
                        local = 'Local Desconhecido';
                      }
                      
                      List<Shadow>? shadows;
                      if (hasCapa) {
                        shadows = [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          )
                        ];
                      }
                      
                      return Row(
                        children: [
                          Icon(
                            Icons.location_on, 
                            color: contentColor.withValues(alpha: 0.8), 
                            size: 16,
                            shadows: shadows,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              local,
                              style: TextStyle(
                                color: contentColor.withValues(alpha: 0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                shadows: shadows,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const Spacer(),
                  Builder(
                    builder: (context) {
                      VoidCallback? onPressed;
                      if (isDownloading) {
                        onPressed = null;
                      } else {
                        onPressed = () => onPicoSelect(pico);
                      }

                      String buttonText;
                      if (isDownloading) {
                        buttonText = 'BAIXANDO...';
                      } else {
                        buttonText = 'VER GUIA';
                      }

                      return ElevatedButton(
                        onPressed: onPressed, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: contentColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: Text(
                          buttonText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,  
                            letterSpacing: 1,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Um pequeno botão no cartão para indicar que pode ser aberto.
Widget buildVerGuiaButton(Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      'VER GUIA',
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    ),
  );
}

/// Texto de instruções na parte inferior do carrossel.
Widget buildFooterInstructions(String text) {
  return Padding(
    padding: const EdgeInsets.all(20.0),
    child: Center(
      child: Text(
        text,
        style: TextStyle(
          color: fishBone,
          fontStyle: FontStyle.italic,
          fontSize: 14,
        ),
      ),
    ),
  );
}
