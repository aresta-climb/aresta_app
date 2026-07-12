import 'dart:io';
import 'dart:math' as math;
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/utils/croqui_map_index.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:frontend/constants/network_constants.dart';
import '../services/firebase/telemetry_service.dart';
import '../services/firebase/app_logger.dart';
import '../services/feedback/feedback_metadata_collector.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../view_functions/common_functions.dart';
import '../view_functions/via_functions.dart';
import '../services/editor_croqui.dart';
import '../utils/dataset_resolver.dart';
import '../navigation/navigation_functions.dart';
import '../navigation/map_hierarchy_resolver.dart';

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
  final Pico pico;
  final Mapa mapa;
  final String cragId;
  final bool autoZoomEnabled;
  final ImageProvider? imageProviderOverride;
  final String? initialSelectedId;
  final Setor? setorContext;
  final Grupo? grupoContext;
  final String? escaladaContextNome;
  
  /// Quando `true`, esta página não desenhará o seu próprio `Scaffold` com `AppBar`.
  /// Isso é essencial quando o mapa é embutido dentro de um Carrossel (`MapasCarrosselPage`),
  /// onde a navegação superior (AppBar) é delegada ao container pai para evitar "clipping" visual
  /// e garantir que a barra fique fixa durante a animação de swipe. Padrão é `false`.
  final bool hideAppBar;

  const MapaInterativoPage({
    super.key,
    required this.pico,
    required this.mapa,
    required this.cragId,
    this.autoZoomEnabled = true,
    this.imageProviderOverride,
    this.initialSelectedId,
    this.setorContext,
    this.grupoContext,
    this.escaladaContextNome,
    this.hideAppBar = false,
  });

  @override
  State<MapaInterativoPage> createState() => _MapaInterativoPageState();
}

