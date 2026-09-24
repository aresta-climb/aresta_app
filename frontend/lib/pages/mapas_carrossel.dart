// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/pages/mapa_interativo.dart';
import 'package:frontend/view_functions/common_functions.dart';
import 'package:frontend/navigation/navigation_functions.dart';
import '../widgets/provedor_imagem_aresta.dart';

typedef MapBuilder =
    Widget Function(BuildContext context, int index, CarrosselItemData item);

class MapasCarrosselPage extends StatefulWidget {
  final Pico pico;
  final String cragId;
  final List<CarrosselItemData> mapas;
  final int initialIndex;
  final MapBuilder? mapBuilder;
  final ImageProvider? imageProviderOverride;
  final Future<File?> Function({required String picoId, required String caminho})? preCarregadorDisco;

  const MapasCarrosselPage({
    super.key,
    required this.pico,
    required this.cragId,
    required this.mapas,
    this.initialIndex = 0,
    this.mapBuilder,
    this.imageProviderOverride,
    this.preCarregadorDisco,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _iniciarPreCarregamentoMapasCarrossel();
    });
  }

  @override
  void didUpdateWidget(MapasCarrosselPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      if (widget.initialIndex != oldWidget.initialIndex) {
        _currentIndex = widget.initialIndex;
        // jumpToPage sincroniza a página quando o índice inicial é alterado.
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentIndex);
        }
      }
    });
    if (widget.mapas != oldWidget.mapas || widget.cragId != oldWidget.cragId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _iniciarPreCarregamentoMapasCarrossel();
      });
    }
  }

  void _iniciarPreCarregamentoMapasCarrossel() {
    final preCarregador = widget.preCarregadorDisco ?? ProvedorImagemAresta.preCarregarNoDisco;
    for (final mapa in widget.mapas) {
      if (mapa.mapaCaminhoImagem.isNotEmpty) {
        preCarregador(
          picoId: widget.cragId,
          caminho: mapa.mapaCaminhoImagem,
        ).catchError((e, stack) {
          // Captura erros de I/O ou conexão graciosamente sem interferir na UI
          return null;
        });
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

  Widget _defaultMapBuilder(
    BuildContext context,
    int index,
    CarrosselItemData item,
  ) {
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
      key: ValueKey('${widget.cragId}_${item.mapaCaminhoImagem}_${widget.imageProviderOverride.hashCode}'),
      pico: widget.pico,
      mapa: result.mapa,
      cragId: widget.cragId,
      initialSelectedId: item.initialSelectedId,
      escaladaContextNome: item.escaladaContextNome,
      setorContext: resolvedSetor,
      grupoContext: resolvedGrupo,
      imageProviderOverride: widget.imageProviderOverride,
      hideAppBar: widget.mapas.length > 1,
      popOnActionIfOriginal:
          false, // Previne que o clique em 'Mais Info' do carrossel feche a tela
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mapas.length == 1) {
      final builder = widget.mapBuilder ?? _defaultMapBuilder;
      return builder(context, 0, widget.mapas.first);
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
              onPressed: _currentIndex < widget.mapas.length - 1
                  ? _goToNext
                  : null,
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
        physics:
            const NeverScrollableScrollPhysics(), // Evita conflito com o mapa
        itemCount: widget.mapas.length,
        itemBuilder: (context, index) {
          final builder = widget.mapBuilder ?? _defaultMapBuilder;
          return builder(context, index, widget.mapas[index]);
        },
      ),
    );
  }
}
