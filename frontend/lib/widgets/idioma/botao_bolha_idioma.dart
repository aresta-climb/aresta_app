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
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BandeiraIdiomaApp(
                        key: Key('bandeira_bolha_ativa_${idiomaAtivo.codigoIso}'),
                        idioma: idiomaAtivo,
                        largura: 22,
                        altura: 15.5,
                        raioBorda: 4.0,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.expand_more_rounded,
                        size: 15,
                        color: sobreFundoFotografico
                            ? Colors.white70
                            : cores.ashGrey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Abre o diálogo flutuante em estilo bolha para escolha imediata entre os 5 idiomas suportados.
Future<void> exibirSeletorBolhasIdioma(
  BuildContext context, {
  ControladorIdiomaApp? controlador,
}) {
  final ctrl = controlador ?? ControladorIdiomaApp.instancia;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar seletor de idioma',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 190),
    pageBuilder: (dialogContext, _, _) {
      return SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
            child: _PainelBolhasIdioma(controlador: ctrl),
          ),
        ),
      );
    },
    transitionBuilder: (_, animacao, _, filho) {
      final curva = CurvedAnimation(
        parent: animacao,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: animacao,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curva),
          alignment: Alignment.topRight,
          child: filho,
        ),
      );
    },
  );
}

class _PainelBolhasIdioma extends StatelessWidget {
  final ControladorIdiomaApp controlador;

  const _PainelBolhasIdioma({required this.controlador});

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return ValueListenableBuilder<IdiomaApp>(
      valueListenable: controlador.notificadorIdioma,
      builder: (context, idiomaAtual, _) {
        final titulo = TradutorApp.texto(
          ChaveTexto.seletorIdiomaTitulo,
          idioma: idiomaAtual,
        );
        final subtitulo = TradutorApp.texto(
          ChaveTexto.seletorIdiomaSubtitulo,
          idioma: idiomaAtual,
        );

