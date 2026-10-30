// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import '../test/caos/fabrica_dataset_caos.dart';

/// Duração da campanha de caos quando executada em dispositivo físico/emulador ou Cloud Device Lab.
const int kDuracaoDispositivoSegundos = int.fromEnvironment(
  'DURACAO_CAMPANHA_CAOS_SEGUNDOS',
  defaultValue: 60,
);

/// Habilita envio ao Sentry durante execução em dispositivo real/emulador.
const bool kReportarSentryDispositivo = bool.fromEnvironment(
  'REPORTAR_SENTRY_CAOS',
  defaultValue: true,
);

/// Semente inicial opcional (`0` gera semente variável a cada execução).
const int kSeedInicialDispositivo = int.fromEnvironment(
  'SEED_INICIAL_CAOS',
  defaultValue: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Robô Caótico em dispositivo/emulador exercita fluxos completos sem crashes',
    (tester) async {
      final ambiente = await AmbienteAppCaos.inicializar();
      try {
        final motor = ambiente.criarMotor(
          tester: tester,
          reportarAoSentry: kReportarSentryDispositivo,
        );

        final seedInicial = kSeedInicialDispositivo != 0
            ? kSeedInicialDispositivo
            : (DateTime.now().millisecondsSinceEpoch % 100000000);

        final relatorio = await motor.executarCampanhaPorTempo(
          duracaoMaxima: const Duration(seconds: kDuracaoDispositivoSegundos),
          maxPassosPorSessao: 25,
          seedInicial: seedInicial,
        );

        if (relatorio.falhasUnicas.isNotEmpty) {
          fail(relatorio.formatarResumoConsolidado());
        }
      } finally {
        await ambiente.limpar();
      }
    },
  );
}
