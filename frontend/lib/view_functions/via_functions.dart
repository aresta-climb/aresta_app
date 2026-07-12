import 'package:flutter/material.dart';
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
      return escalada.viaEsportiva.dificuldade.name.replaceAll('BR_', '').replaceAll('_', ' ');
    case Escalada_Tipo.viaMovel:
      return escalada.viaMovel.dificuldade.name.replaceAll('BR_', '').replaceAll('_', ' ');
    case Escalada_Tipo.boulder:
      return escalada.boulder.dificuldade.name.replaceAll('BR_', '');
    case Escalada_Tipo.viaMultiplasEnfiadas:
      return escalada.viaMultiplasEnfiadas.dificuldadeMaxima.name.replaceAll('BR_', '').replaceAll('_', ' ');
    default:
      return '';
  }
}

/// Retorna um valor numérico representando a dificuldade para fins de ordenação.
int getGrauValue(Escalada escalada) {
  switch (escalada.whichTipo()) {
    case Escalada_Tipo.viaEsportiva:
      return escalada.viaEsportiva.dificuldade.value;
    case Escalada_Tipo.viaMovel:
      return escalada.viaMovel.dificuldade.value;
    case Escalada_Tipo.boulder:
      return escalada.boulder.dificuldade.value;
    case Escalada_Tipo.viaMultiplasEnfiadas:
      return escalada.viaMultiplasEnfiadas.dificuldadeMaxima.value;
    default:
      return 0;
  }
}

/// Constrói o corpo rolável principal da página da Via.
Widget buildViaBody(BuildContext context, Escalada escalada, String cragId, {Pico? pico, Setor? setor, Grupo? grupo, bool fromSetorPage = false, bool fromMapaPage = false}) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildContentForEscalada(context, escalada, cragId, pico: pico, setor: setor, grupo: grupo, fromSetorPage: fromSetorPage, fromMapaPage: fromMapaPage)],
    ),
  );
}

