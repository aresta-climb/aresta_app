// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../data/modelos/cadena.dart';
import '../../data/modelos/tipo_ascensao.dart';
import '../../utils/filtro_grau_escalada.dart';

/// Consolidação analítica e métricas de desempenho esportivo da caderneta do escalador.
///
/// Apresenta dados agregados de ascensões, taxas de encadenamento rápido (À Vista e Flash)
/// e a distribuição em pirâmide de graduação para vias de falésia e blocos de boulder.
class EstatisticasCaderneta {
  /// Quantidade total de registros efetuados (cadenas e tentativas combinadas).
  final int totalAscensoes;

  /// Quantidade de vias ou boulders encadenados com sucesso ([TipoAscensao.isCadena] == true).
  final int totalCadenas;

  /// Quantidade de tentativas sem cadena registradas.
  final int totalTentativas;

  /// Distribuição das ascensões agrupadas por cada estilo esportivo.
  final Map<TipoAscensao, int> contagemPorEstilo;

  /// Pirâmide de graduação de vias (grau formatado -> quantidade de cadenas),
  /// ordenada do grau mais fácil para o mais desafiador.
  final Map<String, int> piramideVias;

  /// Pirâmide de graduação de boulders (grau V -> quantidade de cadenas),
  /// ordenada do grau mais fácil para o mais desafiador.
  final Map<String, int> piramideBoulders;

  /// Maior grau conquistado em via com sucesso.
  final String? maiorGrauVia;

  /// Maior grau conquistado em boulder com sucesso.
  final String? maiorGrauBoulder;

  /// Porcentagem de cadenas conquistadas no primeiro contato (À Vista + Flash)
  /// em relação ao total de cadenas conquistadas (0.0 a 100.0%).
  final double taxaAVistaFlash;

  /// Construtor imutável com todos os campos de estatística esportiva.
  const EstatisticasCaderneta({
    required this.totalAscensoes,
    required this.totalCadenas,
    required this.totalTentativas,
    required this.contagemPorEstilo,
    required this.piramideVias,
    required this.piramideBoulders,
    this.maiorGrauVia,
    this.maiorGrauBoulder,
    required this.taxaAVistaFlash,
  });

  /// Cria uma instância zerada para quando não houver ascensões registradas.
  factory EstatisticasCaderneta.vazia() => const EstatisticasCaderneta(
        totalAscensoes: 0,
        totalCadenas: 0,
        totalTentativas: 0,
        contagemPorEstilo: {},
        piramideVias: {},
        piramideBoulders: {},
        maiorGrauVia: null,
        maiorGrauBoulder: null,
        taxaAVistaFlash: 0.0,
      );

  /// Processa a lista de [cadenas] e compila as estatísticas consolidadas.
  ///
  /// O parâmetro opcional [resolvedorGrau] permite resolver o grau oficial da via
  /// a partir de seu `escaladaUid` (por exemplo, consultando o catálogo do dataset).
  factory EstatisticasCaderneta.calcular(
    List<Cadena> cadenas, {
    String? Function(String escaladaUid)? resolvedorGrau,
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

      final grau = resolvedorGrau?.call(cadena.escaladaUid);
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
    final piramideBouldersOrdenada =
        _ordenarPiramide(mapaBoulders, _pesoGrauBoulder);

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
    // Fallback numérico simples para graus não mapeados
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

  /// Retorna uma cópia das estatísticas com campos seletivamente substituídos.
  EstatisticasCaderneta copyWith({
    int? totalAscensoes,
    int? totalCadenas,
    int? totalTentativas,
    Map<TipoAscensao, int>? contagemPorEstilo,
    Map<String, int>? piramideVias,
    Map<String, int>? piramideBoulders,
    String? maiorGrauVia,
    String? maiorGrauBoulder,
    double? taxaAVistaFlash,
  }) {
    return EstatisticasCaderneta(
      totalAscensoes: totalAscensoes ?? this.totalAscensoes,
      totalCadenas: totalCadenas ?? this.totalCadenas,
      totalTentativas: totalTentativas ?? this.totalTentativas,
      contagemPorEstilo: contagemPorEstilo ?? this.contagemPorEstilo,
      piramideVias: piramideVias ?? this.piramideVias,
      piramideBoulders: piramideBoulders ?? this.piramideBoulders,
      maiorGrauVia: maiorGrauVia ?? this.maiorGrauVia,
      maiorGrauBoulder: maiorGrauBoulder ?? this.maiorGrauBoulder,
      taxaAVistaFlash: taxaAVistaFlash ?? this.taxaAVistaFlash,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EstatisticasCaderneta) return false;

    if (other.totalAscensoes != totalAscensoes ||
        other.totalCadenas != totalCadenas ||
        other.totalTentativas != totalTentativas ||
        other.maiorGrauVia != maiorGrauVia ||
        other.maiorGrauBoulder != maiorGrauBoulder ||
        (other.taxaAVistaFlash - taxaAVistaFlash).abs() > 0.001) {
      return false;
    }

    if (other.piramideVias.length != piramideVias.length) return false;
    for (final key in piramideVias.keys) {
      if (other.piramideVias[key] != piramideVias[key]) return false;
    }

    if (other.piramideBoulders.length != piramideBoulders.length) return false;
    for (final key in piramideBoulders.keys) {
      if (other.piramideBoulders[key] != piramideBoulders[key]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
        totalAscensoes,
        totalCadenas,
        totalTentativas,
        maiorGrauVia,
        maiorGrauBoulder,
        taxaAVistaFlash.round(),
      );

  @override
  String toString() {
    return 'EstatisticasCaderneta(totalAscensoes: $totalAscensoes, totalCadenas: $totalCadenas, maiorVia: $maiorGrauVia, maiorBoulder: $maiorGrauBoulder)';
  }
}