/// O estado da página [MapaInterativoPage].
///
/// Utiliza o [AutomaticKeepAliveClientMixin] para preservar o estado visual
/// (nível de zoom, posição de pan, e status de animações já tocadas) quando 
/// este widget é embutido dentro de listas sob demanda como o [PageView]
/// (usado na `MapasCarrosselPage`). Isso evita o recarregamento do zero da
/// imagem do mapa e das animações.
class _MapaInterativoPageState extends State<MapaInterativoPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  String? _selectedId;
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _zoomAnimation;

  final Map<String, List<Mapa_Referencia>> _poiToRefs = {};
  final Map<Mapa_Referencia, ResolvedDataset> _refToResolved = {};
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

    _buildReferenceMaps();
    
    if (widget.initialSelectedId != null) {
      _selectedId = widget.initialSelectedId;
      
      // Se um contexto de escalada foi fornecido, tentamos focar automaticamente
      // na aba do carrossel correspondente a essa escalada.
      // Isso previne o bug onde múltiplos pontos (ex: 2-A e 2-B) compartilham o mesmo
      // ID no mapa (o mesmo "pin"), fazendo com que o pin abra na primeira aba (2-A)
      // mesmo quando o usuário clicou em "Ver no mapa" a partir da via 2-B.
      if (widget.escaladaContextNome != null) {
        final refs = _poiToRefs[_selectedId!];
        if (refs != null) {
          for (int i = 0; i < refs.length; i++) {
            final resolved = _refToResolved[refs[i]];
            if (resolved?.escalada != null && getEscaladaNome(resolved!.escalada!) == widget.escaladaContextNome) {
              _focusedItemIndex = i;
              break;
            }
          }
        }
      }
    }
    _updateFeedbackNode();

    _imageProviderFuture = widget.imageProviderOverride != null
        ? Future.value(widget.imageProviderOverride)
        : _resolveImageProvider();
  }

  @override
  void didUpdateWidget(MapaInterativoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mapa != oldWidget.mapa || widget.pico != oldWidget.pico) {
      _buildReferenceMaps();
    }
    
    if (widget.mapa != oldWidget.mapa || widget.imageProviderOverride != oldWidget.imageProviderOverride) {
      // The map object changed (either experimental mode update or a new downloaded update)
      // The file on disk might have been overwritten without path changes.
      // We evict the image from the cache to force a reload from disk.
      _imageProviderFuture?.then((provider) { provider?.evict(); });
      
      _imageProviderFuture = widget.imageProviderOverride != null
          ? Future.value(widget.imageProviderOverride)
          : _resolveImageProvider();
    }
  }

  void _buildReferenceMaps() {
    _poiToRefs.clear();
    _refToResolved.clear();

    String? defaultSetorNome = widget.setorContext?.nome;
    String? defaultGrupoNome = widget.grupoContext?.nome;

    for (var ref in widget.mapa.referencias) {
      try {
        final resolved = DatasetResolver.resolveReferencia(
          pico: widget.pico,
          referencia: ref,
          defaultGrupoNome: defaultGrupoNome,
          defaultSetorNome: defaultSetorNome,
        );
        
        _refToResolved[ref] = resolved;
        
        for (var id in ref.ids) {
          if (id.isNotEmpty) {
            _poiToRefs.putIfAbsent(id, () => []).add(ref);
          }
        }
      } catch (e) {
        AppLogger.instance.logError('Unresolved reference in map: $e');
      }
    }
  }

  void _updateFeedbackNode() {
    if (_selectedId == null) {
      FeedbackMetadataCollector.globalActiveNodeOverride = null;
    } else {
      final refs = _poiToRefs[_selectedId];
      final ref = refs != null && refs.isNotEmpty ? refs.first : null;
      final viaName = ref?.nome ?? _selectedId;
      final fileName = widget.mapa.caminhoImagemMapa.split('/').last;
      FeedbackMetadataCollector.globalActiveNodeOverride = 'MapaInterativoNode($fileName, Ref: $viaName)';
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
    final baseUrl = '${NetworkConstants.officialServerUrl}/';
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

  List<Mapa_PontoDeInteresse> _getPontosForRef(Mapa_Referencia? ref) {
    if (ref == null) return [];
    final ids = ref.ids.where((id) => id.isNotEmpty).toList();
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
      
      int targetIndex = 0;
      
      // Durante o carregamento inicial (isUserInteraction = false), se houver um 
      // contexto de escalada, localizamos a aba correta deste ponto de interesse.
      // Evita focar erroneamente no primeiro item do carrossel caso vários itens 
      // compartilhem o mesmo marcador no croqui.
      if (!isUserInteraction && widget.escaladaContextNome != null) {
        final refs = _poiToRefs[marker.id];
        if (refs != null) {
          for (int i = 0; i < refs.length; i++) {
            final resolved = _refToResolved[refs[i]];
            if (resolved?.escalada != null && getEscaladaNome(resolved!.escalada!) == widget.escaladaContextNome) {
              targetIndex = i;
              break;
            }
          }
        }
      }
      
      _focusedItemIndex = targetIndex;
      _updateFeedbackNode();
    });

    final refs = _poiToRefs[marker.id];
    if (refs != null && refs.isNotEmpty) {
      final ref = refs[_focusedItemIndex]; // Use correct ref!
      final resolved = _refToResolved[ref];
      if (isUserInteraction && resolved?.escalada != null) {
        TelemetryService.instance.logAcaoEscalada(
          widget.cragId,
          widget.setorContext?.nome ?? 'Geral',
          getEscaladaNome(resolved!.escalada!),
          'selecionar_no_mapa',
          'mapa'
        );
      }

      if (_autoZoomEnabled) {
        final pontos = _getPontosForRef(ref);
        _zoomToPoints(pontos, Size(constraints.maxWidth, constraints.maxHeight), viewportSize, ref: ref);
      }
    }
  }

  void _zoomToPoints(
    List<Mapa_PontoDeInteresse> pontos,
    Size childSize,
    Size viewportSize, {
    Mapa_Referencia? ref,
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

    bool hasMultiplePoints = pontos.length > 1;

    if (ref != null && ref.hasAjusteDeCamera() && ref.ajusteDeCamera.hasZoom()) {
      targetScale = ref.ajusteDeCamera.zoom;
    } else if (hasMultiplePoints && (boxWidthRel > 0 || boxHeightRel > 0)) {
      // Usa lógica de Bounding Box para qualquer rota com múltiplos pontos (início/fim, meio, boulders, etc)
      final double availableHeight = viewportSize.height * 0.55;
      final double availableWidth = viewportSize.width * 0.85;
      
      final double scaleX = availableWidth / (boxWidthRel * childSize.width);
      final double scaleY = availableHeight / (boxHeightRel * childSize.height);
      
      if (scaleX.isFinite && scaleY.isFinite) {
        final calculatedScale = math.min(scaleX, scaleY);
        double maxAutoZoom = 2.5;
        targetScale = math.min(math.max(calculatedScale, 1.0), maxAutoZoom);
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

    if (pontos.length == 1 && ref != null && _refToResolved[ref]?.escalada != null) {
      final ids = ref.ids;
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

      // POIs that don't have references shouldn't be drawn at all, per phase 4.5.
      if (!_poiToRefs.containsKey(ponto.id)) {
        return const SizedBox.shrink();
      }

      bool isSelected = false;
      if (_selectedId != null) {
        final refs = _poiToRefs[_selectedId!];
        if (refs != null && refs.isNotEmpty && _focusedItemIndex < refs.length) {
          final focusedRef = refs[_focusedItemIndex];
          isSelected = focusedRef.ids.contains(ponto.id);
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
          // HitTestBehavior default is deferToChild, which forwards the hit test down to CustomPainter.
          // This ensures accurate clicks on rotated polygons rather than their larger AABBs.
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


  Widget _buildCardContentForResolved(Mapa_Referencia ref, ResolvedDataset resolved) {
    if (resolved.escalada != null) {
      return _buildEscaladaCard(ref, resolved.escalada!);
    } else if (resolved.setor != null) {
      return _buildSetorCard(ref, resolved.setor!);
    } else if (resolved.grupo != null) {
      return _buildGrupoCard(ref, resolved.grupo!);
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildEscaladaCard(Mapa_Referencia ref, Escalada escalada) {
    String title = '';
    String subtitle = '';
    
    String formatGrade(dynamic dificuldade) {
      String g = dificuldade.name
          .replaceAll('BR_', '')
          .replaceAll('_BARRA_', '/')
          .replaceAll('_', ' ')
          .toLowerCase();

      return g.replaceAllMapped(RegExp(r'([1-6])(sup)?'), (match) {
        if (match.group(2) == 'sup') {
          return '${match.group(1)}ºsup';
        } else {
          return '${match.group(1)}º';
        }
      });
    }

    switch (escalada.whichTipo()) {
      case Escalada_Tipo.viaEsportiva:
        title = escalada.viaEsportiva.nome;
        subtitle = 'Esportiva | ${formatGrade(escalada.viaEsportiva.dificuldade)}';
        break;
      case Escalada_Tipo.viaMovel:
        title = escalada.viaMovel.nome;
        subtitle = 'Móvel | ${formatGrade(escalada.viaMovel.dificuldade)}';
        break;
      case Escalada_Tipo.boulder:
        title = escalada.boulder.nome;
        subtitle = 'Boulder | ${formatGrade(escalada.boulder.dificuldade)}';
        break;
      case Escalada_Tipo.viaMultiplasEnfiadas:
        title = escalada.viaMultiplasEnfiadas.nome;
        subtitle = 'Múltiplas Enfiadas | ${escalada.viaMultiplasEnfiadas.numeroEnfiadas} enfiadas';
        break;
      case Escalada_Tipo.highline:
        title = escalada.highline.nome;
        subtitle = 'Highline | ${escalada.highline.distancia}m';
        break;
      default:
        break;
    }

    String getLabelsForRef(Mapa_Referencia ref) {
      if (ref.ids.isEmpty) return ref.nome;
      List<String> labels = [];
      for (var id in ref.ids) {
        for (var p in widget.mapa.pontosDeInteresse) {
          if (p.id == id) {
            if (p.label.isNotEmpty) {
              labels.add(p.label);
            } else {
              labels.add(id);
            }
            break;
          }
        }
      }
      return labels.isNotEmpty ? labels.join('-') : ref.nome;
    }

    final resolved = _refToResolved[ref];
    List<IndexedMap> foundMaps = [];
    if (resolved != null && resolved.escalada != null) {
      final index = CroquiMapIndex(widget.pico);
      foundMaps = index.getMapasForReference(resolved);
    }

    return _buildBaseCard(
      title: title,
      subtitle: subtitle,
      resolvedLabel: getLabelsForRef(ref),
      onClose: () {
        setState(() {
          _selectedId = null;
          _updateFeedbackNode();
        });
      },
      actionLabel: 'Mais Info',
      onAction: () {
        bool isOriginal = false;
        if (widget.initialSelectedId != null && ref.ids.contains(widget.initialSelectedId)) {
          isOriginal = true;
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
          AppNav.toVia(
            context,
            cragId: widget.cragId,
            escalada: escalada,
            setor: resolved?.setor,
            grupo: resolved?.grupo,
          );
        }
      },
      secondaryActionLabel: foundMaps.length > 1 ? 'Ver nos mapas (${foundMaps.length})' : null,
      onSecondaryAction: foundMaps.length > 1 ? () {
        TelemetryService.instance.logAcaoEscalada(
          widget.cragId,
          widget.setorContext?.nome ?? 'Geral',
          title,
          'ver_nos_mapas_carrossel',
          'mapa'
        );
        final mapasData = foundMaps.map((fm) => CarrosselItemData(
          mapaCaminhoImagem: fm.mapa!.caminhoImagemMapa,
          setorContextNome: fm.setorContext?.nome,
          grupoContextNome: null, // Assume flat for now or find it if needed
          initialSelectedId: fm.referencedId,
        )).toList();
        
        AppNav.toMapas(
          context,
          cragId: widget.cragId,
          mapas: mapasData,
        );
      } : null,
    );
  }

  Widget _buildSetorCard(Mapa_Referencia ref, Setor setor) {
    return _buildBaseCard(
      title: setor.nome,
      subtitle: 'Setor',
      resolvedLabel: ref.nome,
      onClose: () {
        setState(() {
          _selectedId = null;
          _updateFeedbackNode();
        });
      },
      actionLabel: 'Ir para Setor',
      onAction: () => AppNav.toSetor(context, setor: setor),
      secondaryActionLabel: setor.mapas.length > 1 ? 'Ver mapas (${setor.mapas.length})' : (setor.mapas.isNotEmpty ? 'Ver mapa' : null),
      onSecondaryAction: setor.mapas.isNotEmpty ? () {
        int indiceMapa = 0;
        if (ref.hasIndiceMapaAlvo()) {
          indiceMapa = ref.indiceMapaAlvo;
        } else if (setor.hasIndiceMapaPadrao()) {
          indiceMapa = setor.indiceMapaPadrao;
        }
        if (indiceMapa < 0 || indiceMapa >= setor.mapas.length) indiceMapa = 0;
        
        final resolved = _refToResolved[ref];
        if (setor.mapas.length > 1) {
          final mapasData = setor.mapas.map((m) => CarrosselItemData(
            mapaCaminhoImagem: m.caminhoImagemMapa,
            setorContextNome: setor.nome,
            grupoContextNome: resolved?.grupo?.nome,
          )).toList();
          
          AppNav.toMapas(
            context,
            cragId: widget.cragId,
            mapas: mapasData,
            initialIndex: indiceMapa,
          );
        } else {
          AppNav.toMapas(
            context,
            cragId: widget.cragId,
            mapas: [
              CarrosselItemData(
                mapaCaminhoImagem: setor.mapas[0].caminhoImagemMapa,
                setorContextNome: setor.nome,
                grupoContextNome: resolved?.grupo?.nome,
              )
            ],
          );
        }
      } : null,
    );
  }

  Widget _buildGrupoCard(Mapa_Referencia ref, Grupo grupo) {
    return _buildBaseCard(
      title: grupo.nome,
      subtitle: 'Grupo',
      resolvedLabel: ref.nome,
      onClose: () {
        setState(() {
          _selectedId = null;
          _updateFeedbackNode();
        });
      },
      actionLabel: 'Ir para Grupo',
      onAction: () => AppNav.toGrupo(context, grupo: grupo),
      secondaryActionLabel: grupo.mapas.length > 1 ? 'Ver mapas (${grupo.mapas.length})' : (grupo.mapas.isNotEmpty ? 'Ver mapa' : null),
      onSecondaryAction: grupo.mapas.isNotEmpty ? () {
        int indiceMapa = 0;
        if (ref.hasIndiceMapaAlvo()) {
          indiceMapa = ref.indiceMapaAlvo;
        } else if (grupo.hasIndiceMapaPadrao()) {
          indiceMapa = grupo.indiceMapaPadrao;
        }
        if (indiceMapa < 0 || indiceMapa >= grupo.mapas.length) indiceMapa = 0;
        
        if (grupo.mapas.length > 1) {
          final mapasData = grupo.mapas.map((m) => CarrosselItemData(
            mapaCaminhoImagem: m.caminhoImagemMapa,
            grupoContextNome: grupo.nome,
          )).toList();
          
          AppNav.toMapas(
            context,
            cragId: widget.cragId,
            mapas: mapasData,
            initialIndex: indiceMapa,
          );
        } else {
          AppNav.toMapas(
            context,
            cragId: widget.cragId,
            mapas: [
              CarrosselItemData(
                mapaCaminhoImagem: grupo.mapas[0].caminhoImagemMapa,
                grupoContextNome: grupo.nome,
              )
            ],
          );
        }
      } : null,
    );
  }

  Widget _buildBaseCard({
    required String title,
    required String subtitle,
    required String resolvedLabel,
    required VoidCallback onClose,
    required String actionLabel,
    required VoidCallback onAction,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
  }) {
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
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (resolvedLabel.isNotEmpty)
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
                          Text(
                            title,
                            style: TextStyle(
                              color: beastHide,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: fishBone.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: fishBone),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: (secondaryActionLabel != null && onSecondaryAction != null)
                    ? WrapAlignment.spaceBetween
                    : WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
              runSpacing: 4,
              children: [
                if (secondaryActionLabel != null && onSecondaryAction != null)
                  TextButton.icon(
                    onPressed: onSecondaryAction,
                    icon: Icon(Icons.map, color: fishBone, size: 16),
                    label: Text(
                      secondaryActionLabel,
                      style: TextStyle(color: fishBone, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                TextButton.icon(
                  onPressed: onAction,
                  icon: Icon(Icons.open_in_new, color: beastHide, size: 16),
                  label: Text(
                    actionLabel,
                    style: TextStyle(color: beastHide, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingCard(BoxConstraints constraints, Size viewportSize) {
    if (_selectedId == null) return const SizedBox.shrink();

    final refs = _poiToRefs[_selectedId!];
    if (refs == null || refs.isEmpty) return const SizedBox.shrink();

    Widget content;
    if (refs.length > 1) {
      void changeItem(int newIndex) {
        setState(() {
          _focusedItemIndex = newIndex;
        });
        
        final newRef = refs[newIndex];
        final newResolved = _refToResolved[newRef];
        if (newResolved?.escalada != null) {
          TelemetryService.instance.logAcaoEscalada(
            widget.cragId,
            widget.setorContext?.nome ?? 'Geral',
            getEscaladaNome(newResolved!.escalada!),
            'selecionar_no_mapa',
            'mapa_swipe'
          );
        }

        if (_autoZoomEnabled && _imageSize != null) {
          final pontos = _getPontosForRef(newRef);
          _zoomToPoints(pontos, _imageSize!, viewportSize, ref: newRef);
        }
      }



      content = GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            if (_focusedItemIndex > 0) changeItem(_focusedItemIndex - 1);
          } else if (details.primaryVelocity! < 0) {
            if (_focusedItemIndex < refs.length - 1) changeItem(_focusedItemIndex + 1);
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
                  ...List.generate(refs.length, (index) {
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
                    color: _focusedItemIndex < refs.length - 1 ? beastHide : fishBone.withValues(alpha: 0.3),
                    onPressed: _focusedItemIndex < refs.length - 1 ? () => changeItem(_focusedItemIndex + 1) : null,
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: KeyedSubtree(
                key: ValueKey(_focusedItemIndex),
                child: _buildCardContentForResolved(refs[_focusedItemIndex], _refToResolved[refs[_focusedItemIndex]]!),
              ),
            ),
          ],
        ),
      );
    } else {
      content = _buildCardContentForResolved(refs.first, _refToResolved[refs.first]!);
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
    super.build(context);
    
    if (widget.mapa.larguraMapa == 0 || widget.mapa.alturaMapa == 0) {
      return const SizedBox.shrink(); // Mapa inválido
    }

    final bodyContent = LayoutBuilder(
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
                  // Camada 4: Botão de Navegação "Subir" (Up)
                  // Um botão dinâmico exibido apenas quando existe um mapa
                  // de nível hierárquico superior (ex: Setor -> Grupo, ou Grupo -> Geral).
                  Builder(
                    builder: (context) {
                      final upDest = MapHierarchyResolver.resolveUpDestination(
                        pico: widget.pico,
                        setorContext: widget.setorContext,
                        grupoContext: widget.grupoContext,
                      );
                      
                      if (upDest == null) {
                        return const SizedBox.shrink();
                      }

                      return Positioned(
                        top: 10,
                        left: 10,
                        child: SafeArea(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.45,
                            ),
                            child: ActionChip(
                              side: BorderSide.none,
                              backgroundColor: beastHide,
                              avatar: Icon(Icons.turn_left_outlined, color: nobleBlack, size: 18),
                              label: Text(
                                upDest.label,
                                style: TextStyle(color: nobleBlack, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              onPressed: () {
                                TelemetryService.instance.logNavegacaoHierarquica(
                                  widget.cragId,
                                  upDest.label,
                                );
                                AppNav.toMapas(
                                  context,
                                  cragId: widget.cragId,
                                  mapas: upDest.mapasData,
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    }
                  ),
                ],
              ),
            );
            },
          );
        },
    );

    // Se hideAppBar for true, retornamos apenas o corpo embrulhado em um SafeArea
    // para garantir que os botões absolutos não fiquem escondidos na status bar.
    if (widget.hideAppBar) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(child: bodyContent),
      );
    }

    // Comportamento padrão (Standalone)
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
      body: bodyContent,
    );
  }
}

class AreaInfo {
  final List<Offset> polygon;
  final Rect bounds;

  AreaInfo({required this.polygon, required this.bounds});
}

/// Helper class that converts Protobuf marker bounds (`Mapa_PontoDeInteresse`)
/// into a polygon of relative/absolute coordinates and calculates its enclosing
/// Axis-Aligned Bounding Box (AABB). This is used to create a `Positioned` widget
/// and to power the precise `MarkerPainter` hit-testing.
class AreaHelper {
  /// Computes a list of vertices forming the polygon for a given marker,
  /// along with its encompassing AABB. Returns `null` if the shape is not supported.
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
    if (pico.hasMapasGerais() && pico.mapasGerais.hasConteudo()) {
      for (var m in pico.mapasGerais.conteudo.mapas) {
        if (m.caminhoImagemMapa == mapaCaminhoImagem) {
          mapa = m;
          break;
        }
      }
    }

    if (mapa == null) {
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


}

/// A `CustomPainter` responsible for drawing map markers and precisely detecting taps.
///
/// It operates in the local coordinate space established by the `Positioned` widget
/// which acts as an Axis-Aligned Bounding Box (AABB) around the marker. The polygon's
/// absolute map coordinates are translated by `minX`/`minY` and scaled down to the
/// UI `constraints` proportionally based on the original `mapWidth`/`mapHeight`.
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
    final localPolygon = <Offset>[];
    for (int i = 0; i < polygon.length; i++) {
      final p = polygon[i];
      final localX =
          ((p.dx - minX) / mapWidth * constraints.maxWidth) + padding;
      final localY =
          ((p.dy - minY) / mapHeight * constraints.maxHeight) + padding;
      
      final localOffset = Offset(localX, localY);
      localPolygon.add(localOffset);

      if (i == 0) {
        path.moveTo(localX, localY);
      } else {
        path.lineTo(localX, localY);
      }
    }
    path.close();

    // First, check if the point is strictly inside the mathematical bounds.
    if (path.contains(position)) return true;

    // Inflate path for easier tapping by checking distance to all polygon segments.
    // A tolerance of 10.0 units is reasonable for finger taps.
    const double tolerance = 10.0;
    const double toleranceSq = tolerance * tolerance;

    for (int i = 0; i < localPolygon.length; i++) {
      final p1 = localPolygon[i];
      final p2 = localPolygon[(i + 1) % localPolygon.length];
      
      final l2 = (p1.dx - p2.dx) * (p1.dx - p2.dx) + (p1.dy - p2.dy) * (p1.dy - p2.dy);
      double distSq;
      if (l2 == 0) {
        distSq = (position.dx - p1.dx) * (position.dx - p1.dx) + (position.dy - p1.dy) * (position.dy - p1.dy);
      } else {
        var t = ((position.dx - p1.dx) * (p2.dx - p1.dx) + (position.dy - p1.dy) * (p2.dy - p1.dy)) / l2;
        t = t < 0 ? 0 : (t > 1 ? 1 : t);
        final proj = Offset(p1.dx + t * (p2.dx - p1.dx), p1.dy + t * (p2.dy - p1.dy));
        distSq = (position.dx - proj.dx) * (position.dx - proj.dx) + (position.dy - proj.dy) * (position.dy - proj.dy);
      }

      if (distSq <= toleranceSq) return true;
    }

    return false;
  }

  @override
  bool shouldRepaint(covariant MarkerPainter oldDelegate) {
    return oldDelegate.isSelected != isSelected ||
        oldDelegate.constraints != constraints;
  }
}

