// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0


export '../../utils/formatador_escalada.dart' show obterCodigoGrauOficial;
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../data/modelos/interacao_via.dart';
import '../../navigation/arvore_navegacao.dart';
import '../../navigation/construtor_reativo_pagina.dart';
import '../../navigation/funcoes_navegacao.dart';
import '../../theme/cores_app.dart';
import '../../utils/consulta_dataset.dart';
import '../../utils/formatador_escalada.dart';
import '../../widgets/caderneta/secao_caderneta_via.dart';
import '../../widgets/linha_localizacao_setor.dart';
import '../../widgets/mapa_thumbnail.dart';
import '../../widgets/via/bolha_alerta_seguranca_via.dart';
import '../../widgets/via/secoes_detalhes_via.dart';
import '../view_models/secao_caderneta_via_view_model.dart';
import '../view_models/via_view_model.dart';
import 'biblioteca_funcoes_comuns.dart';
import 'markdown_offline.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/firebase/telemetria.dart';

/// Retorna o nome da escalada com base em sua modalidade ativa.
String getEscaladaNome(Escalada escalada) => obterNomeEscalada(escalada);

/// Retorna o rótulo da modalidade da escalada (`'Esportiva'`, `'Mista'`, `'Móvel'`, `'Boulder'`, `'Multienfiada'`, `'Highline'`).
String getModalidadeEscalada(Escalada escalada) {
  switch (escalada.whichTipo()) {
    case Escalada_Tipo.viaEsportiva:
      return 'Esportiva';
    case Escalada_Tipo.viaMovel:
      if (escalada.viaMovel.quantidadeProtecoesIntermediarias > 0) {
        return 'Mista';
      }
      return 'Móvel';
    case Escalada_Tipo.boulder:
      return 'Boulder';
    case Escalada_Tipo.viaMultiplasEnfiadas:
      if (escalada.viaMultiplasEnfiadas.tipoViaMultiplasEnfiadas ==
          ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas.MISTA) {
        return 'Mista';
      }
      return 'Multienfiada';
    case Escalada_Tipo.highline:
      return 'Highline';
    case Escalada_Tipo.notSet:
      return '';
  }
}

/// Retorna a string formatada de proteções na notação `X+Y` (`<intermediárias>+<parada>`).
String getProtecoesString(Escalada escalada) {
  var intermediarias = 0;
  var parada = 0;

  switch (escalada.whichTipo()) {
    case Escalada_Tipo.viaEsportiva:
      intermediarias = escalada.viaEsportiva.quantidadeProtecoesIntermediarias;
      parada = escalada.viaEsportiva.quantidadeProtecoesParada;
    case Escalada_Tipo.viaMovel:
      intermediarias = escalada.viaMovel.quantidadeProtecoesIntermediarias;
      parada = escalada.viaMovel.quantidadeProtecoesParada;
    case Escalada_Tipo.viaMultiplasEnfiadas:
      intermediarias =
          escalada.viaMultiplasEnfiadas.quantidadeCosturasIntermediarias;
      parada = escalada.viaMultiplasEnfiadas.quantidadeEquipamentosParada;
    default:
      return '';
  }

  if (intermediarias > 0 || parada > 0) {
    return '$intermediarias+$parada';
  }
  return '';
}

/// Retorna a string formatada do grau/dificuldade da escalada.
String getGrauString(Escalada escalada) => obterTextoGrauEscalada(escalada);

/// Formata uma string de dificuldade (`BR_4`, `BR_6SUP`, `V4`) adicionando `'º'` quando aplicável.
String formatGradeString(String name) => formatarTextoGrau(name);

