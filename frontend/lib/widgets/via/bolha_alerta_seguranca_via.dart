// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/modelos/interacao_via.dart';
import '../../idioma/tradutor_app.dart';
import '../../theme/cores_app.dart';
import '../../view/view_models/formulario_alerta_via_view_model.dart';
import 'modais_edicao_interacao_via.dart';

export 'modais_edicao_interacao_via.dart';

/// Cor vermelha de alta visibilidade usada nas bolhas de alerta estilo Waze sobre rocha e cartões escuros.
const Color _corVermelhoAlerta = Color(0xFFD93829);

/// Conjunto compacto de bolhas vermelhas em formato de balão de fala com emojis de risco (`🐝`, `🪨`, `🔩`, `⚠️`),
/// posicionado sobre o canto superior direito da área de croqui/grau da `ViaPage`.
class BolhasFlutuantesAlertaVia extends StatelessWidget {
  /// Lista de alertas ativos a exibir como bolhas clicáveis.
  final List<AlertaSegurancaVia> alertas;

  /// Callback acionado ao tocar em uma bolha para abrir o modal *"Ainda está lá?"*.
  final ValueChanged<AlertaSegurancaVia> aoSelecionarAlerta;

  /// Cria uma instância de [BolhasFlutuantesAlertaVia].
  const BolhasFlutuantesAlertaVia({
    super.key,
    required this.alertas,
    required this.aoSelecionarAlerta,
  });

  @override
  Widget build(BuildContext context) {
    if (alertas.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: alertas
          .map(
            (alerta) => BolhaEmojiAlertaVia(
              key: Key('bolha_alerta_${alerta.categoria.codigoBanco}'),
              alerta: alerta,
              aoTocar: () => aoSelecionarAlerta(alerta),
            ),
          )
          .toList(),
    );
  }
}

/// Balão vermelho estilo chat/Waze contendo o emoji da categoria de risco e contador de confirmações.
class BolhaEmojiAlertaVia extends StatelessWidget {
  /// Alerta de segurança associado a esta bolha.
  final AlertaSegurancaVia alerta;

  /// Callback executado ao tocar na bolha.
  final VoidCallback aoTocar;

