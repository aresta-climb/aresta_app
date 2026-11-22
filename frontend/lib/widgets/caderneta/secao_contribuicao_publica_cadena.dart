// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../theme/cores_app.dart';
import '../../view/view_models/registro_cadena_view_model.dart';

/// Bloco puramente declarativo (Dumb UI) de **Contribuição Pública** exibido no `ModalRegistroCadena`.
///
/// Renderiza as opções de percepção de grau já formatadas pelo [RegistroCadenaViewModel] e o campo
/// opcional de dicas públicas de beta/equipamento sem executar cálculos de domínio.
class SecaoContribuicaoPublicaAscensao extends StatelessWidget {
  /// Opções pré-formatadas de percepção de grau (`-2` a `+2`) fornecidas pelo ViewModel.
  final List<OpcaoDeltaGrauApresentacao> opcoesDelta;

  /// Callback acionado quando o escalador escolhe um delta de grau.
  final ValueChanged<int> aoSelecionarDelta;

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
    required this.opcoesDelta,
    required this.aoSelecionarDelta,
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
            children: opcoesDelta.map((opcao) {
              final selecionado = opcao.selecionado;
              return ChoiceChip(
                key: Key('chip_delta_grau_${opcao.delta}'),
                label: Text(
                  opcao.rotulo,
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
                  if (ativo) aoSelecionarDelta(opcao.delta);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          if (estaAutenticado) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Beta da Comunidade (opcional)',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cores.chalkWhite,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  contadorComentarioTexto,
                  style: TextStyle(
                    color: atingiuLimiteComentario
                        ? cores.rustIron
                        : cores.ashGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('campo_comentario_publico_cadena'),
              controller: controladorComentario,
              maxLength: limiteCaracteresComentario,
              maxLines: 2,
              buildCounter:
                  (
                    context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
              style: TextStyle(color: cores.chalkWhite, fontSize: 14),
              decoration: InputDecoration(
                hintText:
                    'Ex.: Costura 3 longa; boa leitura pela esquerda no crux.',
                hintStyle: TextStyle(
                  color: cores.ashGrey.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: cores.deepBasalt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cores.graniteEdge),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cores.graniteEdge),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cores.rustIron),
                ),
              ),
            ),
          ] else
            Text(
              'Conecte sua conta na aba Perfil para enviar votos e dicas públicas ao guia comunitário.',
              style: TextStyle(color: cores.ashGrey, fontSize: 12, height: 1.35),
            ),
        ],
      ),
    );
  }
}