Widget _buildContentForEscalada(BuildContext context, Escalada escalada, String cragId, {Pico? pico, Setor? setor, Grupo? grupo, bool fromSetorPage = false, bool fromMapaPage = false}) {
  switch (escalada.whichTipo()) {
    case Escalada_Tipo.viaEsportiva:
      return _buildViaEsportiva(context, escalada, escalada.viaEsportiva, cragId, pico, setor, grupo, fromSetorPage, fromMapaPage);
    case Escalada_Tipo.viaMovel:
      return _buildViaMovel(context, escalada, escalada.viaMovel, cragId, pico, setor, grupo, fromSetorPage, fromMapaPage);
    case Escalada_Tipo.boulder:
      return _buildBoulder(context, escalada, escalada.boulder, cragId, pico, setor, grupo, fromSetorPage, fromMapaPage);
    case Escalada_Tipo.viaMultiplasEnfiadas:
      return _buildMultipitch(context, escalada, escalada.viaMultiplasEnfiadas, cragId, pico, setor, grupo, fromSetorPage, fromMapaPage);
    case Escalada_Tipo.highline:
      return _buildHighline(context, escalada, escalada.highline, cragId, pico, setor, grupo, fromSetorPage, fromMapaPage);
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

Widget _buildViaEsportiva(BuildContext context, Escalada escalada, ViaEsportiva via, String cragId, Pico? pico, Setor? setor, Grupo? grupo, bool fromSetorPage, bool fromMapaPage) {
  List<Widget> statCards = [];
  if (via.hasDificuldade()) statCards.add(_buildStatCard('Dificuldade', _fmtEnum(via.dificuldade), Icons.trending_up));
  if (via.hasExtensao() && via.extensao > 0) statCards.add(_buildStatCard('Extensão', '${via.extensao}m', Icons.height));
  if (via.hasTipoParede()) statCards.add(_buildStatCard('Parede', _fmtEnum(via.tipoParede), Icons.terrain));
  if (via.hasQuantidadeProtecoesIntermediarias() && via.quantidadeProtecoesIntermediarias > 0) statCards.add(_buildStatCard('Proteções', via.quantidadeProtecoesIntermediarias.toString(), Icons.shield_outlined));
  if (via.hasExposicao()) statCards.add(_buildStatCard('Exposição', _fmtEnum(via.exposicao), Icons.warning_amber_rounded));
  if (via.hasDificuldadeArtificial()) statCards.add(_buildStatCard('Artificial', _fmtEnum(via.dificuldadeArtificial), Icons.architecture));

  List<Widget> historyRows = [];
  if (via.conquistadores.isNotEmpty) historyRows.add(_buildHistoryRow('Conquistadores', via.conquistadores.join(', ')));
  if (via.hasDataAbertura() && via.dataAbertura.isNotEmpty) historyRows.add(_buildHistoryRow('Abertura', via.dataAbertura));
  if (via.hasDataManutencao() && via.dataManutencao.isNotEmpty) historyRows.add(_buildHistoryRow('Manutenção', via.dataManutencao));

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildTopBadges(context, escalada, cragId, pico, setor, grupo, fromSetorPage, fromMapaPage, via.destaque),
      _buildHeader('Informações da Via Esportiva'),
      if (statCards.isNotEmpty) Wrap(spacing: 10, runSpacing: 10, children: statCards),
      
      if (via.hasQuantidadeProtecoesParada() || (via.hasTipoAncoragem() && via.tipoAncoragem.isNotEmpty)) ...[
        const SizedBox(height: 10),
        _buildHeader('Parada & Ancoragem'),
        if (via.hasQuantidadeProtecoesParada() && via.quantidadeProtecoesParada > 0) _buildInfoRow('Proteções na Parada', via.quantidadeProtecoesParada.toString()),
        if (via.hasTipoAncoragem() && via.tipoAncoragem.isNotEmpty) _buildInfoRow('Tipo de Ancoragem', via.tipoAncoragem),
      ],
      
      if (historyRows.isNotEmpty) ...[
        _buildHeader('Histórico'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
          child: Column(children: historyRows),
        ),
      ],
      
      const SizedBox(height: 20),
      if (via.hasChavePixManutencao() && via.chavePixManutencao.isNotEmpty)
        _buildActionButton('Apoie a Manutenção (Pix: ${via.chavePixManutencao})', Icons.volunteer_activism, () {}, color: Colors.green),
      if (via.hasUrlVideoBeta() && via.urlVideoBeta.isNotEmpty)
        _buildActionButton('Assistir Vídeo Beta', Icons.play_circle_fill, () {}, color: Colors.blueAccent),
        
      if (via.hasDescricao() && via.descricao.isNotEmpty) ...[
        _buildHeader('Descrição'),
        OfflineMarkdown(data: via.descricao, cragId: cragId),
      ],
    ],
  );
}

