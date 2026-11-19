// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../services/compartilhamento/servico_compartilhamento.dart';
import '../view/function_library/biblioteca_funcoes_comuns.dart';
import '../view/function_library/via_functions.dart';
import '../view/view_models/secao_caderneta_via_view_model.dart';
import '../view/view_models/via_view_model.dart';
import '../widgets/via/bolha_alerta_seguranca_via.dart';

/// Página declarativa (MVVM) que exibe os detalhes técnicos, croqui interativo,
/// consenso comunitário de grau, bolhas de alerta estilo Waze e caderneta de uma [Escalada].
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
    exibirModalReportarAlertaVia(
      context,
      aoReportar: (categoria, detalhe) async {
        final sucesso = await _viewModel.reportarAlerta(
          categoria,
          detalhe: detalhe,
        );
        if (sucesso && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Alerta de segurança registrado!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final nome = _viewModel.nomeEscalada;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: buildCommonAppBar(
            context,
            nome.toUpperCase(),
            actions: [
              if (_viewModel.podeReportarAlerta)
                IconButton(
                  key: const Key('btn_reportar_alerta_via'),
                  icon: const Icon(Icons.campaign_outlined),
                  tooltip: 'Reportar alerta de segurança',
                  onPressed: () => _abrirModalReportarAlerta(context),
                ),
              if (_viewModel.possuiUid)
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Compartilhar escalada',
                  onPressed: () {
                    ServicoCompartilhamento.instancia.compartilharEscalada(
                      idCroqui: widget.cragId,
                      uid: widget.escalada.uid,
                      nomeEscalada: nome,
                      grau: getGrauString(widget.escalada),
                      nomeSetor:
                          widget.setor?.nome ?? widget.grupo?.nome ?? 'Geral',
                      nomePico: widget.pico?.nome ?? widget.cragId,
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
