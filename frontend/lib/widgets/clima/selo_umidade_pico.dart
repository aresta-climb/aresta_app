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

