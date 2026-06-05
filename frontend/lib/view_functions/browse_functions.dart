import 'package:flutter/material.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'common_functions.dart';

/// Constrói a área de conteúdo principal para a página de Explorar (Browse).
///
/// Ela exibe uma barra de pesquisa e uma lista de picos disponíveis que podem ser baixados.
/// O callback [onSearchChanged] é acionado quando o usuário digita na barra de pesquisa.
/// O callback [onDownload] é acionado quando o usuário toca no botão de download em um item de pico.
Widget buildBrowseBody(
  BuildContext context, 
  List<Map<String, dynamic>> availableCrags, 
  {
    required ValueChanged<String> onSearchChanged,
    required Function(Map<String, dynamic>) onDownload,
    VoidCallback? onAddExperimental,
  }
) {
  return Column(
    children: [
      const SizedBox(height: 10),
      buildSearchBar(onChanged: onSearchChanged),
      Expanded(
        child: _buildCragList(availableCrags, onDownload, onAddExperimental: onAddExperimental),
      ),
    ],
  );
}

/// Constrói a lista rolável de picos disponíveis.
///
/// Se [availableCrags] estiver vazio, exibe uma mensagem de fallback indicando que nenhum pico foi encontrado.
Widget _buildCragList(
  List<Map<String, dynamic>> availableCrags, 
  Function(Map<String, dynamic>) onDownload,
  {VoidCallback? onAddExperimental}
) {
  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildBrowseSectionTitle('Picos Disponíveis'),
        
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
                  fontSize: 12
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: beastHide, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          ...availableCrags.map((crag) => buildCragListItem(crag, () => onDownload(crag))),
      ],
    ),
  );
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
Widget buildCragListItem(Map<String, dynamic> crag, VoidCallback onDownload) {
  return _CragListItem(crag: crag, onDownload: onDownload);
}

/// Widget com estado para o card expansível de cada pico.
class _CragListItem extends StatefulWidget {
  const _CragListItem({required this.crag, required this.onDownload});

  final Map<String, dynamic> crag;
  final VoidCallback onDownload;

  @override
  State<_CragListItem> createState() => _CragListItemState();
}

class _CragListItemState extends State<_CragListItem>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _chevronController;
  late final Animation<double> _chevronAngle;

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
  }

  @override
  void dispose() {
    _chevronController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _chevronController.forward();
        TelemetryService.instance.logAcaoExplorar(safeString(widget.crag['id']), 'ver_detalhes');
      } else {
        _chevronController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate =
        formatDataUpdate(widget.crag['dataUpdate'] as String?);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _expanded
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expanded
                ? beastHide.withValues(alpha: 0.4)
                : fishBone.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
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
                      _buildCragIcon(safeString(widget.crag['thumbnailUrl'])),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              safeString(widget.crag['nome'],
                                  fallback: 'Sem Nome'),
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
                                          ? formatTimeAgo(widget
                                              .crag['dataUpdate'] as String?)
                                          : safeString(widget.crag['local'],
                                              fallback: 'Local Desconhecido'),
                                      style: TextStyle(
                                        color: _expanded
                                            ? beastHide
                                                .withValues(alpha: 0.8)
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
                            safeString(widget.crag['local'],
                                fallback: 'Local Desconhecido'),
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            Icons.calendar_today_rounded,
                            'Última atualização',
                            formattedDate.isNotEmpty ? formattedDate : 'Sem data',
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Botão de download em largura total
                        _buildDownloadButton(widget.crag, widget.onDownload),
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
              Text(
                value,
                style: TextStyle(
                  color: fishBone,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Constrói o ícone visual que lidera o item da lista de picos.
/// 
/// Agora utiliza a thumbnail disponível no servidor se [thumbnailUrl] não estiver vazia.
Widget _buildCragIcon(String thumbnailUrl) {
  Widget content;

  if (thumbnailUrl.isNotEmpty) {
    content = Image.network(
      thumbnailUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(), // Caso tiver um error, ir para o ícone de fallback
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        double? progressValue;
        if (loadingProgress.expectedTotalBytes != null) {
          progressValue = loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!;
        }

        return Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: beastHide.withValues(alpha: 0.5),
              value: progressValue,
            ),
          ),
        );
      },
    );
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
  return Center(
    child: Icon(
      Icons.terrain,
      color: beastHide,
      size: 24,
    ),
  );
}


/// Constrói o botão de download em largura total mostrado na área expandida do card.
/// Quando o pico já está baixado, o botão fica desabilitado com estilo acinzentado.
Widget _buildDownloadButton(Map<String, dynamic> crag, VoidCallback onDownload) {
  final bool isDownloaded = crag['isDownloaded'] == true;

  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: isDownloaded ? null : onDownload,
      icon: Icon(
        isDownloaded ? Icons.check_rounded : Icons.download_rounded,
        size: 18,
      ),
      label: Text(
        isDownloaded ? 'JÁ BAIXADO' : 'BAIXAR',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          fontSize: 13,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isDownloaded ? Colors.grey.withValues(alpha: 0.2) : Colors.green.shade700,
        foregroundColor: isDownloaded
            ? fishBone.withValues(alpha: 0.4)
            : fishBone,
        disabledBackgroundColor: Colors.grey.withValues(alpha: 0.15),
        disabledForegroundColor: fishBone.withValues(alpha: 0.35),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}
