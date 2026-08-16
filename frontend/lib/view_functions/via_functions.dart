import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

import '../aresta_api/proto/generated/croqui.pb.dart';
import 'common_functions.dart';
import 'offline_markdown.dart';
import '../widgets/mapa_thumbnail.dart';
import '../navigation/navigation_functions.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../utils/croqui_map_index.dart';
import '../utils/dataset_resolver.dart';
import '../navigation/navigation_tree.dart';

/// Retorna o nome da escalada com base em seu tipo.
String getEscaladaNome(Escalada escalada) {
  switch (escalada.whichTipo()) {
    case Escalada_Tipo.viaEsportiva:
      return escalada.viaEsportiva.nome;
    case Escalada_Tipo.viaMovel:
      return escalada.viaMovel.nome;
    case Escalada_Tipo.boulder:
      return escalada.boulder.nome;
    case Escalada_Tipo.viaMultiplasEnfiadas:
      return escalada.viaMultiplasEnfiadas.nome;
    case Escalada_Tipo.highline:
      return escalada.highline.nome;
    case Escalada_Tipo.notSet:
      return 'Sem Nome';
  }
}

/// Retorna a string formatada do grau/dificuldade da escalada.
String getGrauString(Escalada escalada) {
  switch (escalada.whichTipo()) {
    case Escalada_Tipo.viaEsportiva:
      return formatGradeString(escalada.viaEsportiva.dificuldade.name);
    case Escalada_Tipo.viaMovel:
      return formatGradeString(escalada.viaMovel.dificuldade.name);
    case Escalada_Tipo.boulder:
      return formatGradeString(escalada.boulder.dificuldade.name);
    case Escalada_Tipo.viaMultiplasEnfiadas:
      return formatGradeString(
          escalada.viaMultiplasEnfiadas.dificuldadeMaxima.name);
    default:
      return '';
  }
}

/// Formata uma string de dificuldade (ex: BR_4, BR_4_sup) adicionando 'º'.
String formatGradeString(String name) {
  String g = name
      .replaceAll('BR_', '')
      .replaceAll('_BARRA_', '/')
      .replaceAll('_', ' ')
      .toLowerCase();

  return g.replaceAllMapped(RegExp(r'\b([1-9])\s?(sup)?\b'), (match) {
    String num = match.group(1) ?? '';
    String sup = match.group(2) != null ? 'sup' : '';
    return '$numº$sup';
  });
}