Widget _buildViaMovel(BuildContext context, Escalada escalada, ViaMovel via, String cragId, Pico? pico, Setor? setor, Grupo? grupo, bool fromSetorPage, bool fromMapaPage) {
  List<Widget> statCards = [];
  if (via.hasDificuldade()) statCards.add(_buildStatCard('Dificuldade', _fmtEnum(via.dificuldade), Icons.trending_up));
  if (via.hasExtensao() && via.extensao > 0) statCards.add(_buildStatCard('Extensão', '${via.extensao}m', Icons.height));
  if (via.hasTipoParede()) statCards.add(_buildStatCard('Parede', _fmtEnum(via.tipoParede), Icons.terrain));
  if (via.hasQuantidadeProtecoesIntermediarias() && via.quantidadeProtecoesIntermediarias > 0) statCards.add(_buildStatCard('Proteções Fixas', via.quantidadeProtecoesIntermediarias.toString(), Icons.shield_outlined));
  if (via.hasExposicao()) statCards.add(_buildStatCard('Exposição', _fmtEnum(via.exposicao), Icons.warning_amber_rounded));
  if (via.hasDificuldadeArtificial()) statCards.add(_buildStatCard('Artificial', _fmtEnum(via.dificuldadeArtificial), Icons.architecture));
  if (via.hasDificuldadeArtificialEmLivre()) statCards.add(_buildStatCard('Art. em Livre', _fmtEnum(via.dificuldadeArtificialEmLivre), Icons.back_hand));

  List<Widget> historyRows = [];
  if (via.conquistadores.isNotEmpty) historyRows.add(_buildHistoryRow('Conquistadores', via.conquistadores.join(', ')));
  if (via.hasDataAbertura() && via.dataAbertura.isNotEmpty) historyRows.add(_buildHistoryRow('Abertura', via.dataAbertura));
  if (via.hasDataManutencao() && via.dataManutencao.isNotEmpty) historyRows.add(_buildHistoryRow('Manutenção', via.dataManutencao));

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildTopBadges(context, escalada, cragId, pico, setor, grupo, fromSetorPage, fromMapaPage, via.destaque),
      _buildHeader('Informações da Via Móvel'),
      if (statCards.isNotEmpty) Wrap(spacing: 10, runSpacing: 10, children: statCards),
      
      if (via.hasProtecoesMoveis() && via.protecoesMoveis.isNotEmpty) ...[
        const SizedBox(height: 10),
        _buildHeader('Peças Móveis'),
        Text(via.protecoesMoveis, style: TextStyle(color: fishBone, fontSize: 15)),
      ],

      if (via.hasQuantidadeProtecoesParada() || (via.hasTipoAncoragem() && via.tipoAncoragem.isNotEmpty)) ...[
        const SizedBox(height: 10),
        _buildHeader('Parada & Ancoragem'),
        if (via.hasQuantidadeProtecoesParada() && via.quantidadeProtecoesParada > 0) _buildInfoRow('Proteções na Parada', via.quantidadeProtecoesParada.toString()),
        if (via.hasTipoAncoragem() && via.tipoAncoragem.isNotEmpty) _buildInfoRow('Tipo de Ancoragem', via.tipoAncoragem),
      ],
      
      if (historyRows.isNotEmpty) ...[
        _buildHeader('Histórico'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
          child: Column(children: historyRows),
        ),
      ],
      
      const SizedBox(height: 20),
      if (via.hasChavePixManutencao() && via.chavePixManutencao.isNotEmpty)
        _buildActionButton('Apoie a Manutenção (Pix: ${via.chavePixManutencao})', Icons.volunteer_activism, () {}, color: Colors.green),
      if (via.hasUrlVideoBeta() && via.urlVideoBeta.isNotEmpty)
        _buildActionButton('Assistir Vídeo Beta', Icons.play_circle_fill, () {}, color: Colors.blueAccent),
        
      if (via.hasDescricao() && via.descricao.isNotEmpty) ...[
        _buildHeader('Descrição'),
        OfflineMarkdown(data: via.descricao, cragId: cragId),
      ],
    ],
  );
}

Widget _buildBoulder(BuildContext context, Escalada escalada, Boulder via, String cragId, Pico? pico, Setor? setor, Grupo? grupo, bool fromSetorPage, bool fromMapaPage) {
  List<Widget> statCards = [];
  if (via.hasDificuldade()) statCards.add(_buildStatCard('Dificuldade', _fmtEnum(via.dificuldade), Icons.trending_up));
  if (via.hasTipoParede()) statCards.add(_buildStatCard('Parede', _fmtEnum(via.tipoParede), Icons.terrain));

  List<Widget> historyRows = [];
  if (via.conquistadores.isNotEmpty) historyRows.add(_buildHistoryRow('Conquistadores', via.conquistadores.join(', ')));
  if (via.hasDataAbertura() && via.dataAbertura.isNotEmpty) historyRows.add(_buildHistoryRow('Abertura', via.dataAbertura));

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildTopBadges(context, escalada, cragId, pico, setor, grupo, fromSetorPage, fromMapaPage, via.destaque),
      _buildHeader('Informações do Boulder'),
      if (statCards.isNotEmpty) Wrap(spacing: 10, runSpacing: 10, children: statCards),
      
      if (historyRows.isNotEmpty) ...[
        _buildHeader('Histórico'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
          child: Column(children: historyRows),
        ),
      ],
      
      const SizedBox(height: 20),
      if (via.hasChavePixManutencao() && via.chavePixManutencao.isNotEmpty)
        _buildActionButton('Apoie a Manutenção (Pix: ${via.chavePixManutencao})', Icons.volunteer_activism, () {}, color: Colors.green),
      if (via.hasUrlVideoBeta() && via.urlVideoBeta.isNotEmpty)
        _buildActionButton('Assistir Vídeo Beta', Icons.play_circle_fill, () {}, color: Colors.blueAccent),
        
      if (via.hasDescricao() && via.descricao.isNotEmpty) ...[
        _buildHeader('Descrição'),
        OfflineMarkdown(data: via.descricao, cragId: cragId),
      ],
    ],
  );
}