  /// Cria uma instância de [BolhaEmojiAlertaVia].
  const BolhaEmojiAlertaVia({
    super.key,
    required this.alerta,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr(
        ChaveTexto.alertaPrefixoSemantics,
        {'rotulo': alerta.categoria.rotulo},
      ),
      child: GestureDetector(
        onTap: aoTocar,
        child: CustomPaint(
          // ignore: prefer_const_constructors
          painter: _PintorBolhaChatVermelha(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(11, 7, 11, 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  alerta.categoria.emoji,
                  style: const TextStyle(fontSize: 18, height: 1.1),
                ),
                if (alerta.confirmacoesAtivas > 1) ...[
                  const SizedBox(width: 4),
                  Text(
                    '${alerta.confirmacoesAtivas}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      shadows: [
                        Shadow(
                          color: Color(0x66000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Constrói a silhueta unificada de balão de fala (`PathOperation.union`) da bolha de alerta,
/// fundindo corpo arredondado e cauda curva orgânica sem costura interna, com ponta exata em `(0.24 * w, h)`.
Path construirCaminhoBolhaAlerta(Size size) {
  const alturaCauda = 7.5;
  final alturaCorpo = math.max(14.0, size.height - alturaCauda);
  final raioCanto = math.min(13.0, alturaCorpo * 0.42);

  final caminhoCorpo = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, alturaCorpo),
        Radius.circular(raioCanto),
      ),
    );

  final pontaX = size.width * 0.24;
  final pontaY = size.height;
  final esqBaseX = (pontaX - 3.5).clamp(raioCanto * 0.55, size.width - 12.0);
  final dirBaseX =
      (pontaX + 11.5).clamp(esqBaseX + 6.0, size.width - raioCanto * 0.45);
  final topoInsercaoY = alturaCorpo - 4.0;

  final caminhoCauda = Path()
    ..moveTo(esqBaseX, topoInsercaoY)
    ..lineTo(esqBaseX, alturaCorpo - 0.5)
    ..quadraticBezierTo(
      esqBaseX + 0.4,
      alturaCorpo + alturaCauda * 0.55,
      pontaX,
      pontaY,
    )
    ..quadraticBezierTo(
      pontaX + 5.2,
      alturaCorpo + alturaCauda * 0.42,
      dirBaseX,
      alturaCorpo - 0.5,
    )
    ..lineTo(dirBaseX, topoInsercaoY)
    ..close();

  return Path.combine(PathOperation.union, caminhoCorpo, caminhoCauda);
}

class _PintorBolhaChatVermelha extends CustomPainter {
  const _PintorBolhaChatVermelha();

  @override
  void paint(Canvas canvas, Size size) {
    const alturaCauda = 7.5;
    final alturaCorpo = math.max(14.0, size.height - alturaCauda);
    final caminho = construirCaminhoBolhaAlerta(size);
    final retanguloTotal = Offset.zero & size;

    canvas.drawShadow(caminho, Colors.black.withValues(alpha: 0.72), 7.0, true);
    canvas.drawPath(
      caminho.shift(const Offset(0, 1.5)),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );

    final preenchimento = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF44D3B),
          Color(0xFFD93223),
          Color(0xFFB91E12),
        ],
        stops: [0.0, 0.62, 1.0],
      ).createShader(retanguloTotal)
      ..style = PaintingStyle.fill;
    canvas.drawPath(caminho, preenchimento);

    canvas.save();
    canvas.clipPath(caminho);
    final retBrilho = Rect.fromLTWH(0, 0, size.width, alturaCorpo * 0.52);
    canvas.drawRect(
      retBrilho,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.26),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(retBrilho),
    );
    canvas.restore();

    final borda = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(caminho, borda);
  }

  @override
  bool shouldRepaint(covariant _PintorBolhaChatVermelha oldDelegate) => false;
}

/// Abre o modal estilo Waze perguntando *"Ainda está lá?"* quando o escalador toca na bolha vermelha,
/// oferecendo também ações de editar e excluir quando o alerta foi criado pelo próprio usuário.
Future<void> exibirModalConfirmacaoAlertaVia(
  BuildContext context, {
  required AlertaSegurancaVia alerta,
  EstadoInteracaoAlertaUsuario estadoUsuario =
      EstadoInteracaoAlertaUsuario.podeConfirmar,
  required Future<void> Function(bool aindaEstaLa) aoResponder,
  VoidCallback? aoSolicitarEdicao,
  VoidCallback? aoSolicitarExclusao,
}) {
  final cores = context.colors;
  final subtitulo = FormularioAlertaViaViewModel.formatarSubtituloConfirmacao(
    alerta,
  );
  final citacaoDetalhe = FormularioAlertaViaViewModel.formatarCitacaoDetalhe(
    alerta,
  );

  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: cores.deepBasalt,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (modalCtx) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _corVermelhoAlerta.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: _corVermelhoAlerta, width: 1.5),
                    ),
                    child: Text(
                      alerta.categoria.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alerta.categoria.rotulo,
                          style: TextStyle(
                            color: cores.chalkWhite,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitulo,
                          style: TextStyle(
                            color: cores.ashGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (citacaoDetalhe != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cores.caveShadow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cores.graniteEdge),
                  ),
                  child: Text(
                    citacaoDetalhe,
                    style: TextStyle(
                      color: cores.chalkWhite,
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (estadoUsuario ==
                  EstadoInteracaoAlertaUsuario.requerAutenticacao)
                Container(
                  key: const Key('aviso_login_alerta_via'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cores.caveShadow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cores.graniteEdge),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: cores.rustIron,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          modalCtx.tr(ChaveTexto.alertaEntreParaConfirmar),
                          style: TextStyle(
                            color: cores.ashGrey,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Text(
                  modalCtx.tr(ChaveTexto.alertaAindaEstaLa),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cores.chalkWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('btn_confirmar_alerta_resolvido'),
                        onPressed: () async {
                          Navigator.of(modalCtx).pop();
                          await aoResponder(false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cores.chalkWhite,
                          side: BorderSide(color: cores.graniteEdge),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          modalCtx.tr(ChaveTexto.alertaNaoJaResolveu),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        key: const Key('btn_confirmar_alerta_ativo'),
                        onPressed:
                            estadoUsuario ==
                                EstadoInteracaoAlertaUsuario.podeConfirmar
                            ? () async {
                                Navigator.of(modalCtx).pop();
                                await aoResponder(true);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _corVermelhoAlerta,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: cores.caveShadow,
                          disabledForegroundColor: cores.ashGrey,
                          padding: const EdgeInsets.symmetric(
                            vertical: 13,
                            horizontal: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          switch (estadoUsuario) {
                            EstadoInteracaoAlertaUsuario.criadoPorMim =>
                              modalCtx.tr(
                                ChaveTexto.alertaReportadoPorVoceCheck,
                              ),
                            EstadoInteracaoAlertaUsuario.jaConfirmadoPorMim =>
                              modalCtx.tr(
                                ChaveTexto.alertaConfirmadoPorVoceCheck,
                              ),
                            _ => modalCtx.tr(ChaveTexto.alertaSimAindaEstaLa),
                          },
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                if (estadoUsuario ==
                        EstadoInteracaoAlertaUsuario.criadoPorMim &&
                    (aoSolicitarEdicao != null ||
                        aoSolicitarExclusao != null)) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (aoSolicitarEdicao != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('btn_editar_alerta_modal'),
                            onPressed: () {
                              Navigator.of(modalCtx).pop();
                              aoSolicitarEdicao();
                            },
                            icon: Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: cores.chalkWhite,
                            ),
                            label: Text(
                              modalCtx.tr(ChaveTexto.alertaEditarBtn),
                              style: TextStyle(
                                color: cores.chalkWhite,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: cores.graniteEdge),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      if (aoSolicitarEdicao != null &&
                          aoSolicitarExclusao != null)
                        const SizedBox(width: 10),
                      if (aoSolicitarExclusao != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('btn_excluir_alerta_modal'),
                            onPressed: () {
                              Navigator.of(modalCtx).pop();
                              aoSolicitarExclusao();
                            },
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: _corVermelhoAlerta,
                            ),
                            label: Text(
                              modalCtx.tr(ChaveTexto.alertaExcluirBtn),
                              style: const TextStyle(
                                color: _corVermelhoAlerta,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _corVermelhoAlerta.withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// Abre o modal rápido estilo Waze para reportar um novo alerta de segurança na via.
Future<void> exibirModalReportarAlertaVia(
  BuildContext context, {
  AlertaSegurancaVia? alertaInicial,
  required Future<void> Function(
    CategoriaAlertaSeguranca categoria,
    String? detalhe,
  ) aoReportar,
}) {
  return exibirModalFormularioAlertaVia(
    context,
    alertaInicial: alertaInicial,
    aoSubmeter: aoReportar,
  );
}