/// Calcula um peso inteiro monotônico para ordenação numérica de graus brasileiros e escala V.
int getGradeSortWeight(String gradeName) {
  if (gradeName.contains('INDEFINIDO')) return 9998;
  if (gradeName.contains('PROJETO')) return 9999;

  final limpo = gradeName.replaceAll('BR_', '').replaceAll('V', '');
  final partes = limpo.split('_BARRA_');
  final primeiro = partes[0];

  if (primeiro == 'B') {
    return 10 + (partes.length > 1 ? 2 : 0);
  }

  final numero =
      int.tryParse(primeiro.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  var pesoLetra = 0;
  if (primeiro.endsWith('A')) {
    pesoLetra = 10;
  } else if (primeiro.endsWith('B')) {
    pesoLetra = 20;
  } else if (primeiro.endsWith('C')) {
    pesoLetra = 30;
  } else if (primeiro.endsWith('SUP')) {
    pesoLetra = 5;
  }

  final pesoBarra = partes.length > 1 ? 2 : 0;
  return (numero + 1) * 100 + pesoLetra + pesoBarra;
}

/// Retorna um valor numérico representando a dificuldade da [escalada] para ordenação em listas.
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
        escalada.viaMultiplasEnfiadas.dificuldadeMaxima.name,
      );
    default:
      return 9998;
  }
}

/// Retorna a soma de proteções fixas intermediárias e de parada para ordenação.
int getProtecoesValue(Escalada escalada) {
  switch (escalada.whichTipo()) {
    case Escalada_Tipo.viaEsportiva:
      return escalada.viaEsportiva.quantidadeProtecoesIntermediarias +
          escalada.viaEsportiva.quantidadeProtecoesParada;
    case Escalada_Tipo.viaMovel:
      return escalada.viaMovel.quantidadeProtecoesIntermediarias +
          escalada.viaMovel.quantidadeProtecoesParada;
    default:
      return 0;
  }
}

/// Constrói o corpo rolável declarativo da página de detalhes da Via.
Widget buildViaBody(
  BuildContext context,
  Escalada escalada,
  String cragId, {
  Pico? pico,
  Setor? setor,
  Grupo? grupo,
  bool fromSetorPage = false,
  bool fromMapaPage = false,
  ViaViewModel? viewModel,
  SecaoCadernetaViaViewModel? cadernetaViewModel,
}) {
  return CorpoDetalhesVia(
    escalada: escalada,
    cragId: cragId,
    pico: pico,
    setor: setor,
    grupo: grupo,
    fromMapaPage: fromMapaPage,
    viewModel: viewModel,
    cadernetaViewModel: cadernetaViewModel,
  );
}

/// Corpo rolável reativo (Dumb UI) que compõe todas as seções modulares da `ViaPage`
/// a partir do estado exposto pelo [ViaViewModel].
class CorpoDetalhesVia extends StatefulWidget {
  /// Escalada Protobuf exibida.
  final Escalada escalada;

  /// Identificador do croqui.
  final String cragId;

  /// Pico pai opcional.
  final Pico? pico;

  /// Setor pai opcional.
  final Setor? setor;

  /// Grupo pai opcional.
  final Grupo? grupo;

  /// Indica se a navegação partiu diretamente da `MapaPage`.
  final bool fromMapaPage;

  /// ViewModel opcional injetado externamente pela `ViaPage` ou testes.
  final ViaViewModel? viewModel;

  /// ViewModel opcional da seção de caderneta pessoal.
  final SecaoCadernetaViaViewModel? cadernetaViewModel;

  /// Cria uma instância de [CorpoDetalhesVia].
  const CorpoDetalhesVia({
    super.key,
    required this.escalada,
    required this.cragId,
    this.pico,
    this.setor,
    this.grupo,
    this.fromMapaPage = false,
    this.viewModel,
    this.cadernetaViewModel,
  });

  @override
  State<CorpoDetalhesVia> createState() => _CorpoDetalhesViaState();
}

class _CorpoDetalhesViaState extends State<CorpoDetalhesVia> {
  late ViaViewModel _viewModel;
  bool _gerenciaCicloVida = false;

  @override
  void initState() {
    super.initState();
    _vincularViewModel();
  }

