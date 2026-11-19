// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../data/modelos/interacao_via.dart';
import '../../utils/formatador_escalada.dart';
import '../../widgets/caderneta/secao_caderneta_via.dart';
import '../../widgets/via/bolha_alerta_seguranca_via.dart';
import '../../widgets/via/secoes_detalhes_via.dart';
import '../view_models/secao_caderneta_via_view_model.dart';
import '../view_models/via_view_model.dart';

export '../../utils/formatador_escalada.dart' show obterCodigoGrauOficial;

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
