// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';

import 'cliente_clima_altimetria_fake.dart';

void main() {
  group('ClienteClimaAltimetriaFake', () {
    test(
      'deve inicializar com snapshot vazio padrao ou retornar o snapshot configurado contabilizando chamadas',
      () async {
        final fakePadrao = ClienteClimaAltimetriaFake();
        final vazio = await fakePadrao.buscarSnapshotRemoto();
        expect(vazio.bolhasChuva, isEmpty);
        expect(fakePadrao.totalChamadas, equals(1));

        final esperado = SnapshotClimaAltimetria(
          geradoEm: DateTime.utc(2026, 11, 25, 12),
          bolhasChuva: const [],
          chuvaPorPico: const {},
          altimetriaPorPico: const {
            'urca': CotaAltimetricaPico(
              altitudeBaseMetros: 12,
              altitudePicoMetros: 396,
            ),
          },
        );
        final fake = ClienteClimaAltimetriaFake(snapshotInicial: esperado);

        final apenasClima = await fake.buscarSnapshotRemoto();
        expect(fake.totalChamadas, equals(1));
        expect(fake.totalChamadasComAltimetria, equals(0));
        expect(apenasClima.altimetriaPorPico, isEmpty);

        final recebido = await fake.buscarSnapshotRemoto(
          incluirAltimetria: true,
        );
        expect(fake.totalChamadas, equals(2));
        expect(fake.totalChamadasComAltimetria, equals(1));
        expect(
          recebido.altimetriaPorPico['urca']!.altitudePicoMetros,
          equals(396),
        );
      },
    );

    test(
      'deve lancar erro configurado para simular indisponibilidade externa de forma deterministica',
      () async {
        final fake = ClienteClimaAltimetriaFake(
          erroSimulado: StateError('Supabase/NASA indisponivel'),
        );

        await expectLater(fake.buscarSnapshotRemoto(), throwsStateError);
        expect(fake.totalChamadas, equals(1));
      },
    );
  });
}
