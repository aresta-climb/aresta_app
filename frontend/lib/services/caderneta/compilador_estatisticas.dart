// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../data/modelos/cadena.dart';
import '../../data/modelos/tipo_ascensao.dart';
import '../../utils/filtro_grau_escalada.dart';
import 'estatisticas_caderneta.dart';

/// Algoritmo dedicado para compilação analítica e agregação de métricas da caderneta.
///
/// Processa a lista de ascensões, calcula frequências por estilo esportivo, ordena
/// a pirâmide de graduação de acordo com o peso oficial da dificuldade e extrai
/// os maiores graus conquistados em vias e boulders.
abstract final class CompiladorEstatisticasCaderneta {
  /// Compila e consolida uma lista de [cadenas] em uma instância de [EstatisticasCaderneta].
  ///
  /// A função opcional [obterGrauDaVia] recebe o UID de uma escalada e retorna sua graduação
  /// textual oficial no catálogo (ex: '7a', 'V5').
  static EstatisticasCaderneta compilar(
    List<Cadena> cadenas, {
    String? Function(String escaladaUid)? obterGrauDaVia,
  }) {
    if (cadenas.isEmpty) {
      return EstatisticasCaderneta.vazia();
    }

    final contagemEstilo = <TipoAscensao, int>{
      for (final tipo in TipoAscensao.values) tipo: 0,
    };
    final mapaVias = <String, int>{};
    final mapaBoulders = <String, int>{};

    int totalCadenas = 0;
    int totalTentativas = 0;
    int totalAVistaFlash = 0;

    for (final cadena in cadenas) {
      contagemEstilo[cadena.tipoAscensao] =
          (contagemEstilo[cadena.tipoAscensao] ?? 0) + 1;

      if (!cadena.isCadena) {
        totalTentativas++;
        continue;
      }

      totalCadenas++;
      if (cadena.tipoAscensao == TipoAscensao.aVista ||
          cadena.tipoAscensao == TipoAscensao.flash) {
        totalAVistaFlash++;
      }

      final grau = obterGrauDaVia?.call(cadena.escaladaUid);
      if (grau != null && grau.trim().isNotEmpty) {
        final grauLimpo = grau.trim();
        if (cadena.tipoEscalada.isBoulder) {
          mapaBoulders[grauLimpo] = (mapaBoulders[grauLimpo] ?? 0) + 1;
        } else {
          mapaVias[grauLimpo] = (mapaVias[grauLimpo] ?? 0) + 1;
        }
      }
    }

    final piramideViasOrdenada = _ordenarPiramide(mapaVias, _pesoGrauVia);
    final piramideBouldersOrdenada = _ordenarPiramide(
      mapaBoulders,
      _pesoGrauBoulder,
    );

    final maiorVia = piramideViasOrdenada.isNotEmpty
        ? piramideViasOrdenada.keys.last
        : null;
    final maiorBoulder = piramideBouldersOrdenada.isNotEmpty
        ? piramideBouldersOrdenada.keys.last
        : null;

    final taxa = totalCadenas > 0
        ? (totalAVistaFlash / totalCadenas) * 100.0
        : 0.0;

    return EstatisticasCaderneta(
      totalAscensoes: cadenas.length,
      totalCadenas: totalCadenas,
      totalTentativas: totalTentativas,
      contagemPorEstilo: contagemEstilo,
      piramideVias: piramideViasOrdenada,
      piramideBoulders: piramideBouldersOrdenada,
      maiorGrauVia: maiorVia,
      maiorGrauBoulder: maiorBoulder,
      taxaAVistaFlash: taxa,
    );
  }

  static Map<String, int> _ordenarPiramide(
    Map<String, int> mapa,
    int Function(String) pesoFn,
  ) {
    final entradas = mapa.entries.toList()
      ..sort((a, b) {
        final pesoA = pesoFn(a.key);
        final pesoB = pesoFn(b.key);
        if (pesoA != pesoB) {
          return pesoA.compareTo(pesoB);
        }
        return a.key.compareTo(b.key);
      });

    return {for (final e in entradas) e.key: e.value};
  }

  static int _pesoGrauVia(String grau) {
    for (final opcao in OpcoesGrau.grausVia) {
      if (opcao.rotulo.toLowerCase() == grau.toLowerCase()) {
        return opcao.valor;
      }
    }
    final match = RegExp(r'\d+').firstMatch(grau);
    if (match != null) {
      final numero = int.tryParse(match.group(0)!) ?? 0;
      return numero * 100;
    }
    return 0;
  }

  static int _pesoGrauBoulder(String grau) {
    for (final opcao in OpcoesGrau.grausBoulder) {
      if (opcao.rotulo.toLowerCase() == grau.toLowerCase()) {
        return opcao.valor;
      }
    }
    final match = RegExp(r'\d+').firstMatch(grau);
    if (match != null) {
      final numero = int.tryParse(match.group(0)!) ?? 0;
      return numero * 100;
    }
    return 0;
  }
}
