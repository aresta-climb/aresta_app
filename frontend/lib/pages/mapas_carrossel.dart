import 'package:flutter/material.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/pages/mapa_interativo.dart';
import 'package:frontend/view_functions/common_functions.dart';
import 'package:frontend/navigation/navigation_functions.dart';


typedef MapBuilder = Widget Function(BuildContext context, int index, CarrosselItemData item);

class MapasCarrosselPage extends StatefulWidget {
  final Pico pico;
  final String cragId;
  final List<CarrosselItemData> mapas;
  final int initialIndex;
  final MapBuilder? mapBuilder;
  final ImageProvider? imageProviderOverride;

  const MapasCarrosselPage({
    super.key,
    required this.pico,
    required this.cragId,
    required this.mapas,
    this.initialIndex = 0,
    this.mapBuilder,
    this.imageProviderOverride,
  });

  @override
  State<MapasCarrosselPage> createState() => _MapasCarrosselPageState();
}

class _MapasCarrosselPageState extends State<MapasCarrosselPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void didUpdateWidget(MapasCarrosselPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      _currentIndex = widget.initialIndex;
      // We don't want to jump instantly without animation or wait if it's already on that page.
      // jumpToPage handles this synchronously.
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _pageController.jumpToPage(_currentIndex);
    }
  }

  void _goToNext() {
    if (_currentIndex < widget.mapas.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.jumpToPage(_currentIndex);
    }
  }

  Widget _defaultMapBuilder(BuildContext context, int index, CarrosselItemData item) {
    final result = MapHelper.resolveMapaAndContext(
      pico: widget.pico,
      mapaCaminhoImagem: item.mapaCaminhoImagem,
      setorContextNome: item.setorContextNome,
      grupoContextNome: item.grupoContextNome,
    );
    
    Setor? resolvedSetor;
    Grupo? resolvedGrupo;

    for (var sg in widget.pico.setoresOuGrupos) {
      if (sg.hasGrupo() && sg.grupo.hasConteudo()) {
        final g = sg.grupo.conteudo;
        if (g.nome == item.grupoContextNome) {
          resolvedGrupo = g;
          for (var s in g.setores) {
            if (s.hasConteudo() && s.conteudo.nome == item.setorContextNome) {
              resolvedSetor = s.conteudo;
              break;
            }
          }
        }
      } else if (sg.hasSetor() && sg.setor.hasConteudo()) {
        final s = sg.setor.conteudo;
        if (s.nome == item.setorContextNome) {
          resolvedSetor = s;
        }
      }
    }

    return MapaInterativoPage(
      pico: widget.pico,
      mapa: result.mapa,
      cragId: widget.cragId,
      initialSelectedId: item.initialSelectedId,
      setorContext: resolvedSetor,
      grupoContext: resolvedGrupo,
      imageProviderOverride: widget.imageProviderOverride,
      hideAppBar: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppNav.back(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: _currentIndex > 0 ? _goToPrevious : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '${(_currentIndex + 1).toString().padLeft(2, '0')} de ${widget.mapas.length.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: _currentIndex < widget.mapas.length - 1 ? _goToNext : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          buildFeedbackButton(context, color: Colors.white),
          const SizedBox(width: 12),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Evita conflito com o mapa
        itemCount: widget.mapas.length,
        itemBuilder: (context, index) {
          final builder = widget.mapBuilder ?? _defaultMapBuilder;
          return builder(context, index, widget.mapas[index]);
        },
      ),
    );
  }
}
