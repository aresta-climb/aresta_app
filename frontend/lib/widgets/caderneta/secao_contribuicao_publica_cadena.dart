// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../theme/cores_app.dart';
import '../../utils/calculadora_delta_grau.dart';

/// Bloco declarativo de **Contribuição Pública** exibido no `ModalRegistroCadena`.
///
/// Unifica a avaliação de percepção de grau (`-2` a `+2`, com `0` pré-selecionado) e
/// o campo opcional de dicas públicas de beta/equipamento em uma única tela de baixa fricção.
class SecaoContribuicaoPublicaAscensao extends StatelessWidget {
  /// Valores de delta suportados em relação ao grau oficial da escalada.
  static const List<int> deltasDisponiveis = [-2, -1, 0, 1, 2];

  /// Delta atualmente selecionado (`-2` a `+2`).
  final int deltaSelecionado;

  /// Callback acionado quando o escalador escolhe um delta de grau.
  final ValueChanged<int> aoSelecionarDelta;

  /// Código numérico Protobuf do grau oficial da escalada, quando definido.
  final int? codigoGrauOficial;

  /// Indica se a escalada pertence à modalidade boulder.
  final bool ehBoulder;

  /// Indica se o escalador está autenticado para publicar voto e comentário no guia comunitário.
  final bool estaAutenticado;

  /// Controlador vinculado ao campo opcional de comentário público.
  final TextEditingController controladorComentario;

  /// Indicador de contagem de caracteres do comentário público (`'0/280'`).
  final String contadorComentarioTexto;

  /// Indica se o comentário público atingiu o limite máximo de caracteres.
  final bool atingiuLimiteComentario;

  /// Limite máximo de caracteres permitido no comentário público (`280`).
  final int limiteCaracteresComentario;

  /// Cria uma instância de [SecaoContribuicaoPublicaAscensao].
  const SecaoContribuicaoPublicaAscensao({
    super.key,
    required this.deltaSelecionado,
    required this.aoSelecionarDelta,
    required this.codigoGrauOficial,
    required this.ehBoulder,
    required this.estaAutenticado,
    required this.controladorComentario,
    required this.contadorComentarioTexto,
    required this.atingiuLimiteComentario,
    required this.limiteCaracteresComentario,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cores.caveShadow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cores.graniteEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.public_rounded, size: 16, color: cores.rustIron),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'CONTRIBUIÇÃO PÚBLICA',
                  style: TextStyle(
                    color: cores.rustIron,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Percepção do grau técnico da linha:',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: cores.chalkWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: deltasDisponiveis.map((delta) {
              final selecionado = delta == deltaSelecionado;
              final rotulo = rotuloOpcaoDeltaGrau(
                delta,
                codigoOficial: codigoGrauOficial,
                ehBoulder: ehBoulder,
              );
              return ChoiceChip(
                key: Key('chip_delta_grau_$delta'),
                label: Text(
                  rotulo,
                  style: TextStyle(
                    color: selecionado ? cores.chalkWhite : cores.ashGrey,
                    fontWeight: selecionado
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
                selected: selecionado,
                selectedColor: cores.rustIron,
                backgroundColor: cores.deepBasalt,
                side: BorderSide(
                  color: selecionado ? cores.rustIron : cores.graniteEdge,
                ),
                onSelected: (ativo) {
                  if (ativo) aoSelecionarDelta(delta);
                },
              );
            }).toList(),
          ),
          if (estaAutenticado) const SizedBox.shrink(),
        ],
      ),
    );
  }
}
