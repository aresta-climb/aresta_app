import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/firebase/telemetry_service.dart';
import '../services/firebase/app_logger.dart';
import '../services/feedback/feedback_metadata_collector.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../view_functions/common_functions.dart';
import '../view_functions/offline_markdown.dart';
import '../view_functions/via_functions.dart';
import '../services/editor_croqui.dart';
import '../navigation/navigation_functions.dart';

/// A página principal para visualização e interação com croquis topográficos (mapas) offline.
///
/// Esta página fornece um `InteractiveViewer` permitindo pan e zoom fluidos sobre as imagens de mapa.
/// Ela desenha marcadores dinâmicos mapeando coordenadas geométricas (polígonos, caixas, pontos)
/// extraídas dos dados Protobuf (`Mapa_PontoDeInteresse`) para proporções relativas da imagem.
///
/// **Principais Funcionalidades:**
/// - **Resolução Dinâmica Offline**: Localiza e carrega autonomamente a imagem de fundo dentro do diretório do pico local.
/// - **Auto-Zoom (Foco Automático)**: Se acessado através de uma `ViaPage` com a intenção de visualizar um ponto 
///   específico (`initialSelectedId`), o mapa usará uma animação com matriz de transformação (`Matrix4Tween`) 
///   para focar e dar zoom exatamente na rota desejada assim que for renderizado.
/// - **Navegação Circular Segura**: O cartão flutuante exibido na seleção de um marcador permite ir diretamente
///   para a `ViaPage` dele. O mapa repassa o `setorContext` para garantir que a navegação do botão 
///   "Ver no mapa" continue funcionando e inteligentemente executa um `Navigator.pop` caso a via clicada
///   seja a mesma que abriu o mapa, prevenindo um loop infinito na pilha de telas.
class MapaInterativoPage extends StatefulWidget {
  final Mapa mapa;
  final String cragId;
  final List<Escalada> escaladas;
  final List<ArquivoSetor> setores;
  final bool autoZoomEnabled;
  final ImageProvider? imageProviderOverride;
  final String? initialSelectedId;
  final Setor? setorContext;

  const MapaInterativoPage({
    super.key,
    required this.mapa,
    required this.cragId,
    this.escaladas = const [],
    this.setores = const [],
    this.autoZoomEnabled = true,
    this.imageProviderOverride,
    this.initialSelectedId,
    this.setorContext,
  });

  @override
  State<MapaInterativoPage> createState() => _MapaInterativoPageState();
}

