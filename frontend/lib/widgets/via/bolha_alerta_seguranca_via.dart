// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../data/modelos/interacao_via.dart';
import '../../theme/cores_app.dart';
import '../../view/view_models/formulario_alerta_via_view_model.dart';

/// Cor vermelha de alta visibilidade usada nas bolhas de alerta estilo Waze sobre rocha e cartões escuros.
const Color _corVermelhoAlerta = Color(0xFFD93829);

/// Conjunto compacto de bolhas vermelhas em formato de balão de fala com emojis de risco (`🐝`, `🪨`, `🔩`, `💧`, `⚠️`),
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
      label: 'Alerta: ${alerta.categoria.rotulo}',
      child: GestureDetector(
        onTap: aoTocar,
        child: CustomPaint(
          painter: _PintorBolhaChatVermelha(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(11, 7, 11, 13),
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

class _PintorBolhaChatVermelha extends CustomPainter {
  const _PintorBolhaChatVermelha();

  @override
  void paint(Canvas canvas, Size size) {
    const alturaCauda = 6.0;
    final alturaCorpo = size.height - alturaCauda;
    final raio = alturaCorpo / 2;

    final caminho = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, alturaCorpo),
          Radius.circular(raio),
        ),
      )
      ..moveTo(size.width * 0.34, alturaCorpo - 1)
      ..lineTo(size.width * 0.24, size.height)
      ..lineTo(size.width * 0.52, alturaCorpo - 1)
      ..close();

    canvas.drawShadow(caminho, Colors.black.withValues(alpha: 0.65), 6, true);

    final preenchimento = Paint()
      ..color = _corVermelhoAlerta
      ..style = PaintingStyle.fill;
    canvas.drawPath(caminho, preenchimento);

    final borda = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(caminho, borda);
  }

  @override
  bool shouldRepaint(covariant _PintorBolhaChatVermelha oldDelegate) => false;
}

/// Abre o modal estilo Waze perguntando *"Ainda está lá?"* quando o escalador toca na bolha vermelha.
Future<void> exibirModalConfirmacaoAlertaVia(
  BuildContext context, {
  required AlertaSegurancaVia alerta,
  required Future<void> Function(bool aindaEstaLa) aoResponder,
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
                          'Reportado por ${alerta.autorNomePublico} em $dia/$mes • ${alerta.confirmacoesAtivas}x confirmado',
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
              if (alerta.detalhe != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cores.caveShadow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cores.graniteEdge),
                  ),
                  child: Text(
                    '“${alerta.detalhe}”',
                    style: TextStyle(
                      color: cores.chalkWhite,
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Ainda está lá?',
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
                      child: const Text(
                        'Não, já resolveu',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      key: const Key('btn_confirmar_alerta_ativo'),
                      onPressed: () async {
                        Navigator.of(modalCtx).pop();
                        await aoResponder(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _corVermelhoAlerta,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Sim, ainda está lá',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
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
  required Future<void> Function(
    CategoriaAlertaSeguranca categoria,
    String? detalhe,
  ) aoReportar,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: context.colors.deepBasalt,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (modalCtx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
        ),
        child: _FormularioReportarAlertaVia(aoReportar: aoReportar),
      );
    },
  );
}

class _FormularioReportarAlertaVia extends StatefulWidget {
  final Future<void> Function(
    CategoriaAlertaSeguranca categoria,
    String? detalhe,
  ) aoReportar;

  const _FormularioReportarAlertaVia({required this.aoReportar});

  @override
  State<_FormularioReportarAlertaVia> createState() =>
      _FormularioReportarAlertaViaState();
}

class _FormularioReportarAlertaViaState
    extends State<_FormularioReportarAlertaVia> {
  CategoriaAlertaSeguranca _categoriaSelecionada =
      CategoriaAlertaSeguranca.abelhasInsetos;
  final TextEditingController _detalheController = TextEditingController();

  @override
  void dispose() {
    _detalheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Reportar Alerta na Via',
              style: TextStyle(
                color: cores.chalkWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Avise outros escaladores sobre riscos imediatos nesta linha.',
              style: TextStyle(color: cores.ashGrey, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CategoriaAlertaSeguranca.values.map((cat) {
                final selecionado = cat == _categoriaSelecionada;
                return InkWell(
                  key: Key('opcao_alerta_${cat.codigoBanco}'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _categoriaSelecionada = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selecionado
                          ? _corVermelhoAlerta.withValues(alpha: 0.18)
                          : cores.caveShadow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selecionado
                            ? _corVermelhoAlerta
                            : cores.graniteEdge,
                        width: selecionado ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            cat.rotulo,
                            style: TextStyle(
                              color: cores.chalkWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Text(
              _categoriaSelecionada.descricaoCurta,
              style: TextStyle(color: cores.ashGrey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('campo_detalhe_alerta_via'),
              controller: _detalheController,
              maxLength: AlertaSegurancaVia.limiteCaracteresDetalhe,
              style: TextStyle(color: cores.chalkWhite, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Detalhe rápido (opcional)',
                labelStyle: TextStyle(color: cores.ashGrey),
                hintText: 'Ex.: Colmeia próxima à 3ª costura',
                hintStyle: TextStyle(color: cores.ashGrey.withValues(alpha: 0.6)),
                filled: true,
                fillColor: cores.caveShadow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cores.graniteEdge),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              key: const Key('btn_enviar_alerta_via'),
              onPressed: () async {
                final detalhe = _detalheController.text.trim();
                Navigator.of(context).pop();
                await widget.aoReportar(
                  _categoriaSelecionada,
                  detalhe.isNotEmpty ? detalhe : null,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _corVermelhoAlerta,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Enviar Alerta',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
