// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../data/modelos/modelos_clima_pico.dart';

/// Calculadora determinística e sem estado da janela conservadora de 4 dias dos picos
/// (reiniciada sempre que há chuva sobre a região) e da elegibilidade das bolhas ao vivo no mapa.
abstract final class CalculadoraUmidadePico {
  /// Validade máxima de um snapshot de radar ao vivo antes de expirar em modo offline prolongado.
  static const Duration validadeMaximaRadarAoVivo = Duration(hours: 6);

  /// Validade máxima de focos termais de satélite (`VIIRS`/`MODIS` diários) em modo offline.
  static const Duration validadeMaximaIncendioAoVivo = Duration(hours: 24);

  /// Taxa mínima (`mm/h`) para considerar precipitação ativa em curso no radar do globo.
  static const double limiarChuvaAoVivoMmHora = 0.15;

  /// Limiar mínimo diário (`mm`) para que qualquer chuva na região reinicie o contador de 4 dias.
  static const double limiarChuvaRegionalMm = 0.2;

  /// Janela conservadora fixa (em dias) após qualquer episódio de chuva sobre a região do pico.
  static const int janelaConservadoraDias = 4;

  /// Avalia o estado conservador vigente hoje para um único evento de chuva na região do pico.
  ///
  /// Qualquer precipitação regional `>= 0.2 mm` ocorrida nos últimos 4 dias civis
  /// (`0 <= diasDecorridos < 4`) classifica o pico como [NivelUmidadePico.possivelmenteUmido]
  /// com contagem regressiva `4 - diasDecorridos` dias.
  static EstadoUmidadePico avaliarEventoUnico({
    required double milimetros,
    required DateTime dataChuva,
    required DateTime dataReferencia,
    String? bolhaId,
  }) {
    if (milimetros < limiarChuvaRegionalMm) {
      return const EstadoUmidadePico.seco();
    }

    final inicioChuva =
        DateTime.utc(dataChuva.year, dataChuva.month, dataChuva.day);
    final refDia = DateTime.utc(
      dataReferencia.year,
      dataReferencia.month,
      dataReferencia.day,
    );
    final diasDecorridos = refDia.difference(inicioChuva).inDays;
    if (diasDecorridos < 0 || diasDecorridos >= janelaConservadoraDias) {
      return const EstadoUmidadePico.seco();
    }

    return EstadoUmidadePico(
      nivel: NivelUmidadePico.possivelmenteUmido,
      diasParaSecar: janelaConservadoraDias - diasDecorridos,
      diasDesdeChuva: diasDecorridos,
      dataUltimaChuva: inicioChuva,
      milimetrosEvento: milimetros,
      bolhaIdAssociada: bolhaId,
    );
  }

  /// Avalia o histórico recente de chuva regional do pico, reiniciando o contador de 4 dias
  /// e a referência de chuva próxima sempre que houver um evento válido mais recente.
  static EstadoUmidadePico avaliarHistoricoPico({
    required List<EventoChuvaPico> eventos,
    required DateTime dataReferencia,
  }) {
    EstadoUmidadePico vigente = const EstadoUmidadePico.seco();
    for (final ev in eventos) {
      final avaliado = avaliarEventoUnico(
        milimetros: ev.milimetros,
        dataChuva: ev.data,
        dataReferencia: dataReferencia,
        bolhaId: ev.bolhaId,
      );
      if (_devePrevalecer(avaliado, vigente)) {
        vigente = avaliado;
      }
    }
    return vigente;
  }

  /// Filtra apenas as tempestades que estão chovendo ao vivo (`>= 0.15 mm/h`) dentro da janela válida.
  static List<BolhaAtivaRenderizavel> filtrarBolhasAtivas({
    required List<BolhaChuvaRegional> bolhas,
    required DateTime geradoEm,
    required DateTime dataReferencia,
  }) {
    final idade = dataReferencia.toUtc().difference(geradoEm.toUtc());
    if (idade > validadeMaximaRadarAoVivo) {
      return const [];
    }

    final resultado = <BolhaAtivaRenderizavel>[];
    for (final bolha in bolhas) {
      if (bolha.intensidadeMmHora < limiarChuvaAoVivoMmHora) continue;
      resultado.add(
        BolhaAtivaRenderizavel(
          bolha: bolha,
          nivelIntensidade: bolha.nivelIntensidade,
        ),
      );
    }
    return resultado;
  }

  /// Filtra os perímetros de incêndio florestal vigentes dentro da janela de 24 horas do satélite.
  static List<BolhaIncendioAtivaRenderizavel> filtrarIncendiosAtivos({
    required List<BolhaIncendioRegional> incendios,
    required DateTime geradoEm,
    required DateTime dataReferencia,
  }) {
    final idade = dataReferencia.toUtc().difference(geradoEm.toUtc());
    if (idade > validadeMaximaIncendioAoVivo) {
      return const [];
    }
    return incendios
        .map((f) => BolhaIncendioAtivaRenderizavel(incendio: f))
        .toList(growable: false);
  }

  static bool _devePrevalecer(EstadoUmidadePico candidato, EstadoUmidadePico atual) {
    if (candidato.nivel.peso != atual.nivel.peso) {
      return candidato.nivel.peso > atual.nivel.peso;
    }
    if (candidato.diasParaSecar != atual.diasParaSecar) {
      return candidato.diasParaSecar > atual.diasParaSecar;
    }
    return candidato.milimetrosEvento > atual.milimetrosEvento;
  }
}
