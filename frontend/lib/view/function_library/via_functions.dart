// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../data/modelos/interacao_via.dart';
import '../../navigation/construtor_reativo_pagina.dart';
import '../../navigation/funcoes_navegacao.dart';
import '../../theme/cores_app.dart';
import '../../utils/formatador_escalada.dart';
import '../../widgets/caderneta/modal_registro_cadena.dart';
import '../../widgets/via/barra_inferior_acoes_via.dart';
import '../../widgets/via/bolha_alerta_seguranca_via.dart';
import '../../widgets/via/cabecalho_e_heroi_via.dart';
import '../../widgets/via/secoes_detalhes_via.dart';
import '../../widgets/via/snackbar_flutuante_seguro.dart';
import '../view_models/secao_caderneta_via_view_model.dart';
import '../view_models/via_view_model.dart';

export '../../utils/formatador_escalada.dart' show obterCodigoGrauOficial;

/// Retorna o nome da escalada com base em sua modalidade ativa.
String getEscaladaNome(Escalada escalada) => obterNomeEscalada(escalada);

/// Retorna o rótulo da modalidade da escalada (`'Esportiva'`, `'Mista'`, `'Móvel'`, `'Boulder'`, `'Multienfiada'`, `'Highline'`).
String getModalidadeEscalada(Escalada escalada) =>
    ExtratorDetalhesTecnicosVia.extrairModalidade(escalada);

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

/// Constrói o corpo declarativo da página de detalhes da Via.
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

