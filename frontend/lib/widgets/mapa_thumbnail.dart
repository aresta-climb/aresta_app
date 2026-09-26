// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../view_functions/common_functions.dart';
import '../navigation/navigation_functions.dart';
import '../services/firebase/telemetry_service.dart';
import '../navigation/navigation_tree.dart';
import 'provedor_imagem_aresta.dart';

class MapaThumbnail extends StatefulWidget {
  final List<Mapa> mapas;
  final String cragId;
  final Setor? setorContext;
  final Grupo? grupoContext;
  final String? nomeContexto;
  final ImageProvider? imageProviderOverride;
  final Future<ImageProvider?>? imageProviderFutureOverride;
  final Future<File?> Function({required String picoId, required String caminho})? preCarregadorDisco;

  /// Lista pré-resolvida de itens para o carrossel (ex: combinação de mapas locais e de setor).
  final List<CarrosselItemData>? carrosselItensOverride;

  const MapaThumbnail({
    super.key,
    required this.mapas,
    required this.cragId,
    this.setorContext,
    this.grupoContext,
    this.nomeContexto,
    this.imageProviderOverride,
    this.imageProviderFutureOverride,
    this.preCarregadorDisco,
    this.carrosselItensOverride,
  });

  @override
  State<MapaThumbnail> createState() => _MapaThumbnailState();
}

class _MapaThumbnailState extends State<MapaThumbnail> {
  Future<ImageProvider?>? _imageProviderFuture;

  @override
  void initState() {
    super.initState();
    _imageProviderFuture = _resolveImageProvider();
    _iniciarPreCarregamentoMapasSubsequentes();
  }

  @override
  void didUpdateWidget(MapaThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      _imageProviderFuture = _resolveImageProvider();
    });
    if (widget.mapas != oldWidget.mapas || widget.cragId != oldWidget.cragId) {
      _iniciarPreCarregamentoMapasSubsequentes();
    }
  }

  void _iniciarPreCarregamentoMapasSubsequentes() {
    if (widget.mapas.length <= 1) return;

    final preCarregador = widget.preCarregadorDisco ?? ProvedorImagemAresta.preCarregarNoDisco;
    for (int i = 1; i < widget.mapas.length; i++) {
      final mapa = widget.mapas[i];
      if (mapa.caminhoImagemMapa.isNotEmpty) {
        preCarregador(
          picoId: widget.cragId,
          caminho: mapa.caminhoImagemMapa,
        );
      }
    }
  }


  Future<ImageProvider?> _resolveImageProvider() async {
    if (widget.imageProviderFutureOverride != null) {
      return widget.imageProviderFutureOverride!;
    }
    if (widget.imageProviderOverride != null) {
      return widget.imageProviderOverride;
    }
    if (widget.mapas.isEmpty) return null;
    return resolveMapImageProvider(widget.cragId, widget.mapas.first);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mapas.isEmpty) return const SizedBox.shrink();
    final thumbnailMap = widget.mapas.first;

    if (thumbnailMap.larguraMapa == 0 || thumbnailMap.alturaMapa == 0) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).extension<AppColors>() ?? AppColors.dark;
    final aspectRatio = thumbnailMap.larguraMapa / thumbnailMap.alturaMapa;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: GestureDetector(
        onTap: () {
          TelemetryService.instance.logAbrirMapa(
            widget.cragId,
            widget.nomeContexto ?? widget.setorContext?.nome ?? 'Geral',
          );
          final mapasParaNavegar = widget.carrosselItensOverride ??
              widget.mapas
                  .map((m) => CarrosselItemData(
                        mapaCaminhoImagem: m.caminhoImagemMapa,
                        setorContextNome: widget.setorContext?.nome,
                        grupoContextNome: widget.grupoContext?.nome,
                      ))
                  .toList();
          AppNav.toMapas(
            context,
            cragId: widget.cragId,
            mapas: mapasParaNavegar,
            imageProviderOverride: widget.imageProviderOverride,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              // Camada 0: Fundo sólido do tema enquanto a imagem carrega
              Container(
                color: colors.deepBasalt,
              ),

              // Camada 1: Imagem de fundo assíncrona com fade suave
              FutureBuilder<ImageProvider?>(
                future: _imageProviderFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Image(
                      image: snapshot.data!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded) return child;
                        return AnimatedOpacity(
                          opacity: frame == null ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          child: child,
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Camada 2: Overlay escuro para contraste e legibilidade
              Container(
                color: Colors.black.withValues(alpha: 0.3),
              ),

              // Camada 3: Botão translúcido central sempre visível e interativo
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandColor.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: beastHide.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.map, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        (widget.carrosselItensOverride?.length ?? widget.mapas.length) > 1
                            ? 'Mapas Interativos (${widget.carrosselItensOverride?.length ?? widget.mapas.length})'
                            : 'Abrir Mapa Interativo',
                        style: TextStyle(
                          color: fishBone,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Resolve o provedor de imagem para um [Mapa], aplicando downsampling por padrão para miniaturas.
Future<ImageProvider?> resolveMapImageProvider(
  String cragId,
  Mapa mapa, {
  int? larguraAlvo = 400,
  int? alturaAlvo,
}) async {
  return resolveImagePathProvider(
    cragId,
    mapa.caminhoImagemMapa,
    larguraAlvo: larguraAlvo,
    alturaAlvo: alturaAlvo,
  );
}

/// Resolve o provedor de imagem para um caminho de mídia, com suporte a downsampling opcional.
Future<ImageProvider?> resolveImagePathProvider(
  String cragId,
  String path, {
  int? larguraAlvo,
  int? alturaAlvo,
}) async {
  return ProvedorImagemAresta.resolver(
    picoId: cragId,
    caminho: path,
    larguraAlvo: larguraAlvo,
    alturaAlvo: alturaAlvo,
  );
}
