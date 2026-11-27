// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../idioma/tradutor_app.dart';
import '../../navigation/funcoes_navegacao.dart';
import '../../theme/cores_app.dart';

/// Exibe o modal centralizado no padrão visual do Aresta Climb informando a taxa
/// empírica de detecção (~85%) e as 6 fontes utilizadas antes de habilitar a camada de clima e fogo.
Future<bool> exibirDialogoAvisoPrecisaoClima(BuildContext context) async {
  final confirmado = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => const DialogoAvisoPrecisaoClima(),
  );
  return confirmado ?? false;
}

/// Modal declarativo (Dumb UI) alinhado à identidade basalto/ferrugem do Aresta Climb,
/// exibindo as fontes específicas, medidor estatístico (~85%) e atalho para a página de estatísticas.
class DialogoAvisoPrecisaoClima extends StatelessWidget {
  const DialogoAvisoPrecisaoClima({super.key});

  @override
  Widget build(BuildContext context) {
    context.idiomaApp;
    final cores = context.colors;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 356),
        child: Container(
          key: const Key('dialogo_aviso_precisao_clima'),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          decoration: BoxDecoration(
            color: cores.deepBasalt,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cores.graniteEdge, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0xBD000000),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cores.rustIron.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cores.rustIron.withValues(alpha: 0.42),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    Icons.radar_rounded,
                    size: 22,
                    color: cores.rustIron,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  tr(ChaveTexto.explorarAvisoClimaTitulo).toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: cores.chalkWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cores.caveShadow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cores.graniteEdge),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 16,
                        color: cores.rustIron,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '~85%',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          color: cores.chalkWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: Container(
                            height: 6,
                            color: cores.graniteEdge,
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: 0.85,
                              child: Container(color: cores.rustIron),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  tr(ChaveTexto.explorarAvisoClimaCorpo),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cores.ashGrey,
                    fontSize: 12,
                    height: 1.36,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const Key('botao_confirmar_aviso_clima'),
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(
                      Icons.layers_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      tr(ChaveTexto.explorarAvisoClimaConfirmar),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cores.rustIron,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('botao_ver_estatisticas_clima'),
                    onPressed: () {
                      final navegador = Navigator.of(context);
                      navegador.pop(false);
                      AppNav.toEstatisticasClima(navegador.context);
                    },
                    icon: Icon(
                      Icons.query_stats_rounded,
                      color: cores.chalkWhite,
                      size: 17,
                    ),
                    label: Text(
                      tr(ChaveTexto.explorarBotaoVerEstatisticasClima),
                      style: TextStyle(
                        color: cores.chalkWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: cores.caveShadow,
                      side: BorderSide(color: cores.graniteEdge),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    key: const Key('botao_cancelar_aviso_clima'),
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      tr(ChaveTexto.comumCancelar),
                      style: TextStyle(
                        color: cores.ashGrey,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão em cápsula posicionado na seção `Mapa` da aba `Explorar` para ligar ou desligar
/// opcionalmente as bolhas de chuva e incêndio (iniciando sempre desligado ao abrir a página).
class BotaoCamadaClimaMapa extends StatelessWidget {
  /// Indica se a camada opcional de chuva/fogo está ativa no mapa.
  final bool ativo;

  /// Callback acionado quando o usuário ativa (após confirmar o aviso) ou desativa a camada.
  final ValueChanged<bool> aoAlterarAtivo;

  const BotaoCamadaClimaMapa({
    super.key,
    required this.ativo,
    required this.aoAlterarAtivo,
  });

  Future<void> _aoTocar(BuildContext context) async {
    if (ativo) {
      aoAlterarAtivo(false);
      return;
    }
    final confirmado = await exibirDialogoAvisoPrecisaoClima(context);
    if (confirmado) {
      aoAlterarAtivo(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.idiomaApp;
    final cores = context.colors;
    final corBorda = ativo
        ? cores.rustIron.withValues(alpha: 0.85)
        : Colors.white12;
    final corFundo = ativo
        ? const Color(0xEB221614)
        : const Color(0xCC10141A);
    final corIcone = ativo ? cores.rustIron : const Color(0xFF9CA3AF);
    final corTexto = ativo ? cores.chalkWhite : const Color(0xFFD1D5DB);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('botao_camada_clima_mapa'),
        borderRadius: BorderRadius.circular(20),
        onTap: () => _aoTocar(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: corFundo,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: corBorda, width: ativo ? 1.25 : 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ativo
                    ? Icons.thunderstorm_rounded
                    : Icons.thunderstorm_outlined,
                size: 14,
                color: corIcone,
              ),
              const SizedBox(width: 6),
              Text(
                tr(ChaveTexto.explorarBotaoClimaMapa),
                style: TextStyle(
                  color: corTexto,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: ativo ? cores.rustIron : const Color(0xFF6B7280),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
