// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/services/clima/servico_clima_altimetria.dart';

/// Biblioteca `test-only` de Fake determinístico em memória para a fronteira remota
/// de clima regional (RainTracker) e altimetria externa.
class ClienteClimaAltimetriaFake implements FonteRemotaClimaAltimetria {
  SnapshotClimaAltimetria snapshotAtual;
  Object? erroSimulado;
  int totalChamadas = 0;
  int totalChamadasComAltimetria = 0;

  ClienteClimaAltimetriaFake({
    SnapshotClimaAltimetria? snapshotInicial,
    this.erroSimulado,
  }) : snapshotAtual = snapshotInicial ??
            SnapshotClimaAltimetria(
              geradoEm: DateTime.utc(2026, 11, 25),
              bolhasChuva: const [],
              chuvaPorPico: const {},
              altimetriaPorPico: const {},
            );

  @override
  Future<SnapshotClimaAltimetria> buscarSnapshotRemoto({
    bool incluirAltimetria = false,
  }) async {
    totalChamadas++;
    if (incluirAltimetria) {
      totalChamadasComAltimetria++;
    }
    final erro = erroSimulado;
    if (erro != null) {
      throw erro;
    }
    if (!incluirAltimetria) {
      return SnapshotClimaAltimetria(
        geradoEm: snapshotAtual.geradoEm,
        bolhasChuva: snapshotAtual.bolhasChuva,
        bolhasIncendio: snapshotAtual.bolhasIncendio,
        chuvaPorPico: snapshotAtual.chuvaPorPico,
        altimetriaPorPico: const {},
      );
    }
    return snapshotAtual;
  }
}