Widget _buildMultipitch(BuildContext context, Escalada escalada, ViaMultiplasEnfiadas via, String cragId, Pico? pico, Setor? setor, Grupo? grupo, bool fromSetorPage, bool fromMapaPage) {
  List<Widget> statCards = [];
  if (via.hasDificuldadeMaxima()) statCards.add(_buildStatCard('Dificuldade Máx', _fmtEnum(via.dificuldadeMaxima), Icons.trending_up));
  if (via.hasDificuldadeMedia()) statCards.add(_buildStatCard('Dificuldade Média', _fmtEnum(via.dificuldadeMedia), Icons.trending_flat));
  if (via.hasDificuldadeArtificial()) statCards.add(_buildStatCard('Artificial', _fmtEnum(via.dificuldadeArtificial), Icons.architecture));
  if (via.hasDificuldadeArtificialEmLivre()) statCards.add(_buildStatCard('Art. em Livre', _fmtEnum(via.dificuldadeArtificialEmLivre), Icons.back_hand));
  if (via.hasExposicao()) statCards.add(_buildStatCard('Exposição', _fmtEnum(via.exposicao), Icons.warning_amber_rounded));
  if (via.hasDuracao()) statCards.add(_buildStatCard('Duração', _fmtEnum(via.duracao), Icons.timer));
  if (via.hasNumeroEnfiadas() && via.numeroEnfiadas > 0) statCards.add(_buildStatCard('Enfiadas', via.numeroEnfiadas.toString(), Icons.format_list_numbered));
  if (via.hasComprimentoTotal() && via.comprimentoTotal > 0) statCards.add(_buildStatCard('Comprimento', '${via.comprimentoTotal}m', Icons.height));
  if (via.hasComprimentoMaiorEnfiada() && via.comprimentoMaiorEnfiada > 0) statCards.add(_buildStatCard('Maior Enfiada', '${via.comprimentoMaiorEnfiada}m', Icons.straighten));
  if (via.hasTipoViaMultiplasEnfiadas()) statCards.add(_buildStatCard('Tipo', _fmtEnum(via.tipoViaMultiplasEnfiadas), Icons.merge_type));

  List<Widget> historyRows = [];
  if (via.conquistadores.isNotEmpty) historyRows.add(_buildHistoryRow('Conquistadores', via.conquistadores.join(', ')));
  if (via.hasDataAbertura() && via.dataAbertura.isNotEmpty) historyRows.add(_buildHistoryRow('Abertura', via.dataAbertura));
  if (via.hasDataManutencao() && via.dataManutencao.isNotEmpty) historyRows.add(_buildHistoryRow('Manutenção', via.dataManutencao));

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildTopBadges(context, escalada, cragId, pico, setor, grupo, fromSetorPage, fromMapaPage, via.destaque, ),
      if (via.mapas.isNotEmpty) ...[
        _buildHeader('Mapas'),
        _buildMapas(via.mapas, cragId, via.enfiadas, setor),
      ],
      _buildHeader('Informações da Multipitch'),
      if (statCards.isNotEmpty) Wrap(spacing: 10, runSpacing: 10, children: statCards),
      
      if (via.hasEquipamentoRecomendado() && via.equipamentoRecomendado.isNotEmpty) ...[
        const SizedBox(height: 10),
        _buildHeader('Rack & Equipamento'),
        Text(via.equipamentoRecomendado, style: TextStyle(color: fishBone, fontSize: 15)),
      ],

      if ((via.hasQuantidadeCosturasIntermediarias() && via.quantidadeCosturasIntermediarias > 0) || 
          (via.hasQuantidadeEquipamentosParada() && via.quantidadeEquipamentosParada > 0)) ...[
        const SizedBox(height: 10),
        _buildHeader('Quantidade Média p/ Enfiada'),
        if (via.hasQuantidadeCosturasIntermediarias() && via.quantidadeCosturasIntermediarias > 0) _buildInfoRow('Costuras Intermediárias', via.quantidadeCosturasIntermediarias.toString()),
        if (via.hasQuantidadeEquipamentosParada() && via.quantidadeEquipamentosParada > 0) _buildInfoRow('Equipamentos na Parada', via.quantidadeEquipamentosParada.toString()),
      ],

      if (historyRows.isNotEmpty) ...[
        _buildHeader('Histórico'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
          child: Column(children: historyRows),
        ),
      ],
      
      const SizedBox(height: 20),
      if (via.hasChavePixManutencao() && via.chavePixManutencao.isNotEmpty)
        _buildActionButton('Apoie a Manutenção (Pix: ${via.chavePixManutencao})', Icons.volunteer_activism, () {}, color: Colors.green),
      if (via.hasUrlVideoBeta() && via.urlVideoBeta.isNotEmpty)
        _buildActionButton('Assistir Vídeo Beta', Icons.play_circle_fill, () {}, color: Colors.blueAccent),
        
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
                  _buildContentForEscalada(context, enf, cragId, pico: pico, setor: setor, grupo: grupo, fromSetorPage: fromSetorPage, fromMapaPage: fromMapaPage),
                ],
              ),
            ),
          );
        }),
      ],
    ],
  );
}

