import 'dart:convert';
import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../view_functions/common_functions.dart';
import '../view_functions/setor_functions.dart';
import '../view_functions/via_functions.dart';
import '../theme/app_colors.dart';
import '../view_functions/browse_functions.dart';
import '../widgets/mapa_thumbnail.dart';

/// Uma página que fornece uma visão geral de um setor específico.
///
/// Ela exibe a descrição do setor e apresenta uma lista de todas as vias
/// de escalada ([Escalada]) e quaisquer subsetores contidos nele.
class SetorPage extends StatefulWidget {
  final Setor setor;
  final Grupo? grupoContext;
  final String cragId;
  final Escalada? scrollToEscalada;

  const SetorPage({
    super.key, 
    required this.setor, 
    this.grupoContext,
    required this.cragId,
    this.scrollToEscalada,
  });

  @override
  State<SetorPage> createState() => _SetorPageState();
}

class _SetorPageState extends State<SetorPage> {
  final EscaladaSortMode _sortMode = EscaladaSortMode.original;
  Future<ImageProvider?>? _coverProviderFuture;
  String? _coverImagePath;
  GlobalKey? _targetKey;

  @override
  void initState() {
    super.initState();
    _coverProviderFuture = _resolveCoverImage();

    if (widget.scrollToEscalada != null) {
      _targetKey = GlobalKey();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && _targetKey?.currentContext != null) {
          Scrollable.ensureVisible(
            _targetKey!.currentContext!,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            alignment: 0.5, // Alinha bem no meio da tela
          );
        }
      });
    }
  }

  @override
  void didUpdateWidget(SetorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollToEscalada != oldWidget.scrollToEscalada && widget.scrollToEscalada != null) {
      setState(() {
        _targetKey = GlobalKey();
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && _targetKey?.currentContext != null) {
          Scrollable.ensureVisible(
            _targetKey!.currentContext!,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            alignment: 0.5,
          );
        }
      });
    }
  }

  Future<ImageProvider?> _resolveCoverImage() async {
    // Tenta encontrar uma imagem Markdown aleatória
    final String jsonString = jsonEncode(widget.setor.toProto3Json());
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
      _coverImagePath = firstPath;
      return resolveImagePathProvider(widget.cragId, firstPath);
    }

    // Se não encontrou imagens, retorna null para fazer fallback pra capa principal
    return null;
  }

  List<Escalada> get _sortedEscaladas {
    if (_sortMode == EscaladaSortMode.original) return widget.setor.escaladas;
    
    final list = List<Escalada>.from(widget.setor.escaladas);
    list.sort((a, b) {
      switch (_sortMode) {
        case EscaladaSortMode.alphaAsc:
          return getEscaladaNome(a).toLowerCase().compareTo(getEscaladaNome(b).toLowerCase());
        case EscaladaSortMode.alphaDesc:
          return getEscaladaNome(b).toLowerCase().compareTo(getEscaladaNome(a).toLowerCase());
        case EscaladaSortMode.gradeAsc:
          return getGrauValue(a).compareTo(getGrauValue(b));
        case EscaladaSortMode.gradeDesc:
          return getGrauValue(b).compareTo(getGrauValue(a));
        case EscaladaSortMode.protectionsAsc:
          return getProtecoesValue(a).compareTo(getProtecoesValue(b));
        case EscaladaSortMode.protectionsDesc:
          return getProtecoesValue(b).compareTo(getProtecoesValue(a));
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
                final collapsedHeight = MediaQuery.of(context).padding.top + kToolbarHeight;
                final expandedHeight = 300.0;
                // A variável 't' (progresso) vai de 1.0 (totalmente expandido) a 0.0 (totalmente colapsado).
                // Usamos isso para animar manualmente o padding e o tamanho da fonte.
                double t = (top - collapsedHeight) / (expandedHeight - collapsedHeight);
                t = t.clamp(0.0, 1.0); // 1.0 = expanded, 0.0 = collapsed

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    FlexibleSpaceBar(
                      background: widget.setor.mapas.isNotEmpty && _coverProviderFuture != null
                          ? FutureBuilder<ImageProvider?>(
                      future: _coverProviderFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(color: context.colors.deepBasalt);
                        }
                        if (snapshot.hasData && snapshot.data != null) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              Image(
                                image: snapshot.data!,
                                fit: BoxFit.cover,
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
                                      colors: [Colors.black, Colors.black.withValues(alpha: 0.7), Colors.transparent],
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
                                      colors: [Colors.black.withValues(alpha: 0.9), Colors.black.withValues(alpha: 0.6), Colors.transparent],
                                      stops: const [0.0, 0.4, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        // Se não encontrou imagem local, exibe a capa do croqui
                        return Stack(
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
                                    colors: [Colors.black, Colors.black.withValues(alpha: 0.7), Colors.transparent],
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
                                    colors: [Colors.black.withValues(alpha: 0.9), Colors.black.withValues(alpha: 0.6), Colors.transparent],
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
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 150,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.8),
                                  Colors.transparent,
                                ],
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
                      right: 16 + (72 * (1 - t)), // Make room for feedback button
                      bottom: 16,
                      child: Text(
                        widget.setor.nome.toUpperCase(),
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
              child: buildSetorBody(
                context,
                widget.setor,
                widget.cragId,
                _sortedEscaladas,
                widget.scrollToEscalada,
                _targetKey,
                null, // botão de ordenação (se houver)
                widget.grupoContext,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
