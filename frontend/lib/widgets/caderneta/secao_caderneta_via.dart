// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../theme/cores_app.dart';
import '../../view/view_models/secao_caderneta_via_view_model.dart';
import 'modal_registro_cadena.dart';

/// Componente visual declarativo (Dumb UI) que exibe o selo de melhor ascensão e o botão
/// de registro de cadenas/tentativas na tela de detalhes de uma [Escalada].
///
/// Delega integralmente regras de visibilidade, formatação e consultas de repositório
/// ao [SecaoCadernetaViaViewModel], sem importar nem acessar serviços diretamente.
class SecaoCadernetaVia extends StatefulWidget {
  /// Escalada Protobuf exibida na página.
  final Escalada escalada;

  /// ViewModel opcional injetado externamente.
  final SecaoCadernetaViaViewModel? viewModel;

  const SecaoCadernetaVia({
    super.key,
    required this.escalada,
    this.viewModel,
  });

  @override
  State<SecaoCadernetaVia> createState() => _SecaoCadernetaViaState();
}

class _SecaoCadernetaViaState extends State<SecaoCadernetaVia> {
  late final SecaoCadernetaViaViewModel _viewModel;
  bool _gerenciaCicloVida = false;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
    } else {
      _viewModel = SecaoCadernetaViaViewModel(escalada: widget.escalada);
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

  void _abrirRegistro(BuildContext context) {
    final registroVm = _viewModel.criarViewModelRegistro();
    exibirModalRegistroCadena(
      context,
      viewModel: registroVm,
    ).whenComplete(registroVm.dispose);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (!_viewModel.visivel) {
          return const SizedBox.shrink();
        }

        final cores = context.colors;
        final isCadena = _viewModel.isCadena;
        final resumo = _viewModel.resumoAscensao;
        final citacaoNotas = _viewModel.citacaoNotasPrivadas;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isCadena
                ? cores.darkPine.withValues(alpha: 0.5)
                : cores.caveShadow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCadena
                  ? cores.fernGreen.withValues(alpha: 0.6)
                  : cores.graniteEdge,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (resumo != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      isCadena
                          ? Icons.check_circle_rounded
                          : Icons.refresh_rounded,
                      color: isCadena ? cores.fernGreen : cores.rustIron,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        resumo,
                        style: TextStyle(
                          color: cores.chalkWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                if (citacaoNotas != null) ...[
                  const SizedBox(height: 6),
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
                const SizedBox(height: 12),
              ],
              ElevatedButton.icon(
                key: const Key('btn_registrar_cadena'),
                onPressed: () => _abrirRegistro(context),
                icon: Icon(
                  _viewModel.possuiAscensao
                      ? Icons.add_circle_outline
                      : Icons.bookmark_add_outlined,
                  size: 18,
                  color: cores.chalkWhite,
                ),
                label: Text(
                  _viewModel.rotuloBotao,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCadena ? cores.fernGreen : cores.rustIron,
                  foregroundColor: cores.chalkWhite,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