int getGradeSortWeight(String gradeName) {
  if (gradeName.contains('INDEFINIDO')) return 0;
  if (gradeName.contains('PROJETO')) return 1;

  String g = gradeName.replaceAll('BR_', '').replaceAll('V', '');

  List<String> parts = g.split('_BARRA_');
  String first = parts[0];

  if (first == 'B') {
    return 10 + (parts.length > 1 ? 2 : 0);
  }

  int num = int.tryParse(first.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  int letterWeight = 0;
  if (first.endsWith('A')) {
    letterWeight = 10;
  } else if (first.endsWith('B')) {
    letterWeight = 20;
  } else if (first.endsWith('C')) {
    letterWeight = 30;
  } else if (first.endsWith('SUP')) {
    letterWeight = 5;
  }

  int barraWeight = parts.length > 1 ? 2 : 0;

  return (num + 1) * 100 + letterWeight + barraWeight;
}

/// Retorna um valor numérico representando a dificuldade para fins de ordenação.
int getGrauValue(Escalada escalada) {
  switch (escalada.whichTipo()) {
    case Escalada_Tipo.viaEsportiva:
      return getGradeSortWeight(escalada.viaEsportiva.dificuldade.name);
    case Escalada_Tipo.viaMovel:
      return getGradeSortWeight(escalada.viaMovel.dificuldade.name);
    case Escalada_Tipo.boulder:
      return getGradeSortWeight(escalada.boulder.dificuldade.name);
    case Escalada_Tipo.viaMultiplasEnfiadas:
      return getGradeSortWeight(
          escalada.viaMultiplasEnfiadas.dificuldadeMaxima.name);
    default:
      return 0;
  }
}

/// Retorna a quantidade de proteções (fixas + móveis) para fins de ordenação.
int getProtecoesValue(Escalada escalada) {
  switch (escalada.whichTipo()) {
    case Escalada_Tipo.viaEsportiva:
      return escalada.viaEsportiva.quantidadeProtecoesIntermediarias +
          escalada.viaEsportiva.quantidadeProtecoesParada;
    case Escalada_Tipo.viaMovel:
      return escalada.viaMovel.quantidadeProtecoesIntermediarias +
          escalada.viaMovel.quantidadeProtecoesParada;
    case Escalada_Tipo.viaMultiplasEnfiadas:
      // Multi-pitch might not have simple protections count at the top level
      return 0;
    default:
      return 0;
  }
}

/// Constrói o corpo rolável principal da página da Via.
Widget buildViaBody(
  BuildContext context,
  Escalada escalada,
  String cragId, {
  Pico? pico,
  Setor? setor,
  Grupo? grupo,
  bool fromSetorPage = false,
  bool fromMapaPage = false,
}) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContentForEscalada(
          context,
          escalada,
          cragId,
          pico: pico,
          setor: setor,
          grupo: grupo,
          fromSetorPage: fromSetorPage,
          fromMapaPage: fromMapaPage,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => AppNav.home(context),
            icon: const Icon(Icons.home, color: Colors.white),
            label: const Text(
              'Voltar para o Início',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildContentForEscalada(
  BuildContext context,
  Escalada escalada,
  String cragId, {
  Pico? pico,
  Setor? setor,
  Grupo? grupo,
  bool fromSetorPage = false,
  bool fromMapaPage = false,
}) {
  switch (escalada.whichTipo()) {
    case Escalada_Tipo.viaEsportiva:
      return _buildViaEsportiva(
        context,
        escalada,
        escalada.viaEsportiva,
        cragId,
        pico,
        setor,
        grupo,
        fromSetorPage,
        fromMapaPage,
      );
    case Escalada_Tipo.viaMovel:
      return _buildViaMovel(
        context,
        escalada,
        escalada.viaMovel,
        cragId,
        pico,
        setor,
        grupo,
        fromSetorPage,
        fromMapaPage,
      );
    case Escalada_Tipo.boulder:
      return _buildBoulder(
        context,
        escalada,
        escalada.boulder,
        cragId,
        pico,
        setor,
        grupo,
        fromSetorPage,
        fromMapaPage,
      );
    case Escalada_Tipo.viaMultiplasEnfiadas:
      return _buildMultipitch(
        context,
        escalada,
        escalada.viaMultiplasEnfiadas,
        cragId,
        pico,
        setor,
        grupo,
        fromSetorPage,
        fromMapaPage,
      );
    case Escalada_Tipo.highline:
      return _buildHighline(
        context,
        escalada,
        escalada.highline,
        cragId,
        pico,
        setor,
        grupo,
        fromSetorPage,
        fromMapaPage,
      );
    default:
      return Text(
        'Detalhes não disponíveis.',
        style: TextStyle(color: fishBone),
      );
  }
}

String _fmtEnum(dynamic e) {
  if (e == null) return '';
  String text = e.name
      .toString()
      .replaceAll(
        RegExp(
          r'^(BR_|GRAU_EXPOSICAO_|TIPO_PAREDE_|GRAU_DURACAO_|TIPO_VIA_MULTIPLAS_ENFIADAS_|GRAU_BOULDER_|GRAU_ARTIFICIAL_)',
        ),
        '',
      )
      .replaceAll('_', ' ')
      .toLowerCase();

  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

Widget _buildViaEsportiva(
  BuildContext context,
  Escalada escalada,
  ViaEsportiva via,
  String cragId,
  Pico? pico,
  Setor? setor,
  Grupo? grupo,
  bool fromSetorPage,
  bool fromMapaPage,
) {
  List<Widget> statCards = [];
  if (via.hasDificuldade()) {
    statCards.add(
      _buildStatCard(
        context,
        'Dificuldade',
        _fmtEnum(via.dificuldade),
        Icons.trending_up,
      ),
    );
  }
  if (via.hasExtensao() && via.extensao > 0) {
    statCards.add(
      _buildStatCard(context, 'Extensão', '${via.extensao}m', Icons.height),
    );
  }
  if (via.hasTipoParede()) {
    statCards.add(
      _buildStatCard(
        context,
        'Parede',
        _fmtEnum(via.tipoParede),
        Icons.terrain,
      ),
    );
  }
  if (via.hasQuantidadeProtecoesIntermediarias() &&
      via.quantidadeProtecoesIntermediarias > 0) {
    statCards.add(
      _buildStatCard(
        context,
        'Proteções',
        via.quantidadeProtecoesIntermediarias.toString(),
        Icons.shield_outlined,
      ),
    );
  }
  if (via.hasExposicao()) {
    statCards.add(
      _buildStatCard(
        context,
        'Exposição',
        _fmtEnum(via.exposicao),
        Icons.warning_amber_rounded,
      ),
    );
  }
  if (via.hasQuantidadeProtecoesParada() && via.quantidadeProtecoesParada > 0) {
    statCards.add(
      _buildStatCard(
        context,
        'Paradas',
        via.quantidadeProtecoesParada.toString(),
        Icons.anchor,
      ),
    );
  }
  if (via.hasDificuldadeArtificial()) {
    statCards.add(
      _buildStatCard(
        context,
        'Artificial',
        _fmtEnum(via.dificuldadeArtificial),
        Icons.architecture,
      ),
    );
  }

  List<Widget> historyRows = [];
  if (via.conquistadores.isNotEmpty) {
    historyRows.add(
      _buildHistoryRow('Conquistadores', via.conquistadores.join(', ')),
    );
  }
  if (via.hasDataAbertura() && via.dataAbertura.isNotEmpty) {
    historyRows.add(_buildHistoryRow('Abertura', via.dataAbertura));
  }
  if (via.hasDataManutencao() && via.dataManutencao.isNotEmpty) {
    historyRows.add(_buildHistoryRow('Manutenção', via.dataManutencao));
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildTopBadges(
        context,
        escalada,
        cragId,
        pico,
        setor,
        grupo,
        fromSetorPage,
        fromMapaPage,
        via.destaque,
      ),
      _buildInteractiveMapButton(
        context,
        escalada,
        cragId,
        pico,
        setor,
        grupo,
        fromMapaPage,
      ),

      if (statCards.isNotEmpty)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: statCards
              .map(
                (card) => SizedBox(
                  width: (MediaQuery.of(context).size.width - 40 - 12) / 2,
                  child: card,
                ),
              )
              .toList(),
        ),

      if (via.hasQuantidadeProtecoesParada() ||
          (via.hasTipoAncoragem() && via.tipoAncoragem.isNotEmpty)) ...[
        const SizedBox(height: 10),
        _buildHeader('Informações'),
        if (via.hasTipoAncoragem() && via.tipoAncoragem.isNotEmpty)
          _buildInfoRow('Tipo de Ancoragem', via.tipoAncoragem),
      ],

      if (historyRows.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.colors.ashGrey.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.menu_book,
                    color: context.colors.slateStone,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'HISTÓRICO & CONQUISTA',
                    style: TextStyle(
                      color: context.colors.slateStone,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...historyRows,
            ],
          ),
        ),
      ],

      const SizedBox(height: 20),
      if (via.hasChavePixManutencao() && via.chavePixManutencao.isNotEmpty)
        _buildActionButton(
          'Apoie a Manutenção (Pix: ${via.chavePixManutencao})',
          Icons.volunteer_activism,
          () {},
          color: Colors.green,
        ),
      if (via.hasUrlVideoBeta() && via.urlVideoBeta.isNotEmpty)
        _buildActionButton(
          'Assistir Vídeo Beta',
          Icons.play_circle_fill,
          () {},
          color: Colors.blueAccent,
        ),

      if (via.hasDescricao() && via.descricao.isNotEmpty) ...[
        _buildHeader('Descrição'),
        OfflineMarkdown(data: via.descricao, cragId: cragId),
      ],
    ],
  );
}

