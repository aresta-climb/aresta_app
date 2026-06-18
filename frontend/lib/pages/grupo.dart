import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../view_functions/common_functions.dart';
import '../view_functions/grupo_functions.dart';

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
      appBar: buildCommonAppBar(context, widget.grupo.nome),
      body: SafeArea(bottom: true, child: buildGrupoBody(
        context, 
        widget.grupo, 
        widget.cragId, 
        _sortedSetores, 
        buildSortMenu<GrupoSortMode>(
          currentMode: _sortMode,
          onSelected: (mode) {
            setState(() {
              _sortMode = mode;
            });
          },
          options: const {
            GrupoSortMode.original: 'Padrão do Guia',
            GrupoSortMode.alphaAsc: 'Alfabético (A-Z)',
            GrupoSortMode.alphaDesc: 'Alfabético (Z-A)',
          },
        )
      )),
      // bottomNavigationBar: buildSecondaryBottomNav(context),
    );
  }
}