/// Corpo reativo (Dumb UI) no estilo *Passaporte da Via + Barra no Polegar*, compondo
/// o cartão unificado superior, as seções modulares abaixo da dobra e o dock inferior.
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
  late SecaoCadernetaViaViewModel _cadernetaViewModel;
  bool _gerenciaViaVm = false;
  bool _gerenciaCadernetaVm = false;

  @override
  void initState() {
    super.initState();
    _vincularViewModels();
  }

  @override
  void didUpdateWidget(covariant CorpoDetalhesVia oldWidget) {
    super.didUpdateWidget(oldWidget);
    final mudouEscaladas = widget.escalada != oldWidget.escalada;
    if (widget.viewModel != oldWidget.viewModel ||
        (_gerenciaViaVm && mudouEscaladas) ||
        widget.cadernetaViewModel != oldWidget.cadernetaViewModel ||
        (_gerenciaCadernetaVm && mudouEscaladas)) {
      _descartarProprios();
      _vincularViewModels();
    }
  }

  void _vincularViewModels() {
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
      _gerenciaViaVm = false;
    } else {
      _viewModel = ViaViewModel(escalada: widget.escalada);
      _gerenciaViaVm = true;
    }

    if (widget.cadernetaViewModel != null) {
      _cadernetaViewModel = widget.cadernetaViewModel!;
      _gerenciaCadernetaVm = false;
    } else {
      _cadernetaViewModel = SecaoCadernetaViaViewModel(
        escalada: widget.escalada,
        repositorioInteracoes: _viewModel.repositorioInteracoes,
      );
      _gerenciaCadernetaVm = true;
    }
  }

  void _descartarProprios() {
    if (_gerenciaViaVm) {
      _viewModel.dispose();
    }
    if (_gerenciaCadernetaVm) {
      _cadernetaViewModel.dispose();
    }
  }

  @override
  void dispose() {
    _descartarProprios();
    super.dispose();
  }

  double get _recuoDockInferior => _cadernetaViewModel.visivel ? 72.0 : 0.0;

  void _abrirRegistroCadena(BuildContext context) {
    final despachanteSnack = capturarDespachanteSnackBarSeguro(
      context,
      recuoExtraInferior: _recuoDockInferior,
    );
    final registroVm = _cadernetaViewModel.criarViewModelRegistro();
    exibirModalRegistroCadena(
      context,
      viewModel: registroVm,
      onSalvo: (cadenaSalva) {
        final mensagem = cadenaSalva.isCadena
            ? 'Cadena salva na caderneta!'
            : 'Tentativa salva na caderneta!';
        despachanteSnack.exibir(
          texto: mensagem,
          duracao: const Duration(seconds: 2),
        );
      },
    ).whenComplete(registroVm.dispose);
  }

  void _abrirConfirmacaoAlerta(
    BuildContext context,
    AlertaSegurancaVia alerta,
  ) {
    final despachanteSnack = capturarDespachanteSnackBarSeguro(
      context,
      recuoExtraInferior: _recuoDockInferior,
    );

    exibirModalConfirmacaoAlertaVia(
      context,
      alerta: alerta,
      estadoUsuario: _viewModel.estadoInteracaoDoAlerta(alerta),
      aoResponder: (aindaEstaLa) async {
        if (aindaEstaLa) {
          await _viewModel.confirmarAlerta(
            alerta.uid,
            aindaEstaLa: true,
          );
          return;
        }

        _viewModel.iniciarResolucaoAlertaComDesfazer(alerta.uid);
        despachanteSnack.exibir(
          texto: 'Alerta marcado como resolvido.',
          duracao: const Duration(seconds: 4),
          rotuloAcao: 'Desfazer',
          aoAcionar: () => _viewModel.desfazerResolucaoAlerta(alerta.uid),
        );
      },
    );
  }

  Future<void> _votarGrauDireto(BuildContext context, int delta) async {
    final despachanteSnack = capturarDespachanteSnackBarSeguro(
      context,
      recuoExtraInferior: _recuoDockInferior,
    );
    final resultado = await _viewModel.votarGrauComunidade(delta);
    if (resultado == ResultadoVotoGrauVia.requerAutenticacao) {
      despachanteSnack.exibir(
        texto:
            'Entre na sua conta na aba Perfil para votar no grau da via.',
        duracao: const Duration(seconds: 3),
      );
    } else if (resultado == ResultadoVotoGrauVia.registrado) {
      despachanteSnack.exibir(
        texto: 'Voto de grau atualizado!',
        duracao: const Duration(seconds: 2),
      );
    }
  }

  void _abrirCroquiInterativo(
    BuildContext context,
    EstadoCroquiVia estadoCroqui,
  ) {
    _viewModel.registrarVisualizacaoCroqui(
      cragId: widget.cragId,
      nomeSetor: widget.setor?.nome,
    );
    if (widget.fromMapaPage) {
      AppNav.back(context);
      return;
    }
    AppNav.toMapas(
      context,
      cragId: widget.cragId,
      mapas: estadoCroqui.itensNavegacaoCroqui,
    );
  }

  Future<void> _copiarPix(BuildContext context) async {
    final despachanteSnack = capturarDespachanteSnackBarSeguro(
      context,
      recuoExtraInferior: _recuoDockInferior,
    );
    final copiou = await _viewModel.copiarChavePix();
    if (copiou) {
      despachanteSnack.exibir(
        texto: 'Chave Pix copiada para a área de transferência!',
        duracao: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return ListenableBuilder(
      listenable: Listenable.merge([_viewModel, _cadernetaViewModel]),
      builder: (context, _) {
        final estadoCroqui = _viewModel.resolverEstadoCroqui(
          pico: widget.pico,
          setor: widget.setor,
          grupo: widget.grupo,
          resolvedorExterno: PageListenableBuilder.resolverOf(context),
        );
        final resumoAscensao = _cadernetaViewModel.resumoAscensao;
        final citacaoNotas = _cadernetaViewModel.citacaoNotasPrivadas;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cartão Unificado "Passaporte da Via" (Direção C)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cores.caveShadow,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: cores.graniteEdge),
                      ),
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
                          if (_cadernetaViewModel.visivel &&
                              resumoAscensao != null) ...[
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () => _abrirRegistroCadena(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _cadernetaViewModel.isCadena
                                      ? cores.darkPine.withValues(alpha: 0.7)
                                      : cores.deepBasalt,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _cadernetaViewModel.isCadena
                                        ? cores.fernGreen.withValues(alpha: 0.7)
                                        : cores.graniteEdge,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _cadernetaViewModel.isCadena
                                              ? Icons.check_circle_rounded
                                              : Icons.refresh_rounded,
                                          size: 18,
                                          color: _cadernetaViewModel.isCadena
                                              ? cores.fernGreen
                                              : cores.rustIron,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            resumoAscensao,
                                            style: TextStyle(
                                              color: cores.chalkWhite,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (citacaoNotas != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        citacaoNotas,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: cores.ashGrey,
                                          fontStyle: FontStyle.italic,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (estadoCroqui.possuiCroqui ||
                              _viewModel.exibirCartaoGrau ||
                              _viewModel.alertasAtivos.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            AreaHeroiTopoGrauVia(
                              estadoCroqui: estadoCroqui,
                              cragId: widget.cragId,
                              nomeEscalada: _viewModel.nomeEscalada,
                              setor: widget.setor,
                              grupo: widget.grupo,
                              aoAbrirCroquiInterativo: () =>
                                  _abrirCroquiInterativo(context, estadoCroqui),
                              exibirCartaoGrau: _viewModel.exibirCartaoGrau,
                              rotuloGrauOficial: _viewModel.rotuloGrauOficial,
                              grauOficial: _viewModel.grauOficialExibicao,
                              complementoGrauOficial:
                                  _viewModel.complementoGrauOficial,
                              apresentacaoConsenso:
                                  _viewModel.apresentacaoConsenso,
                              aoVotarGrau: _viewModel.exibirRecursosComunidade &&
                                      _viewModel.possuiUid
                                  ? (delta) => _votarGrauDireto(context, delta)
                                  : null,
                              alertasAtivos: _viewModel.alertasAtivos,
                              aoTocarAlerta: (alerta) =>
                                  _abrirConfirmacaoAlerta(context, alerta),
                            ),
                          ],
                          if (_viewModel.atributosTecnicos.isNotEmpty ||
                              _viewModel.tipoAncoragem != null) ...[
                            const SizedBox(height: 12),
                            GradeAtributosTecnicosVia(
                              atributos: _viewModel.atributosTecnicos,
                              tipoAncoragem: _viewModel.tipoAncoragem,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
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
                      notas: _viewModel.notasComunidadeApresentacao,
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
              ),
            ),
            BarraInferiorAcoesVia(
              exibirBotaoCaderneta: _cadernetaViewModel.visivel,
              possuiCadena: _cadernetaViewModel.isCadena,
              rotuloBotaoCaderneta: _cadernetaViewModel.rotuloBotao,
              aoRegistrarCadena: () => _abrirRegistroCadena(context),
            ),
          ],
        );
      },
    );
  }
}