Widget _buildViaMovel(
  BuildContext context,
  Escalada escalada,
  ViaMovel via,
  String cragId,
  Pico? pico,
  Setor? setor,
  Grupo? grupo,
  bool fromSetorPage,
  bool fromMapaPage,
) {
  List<Widget> statCards = [];
  if (via.hasDificuldade()) {
    statCards.add(
      _buildStatCard(
        context,
        'Dificuldade',
        _fmtEnum(via.dificuldade),
        Icons.trending_up,
      ),
    );
  }
  if (via.hasExtensao() && via.extensao > 0) {
    statCards.add(
      _buildStatCard(context, 'Extensão', '${via.extensao}m', Icons.height),
    );
  }
  if (via.hasTipoParede()) {
    statCards.add(
      _buildStatCard(
        context,
        'Parede',
        _fmtEnum(via.tipoParede),
        Icons.terrain,
      ),
    );
  }
  if (via.hasQuantidadeProtecoesIntermediarias() &&
      via.quantidadeProtecoesIntermediarias > 0) {
    statCards.add(
      _buildStatCard(
        context,
        'Proteções Fixas',
        via.quantidadeProtecoesIntermediarias.toString(),
        Icons.shield_outlined,
      ),
    );
  }
  if (via.hasExposicao()) {
    statCards.add(
      _buildStatCard(
        context,
        'Exposição',
        _fmtEnum(via.exposicao),
        Icons.warning_amber_rounded,
      ),
    );
  }
  if (via.hasQuantidadeProtecoesParada() && via.quantidadeProtecoesParada > 0) {
    statCards.add(
      _buildStatCard(
        context,
        'Paradas',
        via.quantidadeProtecoesParada.toString(),
        Icons.anchor,
      ),
    );
  }
  if (via.hasDificuldadeArtificial()) {
    statCards.add(
      _buildStatCard(
        context,
        'Artificial',
        _fmtEnum(via.dificuldadeArtificial),
        Icons.architecture,
      ),
    );
  }
  if (via.hasDificuldadeArtificialEmLivre()) {
    statCards.add(
      _buildStatCard(
        context,
        'Art. em Livre',
        _fmtEnum(via.dificuldadeArtificialEmLivre),
        Icons.back_hand,
      ),
    );
  }

  List<Widget> historyRows = [];
  if (via.conquistadores.isNotEmpty) {
    historyRows.add(
      _buildHistoryRow('Conquistadores', via.conquistadores.join(', ')),
    );
  }
  if (via.hasDataAbertura() && via.dataAbertura.isNotEmpty) {
    historyRows.add(_buildHistoryRow('Abertura', via.dataAbertura));
  }
  if (via.hasDataManutencao() && via.dataManutencao.isNotEmpty) {
    historyRows.add(_buildHistoryRow('Manutenção', via.dataManutencao));
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildTopBadges(
        context,
        escalada,
        cragId,
        pico,
        setor,
        grupo,
        fromSetorPage,
        fromMapaPage,
        via.destaque,
      ),
      _buildInteractiveMapButton(
        context,
        escalada,
        cragId,
        pico,
        setor,
        grupo,
        fromMapaPage,
      ),

      if (statCards.isNotEmpty)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: statCards
              .map(
                (card) => SizedBox(
                  width: (MediaQuery.of(context).size.width - 40 - 12) / 2,
                  child: card,
                ),
              )
              .toList(),
        ),

      if (via.hasProtecoesMoveis() && via.protecoesMoveis.isNotEmpty) ...[
        const SizedBox(height: 10),
        _buildHeader('Peças Móveis'),
        Text(
          via.protecoesMoveis,
          style: TextStyle(color: fishBone, fontSize: 15),
        ),
      ],

      if (via.hasQuantidadeProtecoesParada() ||
          (via.hasTipoAncoragem() && via.tipoAncoragem.isNotEmpty)) ...[
        const SizedBox(height: 10),
        _buildHeader('Parada & Ancoragem'),
        if (via.hasTipoAncoragem() && via.tipoAncoragem.isNotEmpty)
          _buildInfoRow('Tipo de Ancoragem', via.tipoAncoragem),
      ],

      if (historyRows.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.colors.ashGrey.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.menu_book,
                    color: context.colors.slateStone,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'HISTÓRICO & CONQUISTA',
                    style: TextStyle(
                      color: context.colors.slateStone,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...historyRows,
            ],
          ),
        ),
      ],

      const SizedBox(height: 20),
      if (via.hasChavePixManutencao() && via.chavePixManutencao.isNotEmpty)
        _buildActionButton(
          'Apoie a Manutenção (Pix: ${via.chavePixManutencao})',
          Icons.volunteer_activism,
          () {},
          color: Colors.green,
        ),
      if (via.hasUrlVideoBeta() && via.urlVideoBeta.isNotEmpty)
        _buildActionButton(
          'Assistir Vídeo Beta',
          Icons.play_circle_fill,
          () {},
          color: Colors.blueAccent,
        ),

      if (via.hasDescricao() && via.descricao.isNotEmpty) ...[
        _buildHeader('Descrição'),
        OfflineMarkdown(data: via.descricao, cragId: cragId),
      ],
    ],
  );
}

