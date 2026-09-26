// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/dataset/modelos/resumo_pico.dart';
import '../services/dataset/modelos/metadados_indice.dart';
import '../theme/app_colors.dart';
import 'provedor_imagem_aresta.dart';

/// Card interativo que exibe um resumo visual do pico (croqui),
/// incluindo thumbnail em cache, status de download, distância e estatísticas de vias.
class CragCard extends StatelessWidget {
  final dynamic crag;
  final ValueListenable<Map<String, double>> downloadingCrags;
  final VoidCallback onDownload;
  final VoidCallback? onOpen;
  final String? distanceStr;
  final bool showDetailedStats;
  final bool? isDownloadedOverride;

  const CragCard({
    super.key,
    required this.crag,
    required this.downloadingCrags,
    required this.onDownload,
    this.onOpen,
    this.distanceStr,
    this.showDetailedStats = false,
    this.isDownloadedOverride,
  });

  @override
  Widget build(BuildContext context) {
    final String id;
    final String nome;
    final bool isDownloaded;
    final String thumbnailUrl;
    final String? capaPath;
    final String? checksumSha256;
    String statsText = '0 setores • 0 escaladas';

    if (crag is MetadadosIndice) {
      final MetadadosIndice m = crag as MetadadosIndice;
      id = m.id;
      nome = m.nome.isEmpty ? 'SEM NOME' : m.nome.toUpperCase();
      isDownloaded = isDownloadedOverride ?? false;
      thumbnailUrl = 'thumbnails/${m.id}.webp';
      capaPath = null;
      checksumSha256 = m.hasChecksumSha256Thumbnail() ? m.checksumSha256Thumbnail : null;

      if (m.hasPrecomputados()) {
        final p = m.precomputados;
        final setores = p.totalSetores;
        final vias = p.totalEscaladas;
        statsText = '$setores setores • $vias escaladas';

        if (showDetailedStats) {
          final List<String> modalidades = [];
          if (p.totalBoulders > 0) modalidades.add('${p.totalBoulders} boulders');
          if (p.totalEsportivas > 0) modalidades.add('${p.totalEsportivas} esportivas');
          if (p.totalMoveis > 0) modalidades.add('${p.totalMoveis} móveis');
          if (p.totalMultiplasEnfiadas > 0) {
            modalidades.add('${p.totalMultiplasEnfiadas} múltiplas enfiadas');
          }
          if (p.totalHighlines > 0) modalidades.add('${p.totalHighlines} highlines');
          if (modalidades.isNotEmpty) {
            statsText += ' (${modalidades.join(', ')})';
          }
        }
      }
    } else {
      final ResumoPico r = crag is ResumoPico
          ? crag as ResumoPico
          : ResumoPico.deMapa(crag is Map<String, dynamic>
              ? crag as Map<String, dynamic>
              : Map<String, dynamic>.from(crag as Map));
      id = r.id;
      nome = r.nome.isEmpty ? 'SEM NOME' : r.nome.toUpperCase();
      isDownloaded = isDownloadedOverride ?? r.isDownloaded;
      thumbnailUrl = r.thumbnailUrl;
      capaPath = (r.capaPath?.isNotEmpty == true) ? r.capaPath : null;
      checksumSha256 = r.checksum.isNotEmpty ? r.checksum : null;

      if (r.estatisticas != null) {
        final stats = r.estatisticas!;
        final setores = stats.totalSetores;
        final vias = stats.totalVias;
        statsText = '$setores setores • $vias escaladas';

        if (showDetailedStats) {
          final List<String> modalidades = [];
          if (stats.totalBoulders > 0) modalidades.add('${stats.totalBoulders} boulders');
          if (stats.totalEsportivas > 0) modalidades.add('${stats.totalEsportivas} esportivas');
          if (stats.totalMoveis > 0) modalidades.add('${stats.totalMoveis} móveis');
          if (stats.totalMultiplasEnfiadas > 0) {
            modalidades.add('${stats.totalMultiplasEnfiadas} múltiplas enfiadas');
          }
          if (stats.totalHighlines > 0) modalidades.add('${stats.totalHighlines} highlines');
          if (modalidades.isNotEmpty) {
            statsText += ' (${modalidades.join(', ')})';
          }
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
        height: 200,
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
            buildCragBackground(
              thumbnailUrl,
              cragId: id,
              capaPath: capaPath,
              checksumSha256: checksumSha256,
            ),
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
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                            ).withValues(alpha: 0.9),
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
                          final progress = downloadingMap[id];
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

/// Widget interno para carregar o plano de fundo da imagem do pico,
/// resolvendo primeiro do armazenamento local e caindo para rede se necessário
/// através de [ProvedorImagemAresta].
class _CragBackgroundWidget extends StatefulWidget {
  final String thumbnailUrl;
  final String? cragId;
  final String? capaPath;
  final String? checksumSha256;

  const _CragBackgroundWidget({
    required this.thumbnailUrl,
    this.cragId,
    this.capaPath,
    this.checksumSha256,
  });

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
        oldWidget.cragId != widget.cragId ||
        oldWidget.capaPath != widget.capaPath ||
        oldWidget.checksumSha256 != widget.checksumSha256) {
      _inicializarProvedor();
    }
  }

  void _inicializarProvedor() {
    _provedorImagemFuture = null;
    String? cragId = widget.cragId;
    if ((cragId == null || cragId.isEmpty) && widget.thumbnailUrl.isNotEmpty) {
      final correspondencia =
          RegExp(r'thumbnails/([^/?#]+)\.webp').firstMatch(widget.thumbnailUrl);
      if (correspondencia != null) {
        cragId = correspondencia.group(1);
      }
    }

    // Prioriza capaPath local ou remoto; se ausente, recorre a thumbnailUrl ou padrão canônico
    final String caminhoFinal;
    if (widget.capaPath != null && widget.capaPath!.isNotEmpty) {
      caminhoFinal = widget.capaPath!;
    } else if (widget.thumbnailUrl.isNotEmpty) {
      caminhoFinal = widget.thumbnailUrl;
    } else if (cragId != null && cragId.isNotEmpty) {
      caminhoFinal = 'thumbnails/$cragId.webp';
    } else {
      return;
    }

    _provedorImagemFuture = ProvedorImagemAresta.resolver(
      picoId: cragId ?? '',
      caminho: caminhoFinal,
      checksumSha256: widget.checksumSha256,
      larguraAlvo: 300,
    );
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

/// Constrói o fundo visual do card do pico com suporte a cache local e ProvedorImagemAresta.
Widget buildCragBackground(
  String thumbnailUrl, {
  String? cragId,
  String? capaPath,
  String? checksumSha256,
}) {
  return _CragBackgroundWidget(
    thumbnailUrl: thumbnailUrl,
    cragId: cragId,
    capaPath: capaPath,
    checksumSha256: checksumSha256,
  );
}
