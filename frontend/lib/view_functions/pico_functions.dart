import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../utils/markdown_utils.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/main.dart';
import 'common_functions.dart';
import 'offline_markdown.dart';
import 'package:fuzzy/fuzzy.dart';
import 'via_functions.dart';
import '../navigation/navigation_functions.dart';
import '../services/firebase/telemetry_service.dart';

/// Filtra e retorna apenas os botões que possuem destino do tipo seção textual.
List<Botao> getSecaoBotoes(Croqui croqui) {
  return croqui.botoes
      .where((b) => b.hasDestino() && b.destino.hasSecaoTextual())
      .toList();
}

/// Retorna os botões de seção textual que são considerados de "capa" (contêm "capa" no texto).
List<Botao> getCapaBotoes(List<Botao> botoes) {
  return botoes.where((b) => b.texto.toLowerCase().contains('capa')).toList();
}

/// Retorna os botões de seção textual que não são de capa.
List<Botao> getOtherBotoes(List<Botao> botoes) {
  return botoes.where((b) => !b.texto.toLowerCase().contains('capa')).toList();
}

/// Constrói o corpo rolável principal da página do Pico.
///
/// Ele extrai a descrição e itera por todos os setores disponíveis para renderizá-los.
Widget buildPicoBody(BuildContext context, Pico pico, Croqui croqui, String cragId, [GlobalKey? mapaKey]) {
  final secaoBotoes = getSecaoBotoes(croqui);
  final capaBotoes = getCapaBotoes(secaoBotoes);
  final otherBotoes = getOtherBotoes(secaoBotoes);

  bool mapaKeyAssigned = false;

  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('Informações do Local'),
        _buildInfoRow('Nome', pico.nome),
        if (pico.descricao.isNotEmpty) ...[
          const SizedBox(height: 10),
          OfflineMarkdown(data: pico.descricao, cragId: cragId),
          const SizedBox(height: 10),
        ],
        if (pico.estado.isNotEmpty) _buildInfoRow('Estado', pico.estado),
        const SizedBox(height: 20),
        if (capaBotoes.isNotEmpty) ...[
          ...capaBotoes.map((b) {
            final md = b.destino.secaoTextual;
            final isMap = b.texto.toLowerCase().contains('mapa') || md.conteudo.toLowerCase().contains('mapa');
            final useKey = !mapaKeyAssigned && isMap && mapaKey != null;
            if (useKey) mapaKeyAssigned = true;

            Widget child = Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: OfflineMarkdown(data: md.conteudo, cragId: cragId),
            );

            if (useKey) {
              return KeyedSubtree(key: mapaKey, child: child);
            }
            return child;
          }),
          const SizedBox(height: 10),
        ],
        if (otherBotoes.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildHeader('Mais Informações'),
          ...otherBotoes.map((b) => buildBotaoTile(context, b, cragId)),
        ],
        _buildHeader('Setores'),
        if (pico.setoresOuGrupos.isEmpty)
          Text('Nenhum elemento disponível.', style: TextStyle(color: fishBone))
        else
          ...pico.setoresOuGrupos.map((setorOuGrupo) {
            if (setorOuGrupo.whichTipo() == SetorOuGrupo_Tipo.setor && setorOuGrupo.setor.hasConteudo()) {
              return buildSectorTile(context, setorOuGrupo.setor.conteudo, cragId);
            } else if (setorOuGrupo.whichTipo() == SetorOuGrupo_Tipo.grupo && setorOuGrupo.grupo.hasConteudo()) {
              return buildGrupoTile(context, setorOuGrupo.grupo.conteudo, cragId);
            }
            return const SizedBox.shrink();
          }),
      ],
    ),
  );
}

Widget _buildHeader(String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      title,
      style: TextStyle(
        color: beastHide,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

Widget _buildInfoRow(String label, String value) {
  if (value.isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(color: beastHide, fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: value,
            style: TextStyle(color: fishBone),
          ),
        ],
      ),
    ),
  );
}

Widget buildSectorTile(BuildContext context, Setor setor, String cragId) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Material(
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: beastHide.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
      title: Text(
        setor.nome,
        style: TextStyle(color: fishBone, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      subtitle: setor.descricao.isNotEmpty
          ? Text(setor.descricao, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fishBone.withValues(alpha: 0.6), fontSize: 13))
          : null,
      trailing: Icon(Icons.chevron_right, color: beastHide),
      onTap: () {
        TelemetryService.instance.logAbrirSetor(cragId, setor.nome);
        AppNav.toSetor(context, setor: setor);
      },
    ),
  ));
}

Widget buildGrupoTile(BuildContext context, Grupo grupo, String cragId) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Material(
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: beastHide.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
      title: Text(
        grupo.nome,
        style: TextStyle(color: fishBone, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      subtitle: grupo.descricao.isNotEmpty
          ? Text(grupo.descricao, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fishBone.withValues(alpha: 0.6), fontSize: 13))
          : null,
      trailing: Icon(Icons.folder, color: beastHide),
      onTap: () {
        TelemetryService.instance.logAbrirGrupo(cragId, grupo.nome);
        AppNav.toGrupo(context, grupo: grupo);
      },
    ),
  ));
}

