// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../idioma/tradutor_app.dart';
import '../../theme/cores_app.dart';
import '../idioma/bandeira_idioma_app.dart';

/// Cartão declarativo na tela de Configurações para alternância direta entre os 5 idiomas do app.
class CartaoPreferenciaIdioma extends StatelessWidget {
  final ControladorIdiomaApp? controlador;

  const CartaoPreferenciaIdioma({
    super.key,
    this.controlador,
  });

  ControladorIdiomaApp get _ctrl =>
      controlador ?? ControladorIdiomaApp.instancia;

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return ValueListenableBuilder<IdiomaApp>(
      valueListenable: _ctrl.notificadorIdioma,
      builder: (context, idiomaAtual, _) {
        final titulo = TradutorApp.texto(
          ChaveTexto.configIdiomaTitulo,
          idioma: idiomaAtual,
        );
        final subtitulo = TradutorApp.texto(
          ChaveTexto.configIdiomaSubtitulo,
          idioma: idiomaAtual,
        );

        return Container(
          key: const Key('cartao_preferencia_idioma'),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cores.caveShadow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cores.graniteEdge),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.language_rounded,
                    color: cores.rustIron,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    titulo,
                    style: TextStyle(
                      color: cores.chalkWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subtitulo,
                style: TextStyle(
                  color: cores.ashGrey,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final opcao in IdiomaApp.values)
                    _BolhaIdiomaConfig(
                      idioma: opcao,
                      selecionado: opcao == idiomaAtual,
                      aoTocar: () {
                        HapticFeedback.selectionClick();
                        _ctrl.definirIdioma(opcao);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

