// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../idioma/tradutor_app.dart';
import '../../theme/cores_app.dart';
import 'bandeira_idioma_app.dart';

export 'bandeira_idioma_app.dart';

/// Botão flutuante em formato de bolha para alternância rápida de idioma com bandeira do país.
///
/// - **Toque simples**: abre o painel flutuante animado de bandeiras para seleção direta.
/// - **Toque longo**: rotaciona instantaneamente para o próximo idioma.
/// - Construído sem `BackdropFilter`/`ImageFiltered`, sem `Image` e sem `ScrollView` para preservar
///   100% da performance de GPU e dos invariantes estruturais de `HomePage` e `PicoDetailsPage`.
class BotaoBolhaIdioma extends StatelessWidget {
  /// Controlador opcional para isolamento determinístico em testes.
  final ControladorIdiomaApp? controlador;

  /// Quando verdadeiro, aplica fundo translúcido escuro (`Colors.black87`) ideal para cabeçalhos sobre fotos.
  final bool sobreFundoFotografico;

  const BotaoBolhaIdioma({
    super.key,
    this.controlador,
    this.sobreFundoFotografico = false,
  });

  ControladorIdiomaApp get _ctrl =>
      controlador ?? ControladorIdiomaApp.instancia;

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return ValueListenableBuilder<IdiomaApp>(
      valueListenable: _ctrl.notificadorIdioma,
      builder: (context, idiomaAtivo, _) {
        final dica = TradutorApp.texto(
          ChaveTexto.seletorIdiomaTooltip,
          idioma: idiomaAtivo,
        );
        final corFundo = sobreFundoFotografico
            ? Colors.black87
            : cores.caveShadow;
        final corBorda = sobreFundoFotografico
            ? Colors.white24
            : cores.graniteEdge;

        return Semantics(
          button: true,
          label: '$dica (${idiomaAtivo.nomeNativo})',
          child: Tooltip(
            message: '$dica (${idiomaAtivo.nomeNativo})',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => exibirSeletorBolhasIdioma(
                  context,
                  controlador: _ctrl,
                ),
                onLongPress: () {
                  HapticFeedback.selectionClick();
                  _ctrl.ciclarProximoIdioma();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  decoration: BoxDecoration(
                    color: corFundo,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: corBorda, width: 1.15),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
