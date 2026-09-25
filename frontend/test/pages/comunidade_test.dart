// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:frontend/pages/comunidade.dart';
import 'package:frontend/services/firebase/remote_config_service.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_app_logger.dart';
import '../mocks/mock_telemetry_service.dart';

class FakeRemoteConfigService extends Fake implements RemoteConfigService {
  String url = 'https://chat.whatsapp.com/JmxWeLSmGTT66AREtrKyjA';
  String discordUrl = 'https://discord.gg/NT9uSKJWYs';

  @override
  String get whatsappCommunityUrl => url;

  @override
  String get discordCommunityUrl => discordUrl;
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
  late MockTelemetryService mockTelemetria;

  setUp(() {
    mockTelemetria = MockTelemetryService();
    TelemetryService.instance = mockTelemetria;
    mockLogger = MockAppLogger();
    AppLogger.instance = mockLogger;
    mockLauncher = MockUrlLauncherPlatform();
    UrlLauncherPlatform.instance = mockLauncher;
    fakeRemoteConfig = FakeRemoteConfigService();
    RemoteConfigService.instance = fakeRemoteConfig;
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: Theme(
        data: ThemeData(
          extensions: [
            AppColors.dark,
          ],
        ),
        child: const ComunidadePage(),
      ),
    );
  }

