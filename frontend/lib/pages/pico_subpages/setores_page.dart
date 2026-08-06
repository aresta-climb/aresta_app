import 'package:flutter/material.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../view_functions/pico_functions.dart';
import '../../view_functions/common_functions.dart';
import '../../view_functions/grupo_functions.dart';
import '../../widgets/mapa_thumbnail.dart';

class SetoresPage extends StatefulWidget {
  final Pico pico;
  final String cragId;

  const SetoresPage({super.key, required this.pico, required this.cragId});

  @override
  State<SetoresPage> createState() => _SetoresPageState();
}

class _SetoresPageState extends State<SetoresPage> {
  GrupoSortMode _sortMode = GrupoSortMode.original;
  final TextEditingController _searchController = TextEditingController();
  final String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SetorOuGrupo> get _sortedSetoresOuGrupos {
    List<SetorOuGrupo> list = List<SetorOuGrupo>.from(
      widget.pico.setoresOuGrupos,
    );

    if (_searchQuery.isNotEmpty) {
      list = list.where((sg) {
        String nome = '';
        if (sg.whichTipo() == SetorOuGrupo_Tipo.setor &&
            sg.setor.hasConteudo()) {
          nome = sg.setor.conteudo.nome;
        } else if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo &&
            sg.grupo.hasConteudo()) {
          nome = sg.grupo.conteudo.nome;
        }
        return nome.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_sortMode == GrupoSortMode.original) return list;

    list.sort((a, b) {
      String nomeA = '';
      String nomeB = '';

      if (a.whichTipo() == SetorOuGrupo_Tipo.setor && a.setor.hasConteudo()) {
        nomeA = a.setor.conteudo.nome.toLowerCase();
      } else if (a.whichTipo() == SetorOuGrupo_Tipo.grupo &&
          a.grupo.hasConteudo()) {
        nomeA = a.grupo.conteudo.nome.toLowerCase();
      }

      if (b.whichTipo() == SetorOuGrupo_Tipo.setor && b.setor.hasConteudo()) {
        nomeB = b.setor.conteudo.nome.toLowerCase();
      } else if (b.whichTipo() == SetorOuGrupo_Tipo.grupo &&
          b.grupo.hasConteudo()) {
        nomeB = b.grupo.conteudo.nome.toLowerCase();
      }

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
    final hasMap = widget.pico.hasMapasGerais() &&
        widget.pico.mapasGerais.hasConteudo() &&
        widget.pico.mapasGerais.conteudo.mapas.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: hasMap ? 250.0 : null,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              buildFeedbackButton(context, color: Colors.white),
              const SizedBox(width: 8),
            ],
            flexibleSpace: hasMap
                ? FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 50, bottom: 16),
                    title: Text(
                      'SETORES',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.2,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                    background: MapaThumbnail(
                      mapa: widget.pico.mapasGerais.conteudo.mapas.first,
                      cragId: widget.cragId,
                      nomeContexto: widget.pico.nome,
                    ),
                  )
                : FlexibleSpaceBar(
                    title: const Text(
                      'SETORES',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (widget.pico.setoresOuGrupos.isEmpty)
                  Text(
                    'Nenhum elemento disponível.',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  )
                else ...[
                  buildGrupoSortGrid(context, _sortMode, (mode) {
                    setState(() {
                      _sortMode = mode;
                    });
                  }),
                  const SizedBox(height: 16),
                  ..._sortedSetoresOuGrupos.map((setorOuGrupo) {
                    if (setorOuGrupo.whichTipo() == SetorOuGrupo_Tipo.setor &&
                        setorOuGrupo.setor.hasConteudo()) {
                      return buildSectorTile(
                        context,
                        setorOuGrupo.setor.conteudo,
                        widget.cragId,
                      );
                    } else if (setorOuGrupo.whichTipo() ==
                            SetorOuGrupo_Tipo.grupo &&
                        setorOuGrupo.grupo.hasConteudo()) {
                      return buildGrupoTile(
                        context,
                        setorOuGrupo.grupo.conteudo,
                        widget.cragId,
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