List<Escalada> getAllEscaladasFromPico(Pico pico) {
  final List<Escalada> allEscaladas = [];
  for (final sg in pico.setoresOuGrupos) {
    if (sg.whichTipo() == SetorOuGrupo_Tipo.setor && sg.setor.hasConteudo()) {
      allEscaladas.addAll(sg.setor.conteudo.escaladas);
    } else if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo && sg.grupo.hasConteudo()) {
      for (final s in sg.grupo.conteudo.setores) {
        if (s.hasConteudo()) {
          allEscaladas.addAll(s.conteudo.escaladas);
        }
      }
    }
  }
  return allEscaladas;
}

Setor? findSetorForEscalada(Pico pico, Escalada target) {
  for (final sg in pico.setoresOuGrupos) {
    if (sg.whichTipo() == SetorOuGrupo_Tipo.setor && sg.setor.hasConteudo()) {
      if (sg.setor.conteudo.escaladas.contains(target)) return sg.setor.conteudo;
    } else if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo && sg.grupo.hasConteudo()) {
      for (final s in sg.grupo.conteudo.setores) {
        if (s.hasConteudo() && s.conteudo.escaladas.contains(target)) return s.conteudo;
      }
    }
  }
  return null;
}

bool isPicoBoulderArea(Pico pico) {
  final allEscaladas = getAllEscaladasFromPico(pico);
  return isBoulderArea(allEscaladas);
}

class ViaSearchDelegate extends SearchDelegate<Escalada?> {
  final Pico pico;
  final String cragId;
  late final List<Escalada> allEscaladas;

  ViaSearchDelegate(this.pico, this.cragId) {
    allEscaladas = getAllEscaladasFromPico(pico);
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: beastHide),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: fishBone, fontSize: 14),
        border: InputBorder.none,
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: TextStyle(color: beastHide, fontSize: 16),
      ),
    );
  }

  @override
  String get searchFieldLabel {
    if (isPicoBoulderArea(pico)) {
      return 'Buscar boulder (ex: V4)...';
    } else {
      return 'Buscar via (ex: 7a)...';
    }
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear, color: beastHide),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: beastHide),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList();
  }

  Widget _buildList() {
    if (query.isEmpty) {
      return Container(color: nobleBlack);
    }

    final queryLower = normalizeSearchString(query);

    final fuse = Fuzzy<Escalada>(
      allEscaladas,
      options: FuzzyOptions(
        keys: [
          WeightedKey<Escalada>(
            name: 'nome',
            getter: (e) => normalizeSearchString(getEscaladaNome(e)),
            weight: 1.0,
          ),
          WeightedKey<Escalada>(
            name: 'grau',
            getter: (e) => normalizeSearchString(getGrauString(e)),
            weight: 0.8,
          ),
        ],
        threshold: 0.4,
      ),
    );

    final results = fuse.search(queryLower).map((r) => r.item).toList();

    if (results.isEmpty) {
      String emptyText = 'Nenhuma via encontrada.';
      if (isPicoBoulderArea(pico)) {
        emptyText = 'Nenhum boulder encontrado.';
      }
      
      return Container(
        color: nobleBlack,
        alignment: Alignment.center,
        child: Text(
          emptyText,
          style: TextStyle(color: fishBone, fontSize: 16),
        ),
      );
    }

    return Container(
      color: nobleBlack,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final escalada = results[index];
          final nome = getEscaladaNome(escalada);
          final grau = getGrauString(escalada);
          final subtitle = grau.isNotEmpty ? 'Dificuldade: $grau' : null;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.white.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: beastHide.withValues(alpha: 0.2)),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
              title: Text(nome, style: TextStyle(color: fishBone, fontWeight: FontWeight.bold)),
              subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: fishBone.withValues(alpha: 0.7), fontSize: 12)) : null,
              leading: Icon(Icons.terrain, color: beastHide),
              trailing: Icon(Icons.chevron_right, color: beastHide),
              onTap: () {
                close(context, escalada);
              },
            ),
          ));
        },
      ),
    );
  }
}

Widget buildBotaoTile(BuildContext context, Botao botao, String cragId) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Material(
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: beastHide.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(Icons.info_outline, color: beastHide),
        title: Text(
          botao.texto,
          style: TextStyle(color: fishBone, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        trailing: Icon(Icons.chevron_right, color: beastHide),
        onTap: () {
          if (botao.hasDestino() && botao.destino.hasSecaoTextual()) {
            final md = botao.destino.secaoTextual;
            final treeNav = TreeNavigationWrapper.currentTreeController;
            if (treeNav != null) {
              treeNav.navigateTo(TextNode(title: botao.texto, parent: treeNav.currentNode));
            }
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) {
                return DraggableScrollableSheet(
                  initialChildSize: 0.6,
                  minChildSize: 0.4,
                  maxChildSize: 0.9,
                  expand: false,
                  builder: (context, scrollController) {
                    final bottomPadding = MediaQuery.of(context).padding.bottom;
                    return ListView(
                      controller: scrollController,
                      padding: EdgeInsets.only(
                        top: 20,
                        left: 20,
                        right: 20,
                        bottom: 20 + bottomPadding,
                      ),
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                botao.texto,
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: beastHide),
                              ),
                            ),
                            buildFeedbackButton(context, color: beastHide),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Builder(
                          builder: (context) {
                            final content = MarkdownUtils.cleanModalContent(md.conteudo, botao.texto);
                            return OfflineMarkdown(data: content, cragId: cragId);
                          }
                        ),
                      ],
                    );
                  },
                );
              },
            ).whenComplete(() {
              final treeNav = TreeNavigationWrapper.currentTreeController;
              if (treeNav != null && treeNav.currentNode is TextNode) {
                treeNav.goBack();
              }
            });
          }
        },
      ),
    ),
  );
}
