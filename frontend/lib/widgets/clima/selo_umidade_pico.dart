// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../data/modelos/modelos_clima_pico.dart';
import '../../idioma/tradutor_app.dart';

/// Paleta semântica conservadora para a condição hídrica estimada do pico,
/// distinguindo `Possivelmente úmido` (janela cautelar azul-ciano/âmbar de 4 dias)
/// e `Seco` (esmeralda discreto).
abstract final class PaletaUmidadePico {
  /// Cor terracota institucional dos pontos Aresta recolhidos no mapa.
  static const Color corPontoArestaPadrao = Color(0xFFE27D60);

  /// Duração total (em dias) da janela conservadora exibida na barra visual do pico.
  static const int totalDiasJanelaConservadora = 4;

  /// Cor vibrante de destaque usada em indicadores circulares e ícones no mapa.
  static Color corDestaque(NivelUmidadePico nivel) {
    return switch (nivel) {
      NivelUmidadePico.possivelmenteUmido => const Color(0xFF38BDF8),
      NivelUmidadePico.seco => const Color(0xFF22C55E),
    };
  }

  /// Cor de superfície escura saturada (alta opacidade para evitar sangramento de sombras).
  static Color corFundo(NivelUmidadePico nivel) {
    return switch (nivel) {
      NivelUmidadePico.possivelmenteUmido => const Color(0xF20B2536),
      NivelUmidadePico.seco => const Color(0xF20D2B1D),
    };
  }

  /// Cor da borda da tarja, cartão ou pílula expandida.
  static Color corBorda(NivelUmidadePico nivel) {
    return switch (nivel) {
      NivelUmidadePico.possivelmenteUmido => const Color(0xB838BDF8),
      NivelUmidadePico.seco => const Color(0x994ADE80),
    };
  }

  /// Cor clara de alto contraste para o texto principal dentro da tarja ou cartão.
  static Color corTexto(NivelUmidadePico nivel) {
    return switch (nivel) {
      NivelUmidadePico.possivelmenteUmido => const Color(0xFFE0F2FE),
      NivelUmidadePico.seco => const Color(0xFFDCFCE7),
    };
  }

  /// Ícone meteorológico distinto para cada estado conservador (não depende apenas de cor).
  static IconData icone(NivelUmidadePico nivel) {
    return switch (nivel) {
      NivelUmidadePico.possivelmenteUmido => Icons.water_drop_rounded,
      NivelUmidadePico.seco => Icons.wb_sunny_rounded,
    };
  }

  /// Formata a contagem regressiva de dias (`1 dia` / `4 dias`) no idioma ativo.
  static String formatarContagemDias(int dias) {
    final seguro = dias < 1 ? 1 : dias;
    if (seguro == 1) {
      return tr(ChaveTexto.climaContagemUmDia);
    }
    return tr(ChaveTexto.climaContagemDias, {'dias': seguro});
  }

  /// Formata o complemento `"chuva próxima hoje (DD/MM)"` ou `"chuva próxima há X dias (DD/MM)"`.
  static String? formatarDetalheChuvaProxima(EstadoUmidadePico umidade) {
    final dataCurta = umidade.dataChuvaFormatadaCurta;
    if (dataCurta == null) return null;
    final diasAtras = umidade.diasDesdeChuva < 0 ? 0 : umidade.diasDesdeChuva;
    if (diasAtras == 0) {
      return tr(ChaveTexto.climaChuvaProximaHoje, {'data': dataCurta});
    }
    if (diasAtras == 1) {
      return tr(ChaveTexto.climaChuvaProximaUmDia, {'data': dataCurta});
    }
    return tr(
      ChaveTexto.climaChuvaProximaDias,
      {'dias': diasAtras, 'data': dataCurta},
    );
  }

  /// Formata o aviso conservador completo: `"Possivelmente úmido (4 dias) - chuva próxima ..."`.
  static String formatarResumo(EstadoUmidadePico umidade) {
    if (!umidade.nivel.estaUmido) {
      return tr(ChaveTexto.climaRochaSecaSemChuva);
    }
    final cabecalho =
        '${umidade.nivel.rotulo} (${formatarContagemDias(umidade.diasParaSecar)})';
    final detalheChuva = formatarDetalheChuvaProxima(umidade);
    if (detalheChuva == null) {
      return cabecalho;
    }
    return '$cabecalho - $detalheChuva';
  }
}

/// Tarja declarativa compacta (Dumb UI) de condição hídrica exibida nos cards da gaveta `Explorar`.
class TarjaUmidadePico extends StatelessWidget {
  /// Estado conservador calculado de umidade do pico.
  final EstadoUmidadePico umidade;

  /// Quando `true`, renderiza também o estado conservador seco.
  final bool exibirQuandoSeco;

  /// Margem externa opcional da tarja.
  final EdgeInsetsGeometry? margem;

  /// Cria uma instância de [TarjaUmidadePico].
  const TarjaUmidadePico({
    super.key,
    required this.umidade,
    this.exibirQuandoSeco = false,
    this.margem,
  });

  @override
  Widget build(BuildContext context) {
    context.idiomaApp;
    final nivel = umidade.nivel;
    if (!nivel.estaUmido && !exibirQuandoSeco) {
      return const SizedBox.shrink();
    }

    final corTexto = PaletaUmidadePico.corTexto(nivel);
    final corDestaque = PaletaUmidadePico.corDestaque(nivel);

    return Container(
      width: double.infinity,
      margin: margem,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: PaletaUmidadePico.corFundo(nivel),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PaletaUmidadePico.corBorda(nivel)),
      ),
      child: Row(
        children: [
          Icon(
            PaletaUmidadePico.icone(nivel),
            size: 15,
            color: corDestaque,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              PaletaUmidadePico.formatarResumo(umidade),
              style: TextStyle(
                color: corTexto,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cartão expandido (Dumb UI) para a `PicoDetailsPage`, apresentando o contador conservador
/// de 4 dias reiniciado a cada chuva regional próxima e a nota explícita de estimativa.
class CartaoCondicaoHidricaPico extends StatelessWidget {
  /// Estado conservador vigente do pico.
  final EstadoUmidadePico umidade;

  /// Margem externa opcional do cartão.
  final EdgeInsetsGeometry? margem;

