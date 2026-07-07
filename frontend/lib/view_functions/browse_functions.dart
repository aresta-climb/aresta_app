import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../services/http/zip_interceptor_client.dart';
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
  Map<String, double> downloadingCrags, {
  required ValueChanged<String> onSearchChanged,
  required Function(Map<String, dynamic>) onDownload,
  Function(Map<String, dynamic>)? onOpen,
  VoidCallback? onAddExperimental,
  Set<String> nearbyAvailableCrags = const {},
}) {
  return Column(
    children: [
      const SizedBox(height: 10),
      buildSearchBar(onChanged: onSearchChanged),
      Expanded(
        child: _buildCragList(
          context,
          availableCrags,
          downloadingCrags,
          onDownload,
          onOpen: onOpen,
          onAddExperimental: onAddExperimental,
          nearbyAvailableCrags: nearbyAvailableCrags,
        ),
      ),
    ],
  );
}

/// Constrói a lista rolável de picos disponíveis.
///
/// Se [availableCrags] estiver vazio, exibe uma mensagem de fallback indicando que nenhum pico foi encontrado.
Widget _buildCragList(
  BuildContext context,
  List<Map<String, dynamic>> availableCrags,
  Map<String, double> downloadingCrags,
  Function(Map<String, dynamic>) onDownload, {
  Function(Map<String, dynamic>)? onOpen,
  VoidCallback? onAddExperimental,
  Set<String> nearbyAvailableCrags = const {},
}) {
  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            buildBrowseSectionTitle('Picos Disponíveis'),
            _AnimatedMapButton(
              onPressed: () {
                AppNav.toMapaoGlobal(
                  context,
                  crags: availableCrags,
                );
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
              icon: Icon(Icons.add_circle_outline, color: beastHide, size: 20),
              label: Text(
                'TROCAR SERVING',
                style: TextStyle(
                  color: beastHide,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  fontSize: 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: beastHide, width: 1.5),
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
                style: TextStyle(color: fishBone, fontSize: 16),
              ),
            ),
          )
        else
          ...availableCrags.map(
            (crag) => buildCragListItem(
              crag,
              downloadingCrags[crag['id']],
              () => onDownload(crag),
              onOpen: onOpen != null ? () => onOpen(crag) : null,
              isAvailableP2P: nearbyAvailableCrags.contains(crag['id']),
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

class _AnimatedMapButtonState extends State<_AnimatedMapButton> with SingleTickerProviderStateMixin {
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
        child: ElevatedButton.icon(
          icon: const Icon(Icons.map, color: Colors.black, size: 18),
          label: const Text(
            'Mapa',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              fontSize: 13,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC0A080), // beastHide
            foregroundColor: Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}

/// Constrói um título de seção estilizado para a lista de exploração.
Widget buildBrowseSectionTitle(String title) {
  return Text(
    title,
    style: TextStyle(
      color: fishBone,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  );
}

/// Constrói um item de lista individual representando um pico que pode ser baixado.
///
/// O card é expansível: no estado colapsado mostra ícone, nome e local.
/// Ao expandir, também exibe a data do último update e o botão de download.
Widget buildCragListItem(
  Map<String, dynamic> crag,
  double? downloadProgress,
  VoidCallback onDownload, {
  VoidCallback? onOpen,
  bool isAvailableP2P = false,
}) {
  return _CragListItem(crag: crag, downloadProgress: downloadProgress, onDownload: onDownload, onOpen: onOpen, isAvailableP2P: isAvailableP2P);
}

/// Widget com estado para o card expansível de cada pico.
class _CragListItem extends StatefulWidget {
  const _CragListItem({
    required this.crag,
    required this.downloadProgress,
    required this.onDownload,
    this.onOpen,
    this.isAvailableP2P = false,
  });

  final Map<String, dynamic> crag;
  final double? downloadProgress;
  final VoidCallback onDownload;
  final VoidCallback? onOpen;
  final bool isAvailableP2P;

  @override
  State<_CragListItem> createState() => _CragListItemState();
}

class _CragListItemState extends State<_CragListItem>
    with TickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _chevronController;
  late final Animation<double> _chevronAngle;
  late final AnimationController _p2pPulseController;

  @override
  void initState() {
    super.initState();
    _chevronController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _chevronAngle = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _chevronController, curve: Curves.easeInOut),
    );
    
    _p2pPulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    if (widget.isAvailableP2P) {
      _p2pPulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _CragListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAvailableP2P != oldWidget.isAvailableP2P) {
      if (widget.isAvailableP2P) {
        _p2pPulseController.repeat(reverse: true);
      } else {
        _p2pPulseController.stop();
        _p2pPulseController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _chevronController.dispose();
    _p2pPulseController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _chevronController.forward();
        TelemetryService.instance.logAcaoExplorar(
          safeString(widget.crag['id']),
          'ver_detalhes',
        );
      } else {
        _chevronController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = formatDataUpdate(
      widget.crag['dataUpdate'] as String?,
    );

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark 
        ? (_expanded
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.05))
        : obsidianBrown;
        
    final p2pBgColor = isDark ? Colors.green.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.3);
    final p2pBorderColor = Colors.green.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: AnimatedBuilder(
        animation: _p2pPulseController,
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: double.infinity,
            decoration: BoxDecoration(
              color: widget.isAvailableP2P 
                  ? Color.lerp(baseColor, p2pBgColor, _p2pPulseController.value)
                  : baseColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isAvailableP2P 
                    ? Color.lerp(
                        _expanded ? beastHide.withValues(alpha: 0.4) : fishBone.withValues(alpha: 0.1),
                        p2pBorderColor,
                        _p2pPulseController.value,
                      )!
                    : (_expanded
                        ? beastHide.withValues(alpha: 0.4)
                        : fishBone.withValues(alpha: 0.1)),
                width: 1,
              ),
            ),
            child: child,
          );
        },
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(16),
            splashColor: beastHide.withValues(alpha: 0.1),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Linha principal (sempre visível) ──────────────────
                  Row(
                    children: [
                      _buildCragIcon(safeString(widget.crag['thumbnailUrl']), cragId: safeString(widget.crag['id'])),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              safeString(
                                widget.crag['nome'],
                                fallback: 'Sem Nome',
                              ),
                              style: TextStyle(
                                color: fishBone,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Subtítulo dinâmico: alterna entre local e tempo relativo
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Row(
                                key: ValueKey(_expanded),
                                children: [
                                  Icon(
                                    _expanded
                                        ? Icons.access_time_rounded
                                        : Icons.location_on_outlined,
                                    size: 14,
                                    color: _expanded
                                        ? beastHide.withValues(alpha: 0.8)
                                        : fishBone.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _expanded
                                          ? formatTimeAgo(
                                              widget.crag['dataUpdate']
                                                  as String?,
                                            )
                                          : safeString(
                                              widget.crag['local'],
                                              fallback: 'Local Desconhecido',
                                            ),
                                      style: TextStyle(
                                        color: _expanded
                                            ? beastHide.withValues(alpha: 0.8)
                                            : fishBone.withValues(alpha: 0.6),
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Chevron animado
                      RotationTransition(
                        turns: _chevronAngle,
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: fishBone.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),

                  // ── Área expandida ────────────────────────────────────
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        // Descrição Curta
                        if (widget.crag['descricao'] != null && widget.crag['descricao'].toString().isNotEmpty) ...[
                          Text(
                            widget.crag['descricao'],
                            style: TextStyle(
                              color: fishBone.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Divider(
                          color: fishBone.withValues(alpha: 0.1),
                          thickness: 1,
                          height: 1,
                        ),
                        const SizedBox(height: 12),
                        // Detalhes extras (Localização real + Data completa)
                        if (_expanded) ...[
                          _buildDetailRow(
                            Icons.location_on_rounded,
                            'Localização',
                            safeString(
                              widget.crag['local'],
                              fallback: 'Local Desconhecido',
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            Icons.calendar_today_rounded,
                            'Última atualização',
                            formattedDate.isNotEmpty
                                ? formattedDate
                                : 'Sem data',
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Botão de download ou abrir croqui em largura total
                        _buildDownloadButton(
                          widget.crag,
                          widget.onDownload,
                          widget.downloadProgress,
                          onOpen: widget.onOpen,
                          isAvailableP2P: widget.isAvailableP2P,
                        ),
                      ],
                    ),
                    crossFadeState: _expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                    sizeCurve: Curves.easeInOut,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: beastHide.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: fishBone.withValues(alpha: 0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(value, style: TextStyle(color: fishBone, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Constrói o ícone visual que lidera o item da lista de picos.
///
/// Agora utiliza a thumbnail disponível no servidor se [thumbnailUrl] não estiver vazia,
/// e lida com URLs 'aresta-zip://' baixando os bytes em memória.
Widget _buildCragIcon(String thumbnailUrl, {String? cragId}) {
  Widget content;

  if (thumbnailUrl.isNotEmpty) {
    if (thumbnailUrl.startsWith('aresta-zip://')) {
      content = FutureBuilder<http.Response>(
        future: ZipInterceptorClient().get(Uri.parse(thumbnailUrl)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: beastHide.withValues(alpha: 0.5),
                ),
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.statusCode != 200) {
            return _buildPlaceholderIcon();
          }
          return Image.memory(
            snapshot.data!.bodyBytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
          );
        },
      );
    } else {
      if (cragId != null && cragId.isNotEmpty) {
        content = FutureBuilder<Directory>(
          future: getApplicationDocumentsDirectory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: beastHide.withValues(alpha: 0.5),
                  ),
                ),
              );
            }
            if (snapshot.hasData) {
              final file = File('${snapshot.data!.path}/thumbnails/$cragId.webp');
              if (file.existsSync()) {
                return Image.file(
                  file,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
                );
              }
            }
            return _buildPlaceholderIcon();
          },
        );
      } else {
        content = _buildPlaceholderIcon();
      }
    }
  } else {
    content = _buildPlaceholderIcon();
  }

  return Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: beastHide.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    child: content,
  );
}

/// Ícone de fallback (montanha) usado quando não há thumbnail ou ela falha ao carregar.
Widget _buildPlaceholderIcon() {
  return Center(child: Icon(Icons.terrain, color: beastHide, size: 24));
}

/// Constrói o botão de download em largura total mostrado na área expandida do card.
/// Quando o pico já está baixado, o botão fica desabilitado com estilo acinzentado.
Widget _buildDownloadButton(
  Map<String, dynamic> crag,
  VoidCallback onDownload,
  double? downloadProgress, {
  VoidCallback? onOpen,
  bool isAvailableP2P = false,
}) {
  final bool isDownloaded = crag['isDownloaded'] == true;

  if (downloadProgress != null) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: mossRock.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'BAIXANDO...',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  fontSize: 13,
                  color: fishBone,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: downloadProgress,
                color: fishBone,
                backgroundColor: fishBone.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  if (isDownloaded) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onOpen,
        icon: const Icon(Icons.folder_open_rounded, size: 18),
        label: const Text(
          'ABRIR CROQUI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            fontSize: 13,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: beastHide,
          foregroundColor: nobleBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  // Se não estiver baixado, e estiver disponível via P2P
  if (isAvailableP2P) {
    return _PulsingDownloadButton(onPressed: onDownload);
  }

  // Padrão (Não baixado, apenas Cloud)
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: onDownload,
      icon: const Icon(Icons.download_rounded, size: 18),
      label: const Text(
        'BAIXAR',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          fontSize: 13,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: mossRock,
        foregroundColor: fishBone,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}

class _PulsingDownloadButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _PulsingDownloadButton({required this.onPressed});
  @override
  State<_PulsingDownloadButton> createState() => _PulsingDownloadButtonState();
}

class _PulsingDownloadButtonState extends State<_PulsingDownloadButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _colorAnimation = ColorTween(
      begin: mossRock,
      end: Colors.greenAccent.shade400,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          return ElevatedButton.icon(
            onPressed: widget.onPressed,
            icon: const Icon(Icons.wifi_tethering, size: 18),
            label: const Text(
              'BAIXAR DE UM AMIGO PRÓXIMO',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _colorAnimation.value,
              foregroundColor: nobleBlack,
              elevation: 4,
              shadowColor: Colors.greenAccent.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }
}
