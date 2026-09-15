// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../theme/app_colors.dart';
import '../widgets/provedor_imagem_aresta.dart';
import 'common_functions.dart';
import '../navigation/navigation_functions.dart';

/// Constrói a área de conteúdo principal para a página de Explorar (Browse).
///
/// Ela exibe uma barra de pesquisa e uma lista de picos disponíveis que podem ser baixados.
/// O callback [onSearchChanged] é acionado quando o usuário digita na barra de pesquisa.
/// O callback [onDownload] é acionado quando o usuário toca no botão de download em um item de pico.
Widget buildBrowseBody(
  BuildContext context,
  List<Map<String, dynamic>> availableCrags,
  ValueListenable<Map<String, double>> downloadingCrags, {
  required ValueChanged<String> onSearchChanged,
  required Function(Map<String, dynamic>) onDownload,
  Function(Map<String, dynamic>)? onOpen,
  VoidCallback? onAddExperimental,
  VoidCallback? onFilterPressed,
  VoidCallback? onSyncPressed,
}) {
  return Column(
    children: [
      const SizedBox(height: 10),
      buildSearchBar(
        onChanged: onSearchChanged,
        onFilterPressed: onFilterPressed,
        onSyncPressed: onSyncPressed,
        showFeedback: true,
      ),
      Expanded(
        child: _buildCragList(
          context,
          availableCrags,
          downloadingCrags,
          onDownload,
          onOpen: onOpen,
          onAddExperimental: onAddExperimental,
        ),
      ),
    ],
  );
}

Widget _buildCragList(
  BuildContext context,
  List<Map<String, dynamic>> availableCrags,
  ValueListenable<Map<String, double>> downloadingCrags,
  Function(Map<String, dynamic>) onDownload, {
  Function(Map<String, dynamic>)? onOpen,
  VoidCallback? onAddExperimental,
}) {
  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'GRADE DE CROQUIS',
              style: TextStyle(
                color: context.colors.dryMoss,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            _AnimatedMapButton(
              onPressed: () {
                AppNav.toMapaGlobal(context, crags: availableCrags);
              },
            ),
          ],
        ),

        // Botão Único de Adição Experimental
        if (onAddExperimental != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddExperimental,
              icon: Icon(
                Icons.add_circle_outline,
                color: context.colors.beastHide,
                size: 20,
              ),
              label: Text(
                'TROCAR SERVING',
                style: TextStyle(
                  color: context.colors.beastHide,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  fontSize: 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.colors.beastHide, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        if (availableCrags.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40.0),
              child: Text(
                'Nenhum pico encontrado.',
                style: TextStyle(color: context.colors.ashGrey, fontSize: 16),
              ),
            ),
          )
        else
          ...availableCrags.map(
            (crag) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: CragCard(
                crag: crag,
                downloadingCrags: downloadingCrags,
                onDownload: () => onDownload(crag),
                onOpen: onOpen != null ? () => onOpen(crag) : null,
              ),
            ),
          ),
      ],
    ),
  );
}

class _AnimatedMapButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _AnimatedMapButton({required this.onPressed});

  @override
  State<_AnimatedMapButton> createState() => _AnimatedMapButtonState();
}

