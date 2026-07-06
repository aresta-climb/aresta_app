import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/pages/mapa_interativo.dart';


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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Evita conflito com o mapa
            itemCount: widget.mapas.length,
            itemBuilder: (context, index) {
              final builder = widget.mapBuilder ?? _defaultMapBuilder;
              return builder(context, index, widget.mapas[index]);
            },
          ),
          
          // UI Flutuante Superior
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                              fontSize: 14,
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
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
