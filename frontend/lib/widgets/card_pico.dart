// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../view/view_models/card_croqui_view_model.dart';
import '../theme/cores_app.dart';
import 'provedor_imagem_aresta.dart';

/// Card interativo que exibe um resumo visual do pico (croqui) a partir de [CardCroquiViewModel] (Dumb UI).
///
/// Não contém regras de negócio ou de formatação de entidades de dados, apenas renderiza visualmente
/// as informações já preparadas e delega ações do usuário via callbacks.
class CragCard extends StatelessWidget {
  final CardCroquiViewModel dados;
  final ValueListenable<Map<String, double>> downloadingCrags;
  final VoidCallback onDownload;
  final VoidCallback? onOpen;

  const CragCard({
    super.key,
    required this.dados,
    required this.downloadingCrags,
    required this.onDownload,
    this.onOpen,
  });

  /// Construtor de conveniência que recebe metadados flexíveis e mapeia para [CardCroquiViewModel].
  factory CragCard.deMetadados({
    Key? key,
    required dynamic metadados,
    required ValueListenable<Map<String, double>> downloadingCrags,
    required VoidCallback onDownload,
    VoidCallback? onOpen,
    String? distanceStr,
    bool showDetailedStats = false,
    bool isDownloaded = false,
  }) {
    return CragCard(
      key: key,
      dados: mapearMetadadosParaCard(
        metadados,
        salvoOffline: isDownloaded,
        textoDistancia: distanceStr,
        estatisticasDetalhadas: showDetailedStats,
      ),
      downloadingCrags: downloadingCrags,
      onDownload: onDownload,
      onOpen: onOpen,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String id = dados.id;
    final String nome = dados.titulo;
    final String thumbnailUrl = dados.caminhoMiniatura;
    final String statsText = dados.textoEstatisticas;
    final bool isDownloaded = dados.salvoOffline;
    final String? distanceStr = dados.textoDistancia;
    final String? capaPath = dados.caminhoCapa;
    final String? checksumSha256 = dados.checksumSha256;

    return GestureDetector(
      onTap: () {
        if (onOpen != null) {
          onOpen!();
        } else {
          onDownload();
        }
      },
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: context.colors.darkPine,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            buildCragBackground(
              thumbnailUrl,
              cragId: id,
              capaPath: capaPath,
              checksumSha256: checksumSha256,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (distanceStr != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.place,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                distanceStr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isDownloaded)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF7B8B6F,
                            ).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'SALVO OFFLINE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ValueListenableBuilder<Map<String, double>>(
                        valueListenable: downloadingCrags,
                        builder: (context, downloadingMap, child) {
                          final progress = downloadingMap[id];
                          if (progress != null) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${(progress * 100).toInt()}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statsText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget interno para carregar o plano de fundo da imagem do pico,
/// resolvendo primeiro do armazenamento local e caindo para rede se necessário
/// através de [ProvedorImagemAresta].
class _CragBackgroundWidget extends StatefulWidget {
  final String thumbnailUrl;
  final String? cragId;
  final String? capaPath;
  final String? checksumSha256;
  final int larguraAlvo;
  final void Function(double proporcao)? aoResolverProporcao;

  const _CragBackgroundWidget({
    required this.thumbnailUrl,
    this.cragId,
    this.capaPath,
    this.checksumSha256,
    this.larguraAlvo = 450,
    this.aoResolverProporcao,
  });

  @override
  State<_CragBackgroundWidget> createState() => _CragBackgroundWidgetState();
}

class _CragBackgroundWidgetState extends State<_CragBackgroundWidget> {
  Future<ImageProvider?>? _provedorImagemFuture;
  ImageStream? _imagemStream;
  ImageStreamListener? _imagemStreamListener;

  @override
  void initState() {
    super.initState();
    _inicializarProvedor();
  }

  @override
  void didUpdateWidget(covariant _CragBackgroundWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thumbnailUrl != widget.thumbnailUrl ||
        oldWidget.cragId != widget.cragId ||
        oldWidget.capaPath != widget.capaPath ||
        oldWidget.checksumSha256 != widget.checksumSha256 ||
        oldWidget.larguraAlvo != widget.larguraAlvo ||
        (oldWidget.aoResolverProporcao == null) !=
            (widget.aoResolverProporcao == null)) {
      _inicializarProvedor();
    }
  }

  @override
  void dispose() {
    _removerOuvinteImagem();
    super.dispose();
  }

  void _removerOuvinteImagem() {
    if (_imagemStream != null && _imagemStreamListener != null) {
      _imagemStream!.removeListener(_imagemStreamListener!);
      _imagemStream = null;
      _imagemStreamListener = null;
    }
  }

  void _inicializarProvedor() {
    _removerOuvinteImagem();
    _provedorImagemFuture = null;
    String? cragId = widget.cragId;
    if ((cragId == null || cragId.isEmpty) && widget.thumbnailUrl.isNotEmpty) {
      final correspondencia =
          RegExp(r'thumbnails/([^/?#]+)\.webp').firstMatch(widget.thumbnailUrl);
      if (correspondencia != null) {
        cragId = correspondencia.group(1);
      }
    }

    // Prioriza capaPath local ou remoto; se ausente, recorre a thumbnailUrl quando definida.
    // Se nenhum caminho estiver disponível, não dispara resolução e exibe a logo da splash screen.
    final String caminhoFinal;
    if (widget.capaPath != null && widget.capaPath!.trim().isNotEmpty) {
      caminhoFinal = widget.capaPath!.trim();
    } else if (widget.thumbnailUrl.trim().isNotEmpty &&
        !widget.thumbnailUrl.endsWith('/.webp')) {
      caminhoFinal = widget.thumbnailUrl.trim();
    } else {
      return;
    }

    final future = ProvedorImagemAresta.resolver(
      picoId: cragId ?? '',
      caminho: caminhoFinal,
      checksumSha256: widget.checksumSha256,
      larguraAlvo: widget.larguraAlvo,
    );

    if (widget.aoResolverProporcao != null) {
      future.then((provedor) {
        if (provedor != null && mounted) {
          _removerOuvinteImagem();
          final stream = provedor.resolve(const ImageConfiguration());
          _imagemStream = stream;
          _imagemStreamListener = ImageStreamListener(
            (ImageInfo info, bool synchronousCall) {
              final w = info.image.width;
              final h = info.image.height;
              if (w > 0 && h > 0 && mounted) {
                widget.aoResolverProporcao?.call(w / h);
              }
            },
            onError: (dynamic _, StackTrace? stackTrace) {},
          );
          stream.addListener(_imagemStreamListener!);
        }
      });
    }

    _provedorImagemFuture = future;
  }

  /// Constrói a capa padrão com a logo do Aresta preenchendo 100% do espaço sobre fundo preto.
  /// Usado exclusivamente quando o croqui não possui capa declarada no Protobuf.
  Widget _construirCapaPadraoAresta() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Image.asset(
        'assets/logo_in_app.jpg',
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  /// Constrói o container com ícone de imagem indisponível ([Icons.broken_image]).
  /// Usado quando o croqui possui capa no Protobuf mas ela não foi baixada ou falhou.
  Widget _construirImagemIndisponivel() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF2C332A),
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey,
          size: 50,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_provedorImagemFuture != null) {
      return FutureBuilder<ImageProvider?>(
        future: _provedorImagemFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFF2C332A),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            final imageProvider = snapshot.data!;
            return Image(
              image: imageProvider,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _construirImagemIndisponivel(),
            );
          }
          return _construirImagemIndisponivel();
        },
      );
    }
    return _construirCapaPadraoAresta();
  }
}

/// Constrói o fundo visual do card ou cabeçalho do pico com suporte a cache local e [ProvedorImagemAresta].
///
/// Renderiza a imagem em camada única com [BoxFit.cover], permitindo configurar [larguraAlvo]
/// (padrão de 450 para cards e 1200 para cabeçalho) e [aoResolverProporcao] para notificar
/// a proporção de aspecto (`largura / altura`) decodificada da imagem.
Widget buildCragBackground(
  String thumbnailUrl, {
  String? cragId,
  String? capaPath,
  String? checksumSha256,
  int larguraAlvo = 450,
  void Function(double proporcao)? aoResolverProporcao,
}) {
  return _CragBackgroundWidget(
    thumbnailUrl: thumbnailUrl,
    cragId: cragId,
    capaPath: capaPath,
    checksumSha256: checksumSha256,
    larguraAlvo: larguraAlvo,
    aoResolverProporcao: aoResolverProporcao,
  );
}