class _AnimatedMapButtonState extends State<_AnimatedMapButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _controller.forward(),
      onPointerUp: (_) => _controller.reverse(),
      onPointerCancel: (_) => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.explore_outlined,
                      color: const Color(0xFFC05244),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'VER NO MAPA',
                      style: TextStyle(
                        color: const Color(0xFFC05244),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wrapper for _CragCard to maintain compatibility with other modules and tests.
Widget buildCragListItem(
  Map<String, dynamic> crag,
  ValueListenable<Map<String, double>> downloadingCrags,
  VoidCallback onDownload, {
  VoidCallback? onOpen,
}) {
  return CragCard(
    crag: crag,
    downloadingCrags: downloadingCrags,
    onDownload: onDownload,
    onOpen: onOpen,
  );
}

class CragCard extends StatelessWidget {
  final Map<String, dynamic> crag;
  final ValueListenable<Map<String, double>> downloadingCrags;
  final VoidCallback onDownload;
  final VoidCallback? onOpen;
  final String? distanceStr;
  final bool showDetailedStats;

  const CragCard({
    super.key,
    required this.crag,
    required this.downloadingCrags,
    required this.onDownload,
    this.onOpen,
    this.distanceStr,
    this.showDetailedStats = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDownloaded = crag['isDownloaded'] == true;
    final String nome = safeString(
      crag['nome'],
      fallback: 'Sem Nome',
    ).toUpperCase();

    // Attempt to extract sectors/routes count if available in description or another field
    String statsText = '0 setores • 0 escaladas';
    if (crag['estatisticas'] != null) {
      final stats = crag['estatisticas'];
      final setores = stats['totalSetores'] ?? 0;
      final vias = stats['totalVias'] ?? 0;

      statsText = '$setores setores • $vias escaladas';

      if (showDetailedStats) {
        final List<String> modalidades = [];
        if ((stats['totalBoulders'] ?? 0) > 0) {
          modalidades.add('${stats['totalBoulders']} boulders');
        }
        if ((stats['totalEsportivas'] ?? 0) > 0) {
          modalidades.add('${stats['totalEsportivas']} esportivas');
        }
        if ((stats['totalMoveis'] ?? 0) > 0) {
          modalidades.add('${stats['totalMoveis']} móveis');
        }
        if ((stats['totalMultiplasEnfiadas'] ?? 0) > 0) {
          modalidades.add('${stats['totalMultiplasEnfiadas']} múltiplas enfiadas');
        }
        if ((stats['totalHighlines'] ?? 0) > 0) {
          modalidades.add('${stats['totalHighlines']} highlines');
        }

        if (modalidades.isNotEmpty) {
          statsText += ' (${modalidades.join(', ')})';
        }
      }
    }

    return GestureDetector(
      onTap: () {
        if (onOpen != null) {
          onOpen!();
        } else {
          onDownload();
        }
      },
      child: Container(
        height: 200, // Large card height
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: context.colors.darkPine,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            buildCragBackground(
              safeString(crag['thumbnailUrl']),
              cragId: safeString(crag['id']),
            ),

            // Gradient Overlay for readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Right Badges
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (distanceStr != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.place,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                distanceStr!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isDownloaded)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF7B8B6F,
                            ).withValues(alpha: 0.9), // Greenish Olive badge
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'SALVO OFFLINE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ValueListenableBuilder<Map<String, double>>(
                        valueListenable: downloadingCrags,
                        builder: (context, downloadingMap, child) {
                          final progress = downloadingMap[crag['id']];
                          if (progress != null) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${(progress * 100).toInt()}%',
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
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),

                  // Bottom Left Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statsText,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget de plano de fundo e miniatura para o cartão de pico na exploração.
///
/// Resolve miniaturas locais e remotas de forma unificada através do [ProvedorImagemAresta],
/// aplicando downsampling com largura alvo de 300 pixels para preservar a memória gráfica.
class _CragBackgroundWidget extends StatefulWidget {
  final String thumbnailUrl;
  final String? cragId;

  const _CragBackgroundWidget({required this.thumbnailUrl, this.cragId});

  @override
  State<_CragBackgroundWidget> createState() => _CragBackgroundWidgetState();
}

class _CragBackgroundWidgetState extends State<_CragBackgroundWidget> {
  Future<ImageProvider?>? _provedorImagemFuture;

  @override
  void initState() {
    super.initState();
    _inicializarProvedor();
  }

  @override
  void didUpdateWidget(covariant _CragBackgroundWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thumbnailUrl != widget.thumbnailUrl ||
        oldWidget.cragId != widget.cragId) {
      _inicializarProvedor();
    }
  }

  /// Inicializa o provedor de imagem para o plano de fundo do pico.
  ///
  /// Sempre que [cragId] estiver disponível (ou puder ser inferido do caminho de miniatura),
  /// delega a resolução para [ProvedorImagemAresta] utilizando o caminho canônico
  /// `thumbnails/$cragId.webp`. Isso assegura que:
  /// 1. Miniaturas locais em `/downloads/thumbnails` ou `/thumbnails` sejam priorizadas.
  /// 2. O cache volátil seja consultado com base no hash do índice.
  /// 3. Em caso de download remoto, a requisição seja direcionada para o endpoint
  ///    canônico da CDN (`/thumbnails/<cragId>.webp`), evitando URLs legadas que retornam 404.
  void _inicializarProvedor() {
    _provedorImagemFuture = null;
    String? cragId = widget.cragId;
    if ((cragId == null || cragId.isEmpty) && widget.thumbnailUrl.isNotEmpty) {
      final correspondencia = RegExp(r'thumbnails/([^/?#]+)\.webp').firstMatch(widget.thumbnailUrl);
      if (correspondencia != null) {
        cragId = correspondencia.group(1);
      }
    }

    if (cragId != null && cragId.isNotEmpty) {
      _provedorImagemFuture = ProvedorImagemAresta.resolver(
        picoId: cragId,
        caminho: 'thumbnails/$cragId.webp',
        larguraAlvo: 300,
      );
    } else if (widget.thumbnailUrl.isNotEmpty &&
        (widget.thumbnailUrl.startsWith('http://') ||
            widget.thumbnailUrl.startsWith('https://'))) {
      _provedorImagemFuture = Future.value(
        ResizeImage.resizeIfNeeded(
          300,
          null,
          NetworkImage(widget.thumbnailUrl),
        ),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF2C332A),
      child: Center(
        child: Icon(
          Icons.terrain,
          color: Colors.white.withValues(alpha: 0.1),
          size: 64,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_provedorImagemFuture != null) {
      return FutureBuilder<ImageProvider?>(
        future: _provedorImagemFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildPlaceholder();
          }
          if (snapshot.hasData && snapshot.data != null) {
            return Image(
              image: snapshot.data!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
            );
          }
          return _buildPlaceholder();
        },
      );
    }
    return _buildPlaceholder();
  }
}

Widget buildCragBackground(String thumbnailUrl, {String? cragId}) {
  return _CragBackgroundWidget(thumbnailUrl: thumbnailUrl, cragId: cragId);
}

void showDownloadBottomSheet(
  BuildContext context,
  Map<String, dynamic> crag,
  VoidCallback onDownload,
  ValueListenable<Map<String, double>> downloadingCrags, {
  VoidCallback? onOpen,
}) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: context.colors.deepBasalt,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext bottomSheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottom sheet handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.graniteEdge,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                safeString(crag['nome'], fallback: 'Pico'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                safeString(crag['local'], fallback: 'Local Desconhecido'),
                style: TextStyle(color: context.colors.ashGrey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (crag['descricao'] != null &&
                  crag['descricao'].toString().isNotEmpty) ...[
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      crag['descricao'],
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              ValueListenableBuilder<Map<String, double>>(
                valueListenable: downloadingCrags,
                builder: (context, downloadingMap, child) {
                  final progress = downloadingMap[crag['id']];
                  final isDownloading = progress != null;

                  if (isDownloading) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: context.colors.darkPine,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'BAIXANDO...',
                            style: TextStyle(
                              color: context.colors.dryMoss,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: context.colors.graniteEdge,
                              color: context.colors.dryMoss,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (crag['isDownloaded'] == true && onOpen != null) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            bottomSheetContext,
                          ); // Close sheet first
                          onOpen();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.dryMoss,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'ABRIR CROQUI',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    );
                  }

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        onDownload();
                        Navigator.pop(
                          bottomSheetContext,
                        ); // Close sheet after triggering download
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC05244), // Red button
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'BAIXAR CROQUI',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
