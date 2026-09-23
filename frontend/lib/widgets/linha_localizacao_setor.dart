// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../navigation/navigation_functions.dart';
import '../services/firebase/telemetry_service.dart';
import '../theme/app_colors.dart';
import '../view_functions/via_functions.dart';

/// Componente que apresenta a localização geográfica de uma escalada (`Grupo > Setor`
/// ou apenas `Setor`) com indicação visual evidente de que é acionável para abrir
/// diretamente a visualização do setor no croqui com foco na via.
class LinhaLocalizacaoSetor extends StatelessWidget {
  /// Identificador único do pico (cragId).
  final String cragId;

  /// Setor ao qual a escalada pertence.
  final Setor setor;

  /// Grupo geográfico pai do setor, caso exista.
  final Grupo? grupo;

  /// Escalada de referência para posicionamento/scroll no croqui.
  final Escalada? escalada;

  /// Callback customizado acionado ao tocar na linha (útil para testes ou sobreposições).
  final VoidCallback? onAbrirSetor;

  const LinhaLocalizacaoSetor({
    super.key,
    required this.cragId,
    required this.setor,
    this.grupo,
    this.escalada,
    this.onAbrirSetor,
  });

  String get _textoHierarquia {
    if (grupo != null && grupo!.nome.isNotEmpty) {
      return '${grupo!.nome} > ${setor.nome}';
    }
    return setor.nome;
  }

  void _aoTocar(BuildContext context) {
    if (onAbrirSetor != null) {
      onAbrirSetor!();
      return;
    }

    final nomeVia = escalada != null ? getEscaladaNome(escalada!) : '';
    TelemetryService.instance.logAcaoEscalada(
      cragId,
      setor.nome,
      nomeVia,
      'abrir_setor',
      'linha_localizacao_setor',
    );

    AppNav.toSetor(
      context,
      setor: setor,
      grupoContext: grupo,
      scrollToEscalada: escalada,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abrir croqui do setor $_textoHierarquia',
      child: InkWell(
        onTap: () => _aoTocar(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.colors.mossRock.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.colors.mossRock.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: context.colors.mossRock,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _textoHierarquia,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.colors.mossRock.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver no croqui',
                      style: TextStyle(
                        color: context.colors.mossRock,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: context.colors.mossRock,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