class _MapaInterativoPageState extends State<MapaInterativoPage>
    with SingleTickerProviderStateMixin {
  String? _selectedId;
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _zoomAnimation;

  final Map<String, List<dynamic>> _idMap = {};
  Future<ImageProvider?>? _imageProviderFuture;
  late bool _autoZoomEnabled;
  bool _initialZoom = false;
  Size? _imageSize;
  int _focusedItemIndex = 0;

  @override
  void initState() {
    super.initState();
    _autoZoomEnabled = widget.autoZoomEnabled;
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.addListener(() {
      if (_zoomAnimation != null) {
        _transformationController.value = _zoomAnimation!.value;
      }
    });

    _idMap.addAll(
      MapHelper.buildIdMap(
        mapa: widget.mapa,
        escaladas: widget.escaladas,
        setores: widget.setores,
      ),
    );
    
    if (widget.initialSelectedId != null) {
      _selectedId = widget.initialSelectedId;
    }
    _updateFeedbackNode();

    _imageProviderFuture = widget.imageProviderOverride != null
        ? Future.value(widget.imageProviderOverride)
        : _resolveImageProvider();
  }

  void _updateFeedbackNode() {
    if (_selectedId == null) {
      FeedbackMetadataCollector.globalActiveNodeOverride = null;
    } else {
      final items = _idMap[_selectedId];
      final item = items != null && items.isNotEmpty ? items.first : null;
      final viaName = item != null ? getEscaladaNome(item) : _selectedId;
      final fileName = widget.mapa.caminhoImagemMapa.split('/').last;
      FeedbackMetadataCollector.globalActiveNodeOverride = 'MapaInterativoNode($fileName, Via: $viaName)';
    }
  }

  Future<ImageProvider?> _resolveImageProvider() async {
    final dir = await getApplicationDocumentsDirectory();
    final editor = EditorDeCroqui.instance;
    final downloadsPath = '${editor.downloadsPath(dir.path)}/${widget.cragId}';

    String path = widget.mapa.caminhoImagemMapa;
    String fileName = path.split('/').last;

    File? localFile;
    
    // 1. Se for uma URL absoluta, tentamos extrair o caminho relativo
    const baseUrl = 'https://aresta-climb.github.io/aresta_serving/';
    if (path.startsWith(baseUrl)) {
      final relativePath = path.replaceFirst(baseUrl, '');
      final directFile = File('$downloadsPath/$relativePath');
      if (directFile.existsSync()) {
        localFile = directFile;
      }
    }

    // 2. Tenta usar o caminho diretamente como um caminho relativo
    if (localFile == null) {
      String cleanPath = path.startsWith('/') ? path.substring(1) : path;
      final directFile = File('$downloadsPath/$cleanPath');
      if (directFile.existsSync()) {
        localFile = directFile;
      }
    }

    // 2. Fallback: Procura pelo nome do arquivo recursivamente
    if (localFile == null && fileName.isNotEmpty) {
      final searchName = Uri.decodeComponent(fileName).toLowerCase();
      String searchBaseName = searchName.contains('.')
          ? searchName.substring(0, searchName.lastIndexOf('.'))
          : searchName;

      try {
        final downloadsDir = Directory(downloadsPath);
        if (downloadsDir.existsSync()) {
          final entities = downloadsDir.listSync(recursive: true);
          for (var entity in entities) {
            if (entity is File) {
              final String ePath = entity.path.replaceAll('\\', '/');
              final String eName = ePath.split('/').last;
              final String eNameLower = Uri.decodeComponent(
                eName,
              ).toLowerCase();
              if (eNameLower == searchName) {
                localFile = entity;
                break;
              }
              String eBaseName = eNameLower.contains('.')
                  ? eNameLower.substring(0, eNameLower.lastIndexOf('.'))
                  : eNameLower;
              if (eBaseName == searchBaseName) {
                localFile = entity;
                break;
              }
            }
          }
        }
      } catch (e) {
        // ignora erros de leitura
      }
    }

    if (localFile != null && localFile.existsSync()) {
      return FileImage(localFile);
    }

    AppLogger.instance.logError('Erro: Imagem do mapa não encontrada localmente: $path');
    return null;
  }

  @override
  void dispose() {
    FeedbackMetadataCollector.globalActiveNodeOverride = null;
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  List<Mapa_PontoDeInteresse> _getPontosForItem(dynamic item) {
    if (item == null) return [];
    
    List<String> ids = [];
    if (item is Escalada) {
      ids = MapHelper.getEscaladaIdsNoMapa(item);
    } else if (item is Setor) {
      ids = [item.idNoMapa];
    }
    
    return widget.mapa.pontosDeInteresse.where((p) => ids.contains(p.id)).toList();
  }

  void _onMarkerTap(
    Mapa_PontoDeInteresse marker,
    BoxConstraints constraints,
    Size viewportSize, {
    bool isUserInteraction = true,
  }) {
    setState(() {
      _selectedId = marker.id;
      _focusedItemIndex = 0;
      _updateFeedbackNode();
    });

    final items = _idMap[marker.id];
    if (items != null && items.isNotEmpty) {
      final item = items.first;
      if (isUserInteraction && item is Escalada) {
        TelemetryService.instance.logAcaoEscalada(
          widget.cragId,
          widget.setorContext?.nome ?? 'Geral',
          getEscaladaNome(item),
          'selecionar_no_mapa',
          'mapa'
        );
      }

      if (_autoZoomEnabled) {
        final pontos = _getPontosForItem(item);
        _zoomToPoints(pontos, Size(constraints.maxWidth, constraints.maxHeight), viewportSize, contextItem: item);
      }
    }
  }

  void _zoomToPoints(
    List<Mapa_PontoDeInteresse> pontos,
    Size childSize,
    Size viewportSize, {
    dynamic contextItem,
  }) {
    if (pontos.isEmpty) return;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (var p in pontos) {
      final areaInfo = AreaHelper.getAreaInfo(p);
      if (areaInfo != null) {
        if (areaInfo.bounds.left < minX) minX = areaInfo.bounds.left;
        if (areaInfo.bounds.top < minY) minY = areaInfo.bounds.top;
        if (areaInfo.bounds.right > maxX) maxX = areaInfo.bounds.right;
        if (areaInfo.bounds.bottom > maxY) maxY = areaInfo.bounds.bottom;
      }
    }

    if (minX == double.infinity) return;

    final double relMinX = minX / widget.mapa.larguraMapa;
    final double relMinY = minY / widget.mapa.alturaMapa;
    final double relMaxX = maxX / widget.mapa.larguraMapa;
    final double relMaxY = maxY / widget.mapa.alturaMapa;

    final double relCenterX = relMinX + (relMaxX - relMinX) / 2;
    final double relCenterY = relMinY + (relMaxY - relMinY) / 2;

    double targetScale = 2.5; // Fixed default for single points

    final boxWidthRel = relMaxX - relMinX;
    final boxHeightRel = relMaxY - relMinY;

    bool hasInicioEFim = false;
    if (pontos.length > 1) {
      if (contextItem is Escalada) {
        final ids = MapHelper.getEscaladaIdsNoMapa(contextItem);
        bool hasInicio = ids.isNotEmpty && ids[0].isNotEmpty;
        bool hasFim = ids.length > 2 && ids[2].isNotEmpty;
        hasInicioEFim = hasInicio && hasFim;
      } else {
        hasInicioEFim = true;
      }
    }

    if (hasInicioEFim && (boxWidthRel > 0 || boxHeightRel > 0)) {
      // Usa lógica de Bounding Box apenas para vias grandes (início e fim)
      final double availableHeight = viewportSize.height * 0.55;
      final double availableWidth = viewportSize.width * 0.85;
      
      final double scaleX = availableWidth / (boxWidthRel * childSize.width);
      final double scaleY = availableHeight / (boxHeightRel * childSize.height);
      
      if (scaleX.isFinite && scaleY.isFinite) {
        final calculatedScale = math.min(scaleX, scaleY);
        targetScale = math.min(math.max(calculatedScale, 1.0), 5.0);
      }
    }

    final double markerX = relCenterX * childSize.width;
    final double markerY = relCenterY * childSize.height;

    final double offsetX = (viewportSize.width - childSize.width) / 2;
    final double offsetY = (viewportSize.height - childSize.height) / 2;

    final double actualMarkerX = markerX + offsetX;
    final double actualMarkerY = markerY + offsetY;

    // Centro visual do mapa padrão é 35% do topo (área livre acima do card)
    double visualCenterY = viewportSize.height * 0.35;

    if (pontos.length == 1 && contextItem is Escalada) {
      final ids = MapHelper.getEscaladaIdsNoMapa(contextItem);
      bool hasInicio = ids.isNotEmpty && ids[0].isNotEmpty;
      bool hasMeio = ids.length > 1 && ids[1].isNotEmpty;
      bool hasFim = ids.length > 2 && ids[2].isNotEmpty;

      if (hasInicio && !hasMeio && !hasFim) {
        // Só início: joga o ponto mais pra baixo (perto do card) para ver a parede pra cima
        visualCenterY = viewportSize.height * 0.60;
      } else if (!hasInicio && hasMeio && !hasFim) {
        // Só meio: centro da área visível
        visualCenterY = viewportSize.height * 0.35;
      } else if (!hasInicio && !hasMeio && hasFim) {
        // Só fim: joga o ponto mais pra cima (perto do topo) para ver a parede pra baixo
        visualCenterY = viewportSize.height * 0.15;
      }
    }

    final double targetX =
        (viewportSize.width / 2) - (actualMarkerX * targetScale);
    final double targetY =
        visualCenterY - (actualMarkerY * targetScale);

    final Matrix4 targetMatrix = Matrix4.identity()
      ..translate(targetX, targetY)
      ..scale(targetScale);

    _zoomAnimation =
        Matrix4Tween(
          begin: _transformationController.value,
          end: targetMatrix,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _animationController.forward(from: 0);
  }

  List<Widget> _buildMarkers(BoxConstraints constraints, Size viewportSize) {
    if (widget.mapa.larguraMapa == 0 || widget.mapa.alturaMapa == 0) return [];

    return widget.mapa.pontosDeInteresse.map((ponto) {
      final areaInfo = AreaHelper.getAreaInfo(ponto);
      if (areaInfo == null) return const SizedBox.shrink();

      final minX = areaInfo.bounds.left;
      final maxX = areaInfo.bounds.right;
      final minY = areaInfo.bounds.top;
      final maxY = areaInfo.bounds.bottom;
      final polygon = areaInfo.polygon;

      final relLeft = minX / widget.mapa.larguraMapa;
      final relTop = minY / widget.mapa.alturaMapa;
      final relWidth = (maxX - minX) / widget.mapa.larguraMapa;
      final relHeight = (maxY - minY) / widget.mapa.alturaMapa;

      bool isSelected = false;
      if (_selectedId != null) {
        final items = _idMap[_selectedId!];
        if (items != null && items.isNotEmpty && _focusedItemIndex < items.length) {
          final focusedItem = items[_focusedItemIndex];
          if (focusedItem is Escalada) {
            final ids = MapHelper.getEscaladaIdsNoMapa(focusedItem);
            isSelected = ids.contains(ponto.id);
          } else if (focusedItem is Setor) {
            isSelected = focusedItem.idNoMapa == ponto.id;
          }
        }
      }

      final double hitBoxPadding = 4.0;

      return Positioned(
        left: (relLeft * constraints.maxWidth) - hitBoxPadding,
        top: (relTop * constraints.maxHeight) - hitBoxPadding,
        width: (relWidth * constraints.maxWidth) + (hitBoxPadding * 2),
        height: (relHeight * constraints.maxHeight) + (hitBoxPadding * 2),
        child: GestureDetector(
          key: Key('marker_${ponto.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => _onMarkerTap(ponto, constraints, viewportSize),
          child: CustomPaint(
            painter: MarkerPainter(
              polygon: polygon,
              minX: minX,
              minY: minY,
              mapWidth: widget.mapa.larguraMapa.toDouble(),
              mapHeight: widget.mapa.alturaMapa.toDouble(),
              constraints: constraints,
              isSelected: isSelected,
              padding: hitBoxPadding,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildCardContentForItem(dynamic item) {
    String title = '';
    Widget? subtitleWidget;
    VoidCallback? onTap;
    List<Widget> extraInfo = [];

    Widget buildCardInfo(String label, String value) {
      if (value.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$label: ',
                style: TextStyle(
                  color: beastHide,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              TextSpan(
                text: value,
                style: TextStyle(color: fishBone, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    String formatGrade(dynamic dificuldade) {
      String g = dificuldade.name
          .replaceAll('BR_', '')
          .replaceAll('_BARRA_', '/')
          .replaceAll('_', ' ')
          .toLowerCase();

      return g.replaceAllMapped(RegExp(r'\b([1-6])(sup)?\b'), (match) {
        if (match.group(2) == 'sup') {
          return '${match.group(1)}ºsup';
        } else {
          return '${match.group(1)}º';
        }
      });
    }

    if (item is Escalada) {
      switch (item.whichTipo()) {
        case Escalada_Tipo.viaEsportiva:
          final v = item.viaEsportiva;
          title = v.nome;
          String sub = 'Esportiva | ${formatGrade(v.dificuldade)}';
          if (v.quantidadeProtecoesIntermediarias > 0 ||
              v.quantidadeProtecoesParada > 0) {
            String protecoes = '${v.quantidadeProtecoesIntermediarias}';
            if (v.quantidadeProtecoesParada > 0) {
              protecoes += '+${v.quantidadeProtecoesParada}';
            }
            sub += ' | $protecoes';
          }
          subtitleWidget = Text(
            sub,
            style: TextStyle(
              color: fishBone.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          );
          extraInfo.add(buildCardInfo('Ancoragem', v.tipoAncoragem));
          if (v.descricao.isNotEmpty) {
            extraInfo.add(const SizedBox(height: 8));
            extraInfo.add(
              OfflineMarkdown(data: v.descricao, cragId: widget.cragId),
            );
          }
          break;
        case Escalada_Tipo.viaMovel:
          final v = item.viaMovel;
          title = v.nome;
          subtitleWidget = RichText(
            text: TextSpan(
              style: TextStyle(
                color: fishBone.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              children: [
                const TextSpan(text: 'Móvel | '),
                TextSpan(text: formatGrade(v.dificuldade)),
                const TextSpan(text: ' | '),
                const TextSpan(
                  text: 'Móvel',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
          extraInfo.add(buildCardInfo('Ancoragem', v.tipoAncoragem));
          extraInfo.add(buildCardInfo('Peças', v.protecoesMoveis));
          if (v.descricao.isNotEmpty) {
            extraInfo.add(const SizedBox(height: 8));
            extraInfo.add(
              OfflineMarkdown(data: v.descricao, cragId: widget.cragId),
            );
          }
          break;
        case Escalada_Tipo.boulder:
          final v = item.boulder;
          title = v.nome;
          subtitleWidget = Text(
            'Boulder | ${formatGrade(v.dificuldade)}',
            style: TextStyle(
              color: fishBone.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          );
          if (v.descricao.isNotEmpty) {
            extraInfo.add(const SizedBox(height: 8));
            extraInfo.add(
              OfflineMarkdown(data: v.descricao, cragId: widget.cragId),
            );
          }
          break;
        case Escalada_Tipo.viaMultiplasEnfiadas:
          final v = item.viaMultiplasEnfiadas;
          title = v.nome;
          subtitleWidget = Text(
            'Múltiplas Enfiadas | ${v.numeroEnfiadas} enfiadas | ${v.comprimentoTotal}m',
            style: TextStyle(
              color: fishBone.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          );
          if (v.descricao.isNotEmpty) {
            extraInfo.add(const SizedBox(height: 8));
            extraInfo.add(
              OfflineMarkdown(data: v.descricao, cragId: widget.cragId),
            );
          }
          break;
        case Escalada_Tipo.highline:
          final v = item.highline;
          title = v.nome;
          subtitleWidget = Text(
            'Highline | ${v.distancia}m',
            style: TextStyle(
              color: fishBone.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          );
          if (v.descricao.isNotEmpty) {
            extraInfo.add(const SizedBox(height: 8));
            extraInfo.add(
              OfflineMarkdown(data: v.descricao, cragId: widget.cragId),
            );
          }
          break;
        case Escalada_Tipo.notSet:
          break;
      }

      onTap = () {
        bool isOriginal = false;
        if (widget.initialSelectedId != null) {
          final ids = MapHelper.getEscaladaIdsNoMapa(item);
          if (ids.contains(widget.initialSelectedId)) {
            isOriginal = true;
          }
        }

        if (isOriginal) {
          AppNav.back(context);
        } else {
          TelemetryService.instance.logAcaoEscalada(
            widget.cragId,
            widget.setorContext?.nome ?? 'Geral',
            title,
            'abrir_detalhes',
            'mapa'
          );
          AppNav.toVia(context, escalada: item, setor: widget.setorContext);
        }
      };
    } else if (item is Setor) {
      title = item.nome;
      subtitleWidget = Text(
        'Setor',
        style: TextStyle(color: fishBone.withValues(alpha: 0.7), fontSize: 14),
      );
      onTap = () => AppNav.toSetor(context, setor: item);
    }

    String resolvedLabel = '';
    if (item is Escalada) {
      List<String> rawIds = MapHelper.getEscaladaIdsNoMapa(item);
      rawIds.removeWhere((id) => id.isEmpty);
      
      if (rawIds.isNotEmpty) {
        final pointsMap = {for (var p in widget.mapa.pontosDeInteresse) p.id: p.label};
        List<String> labels = [];
        for (var id in rawIds) {
          if (pointsMap.containsKey(id)) {
            labels.add(pointsMap[id]!.isNotEmpty ? pointsMap[id]! : id);
          }
        }
        if (labels.isNotEmpty) {
          resolvedLabel = labels.join('-');
        }
      }
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (resolvedLabel.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: nobleBlack,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: beastHide.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                resolvedLabel,
                                style: TextStyle(
                                  color: fishBone,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: beastHide,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (subtitleWidget != null) ...[
                        const SizedBox(height: 4),
                        subtitleWidget,
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: fishBone),
                  onPressed: () {
                    setState(() {
                      _selectedId = null;
                      _updateFeedbackNode();
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            if (extraInfo.isNotEmpty) ...[
              Divider(color: beastHide, height: 24),
              ...extraInfo,
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onTap,
                icon: Icon(
                  Icons.open_in_new,
                  color: beastHide,
                  size: 16,
                ),
                label: Text(
                  'Mais',
                  style: TextStyle(
                    color: beastHide,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingCard(BoxConstraints constraints, Size viewportSize) {
    if (_selectedId == null) return const SizedBox.shrink();

    final items = _idMap[_selectedId!];
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    Widget content;
    if (items.length > 1) {
      void changeItem(int newIndex) {
        setState(() {
          _focusedItemIndex = newIndex;
        });
        
        final newItem = items[newIndex];
        if (newItem is Escalada) {
          TelemetryService.instance.logAcaoEscalada(
            widget.cragId,
            widget.setorContext?.nome ?? 'Geral',
            getEscaladaNome(newItem),
            'selecionar_no_mapa',
            'mapa_swipe'
          );
        }

        if (_autoZoomEnabled && _imageSize != null) {
          final pontos = _getPontosForItem(newItem);
          _zoomToPoints(pontos, _imageSize!, viewportSize, contextItem: newItem);
        }
      }

      content = GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            if (_focusedItemIndex > 0) changeItem(_focusedItemIndex - 1);
          } else if (details.primaryVelocity! < 0) {
            if (_focusedItemIndex < items.length - 1) changeItem(_focusedItemIndex + 1);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    color: _focusedItemIndex > 0 ? beastHide : fishBone.withValues(alpha: 0.3),
                    onPressed: _focusedItemIndex > 0 ? () => changeItem(_focusedItemIndex - 1) : null,
                  ),
                  ...List.generate(items.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _focusedItemIndex ? beastHide : fishBone.withValues(alpha: 0.3),
                      ),
                    );
                  }),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    color: _focusedItemIndex < items.length - 1 ? beastHide : fishBone.withValues(alpha: 0.3),
                    onPressed: _focusedItemIndex < items.length - 1 ? () => changeItem(_focusedItemIndex + 1) : null,
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: KeyedSubtree(
                key: ValueKey(_focusedItemIndex),
                child: _buildCardContentForItem(items[_focusedItemIndex]),
              ),
            ),
          ],
        ),
      );
    } else {
      content = _buildCardContentForItem(items.first);
    }

    return Card(
      color: obsidianBrown,
      elevation: 8,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: beastHide.withValues(alpha: 0.3), width: 1),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mapa.larguraMapa == 0 || widget.mapa.alturaMapa == 0) {
      return const SizedBox.shrink(); // Mapa inválido
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppNav.back(context),
        ),
        title: const Text(
          'Croqui Interativo',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          buildFeedbackButton(context, color: Colors.white),
          const SizedBox(width: 12),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, viewportConstraints) {
          final viewportSize = Size(
            viewportConstraints.maxWidth,
            viewportConstraints.maxHeight,
          );
          return FutureBuilder<ImageProvider?>(
            future: _imageProviderFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: beastHide),
                );
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const SizedBox.shrink();
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_selectedId != null) {
                    setState(() {
                      _selectedId = null;
                      _updateFeedbackNode();
                    });
                  }
                },
                child: Stack(
                  children: [
                    // Camada 1: Mapa e Marcadores
                  InteractiveViewer(
                    transformationController: _transformationController,
                    boundaryMargin: EdgeInsets.symmetric(
                      horizontal: viewportSize.width / 2,
                      vertical: viewportSize.height / 2,
                    ),
                    minScale: 0.5,
                    maxScale: 6.0,
                    constrained: true,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio:
                            widget.mapa.larguraMapa / widget.mapa.alturaMapa,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            _imageSize = Size(constraints.maxWidth, constraints.maxHeight);
                            if (!_initialZoom && _selectedId != null && _autoZoomEnabled) {
                              _initialZoom = true;
                              Mapa_PontoDeInteresse? targetMarker;
                              for (var p in widget.mapa.pontosDeInteresse) {
                                if (p.id == _selectedId) {
                                  targetMarker = p;
                                  break;
                                }
                              }
                              if (targetMarker != null) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    _onMarkerTap(targetMarker!, constraints, viewportSize, isUserInteraction: false);
                                  }
                                });
                              }
                            }

                            return Stack(
                                  children: [
                                  Image(
                                    image: snapshot.data!,
                                    fit: BoxFit.contain,
                                    width: constraints.maxWidth,
                                    height: constraints.maxHeight,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                color: Colors.grey,
                                                size: 50,
                                              ),
                                            ),
                                  ),
                                  ..._buildMarkers(constraints, viewportSize),
                                ],
                              );
                            },
                        ),
                      ),
                    ),
                  ),

                  // Camada 2: Card Flutuante
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    bottom: _selectedId != null
                        ? 20 + MediaQuery.of(context).padding.bottom
                        : -150,
                    left: 20,
                    right: 20,
                    child: _buildFloatingCard(viewportConstraints, viewportSize),
                  ),
                  // Camada 3: Toggle Auto-Zoom
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: nobleBlack.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _autoZoomEnabled
                              ? Icons.gps_fixed
                              : Icons.gps_not_fixed,
                          color: _autoZoomEnabled
                              ? beastHide
                              : fishBone.withValues(alpha: 0.5),
                        ),
                        tooltip: _autoZoomEnabled
                            ? 'Desativar Auto-Zoom'
                            : 'Ativar Auto-Zoom',
                        onPressed: () {
                          setState(() {
                            _autoZoomEnabled = !_autoZoomEnabled;
                          });
                        },
                      ),
                    ),
                  ),
                  if (widget.setorContext != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: SafeArea(
                        child: FloatingActionButton.extended(
                          heroTag: 'btnMapaGeral',
                          onPressed: () {
                            TelemetryService.instance.logAcaoEscalada(
                              widget.cragId, 
                              widget.setorContext!.nome, 
                              'Geral', 
                              'abrir_mapa_geral', 
                              'mapa_setor'
                            );
                            AppNav.toMapaGeralPico(context, returnToSetor: widget.setorContext);
                          },
                          backgroundColor: beastHide,
                          icon: Icon(Icons.map, color: nobleBlack),
                          label: Text('Mapa Geral', style: TextStyle(color: nobleBlack, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ],
              ),
            );
            },
          );
        },
      ),
    );
  }
}

class AreaInfo {
  final List<Offset> polygon;
  final Rect bounds;

  AreaInfo({required this.polygon, required this.bounds});
}

class AreaHelper {
  static AreaInfo? getAreaInfo(Mapa_PontoDeInteresse ponto) {
    List<Offset> polygon = [];
    double minX, minY, maxX, maxY;

    switch (ponto.whichTipoArea()) {
      case Mapa_PontoDeInteresse_TipoArea.circular:
        final c = ponto.circular;
        final int points = 32;
        for (int i = 0; i < points; i++) {
          final double theta = 2.0 * math.pi * i / points;
          polygon.add(
            Offset(
              c.x + c.raio * math.cos(theta),
              c.y + c.raio * math.sin(theta),
            ),
          );
        }
        minX = (c.x - c.raio).toDouble();
        maxX = (c.x + c.raio).toDouble();
        minY = (c.y - c.raio).toDouble();
        maxY = (c.y + c.raio).toDouble();
        break;

      case Mapa_PontoDeInteresse_TipoArea.box:
        final b = ponto.box;
        final double w2 = b.comprimento / 2.0;
        final double h2 = b.largura / 2.0;
        final double angle = (b.anguloGrausX100 / 100.0) * math.pi / 180.0;

        final List<Offset> corners = [
          Offset(-w2, -h2),
          Offset(w2, -h2),
          Offset(w2, h2),
          Offset(-w2, h2),
        ];

        for (var corner in corners) {
          final double rotatedX =
              b.x + corner.dx * math.cos(angle) - corner.dy * math.sin(angle);
          final double rotatedY =
              b.y + corner.dx * math.sin(angle) + corner.dy * math.cos(angle);
          polygon.add(Offset(rotatedX, rotatedY));
        }

        minX = polygon.map((p) => p.dx).reduce(math.min);
        maxX = polygon.map((p) => p.dx).reduce(math.max);
        minY = polygon.map((p) => p.dy).reduce(math.min);
        maxY = polygon.map((p) => p.dy).reduce(math.max);
        break;

      case Mapa_PontoDeInteresse_TipoArea.areaLivre:
        final al = ponto.areaLivre;
        if (al.coordenadas.length < 2) return null;
        for (int i = 0; i < al.coordenadas.length; i += 2) {
          polygon.add(
            Offset(al.coordenadas[i].toDouble(), al.coordenadas[i + 1].toDouble()),
          );
        }
        minX = polygon.map((p) => p.dx).reduce(math.min);
        maxX = polygon.map((p) => p.dx).reduce(math.max);
        minY = polygon.map((p) => p.dy).reduce(math.min);
        maxY = polygon.map((p) => p.dy).reduce(math.max);
        break;

      default:
        return null;
    }

    return AreaInfo(
      polygon: polygon,
      bounds: Rect.fromLTRB(minX, minY, maxX, maxY),
    );
  }
}

class MapaResolutionResult {
  final Mapa mapa;
  final List<Escalada> escaladas;
  final List<ArquivoSetor> setores;

  MapaResolutionResult({
    required this.mapa,
    required this.escaladas,
    required this.setores,
  });
}

class MapHelper {
  static MapaResolutionResult resolveMapaAndContext({
    required Pico pico,
    required String mapaCaminhoImagem,
    String? setorContextNome,
    String? grupoContextNome,
  }) {
    Mapa? mapa;

    // Busca o mapa nas diferentes estruturas do Pico
    for (var sg in pico.setoresOuGrupos) {
      if (sg.whichTipo() == SetorOuGrupo_Tipo.setor && sg.setor.hasConteudo()) {
        for (var m in sg.setor.conteudo.mapas) {
          if (m.caminhoImagemMapa == mapaCaminhoImagem) {
            mapa = m;
            break;
          }
        }
      } else if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo && sg.grupo.hasConteudo()) {
        for (var m in sg.grupo.conteudo.mapas) {
          if (m.caminhoImagemMapa == mapaCaminhoImagem) {
            mapa = m;
            break;
          }
        }
        if (mapa != null) break;

        // Busca nos sub-setores do grupo
        for (var s in sg.grupo.conteudo.setores) {
          if (s.hasConteudo()) {
            for (var m in s.conteudo.mapas) {
              if (m.caminhoImagemMapa == mapaCaminhoImagem) {
                mapa = m;
                break;
              }
            }
          }
          if (mapa != null) break;
        }
      }
      if (mapa != null) break;
    }

    if (mapa == null) {
      // Map might be in a via (Multipitch etc)
      for (var sg in pico.setoresOuGrupos) {
        if (sg.whichTipo() == SetorOuGrupo_Tipo.setor && sg.setor.hasConteudo()) {
          for (var esc in sg.setor.conteudo.escaladas) {
            if (esc.hasViaMultiplasEnfiadas()) {
              for (var m in esc.viaMultiplasEnfiadas.mapas) {
                if (m.caminhoImagemMapa == mapaCaminhoImagem) {
                  mapa = m;
                  break;
                }
              }
            }
            if (mapa != null) break;
          }
        } else if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo && sg.grupo.hasConteudo()) {
          for (var s in sg.grupo.conteudo.setores) {
            if (s.hasConteudo()) {
              for (var esc in s.conteudo.escaladas) {
                if (esc.hasViaMultiplasEnfiadas()) {
                  for (var m in esc.viaMultiplasEnfiadas.mapas) {
                    if (m.caminhoImagemMapa == mapaCaminhoImagem) {
                      mapa = m;
                      break;
                    }
                  }
                }
                if (mapa != null) break;
              }
            }
            if (mapa != null) break;
          }
        }
        if (mapa != null) break;
      }
    }

    // Identifica os contextos
    Setor? matchedSetor;
    Grupo? matchedGrupo;

    if (setorContextNome != null) {
      for (var sg in pico.setoresOuGrupos) {
        if (sg.whichTipo() == SetorOuGrupo_Tipo.setor && sg.setor.hasConteudo()) {
          if (sg.setor.conteudo.nome == setorContextNome) {
            matchedSetor = sg.setor.conteudo;
            break;
          }
        } else if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo && sg.grupo.hasConteudo()) {
          for (var s in sg.grupo.conteudo.setores) {
            if (s.hasConteudo() && s.conteudo.nome == setorContextNome) {
              matchedSetor = s.conteudo;
              break;
            }
          }
          if (matchedSetor != null) break;
        }
      }
    }

    if (grupoContextNome != null) {
      for (var sg in pico.setoresOuGrupos) {
        if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo && sg.grupo.hasConteudo()) {
          if (sg.grupo.conteudo.nome == grupoContextNome) {
            matchedGrupo = sg.grupo.conteudo;
            break;
          }
        }
      }
    }

    List<Escalada> escaladas = [];
    List<ArquivoSetor> setores = [];

    if (matchedSetor != null) {
      escaladas = matchedSetor.escaladas;
    } else if (matchedGrupo != null) {
      for (var s in matchedGrupo.setores) {
        if (s.hasConteudo()) {
          // Se o setor não tem mapa próprio, suas escaladas devem estar no mapa do grupo.
          if (s.conteudo.mapas.isEmpty) {
            escaladas.addAll(s.conteudo.escaladas);
          }
        }
      }
      setores = matchedGrupo.setores;
    } else {
      for (var sg in pico.setoresOuGrupos) {
        if (sg.whichTipo() == SetorOuGrupo_Tipo.setor && sg.setor.hasConteudo()) {
          if (sg.setor.conteudo.mapas.isEmpty) {
            escaladas.addAll(sg.setor.conteudo.escaladas);
          }
          setores.add(sg.setor);
        } else if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo && sg.grupo.hasConteudo()) {
          if (sg.grupo.conteudo.mapas.isEmpty) {
            for (var s in sg.grupo.conteudo.setores) {
              if (s.hasConteudo() && s.conteudo.mapas.isEmpty) {
                escaladas.addAll(s.conteudo.escaladas);
              }
            }
          }
        }
      }
    }

    return MapaResolutionResult(
      mapa: mapa ?? Mapa(),
      escaladas: escaladas,
      setores: setores,
    );
  }

  static Map<String, List<dynamic>> buildIdMap({
    required Mapa mapa,
    required List<Escalada> escaladas,
    required List<ArquivoSetor> setores,
  }) {
    final Map<String, List<dynamic>> idMap = {};
    final Set<String> duplicates = {};

    final Set<String> validIds = mapa.pontosDeInteresse.map((p) => p.id).toSet();

    void addId(String id, dynamic item) {
      if (id.isEmpty) return;
      if (!validIds.contains(id)) return;
      if (duplicates.contains(id)) return;

      if (idMap.containsKey(id)) {
        // Verifica se o mesmo item exato já está na lista
        final existingList = idMap[id]!;
        for (var existingItem in existingList) {
          if (identical(existingItem, item) || existingItem.toString() == item.toString()) {
            return; // Já adicionado exato
          }
        }
        
        // Se for um item novo, adiciona à lista para o mesmo marcador
        existingList.add(item);
      } else {
        idMap[id] = [item];
      }
    }

    // Priorizar os setores (sub-setores) primeiro, pois na visão de grupo
    // os IDs 01, 02 geralmente se referem aos setores e não as vias neles
    for (var set in setores) {
      if (set.hasConteudo()) {
        addId(set.conteudo.idNoMapa, set.conteudo);
      }
    }

    for (var esc in escaladas) {
      final ids = getEscaladaIdsNoMapa(esc);
      for (var id in ids) {
        addId(id, esc);
      }
    }
    return idMap;
  }

  static List<String> getEscaladaIdsNoMapa(Escalada escalada) {
    switch (escalada.whichTipo()) {
      case Escalada_Tipo.viaEsportiva:
        return [
          escalada.viaEsportiva.idNoMapa,
          escalada.viaEsportiva.idNoMapaMeio,
          escalada.viaEsportiva.idNoMapaFim,
        ];
      case Escalada_Tipo.viaMovel:
        return [
          escalada.viaMovel.idNoMapa,
          escalada.viaMovel.idNoMapaMeio,
          escalada.viaMovel.idNoMapaFim,
        ];
      case Escalada_Tipo.boulder:
        return [
          escalada.boulder.idNoMapa,
          escalada.boulder.idNoMapaMeio,
          escalada.boulder.idNoMapaFim,
        ];
      case Escalada_Tipo.viaMultiplasEnfiadas:
        return [
          escalada.viaMultiplasEnfiadas.idNoMapa,
          escalada.viaMultiplasEnfiadas.idNoMapaMeio,
          escalada.viaMultiplasEnfiadas.idNoMapaFim,
        ];
      case Escalada_Tipo.highline:
        return [
          escalada.highline.idNoMapa,
          escalada.highline.idNoMapaMeio,
          escalada.highline.idNoMapaFim,
        ];
      default:
        return [];
    }
  }
}

class MarkerPainter extends CustomPainter {
  final List<Offset> polygon;
  final double minX;
  final double minY;
  final double mapWidth;
  final double mapHeight;
  final BoxConstraints constraints;
  final bool isSelected;
  final double padding;

  MarkerPainter({
    required this.polygon,
    required this.minX,
    required this.minY,
    required this.mapWidth,
    required this.mapHeight,
    required this.constraints,
    required this.isSelected,
    required this.padding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (int i = 0; i < polygon.length; i++) {
      final p = polygon[i];
      final localX =
          ((p.dx - minX) / mapWidth * constraints.maxWidth) + padding;
      final localY =
          ((p.dy - minY) / mapHeight * constraints.maxHeight) + padding;

      if (i == 0) {
        path.moveTo(localX, localY);
      } else {
        path.lineTo(localX, localY);
      }
    }
    path.close();

    if (isSelected) {
      final fillPaint = Paint()
        ..color = beastHide.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      canvas.drawPath(path, fillPaint);

      final borderPaint = Paint()
        ..color = beastHide.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.5);
      canvas.drawPath(path, borderPaint);
    } else {
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      canvas.drawPath(path, glowPaint);
    }
  }

  @override
  bool? hitTest(Offset position) {
    final path = Path();
    for (int i = 0; i < polygon.length; i++) {
      final p = polygon[i];
      final localX =
          ((p.dx - minX) / mapWidth * constraints.maxWidth) + padding;
      final localY =
          ((p.dy - minY) / mapHeight * constraints.maxHeight) + padding;

      if (i == 0) {
        path.moveTo(localX, localY);
      } else {
        path.lineTo(localX, localY);
      }
    }
    path.close();

    // Inflate path for easier tapping
    return path.contains(position);
  }

  @override
  bool shouldRepaint(covariant MarkerPainter oldDelegate) {
    return oldDelegate.isSelected != isSelected ||
        oldDelegate.constraints != constraints;
  }
}