Widget _buildBoulder(
  BuildContext context,
  Escalada escalada,
  Boulder via,
  String cragId,
  Pico? pico,
  Setor? setor,
  Grupo? grupo,
  bool fromSetorPage,
  bool fromMapaPage,
) {
  List<Widget> statCards = [];
  if (via.hasDificuldade()) {
    statCards.add(
      _buildStatCard(
        context,
        'Dificuldade',
        _fmtEnum(via.dificuldade),
        Icons.trending_up,
      ),
    );
  }
  if (via.hasTipoParede()) {
    statCards.add(
      _buildStatCard(
        context,
        'Parede',
        _fmtEnum(via.tipoParede),
        Icons.terrain,
      ),
    );
  }

  List<Widget> historyRows = [];
  if (via.conquistadores.isNotEmpty) {
    historyRows.add(
      _buildHistoryRow('Conquistadores', via.conquistadores.join(', ')),
    );
  }
  if (via.hasDataAbertura() && via.dataAbertura.isNotEmpty) {
    historyRows.add(_buildHistoryRow('Abertura', via.dataAbertura));
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildTopBadges(
        context,
        escalada,
        cragId,
        pico,
        setor,
        grupo,
        fromSetorPage,
        fromMapaPage,
        via.destaque,
      ),
      _buildInteractiveMapButton(
        context,
        escalada,
        cragId,
        pico,
        setor,
        grupo,
        fromMapaPage,
      ),

      if (statCards.isNotEmpty)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: statCards
              .map(
                (card) => SizedBox(
                  width: (MediaQuery.of(context).size.width - 40 - 12) / 2,
                  child: card,
                ),
              )
              .toList(),
        ),

      if (historyRows.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.colors.ashGrey.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.menu_book,
                    color: context.colors.slateStone,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'HISTÓRICO & CONQUISTA',
                    style: TextStyle(
                      color: context.colors.slateStone,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...historyRows,
            ],
          ),
        ),
      ],

      const SizedBox(height: 20),
      if (via.hasChavePixManutencao() && via.chavePixManutencao.isNotEmpty)
        _buildActionButton(
          'Apoie a Manutenção (Pix: ${via.chavePixManutencao})',
          Icons.volunteer_activism,
          () {},
          color: Colors.green,
        ),
      if (via.hasUrlVideoBeta() && via.urlVideoBeta.isNotEmpty)
        _buildActionButton(
          'Assistir Vídeo Beta',
          Icons.play_circle_fill,
          () {},
          color: Colors.blueAccent,
        ),

      if (via.hasDescricao() && via.descricao.isNotEmpty) ...[
        _buildHeader('Descrição'),
        OfflineMarkdown(data: via.descricao, cragId: cragId),
      ],
    ],
  );
}

