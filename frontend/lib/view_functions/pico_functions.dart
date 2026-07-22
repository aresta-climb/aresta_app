import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/main.dart';
import 'common_functions.dart';
import 'offline_markdown.dart';
import 'package:fuzzy/fuzzy.dart';
import 'via_functions.dart';
import '../navigation/navigation_functions.dart';
import '../services/firebase/telemetry_service.dart';
import '../widgets/mapa_thumbnail.dart';
import '../theme/app_colors.dart';

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
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: OfflineMarkdown(data: md.conteudo, cragId: cragId),
            );
          }),
          const SizedBox(height: 10),
        ],

        if (otherBotoes.isNotEmpty) ...[
          _buildHeader('Mais Informações'),
          ...otherBotoes.map((b) => buildBotaoTile(context, b, cragId)),
          const SizedBox(height: 20),
        ],
        
        if (pico.hasMapasGerais() && pico.mapasGerais.hasConteudo() && pico.mapasGerais.conteudo.mapas.isNotEmpty) ...[
          KeyedSubtree(
            key: mapaKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader('Mapas Gerais'),
                ...pico.mapasGerais.conteudo.mapas.map((mapa) => Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: MapaThumbnail(
                    mapa: mapa,
                    cragId: cragId,
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 10),
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

Widget buildSectorTile(BuildContext context, Setor setor, String cragId, {Grupo? grupoContext}) {
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
      trailing: Icon(Icons.chevron_right, color: beastHide),
      onTap: () {
        TelemetryService.instance.logAbrirSetor(cragId, setor.nome);
        AppNav.toSetor(context, setor: setor, grupoContext: grupoContext);
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
      trailing: Icon(Icons.folder, color: beastHide),
      onTap: () {
        TelemetryService.instance.logAbrirGrupo(cragId, grupo.nome);
        AppNav.toGrupo(context, grupo: grupo);
      },
    ),
  ));
}


List<Setor> getAllSetoresFromPico(Pico pico) {
  final List<Setor> allSetores = [];
  for (final sg in pico.setoresOuGrupos) {
    if (sg.whichTipo() == SetorOuGrupo_Tipo.setor && sg.setor.hasConteudo()) {
      allSetores.add(sg.setor.conteudo);
    } else if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo && sg.grupo.hasConteudo()) {
      for (final s in sg.grupo.conteudo.setores) {
        if (s.hasConteudo()) {
          allSetores.add(s.conteudo);
        }
      }
    }
  }
  return allSetores;
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

class PicoSearchDelegate extends SearchDelegate<Object?> {
  final Pico pico;
  final String cragId;
  late final List<Escalada> allEscaladas;
  late final List<Setor> allSetores;

  PicoSearchDelegate(this.pico, this.cragId) {
    allEscaladas = getAllEscaladasFromPico(pico);
    allSetores = getAllSetoresFromPico(pico);
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: context.colors.deepBasalt,
        iconTheme: const IconThemeData(color: Color(0xFFC04F34)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: context.colors.ashGrey, fontSize: 14),
        border: InputBorder.none,
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: TextStyle(color: context.colors.chalkWhite, fontSize: 16),
      ),
    );
  }

  @override
  String get searchFieldLabel {
    if (isPicoBoulderArea(pico)) {
      return 'Buscar boulder (ex: V4) ou setor...';
    } else {
      return 'Buscar escalada (ex: 7a) ou setor...';
    }
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Color(0xFFC04F34)),
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
      icon: const Icon(Icons.arrow_back, color: Color(0xFFC04F34)),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    if (query.isEmpty) {
      return Container(color: context.colors.deepBasalt);
    }

    final queryLower = normalizeSearchString(query);

    final fuseEscaladas = Fuzzy<Escalada>(
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
    
    final fuseSetores = Fuzzy<Setor>(
      allSetores,
      options: FuzzyOptions(
        keys: [
          WeightedKey<Setor>(
            name: 'nome',
            getter: (s) => normalizeSearchString(s.nome),
            weight: 1.0,
          ),
        ],
        threshold: 0.4,
      ),
    );

    final resultsEscaladas = fuseEscaladas.search(queryLower).map((r) => r.item).toList();
    final resultsSetores = fuseSetores.search(queryLower).map((r) => r.item).toList();
    final results = [...resultsSetores, ...resultsEscaladas];

    if (results.isEmpty) {
      return Container(
        color: context.colors.deepBasalt,
        alignment: Alignment.center,
        child: Text(
          'Nenhum resultado encontrado.',
          style: TextStyle(color: context.colors.ashGrey, fontSize: 16),
        ),
      );
    }

    return Container(
      color: context.colors.deepBasalt,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final item = results[index];
          
          String title = '';
          String? subtitle;
          IconData icon = Icons.terrain;
          
          if (item is Escalada) {
            title = getEscaladaNome(item);
            final grau = getGrauString(item);
            subtitle = grau.isNotEmpty ? 'Dificuldade: $grau' : null;
            icon = Icons.terrain;
          } else if (item is Setor) {
            title = item.nome;
            subtitle = 'Setor';
            icon = Icons.layers;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: context.colors.caveShadow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: context.colors.graniteEdge),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
              title: Text(title, style: TextStyle(color: context.colors.chalkWhite, fontWeight: FontWeight.bold)),
              subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: context.colors.ashGrey, fontSize: 12)) : null,
              leading: Icon(icon, color: const Color(0xFFC04F34)),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFFC04F34)),
              onTap: () {
                close(context, item);
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
              treeNav.navigateTo(TextNode(
                title: botao.texto,
                content: md.conteudo,
                cragId: cragId,
                parent: treeNav.currentNode,
              ));
            }
          }
        },
      ),
    ),
  );
}
