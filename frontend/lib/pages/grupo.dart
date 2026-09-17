// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../view_functions/common_functions.dart';
import '../view_functions/grupo_functions.dart';
import '../theme/app_colors.dart';
import '../view_functions/browse_functions.dart';
import '../widgets/mapa_thumbnail.dart';

/// Uma página que exibe informações detalhadas sobre um grupo específico de setores.
///
/// Ela apresenta a descrição, propriedades do grupo e lista todos os setores contidos nele.
class GrupoPage extends StatefulWidget {
  final Grupo grupo;
  final String cragId;

  const GrupoPage({super.key, required this.grupo, required this.cragId});

  @override
  State<GrupoPage> createState() => _GrupoPageState();
}

class _GrupoPageState extends State<GrupoPage> {
  GrupoSortMode _sortMode = GrupoSortMode.original;
  Future<ImageProvider?>? _coverProviderFuture;

  @override
  void initState() {
    super.initState();
    _coverProviderFuture = _resolveCoverImage();
  }

  @override
  void didUpdateWidget(GrupoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      _coverProviderFuture = _resolveCoverImage();
    });
  }


  Future<ImageProvider?> _resolveCoverImage() async {
    // Tenta encontrar uma imagem Markdown aleatória
    final String jsonString = jsonEncode(widget.grupo.toProto3Json());
    final RegExp regex = RegExp(r'!\[.*?\]\((.*?)\)');
    final matches = regex.allMatches(jsonString);
    List<String> paths = [];

    for (var match in matches) {
      if (match.groupCount >= 1) {
        String path = match.group(1)!;
        if (!path.startsWith('http')) {
          paths.add(path);
        }
      }
    }

    if (paths.isNotEmpty) {
      final firstPath = paths.first;
      return resolveImagePathProvider(widget.cragId, firstPath, larguraAlvo: 600);
    }

    // Se não encontrou imagens, retorna null para fazer fallback pra capa principal
    return null;
  }

  List<ArquivoSetor> get _sortedSetores {
    if (_sortMode == GrupoSortMode.original) return widget.grupo.setores;

    final list = List<ArquivoSetor>.from(widget.grupo.setores);
    list.sort((a, b) {
      if (!a.hasConteudo() || !b.hasConteudo()) return 0;

      final nomeA = a.conteudo.nome.toLowerCase();
      final nomeB = b.conteudo.nome.toLowerCase();

      switch (_sortMode) {
        case GrupoSortMode.alphaAsc:
          return nomeA.compareTo(nomeB);
        case GrupoSortMode.alphaDesc:
          return nomeB.compareTo(nomeA);
        default:
          return 0;
      }
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            backgroundColor: context.colors.deepBasalt,
            iconTheme: IconThemeData(color: context.colors.chalkWhite),
            actions: [
              buildFeedbackButton(context, color: context.colors.chalkWhite),
              const SizedBox(width: 8),
            ],
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final top = constraints.biggest.height;
                final collapsedHeight =
                    MediaQuery.of(context).padding.top + kToolbarHeight;
                final expandedHeight = 300.0;
                // A variável 't' (progresso) vai de 1.0 (totalmente expandido) a 0.0 (totalmente colapsado).
                // Usamos isso para animar manualmente o padding e o tamanho da fonte.
                double t =
                    (top - collapsedHeight) /
                    (expandedHeight - collapsedHeight);
                t = t.clamp(0.0, 1.0);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    FlexibleSpaceBar(
                      background:
                          widget.grupo.mapas.isNotEmpty &&
                              _coverProviderFuture != null
                          ? FutureBuilder<ImageProvider?>(
                              future: _coverProviderFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Container(
                                    color: context.colors.deepBasalt,
                                  );
                                }
                                if (snapshot.hasData && snapshot.data != null) {
                                  return Stack(
                                    fit: StackFit.expand,
                                    children: [
                                       Image(
                                         image: snapshot.data!,
                                         fit: BoxFit.cover,
                                         errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                       ),
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        right: 0,
                                        height: 200,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.black,
                                                Colors.black.withValues(
                                                  alpha: 0.7,
                                                ),
                                                Colors.transparent,
                                              ],
                                              stops: const [0.0, 0.4, 1.0],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        height: 200,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                Colors.black.withValues(
                                                  alpha: 0.9,
                                                ),
                                                Colors.black.withValues(
                                                  alpha: 0.6,
                                                ),
                                                Colors.transparent,
                                              ],
                                              stops: const [0.0, 0.4, 1.0],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    buildCragBackground(
                                      '',
                                      cragId: widget.cragId,
                                    ),
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      height: 200,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.black,
                                              Colors.black.withValues(
                                                alpha: 0.7,
                                              ),
                                              Colors.transparent,
                                            ],
                                            stops: const [0.0, 0.4, 1.0],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      height: 200,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              Colors.black.withValues(
                                                alpha: 0.9,
                                              ),
                                              Colors.black.withValues(
                                                alpha: 0.6,
                                              ),
                                              Colors.transparent,
                                            ],
                                            stops: const [0.0, 0.4, 1.0],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            )
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                buildCragBackground('', cragId: widget.cragId),
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  height: 200,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black,
                                          Colors.black.withValues(alpha: 0.7),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.4, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  height: 200,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.9),
                                          Colors.black.withValues(alpha: 0.6),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.4, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    Positioned(
                      // Anima a margem esquerda de 16 (expandido) para 72 (colapsado) para não sobrepor o botão de voltar.
                      left: 16 + (56 * (1 - t)),
                      // Anima a margem direita para dar espaço ao botão de feedback.
                      right: 16 + (72 * (1 - t)),
                      bottom: 16,
                      child: Text(
                        widget.grupo.nome.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'BebasNeue',
                          // A fonte diminui suavemente de 28 para 20.
                          fontSize: 20 + (8 * t),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                        // Força para 1 linha a partir da metade do scroll para evitar que o texto bata na status bar.
                        maxLines: t > 0.5 ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: SafeArea(
              top: false,
              bottom: true,
              child: buildGrupoBody(
                context,
                widget.grupo,
                widget.cragId,
                _sortedSetores,
                _sortMode,
                (mode) {
                  setState(() {
                    _sortMode = mode;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
