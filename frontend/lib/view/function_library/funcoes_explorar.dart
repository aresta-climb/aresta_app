// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/modelos/modelos_clima_pico.dart';
import '../../idioma/tradutor_app.dart';
import '../../widgets/card_pico.dart';
import '../../widgets/explorar/componentes_marcador_globo.dart';
import '../view_models/card_croqui_view_model.dart';

export '../../widgets/card_pico.dart';

/// Extrai a sigla da Unidade Federativa (`UF`, ex.: `'MG'`, `'RJ'`) a partir do slug/caminho
/// padronizado do catálogo (`br_mg_...`) ou aproxima pela coordenada geográfica.
String extrairSiglaUfPico({
  required String id,
  required String caminhoRelativo,
  required double latitude,
  required double longitude,
}) {
  final padraoBr = RegExp(r'(?:^|/|_)br_([a-zA-Z]{2})(?:_|/)');
  final mId = padraoBr.firstMatch(id);
  if (mId != null) return mId.group(1)!.toUpperCase();

  final mCam = padraoBr.firstMatch(caminhoRelativo);
  if (mCam != null) return mCam.group(1)!.toUpperCase();

  if (latitude >= -23.4 &&
      latitude <= -20.7 &&
      longitude >= -44.9 &&
      longitude <= -40.9) {
    return 'RJ';
  }
  if (latitude >= -21.4 &&
      latitude <= -17.8 &&
      longitude >= -41.9 &&
      longitude <= -39.6) {
    return 'ES';
  }
  if (latitude >= -25.3 &&
      latitude <= -19.7 &&
      longitude >= -53.1 &&
      longitude <= -44.1) {
    return 'SP';
  }
  if (latitude >= -22.9 &&
      latitude <= -14.2 &&
      longitude >= -51.1 &&
      longitude <= -39.8) {
    return 'MG';
  }
  if (latitude < -25.3) return 'RS';
  if (latitude > -14.2) return 'BA';
  return 'BR';
}

/// Constrói um [MarcadorPicoGlobo] imutável a partir dos dados geográficos, cota DEM e estado de umidade.
MarcadorPicoGlobo construirMarcadorGloboPico({
  required String id,
  required String nome,
  required String caminhoRelativo,
  required double latitude,
  required double longitude,
  required CotaAltimetricaPico? cota,
  required EstadoUmidadePico umidade,
}) {
  final picoAlt = cota?.altitudePicoMetros ?? 920;
  final baseAlt = cota?.altitudeBaseMetros ?? math.max(0, picoAlt - 280);
  return MarcadorPicoGlobo(
    id: id,
    nome: nome.isEmpty ? tr(ChaveTexto.comumPico) : nome,
    uf: extrairSiglaUfPico(
      id: id,
      caminhoRelativo: caminhoRelativo,
      latitude: latitude,
      longitude: longitude,
    ),
    latitude: latitude,
    longitude: longitude,
    altitudeBaseMetros: baseAlt,
    altitudePicoMetros: picoAlt,
    dimensaoGradeDem: cota?.dimensaoGradeDem ?? 0,
    raioGradeDemGraus: cota?.raioGradeDemGraus ?? 0.024,
    gradeDemMetros: cota?.gradeDemMetros ?? const [],
    umidade: umidade,
  );
}

/// Normaliza um alvo de download (`CardCroquiViewModel`, `Map` ou identificador textual) em `(id, nome)`.
({String id, String nome}) resolverAlvoDownloadExplorar(Object? crag) {
  final padraoPico = tr(ChaveTexto.comumPico);
  if (crag is CardCroquiViewModel) {
    return (
      id: crag.id,
      nome: crag.titulo.isEmpty ? padraoPico : crag.titulo,
    );
  }
  if (crag is Map) {
    return (
      id: crag['id']?.toString() ?? '',
      nome: crag['nome']?.toString() ?? padraoPico,
    );
  }
  return (id: crag?.toString() ?? '', nome: padraoPico);
}

                  downloadingCrags: downloadingCrags,
                  onDownload: () => onDownload(dados),
                  onOpen: onOpen != null ? () => onOpen(dados) : null,
                ),
              );
            },
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

class _AnimatedMapButtonState extends State<_AnimatedMapButton>
    with SingleTickerProviderStateMixin {
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
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.explore_outlined,
                      color: const Color(0xFFC05244),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'VER NO MAPA',
                      style: TextStyle(
                        color: const Color(0xFFC05244),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wrapper for _CragCard to maintain compatibility with other modules and tests.
Widget buildCragListItem(
  dynamic crag,
  ValueListenable<Map<String, double>> downloadingCrags,
  VoidCallback onDownload, {
  VoidCallback? onOpen,
  bool isDownloaded = false,
}) {
  final item = _normalizarCards([crag]).first;
  final dados = item.salvoOffline == isDownloaded
      ? item
      : item.comSalvoOffline(isDownloaded);
  return CragCard(
    dados: dados,
    downloadingCrags: downloadingCrags,
    onDownload: onDownload,
    onOpen: onOpen,
  );
}

void showDownloadBottomSheet(
  BuildContext context,
  dynamic crag,
  VoidCallback onDownload,
  ValueListenable<Map<String, double>> downloadingCrags, {
  VoidCallback? onOpen,
  bool isDownloaded = false,
}) {
  final CardCroquiViewModel pico = _normalizarCards([crag]).first;
  final String localFormatado = pico.localizacao;

  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: context.colors.deepBasalt,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext bottomSheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottom sheet handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.graniteEdge,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                pico.nome.isNotEmpty ? pico.nome : 'Pico',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localFormatado.isNotEmpty ? localFormatado : 'Local Desconhecido',
                style: TextStyle(color: context.colors.ashGrey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (pico.descricao.isNotEmpty) ...[
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      pico.descricao,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              ValueListenableBuilder<Map<String, double>>(
                valueListenable: downloadingCrags,
                builder: (context, downloadingMap, child) {
                  final progress = downloadingMap[pico.id];
                  final isDownloading = progress != null;

                  if (isDownloading) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: context.colors.darkPine,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'BAIXANDO...',
                            style: TextStyle(
                              color: context.colors.dryMoss,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: context.colors.graniteEdge,
                              color: context.colors.dryMoss,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (isDownloaded && onOpen != null) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            bottomSheetContext,
                          ); // Close sheet first
                          onOpen();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.dryMoss,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'ABRIR CROQUI',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    );
                  }

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        onDownload();
                        Navigator.pop(
                          bottomSheetContext,
                        ); // Close sheet after triggering download
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC05244), // Red button
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'BAIXAR CROQUI',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