Widget _buildMultipitch(
  BuildContext context,
  Escalada escalada,
  ViaMultiplasEnfiadas via,
  String cragId,
  Pico? pico,
  Setor? setor,
  Grupo? grupo,
  bool fromSetorPage,
  bool fromMapaPage,
) {
  List<Widget> statCards = [];
  if (via.hasDificuldadeMaxima()) {
    statCards.add(
      _buildStatCard(
        context,
        'Dificuldade Máx',
        _fmtEnum(via.dificuldadeMaxima),
        Icons.trending_up,
      ),
    );
  }
  if (via.hasDificuldadeMedia()) {
    statCards.add(
      _buildStatCard(
        context,
        'Dificuldade Média',
        _fmtEnum(via.dificuldadeMedia),
        Icons.trending_flat,
      ),
    );
  }
  if (via.hasDificuldadeArtificial()) {
    statCards.add(
      _buildStatCard(
        context,
        'Artificial',
        _fmtEnum(via.dificuldadeArtificial),
        Icons.architecture,
      ),
    );
  }
  if (via.hasDificuldadeArtificialEmLivre()) {
    statCards.add(
      _buildStatCard(
        context,
        'Art. em Livre',
        _fmtEnum(via.dificuldadeArtificialEmLivre),
        Icons.back_hand,
      ),
    );
  }
  if (via.hasExposicao()) {
    statCards.add(
      _buildStatCard(
        context,
        'Exposição',
        _fmtEnum(via.exposicao),
        Icons.warning_amber_rounded,
      ),
    );
  }
  if (via.hasDuracao()) {
    statCards.add(
      _buildStatCard(context, 'Duração', _fmtEnum(via.duracao), Icons.timer),
    );
  }
  if (via.hasNumeroEnfiadas() && via.numeroEnfiadas > 0) {
    statCards.add(
      _buildStatCard(
        context,
        'Enfiadas',
        via.numeroEnfiadas.toString(),
        Icons.format_list_numbered,
      ),
    );
  }
  if (via.hasQuantidadeEquipamentosParada() &&
      via.quantidadeEquipamentosParada > 0) {
    statCards.add(
      _buildStatCard(
        context,
        'Paradas',
        via.quantidadeEquipamentosParada.toString(),
        Icons.anchor,
      ),
    );
  }
  if (via.hasComprimentoTotal() && via.comprimentoTotal > 0) {
    statCards.add(
      _buildStatCard(
        context,
        'Comprimento',
        '${via.comprimentoTotal}m',
        Icons.height,
      ),
    );
  }
  if (via.hasComprimentoMaiorEnfiada() && via.comprimentoMaiorEnfiada > 0) {
    statCards.add(
      _buildStatCard(
        context,
        'Maior Enfiada',
        '${via.comprimentoMaiorEnfiada}m',
        Icons.straighten,
      ),
    );
  }
  if (via.hasTipoViaMultiplasEnfiadas()) {
    statCards.add(
      _buildStatCard(
        context,
        'Tipo',
        _fmtEnum(via.tipoViaMultiplasEnfiadas),
        Icons.merge_type,
      ),
    );
  }

  List<Widget> historyRows = [];
  if (via.conquistadores.isNotEmpty) {
    historyRows.add(
      _buildHistoryRow('Conquistadores', via.conquistadores.join(', ')),
    );
  }
  if (via.hasDataAbertura() && via.dataAbertura.isNotEmpty) {
    historyRows.add(_buildHistoryRow('Abertura', via.dataAbertura));
  }
  if (via.hasDataManutencao() && via.dataManutencao.isNotEmpty) {
    historyRows.add(_buildHistoryRow('Manutenção', via.dataManutencao));
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildTopBadges(
        context,
        escalada,
        cragId,
        pico,
        setor,
        grupo,
        fromSetorPage,
        fromMapaPage,
        via.destaque,
      ),
      if (via.mapas.isNotEmpty) ...[
        _buildHeader('Mapas'),
        _buildMapas(via.mapas, cragId, via.enfiadas, setor),
      ],
      _buildHeader('Informações da Multipitch'),
      if (statCards.isNotEmpty)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: statCards
              .map(
                (card) => SizedBox(
                  width: (MediaQuery.of(context).size.width - 40 - 12) / 2,
                  child: card,
                ),
              )
              .toList(),
        ),

      if (via.hasEquipamentoRecomendado() &&
          via.equipamentoRecomendado.isNotEmpty) ...[
        const SizedBox(height: 10),
        _buildHeader('Rack & Equipamento'),
        Text(
          via.equipamentoRecomendado,
          style: TextStyle(color: fishBone, fontSize: 15),
        ),
      ],

      if ((via.hasQuantidadeCosturasIntermediarias() &&
              via.quantidadeCosturasIntermediarias > 0) ||
          (via.hasQuantidadeEquipamentosParada() &&
              via.quantidadeEquipamentosParada > 0)) ...[
        const SizedBox(height: 10),
        _buildHeader('Quantidade Média p/ Enfiada'),
        if (via.hasQuantidadeCosturasIntermediarias() &&
            via.quantidadeCosturasIntermediarias > 0)
          _buildInfoRow(
            'Costuras Intermediárias',
            via.quantidadeCosturasIntermediarias.toString(),
          ),
      ],

      if (historyRows.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.colors.ashGrey.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.menu_book,
                    color: context.colors.slateStone,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'HISTÓRICO & CONQUISTA',
                    style: TextStyle(
                      color: context.colors.slateStone,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...historyRows,
            ],
          ),
        ),
      ],

      const SizedBox(height: 20),
      if (via.hasChavePixManutencao() && via.chavePixManutencao.isNotEmpty)
        _buildActionButton(
          'Apoie a Manutenção (Pix: ${via.chavePixManutencao})',
          Icons.volunteer_activism,
          () {},
          color: Colors.green,
        ),
      if (via.hasUrlVideoBeta() && via.urlVideoBeta.isNotEmpty)
        _buildActionButton(
          'Assistir Vídeo Beta',
          Icons.play_circle_fill,
          () {},
          color: Colors.blueAccent,
        ),

      if (via.hasDescricao() && via.descricao.isNotEmpty) ...[
        _buildHeader('Descrição'),
        OfflineMarkdown(data: via.descricao, cragId: cragId),
      ],
      if (via.enfiadas.isNotEmpty) ...[
        _buildHeader('Enfiadas'),
        ...via.enfiadas.asMap().entries.map((entry) {
          int index = entry.key;
          Escalada enf = entry.value;
          return Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: beastHide.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
              ),
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enfiada ${index + 1}',
                    style: TextStyle(
                      color: beastHide,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildContentForEscalada(
                    context,
                    enf,
                    cragId,
                    pico: pico,
                    setor: setor,
                    grupo: grupo,
                    fromSetorPage: fromSetorPage,
                    fromMapaPage: fromMapaPage,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    ],
  );
}

Widget _buildHighline(
  BuildContext context,
  Escalada escalada,
  Highline via,
  String cragId,
  Pico? pico,
  Setor? setor,
  Grupo? grupo,
  bool fromSetorPage,
  bool fromMapaPage,
) {
  List<Widget> statCards = [];
  if (via.hasDistancia() && via.distancia > 0) {
    statCards.add(
      _buildStatCard(
        context,
        'Distância',
        '${via.distancia}m',
        Icons.straighten,
      ),
    );
  }
  if (via.hasAltura() && via.altura > 0) {
    statCards.add(
      _buildStatCard(context, 'Altura', '${via.altura}m', Icons.height),
    );
  }
  if (via.hasExposicao() && via.exposicao > 0) {
    statCards.add(
      _buildStatCard(
        context,
        'Exposição',
        via.exposicao.toString(),
        Icons.warning_amber_rounded,
      ),
    );
  }

  List<Widget> historyRows = [];
  if (via.conquistadores.isNotEmpty) {
    historyRows.add(
      _buildHistoryRow('Conquistadores', via.conquistadores.join(', ')),
    );
  }
  if (via.hasDataAbertura() && via.dataAbertura.isNotEmpty) {
    historyRows.add(_buildHistoryRow('Abertura', via.dataAbertura));
  }
  if (via.hasDataManutencao() && via.dataManutencao.isNotEmpty) {
    historyRows.add(_buildHistoryRow('Manutenção', via.dataManutencao));
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildTopBadges(
        context,
        escalada,
        cragId,
        pico,
        setor,
        grupo,
        fromSetorPage,
        fromMapaPage,
        via.destaque,
      ),

      if (statCards.isNotEmpty)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: statCards
              .map(
                (card) => SizedBox(
                  width: (MediaQuery.of(context).size.width - 40 - 12) / 2,
                  child: card,
                ),
              )
              .toList(),
        ),

      if (historyRows.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.colors.ashGrey.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.menu_book,
                    color: context.colors.slateStone,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'HISTÓRICO & CONQUISTA',
                    style: TextStyle(
                      color: context.colors.slateStone,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...historyRows,
            ],
          ),
        ),
      ],

      const SizedBox(height: 20),
      if (via.hasChavePixManutencao() && via.chavePixManutencao.isNotEmpty)
        _buildActionButton(
          'Apoie a Manutenção (Pix: ${via.chavePixManutencao})',
          Icons.volunteer_activism,
          () {},
          color: Colors.green,
        ),
      if (via.hasUrlVideoBeta() && via.urlVideoBeta.isNotEmpty)
        _buildActionButton(
          'Assistir Vídeo Beta',
          Icons.play_circle_fill,
          () {},
          color: Colors.blueAccent,
        ),

      if (via.hasDescricaoAcesso() && via.descricaoAcesso.isNotEmpty) ...[
        _buildHeader('Descrição do Acesso'),
        OfflineMarkdown(data: via.descricaoAcesso, cragId: cragId),
      ],
      if (via.hasDescricaoAncoragem() && via.descricaoAncoragem.isNotEmpty) ...[
        _buildHeader('Descrição da Ancoragem'),
        OfflineMarkdown(data: via.descricaoAncoragem, cragId: cragId),
      ],
      if (via.hasDescricao() && via.descricao.isNotEmpty) ...[
        _buildHeader('Descrição'),
        OfflineMarkdown(data: via.descricao, cragId: cragId),
      ],
    ],
  );
}