  void setScreenSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('ComunidadePage renderiza todos os cards de ação', (WidgetTester tester) async {
    setScreenSize(tester);
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('MÍDIAS, APOIOS E INTERATIVIDADES'), findsOneWidget);
    expect(find.text('SOBRE O TIME'), findsOneWidget);
    expect(find.text('GRUPO DO WHATSAPP'), findsOneWidget);
    expect(find.text('INSTAGRAM OFICIAL'), findsOneWidget);
    expect(find.text('LINKEDIN DO PROJETO'), findsOneWidget);
    expect(find.text('DISCORD DOS DESENVOLVEDORES'), findsOneWidget);
    expect(find.text('GITHUB DO ARESTA'), findsOneWidget);
  });

  testWidgets('Ao clicar nos cards com sucesso, abre a URL correspondente sem registrar erros', (WidgetTester tester) async {
    setScreenSize(tester);
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    mockLauncher.shouldThrow = false;

    // WhatsApp
    await tester.tap(find.text('GRUPO DO WHATSAPP'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(mockLauncher.lastLaunchedUrl, 'https://chat.whatsapp.com/JmxWeLSmGTT66AREtrKyjA');
    expect(mockLogger.recordedErrors, isEmpty);

    // Instagram
    await tester.tap(find.text('INSTAGRAM OFICIAL'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(mockLauncher.lastLaunchedUrl, 'https://www.instagram.com/arestaclimb/');
    expect(mockLogger.recordedErrors, isEmpty);

    // Discord
    await tester.ensureVisible(find.text('DISCORD DOS DESENVOLVEDORES'));
    await tester.tap(find.text('DISCORD DOS DESENVOLVEDORES'));
    await tester.pumpAndSettle();
    expect(mockLauncher.lastLaunchedUrl, 'https://discord.gg/NT9uSKJWYs');
    expect(mockLogger.recordedErrors, isEmpty);
  });

  testWidgets('Ao clicar no card do WhatsApp, consome dinamicamente a URL do RemoteConfigService', (WidgetTester tester) async {
    setScreenSize(tester);
    fakeRemoteConfig.url = 'https://chat.whatsapp.com/NovaComunidade123';
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    mockLauncher.shouldThrow = false;
    await tester.tap(find.text('GRUPO DO WHATSAPP'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(mockLauncher.lastLaunchedUrl, 'https://chat.whatsapp.com/NovaComunidade123');
    expect(mockLogger.recordedErrors, isEmpty);
  });

  testWidgets('Ao clicar no card do Discord, consome dinamicamente a URL do RemoteConfigService', (WidgetTester tester) async {
    setScreenSize(tester);
    fakeRemoteConfig.discordUrl = 'https://discord.gg/NovoDiscord123';
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    mockLauncher.shouldThrow = false;
    await tester.ensureVisible(find.text('DISCORD DOS DESENVOLVEDORES'));
    await tester.tap(find.text('DISCORD DOS DESENVOLVEDORES'));
    await tester.pumpAndSettle();

    expect(mockLauncher.lastLaunchedUrl, 'https://discord.gg/NovoDiscord123');
    expect(mockLogger.recordedErrors, isEmpty);
  });

  testWidgets('Ao clicar nos cards de links externos com falha nativa, registra erro com a URL correspondente', (WidgetTester tester) async {
    setScreenSize(tester);
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    mockLauncher.shouldThrow = true;

    // 1. WhatsApp
    await tester.ensureVisible(find.text('GRUPO DO WHATSAPP'));
    await tester.tap(find.text('GRUPO DO WHATSAPP'));
    await tester.pumpAndSettle();
    expect(
      mockLogger.recordedErrors.any(
        (e) => e['contextMessage'].contains('https://chat.whatsapp.com/JmxWeLSmGTT66AREtrKyjA'),
      ),
      isTrue,
    );

    // 2. Instagram
    await tester.ensureVisible(find.text('INSTAGRAM OFICIAL'));
    await tester.tap(find.text('INSTAGRAM OFICIAL'));
    await tester.pumpAndSettle();
    expect(
      mockLogger.recordedErrors.any(
        (e) => e['contextMessage'].contains('https://www.instagram.com/arestaclimb/'),
      ),
      isTrue,
    );

    // 3. LinkedIn
    await tester.ensureVisible(find.text('LINKEDIN DO PROJETO'));
    await tester.tap(find.text('LINKEDIN DO PROJETO'));
    await tester.pumpAndSettle();
    expect(
      mockLogger.recordedErrors.any(
        (e) => e['contextMessage'].contains('https://www.linkedin.com/company/arestaclimb/'),
      ),
      isTrue,
    );

    // 4. Discord
    await tester.ensureVisible(find.text('DISCORD DOS DESENVOLVEDORES'));
    await tester.tap(find.text('DISCORD DOS DESENVOLVEDORES'));
    await tester.pumpAndSettle();
    expect(
      mockLogger.recordedErrors.any(
        (e) => e['contextMessage'].contains('https://discord.gg/NT9uSKJWYs'),
      ),
      isTrue,
    );

    // 5. GitHub
    await tester.ensureVisible(find.text('GITHUB DO ARESTA'));
    await tester.tap(find.text('GITHUB DO ARESTA'));
    await tester.pumpAndSettle();
    expect(
      mockLogger.recordedErrors.any(
        (e) => e['contextMessage'].contains('https://github.com/aresta-climb'),
      ),
      isTrue,
    );
  });

  testWidgets('ComunidadePage renderiza rodapé de versão com indicação de Beta Aberto', (WidgetTester tester) async {
    setScreenSize(tester);
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.textContaining('• Beta Aberto'), findsOneWidget);
  });

  testWidgets('ComunidadePage dispara logLinkExterno com detalhe ao clicar nos cards sociais', (WidgetTester tester) async {
    setScreenSize(tester);
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // 1. WhatsApp
    mockTelemetria.clear();
    await tester.tap(find.text('GRUPO DO WHATSAPP'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(mockTelemetria.recordedEvents, contains('link_externo'));
    var params = mockTelemetria.recordedParams['link_externo']!;
    expect(params['acao'], 'abrir_link_externo');
    expect(params['origem'], 'comunidade');
    expect(params['detalhe'], 'https://chat.whatsapp.com/JmxWeLSmGTT66AREtrKyjA');

    // 2. Instagram
    mockTelemetria.clear();
    await tester.tap(find.text('INSTAGRAM OFICIAL'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(mockTelemetria.recordedEvents, contains('link_externo'));
    params = mockTelemetria.recordedParams['link_externo']!;
    expect(params['acao'], 'abrir_link_externo');
    expect(params['origem'], 'comunidade');
    expect(params['detalhe'], 'https://www.instagram.com/arestaclimb/');

    // 3. LinkedIn
    mockTelemetria.clear();
    await tester.ensureVisible(find.text('LINKEDIN DO PROJETO'));
    await tester.tap(find.text('LINKEDIN DO PROJETO'));
    await tester.pumpAndSettle();
    expect(mockTelemetria.recordedEvents, contains('link_externo'));
    params = mockTelemetria.recordedParams['link_externo']!;
    expect(params['origem'], 'comunidade');
    expect(params['detalhe'], 'https://www.linkedin.com/company/arestaclimb/');

    // 4. Discord
    mockTelemetria.clear();
    await tester.ensureVisible(find.text('DISCORD DOS DESENVOLVEDORES'));
    await tester.tap(find.text('DISCORD DOS DESENVOLVEDORES'));
    await tester.pumpAndSettle();
    expect(mockTelemetria.recordedEvents, contains('link_externo'));
    params = mockTelemetria.recordedParams['link_externo']!;
    expect(params['origem'], 'comunidade');
    expect(params['detalhe'], fakeRemoteConfig.discordCommunityUrl);

    // 5. GitHub
    mockTelemetria.clear();
    await tester.ensureVisible(find.text('GITHUB DO ARESTA'));
    await tester.tap(find.text('GITHUB DO ARESTA'));
    await tester.pumpAndSettle();
    expect(mockTelemetria.recordedEvents, contains('link_externo'));
    params = mockTelemetria.recordedParams['link_externo']!;
    expect(params['origem'], 'comunidade');
    expect(params['detalhe'], 'https://github.com/aresta-climb');
  });

  testWidgets('Todos os links externos disparados pela ComunidadePage possuem formato HTTPS e hosts válidos', (WidgetTester tester) async {
    setScreenSize(tester);
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final List<(String, String)> cardsEHosts = [
      ('GRUPO DO WHATSAPP', 'chat.whatsapp.com'),
      ('INSTAGRAM OFICIAL', 'www.instagram.com'),
      ('LINKEDIN DO PROJETO', 'www.linkedin.com'),
      ('DISCORD DOS DESENVOLVEDORES', 'discord.gg'),
      ('GITHUB DO ARESTA', 'github.com'),
    ];

    for (final (cardTitle, expectedHost) in cardsEHosts) {
      mockLauncher.shouldThrow = false;
      mockLauncher.lastLaunchedUrl = null;

      await tester.ensureVisible(find.text(cardTitle));
      await tester.tap(find.text(cardTitle));
      await tester.pumpAndSettle();

      final launchedUrl = mockLauncher.lastLaunchedUrl;
      expect(launchedUrl, isNotNull, reason: 'Card "$cardTitle" deve disparar uma URL');

      final uri = Uri.tryParse(launchedUrl!);
      expect(uri, isNotNull, reason: 'URL "$launchedUrl" deve ser um URI bem formado');
      expect(uri!.isAbsolute, isTrue, reason: 'URL deve ser absoluta');
      expect(uri.scheme, 'https', reason: 'URL deve usar HTTPS');
      expect(uri.host, expectedHost, reason: 'URL deve ter o host $expectedHost');
    }
  });

  testWidgets('Ao tocar no card SOBRE O TIME, aciona o callback sem lançar exceções', (WidgetTester tester) async {
    setScreenSize(tester);
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('SOBRE O TIME'));
    await tester.pumpAndSettle();

    expect(find.text('SOBRE O TIME'), findsOneWidget);
  });
}
