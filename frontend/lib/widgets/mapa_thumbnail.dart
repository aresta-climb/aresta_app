// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

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

  const MapaThumbnail({
    super.key,
    required this.mapas,
    required this.cragId,
    this.setorContext,
    this.grupoContext,
    this.nomeContexto,
    this.imageProviderOverride,
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
  }

  @override
  void didUpdateWidget(MapaThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mapas != oldWidget.mapas ||
        widget.imageProviderOverride != oldWidget.imageProviderOverride) {
      _imageProviderFuture?.then((provider) {
        provider?.evict();
      });
      _imageProviderFuture = _resolveImageProvider();
    }
  }

  Future<ImageProvider?> _resolveImageProvider() async {
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

    return FutureBuilder<ImageProvider?>(
      future: _imageProviderFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AspectRatio(
            aspectRatio: thumbnailMap.larguraMapa / thumbnailMap.alturaMapa,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: beastHide),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            TelemetryService.instance.logAbrirMapa(
              widget.cragId,
              widget.nomeContexto ?? widget.setorContext?.nome ?? 'Geral',
            );
            AppNav.toMapas(
              context,
              cragId: widget.cragId,
              mapas: widget.mapas.map((m) => CarrosselItemData(
                mapaCaminhoImagem: m.caminhoImagemMapa,
                setorContextNome: widget.setorContext?.nome,
                grupoContextNome: widget.grupoContext?.nome,
              )).toList(),
              imageProviderOverride: widget.imageProviderOverride,
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Imagem de fundo
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: thumbnailMap.larguraMapa / thumbnailMap.alturaMapa,
                  child: Image(image: snapshot.data!, fit: BoxFit.cover),
                ),
              ),
              // Overlay escuro
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              // Botão Translúcido
              Container(
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
                    Icon(Icons.map, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      widget.mapas.length > 1
                          ? 'Mapas Interativos (${widget.mapas.length})'
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
            ],
          ),
        );
      },
    );
  }
}

Future<ImageProvider?> resolveMapImageProvider(String cragId, Mapa mapa) async {
  return resolveImagePathProvider(cragId, mapa.caminhoImagemMapa);
}

Future<ImageProvider?> resolveImagePathProvider(
  String cragId,
  String path,
) async {
  return ProvedorImagemAresta.resolver(
    picoId: cragId,
    caminho: path,
  );
}
