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
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
              title: Text(
                widget.setor.nome.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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
