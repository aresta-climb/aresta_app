// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../theme/app_colors.dart';
import 'common_functions.dart';
import '../navigation/navigation_functions.dart';
import '../services/dataset/modelos/resumo_pico.dart';
import '../widgets/crag_card.dart';
export '../widgets/crag_card.dart';

/// Constrói a área de conteúdo principal para a página de Explorar (Browse).
///
/// Ela exibe uma barra de pesquisa e uma lista de picos disponíveis que podem ser baixados.
/// O callback [onSearchChanged] é acionado quando o usuário digita na barra de pesquisa.
/// O callback [onDownload] é acionado quando o usuário toca no botão de download em um item de pico.
Widget buildBrowseBody(
  BuildContext context,
  dynamic availableCrags,
  ValueListenable<Map<String, double>> downloadingCrags, {
  required ValueChanged<String> onSearchChanged,
  required Function(dynamic) onDownload,
  Function(dynamic)? onOpen,
  VoidCallback? onAddExperimental,
  VoidCallback? onFilterPressed,
  VoidCallback? onSyncPressed,
}) {
  final List<ResumoPico> picos = _normalizarPicos(availableCrags);
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
          picos,
          downloadingCrags,
          onDownload,
          onOpen: onOpen,
          onAddExperimental: onAddExperimental,
        ),
      ),
    ],
  );
}

List<ResumoPico> _normalizarPicos(dynamic lista) {
  if (lista == null) return const [];
  if (lista is List<ResumoPico>) return lista;
  if (lista is List) {
    return lista.map((item) {
      if (item is ResumoPico) return item;
      if (item is Map<String, dynamic>) return ResumoPico.deMapa(item);
      if (item is Map) return ResumoPico.deMapa(Map<String, dynamic>.from(item));
      return const ResumoPico(id: '', nome: '', local: '');
    }).toList();
  }
  return const [];
}

Widget _buildCragList(
  BuildContext context,
  List<ResumoPico> availableCrags,
  ValueListenable<Map<String, double>> downloadingCrags,
  Function(dynamic) onDownload, {
  Function(dynamic)? onOpen,
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
  dynamic crag,
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



void showDownloadBottomSheet(
  BuildContext context,
  dynamic crag,
  VoidCallback onDownload,
  ValueListenable<Map<String, double>> downloadingCrags, {
  VoidCallback? onOpen,
}) {
  final ResumoPico pico = crag is ResumoPico
      ? crag
      : ResumoPico.deMapa(crag is Map<String, dynamic>
          ? crag
          : Map<String, dynamic>.from(crag as Map));

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
                pico.nome.isNotEmpty ? pico.nome : 'Pico',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pico.local.isNotEmpty ? pico.local : 'Local Desconhecido',
                style: TextStyle(color: context.colors.ashGrey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (pico.descricao.isNotEmpty) ...[
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      pico.descricao,
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
                  final progress = downloadingMap[pico.id];
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

                  if (pico.isDownloaded && onOpen != null) {
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
