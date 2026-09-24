// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/widgets/banner_modo_online.dart';
import '../mocks/mock_telemetry_service.dart';

void main() {
  late MockTelemetryService mockTelemetria;

  setUp(() {
    mockTelemetria = MockTelemetryService();
    TelemetryService.instance = mockTelemetria;
  });

  group('BannerModoOnline', () {
    testWidgets('exibe modo online e botão de salvar offline', (tester) async {
      bool clicouSalvar = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BannerModoOnline(
              tamanhoFormatado: '18.4 MB',
              isDownloaded: false,
              progressoDownload: null,
              onSalvarOffline: () {
                clicouSalvar = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('MODO ONLINE'), findsOneWidget);
      expect(find.text('Salvar Offline (18.4 MB)'), findsOneWidget);

      await tester.tap(find.text('Salvar Offline (18.4 MB)'));
      expect(clicouSalvar, isTrue);
    });

    testWidgets('exibe Salvar Offline sem parenteses quando tamanhoFormatado for nulo ou 0 B', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BannerModoOnline(
              tamanhoFormatado: null,
              isDownloaded: false,
              progressoDownload: null,
              onSalvarOffline: () {},
            ),
          ),
        ),
      );

      expect(find.text('Salvar Offline'), findsOneWidget);
    });

    testWidgets('exibe progresso quando download estiver ativo', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BannerModoOnline(
              tamanhoFormatado: '18.4 MB',
              isDownloaded: false,
              progressoDownload: 0.45,
              onSalvarOffline: () {},
            ),
          ),
        ),
      );

      expect(find.text('BAIXANDO (45%)...'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('exibe estado salvo offline quando isDownloaded for true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BannerModoOnline(
              tamanhoFormatado: '18.4 MB',
              isDownloaded: true,
              progressoDownload: null,
              onSalvarOffline: () {},
            ),
          ),
        ),
      );

      expect(find.text('SALVO OFFLINE'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('dispara telemetria banner_modo_online ao salvar com cragId informado', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BannerModoOnline(
              cragId: 'crag_banner_teste',
              tamanhoFormatado: '18.4 MB',
              isDownloaded: false,
              progressoDownload: null,
              onSalvarOffline: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Salvar Offline (18.4 MB)'));
      await tester.pumpAndSettle();

      expect(mockTelemetria.recordedEvents, contains('banner_modo_online'));
      final params = mockTelemetria.recordedParams['banner_modo_online']!;
      expect(params['id_croqui'], 'crag_banner_teste');
      expect(params['acao'], 'banner_salvar_offline');
      expect(params['origem'], 'banner_online');
      expect(params['modo_acesso'], 'online');
    });
  });
}
