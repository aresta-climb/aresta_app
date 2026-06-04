import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../view_functions/common_functions.dart';
import '../view_functions/offline_markdown.dart';
import '../view_functions/via_functions.dart';
import '../services/editor_croqui.dart';
import '../navigation/navigation_functions.dart';
import '../services/firebase/telemetry_service.dart';

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

  final Map<String, dynamic> _idMap = {};
  Future<ImageProvider?>? _imageProviderFuture;
  late bool _autoZoomEnabled;
  bool _initialZoom = false;

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
      MapHelper.buildIdMap(escaladas: widget.escaladas, setores: widget.setores),
    );
    
    if (widget.initialSelectedId != null) {
      _selectedId = widget.initialSelectedId;
    }

    _imageProviderFuture = widget.imageProviderOverride != null
        ? Future.value(widget.imageProviderOverride)
        : _resolveImageProvider();
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

    debugPrint('Erro: Imagem do mapa não encontrada localmente: $path');
    return null;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onMarkerTap(
    Mapa_PontoDeInteresse marker,
    BoxConstraints constraints,
    Size viewportSize, {
    bool isUserInteraction = true,
  }) {
    setState(() {
      _selectedId = marker.id;
    });

    if (isUserInteraction) {
      final item = _idMap[marker.id];
      if (item is Escalada) {
        TelemetryService.instance.logClicarEscaladaMapa(
          widget.cragId,
          widget.setorContext?.nome ?? 'Geral',
          getEscaladaNome(item)
        );
      }
    }

    if (_autoZoomEnabled) {
      final areaInfo = AreaHelper.getAreaInfo(marker);
      if (areaInfo == null) return;

      final minX = areaInfo.bounds.left;
      final maxX = areaInfo.bounds.right;
      final minY = areaInfo.bounds.top;
      final maxY = areaInfo.bounds.bottom;

      final double relCenterX =
          (minX + (maxX - minX) / 2) / widget.mapa.larguraMapa;
      final double relCenterY =
          (minY + (maxY - minY) / 2) / widget.mapa.alturaMapa;

      _zoomToRelativePoint(
        relCenterX,
        relCenterY,
        Size(constraints.maxWidth, constraints.maxHeight),
        viewportSize,
      );
    }
  }

  void _zoomToRelativePoint(
    double relX,
    double relY,
    Size childSize,
    Size viewportSize,
  ) {
    const double targetScale = 2.5;

    final double markerX = relX * childSize.width;
    final double markerY = relY * childSize.height;

    final double offsetX = (viewportSize.width - childSize.width) / 2;
    final double offsetY = (viewportSize.height - childSize.height) / 2;

    final double actualMarkerX = markerX + offsetX;
    final double actualMarkerY = markerY + offsetY;

    final double targetX =
        (viewportSize.width / 2) - (actualMarkerX * targetScale);
    final double targetY =
        (viewportSize.height / 2) - (actualMarkerY * targetScale);

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

      final isSelected = ponto.id == _selectedId;

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

  Widget _buildFloatingCard() {
    if (_selectedId == null) return const SizedBox.shrink();

    final item = _idMap[_selectedId!];
    if (item == null) return const SizedBox.shrink();

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
            'Multipitch | ${formatGrade(v.dificuldadeMaxima)}',
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
        default:
          title = 'Sem Nome';
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
          // Tap on the source via — go back to it in the tree
          AppNav.back(context);
        } else {
          TelemetryService.instance.logVerDetalhesEscalada(
            widget.cragId,
            widget.setorContext?.nome ?? 'Geral',
            title,
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
        child: SingleChildScrollView(
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
                          Text(
                            title,
                            style: TextStyle(
                              color: fishBone,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ?subtitleWidget,
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: fishBone),
                      onPressed: () => setState(() => _selectedId = null),
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
        ),
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
        title: Text(
          'Croqui Interativo',
          style: TextStyle(color: fishBone),
        ),
        iconTheme: IconThemeData(color: fishBone),
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

              return Stack(
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

                            return GestureDetector(
                              onTap: () {
                                if (_selectedId != null) {
                                  setState(() => _selectedId = null);
                                }
                              },
                              child: Stack(
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
                              ),
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
                    child: _buildFloatingCard(),
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
                            AppNav.toMapaGeralPico(context, returnToSetor: widget.setorContext);
                          },
                          backgroundColor: beastHide,
                          icon: Icon(Icons.map, color: nobleBlack),
                          label: Text('Mapa Geral', style: TextStyle(color: nobleBlack, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ],
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

class MapHelper {
  static Map<String, dynamic> buildIdMap({
    required List<Escalada> escaladas,
    required List<ArquivoSetor> setores,
  }) {
    final Map<String, dynamic> idMap = {};
    final Set<String> duplicates = {};

    void addId(String id, dynamic item) {
      if (id.isEmpty) return;
      if (duplicates.contains(id)) return;

      if (idMap.containsKey(id)) {
        debugPrint(
          'Erro: Mais de uma escalada/setor com o mesmo idNoMapa ($id). Removendo do mapa...',
        );
        idMap.remove(id);
        duplicates.add(id);
      } else {
        idMap[id] = item;
      }
    }

    for (var esc in escaladas) {
      final ids = getEscaladaIdsNoMapa(esc);
      for (var id in ids) {
        addId(id, esc);
      }
    }
    for (var set in setores) {
      if (set.hasConteudo()) {
        addId(set.conteudo.idNoMapa, set.conteudo);
        for (var esc in set.conteudo.escaladas) {
          final ids = getEscaladaIdsNoMapa(esc);
          for (var id in ids) {
            addId(id, esc);
          }
        }
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