  @override
  void didUpdateWidget(covariant CorpoDetalhesVia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.viewModel != oldWidget.viewModel ||
        (_gerenciaCicloVida && widget.escalada != oldWidget.escalada)) {
      if (_gerenciaCicloVida) {
        _viewModel.dispose();
      }
      _vincularViewModel();
    }
  }

  void _vincularViewModel() {
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
      _gerenciaCicloVida = false;
    } else {
      _viewModel = ViaViewModel(escalada: widget.escalada);
      _gerenciaCicloVida = true;
    }
  }

  @override
  void dispose() {
    if (_gerenciaCicloVida) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  void _abrirConfirmacaoAlerta(
    BuildContext context,
    AlertaSegurancaVia alerta,
  ) {
    exibirModalConfirmacaoAlertaVia(
      context,
      alerta: alerta,
      aoResponder: (aindaEstaLa) async {
        await _viewModel.confirmarAlerta(
          alerta.uid,
          aindaEstaLa: aindaEstaLa,
        );
      },
    );
  }

  Future<void> _copiarPix(BuildContext context) async {
    final copiou = await _viewModel.copiarChavePix();
    if (copiou && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chave Pix copiada para a área de transferência!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CabecalhoIdentidadeVia(
                nomeEscalada: _viewModel.nomeEscalada,
                modalidade: _viewModel.modalidade,
                ehDestaque: _viewModel.ehDestaque,
                cragId: widget.cragId,
                escalada: widget.escalada,
                setor: widget.setor,
                grupo: widget.grupo,
              ),
              AreaHeroiTopoGrauVia(
                escalada: widget.escalada,
                cragId: widget.cragId,
                pico: widget.pico,
                setor: widget.setor,
                grupo: widget.grupo,
                fromMapaPage: widget.fromMapaPage,
                exibirCartaoGrau: _viewModel.exibirCartaoGrau,
                rotuloGrauOficial: _viewModel.rotuloGrauOficial,
                grauOficial: _viewModel.grauOficialExibicao,
                complementoGrauOficial: _viewModel.complementoGrauOficial,
                consensoGrau: _viewModel.consensoGrau,
                alertasAtivos: _viewModel.alertasAtivos,
                aoTocarAlerta: (alerta) =>
                    _abrirConfirmacaoAlerta(context, alerta),
              ),
              SecaoCadernetaVia(
                escalada: widget.escalada,
                viewModel: widget.cadernetaViewModel,
              ),
              GradeAtributosTecnicosVia(
                atributos: _viewModel.atributosTecnicos,
                tipoAncoragem: _viewModel.tipoAncoragem,
              ),
              SecaoTextosETecnicasVia(
                cragId: widget.cragId,
                secoes: _viewModel.secoesTexto,
              ),
              SecaoEnfiadasVia(enfiadas: _viewModel.enfiadas),
              SecaoBetasMidiaVia(
                midias: _viewModel.midiasBeta,
                aoAbrirMidia: _viewModel.abrirMidiaBeta,
              ),
              SecaoNotasComunidadeVia(
                comentarios: _viewModel.comentariosComunidade,
              ),
              SecaoHistoricoEPixVia(
                conquistadoresTexto: _viewModel.conquistadoresTexto,
                dataAbertura: _viewModel.dataAbertura,
                dataManutencao: _viewModel.dataManutencao,
                chavePixManutencao: _viewModel.chavePixManutencao,
                aoCopiarPix: () => _copiarPix(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget _buildMultienfiada(
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
    final grau = formatGradeString(via.dificuldadeMaxima.name);
    if (grau.isNotEmpty) {
      statCards.add(
        _buildStatCard(
          context,
          'Dificuldade Máx',
          grau,
          Icons.trending_up,
        ),
      );
    }
  }
  if (via.hasDificuldadeMedia()) {
    final grau = formatGradeString(via.dificuldadeMedia.name);
    if (grau.isNotEmpty) {
      statCards.add(
        _buildStatCard(
          context,
          'Dificuldade Média',
          grau,
          Icons.trending_flat,
        ),
      );
    }
  }
  if (via.hasDificuldadeArtificial()) {
    final artificial = _fmtEnum(via.dificuldadeArtificial);
    if (artificial.isNotEmpty) {
      statCards.add(
        _buildStatCard(
          context,
          'Artificial',
          artificial,
          Icons.architecture,
        ),
      );
    }
  }
  if (via.hasDificuldadeArtificialEmLivre()) {
    final artLivre = _fmtEnum(via.dificuldadeArtificialEmLivre);
    if (artLivre.isNotEmpty) {
      statCards.add(
        _buildStatCard(
          context,
          'Art. em Livre',
          artLivre,
          Icons.back_hand,
        ),
      );
    }
  }
  if (via.hasExposicao()) {
    final exposicao = _fmtEnum(via.exposicao);
    if (exposicao.isNotEmpty) {
      statCards.add(
        _buildStatCard(
          context,
          'Exposição',
          exposicao,
          Icons.warning_amber_rounded,
        ),
      );
    }
  }
  if (via.hasDuracao()) {
    final duracao = _fmtEnum(via.duracao);
    if (duracao.isNotEmpty) {
      statCards.add(
        _buildStatCard(context, 'Duração', duracao, Icons.timer),
      );
    }
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
  if (via.quantidadeCosturasIntermediarias > 0 ||
      via.quantidadeEquipamentosParada > 0) {
    statCards.add(
      _buildStatCard(
        context,
        'Proteções',
        '${via.quantidadeCosturasIntermediarias}+${via.quantidadeEquipamentosParada}',
        Icons.shield_outlined,
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
    final tipo = _fmtEnum(via.tipoViaMultiplasEnfiadas);
    if (tipo.isNotEmpty) {
      statCards.add(
        _buildStatCard(
          context,
          'Tipo',
          tipo,
          Icons.merge_type,
        ),
      );
    }
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
      _buildHeader('Informações da Multienfiada'),
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

      if (via.hasDescricao() && via.descricao.isNotEmpty) ...[
        _buildHeader('Descrição'),
        OfflineMarkdown(data: via.descricao, cragId: cragId),
      ],

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
  ResolvedDataset? resolved;
  if (pico != null) {
    final resolver =
        PageListenableBuilder.resolverOf(context) ?? DatasetResolver(pico: pico);
    resolved = escalada.uid.isNotEmpty
        ? resolver.obterPorUid(escalada.uid)
        : resolver.buscarPorNome(
            grupoNome: grupo?.nome,
            setorNome: setor?.nome,
            escaladaNome: getEscaladaNome(escalada),
          );
  }

  // 1. Se a escalada possui mapas próprios locais, exibe o MapaThumbnail rico
  if (escalada.mapas.isNotEmpty) {
    final validMapas = escalada.mapas
        .where((m) =>
            m.caminhoImagemMapa.isNotEmpty &&
            m.larguraMapa > 0 &&
            m.alturaMapa > 0)
        .toList();

    if (validMapas.isNotEmpty) {
      final List<CarrosselItemData> carrosselItens;
      if (resolved != null) {
        carrosselItens = resolved.resolverCarrosselUnificado();
      } else {
        carrosselItens = validMapas
            .map(
              (m) => CarrosselItemData(
                mapaCaminhoImagem: m.caminhoImagemMapa,
                setorContextNome: setor?.nome,
                grupoContextNome: grupo?.nome,
                escaladaContextNome: getEscaladaNome(escalada),
              ),
            )
            .toList();
      }

      final aspectRatio =
          validMapas.first.larguraMapa / validMapas.first.alturaMapa;

      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: MapaThumbnail(
              mapas: validMapas,
              cragId: cragId,
              setorContext: setor,
              grupoContext: grupo,
              nomeContexto: getEscaladaNome(escalada),
              carrosselItensOverride: carrosselItens,
            ),
          ),
        ),
      );
    }
  }

  // 2. Se a escalada não possui mapas próprios, verifica mapas onde ela é referenciada
  final referencias = resolved?.referencias ?? const [];
  if (referencias.isEmpty) return const SizedBox.shrink();

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
          final mapasData = referencias
              .map(
                (refNoMapa) => CarrosselItemData(
                  mapaCaminhoImagem: refNoMapa.mapa.caminhoImagemMapa,
                  setorContextNome: refNoMapa.setorContexto?.nome,
                  grupoContextNome: refNoMapa.grupoContexto?.nome,
                  escaladaContextNome: getEscaladaNome(escalada),
                  initialSelectedId: refNoMapa.referencia.pontosUids.isNotEmpty
                      ? refNoMapa.referencia.pontosUids.first
                      : null,
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
      LinhaLocalizacaoSetor(
        cragId: cragId,
        setor: setor,
        grupo: grupo,
        escalada: escalada,
      ),
    );
  }

  if (isDestaque) {
    badges.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
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
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: badges,
    ),
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
