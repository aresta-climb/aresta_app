// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../navigation/funcoes_navegacao.dart';
import '../theme/cores_app.dart';
import '../view/function_library/via_functions.dart';
import '../view/view_models/secao_caderneta_via_view_model.dart';
import '../view/view_models/via_view_model.dart';
import '../widgets/via/bolha_alerta_seguranca_via.dart';
import '../widgets/via/snackbar_flutuante_seguro.dart';

/// Página declarativa (Dumb UI / MVVM) que exibe o Passaporte unificado da via, croqui interativo,
/// consenso comunitário com votação direta, bolhas de alerta com desfazer e dock de caderneta,
/// delegando todos os comandos e estados ao [ViaViewModel].
class ViaPage extends StatefulWidget {
  /// Escalada Protobuf exibida.
  final Escalada escalada;

  /// Identificador do croqui pai.
  final String cragId;

  /// Pico pai opcional para resolução de mapas.
  final Pico? pico;

  /// Setor pai opcional.
  final Setor? setor;

  /// Grupo pai opcional.
  final Grupo? grupo;

  /// Preserva compatibilidade com chamadas vindas diretamente da `SetorPage`.
  final bool fromSetorPage;

  /// Preserva compatibilidade com chamadas vindas diretamente da `MapaPage`.
  final bool fromMapaPage;

  /// ViewModel principal opcional para injeção em testes.
  final ViaViewModel? viewModel;

  /// ViewModel opcional da seção de caderneta esportiva.
  final SecaoCadernetaViaViewModel? cadernetaViewModel;

  /// Cria uma instância de [ViaPage].
  const ViaPage({
    super.key,
    required this.escalada,
    required this.cragId,
    this.pico,
    this.setor,
    this.grupo,
    this.fromSetorPage = false,
    this.fromMapaPage = false,
    this.viewModel,
    this.cadernetaViewModel,
  });

  @override
  State<ViaPage> createState() => _ViaPageState();
}

class _ViaPageState extends State<ViaPage> {
  late ViaViewModel _viewModel;
  bool _gerenciaCicloVida = false;

  @override
  void initState() {
    super.initState();
    _inicializarViewModel();
  }

  @override
  void didUpdateWidget(covariant ViaPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.viewModel != oldWidget.viewModel ||
        (_gerenciaCicloVida && widget.escalada != oldWidget.escalada)) {
      if (_gerenciaCicloVida) {
        _viewModel.dispose();
      }
      _inicializarViewModel();
    }
  }

  void _inicializarViewModel() {
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

  void _abrirModalReportarAlerta(BuildContext context) {
    final despachanteSnack = capturarDespachanteSnackBarSeguro(
      context,
      recuoExtraInferior:
          _viewModel.exibirRecursosComunidade && !_viewModel.ehHighline
          ? 72
          : 0,
    );
    if (!_viewModel.usuarioEstaAutenticado) {
      despachanteSnack.exibir(
        texto:
            'Entre na sua conta na aba Perfil para reportar alertas de segurança.',
        duracao: const Duration(seconds: 3),
      );
      return;
    }
    exibirModalReportarAlertaVia(
      context,
      aoReportar: (categoria, detalhe) async {
        final sucesso = await _viewModel.reportarAlerta(
          categoria,
          detalhe: detalhe,
        );
        if (sucesso) {
          despachanteSnack.exibir(
            texto: 'Alerta de segurança registrado!',
            duracao: const Duration(seconds: 2),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final podeVoltar =
            ModalRoute.of(context)?.canPop == true || AppNav.canGoBack(context);
        final subtituloTopo = widget.pico?.nome.isNotEmpty == true
            ? widget.pico!.nome
            : '';

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: cores.deepBasalt,
            elevation: 0,
            leading: podeVoltar
                ? IconButton(
                    icon: Icon(Icons.arrow_back, color: cores.chalkWhite),
                    onPressed: () => AppNav.back(context),
                  )
                : null,
            title: subtituloTopo.isNotEmpty
                ? Text(
                    subtituloTopo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cores.ashGrey,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
            actions: [
              if (_viewModel.podeReportarAlerta)
                IconButton(
                  key: const Key('btn_reportar_alerta_via'),
                  icon: Icon(
                    Icons.flag_outlined,
                    color: cores.ashGrey,
                    size: 20,
                  ),
                  tooltip: 'Reportar alerta de segurança',
                  onPressed: () => _abrirModalReportarAlerta(context),
                ),
              if (_viewModel.possuiUid)
                IconButton(
                  icon: Icon(
                    Icons.share_outlined,
                    color: cores.chalkWhite,
                    size: 20,
                  ),
                  tooltip: 'Compartilhar escalada',
                  onPressed: () {
                    _viewModel.compartilharEscalada(
                      cragId: widget.cragId,
                      nomePico: widget.pico?.nome,
                      nomeSetor: widget.setor?.nome,
                      nomeGrupo: widget.grupo?.nome,
                    );
                  },
                ),
            ],
          ),
          body: SafeArea(
            bottom: true,
            child: CorpoDetalhesVia(
              escalada: widget.escalada,
              cragId: widget.cragId,
              pico: widget.pico,
              setor: widget.setor,
              grupo: widget.grupo,
              fromMapaPage: widget.fromMapaPage,
              viewModel: _viewModel,
              cadernetaViewModel: widget.cadernetaViewModel,
            ),
          ),
        );
      },
    );
  }
}