Widget _buildHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: beastHide,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 2,
          width: 40,
          color: beastHide.withValues(alpha: 0.5),
        ),
      ],
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

Widget _buildInteractiveMapButton(
  BuildContext context,
  Escalada escalada,
  String cragId,
  Pico? pico,
  Setor? setor,
  Grupo? grupo,
  bool fromMapaPage,
) {
  List<IndexedMap> foundMaps = [];
  if (pico != null) {
    final index = CroquiMapIndex(pico);
    final resolved = ResolvedDataset(
      grupo: grupo,
      setor: setor,
      escalada: escalada,
    );
    foundMaps = index.getMapasForReference(resolved);
  }

  if (foundMaps.isEmpty) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: InkWell(
      onTap: () {
        TelemetryService.instance.logAcaoEscalada(
          cragId,
          setor?.nome ?? '',
          getEscaladaNome(escalada),
          'ver_no_mapa_destaque',
          'detalhes_via',
        );
        if (fromMapaPage) {
          AppNav.back(context);
        } else {
          final mapasData = foundMaps
              .map(
                (fm) => CarrosselItemData(
                  mapaCaminhoImagem: fm.mapa!.caminhoImagemMapa,
                  setorContextNome: fm.setorContext?.nome,
                  grupoContextNome: fm.grupoContext?.nome,
                  escaladaContextNome: getEscaladaNome(escalada),
                  initialSelectedId: fm.referencedId,
                ),
              )
              .toList();
          AppNav.toMapas(context, cragId: cragId, mapas: mapasData);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.brandColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.explore_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text(
              'VER NO CROQUI INTERATIVO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildTopBadges(
  BuildContext context,
  Escalada escalada,
  String cragId,
  Pico? pico,
  Setor? setor,
  Grupo? grupo,
  bool fromSetorPage,
  bool fromMapaPage,
  bool isDestaque,
) {
  List<Widget> badges = [];

  if (setor != null && setor.nome.isNotEmpty) {
    badges.add(
      GestureDetector(
        onTap: () {
          TelemetryService.instance.logAcaoEscalada(
            cragId,
            setor.nome,
            getEscaladaNome(escalada),
            'abrir_setor',
            'detalhes_via',
          );
          AppNav.toSetor(
            context,
            setor: setor,
            grupoContext: grupo,
            scrollToEscalada: escalada,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: context.colors.mossRock.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: context.colors.mossRock.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, size: 14, color: context.colors.mossRock),
              const SizedBox(width: 6),
              Text(
                setor.nome.toUpperCase(),
                style: TextStyle(
                  color: fishBone,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  if (isDestaque) {
    badges.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 14, color: Colors.amber),
            const SizedBox(width: 6),
            const Text(
              'CLÁSSICA',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  if (badges.isEmpty) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.only(bottom: 20, top: 10),
    child: Wrap(spacing: 8, runSpacing: 8, children: badges),
  );
}

Widget _buildMapas(
  List<Mapa> mapas,
  String cragId,
  List<Escalada> escaladasDaVia,
  Setor? setorContext,
) {
  if (mapas.isEmpty) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: mapas.map((mapa) {
      if (mapa.caminhoImagemMapa.isNotEmpty &&
          mapa.larguraMapa > 0 &&
          mapa.alturaMapa > 0) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: mapa.larguraMapa / mapa.alturaMapa,
              child: MapaThumbnail(
                mapa: mapa,
                cragId: cragId,

                setorContext: setorContext,
              ),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }).toList(),
  );
}

Widget _buildStatCard(
  BuildContext context,
  String label,
  String value,
  IconData icon,
) {
  return buildOutlineStatCard(context, label, value, icon);
}

Widget _buildActionButton(
  String label,
  IconData icon,
  VoidCallback onTap, {
  Color? color,
}) {
  color ??= beastHide;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildHistoryRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: slateStone,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: fishBone, fontSize: 14)),
      ],
    ),
  );
}
