// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/firebase/remote_config_service.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:feedback/feedback.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/widgets/modal_beta_aberto.dart';
import '../mocks/mock_app_logger.dart';
import '../mocks/mock_telemetry_service.dart';

class FakeRemoteConfigService extends Fake implements RemoteConfigService {
  String url = 'https://chat.whatsapp.com/JmxWeLSmGTT66AREtrKyjA';

  @override
  String get whatsappCommunityUrl => url;
}

class MockUrlLauncherPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  bool shouldThrow = false;
  String? lastLaunchedUrl;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    if (shouldThrow) {
      throw Exception('Falha ao abrir URL nativa');
    }
    return true;
  }
}

void main() {
  late MockAppLogger mockLogger;
  late MockUrlLauncherPlatform mockLauncher;
  late FakeRemoteConfigService fakeRemoteConfig;
  late MockTelemetryService mockTelemetry;

  setUp(() {
    mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;
    mockLogger = MockAppLogger();
    AppLogger.instance = mockLogger;
    mockLauncher = MockUrlLauncherPlatform();
    UrlLauncherPlatform.instance = mockLauncher;
    fakeRemoteConfig = FakeRemoteConfigService();
    RemoteConfigService.instance = fakeRemoteConfig;
  });

  Widget criarWidgetTeste({
    VoidCallback? onFeedbackSolicitado,
    VoidCallback? onAbrirWhatsapp,
    VoidCallback? onAbrirInstagram,
  }) {
    return MaterialApp(
      home: Theme(
        data: ThemeData(
          extensions: const [AppColors.dark],
        ),
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  exibirModalBetaAberto(
                    context,
                    onFeedbackSolicitado: onFeedbackSolicitado,
                    onAbrirWhatsapp: onAbrirWhatsapp,
                    onAbrirInstagram: onAbrirInstagram,
                  );
                },
                child: const Text('Abrir Modal'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Renderiza modal informativo de Beta Aberto com título branco e botões sociais na ordem instagram -> whatsapp -> feedback', (tester) async {
    await tester.pumpWidget(criarWidgetTeste());
    await tester.tap(find.text('Abrir Modal'));
    await tester.pumpAndSettle();

    expect(find.text('Fase Beta Aberta'), findsOneWidget);
    expect(find.textContaining('iniciativa independente', findRichText: true), findsOneWidget);
    expect(find.textContaining('Novos setores', findRichText: true), findsOneWidget);

    final finderInstagram = find.text('Instagram Oficial');
    final finderWhatsapp = find.text('Comunidade no WhatsApp');
    final finderFeedback = find.text('Enviar Sugestão');

    expect(finderInstagram, findsOneWidget);
    expect(finderWhatsapp, findsOneWidget);
    expect(finderFeedback, findsOneWidget);

    // Valida que a ordem vertical é: Instagram -> WhatsApp -> Feedback
    final dyInstagram = tester.getTopLeft(finderInstagram).dy;
    final dyWhatsapp = tester.getTopLeft(finderWhatsapp).dy;
    final dyFeedback = tester.getTopLeft(finderFeedback).dy;

    expect(dyInstagram, lessThan(dyWhatsapp));
    expect(dyWhatsapp, lessThan(dyFeedback));
  });

  testWidgets('Fecha o modal ao clicar no botão de fechar', (tester) async {
    await tester.pumpWidget(criarWidgetTeste());
    await tester.tap(find.text('Abrir Modal'));
    await tester.pumpAndSettle();

    expect(find.byType(ModalBetaAberto), findsOneWidget);

    final botaoFechar = find.byIcon(Icons.close);
    expect(botaoFechar, findsOneWidget);
    await tester.tap(botaoFechar);
    await tester.pumpAndSettle();

    expect(find.byType(ModalBetaAberto), findsNothing);
  });

  testWidgets('Aciona o callback de feedback e fecha o modal ao clicar no botão de feedback', (tester) async {
    bool feedbackDisparado = false;

    await tester.pumpWidget(criarWidgetTeste(
      onFeedbackSolicitado: () {
        feedbackDisparado = true;
      },
    ));

    await tester.tap(find.text('Abrir Modal'));
    await tester.pumpAndSettle();

    final botaoFeedback = find.text('Enviar Sugestão');
    expect(botaoFeedback, findsOneWidget);
    await tester.tap(botaoFeedback);
    await tester.pumpAndSettle();

    expect(feedbackDisparado, isTrue);
    expect(find.byType(ModalBetaAberto), findsNothing);
  });

  testWidgets('Aciona o fluxo padrão do BetterFeedback ao clicar no botão de feedback sem callback customizado', (tester) async {
    await tester.pumpWidget(
      BetterFeedback(
        child: criarWidgetTeste(),
      ),
    );
    await tester.tap(find.text('Abrir Modal'));
    await tester.pumpAndSettle();

    final botaoFeedback = find.text('Enviar Sugestão');
    await tester.tap(botaoFeedback);
    await tester.pumpAndSettle();

    expect(find.byType(ModalBetaAberto), findsNothing);
  });

  testWidgets('Aciona o callback de WhatsApp customizado ao clicar no botão de comunidade', (tester) async {
    bool whatsappDisparado = false;

    await tester.pumpWidget(criarWidgetTeste(
      onAbrirWhatsapp: () {
        whatsappDisparado = true;
      },
    ));

    await tester.tap(find.text('Abrir Modal'));
    await tester.pumpAndSettle();

    final botaoWhatsapp = find.text('Comunidade no WhatsApp');
    expect(botaoWhatsapp, findsOneWidget);
    await tester.tap(botaoWhatsapp);
    await tester.pumpAndSettle();

    expect(whatsappDisparado, isTrue);
  });

  testWidgets('Aciona o callback de Instagram customizado ao clicar no botão de Instagram', (tester) async {
    bool instagramDisparado = false;

    await tester.pumpWidget(criarWidgetTeste(
      onAbrirInstagram: () {
        instagramDisparado = true;
      },
    ));

    await tester.tap(find.text('Abrir Modal'));
    await tester.pumpAndSettle();

    final botaoInstagram = find.text('Instagram Oficial');
    expect(botaoInstagram, findsOneWidget);
    await tester.tap(botaoInstagram);
    await tester.pumpAndSettle();

    expect(instagramDisparado, isTrue);
  });

  testWidgets('Abre URL nativa do WhatsApp por padrão quando nenhum callback é fornecido', (tester) async {
    await tester.pumpWidget(criarWidgetTeste());
    await tester.tap(find.text('Abrir Modal'));
    await tester.pumpAndSettle();

    final botaoWhatsapp = find.text('Comunidade no WhatsApp');
    await tester.tap(botaoWhatsapp);
    await tester.pumpAndSettle();

    expect(mockLauncher.lastLaunchedUrl, equals('https://chat.whatsapp.com/JmxWeLSmGTT66AREtrKyjA'));
  });

  testWidgets('Abre URL nativa do Instagram por padrão quando nenhum callback é fornecido', (tester) async {
    await tester.pumpWidget(criarWidgetTeste());
    await tester.tap(find.text('Abrir Modal'));
    await tester.pumpAndSettle();

    final botaoInstagram = find.text('Instagram Oficial');
    await tester.tap(botaoInstagram);
    await tester.pumpAndSettle();

    expect(mockLauncher.lastLaunchedUrl, equals('https://www.instagram.com/arestaclimb/'));
  });

  testWidgets('Registra erro no AppLogger caso ocorra falha ao abrir links nativos', (tester) async {
    mockLauncher.shouldThrow = true;

    await tester.pumpWidget(criarWidgetTeste());
    await tester.tap(find.text('Abrir Modal'));
    await tester.pumpAndSettle();

    final botaoWhatsapp = find.text('Comunidade no WhatsApp');
    await tester.tap(botaoWhatsapp);
    await tester.pumpAndSettle();

    expect(mockLogger.recordedErrors.length, equals(1));
    expect(mockLogger.recordedErrors.first['contextMessage'], contains('WhatsApp'));

    final botaoInstagram = find.text('Instagram Oficial');
    await tester.tap(botaoInstagram);
    await tester.pumpAndSettle();

    expect(mockLogger.recordedErrors.length, equals(2));
    expect(mockLogger.recordedErrors.last['contextMessage'], contains('Instagram'));
  });

  group('ModalBetaAberto - Telemetria', () {
    testWidgets('dispara logAcaoBetaAberto ao abrir o modal', (tester) async {
      await tester.pumpWidget(criarWidgetTeste());
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_beta_aberto'));
      final params = mockTelemetry.recordedParams['acao_beta_aberto']!;
      expect(params['acao'], 'abrir_modal_beta');
      expect(params['origem'], 'home_header');
    });

    testWidgets('dispara logAcaoBetaAberto ao clicar no Instagram', (tester) async {
      await tester.pumpWidget(criarWidgetTeste());
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      mockTelemetry.clear();
      await tester.tap(find.text('Instagram Oficial'));
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_beta_aberto'));
      final params = mockTelemetry.recordedParams['acao_beta_aberto']!;
      expect(params['acao'], 'clique_instagram');
      expect(params['origem'], 'modal_beta');
      expect(params['detalhe'], 'instagram');
    });

    testWidgets('dispara logAcaoBetaAberto ao clicar no WhatsApp', (tester) async {
      await tester.pumpWidget(criarWidgetTeste());
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      mockTelemetry.clear();
      await tester.tap(find.text('Comunidade no WhatsApp'));
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_beta_aberto'));
      final params = mockTelemetry.recordedParams['acao_beta_aberto']!;
      expect(params['acao'], 'clique_whatsapp');
      expect(params['origem'], 'modal_beta');
      expect(params['detalhe'], 'whatsapp');
    });

    testWidgets('dispara logAcaoBetaAberto ao clicar em Enviar Sugestão', (tester) async {
      await tester.pumpWidget(criarWidgetTeste(onFeedbackSolicitado: () {}));
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      mockTelemetry.clear();
      await tester.tap(find.text('Enviar Sugestão'));
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_beta_aberto'));
      final params = mockTelemetry.recordedParams['acao_beta_aberto']!;
      expect(params['acao'], 'clique_feedback');
      expect(params['origem'], 'modal_beta');
      expect(params['detalhe'], 'feedback');
    });
  });
}