Widget _buildHighline(BuildContext context, Escalada escalada, Highline via, String cragId, Pico? pico, Setor? setor, Grupo? grupo, bool fromSetorPage, bool fromMapaPage) {
  List<Widget> statCards = [];
  if (via.hasDistancia() && via.distancia > 0) statCards.add(_buildStatCard('Distância', '${via.distancia}m', Icons.straighten));
  if (via.hasAltura() && via.altura > 0) statCards.add(_buildStatCard('Altura', '${via.altura}m', Icons.height));
  if (via.hasExposicao() && via.exposicao > 0) statCards.add(_buildStatCard('Exposição', via.exposicao.toString(), Icons.warning_amber_rounded));

  List<Widget> historyRows = [];
  if (via.conquistadores.isNotEmpty) historyRows.add(_buildHistoryRow('Conquistadores', via.conquistadores.join(', ')));
  if (via.hasDataAbertura() && via.dataAbertura.isNotEmpty) historyRows.add(_buildHistoryRow('Abertura', via.dataAbertura));
  if (via.hasDataManutencao() && via.dataManutencao.isNotEmpty) historyRows.add(_buildHistoryRow('Manutenção', via.dataManutencao));

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildTopBadges(context, escalada, cragId, pico, setor, grupo, fromSetorPage, fromMapaPage, via.destaque, ),
      _buildHeader('Informações do Highline'),
      if (statCards.isNotEmpty) Wrap(spacing: 10, runSpacing: 10, children: statCards),
      
      if (historyRows.isNotEmpty) ...[
        _buildHeader('Histórico'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
          child: Column(children: historyRows),
        ),
      ],
      
      const SizedBox(height: 20),
      if (via.hasChavePixManutencao() && via.chavePixManutencao.isNotEmpty)
        _buildActionButton('Apoie a Manutenção (Pix: ${via.chavePixManutencao})', Icons.volunteer_activism, () {}, color: Colors.green),
      if (via.hasUrlVideoBeta() && via.urlVideoBeta.isNotEmpty)
        _buildActionButton('Assistir Vídeo Beta', Icons.play_circle_fill, () {}, color: Colors.blueAccent),
        
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
            style: TextStyle(
              color: beastHide,
              fontWeight: FontWeight.bold,
            ),
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
          if (fromSetorPage) {
            AppNav.back(context);
          } else {
            TelemetryService.instance.logAcaoEscalada(cragId, setor.nome, getEscaladaNome(escalada), 'abrir_setor', 'detalhes_via');
            AppNav.toSetor(context, setor: setor, grupoContext: grupo);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: fishBone.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: fishBone.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, size: 14, color: fishBone),
              const SizedBox(width: 4),
              Text(
                setor.nome,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 14, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              'Destaque',
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

  // Verificar se há referência em algum mapa
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

  Widget buildMapChip(String label, Mapa targetMap, String id, Setor? mapSetorContext) {
    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: nobleBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: beastHide.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_arrow_rounded, color: beastHide, size: 14),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: fishBone, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
    
    return GestureDetector(
      onTap: () async {
        TelemetryService.instance.logAcaoEscalada(cragId, setor?.nome ?? '', getEscaladaNome(escalada), 'ver_no_mapa', 'detalhes_via');

        if (fromMapaPage) {
          AppNav.back(context);
        } else {
          AppNav.toMapas(
            context,
            cragId: cragId,
            mapas: [
              CarrosselItemData(
                mapaCaminhoImagem: targetMap.caminhoImagemMapa,
                setorContextNome: mapSetorContext?.nome,
                escaladaContextNome: getEscaladaNome(escalada),
                initialSelectedId: id.isNotEmpty ? id : null,
              )
            ],
          );
        }
      },
      child: chip,
    );
  }

  if (foundMaps.length == 1) {
    if (foundMaps.first.mapa != null) {
      badges.add(buildMapChip('Ver no mapa', foundMaps.first.mapa!, foundMaps.first.referencedId, foundMaps.first.setorContext));
    }
  } else if (foundMaps.length > 1) {
    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: nobleBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: beastHide.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.layers, color: beastHide, size: 14),
          const SizedBox(width: 4),
          Text('Ver nos mapas (${foundMaps.length})', style: TextStyle(color: fishBone, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
    
    badges.add(
      GestureDetector(
        onTap: () {
          TelemetryService.instance.logAcaoEscalada(cragId, setor?.nome ?? '', getEscaladaNome(escalada), 'ver_nos_mapas_carrossel', 'detalhes_via');
          if (fromMapaPage) {
            AppNav.back(context);
          } else {
            final mapasData = foundMaps.map((fm) => CarrosselItemData(
              mapaCaminhoImagem: fm.mapa!.caminhoImagemMapa,
              setorContextNome: fm.setorContext?.nome,
              grupoContextNome: null,
              initialSelectedId: fm.referencedId,
            )).toList();
            
            AppNav.toMapas(
              context,
              cragId: cragId,
              mapas: mapasData,
            );
          }
        },
        child: chip,
      ),
    );
  }

  if (badges.isEmpty) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: badges,
    ),
  );
}

Widget _buildMapas(List<Mapa> mapas, String cragId, List<Escalada> escaladasDaVia, Setor? setorContext) {
  if (mapas.isEmpty) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: mapas.map((mapa) {
      if (mapa.caminhoImagemMapa.isNotEmpty && mapa.larguraMapa > 0 && mapa.alturaMapa > 0) {
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

Widget _buildStatCard(String label, String value, IconData icon) {
  return Container(
    width: 155,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: beastHide.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: beastHide, size: 20),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: fishBone.withValues(alpha: 0.7), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: fishBone, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

Widget _buildActionButton(String label, IconData icon, VoidCallback onTap, {Color? color}) {
  color ??= beastHide;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildHistoryRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: TextStyle(color: beastHide.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: TextStyle(color: fishBone)),
        ),
      ],
    ),
  );
}
