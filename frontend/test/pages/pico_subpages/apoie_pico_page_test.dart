// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/pages/pico_subpages/apoie_pico_page.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/utils/pico_categorization.dart';
import '../../mocks/mock_telemetry_service.dart';

void main() {
  late MockTelemetryService mockTelemetria;

  setUp(() {
    mockTelemetria = MockTelemetryService();
    TelemetryService.instance = mockTelemetria;
  });

  Widget criarWidgetTeste({
    required Pico pico,
    required String cragId,
  }) {
    return MaterialApp(
      theme: ThemeData(
        extensions: const [AppColors.dark],
      ),
      home: ApoiePicoPage(
        pico: pico,
        cragId: cragId,
        categories: PicoCategorizedData(Croqui()),
      ),
    );
  }

  group('ApoiePicoPage - Telemetria e Interações', () {
    testWidgets('exibe card do PIX quando pico possui chavePixManutencao e dispara telemetria ao tocar', (tester) async {
      final pico = Pico()
        ..nome = 'Falésia dos Olhos'
        ..chavePixManutencao = 'pix@falesia.org';

      await tester.pumpWidget(criarWidgetTeste(pico: pico, cragId: 'falesia_olhos'));
      await tester.pumpAndSettle();

      expect(find.text('Doação via Pix'), findsOneWidget);
      expect(find.textContaining('pix@falesia.org'), findsOneWidget);

      await tester.tap(find.text('Doação via Pix'));
      await tester.pumpAndSettle();

      expect(find.text('Chave PIX copiada para a área de transferência!'), findsOneWidget);

      expect(mockTelemetria.recordedEvents, contains('apoio_pico'));
      final parametros = mockTelemetria.recordedParams['apoio_pico']!;
      expect(parametros['id_croqui'], equals('falesia_olhos'));
      expect(parametros['acao'], equals('copiar_pix'));
      expect(parametros['origem'], equals('apoie_pico'));
    });
  });
}
