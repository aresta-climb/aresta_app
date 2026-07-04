import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../view_functions/common_functions.dart';
import '../view_functions/setor_functions.dart';
import '../view_functions/via_functions.dart';

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
  GlobalKey? _targetKey;
  EscaladaSortMode _sortMode = EscaladaSortMode.original;

  @override
  void initState() {
    super.initState();
    if (widget.scrollToEscalada != null) {
      _targetKey = GlobalKey();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && _targetKey?.currentContext != null) {
          Scrollable.ensureVisible(
            _targetKey!.currentContext!,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            alignment: 0.5, // Aligns precisely in the middle of the screen
          );
        }
      });
    }
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
      appBar: buildCommonAppBar(context, widget.setor.nome),
      body: SafeArea(bottom: true, child: buildSetorBody(
        context, 
        widget.setor, 
        widget.cragId, 
        _sortedEscaladas, 
        widget.scrollToEscalada, 
        _targetKey, 
        buildSortMenu<EscaladaSortMode>(
          currentMode: _sortMode,
          onSelected: (mode) {
            setState(() {
              _sortMode = mode;
            });
          },
          options: const {
            EscaladaSortMode.original: 'Padrão do Guia',
            EscaladaSortMode.alphaAsc: 'Alfabético (A-Z)',
            EscaladaSortMode.alphaDesc: 'Alfabético (Z-A)',
            EscaladaSortMode.gradeAsc: 'Dificuldade (Fácil primeiro)',
            EscaladaSortMode.gradeDesc: 'Dificuldade (Difícil primeiro)',
          },
        ),
        widget.grupoContext,
      )),
      // bottomNavigationBar: buildSecondaryBottomNav(context),
    );
  }
}
