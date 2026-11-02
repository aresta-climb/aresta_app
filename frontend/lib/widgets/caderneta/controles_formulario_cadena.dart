// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../data/modelos/tipo_ascensao.dart';
import '../../theme/cores_app.dart';

/// Seletor declarativo em formato de chips para escolha do estilo esportivo da ascensão.
///
/// Componente puramente visual (Dumb UI) reutilizável em formulários e filtros de caderneta.
class SeletorEstiloAscensao extends StatelessWidget {
  /// Estilo esportivo atualmente selecionado.
  final TipoAscensao estiloSelecionado;

  /// Callback invocado quando o usuário seleciona um novo estilo esportivo.
  final ValueChanged<TipoAscensao> aoSelecionar;

  const SeletorEstiloAscensao({
    super.key,
    required this.estiloSelecionado,
    required this.aoSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estilo Esportivo',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: cores.chalkWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TipoAscensao.values.map((estilo) {
            final selecionado = estiloSelecionado == estilo;
            return ChoiceChip(
              label: Text(
                estilo.rotulo,
                style: TextStyle(
                  color: selecionado ? cores.chalkWhite : cores.ashGrey,
                  fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: selecionado,
              selectedColor: cores.rustIron,
              backgroundColor: cores.caveShadow,
              side: BorderSide(
                color: selecionado
                    ? cores.rustIron
                    : cores.graniteEdge.withValues(alpha: 0.6),
              ),
              onSelected: (bool ativo) {
                if (ativo) aoSelecionar(estilo);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Seletor numérico declarativo de tentativas/pegas despendidas na ascensão.
class ContadorTentativasAscensao extends StatelessWidget {
  /// Quantidade atual de tentativas exibida no contador.
  final int tentativas;

  /// Indica se o botão de decremento está habilitado.
  final bool podeDecrementar;

  /// Callback acionado ao tocar no botão de incremento (`+`).
  final VoidCallback aoIncrementar;

  /// Callback acionado ao tocar no botão de decremento (`-`).
  final VoidCallback aoDecrementar;

  const ContadorTentativasAscensao({
    super.key,
    required this.tentativas,
    required this.podeDecrementar,
    required this.aoIncrementar,
    required this.aoDecrementar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Tentativas / Pegas',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: cores.chalkWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: cores.caveShadow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cores.graniteEdge),
          ),
          child: Row(
            children: [
              IconButton(
                key: const Key('btn_decrementar_tentativas'),
                icon: const Icon(Icons.remove, size: 18),
                color: podeDecrementar ? cores.chalkWhite : cores.ashGrey,
                onPressed: podeDecrementar ? aoDecrementar : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$tentativas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cores.chalkWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                key: const Key('btn_incrementar_tentativas'),
                icon: const Icon(Icons.add, size: 18),
                color: cores.chalkWhite,
                onPressed: aoIncrementar,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Linha seletora declarativa de data da ascensão.
class SeletorDataAscensao extends StatelessWidget {
  /// Data formatada pronta para exibição (ex.: `01/11/2026`).
  final String dataTexto;

  /// Callback acionado ao tocar no seletor de calendário.
  final VoidCallback aoTocar;

  const SeletorDataAscensao({
    super.key,
    required this.dataTexto,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Data da Ascensão',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: cores.chalkWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          key: const Key('btn_selecionar_data'),
          onTap: aoTocar,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cores.caveShadow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cores.graniteEdge),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: cores.rustIron,
                ),
                const SizedBox(width: 8),
                Text(dataTexto, style: TextStyle(color: cores.chalkWhite)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Campo de texto declarativo para inserção de notas técnicas pessoais da ascensão.
class CampoNotasPrivadasAscensao extends StatelessWidget {
  /// Controlador de edição vinculado ao campo de notas.
  final TextEditingController controlador;

  /// Texto do contador de caracteres exibido no cabeçalho (ex.: `26/200`).
  final String contadorTexto;

  /// Indica se o texto atingiu o limite máximo de caracteres para destaque visual.
  final bool atingiuLimite;

  /// Limite máximo de caracteres permitido pelo campo.
  final int limiteCaracteres;

  const CampoNotasPrivadasAscensao({
    super.key,
    required this.controlador,
    required this.contadorTexto,
    required this.atingiuLimite,
    required this.limiteCaracteres,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Notas Privadas (Crux / Métodos)',
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
              contadorTexto,
              style: TextStyle(
                color: atingiuLimite ? cores.rustIron : cores.ashGrey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('campo_notas_privadas'),
          controller: controlador,
          maxLength: limiteCaracteres,
          maxLines: 3,
          buildCounter:
              (
                context, {
                required currentLength,
                required isFocused,
                maxLength,
              }) => null,
          style: TextStyle(color: cores.chalkWhite),
          decoration: InputDecoration(
            hintText:
                'Ex: Crux no 3º grampo com calcanhar esquerdo, levar costura longa...',
            hintStyle: TextStyle(
              color: cores.ashGrey.withValues(alpha: 0.7),
              fontSize: 13,
            ),
            filled: true,
            fillColor: cores.caveShadow,
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
      ],
    );
  }
}
