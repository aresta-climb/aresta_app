// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import '../../idioma/tradutor_app.dart';

/// Estado discreto e conservador de umidade superficial da rocha (janela de 4 dias
/// reiniciada a cada chuva regional próxima ao pico).
enum NivelUmidadePico {
  seco(peso: 0),
  possivelmenteUmido(peso: 1);

  /// Peso numérico crescente de severidade hídrica usado em comparações de dominância.
  final int peso;

  const NivelUmidadePico({required this.peso});

  /// Nome localizado apresentado nos avisos conservadores de picos com chuva próxima.
  String get rotulo => switch (this) {
        NivelUmidadePico.seco => tr(ChaveTexto.climaSeco),
        NivelUmidadePico.possivelmenteUmido =>
          tr(ChaveTexto.climaPossivelmenteUmido),
      };

  /// Verdadeiro quando houve chuva próxima na região dentro da janela conservadora de 4 dias.
  bool get estaUmido => this != NivelUmidadePico.seco;
}

/// Quatro níveis visuais de intensidade de precipitação ao vivo no radar do globo,
/// acionados pela análise hidrometeorológica (`mm/h` e células convectivas internas).
enum NivelIntensidadeChuva {
  fraca(peso: 1),
  moderada(peso: 2),
  forte(peso: 3),
  extrema(peso: 4);

  /// Peso ordinal (`1..4`) usado para escalar contraste cromático, gotas e trovoadas.
  final int peso;

  const NivelIntensidadeChuva({required this.peso});

  /// Rótulo localizado da faixa de intensidade da precipitação ao vivo.
  String get rotulo => switch (this) {
        NivelIntensidadeChuva.fraca => tr(ChaveTexto.climaChuvaFraca),
        NivelIntensidadeChuva.moderada => tr(ChaveTexto.climaChuvaModerada),
        NivelIntensidadeChuva.forte => tr(ChaveTexto.climaChuvaForte),
        NivelIntensidadeChuva.extrema => tr(ChaveTexto.climaTempestadeSevera),
      };
}

/// Vértice geográfico `(longitude, latitude)` pertencente à isoieta real de uma tempestade ou perímetro de incêndio.
class PontoContornoGeo {
  final double longitude;
  final double latitude;

  const PontoContornoGeo({
    required this.longitude,
    required this.latitude,
  });

  factory PontoContornoGeo.deLista(List<dynamic> par) {
    if (par.length < 2 || par[0] is! num || par[1] is! num) {
      throw const FormatException('PontoContornoGeo inválido.');
    }
    final lon = (par[0] as num).toDouble();
    final lat = (par[1] as num).toDouble();
    if (!lon.isFinite ||
        !lat.isFinite ||
        lat < -90.0 ||
        lat > 90.0 ||
        lon < -180.0 ||
        lon > 180.0) {
      throw const FormatException(
        'Coordenadas fora dos limites em PontoContornoGeo.',
      );
    }
    return PontoContornoGeo(longitude: lon, latitude: lat);
  }

  List<double> paraLista() => <double>[longitude, latitude];
}

/// Pegada geográfica histórica (`horasAtras` antes do instante atual) por onde a tempestade passou.
class RastroPassadoTempestade {
  final int horasAtras;
  final List<PontoContornoGeo> contorno;

  const RastroPassadoTempestade({
    required this.horasAtras,
    required this.contorno,
  });

